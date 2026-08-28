class_name Arsenal
extends RefCounted

## The eight recovered weapons, and the weakness graph that orders the game.
##
## THE WEAKNESS GRAPH IS THE REAL LEVEL DESIGN in a Mega Man game. It is not
## flavour: it is a hidden difficulty curve the player discovers, and it is the
## reason stage select is a meaningful choice rather than a menu. Get the order
## right and the game is fair; get it wrong and it is a wall.
##
## RULES I HELD MYSELF TO, because a badly built graph ruins the structure:
##
##   1. It must be a single CYCLE covering all eight, so every weapon matters
##      and no unit is a dead end. Asserted in ArsenalProbe.
##   2. No unit is weak to the buster. If the buster solved one, the intended
##      route would be optional and the whole loop would deflate.
##   3. The weakness must be LEGIBLE IN THE FICTION -- fungal culture burns,
##      a surgical frame shorts out, an exoframe seizes in cold. A player who
##      guesses correctly from the bestiary alone has been rewarded for
##      reading, which is the same instinct the requisitions reward.
##
## And the canon constraint that shapes every entry: rule 4, no magic. Every
## weapon here is something the Office actually built out of scalpels,
## cultures, machinery and budget -- so every weapon the player carries is a
## thing that was used on people first.

## id -> the id of the weapon it is weak to.
## One cycle: incendiary -> culture -> frame -> cold -> pressure -> optic
##            -> resonance -> mass -> incendiary
const WEAKNESS := {
	"culture": "incendiary",
	"frame": "culture",
	"cold": "frame",
	"pressure": "cold",
	"optic": "pressure",
	"resonance": "optic",
	"mass": "resonance",
	"incendiary": "mass",
}

## Damage multiplier when a weapon hits the unit weak to it. High on purpose:
## the correct weapon should feel like an answer, not an optimisation.
const WEAKNESS_MULTIPLIER := 4.0


static func incendiary() -> WeaponSpec:
	var w := WeaponSpec.new()
	w.id = "incendiary"
	w.issue_name = "DISPERSAL, INCENDIARY"
	w.recovered_from = "Muster 9"
	w.kind = WeaponSpec.Kind.PLACED
	w.damage = 7.0
	w.speed = 420.0
	w.lifetime = 2.6           # it lingers; that is the point
	w.max_live = 2
	w.cooldown = 0.4
	w.radius = 26.0
	w.max_ammo = 20.0
	w.shake = 0.14
	w.tint = Color(1.0, 0.62, 0.28)
	return w

static func culture() -> WeaponSpec:
	var w := WeaponSpec.new()
	w.id = "culture"
	w.issue_name = "AGENT, BIOLOGICAL, DISPERSED"
	w.recovered_from = "Verfahren Seuche, Muster 4"
	w.kind = WeaponSpec.Kind.PLACED
	w.damage = 4.0
	w.speed = 300.0
	w.lifetime = 4.0
	w.max_live = 3
	w.cooldown = 0.5
	w.radius = 30.0
	w.max_ammo = 16.0
	w.tint = Color(0.72, 0.82, 0.45)
	return w

static func frame() -> WeaponSpec:
	var w := WeaponSpec.new()
	w.id = "frame"
	w.issue_name = "DRIVE, ASSISTED, SHORT"
	w.recovered_from = "Gestell 4"
	w.kind = WeaponSpec.Kind.SWEEP
	w.damage = 26.0
	w.speed = 0.0
	w.lifetime = 0.22
	w.max_live = 1
	w.cooldown = 0.55
	w.radius = 74.0
	w.max_ammo = 14.0
	w.knockback = 420.0
	w.shake = 0.5
	w.hit_stop = 0.07
	w.tint = Color(0.66, 0.70, 0.78)
	return w

static func cold() -> WeaponSpec:
	var w := WeaponSpec.new()
	w.id = "cold"
	w.issue_name = "COOLANT, DIRECTED"
	w.recovered_from = "Muster 11"
	w.damage = 8.0
	w.speed = 760.0
	w.lifetime = 1.3
	w.max_live = 4
	w.cooldown = 0.18
	w.max_ammo = 26.0
	w.tint = Color(0.62, 0.88, 0.96)
	return w

static func pressure() -> WeaponSpec:
	var w := WeaponSpec.new()
	w.id = "pressure"
	w.issue_name = "CHAMBER, LOW PRESSURE"
	w.recovered_from = "Muster 14"
	w.kind = WeaponSpec.Kind.PLACED
	w.damage = 5.0
	w.speed = 200.0
	w.lifetime = 3.0
	w.max_live = 2
	w.cooldown = 0.6
	w.radius = 46.0
	w.max_ammo = 12.0
	w.tint = Color(0.55, 0.58, 0.72)
	return w

static func optic() -> WeaponSpec:
	var w := WeaponSpec.new()
	w.id = "optic"
	w.issue_name = "LAMP, EXAMINATION"
	w.recovered_from = "Muster 2"
	w.kind = WeaponSpec.Kind.BEAM
	w.damage = 20.0
	w.speed = 0.0
	w.lifetime = 0.12
	w.max_live = 1
	w.cooldown = 0.7
	w.radius = 10.0
	w.max_ammo = 10.0
	w.shake = 0.2
	w.tint = Color(1.0, 0.97, 0.86)
	return w

static func resonance() -> WeaponSpec:
	var w := WeaponSpec.new()
	w.id = "resonance"
	w.issue_name = "TONE, CALIBRATION"
	w.recovered_from = "Abt. Glocke rig"
	w.damage = 12.0
	w.speed = 520.0
	w.lifetime = 2.2
	w.max_live = 2
	w.cooldown = 0.3
	w.radius = 16.0
	w.max_ammo = 18.0
	w.tint = Color(0.86, 0.74, 1.0)
	return w

static func mass() -> WeaponSpec:
	var w := WeaponSpec.new()
	w.id = "mass"
	w.issue_name = "SHOT, SOLID, HEAVY"
	w.recovered_from = "Muster 12"
	w.damage = 30.0
	w.speed = 620.0
	w.lifetime = 1.6
	w.max_live = 1
	w.cooldown = 0.65
	w.radius = 18.0
	w.max_ammo = 10.0
	w.knockback = 260.0
	w.shake = 0.42
	w.hit_stop = 0.06
	w.tint = Color(0.80, 0.76, 0.68)
	return w


static func all_recovered() -> Array[WeaponSpec]:
	var a: Array[WeaponSpec] = []
	a.append(incendiary())
	a.append(culture())
	a.append(frame())
	a.append(cold())
	a.append(pressure())
	a.append(optic())
	a.append(resonance())
	a.append(mass())
	return a


static func by_id(id: String) -> WeaponSpec:
	if id == "buster":
		return WeaponSpec.buster()
	for w in all_recovered():
		if w.id == id:
			return w
	return null


## What is this unit weak to? "" if nothing.
static func weakness_of(boss_weapon_id: String) -> String:
	return String(WEAKNESS.get(boss_weapon_id, ""))


## Damage multiplier for `weapon_id` used against a boss whose own weapon is
## `boss_weapon_id`.
static func multiplier(weapon_id: String, boss_weapon_id: String) -> float:
	return WEAKNESS_MULTIPLIER if weakness_of(boss_weapon_id) == weapon_id else 1.0
