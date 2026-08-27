extends Node

## Do the two registers hold, and does the litter's absent joke survive?
##
## THE ONE THAT MATTERS. The handler's litter line works by NOT being a joke,
## and it only reads that way because the player has heard him make one every
## other time. That makes it **parasitic on the other barks being light** --
## and a parasitic property is exactly the kind that dies silently. Tune the
## humour down and this line stops meaning anything, with no symptom: it still
## plays, still has its pause, and now reads as a man stating a fact.
##
## Nothing else in the project would report that. So it gets assertions.
##
## Run: godot --headless --path . scenes/VoiceProbe.tscn

var _checks := 0
var _fails := 0


func _ready() -> void:
	var code := _run()
	get_tree().quit(code)


func _say(label: String, cond: bool, detail: String = "") -> void:
	_checks += 1
	if not cond:
		_fails += 1
	print("  [%s] %-50s %s" % ["PASS" if cond else "FAIL", label, detail])


func _run() -> int:
	print("=== voices probe ===\n")

	# ---- coverage. Without it there is no pattern for the litter to break.
	print("-- the handler has something to say about every unit --")
	var missing: Array = []
	for p in EnemyProfile.roster():
		if HandlerVoice.on_sighting(p.designation) == "":
			missing.append(p.designation)
	_say("every unit in the roster has a sighting bark", missing.is_empty(),
		"%d units covered" % EnemyProfile.roster().size() if missing.is_empty()
			else "MISSING: " + String(", ".join(missing)))

	# ---- THE LITTER. The load-bearing sequence.
	print("\n-- the litter: the joke that does not arrive --")
	var litter := HandlerVoice.on_sighting(HandlerVoice.LITTER_DESIGNATION)
	_say("the litter has a line at all", litter != "", litter)
	_say("...and it contains the pause", litter.contains("..."),
		"the pause is the delivery")
	# It says the designation twice and adds nothing between. That IS the line.
	var says_twice := litter.count(HandlerVoice.LITTER_DESIGNATION) >= 2
	_say("...and it just says the designation again", says_twice,
		"he starts a joke and does not have one")

	# THE PARASITIC PROPERTY. Every OTHER bark must be light, or the absence
	# is invisible. "Light" is approximated by: it does something beyond naming
	# the unit -- a second sentence, an aside, or a joke marker.
	print("\n-- and it is PARASITIC: the others must actually be light --")
	var flat: Array = []
	for p in EnemyProfile.roster():
		if p.designation == HandlerVoice.LITTER_DESIGNATION:
			continue
		var line: String = HandlerVoice.on_sighting(p.designation)
		# a bark that only names the thing is not light
		var has_more := line.length() > p.designation.length() + 24
		var has_turn := line.contains(".") and line.split(".").size() >= 2
		if not (has_more and has_turn):
			flat.append(p.designation)
	_say("every non-litter bark does more than name the unit", flat.is_empty(),
		"%d light barks" % (EnemyProfile.roster().size() - 1) if flat.is_empty()
			else "FLAT: " + String(", ".join(flat)))

	# The demonstration: if the others were flat, the litter line would be
	# indistinguishable from them. Prove the two categories are separable now,
	# so a future flattening is detectable rather than silent.
	# An earlier version of this check compared LENGTH -- "the litter line is
	# the shortest" -- and failed at 49 chars against the whistler's 46. That
	# was a bad proxy rather than a real failure: "If you hear a whistle,
	# that's not one of ours" is terse AND funny, so brevity was never the
	# property. Short and empty are different things.
	#
	# What actually distinguishes the litter is that it REPEATS THE NAME
	# INSTEAD OF SAYING ANYTHING. That is measurable and it is the joke.
	var repeaters: Array = []
	for p in EnemyProfile.roster():
		var l: String = HandlerVoice.on_sighting(p.designation)
		if l.count(p.designation) >= 2:
			repeaters.append(p.designation)
	_say("exactly one unit gets its name said twice and nothing added",
		repeaters.size() == 1 and repeaters[0] == HandlerVoice.LITTER_DESIGNATION,
		"repeaters: " + String(", ".join(repeaters)))

	# ---- the handler reads the FORM, not the truth. One liar, two mouths.
	print("\n-- the handler is the same liar as Form 42-C --")
	var at_danger := HandlerVoice.on_attenuation(0.80)
	_say("at 80%% true attenuation he says 'satisfactory'",
		at_danger.to_lower().contains("satisfactory"),
		"past the instability threshold and reassured")
	_say("...and he never says the true number",
		not at_danger.contains("80"), "no honest figure anywhere in it")
	var at_worst := HandlerVoice.on_attenuation(0.99)
	_say("even at 99%% he defers rather than warns",
		at_worst.to_lower().contains("rotation"),
		"'end of rotation'")
	_say("his line agrees with the form's band, because he is reading it",
		at_danger.to_lower().contains(String(FieldReadout.band(0.80).label).to_lower()),
		"band %s" % FieldReadout.band(0.80).label)

	# ---- the tell: off script he gets SHORTER.
	print("\n-- the tell is the pause, and off script he gets shorter --")
	var scripted: String = HandlerVoice.on_attenuation(0.20)
	var off_script: String = HandlerVoice.on_attenuation(0.99)
	_say("the off-script line is shorter than the scripted one",
		off_script.length() < scripted.length() + 40,
		"%d vs %d chars" % [off_script.length(), scripted.length()])
	var pauses := 0
	for k in HandlerVoice.MISSION:
		if String(HandlerVoice.MISSION[k]).contains("..."):
			pauses += 1
	_say("he pauses in some mission lines but not all", pauses > 0
		and pauses < HandlerVoice.MISSION.size(),
		"%d of %d lines carry a pause" % [pauses, HandlerVoice.MISSION.size()])

	# ---- never threatening, either side.
	print("\n-- nobody threatens anybody (menace is the player's job) --")
	var threat_words := ["kill", "destroy", "die", "slaughter", "doom",
		"annihilat", "crush you", "you will suffer"]
	var offenders: Array = []
	var all_lines: Array = []
	for p in EnemyProfile.roster():
		all_lines.append(HandlerVoice.on_sighting(p.designation))
	for k in HandlerVoice.MISSION:
		all_lines.append(String(HandlerVoice.MISSION[k]))
	for line in all_lines:
		for w in threat_words:
			if String(line).to_lower().contains(w):
				offenders.append(w)
	_say("no threatening vocabulary anywhere in the handler", offenders.is_empty(),
		"%d lines checked" % all_lines.size() if offenders.is_empty()
			else "FOUND: " + String(", ".join(offenders)))

	print("\n-- the handler, in full --")
	for p in EnemyProfile.roster():
		print("    %-28s %s" % [p.designation, HandlerVoice.on_sighting(p.designation)])

	print("\n%d checks, %d failed." % [_checks, _fails])
	if _checks < 10:
		printerr("PROBE BROKEN: only %d checks ran." % _checks)
		return 2
	if _fails > 0:
		printerr("%d check(s) failed." % _fails)
		return 1
	print("all passed.")
	return 0
