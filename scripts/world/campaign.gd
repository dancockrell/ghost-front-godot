class_name Campaign
extends RefCounted

## The levels, written in the grammar. Every number here is profile-relative:
## a gap of 0.88 means "88% of a full jump", whatever a full jump currently is.
##
## STRUCTURE: chapters alternate between 1944/45 Europe (Werk installations,
## procurement register) and deep retrievals elsewhere in history (no Werk at
## all). Project 42's defining verb is reaching, not fighting, so the century
## is the variable and the programme is the constant.
##
## Proposed to the lore thread; the alternation and the deep-retrieval settings
## are awaiting a ruling. The MECHANISM below does not depend on the answer --
## if the deep chapters are cut, chapters 1/3/5 stand alone as a campaign, and
## nothing needs rewriting to make that true.
##
## Each level carries its own intent note. A design doc that lives in another
## file goes stale; a note attached to the thing it describes travels with it.


## CHAPTER 1 -- the tutorial that teaches by absence.
##
## The real Ghost Front was a quiet sector where tired units were parked. So
## the first level has almost nothing in it, and that is the design rather than
## a lack of one: teaching movement in a place with no threat means the first
## Werk facility lands as a CHANGE OF REGISTER rather than as level three of a
## shooter. A tutorial that is already tense has spent the contrast it needs
## later.
##
## One Bodenpflege, placed late and alone, so the player meets the vocabulary
## once before the game asks anything of them.
static func quiet_sector() -> LevelSpec:
	return LevelSpec.new("ch1", "THE QUIET SECTOR", "THE ARDENNES, DECEMBER 1944") \
		.note("Teaches: run, jump, coyote, the shape of a gap. Threat is almost "
			+ "absent on purpose -- the contrast is the point, and it is spent "
			+ "in chapter 3.") \
		.ground(2.2) \
		.gap(0.5) \
		.ground(1.6) \
		.gap(0.72) \
		.ground(2.0) \
		.drop(0.5, 1.8) \
		.gap(0.62) \
		.ground(2.4) \
		.enemy("seuche", 1.2) \
		.rise(0.7, 1.6) \
		.ground(1.8) \
		.subject(0.9, 0.55)


## CHAPTER 2 -- the first deep retrieval. No Werk anywhere in it.
##
## A plague year: the edge of the record, which is where the programme can
## reach at all. The hazard is the place. Vertical, cramped, and it teaches
## PHASE because phase is how you get through a building that was not built to
## be moved through.
##
## Attenuation is introduced here with nothing chasing you, so the player can
## feel the meter fill and recover without also being under pressure. The
## seduction is not explained; the level simply has more room than the player
## can reach without spending some.
static func careless_year() -> LevelSpec:
	return LevelSpec.new("ch2", "THE CARELESS YEAR", "A YEAR THE RECORD IS THIN ABOUT") \
		.note("Teaches: phase, and attenuation as a resource you spend. No "
			+ "opposition at all -- the meter should be learned in quiet.") \
		.ground(1.8) \
		.stair(2, 0.72, 0.46) \
		.ceiling(1.5, 1.05) \
		.gap(0.85) \
		.ground(1.4) \
		.stair(3, 0.7, 0.44) \
		.ceiling(1.8, 0.95) \
		.drop(1.4, 2.0) \
		.gap(0.9) \
		.ground(2.2) \
		.subject(1.0, 0.5)


