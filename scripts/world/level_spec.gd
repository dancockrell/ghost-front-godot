class_name LevelSpec
extends RefCounted

## A level as a sentence in a small grammar, rather than as coordinates.
##
## WHY A GRAMMAR AND NOT A TILEMAP. Every distance in this game derives from the
## movement profile -- a gap is a fraction of jump_distance(), a rise is a
## fraction of jump_height. Hand-placed coordinates encode the jump the designer
## had on the day, and go stale the first time anyone retunes it. That is not
## hypothetical: retuning jump_height from 320 to 210 an hour into this project
## silently rescaled every gap, and the greybox survived only because it was
## already built this way.
##
## So levels are written as a sequence of segments in profile-relative units,
## and LevelBuilder turns them into geometry at load time. Retune the jump and
## every level in the game retunes with it, still playable, still honest.
##
## The vocabulary is deliberately small. A designer choosing between six verbs
## writes levels that read as composed; a designer with thirty knobs writes
## levels that read as noise. Add a verb only when a level genuinely cannot be
## said without it.
##
##   ground   len              flat run. The unit of rest.
##   gap      frac             a pit, `frac` of a full jump wide.
##                             >0.9 is a commitment. >1.0 needs the arc.
##   rise     up, len          floor steps up by `up` jump-heights.
##   drop     down, len        floor steps down.
##   stair    count, up, len   `count` ascending ledges. Vertical traversal.
##   ceiling  len, clear       a roof `clear` jump-heights above the floor.
##   anchor   at, up           a conductive anchor, `up` jump-heights above.
##   enemy    branch, at       a Werk unit.
##   subject  at               the extraction target. Exactly one per level.
##
## `at` and `len` are in jump-distances. Everything is relative; nothing is
## measured in pixels anywhere in a level definition.

var id: String = ""
var title: String = ""
var when: String = ""
## Author's note on what this level is for. Kept with the level rather than in
## a separate design doc, because a doc that lives elsewhere goes stale.
var intent: String = ""
var segments: Array = []


func _init(level_id: String = "", level_title: String = "",
		level_when: String = "") -> void:
	id = level_id
	title = level_title
	when = level_when


func ground(len_jd: float) -> LevelSpec:
	segments.append({"kind": "ground", "len": len_jd})
	return self

func gap(frac: float) -> LevelSpec:
	segments.append({"kind": "gap", "frac": frac})
	return self

func rise(up_jh: float, len_jd: float) -> LevelSpec:
	segments.append({"kind": "rise", "up": up_jh, "len": len_jd})
	return self

func drop(down_jh: float, len_jd: float) -> LevelSpec:
	segments.append({"kind": "drop", "down": down_jh, "len": len_jd})
	return self

func stair(count: int, up_jh: float, len_jd: float) -> LevelSpec:
	segments.append({"kind": "stair", "count": count, "up": up_jh, "len": len_jd})
	return self

func ceiling(len_jd: float, clear_jh: float) -> LevelSpec:
	segments.append({"kind": "ceiling", "len": len_jd, "clear": clear_jh})
	return self

## Anchors are placed relative to the CURRENT end of the level, so they move
## with the geometry around them rather than needing absolute positions.
func anchor(back_jd: float, up_jh: float) -> LevelSpec:
	segments.append({"kind": "anchor", "back": back_jd, "up": up_jh})
	return self

func enemy(branch: String, back_jd: float) -> LevelSpec:
	segments.append({"kind": "enemy", "branch": branch, "back": back_jd})
	return self

func subject(back_jd: float, up_jh: float = 0.5) -> LevelSpec:
	segments.append({"kind": "subject", "back": back_jd, "up": up_jh})
	return self

func note(text: String) -> LevelSpec:
	intent = text
	return self


## Validation, run at build time. A malformed level should refuse loudly at
## load rather than producing a subtly wrong space nobody can diagnose --
## a gap of 1.4 with no anchor over it is an impassable level that looks fine
## in a screenshot.
##
## Returns an Array of problem strings; empty means valid.
func validate() -> Array:
	var problems: Array = []
	var subjects := 0
	var has_ground := false
	var last_gap_index := -1
	var anchors_after_gap := 0

	for i in range(segments.size()):
		var s: Dictionary = segments[i]
		match s.kind:
			"ground", "rise", "drop", "stair", "ceiling":
				has_ground = true
			"gap":
				if s.frac <= 0.0:
					problems.append("segment %d: gap of %.2f is not a gap" % [i, s.frac])
				# A gap wider than a full jump is only crossable with the arc,
				# so it must have an anchor. Levels are allowed to demand the
				# arc; they are not allowed to demand it by accident.
				if s.frac > 1.0:
					last_gap_index = i
					anchors_after_gap = 0
			"anchor":
				if last_gap_index >= 0:
					anchors_after_gap += 1
			"subject":
				subjects += 1

	if last_gap_index >= 0 and anchors_after_gap == 0:
		problems.append("segment %d: gap wider than a full jump with no anchor "
			% last_gap_index + "placed after it -- impassable")
	if subjects != 1:
		problems.append("level has %d subjects; exactly 1 is required" % subjects)
	if not has_ground:
		problems.append("level has no standable geometry")
	if segments.is_empty():
		problems.append("level is empty")
	return problems


func describe() -> String:
	var counts := {}
	for s in segments:
		counts[s.kind] = counts.get(s.kind, 0) + 1
	var parts: Array = []
	for k in counts:
		parts.append("%s x%d" % [k, counts[k]])
	return "%s (%s) -- %d segments: %s" % [title, when, segments.size(),
		", ".join(parts)]
