class_name CurrentArc
extends RefCounted

## CURRENT -- throw an electrical arc at a conductive anchor and get pulled to it.
##
## Project 42's third pillar. The bible is explicit that Current runs on theory
## the programme does not fully understand, taken from papers seized after
## Tesla's death, so of the three verbs this is the one allowed to be slightly
## unruly: it snaps, it earths itself on the wrong thing, it occasionally
## embarrasses you. That is characterisation expressed as game feel rather than
## as dialogue.
##
## Selection is deliberately forgiving. Aim picks the anchor by a blend of
## angle and distance rather than by a raycast down the exact stick direction,
## because a grapple that demands precision to START is a grapple that spends
## the player's attention on the wrong half of the move. The interesting
## decision is where to go, not whether you managed to point at it.

## Furthest anchor that can be caught, px.
var range_px: float = 620.0
## Half-angle of the aim cone, radians. Wide, per the note above.
var cone: float = 1.05
## Speed of the pull, px/s.
var pull_speed: float = 1250.0
## Distance at which the arc lets go, px. Non-zero so the player is released
## with momentum instead of being parked exactly on the anchor.
var release_px: float = 46.0
## Hard cap on how long one arc can hold, seconds. Stops a mis-selected anchor
## turning into a stuck player.
var max_hold: float = 1.4

var _anchor: Vector2 = Vector2.ZERO
var _attached: bool = false
var _held: float = 0.0


func is_attached() -> bool:
	return _attached


func anchor() -> Vector2:
	return _anchor


func detach() -> void:
	_attached = false
	_held = 0.0


## Choose the best anchor for an aim direction, or return false.
##
## Scoring: alignment dominates, distance breaks ties. Nearest-only picks the
## anchor behind you; most-aligned-only picks one across the map. Neither alone
## is what a player means when they point.
func pick(from: Vector2, aim: Vector2, anchors: PackedVector2Array) -> Dictionary:
	var dir := aim.normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	var best_score := -INF
	var best := Vector2.ZERO
	var found := false
	for a in anchors:
		var to_a := a - from
		var d := to_a.length()
		if d < 1.0 or d > range_px:
			continue
		var align := dir.dot(to_a / d)          # 1 = dead on, -1 = behind
		if align < cos(cone):
			continue
		var score := align * 2.0 + (1.0 - d / range_px)
		if score > best_score:
			best_score = score
			best = a
			found = true
	return {"found": found, "anchor": best}


func try_attach(from: Vector2, aim: Vector2, anchors: PackedVector2Array) -> bool:
	var r := pick(from, aim, anchors)
	if not r.found:
		return false
	_anchor = r.anchor
	_attached = true
	_held = 0.0
	return true


## Drive one physics frame. Returns {override: Vector2 or null}.
func step(delta: float, pos: Vector2) -> Dictionary:
	if not _attached:
		return {"override": null}

	_held += delta
	var to_a := _anchor - pos
	var d := to_a.length()
	if d <= release_px or _held >= max_hold:
		detach()
		# Released along the last pull direction, so arriving at an anchor
		# throws you past it. The arc is transport, not a parking space.
		return {"override": to_a.normalized() * pull_speed * 0.72}

	return {"override": to_a / d * pull_speed}
