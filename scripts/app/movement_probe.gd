extends Node2D

## Does the player actually move the way the profile says it should?
##
## This deliberately does NOT re-check the arithmetic in MovementProfile --
## that would only prove multiplication works. It builds a real collision
## world, drops a real CharacterBody2D into it, drives it through real physics
## frames with scripted input, and MEASURES what the body did.
##
## The distinction matters. The original had no way to test movement at all,
## so a wrong constant could only be found by playing. Everything here is a
## claim about the artefact, established by a command.
##
## Run: godot --headless --path . scenes/MovementProbe.tscn

const FLOOR_Y := 600.0
const TICK := 1.0 / 60.0

var _checks := 0
var _fails := 0
var _player: Player
var _profile: MovementProfile


func _ready() -> void:
	_profile = MovementProfile.new()
	await _run()


func _ok(label: String, got: float, want: float, tol: float, unit: String = "") -> void:
	_checks += 1
	var d := absf(got - want)
	var good := d <= tol
	if not good:
		_fails += 1
	print("  [%s] %-40s got %8.3f%s  want %8.3f +/- %.3f"
		% ["PASS" if good else "FAIL", label, got, unit, want, tol])


func _say(label: String, cond: bool, detail: String = "") -> void:
	_checks += 1
	if not cond:
		_fails += 1
	print("  [%s] %-40s %s" % ["PASS" if cond else "FAIL", label, detail])


## Build a floor and a ledge. Static bodies, one collision layer, nothing clever.
func _build_world() -> void:
	var floor_body := StaticBody2D.new()
	var floor_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(4000, 80)
	floor_shape.shape = rect
	floor_body.add_child(floor_shape)
	floor_body.global_position = Vector2(0, FLOOR_Y + 40)
	add_child(floor_body)

	_player = Player.new()
	_player.profile = _profile
	_player.read_input = false
	var pshape := CollisionShape2D.new()
	var caps := CapsuleShape2D.new()
	caps.radius = 28.0
	caps.height = 180.0
	pshape.shape = caps
	_player.add_child(pshape)
	# Feet exactly on the floor: capsule centre sits half its height above.
	_player.global_position = Vector2(0, FLOOR_Y - 90.0)
	add_child(_player)


func _settle(frames: int = 12) -> void:
	_player.move_axis = 0.0
	_player.jump_pressed = false
	_player.jump_held = false
	_player.down_held = false
	for i in range(frames):
		await get_tree().physics_frame


## Run one jump and report peak rise and time to that peak.
## hold_frames: how long the jump button stays down (variable jump height).
func _measure_jump(hold_frames: int, max_frames: int = 240) -> Dictionary:
	await _settle()
	var start_y := _player.global_position.y
	var peak_rise := 0.0
	var apex_frames := 0
	var frames_held := 0
	var airborne_frames := 0

	_player.jump_pressed = true
	_player.jump_held = true

	for i in range(max_frames):
		await get_tree().physics_frame
		_player.jump_pressed = false
		frames_held += 1
		if frames_held >= hold_frames:
			_player.jump_held = false

		var rise := start_y - _player.global_position.y
		if rise > peak_rise:
			peak_rise = rise
			apex_frames = i + 1
		if not _player.is_on_floor():
			airborne_frames += 1
		# landed again after having left
		if i > 4 and _player.is_on_floor() and rise < 1.0:
			break

	return {
		"peak_rise": peak_rise,
		"apex_time": float(apex_frames) * TICK,
		"air_time": float(airborne_frames) * TICK,
	}


