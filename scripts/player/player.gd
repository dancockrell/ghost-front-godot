class_name Player
extends CharacterBody2D

## The player. All feel lives in `profile`; this file is the machine that
## applies it, and deliberately contains no tuning numbers of its own.
##
## If you find yourself wanting to type a number in here, it belongs in
## MovementProfile instead -- that separation is the thing that stops this
## turning back into the original's 48-round guessing game.

signal jumped(is_air_jump: bool)
signal landed(fall_speed: float)
signal left_ground()

@export var profile: MovementProfile

## Set false to drive the body from a test harness instead of the keyboard.
@export var read_input: bool = true

# ---- intent, written either by input or by a harness.
var move_axis: float = 0.0
var jump_pressed: bool = false      # edge: this frame
var jump_held: bool = false
var down_held: bool = false

# ---- state
var _coyote_left: float = 0.0
var _buffer_left: float = 0.0
var _air_jumps_left: int = 0
var _was_on_floor: bool = true
var _jump_consumed: bool = true     # stops one press firing twice

## Frames since the last landing; handy for animation and for tests.
var airborne_time: float = 0.0


func _ready() -> void:
	if profile == null:
		profile = MovementProfile.new()
	_air_jumps_left = profile.air_jumps


func _physics_process(delta: float) -> void:
	if read_input:
		_gather_input()
	step(delta)
	if read_input:
		jump_pressed = false


func _gather_input() -> void:
	move_axis = Input.get_axis("move_left", "move_right")
	if Input.is_action_just_pressed("jump"):
		jump_pressed = true
	jump_held = Input.is_action_pressed("jump")
	down_held = Input.is_action_pressed("crouch")


## One physics step. Split out from _physics_process so a headless test can
## drive it directly at a fixed delta without a SceneTree or an input device --
## the movement is then testable, which the original's never was.
func step(delta: float) -> void:
	var on_floor := is_on_floor()

	# ---- ledger of ground contact, before anything moves.
	if on_floor:
		if not _was_on_floor:
			landed.emit(velocity.y)
		_coyote_left = profile.coyote_time
		_air_jumps_left = profile.air_jumps
		airborne_time = 0.0
	else:
		if _was_on_floor:
			left_ground.emit()
		_coyote_left = maxf(0.0, _coyote_left - delta)
		airborne_time += delta

	# ---- jump buffering: remember a press made slightly too early.
	if jump_pressed:
		_buffer_left = profile.jump_buffer
		_jump_consumed = false
	else:
		_buffer_left = maxf(0.0, _buffer_left - delta)

	_apply_jump()
	_apply_horizontal(delta, on_floor)
	_apply_gravity(delta, on_floor)

	var before := global_position
	move_and_slide()
	_apply_corner_correction(before)

	_was_on_floor = on_floor


func _apply_jump() -> void:
	if _buffer_left <= 0.0 or _jump_consumed:
		return

	# A ground jump is available while genuinely on the floor OR inside the
	# coyote window. Checking the window rather than the floor is the whole
	# trick: the player who walked off the ledge two frames ago still gets it.
	if _coyote_left > 0.0:
		velocity.y = profile.jump_velocity()
		_coyote_left = 0.0
		_buffer_left = 0.0
		_jump_consumed = true
		jumped.emit(false)
	elif _air_jumps_left > 0:
		velocity.y = profile.air_jump_velocity()
		_air_jumps_left -= 1
		_buffer_left = 0.0
		_jump_consumed = true
		jumped.emit(true)


func _apply_horizontal(delta: float, on_floor: bool) -> void:
	var target := move_axis * profile.max_speed
	var wants_move := absf(move_axis) > 0.01

	var rate: float
	if on_floor:
		rate = profile.ground_accel() if wants_move else profile.ground_decel()
	else:
		rate = profile.air_accel() if wants_move else profile.air_decel()
		# More authority at the apex, so a jump can still be steered at the
		# moment the player is actually looking at where they will land.
		if absf(velocity.y) < profile.apex_threshold:
			rate *= profile.apex_control_boost

	velocity.x = move_toward(velocity.x, target, rate * delta)


func _apply_gravity(delta: float, on_floor: bool) -> void:
	if on_floor and velocity.y >= 0.0:
		# A small downward bias keeps is_on_floor() stable on slopes rather
		# than flickering, which would otherwise refresh coyote time forever.
		velocity.y = 10.0
		return

	var g: float
	if velocity.y < 0.0:
		g = profile.gravity()
		# Variable jump height: releasing early cuts the rise short. Applied
		# once, on the release edge, not continuously.
		if not jump_held:
			velocity.y *= profile.jump_release_cut
			# Re-read: the cut may have moved us into the apex window.
	else:
		g = profile.fall_gravity()
		if down_held:
			g *= profile.fast_fall_multiplier

	# Apex hang: lighter gravity through the slowest part of the arc.
	if absf(velocity.y) < profile.apex_threshold:
		g *= profile.apex_gravity_scale

	velocity.y = minf(velocity.y + g * delta, profile.max_fall_speed)


## Corner correction. If a rising jump is stopped by a ceiling but only a few
## pixels of the head are clipping it, nudge sideways and let the jump through.
## Without this, players bonk on geometry they can see themselves clearing and
## read it as the collision box being wrong -- which it is, but only just.
func _apply_corner_correction(_before: Vector2) -> void:
	if velocity.y >= 0.0 or not is_on_ceiling():
		return
	var step_px := profile.corner_correction
	if step_px <= 0.0:
		return
	for dir in [-1.0, 1.0]:
		for dist in range(1, int(step_px) + 1):
			var offset := Vector2(dir * float(dist), 0.0)
			if not test_move(global_transform.translated(offset), Vector2(0, -1)):
				global_position += offset
				return


## ---- helpers a test or a HUD can read without poking at privates.
func coyote_remaining() -> float:
	return _coyote_left

func buffer_remaining() -> float:
	return _buffer_left

func air_jumps_remaining() -> int:
	return _air_jumps_left
