class_name PhaseDash
extends RefCounted

## PHASE -- go briefly intangible.
##
## Project 42's second pillar. A short dash that passes through thin matter and
## through enemies: movement and defence on one button, which keeps the game
## aggressive rather than turning defence into waiting.
##
## THE COST IS THE POINT, and it is the lore thread's, not mine.
## Canon (LORE-BIBLE §5, ruled 27 Aug 2026): men who phase too often stop being
## reliably *here*, and the programme's medical files call it ATTENUATION.
##
## THE CRUCIAL CORRECTION, and it is what makes this a mechanic worth having.
## Attenuation is NOT becoming see-through. It is becoming **a fact for fewer
## observers** -- and there is no floor, and nobody knows where it ends.
##
## So the meter is not a penalty bar. It is SEDUCTIVE:
##
##   as you attenuate, the world perceives you less
##   -> enemies notice you later, track you worse, hit you less
##   -> you are genuinely more effective the further gone you are
##
##   and the same slippage takes the floor away
##   -> above the threshold you phase INVOLUNTARILY, dropping through matter
##      you meant to stand on
##
## The soldier furthest along is the most effective one in the room, right up
## until they are not in the room at all. A resource a player is tempted to
## spend toward their own erasure is worth ten they merely manage -- the horror
## is doing mechanical work rather than being narrated alongside it.
##
## Camp Iron Bell knows what repeated phasing does. The handler does not
## mention it. That is the programme's actual lie, and it is about
## survivability rather than about geography.

## Seconds the dash lasts.
var dash_time: float = 0.16
## Dash speed, px/s.
var dash_speed: float = 1150.0
## Minimum seconds between dashes.
var cooldown: float = 0.28

## --- attenuation
var attenuation_enabled: bool = true
## Attenuation added per dash, as a fraction of the meter.
var cost: float = 0.22

## Multiplier on that cost, set by the level. Used for the escort leg.
##
## THE ESCORT RULE, and it is flagged rather than asserted because it is an
## inference from canon rather than canon itself. Established: phasing
## attenuates the person doing it. NOT established: what happens when the agent
## phases while carrying someone. Two defensible readings --
##
##   (a) the subject is dragged through the same slippage, so the cost doubles
##       and the player is spending someone else's coherence to save their own
##   (b) the subject is simply not phased, and the ability is unavailable
##
## (a) is implemented, because it preserves the choice and asks a question,
## where (b) hands down a verdict by removing the option. It also puts the
## player's best defensive tool behind a cost exactly when they most want it,
## which is the tension the extraction leg is for.
##
## Submitted to the lore thread. If (b) is ruled, set this very high or gate
## try_dash() instead; nothing else in the design depends on which way it goes.
var cost_multiplier: float = 1.0
## Fraction of the meter recovered per second while not phasing.
var recovery: float = 0.16
## Above this, involuntary phasing begins.
var unstable_at: float = 0.75
## At full attenuation, expected involuntary phases per second.
var flicker_rate: float = 2.2

## --- the seductive half. How much the world stops perceiving you.
## Enemy detection range is multiplied by (1 - attenuation * perception_falloff),
## so at a full meter with the default you are noticed at 15% of normal range.
var perception_falloff: float = 0.85
## Chance an incoming hit simply fails to land on you, at a full meter.
var evasion_at_full: float = 0.6

var attenuation: float = 0.0

var _time_left: float = 0.0
var _cd_left: float = 0.0
var _dir := Vector2.RIGHT
var _flicker: bool = false
var _rng := RandomNumberGenerator.new()


func _init(seed_value: int = 0) -> void:
	if seed_value != 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()


func is_dashing() -> bool:
	return _time_left > 0.0


## True when the body should currently ignore solid matter -- either because a
## dash is in progress, or because attenuation has taken the choice away.
func is_intangible() -> bool:
	return is_dashing() or _flicker


func is_unstable() -> bool:
	return attenuation_enabled and attenuation >= unstable_at


## --- THE SEDUCTION. Read by enemies, not by the player's own movement.

## Multiplier an enemy should apply to its own detection range when looking for
## this player. Falls toward zero as attenuation rises.
func perception_scale() -> float:
	if not attenuation_enabled:
		return 1.0
	return clampf(1.0 - attenuation * perception_falloff, 0.0, 1.0)

## Chance in 0..1 that an incoming hit fails to land, because there is less of
## the player present for it to land on.
func evasion_chance() -> float:
	if not attenuation_enabled:
		return 0.0
	return clampf(attenuation * evasion_at_full, 0.0, 1.0)

## Roll the above. Enemies call this rather than reading the chance directly,
## so the RNG stays in one place and a test can seed it.
func hit_evaded() -> bool:
	return _rng.randf() < evasion_chance()


func can_dash() -> bool:
	return _cd_left <= 0.0 and _time_left <= 0.0


func reset() -> void:
	attenuation = 0.0
	_time_left = 0.0
	_cd_left = 0.0
	_flicker = false


## Ask for a dash. Returns true if one started.
func try_dash(direction: Vector2) -> bool:
	if not can_dash():
		return false
	_dir = direction.normalized()
	if _dir == Vector2.ZERO:
		_dir = Vector2.RIGHT
	_time_left = dash_time
	_cd_left = dash_time + cooldown
	if attenuation_enabled:
		attenuation = clampf(attenuation + cost * cost_multiplier, 0.0, 1.0)
	return true


## Drive one physics frame. Returns {velocity_override: Vector2 or null}.
func step(delta: float) -> Dictionary:
	_cd_left = maxf(0.0, _cd_left - delta)

	if _time_left > 0.0:
		_time_left = maxf(0.0, _time_left - delta)
		return {"override": _dir * dash_speed}

	if attenuation_enabled:
		# Recovery only runs when not phasing, so spamming the dash genuinely
		# accumulates rather than washing out between uses.
		attenuation = clampf(attenuation - recovery * delta, 0.0, 1.0)

		# Involuntary phasing above the threshold. Probability ramps from 0 at
		# the threshold to flicker_rate at a full meter, so crossing the line
		# is a warning rather than an instant loss of the floor.
		_flicker = false
		if attenuation >= unstable_at:
			var over := (attenuation - unstable_at) / maxf(1.0 - unstable_at, 0.0001)
			if _rng.randf() < flicker_rate * over * delta:
				_flicker = true
	else:
		_flicker = false

	return {"override": null}
