extends Node2D

## A greybox built FROM the movement profile rather than beside it.
##
## Every gap and ledge here is sized as a fraction of profile.jump_distance()
## and profile.jump_height, so the level cannot drift out of agreement with the
## movement. Retune the jump and the test course retunes with it. Hand-placed
## pixel coordinates would go stale the first time anyone touched the profile,
## which is how a greybox ends up teaching you the wrong thing about your game.
##
## The course is ordered to exercise one thing at a time, in the order a player
## would meet them:
##   1. flat ground        -- run, accel, decel
##   2. easy gaps          -- 55% and 75% of a full jump
##   3. the honest gap     -- 92%, which should feel like a commitment
##   4. a ledge            -- walk off it to feel coyote time
##   5. stacked platforms  -- vertical, needs the air jump
##   6. a low ceiling      -- clipping a corner, to feel corner correction
##   7. a pit              -- respawn

const GROUND_Y := 900.0
const PLATFORM_H := 48.0

@export var profile: MovementProfile

var _player: Player
var _spawn := Vector2(200, GROUND_Y - 140.0)
var _solids: Array[Rect2] = []
var _pits: Array[Rect2] = []


func _ready() -> void:
	if profile == null:
		profile = MovementProfile.new()
	_build()
	_spawn_player()
	_add_camera()
	_add_hud()


func _add_solid(r: Rect2) -> void:
	_solids.append(r)
	var body := StaticBody2D.new()
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = r.size
	cs.shape = shape
	body.add_child(cs)
	body.global_position = r.position + r.size * 0.5
	add_child(body)


func _build() -> void:
	var jd := profile.jump_distance()
	var jh := profile.jump_height
	var x := 0.0

	# 1. opening ground: enough room to reach top speed and stop again.
	var run_up := maxf(900.0, profile.max_speed * 1.6)
	_add_solid(Rect2(Vector2(x, GROUND_Y), Vector2(run_up, 400)))
	x += run_up

	# 2-3. three gaps of rising commitment. Landing pads are a full jump wide
	# so the course tests the gap, not the landing precision.
	var gap_fracs: Array[float] = [0.55, 0.75, 0.92]
	for frac in gap_fracs:
		var gap: float = jd * frac
		_pits.append(Rect2(Vector2(x, GROUND_Y), Vector2(gap, 900)))
		x += gap
		var pad := jd * 0.9
		_add_solid(Rect2(Vector2(x, GROUND_Y), Vector2(pad, 400)))
		x += pad

	# 4. a ledge with a long drop after it: walk off and the coyote window is
	# the difference between making the next platform and not.
	_pits.append(Rect2(Vector2(x, GROUND_Y), Vector2(jd * 0.7, 900)))
	x += jd * 0.7
	_add_solid(Rect2(Vector2(x, GROUND_Y + jh * 0.6), Vector2(jd * 1.2, 400)))
	x += jd * 1.2

	# 5. a stack. Rises faster than a single jump, so the air jump is required.
	var step_up := jh * 0.78
	var base_y := GROUND_Y + jh * 0.6
	for i in range(3):
		var w := jd * 0.42
		_add_solid(Rect2(Vector2(x, base_y - step_up * float(i + 1)),
			Vector2(w, PLATFORM_H)))
		x += w + jd * 0.22
	x += jd * 0.2

	# 6. a corridor with a low ceiling: run at it and clip the corner.
	var top_y := base_y - step_up * 3.0
	_add_solid(Rect2(Vector2(x, top_y), Vector2(jd * 1.4, PLATFORM_H)))
	_add_solid(Rect2(Vector2(x, top_y - jh * 1.15), Vector2(jd * 1.4, PLATFORM_H)))
	x += jd * 1.4

	# 7. the run-out.
	_add_solid(Rect2(Vector2(x, top_y), Vector2(jd * 1.5, 600)))


func _spawn_player() -> void:
	_player = Player.new()
	_player.profile = profile
	_player.name = "Player"
	var cs := CollisionShape2D.new()
	var caps := CapsuleShape2D.new()
	caps.radius = 26.0
	caps.height = 150.0
	cs.shape = caps
	_player.add_child(cs)
	# a plain readable silhouette; art replaces this
	var body := ColorRect.new()
	body.color = Color(0.86, 0.83, 0.76)
	body.size = Vector2(52, 150)
	body.position = Vector2(-26, -75)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_player.add_child(body)
	_player.global_position = _spawn
	add_child(_player)


func _add_camera() -> void:
	var cam := Camera2D.new()
	cam.name = "Cam"
	cam.zoom = Vector2(0.9, 0.9)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 6.0
	# a deadzone so small movements do not swim the whole screen
	cam.drag_horizontal_enabled = true
	cam.drag_vertical_enabled = true
	cam.drag_left_margin = 0.18
	cam.drag_right_margin = 0.18
	cam.drag_top_margin = 0.22
	cam.drag_bottom_margin = 0.22
	_player.add_child(cam)
	cam.make_current()


func _add_hud() -> void:
	var layer := CanvasLayer.new()
	var lab := Label.new()
	lab.name = "Debug"
	lab.position = Vector2(18, 14)
	lab.add_theme_font_size_override("font_size", 18)
	lab.add_theme_color_override("font_color", Color(0.85, 0.88, 0.9))
	layer.add_child(lab)
	add_child(layer)


func _physics_process(_delta: float) -> void:
	# respawn on falling out of the world
	if _player.global_position.y > GROUND_Y + 1400.0:
		_player.global_position = _spawn
		_player.velocity = Vector2.ZERO

	var lab := get_node_or_null("CanvasLayer/Debug") as Label
	if lab == null:
		for c in get_children():
			if c is CanvasLayer:
				lab = c.get_node_or_null("Debug") as Label
				break
	if lab:
		lab.text = "%s\nvel %6.0f,%6.0f   floor:%s  coyote %.3f  buffer %.3f  airjumps %d" % [
			profile.describe(),
			_player.velocity.x, _player.velocity.y,
			"Y" if _player.is_on_floor() else "n",
			_player.coyote_remaining(), _player.buffer_remaining(),
			_player.air_jumps_remaining()]
	queue_redraw()


func _draw() -> void:
	var ink := Color(0.10, 0.11, 0.13)
	var lit := Color(0.30, 0.33, 0.38)
	var edge := Color(0.62, 0.66, 0.72)
	for r in _solids:
		draw_rect(r, ink, true)
		draw_rect(Rect2(r.position, Vector2(r.size.x, 6.0)), edge, true)
		draw_rect(Rect2(r.position + Vector2(0, 6), Vector2(r.size.x, 10.0)), lit, true)
	for p in _pits:
		draw_rect(Rect2(p.position, Vector2(p.size.x, 5.0)),
			Color(0.55, 0.22, 0.22, 0.55), true)
