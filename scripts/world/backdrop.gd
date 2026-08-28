class_name Backdrop
extends Node2D

## A layered procedural backdrop, drawn rather than painted.
##
## THE PROBLEM THIS SOLVES. A greybox with no background reads as unfinished no
## matter how good the mechanics are, and "wait for art" would leave the game
## looking like a prototype for weeks. But a flat gradient reads as a
## placeholder too. What actually reads as FINISHED is DEPTH -- several layers
## at different parallax rates, each simpler than the one in front of it.
##
## So this generates silhouette scenery per chapter: ridge lines, tree lines,
## rooflines, gantries. Deterministic from a seed, so a level looks the same
## every time it loads and can be art-directed by changing a number rather than
## by redrawing.
##
## THE PALETTE IS THE ART DIRECTION, not decoration. ART-SPEC §6 gives each
## faction its own print stock, and each faction is drawn in its OWN tradition
## -- never through an enemy's eyes. Project 42 is cream newsprint, flag red
## and navy. Werk Nachtigall is black, iron grey, blood red and ochre, woodcut
## influenced, printed cheaply by a state print office.
##
## Distant layers are pushed toward the sky colour and desaturated, which is
## real aerial perspective and the single cheapest thing that makes a flat
## image read as deep.

## One palette per chapter mood.
class Palette extends RefCounted:
	var sky_top: Color
	var sky_bottom: Color
	var layers: Array           # far -> near
	var haze: Color
	var name: String

	func _init(n: String, st: Color, sb: Color, ls: Array, h: Color) -> void:
		name = n
		sky_top = st
		sky_bottom = sb
		layers = ls
		haze = h


## ARDENNES, DECEMBER 1944. The quiet sector: overcast, blue-grey, snow light.
## Deliberately the least dramatic palette in the game -- chapter 1 teaches by
## absence and the sky should agree with that.
static func ardennes() -> Palette:
	return Palette.new("ardennes",
		Color(0.36, 0.40, 0.47), Color(0.62, 0.66, 0.70),
		[Color(0.44, 0.48, 0.55), Color(0.33, 0.37, 0.44),
		 Color(0.24, 0.27, 0.33), Color(0.16, 0.18, 0.22)],
		Color(0.58, 0.62, 0.68))

## A WERK FACILITY. State print office stock: black, iron grey, ochre. Woodcut
## influence means heavy blacks and few midtones, so the layers step hard.
static func werk() -> Palette:
	return Palette.new("werk",
		Color(0.14, 0.13, 0.15), Color(0.34, 0.28, 0.22),
		[Color(0.30, 0.26, 0.22), Color(0.21, 0.19, 0.18),
		 Color(0.13, 0.12, 0.13), Color(0.07, 0.07, 0.08)],
		Color(0.36, 0.30, 0.23))

## A DEEP RETRIEVAL. Older, warmer, thinner air. Not the war at all.
static func elsewhere() -> Palette:
	return Palette.new("elsewhere",
		Color(0.51, 0.44, 0.40), Color(0.80, 0.71, 0.58),
		[Color(0.62, 0.55, 0.47), Color(0.47, 0.41, 0.37),
		 Color(0.33, 0.29, 0.28), Color(0.20, 0.18, 0.19)],
		Color(0.74, 0.66, 0.55))

## A FIRE. The burning stacks: everything is lit from below and the sky is the
## wrong colour for the hour.
static func fire() -> Palette:
	return Palette.new("fire",
		Color(0.22, 0.11, 0.09), Color(0.66, 0.28, 0.12),
		[Color(0.55, 0.26, 0.14), Color(0.38, 0.18, 0.12),
		 Color(0.22, 0.11, 0.09), Color(0.10, 0.06, 0.06)],
		Color(0.72, 0.35, 0.16))


enum Silhouette { RIDGE, TREES, ROOFS, GANTRY }

@export var palette_name: String = "ardennes"
@export var world_width: float = 8000.0
@export var horizon_y: float = 900.0
@export var seed_value: int = 1

var _pal: Palette
var _layers: Array = []       # [{points, colour, parallax, y}]
var _cam: Camera2D


func _ready() -> void:
	_pal = _palette_by_name(palette_name)
	_generate()
	z_index = -100


static func _palette_by_name(n: String) -> Palette:
	match n:
		"werk": return werk()
		"elsewhere": return elsewhere()
		"fire": return fire()
		_: return ardennes()


func set_camera(c: Camera2D) -> void:
	_cam = c


## Four layers, far to near. Each is a silhouette band with its own parallax
## rate, its own shape vocabulary, and a colour already blended toward the haze
## so distance is doing the work rather than a post-process.
func _generate() -> void:
	_layers.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	var kinds := _kinds_for(_pal.name)
	# parallax: far layers barely move, the nearest moves almost with the world
	var rates := [0.10, 0.22, 0.40, 0.62]
	var heights := [520.0, 400.0, 300.0, 210.0]
	# how much each layer has been eaten by the air between you and it
	var hazes := [0.62, 0.42, 0.22, 0.06]

	for i in range(4):
		var col: Color = _pal.layers[i].lerp(_pal.haze, hazes[i])
		_layers.append({
			"points": _band(rng, kinds[i], heights[i], float(i)),
			"colour": col,
			"parallax": rates[i],
			"base": horizon_y,
		})


