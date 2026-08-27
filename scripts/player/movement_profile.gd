class_name MovementProfile
extends Resource

## The feel of the game, stated as design intent rather than as physics.
##
## The original Ghost Front tuned movement through constants like MANK=26/17
## and FEELJ=1.10, layered over base numbers, rounded, then multiplied by a
## screen scale. It took 48 rounds partly because nobody -- including its
## author, judging by the comments -- could predict what changing one would do.
## A comment in it annotates the derived jump as -290 when the code produces
## 289, and the error went unnoticed because no one could check it by reading.
##
## So this asks for the two numbers a designer can actually picture:
##
##     jump_height     how high he gets, in pixels. Look at the character,
##                     look at the ledge, pick a number.
##     time_to_apex    how long it takes, in seconds. This is the weight dial.
##                     Short = twitchy and arcade. Long = heavy and dreadful.
##
## and derives the rest, which is standard projectile motion:
##
##     gravity        = 2 * jump_height / time_to_apex^2
##     jump_velocity  = -2 * jump_height / time_to_apex
##
## Change jump_height and only the height changes. Change time_to_apex and only
## the weight changes. That is the whole point: the knobs are orthogonal, so
## tuning converges instead of wandering.
##
## Everything below the derivation is the modern platformer forgiveness kit --
## coyote time, jump buffering, variable height, asymmetric gravity, apex hang,
## corner correction. None of it is optional in a game that expects precision;
## a player reads its absence as the game being unfair rather than as the game
## being strict.

@export_group("The two that matter")
## How high a full jump reaches, in pixels. The character is 150px tall, so
## 210 is about 1.4 body heights -- deliberately grounded, and it keeps jump
## DISTANCE at ~1.8x jump HEIGHT, which is the ratio real platformers use.
## Jumping higher than you travel reads as moon-jumping. He has a body.
@export var jump_height: float = 210.0
## Seconds from leaving the floor to the top of the arc. The weight dial.
## 0.38 is inherited from the original -- the one number 48 rounds of tuning
## actually established, and worth keeping when the implementation is not.
@export var time_to_apex: float = 0.38

@export_group("Falling")
## Fall gravity as a multiple of rise gravity. >1 means he drops faster than he
## rose, which reads as weight and shortens the dead time at the top of a jump.
@export var fall_gravity_multiplier: float = 1.45
## Terminal velocity, px/s. Caps long drops so they stay readable.
@export var max_fall_speed: float = 1400.0
## Extra downward pull while holding down in the air.
@export var fast_fall_multiplier: float = 1.9

@export_group("Running")
## Top horizontal speed, px/s.
@export var max_speed: float = 540.0
## Time in seconds to reach top speed from a standstill, on the ground.
@export var ground_accel_time: float = 0.10
## Time in seconds to stop from top speed, on the ground.
@export var ground_decel_time: float = 0.08
## Same two, in the air. Slower, so a committed jump stays committed.
@export var air_accel_time: float = 0.18
@export var air_decel_time: float = 0.26

@export_group("Forgiveness")
## Seconds after walking off a ledge during which a jump still works.
## Below ~0.06 players report "it didn't take my input" without knowing why.
@export var coyote_time: float = 0.10
## Seconds before landing during which a jump press is remembered.
@export var jump_buffer: float = 0.12
## On releasing jump while rising, vertical speed is cut to this fraction.
## This is variable jump height: a tap is a hop, a hold is the full arc.
@export var jump_release_cut: float = 0.45
## Near the top of the arc, gravity is scaled by this and air control rises.
## The "hang" that makes an apex feel deliberate rather than like a stall.
@export var apex_gravity_scale: float = 0.55
## Vertical speed below which the apex window applies, px/s.
@export var apex_threshold: float = 130.0
## Air control multiplier inside the apex window.
@export var apex_control_boost: float = 1.35
## Max pixels to nudge sideways when a jump clips a corner on the way up.
## Without this, players bonk on geometry they visibly cleared.
@export var corner_correction: float = 12.0

@export_group("Air jumps")
## Jumps available after the first. 0 for a strict single-jump game.
@export var air_jumps: int = 1
## Second-jump height as a fraction of the first. Under 1 keeps it a
## deliberate kick rather than a hover.
@export var air_jump_scale: float = 0.76


# ---- derived. Read these; never set them.

## Rise gravity, px/s^2.
func gravity() -> float:
	return (2.0 * jump_height) / (time_to_apex * time_to_apex)

## Fall gravity, px/s^2.
func fall_gravity() -> float:
	return gravity() * fall_gravity_multiplier

## Launch velocity, px/s. Negative because Godot's +Y is down.
func jump_velocity() -> float:
	return -(2.0 * jump_height) / time_to_apex

func air_jump_velocity() -> float:
	return jump_velocity() * air_jump_scale

## Time from apex back to the launch height, given the heavier fall gravity.
func time_to_fall() -> float:
	return sqrt((2.0 * jump_height) / fall_gravity())

## Total hang time for a full jump returning to the same height.
func total_air_time() -> float:
	return time_to_apex + time_to_fall()

## Horizontal distance covered by a full jump at top speed. The number that
## decides whether a gap is crossable, so it belongs in level design docs.
func jump_distance() -> float:
	return max_speed * total_air_time()

func ground_accel() -> float:
	return max_speed / maxf(ground_accel_time, 0.0001)

func ground_decel() -> float:
	return max_speed / maxf(ground_decel_time, 0.0001)

func air_accel() -> float:
	return max_speed / maxf(air_accel_time, 0.0001)

func air_decel() -> float:
	return max_speed / maxf(air_decel_time, 0.0001)

## A one-line summary for logs and the debug overlay.
func describe() -> String:
	return ("h=%.0fpx apex=%.3fs -> grav=%.0f jump_v=%.0f | fall_grav=%.0f "
		+ "air_time=%.3fs jump_dist=%.0fpx") % [
			jump_height, time_to_apex, gravity(), jump_velocity(),
			fall_gravity(), total_air_time(), jump_distance()]
