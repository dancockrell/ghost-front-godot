extends Node2D

## The first playable slice: everything wired together and runnable.
##
## Movement, the three verbs, the Werk, the mission arc and Form 42-C in one
## scene. The greybox stays a pure movement testbed; this is the game.
##
## Geometry is still derived from the movement profile, for the reason the
## greybox exists: hand-placed coordinates go stale the first time anyone
## retunes the jump, and a level that disagrees with its own movement teaches
## you the wrong thing about your game.
##
## Layout, left to right:
##   insertion point ... the way out, and where you must come back to
##   the approach ...... gaps and a patrol, quiet if you are careful
##   the yard .......... open ground, two patrols, the honest test
##   the block ......... vertical, anchors, a Kadaver that owns the floor
##   the subject ....... the far end
##
## Then you walk all of it again with the alarm up.

const GROUND_Y := 900.0
const PLATFORM_H := 48.0

@export var profile: MovementProfile
@export var show_truth: bool = false

var mission: MissionState
var _player: Player
var _enemies: Array[Enemy] = []
var _solids: Array[Rect2] = []
var _pits: Array[Rect2] = []
var _anchors := PackedVector2Array()
var _spawn := Vector2(180, GROUND_Y - 140.0)
var _subject := Vector2.ZERO
var _banner := ""
var _banner_t := 0.0


func _ready() -> void:
	if profile == null:
		profile = MovementProfile.new()
	mission = MissionState.new()
	_build()
	_spawn_player()
	_place_enemies()
	mission.insertion_point = _spawn
	mission.subject_point = _subject
	mission.alarm_raised.connect(_on_alarm)
	mission.phase_changed.connect(_on_phase)
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

	# insertion apron
	_add_solid(Rect2(Vector2(x, GROUND_Y), Vector2(jd * 2.2, 400)))
	x += jd * 2.2

	# the approach: two gaps, one honest
	for frac in [0.6, 0.88]:
		var gap: float = jd * float(frac)
		_pits.append(Rect2(Vector2(x, GROUND_Y), Vector2(gap, 900)))
		x += gap
		_add_solid(Rect2(Vector2(x, GROUND_Y), Vector2(jd * 1.3, 400)))
		x += jd * 1.3

	# the yard: long open ground, nowhere to hide
	var yard := jd * 3.4
	_add_solid(Rect2(Vector2(x, GROUND_Y), Vector2(yard, 400)))
	var yard_mid := x + yard * 0.5
	x += yard

	# the block: three ledges up, anchors between them
	var step_up := jh * 0.8
	for i in range(3):
		var w := jd * 0.5
		_add_solid(Rect2(Vector2(x, GROUND_Y - step_up * float(i + 1)),
			Vector2(w, PLATFORM_H)))
		if i < 2:
			_anchors.append(Vector2(x + w + jd * 0.16,
				GROUND_Y - step_up * float(i + 1) - jh * 0.5))
		x += w + jd * 0.3

	# the far floor, where the subject is
	var top := GROUND_Y - step_up * 3.0
	_add_solid(Rect2(Vector2(x, top), Vector2(jd * 2.4, 600)))
	_subject = Vector2(x + jd * 1.6, top - 80.0)

	# an anchor over each honest gap: an alternative, never the only route
	for p in _pits:
		if p.size.x > jd * 0.75:
			_anchors.append(Vector2(p.position.x + p.size.x * 0.5,
				p.position.y - jh * 1.2))
	_anchors.append(Vector2(yard_mid, GROUND_Y - jh * 1.35))


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
	var body := ColorRect.new()
	body.color = Color(0.86, 0.83, 0.76)
	body.size = Vector2(52, 150)
	body.position = Vector2(-26, -75)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_player.add_child(body)
	_player.global_position = _spawn
	_player.anchors = _anchors
	add_child(_player)


func _add_enemy(p: EnemyProfile, at: Vector2) -> void:
	var e := Enemy.new()
	e.profile = p
	var cs := CollisionShape2D.new()
	var caps := CapsuleShape2D.new()
	caps.radius = 22.0
	caps.height = 110.0
	cs.shape = caps
	e.add_child(cs)
	e.global_position = at
	add_child(e)
	e.brain.set_facing(-1.0)
	_enemies.append(e)


func _place_enemies() -> void:
	var jd := profile.jump_distance()
	# one on the approach, two in the yard, a Kadaver holding the block.
	_add_enemy(EnemyProfile.seuche(), Vector2(jd * 3.4, GROUND_Y - 60.0))
	_add_enemy(EnemyProfile.seuche(), Vector2(jd * 6.2, GROUND_Y - 60.0))
	_add_enemy(EnemyProfile.bestiarium(), Vector2(jd * 7.6, GROUND_Y - 60.0))
	_add_enemy(EnemyProfile.kadaver(), Vector2(jd * 9.4, GROUND_Y - 60.0))


func _add_camera() -> void:
	var cam := Camera2D.new()
	cam.name = "Cam"
	cam.zoom = Vector2(0.72, 0.72)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 6.0
	cam.drag_horizontal_enabled = true
	cam.drag_vertical_enabled = true
	cam.drag_left_margin = 0.16
	cam.drag_right_margin = 0.16
	cam.drag_top_margin = 0.2
	cam.drag_bottom_margin = 0.2
	_player.add_child(cam)
	cam.make_current()


func _add_hud() -> void:
	var layer := CanvasLayer.new()
	var lab := Label.new()
	lab.name = "Form"
	lab.position = Vector2(18, 14)
	lab.add_theme_font_size_override("font_size", 16)
	lab.add_theme_color_override("font_color", Color(0.86, 0.88, 0.9))
	layer.add_child(lab)
	add_child(layer)


