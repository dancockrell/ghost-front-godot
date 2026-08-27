class_name EnemyBrain
extends RefCounted

## Perception and intent for one Werk Nachtigall unit.
##
## THIS IS WHERE ATTENUATION BECOMES REAL. The player's attenuation meter is a
## number on a HUD until something in the world reads it, and this is the thing
## that reads it. Canon: attenuation is not becoming see-through, it is becoming
## a fact for fewer observers -- so it belongs in the OBSERVER, which is here,
## rather than in the player's own movement code.
##
## Two consequences the player should be able to feel without being told:
##   1. a heavily attenuated agent is noticed later, and at shorter range
##   2. once noticed, they are forgotten sooner, because there was less to hold
##
## Awareness is a meter rather than a boolean on purpose. A binary alert flag
## gives the player no way to read how close they are to being seen, which
## turns stealth into a coin flip. A meter is legible, and it lets attenuation
## express itself as a RATE the player can watch respond to their own choices.
##
## States: UNAWARE -> SUSPICIOUS -> ALERT. Attacking is handled by the body,
## not here; this decides only what is known and what is wanted.

enum State { UNAWARE, SUSPICIOUS, ALERT }

var profile: EnemyProfile

## 0..1. Crosses 0.5 into SUSPICIOUS, 1.0 into ALERT.
var awareness: float = 0.0
var state: int = State.UNAWARE
## Where the player was last actually seen. An alerted unit that loses sight
## goes here rather than standing still, which is the difference between a
## guard and a turret.
var last_known := Vector2.ZERO
var has_last_known: bool = false

var _unseen_for: float = 0.0
var _facing: float = 1.0


func _init(p: EnemyProfile = null) -> void:
	profile = p if p != null else EnemyProfile.seuche()


func set_facing(f: float) -> void:
	_facing = signf(f) if absf(f) > 0.01 else _facing


func facing() -> float:
	return _facing


## The range at which this unit can actually notice the player right now.
##
## `perception` is the player's PhaseDash.perception_scale(): 1.0 at zero
## attenuation, falling toward 0.15 at a full meter. Multiplying rather than
## subtracting keeps the relationship proportional, so a long-sighted
## Bestiarium loses more absolute range than a Seuche does -- the better the
## eyes, the more there is to take away.
func effective_range(perception: float) -> float:
	return profile.sight_range * clampf(perception, 0.0, 1.0)


## Can this unit see that point, given the player's current presence?
## `blocked` is supplied by the caller (a raycast), because line of sight is a
## physics query and this class deliberately owns no scene.
func can_see(self_pos: Vector2, target: Vector2, perception: float,
		blocked: bool) -> bool:
	if blocked:
		return false
	var to := target - self_pos
	var d := to.length()
	if d > effective_range(perception):
		return false
	if d < 1.0:
		return true
	var dir := Vector2(_facing, 0.0)
	return dir.dot(to / d) >= cos(profile.sight_cone)


## Advance one frame. Returns the new state.
func step(delta: float, self_pos: Vector2, target: Vector2,
		perception: float, blocked: bool) -> int:
	var seen := can_see(self_pos, target, perception, blocked)

	if seen:
		_unseen_for = 0.0
		last_known = target
		has_last_known = true
		# notice_time is the time to go from nothing to certain, so the rate is
		# its reciprocal. Attenuation does NOT slow this down -- it shortens the
		# range at which it can start. Two separate effects; conflating them
		# would double-count and make a high meter into simple invisibility,
		# which is not what the canon says it is.
		awareness = minf(1.0, awareness + delta / maxf(profile.notice_time, 0.01))
	else:
		_unseen_for += delta
		if _unseen_for >= profile.patience:
			# Forgetting is faster against a faded agent: there was less of them
			# to remember. This is the second half of the seduction and the one
			# a player only notices by escaping more easily than they expected.
			var fade := 1.0 + (1.0 - clampf(perception, 0.0, 1.0)) * 1.5
			awareness = maxf(0.0, awareness - profile.forget_rate * fade * delta)

	if awareness >= 1.0:
		state = State.ALERT
	elif awareness >= 0.5:
		state = State.SUSPICIOUS
	else:
		state = State.UNAWARE
		if awareness <= 0.0:
			has_last_known = false

	return state


## Where the unit wants to be, or null if it has no business anywhere.
func desired_target() -> Variant:
	if state == State.ALERT and has_last_known:
		return last_known
	if state == State.SUSPICIOUS and has_last_known:
		return last_known
	return null


func state_name() -> String:
	match state:
		State.ALERT: return "ALERT"
		State.SUSPICIOUS: return "SUSPICIOUS"
		_: return "UNAWARE"


func reset() -> void:
	awareness = 0.0
	state = State.UNAWARE
	has_last_known = false
	_unseen_for = 0.0
