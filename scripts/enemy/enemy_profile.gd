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
## Working label only. Real names are the lore thread's to grant.
@export var codename: String = "UNNAMED"

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
	p.codename = "SEUCHE-A"
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
	p.codename = "BESTIARIUM-A"
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
	p.codename = "KADAVER-A"
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
