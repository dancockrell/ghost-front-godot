class_name BossRoster
extends RefCounted

## The eight. Written to the Office's register throughout: none of these has a
## frightening name, because the people who built them were not frightened,
## they were over budget and slightly behind schedule.
##
## Each grants the weapon recovered from it, and each is weak to exactly one
## other's, in a single cycle. See Arsenal.WEAKNESS.
##
## Reading order is the intended clockwise route; the player is never told it.

static func _a(n: String, tel: float, act: float, rec: float, dmg: float,
		tell: String) -> BossSpec.Action:
	return BossSpec.Action.new(n, tel, act, rec, dmg, tell)


## MUSTER 9 -- the dispersal frame. Abt. Chemie mounted a sprayer inside a
## greatcoat because the effect was better that way, and the finding is filed.
static func muster_9() -> BossSpec:
	var b := BossSpec.new()
	b.id = "m9"
	b.designation = "Muster 9"
	b.troop_name = "the coat"
	b.grants = "incendiary"
	b.branch = "seuche"
	b.max_health = 280.0
	b.pattern = [
		_a("sweep", 0.75, 0.4, 0.6, 14.0, "the sleeves fill before it turns"),
		_a("douse", 0.6, 1.1, 0.5, 9.0, "a wet line runs the floor toward you"),
		_a("step", 0.4, 0.2, 0.35, 10.0, "it walks; it does not hurry"),
	]
	b.pattern_two = [
		_a("sweep", 0.6, 0.5, 0.45, 14.0, "the same tell, sooner"),
		_a("douse", 0.5, 1.4, 0.4, 9.0, "two lines now, and they cross"),
	]
	b.docket = "Abt. Chemie dispersal frame, mounted inside a greatcoat for "  \
		+ "the effect. Nothing in the sleeves but the rig. The effect works. "  \
		+ "That is the finding."
	return b


## VERFAHREN SEUCHE, MUSTER 4 as a flagship. The culture at scale: it does not
## fight you, it makes the room unavailable one square at a time.
static func muster_4() -> BossSpec:
	var b := BossSpec.new()
	b.id = "m4"
	b.designation = "Verfahren Seuche, Muster 4"
	b.troop_name = "the proving floor"
	b.grants = "culture"
	b.branch = "seuche"
	b.max_health = 250.0
	b.contact_damage = 6.0
	b.pattern = [
		_a("bloom", 0.8, 1.6, 0.7, 8.0, "the smell of bread arrives first"),
		_a("creep", 0.5, 2.0, 0.4, 6.0, "the floor goes soft where it has been"),
		_a("settle", 0.6, 0.3, 0.9, 0.0, "it stops, which is when you can hurt it"),
	]
	b.pattern_two = [
		_a("bloom", 0.65, 2.2, 0.5, 8.0, "the smell arrives late now"),
		_a("creep", 0.45, 2.6, 0.35, 6.0, "less floor each time"),
	]
	b.docket = "Yield continues to improve against projection. Attrition is "  \
		+ "within tolerance and is, per the doctrine adopted 1942, an input "  \
		+ "rather than a loss."
	return b


## GESTELL 4 -- the exoframe, and it is still funny. It does not work well. A
## decade of estimates purchased this and nobody will write down that it walks
## worse than a man.
static func gestell_4() -> BossSpec:
	var b := BossSpec.new()
	b.id = "g4"
	b.designation = "Gestell 4"
	b.troop_name = "the walker"
	b.grants = "frame"
	b.branch = "bestiarium"
	b.max_health = 380.0
	b.contact_damage = 12.0
	b.pattern = [
		_a("stamp", 1.15, 0.3, 1.0, 24.0, "it leans back a long way first"),
		_a("haul", 0.9, 0.6, 0.8, 16.0, "one leg drags before it swings"),
		_a("stall", 0.5, 0.0, 1.4, 0.0, "it stops working. It does this a lot."),
	]
	b.pattern_two = [
		_a("stamp", 1.0, 0.35, 0.9, 24.0, "the same lean"),
		_a("vent", 0.7, 0.9, 1.1, 12.0, "steam, and a man shouting inside it"),
	]
	b.docket = "The unit remains in the field at grid reference appended. "  \
		+ "Recovery has been costed twice and declined twice. The occupant is "  \
		+ "entered on the establishment as present."
	return b


## MUSTER 11 -- the cold rig. Dr. med. H. Krantz put her own name on the
## requisition, which is the detail that does the work.
static func muster_11() -> BossSpec:
	var b := BossSpec.new()
	b.id = "m11"
	b.designation = "Muster 11"
	b.troop_name = "the dome"
	b.grants = "cold"
	b.branch = "kadaver"
	b.max_health = 300.0
	b.pattern = [
		_a("chill", 0.7, 0.9, 0.6, 12.0, "frost crawls out along the floor"),
		_a("lance", 0.55, 0.25, 0.7, 18.0, "one arm draws back and locks"),
		_a("vent", 0.9, 0.5, 1.0, 8.0, "the dome opens and it is slow to shut"),
	]
	b.pattern_two = [
		_a("chill", 0.6, 1.2, 0.5, 12.0, "the frost reaches further"),
		_a("lance", 0.45, 0.3, 0.6, 18.0, "faster to draw, same lock"),
		_a("vent", 0.8, 0.6, 0.85, 8.0, "still slow to shut"),
	]
	b.docket = "Freiwillige Chirurgin. She put her own name on the "  \
		+ "requisition. Smith carried that requisition sixty miles on foot so "  \
		+ "somebody would read it."
	return b


