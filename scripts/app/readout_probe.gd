extends Node

## Does the form lie in the right direction, and does the world stay honest?
##
## Canon permits the interface to understate a cost and call a condition code
## something reassuring. That is a licence to be wrong, which makes it a licence
## that needs a guard -- an interface allowed to lie can drift into lying in the
## wrong direction, or into being believed by the code that runs the game.
##
## Two properties, and the second is the load-bearing one:
##
##   1. THE FORM UNDERSTATES. Never overstates. An interface that panicked
##      early would be honest-by-accident and would lose the point entirely.
##   2. THE WORLD NEVER READS THE FORM. Enemy perception and combat resolution
##      consult the TRUE attenuation. If either ever reads the readout's
##      version, attenuation becomes cosmetic and the player's central
##      decision quietly stops mattering -- with no symptom, because the HUD
##      would still animate.
##
## Property 2 cannot be caught by playing. It is exactly the defect class where
## a broken thing and a working thing produce identical output, so it gets an
## assertion rather than a comment asking people to be careful.
##
## Run: godot --headless --path . scenes/ReadoutProbe.tscn

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
	print("=== W.D. FORM 42-C probe ===")
	print("The form is permitted to lie. These are the limits on the lie.\n")

	# ---- 1. direction of the lie
	print("-- the form understates, and never the reverse --")
	var ok_under := true
	var worst := 0.0
	for i in range(101):
		var truth := float(i) / 100.0
		var shown := FieldReadout.displayed_percent(truth) / 100.0
		if shown > truth + 0.0001:
			ok_under = false
		worst = maxf(worst, truth - shown)
	_say("displayed <= true at all 101 points", ok_under,
		"largest understatement %.0f points" % (worst * 100.0))

	_say("at 0 the form is not falsely alarming",
		is_zero_approx(FieldReadout.displayed_percent(0.0)),
		"%.0f%%" % FieldReadout.displayed_percent(0.0))
	_say("at full attenuation the form still will not say 100",
		FieldReadout.displayed_percent(1.0) < 95.0,
		"%.0f%% of rated" % FieldReadout.displayed_percent(1.0))

	# ---- 2. the reassurance holds where it matters
	print("\n-- and it stays reassuring past the point it should not --")
	var b_mid := FieldReadout.band(0.60)
	var b_bad := FieldReadout.band(0.80)
	var b_worst := FieldReadout.band(0.99)
	_say("at 60%% true it reads NOMINAL", b_mid.label == "NOMINAL",
		"%s %s" % [b_mid.code, b_mid.label])
	_say("at 80%% true -- past the unstable threshold -- still not alarmed",
		b_bad.label != "DANGER" and b_bad.label != "CRITICAL",
		"%s %s" % [b_bad.code, b_bad.label])
	_say("even at 99%% it defers rather than warns",
		b_worst.note.to_lower().contains("end of rotation"),
		"'%s'" % b_worst.note)

	# The unstable threshold is 0.75. The form's first non-NOMINAL band starts
	# at 0.70. So the agent is told "satisfactory" while already at risk of
	# dropping through the floor -- assert that gap exists on purpose, because
	# it is the entire characterisation and someone will otherwise close it.
	var ph := PhaseDash.new(1)
	var band_at_unstable := FieldReadout.band(ph.unstable_at)
	_say("at the true instability threshold the form says SATISFACTORY",
		band_at_unstable.label == "SATISFACTORY",
		"true %.0f%% -> '%s'" % [ph.unstable_at * 100.0, band_at_unstable.label])

	# ---- 3. omissions are omissions
	print("\n-- what the form does not have a box for --")
	_say("perception is not reported", FieldReadout.displayed_perception(0.15) == "--")
	_say("evasion is not reported", FieldReadout.displayed_evasion(0.6) == "--")

	# ---- 4. THE LOAD-BEARING GUARD: the world reads truth, not the form.
	print("\n-- THE WORLD DOES NOT READ THE FORM --")
	var p := PhaseDash.new(7)
	p.attenuation = 0.80

	var true_perc := p.perception_scale()
	var form_perc := FieldReadout.displayed_percent(0.80) / 100.0
	_say("true perception and the form's number are different values",
		absf(true_perc - form_perc) > 0.05,
		"true %.2f vs form %.2f" % [true_perc, form_perc])

	# An enemy's sight must respond to the true value. Drive it with both and
	# assert the answers differ -- if the code had been wired to the readout,
	# these would agree and nothing else would look wrong.
	var prof := EnemyProfile.bestiarium()
	var brain := EnemyBrain.new(prof)
	var r_true := brain.effective_range(true_perc)
	var r_form := brain.effective_range(form_perc)
	_say("enemy sight computed from truth differs from sight-from-form",
		absf(r_true - r_form) > 20.0,
		"%.0fpx (true) vs %.0fpx (if it read the form)" % [r_true, r_form])

	# Combat must do the same. Sample the real resolver at both ends.
	var hits_faded := _sample_hits(1.0, 4000)
	var hits_solid := _sample_hits(0.0, 4000)
	_say("combat lands fewer blows on a faded agent",
		hits_faded < hits_solid * 0.6,
		"%d/4000 faded vs %d/4000 solid" % [hits_faded, hits_solid])
	_say("control: at zero attenuation nothing is evaded by fading",
		hits_solid > 3900, "%d/4000 landed" % hits_solid)

	# ---- 5. the resolver honours a deliberate phase absolutely
	print("\n-- a deliberate phase is absolute, not a dice roll --")
	var p2 := PhaseDash.new(11)
	p2.attenuation = 0.0
	p2.try_dash(Vector2.RIGHT)
	var e := _make_enemy()
	e.act = Enemy.Act.STRIKE
	var blocked := true
	for i in range(200):
		var res := Combat.resolve_strike(e, p2, true)
		if res.hit:
			blocked = false
			break
	e.free()
	_say("200 strikes on a phasing agent all miss", blocked)

	# ---- 6. the readout renders
	print("\n-- the form, as the agent sees it --")
	var text := FieldReadout.render(0.80, 1.7, false, false)
	_say("renders without a true percentage in it",
		not text.contains("80"), "checked for the real number")
	print("")
	for line in text.split("\n"):
		print("      " + line)

	print("\n%d checks, %d failed." % [_checks, _fails])
	if _checks < 12:
		printerr("PROBE BROKEN: only %d checks ran." % _checks)
		return 2
	if _fails > 0:
		printerr("%d check(s) failed." % _fails)
		return 1
	print("\nall passed.")
	return 0


func _make_enemy() -> Enemy:
	var e := Enemy.new()
	e.profile = EnemyProfile.kadaver()
	e.brain = EnemyBrain.new(e.profile)
	e.health = e.profile.max_health
	return e


func _sample_hits(attenuation: float, n: int) -> int:
	var p := PhaseDash.new(20260827)
	p.attenuation = attenuation
	var e := _make_enemy()
	e.act = Enemy.Act.STRIKE
	var hits := 0
	for i in range(n):
		p.attenuation = attenuation
		var r := Combat.resolve_strike(e, p, true)
		if r.hit:
			hits += 1
	e.free()
	return hits
