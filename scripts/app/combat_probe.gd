extends Node

## Does the shooting and the boss fight actually work?
##
## The properties worth guarding are the ones that are invisible when broken:
##
##   - The three-shot cap. Without it, holding the trigger wins, and the whole
##     rhythm of the weapon goes away with no error anywhere.
##   - Ammo actually depleting. A metered weapon that never runs down is an
##     unlimited weapon with a number on it, and the economy silently dies.
##   - The weakness multiplier applying at ONE place. If damage could be
##     constructed anywhere, the route would stop mattering.
##   - Phase two triggering on health, once, and not repeatedly.
##
## Run: godot --headless --path . scenes/CombatProbe.tscn

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
	print("  [%s] %-52s %s" % ["PASS" if cond else "FAIL", label, detail])


func _run() -> int:
	print("=== combat probe ===\n")

	# ================= THE WEAPON SYSTEM =================
	print("-- the buster is always there and always free --")
	var ws := WeaponSystem.new()
	_say("starts carrying the buster", ws.current_id() == "buster",
		ws.current().issue_name)
	_say("the buster is unlimited", is_inf(ws.ammo_of("buster")))

	print("\n-- firing, and the three-shot cap --")
	var spawned := 0
	var t := 0.0
	# hold the trigger for two seconds and count what comes out, WITHOUT ever
	# despawning anything: the cap must stop it, not the cooldown.
	while t < 2.0:
		var out := ws.step(TICK, false, true)
		if not out.is_empty():
			spawned += 1
			ws.note_spawned(ws.current_id())
		t += TICK
	_say("the cap stops fire at max_live", spawned == ws.current().max_live,
		"%d shots with none despawning, cap is %d"
			% [spawned, ws.current().max_live])

	# and the control: retire them and firing resumes
	for i in range(spawned):
		ws.note_despawned("buster")
	var after := ws.step(TICK, false, true)
	_say("control: retiring shots allows firing again", not after.is_empty(),
		"the cap is the limit, not a lockout")

	print("\n-- charging --")
	var ws2 := WeaponSystem.new()
	var w := ws2.current()
	var charged_out := {}
	var held := 0.0
	# hold past the charge time, then release
	while held < w.charge_time + 0.2:
		ws2.step(TICK, true, held == 0.0)
		held += TICK
	_say("charge reaches full while held", ws2.is_charged(),
		"%.0f%%" % (ws2.charge_fraction() * 100.0))
	charged_out = ws2.step(TICK, false, false)   # release
	_say("releasing fires the charged shot", not charged_out.is_empty()
		and bool(charged_out.get("charged", false)))
	_say("...and a charged shot hits harder than a normal one",
		w.charge_damage > w.damage * 2.0,
		"%.0f vs %.0f" % [w.charge_damage, w.damage])

	# control: a short tap must NOT produce a charged shot
	var ws3 := WeaponSystem.new()
	ws3.step(TICK, true, true)
	var tap := ws3.step(TICK, false, false)
	_say("control: a tap does not fire a charged shot",
		tap.is_empty() or not bool(tap.get("charged", false)),
		"charge was %.0f%%" % (ws3.charge_fraction() * 100.0))

	print("\n-- recovered weapons are issued, and metered --")
	var ws4 := WeaponSystem.new()
	_say("issuing a weapon works", ws4.issue("mass"))
	_say("issuing it twice does not duplicate it", not ws4.issue("mass"),
		"%d carried" % ws4.carried.size())
	ws4.select("mass")
	_say("can select the issued weapon", ws4.current_id() == "mass",
		ws4.current().issue_name)
	var start_ammo := ws4.ammo_of("mass")
	var shots := 0
	var guard := 0
	while ws4.ammo_of("mass") > 0.0 and guard < 100000:
		var o := ws4.step(TICK, false, true)
		if not o.is_empty():
			shots += 1
			# retire immediately so the live-cap never masks ammo depletion
			ws4.note_spawned("mass")
			ws4.note_despawned("mass")
		guard += 1
	_say("a metered weapon runs out", ws4.ammo_of("mass") <= 0.0,
		"%d shots from %.0f ammo" % [shots, start_ammo])
	_say("...and then refuses to fire", ws4.step(TICK, false, true).is_empty())
	# The cooldown from the last mass shot is still running here, so firing
	# immediately after switching correctly returns nothing. An earlier version
	# of this check did exactly that and read the working cooldown as a broken
	# buster -- let it expire, which is what a player switching weapons does
	# anyway.
	ws4.select("buster")
	# Wait out the cooldown left over from the LAST MASS SHOT, not the
	# buster's. The first fix here used WeaponSpec.buster().cooldown (0.13s)
	# to wait out a 0.65s mass cooldown, still failed, and still looked like a
	# broken buster. The cooldown is shared state; the weapon that set it is
	# the one whose duration matters.
	var longest := 0.0
	for id in ws4.carried:
		var cw := Arsenal.by_id(String(id))
		if cw != null:
			longest = maxf(longest, cw.cooldown)
	for i in range(int(longest / TICK) + 6):
		ws4.step(TICK, false, false)
	_say("but the buster still works", not ws4.step(TICK, false, true).is_empty(),
		"the fallback is what makes spending a choice")
	ws4.refill_all()
	_say("refill restores it", ws4.ammo_of("mass") >= start_ammo)

	# ================= PROJECTILES =================
	print("\n-- shots travel and expire --")
	var p := Projectile.new()
	add_child(p)
	p.setup(WeaponSpec.buster(), Vector2.ZERO, Vector2.RIGHT, false)
	var x0 := p.global_position.x
	for i in range(10):
		p.step(TICK)
	_say("a shot travels", p.global_position.x > x0 + 100.0,
		"%.0fpx in 10 frames" % (p.global_position.x - x0))
	# Count the 10 travel frames above too. The first version of this check did
	# not, reported 0.93s against a 1.10s lifetime, and looked like a bug --
	# 0.93 + 10 frames is exactly 1.10, so the shot was always correct and the
	# arithmetic was not.
	var alive := true
	var frames := 10
	while alive and frames < 1000:
		alive = p.step(TICK)
		frames += 1
	var lived := float(frames) * TICK
	_say("a shot expires rather than living forever", not alive,
		"%.2fs" % lived)
	_say("...at about its stated lifetime",
		absf(lived - WeaponSpec.buster().lifetime) < 0.05,
		"lived %.2fs against a stated %.2fs" % [lived, WeaponSpec.buster().lifetime])
	p.free()

	# ================= THE BOSS =================
	print("\n-- the boss runs its pattern in order --")
	var b := Boss.new()
	b.spec = BossRoster.muster_12()
	var cs := CollisionShape2D.new()
	var cap := CapsuleShape2D.new()
	cap.radius = 30.0
	cap.height = 140.0
	cs.shape = cap
	b.add_child(cs)
	add_child(b)
	b.player_pos = Vector2(400, 0)

	var seen := {}
	var tells: Array = []
	b.telegraphed.connect(func(n, _t): tells.append(n))
	for i in range(1200):
		b.step(TICK)
		seen[b.state_name()] = true
	_say("it telegraphs", seen.has("TELEGRAPH"))
	_say("it commits", seen.has("ACTIVE"))
	_say("it opens up afterwards", seen.has("OPEN"))
	_say("the pattern loops rather than running out", tells.size() >= 4,
		"%d telegraphs in 20s" % tells.size())

	print("\n-- the weakness is a lock with a key in the room --")
	var b2 := Boss.new()
	b2.spec = BossRoster.muster_12()      # grants "mass", weak to "resonance"
	add_child(b2)
	var wrong := b2.take_damage(10.0, "buster")
	var right := b2.take_damage(10.0, "resonance")
	_say("the right weapon does far more", right > wrong * 3.0,
		"%.0f with resonance vs %.0f with the buster" % [right, wrong])
	_say("control: the buster is never boosted",
		is_equal_approx(wrong, 10.0), "%.0f" % wrong)

	print("\n-- phase two fires once, on health, and changes the pattern --")
	var b3 := Boss.new()
	b3.spec = BossRoster.muster_12()
	add_child(b3)
	var phase_count := [0]
	b3.phase_two.connect(func(): phase_count[0] += 1)
	_say("starts in phase one", b3.pattern().size() == b3.spec.pattern.size())
	# chip it down past the threshold in small bites
	var bites := 0
	while b3.health_fraction() > 0.2 and bites < 500:
		b3.take_damage(5.0, "buster")
		bites += 1
	_say("phase two triggered", phase_count[0] >= 1, "%d times" % phase_count[0])
	_say("...exactly once, not on every hit after", phase_count[0] == 1,
		"%d" % phase_count[0])
	_say("and the pattern actually changed",
		b3.pattern().size() == b3.spec.pattern_two.size()
			or b3.pattern() != b3.spec.pattern,
		"now running pattern_two")

	print("\n-- and it dies --")
	var grants: Array = []
	b3.defeated.connect(func(g): grants.append(g))
	b3.take_damage(99999.0, "buster")
	_say("lethal damage kills it", b3.is_dead(), "hp %.0f" % b3.health)
	_say("...and grants its weapon", grants.size() == 1
		and String(grants[0]) == b3.spec.grants,
		String(grants[0]) if grants.size() > 0 else "NOTHING GRANTED")

	# the full loop: beat it, get issued the weapon, carry it
	var ws5 := WeaponSystem.new()
	ws5.issue(String(grants[0]))
	_say("the issued weapon is carried afterwards", ws5.has(String(grants[0])),
		"%d carried" % ws5.carried.size())

	b.free()
	b2.free()
	b3.free()

	print("\n%d checks, %d failed." % [_checks, _fails])
	if _checks < 20:
		printerr("PROBE BROKEN: only %d checks ran." % _checks)
		return 2
	if _fails > 0:
		printerr("%d check(s) failed." % _fails)
		return 1
	print("all passed.")
	return 0
