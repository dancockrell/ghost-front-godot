class_name LevelBuilder
extends RefCounted

## Turns a LevelSpec into geometry, at load time, against a movement profile.
##
## The whole point of the separation: the spec says "a gap of 0.88" and this
## decides what that means in pixels for the jump the game currently has. Every
## level in the campaign rescales when the movement is retuned, and none of
## them need touching.
##
## Returns plain data rather than nodes. The level scene builds bodies from it,
## which keeps this testable headlessly -- a builder that instantiates
## StaticBody2D cannot be checked without a scene tree, and a level layout that
## cannot be checked is one that gets verified by walking it.

const GROUND_Y := 900.0
const PLATFORM_H := 48.0
const SOLID_DEPTH := 500.0

var solids: Array[Rect2] = []
var pits: Array[Rect2] = []
var anchors := PackedVector2Array()
## [{branch, pos}]
var enemies: Array = []
var subject_pos := Vector2.ZERO
var insertion_pos := Vector2.ZERO
var total_width: float = 0.0

var _problems: Array = []


func problems() -> Array:
	return _problems


func build(spec: LevelSpec, profile: MovementProfile) -> bool:
	solids.clear()
	pits.clear()
	anchors = PackedVector2Array()
	enemies.clear()
	_problems = spec.validate()
	if not _problems.is_empty():
		return false

	var jd := profile.jump_distance()
	var jh := profile.jump_height
	var x := 0.0
	var y := GROUND_Y

	# The apron: somewhere to stand at the start, and the way home.
	var apron := jd * 1.6
	solids.append(Rect2(Vector2(x, y), Vector2(apron, SOLID_DEPTH)))
	insertion_pos = Vector2(x + apron * 0.45, y - 140.0)
	x += apron

	var subject_set := false

	for s in spec.segments:
		match s.kind:
			"ground":
				var w: float = jd * float(s.len)
				solids.append(Rect2(Vector2(x, y), Vector2(w, SOLID_DEPTH)))
				x += w
			"gap":
				var g: float = jd * float(s.frac)
				pits.append(Rect2(Vector2(x, y), Vector2(g, 900.0)))
				x += g
			"rise":
				y -= jh * float(s.up)
				var w2: float = jd * float(s.len)
				solids.append(Rect2(Vector2(x, y), Vector2(w2, SOLID_DEPTH)))
				x += w2
			"drop":
				y += jh * float(s.down)
				var w3: float = jd * float(s.len)
				solids.append(Rect2(Vector2(x, y), Vector2(w3, SOLID_DEPTH)))
				x += w3
			"stair":
				var n: int = int(s.count)
				var w4: float = jd * float(s.len)
				for i in range(n):
					y -= jh * float(s.up)
					solids.append(Rect2(Vector2(x, y), Vector2(w4, PLATFORM_H)))
					x += w4 + jd * 0.24
			"ceiling":
				var w5: float = jd * float(s.len)
				solids.append(Rect2(Vector2(x, y), Vector2(w5, SOLID_DEPTH)))
				solids.append(Rect2(
					Vector2(x, y - jh * float(s.clear) - PLATFORM_H),
					Vector2(w5, PLATFORM_H)))
				x += w5
			"anchor":
				anchors.append(Vector2(x - jd * float(s.back), y - jh * float(s.up)))
			"enemy":
				enemies.append({"branch": String(s.branch),
					"pos": Vector2(x - jd * float(s.back), y - 60.0)})
			"subject":
				subject_pos = Vector2(x - jd * float(s.back), y - jh * float(s.up))
				subject_set = true

	# Run-out past the subject, so the far end is not a cliff edge.
	solids.append(Rect2(Vector2(x, y), Vector2(jd * 1.2, SOLID_DEPTH)))
	x += jd * 1.2
	total_width = x

	if not subject_set:
		_problems.append("builder produced no subject position")
		return false
	return true


## A crossing check the spec cannot do, because it needs the profile: walk the
## level and confirm every gap is actually jumpable, or has an anchor over it.
##
## This exists because a level can validate structurally and still be
## impassable at the current tuning -- and an impassable level is the failure
## mode that looks exactly like a hard one until somebody spends twenty minutes
## proving they cannot make the jump.
## Fraction of a full jump a gap may reach before it needs an anchor. 0.95
## leaves 5% of slack for imperfect execution; a designer writing exactly this
## is deliberately at the edge and is allowed to be.
const CROSSABLE_MARGIN := 0.95
## Pixels of tolerance on that comparison. NOT cosmetic.
##
## Without it the check flips on float rounding: a gap authored as
## `jd * 0.95` and a threshold computed as `reach * 0.95` are the same
## arithmetic reached by different routes, and they disagree in the last bit.
## That produced a check which passed at one tuning and failed at two others
## for the SAME level design -- ch4 reported an "unreachable" gap whose
## over_by was NEGATIVE, i.e. narrower than the jump.
##
## A check whose answer depends on rounding is worse than no check, because it
## is right often enough to be believed.
const MARGIN_EPSILON_PX := 1.0

func unreachable_gaps(profile: MovementProfile) -> Array:
	var bad: Array = []
	var reach := profile.jump_distance()
	for p in pits:
		if p.size.x <= reach * CROSSABLE_MARGIN + MARGIN_EPSILON_PX:
			continue
		var covered := false
		for a in anchors:
			if a.x > p.position.x - reach * 0.2 \
					and a.x < p.position.x + p.size.x + reach * 0.2:
				covered = true
				break
		if not covered:
			bad.append({"x": p.position.x, "width": p.size.x,
				"reach": reach, "over_by": p.size.x - reach})
	return bad
