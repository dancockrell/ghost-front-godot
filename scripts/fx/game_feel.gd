class_name GameFeel
extends RefCounted

## Screen shake, hit stop, and impact flash.
##
## The cheapest large improvement available to any action game, and the one
## most often done badly. Two rules govern everything here:
##
## 1. **Hit stop is for the player's hits, not the player's injuries.** Freezing
##    the frame when the player is hit takes the controls away at the moment
##    they most want them. Freeze on connection, never on damage taken.
##
## 2. **Shake has to decay fast and never rotate.** A slow shake reads as a
##    rumble pack; rotation makes people motion-sick and destroys the
##    readability of a platformer's horizon line. Translate only, and be gone
##    inside a fifth of a second.
##
## Written rather than imported: this is forty lines and importing it would
## mean auditing somebody's licence forever. See docs/RESOURCES.md.

## Peak offset in pixels for a unit-strength shake.
var shake_px: float = 9.0
## Seconds for a shake to decay to nothing.
var shake_decay: float = 0.18
## Hard cap so a pile-up of events cannot blind the player.
var shake_ceiling: float = 1.0

var _shake: float = 0.0
var _stop_left: float = 0.0
var _rng := RandomNumberGenerator.new()


func _init(seed_value: int = 0) -> void:
	if seed_value != 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()


## Add shake. `amount` is 0..1; several sources add and are then clamped, so a
## busy moment cannot stack into an unplayable screen.
func add_shake(amount: float) -> void:
	_shake = clampf(_shake + amount, 0.0, shake_ceiling)


## Freeze for `secs`. Call on a landed hit; do NOT call when the player is hit.
func hit_stop(secs: float) -> void:
	_stop_left = maxf(_stop_left, secs)


func is_stopped() -> bool:
	return _stop_left > 0.0


func shake_amount() -> float:
	return _shake


## Advance. Returns the camera offset to apply this frame.
##
## `delta` must be UNSCALED real time. Driving this from a delta that is itself
## being frozen means the freeze never ends -- the classic hit-stop deadlock,
## and it looks exactly like the game hanging.
func step(unscaled_delta: float) -> Vector2:
	if _stop_left > 0.0:
		_stop_left = maxf(0.0, _stop_left - unscaled_delta)

	if _shake <= 0.0:
		return Vector2.ZERO

	_shake = maxf(0.0, _shake - unscaled_delta / maxf(shake_decay, 0.001))
	# Squared falloff so the tail is short and the peak still reads.
	var mag := _shake * _shake * shake_px
	return Vector2(
		_rng.randf_range(-mag, mag),
		_rng.randf_range(-mag, mag) * 0.6)   # less vertical: the horizon matters


## Suggested strengths, kept in one place so the whole game shakes on one scale
## rather than each call site inventing a number.
const SHAKE_LIGHT := 0.25     # a Seuche connects
const SHAKE_SOLID := 0.5      # a Bestiarium connects
const SHAKE_HEAVY := 0.9      # a Kadaver connects
const STOP_LIGHT := 0.04
const STOP_HEAVY := 0.09
