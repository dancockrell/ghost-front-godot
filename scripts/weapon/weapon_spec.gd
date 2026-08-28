class_name WeaponSpec
extends Resource

## One weapon in the loadout.
##
## THE MEGA MAN STRUCTURE, AND WHY IT FITS THIS UNIVERSE WITHOUT FORCING.
##
## Mega Man's central loop is: eight numbered products, beat one, take its
## principle, use it on the one that is weak to it. Werk Nachtigall already
## numbers its products -- the Office does not name monsters, it issues Muster
## numbers -- so a roster of eight flagship Muster units is what this faction
## would actually build, not a genre convention bolted onto it.
##
## AND THE WEAPON-STEAL IS THE FACTION'S MORAL BILL, which is the part that
## makes this more than a clone. Canon §5, on Project 42: "Mining history for
## scientific minds is Operation Paperclip with a time machine. The real United
## States granted Shiro Ishii of Unit 731 immunity in exchange for his
## human-experimentation data. THE VICTORS BOUGHT THE RESEARCH."
##
## So you do not "gain a weapon". Camp Iron Bell RECOVERS AN OPERATING
## PRINCIPLE from something it destroyed, and issues it back to you on a form.
## The game never comments on this. The requisitions do, and the player works
## out what they have been carrying.
##
## Per §00: it asks, it does not conclude.

enum Kind {
	## Travels until it leaves the screen or hits. The default.
	PROJECTILE,
	## Short-lived, close, sweeps an arc. Melee-shaped.
	SWEEP,
	## Placed and persists. Mines, cultures, held ground.
	PLACED,
	## Instant along a line. Expensive, exact.
	BEAM,
}

@export var id: String = ""
## What Camp Iron Bell calls it on the issue form. The Office's Muster number
## is on the SOURCE, not on the weapon -- the Allies rename what they take,
## which is its own small piece of characterisation.
@export var issue_name: String = ""
## Which Muster unit it was recovered from. Empty for the base buster.
@export var recovered_from: String = ""

@export var kind: int = Kind.PROJECTILE
@export var damage: float = 10.0
@export var speed: float = 900.0
@export var lifetime: float = 1.4
## Shots on screen at once. Mega Man's three-shot cap is a real design choice:
## it forces spacing and rhythm rather than a held trigger.
@export var max_live: int = 3
@export var cooldown: float = 0.14
## Radius for collision, px.
@export var radius: float = 9.0

@export_group("Ammunition")
## Base weapon is unlimited. Everything recovered is metered, which is what
## makes choosing one a decision rather than an upgrade.
@export var unlimited: bool = false
@export var max_ammo: float = 28.0
@export var ammo_per_shot: float = 1.0

@export_group("Charge")
@export var can_charge: bool = false
@export var charge_time: float = 0.95
@export var charge_damage: float = 34.0
@export var charge_radius: float = 20.0

@export_group("Feel")
@export var knockback: float = 0.0
@export var shake: float = 0.0
## Seconds of hit stop when this LANDS. Only for the player's own hits --
## freezing on damage taken removes the controls when they are most wanted.
@export var hit_stop: float = 0.0
@export var tint: Color = Color(0.75, 0.93, 1.0)


## THE BUSTER. Current, which is Project 42's third pillar, made into a gun.
##
## The bible: Current runs on theory the programme does not fully understand,
## taken from papers seized after Tesla's death. So the primary weapon of the
## whole game is built on a dead man's work that nobody at Camp Iron Bell can
## explain, and it is the one thing you never run out of.
static func buster() -> WeaponSpec:
	var w := WeaponSpec.new()
	w.id = "buster"
	w.issue_name = "ARC, HAND, MK II"
	w.recovered_from = ""
	w.damage = 9.0
	w.speed = 1150.0
	w.lifetime = 1.1
	w.max_live = 3
	w.cooldown = 0.13
	w.unlimited = true
	w.can_charge = true
	w.charge_time = 0.95
	w.charge_damage = 34.0
	w.charge_radius = 22.0
	w.shake = 0.06
	w.hit_stop = 0.02
	w.tint = Color(0.78, 0.94, 1.0)
	return w
