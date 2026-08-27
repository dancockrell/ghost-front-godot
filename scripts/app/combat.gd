class_name Combat
extends RefCounted

## Resolution between a Werk strike and the agent.
##
## Deliberately a free function rather than logic inside Enemy or Player.
## Neither should reach into the other -- the enemy asks "am I striking", the
## player asks "is there less of me than there was", and this decides. Keeping
## it here also means the one place attenuation converts into survival is a
## single readable function rather than a rule spread across two classes.
##
## THE HONEST CHANNEL. Everything here reads the TRUE attenuation, never
## FieldReadout's version. The form understates; the world does not, and this
## is the world. If a future change routes any of this through the readout,
## attenuation stops being a real advantage and becomes a cosmetic one, and the
## player's central decision quietly stops mattering.

## Outcome of one strike landing on the agent.
class Result extends RefCounted:
	var hit: bool = false
	var damage: float = 0.0
	var evaded: bool = false
	## True when the strike missed because there was less of the agent present
	## for it to land on, as opposed to missing on range or timing.
	var evaded_by_attenuation: bool = false


## Resolve one enemy strike.
##
## `in_reach` is supplied by the caller after a distance check, so this stays
## testable without a physics world.
static func resolve_strike(enemy: Enemy, phase: PhaseDash,
		in_reach: bool) -> Result:
	var r := Result.new()
	if enemy == null or not enemy.is_striking() or not in_reach:
		return r

	# Phasing outright: a strike cannot land on something not currently made of
	# anything. This is the deliberate use of the verb, and it is absolute.
	if phase != null and phase.is_intangible():
		r.evaded = true
		return r

	# And the involuntary version, which is the seduction paying out. The
	# further gone the agent, the more often a real blow simply fails to find
	# enough of them. The player never chose this; they only chose to phase a
	# lot, which is the whole trap.
	if phase != null and phase.hit_evaded():
		r.evaded = true
		r.evaded_by_attenuation = true
		return r

	r.hit = true
	r.damage = enemy.profile.damage
	return r


## Expected fraction of strikes that land, at a given attenuation. Used by the
## probe to assert the curve rather than sample it, and useful for tuning.
static func expected_hit_rate(phase: PhaseDash, attenuation: float) -> float:
	var saved := phase.attenuation
	phase.attenuation = attenuation
	var e := phase.evasion_chance()
	phase.attenuation = saved
	return 1.0 - e
