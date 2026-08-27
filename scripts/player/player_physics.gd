class_name PlayerPhysics
extends RefCounted

## The tuned feel of Ghost Front, ported as a DERIVATION rather than as numbers.
##
## This is the part of the original that is genuinely irreplaceable: 48 rounds
## of hand-tuning. It is also the part easiest to port wrongly, because the
## original's source contains two sets of numbers and the obvious one is the
## wrong one.
##
## index.html declares:
##     var GRAV=2500, JUMP=-860, JUMP2=-650, RUN=209;
## and then immediately calls physFit(), which OVERWRITES all four from a
## scale-relative derivation. Those declared literals are placeholders that
## never survive a single frame -- the comment on them says so, explaining
## that `var` rather than `const` is deliberate because fit() may run first.
##
## A port that copies -860/2500/209 would be copying dead values. At SC=5 the
## live figures are JUMP -1450, GRAV 3825, RUN 430: roughly 1.7x across the
## board. It would still run, still look like a platformer, and feel wrong in
## a way nobody could point at.
##
## So the derivation is what is ported:
##
##     MANK  = 26/17     the collision box grew from 17 units to 26, and every
##                       length he moves through scales with him. Scaling
##                       velocity AND gravity by the same factor keeps the arc's
##                       SHAPE -- same apex time, same hang -- at a bigger size,
##                       which is the only way to grow a jump without floatiness.
##     FEELJ = 1.10      then a judgement on top of the derivation, kept as
##     FEELR = 1.15      separate numbers so "he is bigger" and "he should move
##                       better" never get confused with each other again.
##
## Original source: index.html PART 8, the physics block (~line 19356).

## Base units, pre-scale. These are the numbers the original tunes in.
const BASE_JUMP := 172.0
const BASE_JUMP2 := 130.0
const BASE_GRAV := 500.0
const BASE_RUN := 49.0

## The box grew; the world grows with it.
const MANK := 26.0 / 17.0
## And then he gets to move like he means it.
const FEELJ := 1.10
const FEELR := 1.15

## Air control: horizontal authority while off the ground.
const AIR := 0.46

## The dash, which is in real seconds and does not scale.
const DASH_SPD := 760.0
const DASH_WIND := 0.055
const DASH_GO := 0.155
const DASH_REC := 0.115
const DASH_CD := 0.80

## The original's reference scale. fit() derives SC from window width; at the
## full-size window it lands on 5, which is the configuration every one of the
## 48 tuning rounds was judged at.
const REFERENCE_SC := 5.0

var sc: float
var jump: float
var jump2: float
var grav: float
var run: float

func _init(scale_units: float = REFERENCE_SC) -> void:
	fit(scale_units)

## physFit() from the original, one for one. round() before the scale multiply
## matters: it is what makes the live values land on exactly -290/-219/765/86
## SC-units rather than on unrounded neighbours, so it is reproduced in the
## same order rather than tidied.
func fit(scale_units: float) -> void:
	sc = scale_units
	jump = -round(BASE_JUMP * MANK * FEELJ) * sc
	jump2 = -round(BASE_JUMP2 * MANK * FEELJ) * sc
	grav = round(BASE_GRAV * MANK) * sc
	run = round(BASE_RUN * MANK * FEELR) * sc

## The two properties the original derives by hand in its comments, exposed so
## a test can assert them rather than a reader having to trust the arithmetic.
## arc height = JUMP^2 / (2*GRAV);  apex time = |JUMP| / GRAV.
func arc_height() -> float:
	return (jump * jump) / (2.0 * grav)

func apex_time() -> float:
	return absf(jump) / grav

## In SC units, i.e. window-independent. The original's design budget is
## quoted in these, so this is the form worth comparing against.
func arc_height_sc() -> float:
	return arc_height() / sc

func top_speed_sc() -> float:
	return run / sc
