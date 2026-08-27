extends Node2D

## Do the Werk behave, and -- the point of this file -- does attenuation
## actually change what the WORLD does, rather than only what the HUD says?
##
## The seduction is only real if an observer reads it. AbilityProbe proved the
## numbers rise; this proves something acts on them. Those are different
## claims and the first one passing tells you nothing about the second.
##
## Every check is run where the wrong answer is available. The perception
## tests all carry a control at zero attenuation, because "faded agent is not
## noticed" and "this enemy never notices anything" print identically.
##
## Run: godot --headless --path . scenes/EnemyProbe.tscn

const TICK := 1.0 / 60.0

var _checks := 0
var _fails := 0


func _ready() -> void:
	var code := _run()
	get_tree().quit(code)


func _say(label: String, cond: bool, detail: String = "") -> void:
	_checks += 1
	if not cond:
		_fails += 1
	print("  [%s] %-48s %s" % ["PASS" if cond else "FAIL", label, detail])


## How long, in seconds, until this brain reaches ALERT on a stationary target
## at `dist` px, at a given perception scale. Returns -1 if it never does.
func _time_to_alert(p: EnemyProfile, dist: float, perception: float,
		limit: float = 12.0) -> float:
	var b := EnemyBrain.new(p)
	b.set_facing(1.0)
	var self_pos := Vector2.ZERO
	var target := Vector2(dist, 0.0)
	var t := 0.0
	while t < limit:
		b.step(TICK, self_pos, target, perception, false)
		t += TICK
		if b.state == EnemyBrain.State.ALERT:
			return t
	return -1.0


