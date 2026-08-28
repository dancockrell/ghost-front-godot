extends Node2D

## Plays any campaign level from its LevelSpec.
##
## Replaces the hand-built MissionSlice: geometry, units, anchors, the subject
## and the requisitions all come from data, so all five chapters are playable
## from one scene and a new level is a new sentence in the grammar rather than
## a new scene file.
##
## Chapter select is [ and ], because a build you cannot get around is a build
## nobody plays past level one.

const GROUND_Y := LevelBuilder.GROUND_Y

@export var profile: MovementProfile
@export var level_index: int = 0
@export var show_truth: bool = false

var mission: MissionState
var _player: Player
var _enemies: Array[Enemy] = []
var _builder: LevelBuilder
var _spec: LevelSpec
var _docs: Array = []
var _doc_nodes: Array = []      # [{pos, doc, taken}]
var _read: Array = []
var _open_doc: Dictionary = {}
var _banner := ""
var _banner_t := 0.0
var _bark := ""
var _bark_t := 0.0
var _barked_at := {}
var _feel: GameFeel
var _whistle: Whistle
var _fx_layer: CanvasLayer
var _fx_rect: ColorRect
var _fx_mat: ShaderMaterial
var _whistled := {}


func _ready() -> void:
	if profile == null:
		profile = MovementProfile.new()
	_feel = GameFeel.new()
	_whistle = Whistle.new()
	add_child(_whistle)          # NOT _own(): survives a level reload
	_build_fx_layer()
	_load_level(level_index)


## The post-process pass. Full-screen quad on its own CanvasLayer above the
## world and below the HUD -- the form should not be distorted by the thing the
## form is lying about.
func _build_fx_layer() -> void:
	_fx_layer = CanvasLayer.new()
	_fx_layer.layer = 1
	_fx_rect = ColorRect.new()
	_fx_rect.anchor_right = 1.0
	_fx_rect.anchor_bottom = 1.0
	_fx_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx_mat = ShaderMaterial.new()
	_fx_mat.shader = load("res://shaders/attenuation.gdshader")
	_fx_rect.material = _fx_mat
	_fx_layer.add_child(_fx_rect)
	add_child(_fx_layer)         # NOT _own(): survives a level reload


## Everything this script spawns joins this group, and ONLY this group is
## cleared on a reload.
##
## The first version did `for c in get_children(): c.queue_free()`, which
## deletes any child the SCENE added too -- it silently ate a screenshot node
## attached in a .tscn, and would equally eat an audio bus, a debug overlay, or
## anything a future scene composes on top. Indiscriminate teardown is
## `git add -A` wearing a different hat: it works until somebody else puts
## something next to you.
const LEVEL_OWNED := "level_owned"


func _own(n: Node) -> Node:
	n.add_to_group(LEVEL_OWNED)
	add_child(n)
	return n


func _clear() -> void:
	for c in get_tree().get_nodes_in_group(LEVEL_OWNED):
		if c.get_parent() == self:
			c.queue_free()
	_enemies.clear()
	_doc_nodes.clear()
	_open_doc = {}
	_barked_at.clear()


func _load_level(idx: int) -> void:
	var levels := Campaign.all()
	level_index = wrapi(idx, 0, levels.size())
	_spec = levels[level_index]
	_clear()
	await get_tree().process_frame

	_builder = LevelBuilder.new()
	if not _builder.build(_spec, profile):
		push_error("level %s failed to build: %s"
			% [_spec.id, ", ".join(_builder.problems())])
		return

	for r in _builder.solids:
		var body := StaticBody2D.new()
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = r.size
		cs.shape = sh
		body.add_child(cs)
		body.global_position = r.position + r.size * 0.5
		_own(body)

	_spawn_player(_builder.insertion_pos)
	for e in _builder.enemies:
		_add_enemy(String(e.branch), e.pos)

	# requisitions, spread along the level so reading them is a route choice
	_docs = Requisitions.for_level(_spec.id)
	for i in range(_docs.size()):
		var t := float(i + 1) / float(_docs.size() + 1)
		_doc_nodes.append({
			"pos": Vector2(_builder.total_width * t, GROUND_Y - 90.0),
			"doc": _docs[i], "taken": false,
		})

	mission = MissionState.new()
	mission.insertion_point = _builder.insertion_pos
	mission.subject_point = _builder.subject_pos
	mission.alarm_raised.connect(func(r): _banner = "SITE ALERT -- " + r.to_upper(); _banner_t = 3.0)
	mission.phase_changed.connect(_on_phase)

	_add_camera()
	_add_hud()
	_say_bark(HandlerVoice.on_phase("insert"), 5.0)