func _on_alarm(reason: String) -> void:
	_banner = "SITE ALERT -- " + reason.to_upper()
	_banner_t = 3.0


func _on_phase(_from: int, to: int) -> void:
	if to == MissionState.Phase.COMPLETE:
		_banner = "SUBJECT RECOVERED. RETURN LOGGED."
		_banner_t = 6.0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F1:
			show_truth = not show_truth
		elif event.keycode == KEY_R:
			_reset()


func _reset() -> void:
	mission = MissionState.new()
	mission.insertion_point = _spawn
	mission.subject_point = _subject
	mission.alarm_raised.connect(_on_alarm)
	mission.phase_changed.connect(_on_phase)
	_player.global_position = _spawn
	_player.velocity = Vector2.ZERO
	_player.phase.reset()
	_player.phase.cost_multiplier = 1.0
	_player.chrono.clear()
	for e in _enemies:
		e.brain.reset()
		e.act = Enemy.Act.IDLE
		e.health = e.profile.max_health
	_banner = ""


func _physics_process(delta: float) -> void:
	if _player.global_position.y > GROUND_Y + 1500.0:
		_player.global_position = _spawn
		_player.velocity = Vector2.ZERO

	var perception := _player.phase.perception_scale()
	var anyone_sees := false

	for e in _enemies:
		if e.is_dead():
			continue
		e.player_pos = _player.global_position
		e.player_perception = perception
		# Line of sight: cheap and honest. A real raycast against level
		# geometry, so cover actually works rather than being decorative.
		e.sight_blocked = _blocked(e.global_position, _player.global_position)
		if e.brain.state == EnemyBrain.State.ALERT:
			anyone_sees = true
			mission.record_detection(0.4 * delta)
		# The site's knowledge floors every unit's awareness, so an alerted
		# site means an alerted guard even if this one never saw anything.
		var bias := mission.awareness_bias()
		if e.brain.awareness < bias:
			e.brain.awareness = bias

		# strike resolution
		if e.is_striking():
			var in_reach := e.global_position.distance_to(_player.global_position) \
				<= e.profile.attack_range + 40.0
			var res := Combat.resolve_strike(e, _player.phase, in_reach)
			if res.hit:
				_banner = "HIT"
				_banner_t = 0.6

	mission.step(delta, anyone_sees)

	# objective proximity
	if not mission.carrying and _player.global_position.distance_to(_subject) < 110.0:
		mission.secure_subject()
		_player.phase.cost_multiplier = 2.0
	elif mission.carrying and mission.phase == MissionState.Phase.EXTRACT \
			and _player.global_position.distance_to(_spawn) < 130.0:
		mission.complete()

	if _banner_t > 0.0:
		_banner_t -= delta

	_update_hud()
	queue_redraw()


func _blocked(from: Vector2, to: Vector2) -> bool:
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(from, to)
	q.collide_with_areas = false
	var hit := space.intersect_ray(q)
	return not hit.is_empty()


func _update_hud() -> void:
	var lab: Label = null
	for c in get_children():
		if c is CanvasLayer:
			lab = c.get_node_or_null("Form") as Label
			break
	if lab == null:
		return
	var ph := _player.phase
	var txt := FieldReadout.render(ph.attenuation, _player.chrono.available(),
		ph.is_dashing(), _player.arc.is_attached())
	txt += "\n  ITEM 6  TASKING .......................... %s" % mission.phase_name()
	if mission.carrying:
		txt += "\n          SUBJECT IN HAND. DISPLACEMENT COST DOUBLED."
	if _banner_t > 0.0 and _banner != "":
		txt += "\n\n  >> " + _banner
	if show_truth:
		txt += "\n\n" + FieldReadout.render_truth(ph.attenuation,
			ph.perception_scale(), ph.evasion_chance())
		txt += "\n[dev] alarm %.2f  bias %.2f  awake %d/%d" % [
			mission.alarm, mission.awareness_bias(),
			_awake_count(), _enemies.size()]
	lab.text = txt


func _awake_count() -> int:
	var n := 0
	for e in _enemies:
		if not e.is_dead() and e.brain.state != EnemyBrain.State.UNAWARE:
			n += 1
	return n


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
	for a in _anchors:
		draw_circle(a, 17.0, Color(0.35, 0.72, 0.95, 0.28))
		draw_circle(a, 7.0, Color(0.75, 0.93, 1.0))

	# the objective, and the way out
	var obj := mission.objective()
	draw_circle(obj, 30.0, Color(0.95, 0.82, 0.35, 0.18))
	draw_circle(obj, 11.0, Color(1.0, 0.88, 0.45))
	draw_circle(_spawn, 20.0, Color(0.5, 0.85, 0.6, 0.16))

	# enemies: colour by branch, ring by awareness
	for e in _enemies:
		if e.is_dead():
			continue
		var col := Color(0.65, 0.72, 0.6)
		match e.profile.branch:
			"bestiarium": col = Color(0.78, 0.55, 0.42)
			"kadaver": col = Color(0.62, 0.66, 0.74)
		draw_rect(Rect2(e.global_position - Vector2(22, 55), Vector2(44, 110)), col, true)
		if e.is_telegraphing():
			draw_circle(e.global_position, 46.0, Color(1.0, 0.5, 0.35, 0.35))
		var aw := e.brain.awareness
		if aw > 0.02:
			draw_arc(e.global_position, 34.0, -PI / 2.0,
				-PI / 2.0 + TAU * aw, 24,
				Color(1.0, 0.75, 0.3) if aw < 1.0 else Color(1.0, 0.35, 0.3), 3.0)

	if _player != null and _player.arc != null and _player.arc.is_attached():
		draw_line(_player.global_position, _player.arc.anchor(),
			Color(0.75, 0.93, 1.0), 3.0)