## MUSTER 14 -- the pressure chamber. A rig for measuring what a person can
## take, walking.
static func muster_14() -> BossSpec:
	var b := BossSpec.new()
	b.id = "m14"
	b.designation = "Muster 14"
	b.troop_name = "the chamber"
	b.grants = "pressure"
	b.branch = "kadaver"
	b.max_health = 320.0
	b.pattern = [
		_a("draw", 0.85, 1.2, 0.7, 10.0, "the air goes toward it before you do"),
		_a("crush", 0.65, 0.3, 0.9, 22.0, "the gauge tops out and holds"),
		_a("reset", 0.5, 0.0, 1.2, 0.0, "it recalibrates. It has to."),
	]
	b.pattern_two = [
		_a("draw", 0.7, 1.5, 0.55, 10.0, "it pulls harder"),
		_a("crush", 0.55, 0.35, 0.75, 22.0, "the gauge does not come down"),
	]
	b.docket = "The rig measures what the subject can take. The figure is "  \
		+ "entered. The subject is not entered, being an input rather than an "  \
		+ "item of equipment."
	return b


## MUSTER 2 -- the examination lamp. Early number, still in service, because
## replacing it would require somebody to justify replacing it.
static func muster_2() -> BossSpec:
	var b := BossSpec.new()
	b.id = "m2"
	b.designation = "Muster 2"
	b.troop_name = "the lamp"
	b.grants = "optic"
	b.branch = "kadaver"
	b.max_health = 240.0
	b.pattern = [
		_a("track", 0.6, 0.8, 0.5, 6.0, "the beam finds you and stays"),
		_a("burn", 0.8, 0.35, 0.8, 20.0, "the beam stops moving. That is the tell."),
		_a("blink", 0.45, 0.0, 0.9, 0.0, "it goes dark while it cycles"),
	]
	b.pattern_two = [
		_a("track", 0.5, 1.0, 0.4, 6.0, "harder to leave"),
		_a("burn", 0.65, 0.4, 0.65, 20.0, "same tell, less of it"),
		_a("blink", 0.4, 0.0, 0.7, 0.0, "shorter dark"),
	]
	b.docket = "Muster 2 remains in service. A submission to replace it was "  \
		+ "returned for want of a stated deficiency. No deficiency has been "  \
		+ "stated."
	return b


## ABT. GLOCKE'S CALIBRATION RIG. It has been measuring since the eleventh
## ring because the instruction to stop would require a countersignature.
static func glocke_rig() -> BossSpec:
	var b := BossSpec.new()
	b.id = "gl"
	b.designation = "Abt. Glocke calibration rig"
	b.troop_name = "the pendulum"
	b.grants = "resonance"
	b.branch = "kadaver"
	b.max_health = 340.0
	b.pattern = [
		_a("swing", 0.7, 0.9, 0.6, 16.0, "the arm goes up on the far side first"),
		_a("ring", 1.0, 0.5, 0.9, 12.0, "everything metal in the room agrees"),
		_a("measure", 0.6, 0.0, 1.1, 0.0, "it writes the figure down"),
	]
	b.pattern_two = [
		_a("swing", 0.6, 1.1, 0.5, 16.0, "a shorter arc, more often"),
		_a("ring", 0.85, 0.7, 0.75, 12.0, "and the room agrees for longer"),
	]
	b.docket = "The rig has run continuously since the eleventh ring. No "  \
		+ "instruction to stop has been received. The officer who "  \
		+ "countersigned the start is no longer at this establishment."
	return b


## MUSTER 12 -- a patient, at flagship scale. The slowest thing in the game and
## the one that hurts most, which is the joke made mechanical.
static func muster_12() -> BossSpec:
	var b := BossSpec.new()
	b.id = "m12"
	b.designation = "Muster 12"
	b.troop_name = "the ward"
	b.grants = "mass"
	b.branch = "kadaver"
	b.max_health = 420.0
	b.contact_damage = 14.0
	b.pattern = [
		_a("advance", 0.5, 0.6, 0.4, 10.0, "it walks the way a man walks a corridor"),
		_a("bring down", 1.1, 0.3, 1.1, 30.0, "both arms come up and stay up"),
		_a("settle", 0.6, 0.0, 1.3, 0.0, "the mountings need a moment"),
	]
	b.pattern_two = [
		_a("advance", 0.45, 0.7, 0.35, 10.0, "same walk"),
		_a("bring down", 0.95, 0.35, 0.95, 30.0, "same arms"),
		_a("sweep", 0.8, 0.5, 0.8, 22.0, "a new one, and it is wider"),
	]
	b.docket = "Post-operative, ambulatory. Entered as fit for duty on the "  \
		+ "ninth occasion. The chest has been opened and closed nine times "  \
		+ "and the mountings are noted as a recurring cost."
	return b


static func all() -> Array[BossSpec]:
	var a: Array[BossSpec] = []
	a.append(muster_9())
	a.append(muster_4())
	a.append(gestell_4())
	a.append(muster_11())
	a.append(muster_14())
	a.append(muster_2())
	a.append(glocke_rig())
	a.append(muster_12())
	return a


static func by_id(id: String) -> BossSpec:
	for b in all():
		if b.id == id:
			return b
	return null