func _spawn_player(at: Vector2) -> void:
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
	_player.global_position = at
	_player.anchors = _builder.anchors
	_own(_player)


func _add_enemy(branch: String, at: Vector2) -> void:
	var p: EnemyProfile
	match branch:
		"bestiarium": p = EnemyProfile.bestiarium()
		"kadaver": p = EnemyProfile.kadaver()
		_: p = EnemyProfile.seuche()
	var e := Enemy.new()
	e.profile = p
	var cs := CollisionShape2D.new()
	var caps := CapsuleShape2D.new()
	caps.radius = 22.0
	caps.height = 110.0
	cs.shape = caps
	e.add_child(cs)
	e.global_position = at
	_own(e)
	e.brain.set_facing(-1.0)
	_enemies.append(e)


func _add_camera() -> void:
	var cam := Camera2D.new()
	cam.name = "Cam"          # looked up by name to apply shake offset
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
	layer.name = "HUD"
	var lab := Label.new()
	lab.name = "Form"
	lab.position = Vector2(18, 12)
	lab.add_theme_font_size_override("font_size", 15)
	lab.add_theme_color_override("font_color", Color(0.86, 0.88, 0.9))
	layer.add_child(lab)
	_own(layer)


func _on_phase(_from: int, to: int) -> void:
	match to:
		MissionState.Phase.SECURED:
			_say_bark(HandlerVoice.on_phase("secured"), 6.0)
		MissionState.Phase.EXTRACT:
			_say_bark(HandlerVoice.on_phase("extract"), 6.0)
		MissionState.Phase.COMPLETE:
			_banner = "SUBJECT RECOVERED. RETURN LOGGED."
			_banner_t = 8.0
			_say_bark(HandlerVoice.on_phase("complete"), 8.0)


func _say_bark(text: String, secs: float) -> void:
	if text == "":
		return
	_bark = text
	_bark_t = secs


func _unhandled_input(ev: InputEvent) -> void:
	if not (ev is InputEventKey and ev.pressed):
		return
	match ev.keycode:
		KEY_F1: show_truth = not show_truth
		KEY_R: _load_level(level_index)
		KEY_BRACKETLEFT: _load_level(level_index - 1)
		KEY_BRACKETRIGHT: _load_level(level_index + 1)
		KEY_ESCAPE: _open_doc = {}


