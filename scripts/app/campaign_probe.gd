extends Node

## Is every level in the campaign actually crossable?
##
## THE FAILURE THIS EXISTS FOR: a level can be structurally valid and still be
## impassable at the current tuning, and an impassable level looks exactly like
## a hard one until somebody spends twenty minutes proving they cannot make the
## jump. Since every distance is profile-relative, a retune can make a level
## uncrossable without anyone touching the level.
##
## So this walks every level at the REAL profile and refuses to pass if any gap
## exceeds the real jump with no anchor over it.
##
## And it runs the check at several profiles rather than one, because a
## campaign that is only crossable at today's numbers is one retune away from
## being broken, silently, in five places at once.
##
## Run: godot --headless --path . scenes/CampaignProbe.tscn

var _checks := 0
var _fails := 0


func _ready() -> void:
	var code := _run()
	get_tree().quit(code)


func _say(label: String, cond: bool, detail: String = "") -> void:
	_checks += 1
	if not cond:
		_fails += 1
	print("  [%s] %-46s %s" % ["PASS" if cond else "FAIL", label, detail])


func _run() -> int:
	print("=== campaign probe ===\n")

	var levels := Campaign.all()
	_say("the campaign has levels at all", levels.size() >= 4,
		"%d levels" % levels.size())

	var profile := MovementProfile.new()

	print("\n-- every level is structurally valid --")
	for spec in levels:
		var problems := spec.validate()
		_say("%s validates" % spec.id, problems.is_empty(),
			spec.title if problems.is_empty() else String(", ".join(problems)))

	print("\n-- and every level actually builds --")
	var built: Array = []
	for spec in levels:
		var b := LevelBuilder.new()
		var ok := b.build(spec, profile)
		_say("%s builds" % spec.id, ok,
			"%d solids, %d pits, %d anchors, %d units, %.0fpx wide" % [
				b.solids.size(), b.pits.size(), b.anchors.size(),
				b.enemies.size(), b.total_width] if ok else String(", ".join(b.problems())))
		if ok:
			built.append({"spec": spec, "b": b})

	print("\n-- and every gap in every level is crossable --")
	for e in built:
		var bad: Array = e.b.unreachable_gaps(profile)
		var detail := "all gaps within reach"
		if not bad.is_empty():
			var parts: Array = []
			for g in bad:
				parts.append("x=%.0f is %.0fpx over" % [g.x, g.over_by])
			detail = String("; ".join(parts))
		_say("%s is crossable" % e.spec.id, bad.is_empty(), detail)

	# ---- the retune sweep. The campaign must survive the movement being
	# retuned, because it will be.
	print("\n-- and stays crossable across a range of tunings --")
	var tunings := [
		{"h": 150.0, "s": 420.0, "label": "heavier"},
		{"h": 210.0, "s": 540.0, "label": "shipping"},
		{"h": 280.0, "s": 680.0, "label": "floatier"},
	]
	for t in tunings:
		var pr := MovementProfile.new()
		pr.jump_height = t.h
		pr.max_speed = t.s
		var broken: Array = []
		for spec in levels:
			var b2 := LevelBuilder.new()
			if not b2.build(spec, pr):
				broken.append(spec.id + " (build)")
				continue
			if not b2.unreachable_gaps(pr).is_empty():
				broken.append(spec.id)
		_say("crossable at the '%s' tuning" % t.label, broken.is_empty(),
			"jump %.0fpx dist %.0fpx%s" % [pr.jump_height, pr.jump_distance(),
				"" if broken.is_empty() else "  BROKEN: " + String(", ".join(broken))])

	# ---- BOUNDARY STABILITY. The property that actually broke: a level design
	# must get the SAME verdict at every tuning, because every distance in it is
	# profile-relative and therefore the ratios are identical. A gap authored at
	# exactly the margin was flipping on float rounding -- passing at one tuning
	# and failing at two others for the same design, reporting a NEGATIVE
	# over_by, i.e. a gap narrower than the jump.
	print("\n-- a design gets the same verdict at every tuning --")
	var edge := LevelSpec.new("edge", "ON THE MARGIN", "NOWHEN")
	edge.ground(2.0).gap(LevelBuilder.CROSSABLE_MARGIN).ground(2.0).subject(1.0, 0.5)
	var verdicts: Array = []
	for sp in [40.0, 137.0, 420.0, 540.0, 680.0, 1100.0]:
		var pe := MovementProfile.new()
		pe.max_speed = sp
		var be := LevelBuilder.new()
		if not be.build(edge, pe):
			verdicts.append("build-fail")
			continue
		verdicts.append("bad" if not be.unreachable_gaps(pe).is_empty() else "ok")
	var consistent := true
	for v in verdicts:
		if v != verdicts[0]:
			consistent = false
	_say("a gap at exactly the margin verdicts consistently", consistent,
		String(", ".join(verdicts)))
	_say("...and that verdict is crossable, not unreachable",
		verdicts[0] == "ok", "a gap AT the margin is allowed by definition")

	# ---- SABOTAGE. The crossability check is worthless unless it can fail.
	print("\n-- SABOTAGE: an impassable level must be REFUSED --")
	var evil := LevelSpec.new("evil", "IMPOSSIBLE", "NOWHEN") \
		.ground(2.0).gap(1.6).ground(2.0).subject(1.0, 0.5)
	var eb := LevelBuilder.new()
	var evil_built := eb.build(evil, profile)
	_say("a level with a 1.6x gap and no anchor fails validation",
		not evil_built, String(", ".join(eb.problems())) if not evil_built
			else "*** IT BUILT, which means the guard is dead ***")

	# and the same gap WITH an anchor must be allowed, or the guard is just
	# banning wide gaps rather than banning unreachable ones
	var fine := LevelSpec.new("fine", "DEMANDING", "NOWHEN") \
		.ground(2.0).gap(1.6).anchor(0.8, 1.2).ground(2.0).subject(1.0, 0.5)
	var fb := LevelBuilder.new()
	var fine_built := fb.build(fine, profile)
	_say("the same gap WITH an anchor is allowed", fine_built,
		"the guard bans unreachable gaps, not wide ones")

	print("\n-- the levels, as designed --")
	for e in built:
		print("    %s" % e.spec.describe())
		print("        %s" % e.spec.intent)

	print("\n%d checks, %d failed." % [_checks, _fails])
	if _checks < 12:
		printerr("PROBE BROKEN: only %d checks ran." % _checks)
		return 2
	if _fails > 0:
		printerr("%d check(s) failed." % _fails)
		return 1
	print("all passed.")
	return 0