func _run() -> int:
	print("=== Werk Nachtigall probe ===")
	print("The question this file exists to answer: does the world read")
	print("attenuation, or is the seduction only a number on a HUD?\n")

	# ================= PERCEPTION vs ATTENUATION =================
	print("-- attenuation shortens the range at which you are noticed --")
	var bes := EnemyProfile.bestiarium()
	var b := EnemyBrain.new(bes)
	var r_present := b.effective_range(1.0)
	var r_faded := b.effective_range(0.15)
	_say("full presence gives full sight range",
		is_equal_approx(r_present, bes.sight_range),
		"%.0fpx" % r_present)
	_say("a faded agent is noticed at much shorter range",
		r_faded < r_present * 0.25,
		"%.0fpx -> %.0fpx" % [r_present, r_faded])

	# The load-bearing case: a distance that is inside sight when solid and
	# outside it when faded. If this is not true, attenuation buys nothing.
	var mid := bes.sight_range * 0.5
	var seen_solid := b.can_see(Vector2.ZERO, Vector2(mid, 0), 1.0, false)
	var seen_faded := b.can_see(Vector2.ZERO, Vector2(mid, 0), 0.15, false)
	_say("at mid range: SEEN when solid", seen_solid, "d=%.0fpx" % mid)
	_say("at mid range: UNSEEN when faded", not seen_faded, "d=%.0fpx" % mid)

	print("\n-- and it delays being noticed even when in range --")
	var near := bes.sight_range * 0.3
	var t_solid := _time_to_alert(bes, near, 1.0)
	var t_faded := _time_to_alert(bes, near, 0.45)
	_say("solid agent is spotted", t_solid > 0.0, "%.2fs" % t_solid)
	_say("control: at 0.45 presence, still in range so still spotted",
		t_faded > 0.0, "%.2fs" % t_faded)
	var t_gone := _time_to_alert(bes, near, 0.1)
	_say("at 0.10 presence the same spot is out of range entirely",
		t_gone < 0.0, "never alerted in 12s")

	print("\n-- a faded agent is FORGOTTEN faster (the second half) --")
	var f_solid := _forget_time(bes, 1.0)
	var f_faded := _forget_time(bes, 0.15)
	_say("forgetting happens at all", f_solid > 0.0, "%.2fs" % f_solid)
	_say("faded agents are forgotten sooner", f_faded < f_solid,
		"solid %.2fs vs faded %.2fs" % [f_solid, f_faded])

	print("\n-- CONTROL: with attenuation disabled, none of the above happens --")
	var flat := EnemyBrain.new(bes)
	_say("at perception 1.0 the range is not reduced",
		is_equal_approx(flat.effective_range(1.0), bes.sight_range),
		"%.0fpx" % flat.effective_range(1.0))
	var t_a := _time_to_alert(bes, near, 1.0)
	var t_b := _time_to_alert(bes, near, 1.0)
	_say("and detection is deterministic run to run",
		is_equal_approx(t_a, t_b), "%.3fs == %.3fs" % [t_a, t_b])

	# ================= THE VISION CONE =================
	print("\n-- it has to be looking at you --")
	var c := EnemyBrain.new(bes)
	c.set_facing(1.0)
	_say("sees what is in front", c.can_see(Vector2.ZERO, Vector2(200, 0), 1.0, false))
	_say("does not see what is behind",
		not c.can_see(Vector2.ZERO, Vector2(-200, 0), 1.0, false))
	_say("line of sight blocks it",
		not c.can_see(Vector2.ZERO, Vector2(200, 0), 1.0, true))

	# ================= THE ATTACK CYCLE =================
	print("\n-- every attack telegraphs, and the tell cannot be cancelled --")
	for maker in [EnemyProfile.seuche, EnemyProfile.bestiarium, EnemyProfile.kadaver]:
		var p: EnemyProfile = maker.call()
		_say("%s telegraphs before striking" % p.codename,
			p.windup > 0.2, "windup=%.2fs" % p.windup)
		_say("%s leaves a punish window" % p.codename,
			p.recover > 0.25, "recover=%.2fs" % p.recover)

	print("\n-- the archetypes are actually different --")
	var s := EnemyProfile.seuche()
	var be := EnemyProfile.bestiarium()
	var k := EnemyProfile.kadaver()
	_say("Bestiarium is the fastest", be.move_speed > s.move_speed and be.move_speed > k.move_speed,
		"%.0f vs %.0f / %.0f" % [be.move_speed, s.move_speed, k.move_speed])
	_say("Kadaver is the toughest", k.max_health > s.max_health and k.max_health > be.max_health,
		"%.0f hp" % k.max_health)
	_say("Kadaver telegraphs longest (readable across a room)",
		k.windup > be.windup and k.windup > s.windup,
		"%.2fs vs %.2fs / %.2fs" % [k.windup, be.windup, s.windup])
	_say("Bestiarium has the best eyes", be.sight_range > s.sight_range and be.sight_range > k.sight_range,
		"%.0fpx" % be.sight_range)
	_say("Seuche is the weakest alone (it is a room, not a duel)",
		s.max_health < be.max_health and s.damage < be.damage,
		"%.0f hp, %.0f dmg" % [s.max_health, s.damage])
	_say("nobody is elegant: no unit outruns the player",
		be.move_speed < 540.0, "fastest Werk %.0f vs player 540" % be.move_speed)

	# ================= A LIVE BODY =================
	print("\n-- a real body runs the cycle in order --")
	var floor_body := StaticBody2D.new()
	var fcs := CollisionShape2D.new()
	var fr := RectangleShape2D.new()
	fr.size = Vector2(3000, 80)
	fcs.shape = fr
	floor_body.add_child(fcs)
	floor_body.global_position = Vector2(0, 640)
	add_child(floor_body)

	var e := Enemy.new()
	e.profile = EnemyProfile.bestiarium()
	var ecs := CollisionShape2D.new()
	var ecap := CapsuleShape2D.new()
	ecap.radius = 24.0
	ecap.height = 120.0
	ecs.shape = ecap
	e.add_child(ecs)
	e.global_position = Vector2(0, 540)
	add_child(e)
	e.brain.set_facing(1.0)

	var seen_states := {}
	e.player_pos = Vector2(80, 540)
	e.player_perception = 1.0
	for i in range(400):
		e.step(TICK)
		seen_states[e.act] = true
		if seen_states.has(Enemy.Act.RECOVER):
			break
	_say("reached WINDUP", seen_states.has(Enemy.Act.WINDUP))
	_say("reached STRIKE", seen_states.has(Enemy.Act.STRIKE))
	_say("reached RECOVER (the player's turn)", seen_states.has(Enemy.Act.RECOVER))

	print("\n-- and it dies --")
	e.take_damage(1000.0, Vector2.ZERO)
	_say("lethal damage kills it", e.is_dead(), "hp=%.0f" % e.health)

	print("\n%d checks, %d failed." % [_checks, _fails])
	if _checks < 20:
		printerr("PROBE BROKEN: only %d checks ran." % _checks)
		return 2
	if _fails > 0:
		printerr("%d check(s) failed." % _fails)
		return 1
	print("all passed.")
	return 0


## Seconds from full alert to fully forgetting, with the player out of sight.
func _forget_time(p: EnemyProfile, perception: float) -> float:
	var b := EnemyBrain.new(p)
	b.awareness = 1.0
	b.state = EnemyBrain.State.ALERT
	b.last_known = Vector2(100, 0)
	b.has_last_known = true
	var t := 0.0
	while t < 60.0:
		# blocked = true: the player is gone, not merely distant
		b.step(TICK, Vector2.ZERO, Vector2(100, 0), perception, true)
		t += TICK
		if b.awareness <= 0.0:
			return t
	return -1.0