func _kinds_for(pal: String) -> Array:
	match pal:
		"werk":
			return [Silhouette.RIDGE, Silhouette.ROOFS,
					Silhouette.GANTRY, Silhouette.GANTRY]
		"elsewhere":
			return [Silhouette.RIDGE, Silhouette.RIDGE,
					Silhouette.TREES, Silhouette.ROOFS]
		"fire":
			return [Silhouette.RIDGE, Silhouette.ROOFS,
					Silhouette.ROOFS, Silhouette.GANTRY]
		_:
			return [Silhouette.RIDGE, Silhouette.TREES,
					Silhouette.TREES, Silhouette.ROOFS]


## Build one silhouette as a polygon spanning well beyond the level, so a
## parallax layer never runs out of scenery at the edges.
func _band(rng: RandomNumberGenerator, kind: int, height: float,
		layer: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var span := world_width * 1.6
	var x := -world_width * 0.5

	match kind:
		Silhouette.RIDGE:
			# smooth-ish hills: two sines plus noise, which reads as terrain
			# without needing a noise library
			var step := 190.0
			while x < span:
				var h := height * (0.55
					+ 0.28 * sin(x * 0.0007 + layer * 2.1)
					+ 0.17 * sin(x * 0.0021 + layer * 5.3)
					+ 0.10 * rng.randf())
				pts.append(Vector2(x, -h))
				x += step
		Silhouette.TREES:
			# a saw of narrow spikes: conifers at distance are a texture, not
			# individual trees, so they are drawn as one continuous edge
			while x < span:
				var w := rng.randf_range(46.0, 96.0)
				var h2 := height * rng.randf_range(0.55, 1.0)
				pts.append(Vector2(x, -h2 * 0.35))
				pts.append(Vector2(x + w * 0.5, -h2))
				pts.append(Vector2(x + w, -h2 * 0.35))
				x += w
		Silhouette.ROOFS:
			# a city edge: flat runs at stepped heights, occasional stack
			while x < span:
				var w2 := rng.randf_range(150.0, 420.0)
				var h3 := height * rng.randf_range(0.35, 1.0)
				pts.append(Vector2(x, -h3))
				pts.append(Vector2(x + w2, -h3))
				if rng.randf() < 0.22:
					var cw := rng.randf_range(12.0, 26.0)
					var ch := h3 * rng.randf_range(1.15, 1.5)
					pts.append(Vector2(x + w2, -ch))
					pts.append(Vector2(x + w2 + cw, -ch))
					pts.append(Vector2(x + w2 + cw, -h3))
					x += cw
				x += w2
		Silhouette.GANTRY:
			# industrial: verticals with a horizontal tie, which reads as a
			# facility rather than a town
			while x < span:
				var gap := rng.randf_range(200.0, 420.0)
				var h4 := height * rng.randf_range(0.5, 1.0)
				var w3 := rng.randf_range(18.0, 40.0)
				pts.append(Vector2(x, -h4 * 0.2))
				pts.append(Vector2(x, -h4))
				pts.append(Vector2(x + w3, -h4))
				pts.append(Vector2(x + w3, -h4 * 0.2))
				x += w3 + gap

	return pts


func _process(_d: float) -> void:
	queue_redraw()


func _draw() -> void:
	var vp := get_viewport_rect().size
	var cam_pos := _cam.global_position if _cam != null else Vector2.ZERO
	# Draw in screen space around the camera, so the backdrop always fills the
	# view regardless of where the level is.
	var left := cam_pos.x - vp.x
	var right := cam_pos.x + vp.x
	var top := cam_pos.y - vp.y

	# ---- sky: a vertical gradient, drawn as bands because a canvas_item
	# gradient needs a texture and bands are indistinguishable at this scale.
	var bands := 24
	var sky_h := vp.y * 2.2
	for i in range(bands):
		var t := float(i) / float(bands - 1)
		var c := _pal.sky_top.lerp(_pal.sky_bottom, t)
		var y0 := top - sky_h * 0.3 + sky_h * t
		draw_rect(Rect2(Vector2(left, y0), Vector2(right - left,
			sky_h / float(bands) + 2.0)), c, true)

	# ---- the layers, far to near.
	#
	# DRAWN AS PER-SEGMENT QUADS, NOT AS ONE POLYGON, and that is a correctness
	# fix rather than an optimisation. `draw_colored_polygon` triangulates as a
	# fan from the first vertex, which is only valid for a CONVEX shape. A
	# ridge line or a roofline is emphatically concave, so the fan produced
	# garbage -- the layers had correct geometry (verified: 2,208 points
	# spanning the level, sane bounds) and still did not appear.
	#
	# A quad per segment is four points, always convex, always right. It also
	# lets each column be clipped to the view cheaply, so an off-screen layer
	# costs nothing.
	var bottom := horizon_y + 900.0
	for l in _layers:
		var off := cam_pos.x * (1.0 - float(l.parallax))
		var pts: PackedVector2Array = l.points
		var col: Color = l.colour
		var base_y: float = float(l.base)
		for i in range(pts.size() - 1):
			var x0 := pts[i].x + off
			var x1 := pts[i + 1].x + off
			if x1 < left - 100.0 or x0 > right + 100.0:
				continue
			if x1 <= x0:
				continue
			var q := PackedVector2Array([
				Vector2(x0, base_y + pts[i].y),
				Vector2(x1, base_y + pts[i + 1].y),
				Vector2(x1, bottom),
				Vector2(x0, bottom),
			])
			draw_colored_polygon(q, col)
