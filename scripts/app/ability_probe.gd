extends Node2D

## Do the three Project 42 verbs behave?
##
## Same discipline as MovementProbe: measure a real body in a real collision
## world, and make sure every check runs where the WRONG answer is available.
## The lesson that produced that rule here was two movement tests that both
## asserted "did he rise?" while an air jump was quietly capable of producing
## the same evidence.
##
## Run: godot --headless --path . scenes/AbilityProbe.tscn

const FLOOR_Y := 600.0
const TICK := 1.0 / 60.0

var _checks := 0
var _fails := 0
var _player: Player
var _profile: MovementProfile


func _ready() -> void:
	_profile = MovementProfile.new()
	await _run()


func _say(label: String, cond: bool, detail: String = "") -> void:
	_checks += 1
	if not cond:
		_fails += 1
	print("  [%s] %-44s %s" % ["PASS" if cond else "FAIL", label, detail])


func _ok(label: String, got: float, want: float, tol: float) -> void:
	_checks += 1
	var good := absf(got - want) <= tol
	if not good:
		_fails += 1
	print("  [%s] %-44s got %8.3f want %8.3f +/- %.3f"
		% ["PASS" if good else "FAIL", label, got, want, tol])


func _build() -> void:
	var body := StaticBody2D.new()
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(4000, 80)
	cs.shape = r
	body.add_child(cs)
	body.global_position = Vector2(0, FLOOR_Y + 40)
	add_child(body)

	_player = Player.new()
	_player.profile = _profile
	_player.read_input = false
	# deterministic RNG so the involuntary-phase check is reproducible
	_player.phase = PhaseDash.new(20260827)
	var pcs := CollisionShape2D.new()
	var caps := CapsuleShape2D.new()
	caps.radius = 26.0
	caps.height = 150.0
	pcs.shape = caps
	_player.add_child(pcs)
	_player.global_position = Vector2(0, FLOOR_Y - 75.0)
	add_child(_player)


func _idle(frames: int = 10) -> void:
	_player.move_axis = 0.0
	_player.vert_axis = 0.0
	_player.jump_pressed = false
	_player.jump_held = false
	_player.rewind_held = false
	_player.phase_pressed = false
	_player.arc_pressed = false
	for i in range(frames):
		await get_tree().physics_frame