func _physics_process(delta: float) -> void:
	if _player == null or mission == null:
		return
	if _player.global_position.y > GROUND_Y + 1600.0:
		_player.global_position = mission.insertion_point
		_player.velocity = Vector2.ZERO

	var perception := _player.phase.perception_scale()
	var anyone_sees := false

	for e in _enemies:
		if e.is_dead():
			continue
		e.player_pos = _player.global_position
		e.player_perception = perception
		e.sight_blocked = _blocked(e.global_position, _player.global_position)
		if e.brain.state == EnemyBrain.State.ALERT:
			anyone_sees = true
			mission.record_detection(0.4 * delta)
		var bias := mission.awareness_bias()
		if e.brain.awareness < bias:
			e.brain.awareness = bias

		# the handler names a unit the first time it is properly seen
		if e.brain.state != EnemyBrain.State.UNAWARE \
				and not _barked_at.has(e.profile.designation):
			_barked_at[e.profile.designation] = true
			_say_bark(HandlerVoice.on_sighting(e.profile.designation), 4.5)

		# THE WHISTLE. Fires as a whistler winds up, from its direction, with
		# nobody visible behind it. The lead exceeds the wind-up, so the
		# warning arrives before the thing does -- and in a corridor, before
		# the thing is even visible.
		if e.profile.answers_a_whistle and e.is_telegraphing() \
				and not _whistled.has(e.get_instance_id()):
			_whistled[e.get_instance_id()] = true
			_whistle.aim_from(_player.global_position, e.global_position)
			_whistle.blow()
		if not e.is_telegraphing():
			_whistled.erase(e.get_instance_id())

		if e.is_striking():
			var reach := e.global_position.distance_to(_player.global_position) \
				<= e.profile.attack_range + 40.0
			var res := Combat.resolve_strike(e, _player.phase, reach)
			if res.hit:
				_banner = "HIT"
				_banner_t = 0.6
				# Shake scales with what hit you, on one shared scale rather
				# than a number invented at each call site.
				if e.profile.damage >= 30.0:
					_feel.add_shake(GameFeel.SHAKE_HEAVY)
				elif e.profile.damage >= 18.0:
					_feel.add_shake(GameFeel.SHAKE_SOLID)
				else:
					_feel.add_shake(GameFeel.SHAKE_LIGHT)
				# NO hit stop here, deliberately. Freezing the frame on damage
				# TAKEN removes the controls at the moment the player most
				# wants them. Hit stop is for hits the player LANDS.

	mission.step(delta, anyone_sees)

	# requisitions
	for d in _doc_nodes:
		if d.taken:
			continue
		if _player.global_position.distance_to(d.pos) < 90.0:
			d.taken = true
			_read.append(d.doc)
			_open_doc = d.doc

	if not mission.carrying \
			and _player.global_position.distance_to(_builder.subject_pos) < 120.0:
		mission.secure_subject()
		_player.phase.cost_multiplier = 2.0
	elif mission.carrying and mission.phase == MissionState.Phase.EXTRACT \
			and _player.global_position.distance_to(mission.insertion_point) < 140.0:
		mission.complete()

	_banner_t = maxf(0.0, _banner_t - delta)
	_bark_t = maxf(0.0, _bark_t - delta)

	# THE HONEST CHANNEL. The shader reads the TRUE attenuation, never the
	# form's version. The whole design collapses to cosmetic if this is ever
	# wired to the readout -- and it would collapse silently, because the HUD
	# and the distortion would both still animate.
	if _fx_mat != null:
		_fx_mat.set_shader_parameter("attenuation", _player.phase.attenuation)
		_fx_mat.set_shader_parameter("unstable_at", _player.phase.unstable_at)
		_fx_mat.set_shader_parameter("time_sec",
			float(Time.get_ticks_msec()) / 1000.0)

	var cam := _player.get_node_or_null("Cam") as Camera2D
	if cam != null and _feel != null:
		cam.offset = _feel.step(delta)

	_update_hud()
	queue_redraw()


func _blocked(from: Vector2, to: Vector2) -> bool:
	var q := PhysicsRayQueryParameters2D.create(from, to)
	q.collide_with_areas = false
	return not get_world_2d().direct_space_state.intersect_ray(q).is_empty()


