class_name BossSpec
extends Resource

## One of the eight flagship Muster units. A Robot Master, in this universe's
## own vocabulary rather than the genre's.
##
## THE FIGHT IS A PATTERN, NOT A HEALTH BAR. That is the whole of Mega Man boss
## design and it is the thing clones get wrong. A boss you beat by out-damaging
## is a wall; a boss you beat by LEARNING is a lock with a key in the room. So
## every unit here is a short loop of telegraphed actions, the loop is fixed,
## and the difficulty lives in reading it rather than in reacting fast.
##
## Every action telegraphs. That rule already governs the ordinary roster and
## it matters more here, because a boss you cannot read is a boss you beat by
## memorising deaths.
##
## PHASE TWO IS A CHANGE OF PATTERN, NEVER A STAT INCREASE. Doubling the
## damage at half health punishes the player for winning; changing the pattern
## asks them to learn a second thing, which is the same pleasure again.
##
## Canon holds throughout: rule 4, no magic -- every one of these is scalpels,
## cultures, machinery and budget. Rule 5, they are genuinely capable. And the
## Office's register: none of them has a frightening name, because the people
## who made them were not frightened, they were over budget.

class Action extends RefCounted:
	var name: String = ""
	## Seconds of readable wind-up before it commits.
	var telegraph: float = 0.6
	## Seconds the action is dangerous.
	var active: float = 0.3
	## Seconds of vulnerability afterwards. The player's turn.
	var recover: float = 0.5
	var damage: float = 14.0
	## Free text: what the player SEES during the telegraph. Kept with the
	## action rather than in an animation file, because the tell is design.
	var tell: String = ""

	func _init(n: String, tel: float, act: float, rec: float,
			dmg: float, t: String) -> void:
		name = n
		telegraph = tel
		active = act
		recover = rec
		damage = dmg
		tell = t

	func total() -> float:
		return telegraph + active + recover


@export var id: String = ""
## The Office's number. This is its real name.
@export var designation: String = ""
## What the troops call it. Never a monster name.
@export var troop_name: String = ""
## The weapon recovered from it, by id in Arsenal.
@export var grants: String = ""
## Which branch built it.
@export_enum("kadaver", "bestiarium", "seuche") var branch: String = "kadaver"

@export var max_health: float = 300.0
## Contact damage. Present so cornering it is punished, kept low so it is not
## the main threat -- a boss whose body is the danger is a boss you fight by
## standing still.
@export var contact_damage: float = 8.0

## The pattern, in order. Loops.
var pattern: Array = []
## The second pattern, entered below `phase_two_at` of max health.
var pattern_two: Array = []
@export var phase_two_at: float = 0.5

## One line of Office paperwork about this unit, found in its arena. The
## §00 test applies: it must ask, not conclude.
@export var docket: String = ""


func total_cycle() -> float:
	var t := 0.0
	for a in pattern:
		t += a.total()
	return t


## Longest telegraph in the pattern. A floor on this is asserted in the probe:
## if the shortest tell in a fight drops below what a player can act on, the
## fight has stopped being readable.
func shortest_telegraph() -> float:
	var m := 999.0
	for a in pattern:
		m = minf(m, a.telegraph)
	for a in pattern_two:
		m = minf(m, a.telegraph)
	return m if m < 999.0 else 0.0


func longest_recovery() -> float:
	var m := 0.0
	for a in pattern:
		m = maxf(m, a.recover)
	for a in pattern_two:
		m = maxf(m, a.recover)
	return m