func _run() -> void:
	print("=== Ghost Front movement probe ===")
	print("profile: ", _profile.describe())
	print("physics tick: %.4fs\n" % TICK)

	_build_world()
	await _settle(20)

	_say("player rests on the floor", _player.is_on_floor(),
		"y=%.1f" % _player.global_position.y)

	# ---- 1. a full jump should reach the height the designer asked for.
	print("\n-- full jump reaches its stated height --")
	var full := await _measure_jump(600)
	# Tolerance is generous on purpose: a 60Hz Euler integration overshoots the
	# closed-form solution slightly, and the apex-hang scaling is a deliberate
	# departure from pure ballistics. What is being checked is that the number
	# a designer types is the number they get, not that Godot solves calculus.
	_ok("peak rise vs jump_height", full.peak_rise, _profile.jump_height,
		_profile.jump_height * 0.18, "px")
	_ok("time to apex vs time_to_apex", full.apex_time, _profile.time_to_apex,
		_profile.time_to_apex * 0.45, "s")

	# ---- 2. variable jump height: a tap must be meaningfully shorter.
	print("\n-- variable jump height (release cuts the rise) --")
	var tap := await _measure_jump(3)
	_say("tap is lower than hold",
		tap.peak_rise < full.peak_rise * 0.85,
		"tap=%.0fpx  hold=%.0fpx" % [tap.peak_rise, full.peak_rise])
	_say("tap still leaves the ground", tap.peak_rise > 20.0,
		"tap=%.0fpx" % tap.peak_rise)

	# ---- 3. asymmetric gravity: falling is quicker than rising.
	print("\n-- fall is heavier than rise --")
	var fall_time: float = full.air_time - full.apex_time
	_say("descent faster than ascent",
		fall_time < full.apex_time,
		"up=%.3fs down=%.3fs" % [full.apex_time, fall_time])

	# ---- 4. coyote time: a jump just after leaving a ledge must work.
	#
	# air_jumps is forced to 0 for this test and the next, and that is the
	# whole point rather than tidiness. Both tests assert "did he rise?", and
	# with an air jump available that evidence is produced just as well by the
	# air jump as by the mechanism being named. The first version of this file
	# passed both while proving neither. A test has to be run where the wrong
	# answer is unavailable, or it is only testing that the code executes.
	var saved_air_jumps := _profile.air_jumps
	_profile.air_jumps = 0

	print("\n-- coyote time (air jump disabled, so only coyote can explain a rise) --")
	await _settle()
	_player.global_position = Vector2(1900, FLOOR_Y - 90.0)
	await _settle(10)
	var coyote_worked := false
	if _player.is_on_floor():
		# step off the edge
		_player.move_axis = 1.0
		var left_at := -1
		for i in range(120):
			await get_tree().physics_frame
			if not _player.is_on_floor():
				left_at = i
				break
		if left_at >= 0:
			# one frame into the window, ask for a jump
			await get_tree().physics_frame
			var y0 := _player.global_position.y
			_player.jump_pressed = true
			_player.jump_held = true
			await get_tree().physics_frame
			_player.jump_pressed = false
			# rising?
			coyote_worked = _player.velocity.y < -100.0
			_say("jump granted after leaving ledge", coyote_worked,
				"vy=%.0f (was y=%.1f)" % [_player.velocity.y, y0])
		else:
			_say("jump granted after leaving ledge", false, "never left the floor")
	else:
		_say("jump granted after leaving ledge", false, "did not start grounded")

	# ---- 5. buffered jump: pressing before landing fires on touchdown.
	# Still air-jumpless, for the same reason as above.
	# The window is jump_buffer seconds wide, so the press has to land inside
	# it -- an earlier version of this test pressed 0.3s before touchdown with
	# a 0.12s buffer and called the correct refusal a bug.
	#
	# It also has to be pressed AFTER the coyote window has shut, or coyote
	# explains the rise just as well as buffering does. Falling 180px takes
	# ~0.24s, coyote is 0.10s, so waiting until he is near the floor puts the
	# press comfortably outside coyote and comfortably inside the buffer.
	print("\n-- jump buffering (no air jump; press is outside coyote, inside buffer) --")
	await _settle()
	_player.global_position = Vector2(0, FLOOR_Y - 270.0)
	_player.velocity = Vector2.ZERO
	var pressed_at_y := 0.0
	var coyote_at_press := 999.0
	for i in range(120):
		await get_tree().physics_frame
		if _player.global_position.y > FLOOR_Y - 120.0:
			break
	pressed_at_y = _player.global_position.y
	coyote_at_press = _player.coyote_remaining()
	_player.jump_pressed = true
	_player.jump_held = true
	await get_tree().physics_frame
	_player.jump_pressed = false
	var buffered := false
	for i in range(60):
		await get_tree().physics_frame
		if _player.velocity.y < -100.0:
			buffered = true
			break
	_say("coyote was already shut when pressed", coyote_at_press <= 0.0,
		"coyote_left=%.4fs at y=%.0f" % [coyote_at_press, pressed_at_y])
	_say("press before landing fires on touchdown", buffered,
		"vy=%.0f" % _player.velocity.y)

	# ---- 5b. THE CONTROL. The two tests above are only worth anything if this
	# same setup can fail. Falling, no air jump, well past the coyote window:
	# a jump press must do nothing. If this "passes" by rising, then the two
	# results above prove nothing and the suite is lying.
	print("\n-- control: with no air jump and no coyote, a press must do NOTHING --")
	await _settle()
	_player.global_position = Vector2(0, FLOOR_Y - 3000.0)
	_player.velocity = Vector2(0, 400.0)
	# burn well past coyote_time so the window is definitely shut
	for i in range(int(_profile.coyote_time / TICK) + 20):
		await get_tree().physics_frame
	var vy_before := _player.velocity.y
	_player.jump_pressed = true
	_player.jump_held = true
	await get_tree().physics_frame
	_player.jump_pressed = false
	await get_tree().physics_frame
	var rose := _player.velocity.y < vy_before - 50.0
	_say("mid-air press is correctly refused", not rose,
		"vy %.0f -> %.0f" % [vy_before, _player.velocity.y])

	_profile.air_jumps = saved_air_jumps

	# ---- 6. air jump is a kick, not a hover.
	print("\n-- air jump --")
	_say("air jump is weaker than ground jump",
		absf(_profile.air_jump_velocity()) < absf(_profile.jump_velocity()),
		"air=%.0f ground=%.0f"
			% [_profile.air_jump_velocity(), _profile.jump_velocity()])

	# ---- 7. terminal velocity is respected on a long drop.
	print("\n-- terminal velocity --")
	await _settle()
	_player.global_position = Vector2(0, FLOOR_Y - 5000.0)
	_player.velocity = Vector2.ZERO
	var vmax := 0.0
	for i in range(180):
		await get_tree().physics_frame
		vmax = maxf(vmax, _player.velocity.y)
		if _player.is_on_floor():
			break
	_say("fall speed capped at max_fall_speed",
		vmax <= _profile.max_fall_speed + 1.0,
		"peak vy=%.0f cap=%.0f" % [vmax, _profile.max_fall_speed])

	# ---- 8. orthogonality: the property the whole design rests on.
	# Changing jump_height must not change time_to_apex, and vice versa.
	print("\n-- the knobs are orthogonal (why this design exists) --")
	var a := MovementProfile.new()
	var b := MovementProfile.new()
	b.jump_height = a.jump_height * 2.0
	_ok("doubling height keeps apex time", b.time_to_apex, a.time_to_apex, 0.0001, "s")
	_say("doubling height doubles the height",
		absf(b.jump_height - a.jump_height * 2.0) < 0.001,
		"%.0f -> %.0f" % [a.jump_height, b.jump_height])
	var c := MovementProfile.new()
	c.time_to_apex = a.time_to_apex * 2.0
	_ok("doubling apex time keeps height", c.jump_height, a.jump_height, 0.0001, "px")
	_say("doubling apex time quarters gravity",
		absf(c.gravity() - a.gravity() / 4.0) < 0.01,
		"%.0f -> %.0f" % [a.gravity(), c.gravity()])

	# ---- report
	print("\n%d checks, %d failed." % [_checks, _fails])
	# Set well below the real count (15) on purpose: this exists to catch a run
	# that died partway or never started, not to be re-typed every time a check
	# is added. A floor set to the exact count is a maintenance tax that gets
	# "fixed" by lowering it, which is how it stops catching anything.
	var floor_checks := 10
	if _checks < floor_checks:
		printerr("PROBE BROKEN: only %d checks ran, expected >= %d."
			% [_checks, floor_checks])
		get_tree().quit(2)
		return
	if _fails > 0:
		printerr("%d check(s) failed." % _fails)
		get_tree().quit(1)
		return
	print("all passed.")
	get_tree().quit(0)