func _run() -> void:
	print("=== Ghost Front ability probe (Chrono / Phase / Current) ===\n")
	_build()
	await _idle(20)

	# ================= CHRONO =================
	print("-- CHRONO: rewind returns you to where you were --")
	await _idle()
	var start := _player.global_position
	_player.move_axis = 1.0
	for i in range(45):
		await get_tree().physics_frame
	var travelled := _player.global_position.x - start.x
	_say("moved away from the start", travelled > 200.0,
		"dx=%.0fpx" % travelled)

	_player.move_axis = 0.0
	_player.rewind_held = true
	var rewound_frames := 0
	for i in range(240):
		await get_tree().physics_frame
		rewound_frames += 1
		if not _player.chrono.is_rewinding():
			break
	_player.rewind_held = false
	var back_err := absf(_player.global_position.x - start.x)
	_say("rewind returned to within 40px of the start", back_err < 40.0,
		"err=%.1fpx after %d frames" % [back_err, rewound_frames])

	# The wrong answer must be available: rewind is only meaningful if NOT
	# rewinding leaves you where you were. Control.
	await _idle()
	var s2 := _player.global_position
	_player.move_axis = 1.0
	for i in range(45):
		await get_tree().physics_frame
	_player.move_axis = 0.0
	for i in range(60):
		await get_tree().physics_frame
	_say("control: without rewind he stays where he ran to",
		absf(_player.global_position.x - s2.x) > 200.0,
		"dx=%.0fpx" % (_player.global_position.x - s2.x))

	print("\n-- CHRONO: history is finite and is consumed --")
	await _idle()
	var ch := _player.chrono
	_say("history fills up", ch.available() > 0.0,
		"%.2fs of %.2fs" % [ch.available(), ch.duration])
	_player.rewind_held = true
	for i in range(400):
		await get_tree().physics_frame
		if ch.available() <= 0.0:
			break
	_player.rewind_held = false
	_say("history exhausts rather than rewinding forever",
		ch.available() <= 0.001, "%.4fs left" % ch.available())

	# ================= PHASE =================
	print("\n-- PHASE: the dash moves you and costs attenuation --")
	await _idle(30)
	_player.phase.reset()
	var p0 := _player.global_position
	var a0: float = _player.phase.attenuation
	_player.move_axis = 1.0
	_player.phase_pressed = true
	await get_tree().physics_frame
	_player.phase_pressed = false
	var dashing := _player.phase.is_dashing()
	for i in range(int(_player.phase.dash_time / TICK) + 2):
		await get_tree().physics_frame
	var dash_dx := _player.global_position.x - p0.x
	_player.move_axis = 0.0
	_say("dash engaged", dashing)
	_say("dash covered ground fast", dash_dx > 120.0, "dx=%.0fpx" % dash_dx)
	_say("dash spent attenuation", _player.phase.attenuation > a0,
		"%.2f -> %.2f" % [a0, _player.phase.attenuation])

	print("\n-- PHASE: attenuation recovers when you stop --")
	var a1: float = _player.phase.attenuation
	await _idle(90)
	_say("attenuation fell while not phasing", _player.phase.attenuation < a1,
		"%.3f -> %.3f" % [a1, _player.phase.attenuation])

	# ---- THE SEDUCTION. Canon: attenuation is not a penalty bar, it is an
	# advantage that costs you your grip on being solid. Assert BOTH halves,
	# because a version of this that only punishes is the wrong mechanic and
	# would still pass a test that only looked at the downside.
	print("\n-- PHASE: the seduction (the fail state must be attractive) --")
	var ph := _player.phase
	ph.attenuation = 0.0
	var see_clear := ph.perception_scale()
	var evade_clear := ph.evasion_chance()
	ph.attenuation = 1.0
	var see_gone := ph.perception_scale()
	var evade_gone := ph.evasion_chance()
	_say("the world perceives you LESS as you attenuate", see_gone < see_clear,
		"perception %.2f -> %.2f" % [see_clear, see_gone])
	_say("you are HARDER TO HIT as you attenuate", evade_gone > evade_clear,
		"evasion %.2f -> %.2f" % [evade_clear, evade_gone])
	_say("at zero attenuation there is no free advantage",
		is_equal_approx(see_clear, 1.0) and is_zero_approx(evade_clear),
		"perception=%.2f evasion=%.2f" % [see_clear, evade_clear])
	_say("the advantage is monotonic, so spending always tempts",
		_monotonic_seduction(ph), "checked 11 points across the meter")

	print("\n-- PHASE: and it takes the floor away --")
	ph.attenuation = 1.0
	_say("full attenuation is unstable", ph.is_unstable(),
		"threshold %.2f" % ph.unstable_at)
	var flickers := 0
	for i in range(600):
		var r := ph.step(TICK)
		ph.attenuation = 1.0   # hold it pinned; recovery would drain it
		if ph.is_intangible():
			flickers += 1
	_say("involuntary phasing actually occurs at full attenuation",
		flickers > 0, "%d flicker frames in 600" % flickers)
	ph.attenuation = 0.0
	var calm := 0
	for i in range(600):
		ph.step(TICK)
		ph.attenuation = 0.0
		if ph.is_intangible():
			calm += 1
	_say("control: no involuntary phasing at zero attenuation", calm == 0,
		"%d flicker frames in 600" % calm)

	# ================= CURRENT =================
	print("\n-- CURRENT: the arc picks a sensible anchor --")
	var arc := CurrentArc.new()
	var from := Vector2(0, 0)
	var anchors := PackedVector2Array([
		Vector2(300, -120),     # ahead and up: the intended one
		Vector2(-300, -120),    # behind
		Vector2(2000, -200),    # out of range
	])
	var r_fwd := arc.pick(from, Vector2(1, -0.4), anchors)
	_say("picks the anchor you aimed at", r_fwd.found and r_fwd.anchor.x > 0.0,
		str(r_fwd.anchor))
	var r_back := arc.pick(from, Vector2(-1, -0.4), anchors)
	_say("aiming the other way picks the other anchor",
		r_back.found and r_back.anchor.x < 0.0, str(r_back.anchor))
	var r_none := arc.pick(from, Vector2(0, 1), anchors)
	_say("aiming at nothing finds nothing", not r_none.found,
		"found=%s" % str(r_none.found))
	var far_only := PackedVector2Array([Vector2(2000, -200)])
	_say("out-of-range anchors are refused",
		not arc.pick(from, Vector2(1, 0), far_only).found,
		"range=%.0fpx" % arc.range_px)

	print("\n-- CURRENT: attaching pulls you to the anchor --")
	await _idle(20)
	_player.global_position = Vector2(0, FLOOR_Y - 300.0)
	_player.velocity = Vector2.ZERO
	var target := Vector2(420, FLOOR_Y - 460.0)
	_player.anchors = PackedVector2Array([target])
	await get_tree().physics_frame
	var d_before := _player.global_position.distance_to(target)
	_player.vert_axis = -0.4
	_player.move_axis = 1.0
	_player.arc_pressed = true
	await get_tree().physics_frame
	_player.arc_pressed = false
	var attached := _player.arc.is_attached()
	for i in range(90):
		await get_tree().physics_frame
		if not _player.arc.is_attached():
			break
	var d_after := _player.global_position.distance_to(target)
	_say("arc attached", attached)
	_say("arc closed the distance to the anchor", d_after < d_before * 0.5,
		"%.0fpx -> %.0fpx" % [d_before, d_after])

	print("\n-- interaction: a phase breaks an arc (the player asked to get off) --")
	await _idle(20)
	_player.global_position = Vector2(0, FLOOR_Y - 300.0)
	_player.anchors = PackedVector2Array([Vector2(600, FLOOR_Y - 400.0)])
	_player.move_axis = 1.0
	_player.vert_axis = -0.3
	_player.arc_pressed = true
	await get_tree().physics_frame
	_player.arc_pressed = false
	var was_attached := _player.arc.is_attached()
	_player.phase.reset()
	_player.phase_pressed = true
	await get_tree().physics_frame
	_player.phase_pressed = false
	_say("arc was attached before the phase", was_attached)
	_say("phase detached the arc", not _player.arc.is_attached())

	# ---- report
	print("\n%d checks, %d failed." % [_checks, _fails])
	if _checks < 18:
		printerr("PROBE BROKEN: only %d checks ran." % _checks)
		get_tree().quit(2)
		return
	if _fails > 0:
		printerr("%d check(s) failed." % _fails)
		get_tree().quit(1)
		return
	print("all passed.")
	get_tree().quit(0)


func _monotonic_seduction(ph: PhaseDash) -> bool:
	var last_see := 2.0
	var last_evade := -1.0
	var saved: float = ph.attenuation
	var ok := true
	for i in range(11):
		ph.attenuation = float(i) / 10.0
		var s := ph.perception_scale()
		var e := ph.evasion_chance()
		if s > last_see or e < last_evade:
			ok = false
		last_see = s
		last_evade = e
	ph.attenuation = saved
	return ok