## CHAPTER 3 -- the first Werk installation, and the register changes.
##
## After two quiet chapters this is a building with a filing system in it. The
## opposition arrives properly: Bodenpflege as spatial pressure, a Kurier that
## closes distance and is the reason Phase stops being a traversal tool and
## starts being a defensive one.
##
## Teaches CURRENT. The first gap wider than a full jump is here, with an
## anchor over it -- the level is allowed to demand the arc, and the builder
## asserts it never demands it by accident.
static func collection_point() -> LevelSpec:
	return LevelSpec.new("ch3", "THE COLLECTION POINT", "A WERK FACILITY, 1945") \
		.note("Teaches: current/arc, and Phase as defence rather than movement. "
			+ "First above-jump gap in the campaign, anchored. The register "
			+ "changes here: this is the first place with paperwork in it.") \
		.ground(2.0) \
		.enemy("seuche", 0.9) \
		.gap(0.8) \
		.ground(1.6) \
		.gap(1.25) \
		.anchor(0.62, 1.25) \
		.ground(2.4) \
		.enemy("bestiarium", 1.4) \
		.enemy("seuche", 0.6) \
		.stair(2, 0.75, 0.5) \
		.gap(1.1) \
		.anchor(0.55, 0.9) \
		.ground(2.0) \
		.enemy("kadaver", 1.0) \
		.ceiling(1.6, 1.1) \
		.ground(1.8) \
		.subject(0.9, 0.5)


## CHAPTER 4 -- the set piece, and the clearest statement the campaign makes.
##
## A library fire. A retrieval against a deadline that is NOT a game timer:
## the building is going, the record is going, and the person you came for is
## not the thing burning.
##
## It states "the better documented a life, the more unreachable it is" as a
## level rather than as a line of dialogue -- the programme can only take the
## people history was careless with, and here the carelessness is happening in
## front of you at four hundred degrees.
##
## Mechanically: all three verbs under pressure, no opposition, and the level
## is built tall and collapsing so Chrono matters -- a rewind is how you
## survive a floor that was there a second ago.
static func burning_stacks() -> LevelSpec:
	return LevelSpec.new("ch4", "THE BURNING STACKS", "A FIRE, AND WHAT IT TOOK") \
		.note("Set piece. All three verbs under pressure, no enemies -- the "
			+ "building is the opposition. Chrono carries this level: the "
			+ "rewind is how you survive a floor that was there a second ago.") \
		.ground(1.6) \
		.stair(3, 0.68, 0.42) \
		.gap(1.15) \
		.anchor(0.58, 0.85) \
		.ceiling(1.4, 0.9) \
		.stair(2, 0.74, 0.44) \
		.gap(0.95) \
		.drop(1.8, 1.6) \
		.gap(1.2) \
		.anchor(0.6, 1.3) \
		.ground(1.4) \
		.stair(2, 0.7, 0.5) \
		.ground(2.0) \
		.subject(1.0, 0.5)


## CHAPTER 5 -- Abt. Glocke, and attenuation stops being a resource you manage
## and becomes one you are tempted to spend.
##
## The densest opposition in the campaign, deliberately: a level you cannot
## comfortably fight through at full presence. The seduction is the solution,
## and the floor going away is the price. Nobody tells the player that.
static func bell_house() -> LevelSpec:
	return LevelSpec.new("ch5", "THE BELL HOUSE", "ABT. GLOCKE CALIBRATION SITE") \
		.note("The seduction level. Opposition is dense enough that full "
			+ "presence is the hard way through, so the player discovers the "
			+ "advantage themselves and pays for it themselves. Nobody says so.") \
		.ground(1.8) \
		.enemy("kadaver", 0.9) \
		.ceiling(1.5, 1.0) \
		.enemy("bestiarium", 0.7) \
		.gap(0.9) \
		.ground(2.6) \
		.enemy("seuche", 1.8) \
		.enemy("seuche", 1.2) \
		.enemy("bestiarium", 0.5) \
		.gap(1.3) \
		.anchor(0.65, 1.3) \
		.ground(2.2) \
		.enemy("kadaver", 1.4) \
		.enemy("seuche", 0.6) \
		.stair(3, 0.72, 0.46) \
		.gap(1.05) \
		.anchor(0.52, 0.95) \
		.ground(2.0) \
		.enemy("kadaver", 1.1) \
		.subject(0.8, 0.5)


static func all() -> Array[LevelSpec]:
	var a: Array[LevelSpec] = []
	a.append(quiet_sector())
	a.append(careless_year())
	a.append(collection_point())
	a.append(burning_stacks())
	a.append(bell_house())
	return a


static func by_id(id: String) -> LevelSpec:
	for l in all():
		if l.id == id:
			return l
	return null
