class_name EnemyProfile
extends Resource

## One Werk Nachtigall archetype, as tunable data.
##
## THE DESIGN DRIVER, and it is canon rather than my invention: rule 4 says the
## Germans get no magic, and the lore thread reframed that from a restriction
## into a MOTIVATION. They get none because they *could not get any*. Locked out
## of the geometry and out of contact, they brute-force with meat and machinery
## what the other two factions get elegantly. They are the control group in
## their own experiment, they know it, and it makes them worse.
##
## That has a direct mechanical reading and it is the spine of every archetype
## below: **nothing they do is elegant.** No teleports, no phasing, no
## rewinding. They cover ground by running at you, they reach you with mass,
## and they solve problems by applying more of themselves. Where the player has
## three verbs, the Werk has weight, numbers and patience.
##
## Every attack telegraphs. A tell you can read is what separates a fair death
## from a cheap one, and it is the one thing the old build got right.

@export_group("Identity")
## Which branch of the Reichsamt. Canon: Kadaver (surgical), Bestiarium
## (grafts and powered frames), Seuche (fungal).
@export_enum("kadaver", "bestiarium", "seuche") var branch: String = "seuche"

## THE TWO-NAME RULE (WORLD-BESTIARY.md §1), and it is structural rather than
## flavour, so it is two fields rather than one string.
##
## `designation` is what the Office calls it: a Muster number inside a
## procedure, on a form, in the estimates. THE OFFICE DOES NOT NAME MONSTERS,
## IT NUMBERS PRODUCTS. Nothing it makes was ever given a frightening name by
## the people who made it -- to them it is late, or over budget, or performing
## to projection.
##
## `troop_name` is what Allied soldiers coined, fast, for a smell or a sound or
## a joke. Short, ugly, English.
##
## Where possible the troop name is ACCIDENTALLY TRUE, and that is the best
## thing in the bestiary. "Patients" is the worked example: the troops mean it
## as a joke about how slowly the thing moves, and the Office means it because
## the thing came out of a surgical theatre and that is what the form says.
## Two meanings on one word and neither side knows the other uses it.
##
## Both names must be reachable in play or the joke is inert -- the Office one
## through found paperwork, the troop one through the handler. A player who
## only ever hears one has been given a codeword.
@export var designation: String = ""
@export var troop_name: String = ""

@export_group("Body")
@export var max_health: float = 100.0
@export var move_speed: float = 120.0
@export var mass_knockback: float = 1.0   # <1 = heavy, shrugs off hits

@export_group("Perception")
## How far it can notice the player at full presence, px. Attenuation scales
## this down -- see EnemyBrain.effective_range().
@export var sight_range: float = 620.0
## Half-angle of the vision cone, radians.
@export var sight_cone: float = 0.9
## Seconds of continuous sight needed to go from unaware to fully aware.
@export var notice_time: float = 0.55
## Seconds of no sight before awareness starts draining.
@export var patience: float = 2.4
## How fast awareness drains once patience runs out, per second.
@export var forget_rate: float = 0.5

@export_group("Attack")
@export var attack_range: float = 90.0
## THE TELEGRAPH. Seconds of visible wind-up before the strike lands.
## This is the single most important number in the file.
@export var windup: float = 0.55
## Seconds the strike itself is active.
@export var strike: float = 0.14
## Seconds of vulnerable recovery after a strike. This is the player's window,
## so it is a difficulty dial with a clear meaning.
@export var recover: float = 0.45
@export var damage: float = 20.0

@export_group("Tells")
## THE BREAD SMELL, and the reason it is a field rather than a texture choice.
##
## Muster 4 ("bakers") announce themselves by smell -- warm, yeasty, entirely
## wrong -- and the men learned to read it. Muster 6 ("the quiet ones") are the
## same procedure late-stage, and THEY DO NOT SMELL OF BREAD. That is how you
## know it is a six and not a four, it was learned the hard way, and it is in
## no manual.
##
## So the ABSENCE of a tell is a second enemy for almost no work, and it only
## functions if the two are otherwise hard to tell apart. EnemyProbe asserts
## that similarity deliberately: if a Muster 6 were obviously different in
## other ways, the missing tell would carry nothing.
@export var has_proximity_tell: bool = false
## Radius at which the tell becomes readable, px.
@export var tell_radius: float = 260.0

## THE WHISTLE. Baureihe 7 do not hunt, they ANSWER -- troops worked that out
## in the field before intelligence did, and somewhere behind them a man is
## blowing. The horror is not the thing coming at you, it is that it was sent.
##
## Mechanically this is the best tell in the game and it is free tension: the
## whistle fires BEFORE the unit commits and comes from off-screen, so the
## warning arrives before the enemy is even visible.
##
## HARD WRITING RULE, carried into code so it cannot be lost: NEVER SHOW THE
## HANDLER. There is no handler entity, no spawn point, no silhouette. A
## whistle with nobody visible behind it is the whole faction.
@export var answers_a_whistle: bool = false
@export var whistle_lead: float = 0.9

@export_group("Movement style")
## Seuche shamble, Bestiarium leap, Kadaver advance. Affects how it closes.
@export var can_leap: bool = false
@export var leap_speed: float = 700.0
@export var leap_windup: float = 0.4


## The three archetypes, each forcing a different verb out of the player.
## Kept as constructors rather than .tres files so the reasoning travels with
## the numbers -- a .tres is a table of values with nowhere to say why.