func _update_hud() -> void:
	var layer := get_node_or_null("HUD")
	if layer == null:
		return
	var lab: Label = layer.get_node_or_null("Form")
	if lab == null:
		return

	if not _open_doc.is_empty():
		lab.text = ("[ %s ]\n\n%s\n\n%s\n\n"
			% [Requisitions.side_name(_open_doc.side), _open_doc.title,
				_open_doc.body]) + "                    -- ESC to put it down --"
		return

	var ph := _player.phase
	var txt := "CH%d  %s -- %s\n\n" % [level_index + 1, _spec.title, _spec.when]
	txt += FieldReadout.render(ph.attenuation, _player.chrono.available(),
		ph.is_dashing(), _player.arc.is_attached())
	txt += "\n  ITEM 6  TASKING .......................... %s" % mission.phase_name()
	txt += "\n  ITEM 7  DOCUMENTS RECOVERED .............. %d of %d" % [
		_read.size(), _doc_nodes.size()]
	if mission.carrying:
		txt += "\n          SUBJECT IN HAND. DISPLACEMENT COST DOUBLED."
	if _bark_t > 0.0 and _bark != "":
		txt += "\n\n  IRON BELL:  \"%s\"" % _bark
	if _banner_t > 0.0 and _banner != "":
		txt += "\n\n  >> " + _banner
	if show_truth:
		txt += "\n\n" + FieldReadout.render_truth(ph.attenuation,
			ph.perception_scale(), ph.evasion_chance())
		txt += "\n[dev] alarm %.2f  awake %d/%d   [ ] chapter  R reset" % [
			mission.alarm, _awake(), _enemies.size()]
	lab.text = txt


func _awake() -> int:
	var n := 0
	for e in _enemies:
		if not e.is_dead() and e.brain.state != EnemyBrain.State.UNAWARE:
			n += 1
	return n


func _draw() -> void:
	if _builder == null:
		return
	var ink := Color(0.10, 0.11, 0.13)
	var lit := Color(0.30, 0.33, 0.38)
	var edge := Color(0.62, 0.66, 0.72)
	for r in _builder.solids:
		draw_rect(r, ink, true)
		draw_rect(Rect2(r.position, Vector2(r.size.x, 6.0)), edge, true)
		draw_rect(Rect2(r.position + Vector2(0, 6), Vector2(r.size.x, 10.0)), lit, true)
	for p in _builder.pits:
		draw_rect(Rect2(p.position, Vector2(p.size.x, 5.0)),
			Color(0.55, 0.22, 0.22, 0.5), true)
	for a in _builder.anchors:
		draw_circle(a, 17.0, Color(0.35, 0.72, 0.95, 0.28))
		draw_circle(a, 7.0, Color(0.75, 0.93, 1.0))

	var obj := mission.objective() if mission != null else _builder.subject_pos
	draw_circle(obj, 30.0, Color(0.95, 0.82, 0.35, 0.16))
	draw_circle(obj, 11.0, Color(1.0, 0.88, 0.45))
	draw_circle(_builder.insertion_pos, 20.0, Color(0.5, 0.85, 0.6, 0.15))

	for d in _doc_nodes:
		if d.taken:
			continue
		draw_rect(Rect2(d.pos - Vector2(11, 15), Vector2(22, 30)),
			Color(0.92, 0.90, 0.82), true)
		draw_rect(Rect2(d.pos - Vector2(11, 15), Vector2(22, 30)),
			Color(0.4, 0.4, 0.36), false, 1.5)

	for e in _enemies:
		if e.is_dead():
			continue
		var col := Color(0.65, 0.72, 0.6)
		match e.profile.branch:
			"bestiarium": col = Color(0.78, 0.55, 0.42)
			"kadaver": col = Color(0.62, 0.66, 0.74)
		draw_rect(Rect2(e.global_position - Vector2(22, 55), Vector2(44, 110)),
			col, true)
		# the bread smell: a Muster 4 announces itself, a Muster 6 does not
		if e.profile.has_proximity_tell:
			draw_circle(e.global_position, e.profile.tell_radius,
				Color(0.85, 0.75, 0.45, 0.05))
		if e.is_telegraphing():
			draw_circle(e.global_position, 46.0, Color(1.0, 0.5, 0.35, 0.35))
		var aw := e.brain.awareness
		if aw > 0.02:
			draw_arc(e.global_position, 34.0, -PI / 2.0, -PI / 2.0 + TAU * aw,
				24, Color(1.0, 0.75, 0.3) if aw < 1.0 else Color(1.0, 0.35, 0.3), 3.0)

	if _player != null and _player.arc != null and _player.arc.is_attached():
		draw_line(_player.global_position, _player.arc.anchor(),
			Color(0.75, 0.93, 1.0), 3.0)