## SEUCHE -- fungal. Slow, numerous, no burst. Not a threat one at a time;
## a threat as a filled room. Answers the question "where do I stand", which
## makes it pressure on POSITIONING rather than on reflex.
## Cordyceps-shaped, per rule 4: no reanimation, no magic.
static func seuche() -> EnemyProfile:
	var p := EnemyProfile.new()
	p.branch = "seuche"
	p.designation = "Verfahren Seuche, Muster 4"
	p.troop_name = "bakers"
	p.has_proximity_tell = true
	p.max_health = 60.0
	p.move_speed = 95.0
	p.mass_knockback = 1.4
	p.sight_range = 430.0
	p.sight_cone = 1.5          # poor eyes, wide arc: it does not really look
	p.notice_time = 0.9
	p.patience = 4.0            # and it does not really stop, either
	p.forget_rate = 0.25
	p.attack_range = 78.0
	p.windup = 0.5
	p.recover = 0.5
	p.damage = 12.0
	return p

## BESTIARIUM -- grafts and powered frames. Fast, leaps, closes distance hard.
## THE REASON YOU NEED PHASE: you cannot outrun it, so you go through it.
static func bestiarium() -> EnemyProfile:
	var p := EnemyProfile.new()
	p.branch = "bestiarium"
	p.designation = "Baureihe 7"
	p.troop_name = "whistlers"
	p.answers_a_whistle = true
	p.max_health = 90.0
	p.move_speed = 300.0
	p.mass_knockback = 1.0
	p.sight_range = 780.0       # the best eyes in the roster
	p.sight_cone = 0.75
	p.notice_time = 0.3
	p.patience = 2.0
	p.forget_rate = 0.7
	p.attack_range = 110.0
	p.windup = 0.34             # the shortest tell; still a real one
	p.strike = 0.12
	p.recover = 0.38
	p.damage = 22.0
	p.can_leap = true
	return p

## KADAVER -- surgical augmentation. Armoured, deliberate, enormous tells and
## enormous consequences. THE REASON YOU NEED CURRENT AND CHRONO: you cannot
## trade with it, so you reposition around it or you take the hit back.
static func kadaver() -> EnemyProfile:
	var p := EnemyProfile.new()
	p.branch = "kadaver"
	p.designation = "Muster 12"
	p.troop_name = "patients"
	p.max_health = 220.0
	p.move_speed = 105.0
	p.mass_knockback = 0.35     # heavy: it barely notices being hit
	p.sight_range = 560.0
	p.sight_cone = 0.6          # narrow: it looks where it is going, only
	p.notice_time = 0.5
	p.patience = 3.2
	p.forget_rate = 0.35
	p.attack_range = 130.0
	p.windup = 0.85             # you can read this one from across the room
	p.strike = 0.2
	p.recover = 0.75            # and punish it for a long time afterwards
	p.damage = 38.0
	return p


## MUSTER 6 -- "the quiet ones". Late-stage Seuche, fully driven, no reflex
## left that belongs to the host.
##
## Mechanically almost a Muster 4, and that is the entire design: the ONLY
## reliable difference is that it does not smell of bread. A player who has
## learned to read the tell walks into a room, reads nothing, and relaxes.
##
## Slightly faster and slightly stronger, but deliberately close enough to be
## mistaken for a four at a glance -- EnemyProbe asserts that closeness,
## because if a six were obviously different the missing tell would carry
## nothing and this would just be a reskin.
static func muster_6() -> EnemyProfile:
	var p := EnemyProfile.new()
	p.branch = "seuche"
	p.designation = "Verfahren Seuche, Muster 6"
	p.troop_name = "the quiet ones"
	p.has_proximity_tell = false      # <- the whole unit, in one false
	p.max_health = 74.0
	p.move_speed = 118.0
	p.mass_knockback = 1.25
	p.sight_range = 470.0
	p.sight_cone = 1.4
	p.notice_time = 0.75
	p.patience = 4.4
	p.forget_rate = 0.2
	p.attack_range = 82.0
	p.windup = 0.44
	p.recover = 0.46
	p.damage = 17.0
	return p


## GESTELL 4 -- "walkers", and this one is a joke and should be played as one.
##
## The exoframes do not work well. Heavy, slow, they fail in cold, and a man
## inside cannot get out unassisted. Werk Nachtigall keeps funding them because
## a decade of estimates purchased this, and admitting it walks worse than a
## man would require somebody to write that down.
##
## §0 says if every beat is solemn we have failed. A walker stuck with a man
## inside it who cannot get out, while the war happens elsewhere, is the
## register exactly -- and the man cannot get out.
##
## The slowest thing in the roster and the longest telegraph in the game. It
## is not a threat, it is an obstacle with an occupant, and it satisfies the
## no-unit-outruns-the-player rule without trying.
static func gestell_4() -> EnemyProfile:
	var p := EnemyProfile.new()
	p.branch = "bestiarium"
	p.designation = "Gestell 4"
	p.troop_name = "walkers"
	p.max_health = 260.0
	p.move_speed = 62.0               # slower than a walking man
	p.mass_knockback = 0.3
	p.sight_range = 400.0
	p.sight_cone = 0.45               # it can barely turn its head
	p.notice_time = 1.1
	p.patience = 2.0
	p.forget_rate = 0.6
	p.attack_range = 120.0
	p.windup = 1.15                   # the longest tell in the game
	p.strike = 0.22
	p.recover = 0.95
	p.damage = 30.0
	return p


## Everything, for tests and for the bestiary screen.
static func roster() -> Array[EnemyProfile]:
	var a: Array[EnemyProfile] = []
	a.append(seuche())
	a.append(muster_6())
	a.append(bestiarium())
	a.append(gestell_4())
	a.append(kadaver())
	return a


## "Muster 12 (patients)". Used by found paperwork and by the handler
## respectively; both halves must be reachable in play or the joke is inert.
func full_name() -> String:
	return "%s (%s)" % [designation, troop_name]
