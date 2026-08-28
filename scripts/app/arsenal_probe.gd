extends Node

## Is the Mega Man structure actually sound?
##
## The weakness graph is the hidden difficulty curve of the whole game. A
## broken one does not crash, does not fail to load, and does not look wrong in
## any screenshot -- it just makes the game unfair in a way nobody can diagnose
## from inside a single fight. So it gets asserted rather than eyeballed.
##
## The properties that matter, in order:
##
##   1. It is a SINGLE CYCLE over all eight. Two short cycles would mean two
##      disconnected sub-games and four weapons that never matter.
##   2. Nothing is weak to the buster. If one were, the intended route would be
##      optional and the loop would deflate.
##   3. Every boss grants a distinct weapon, and every weapon is granted.
##   4. Every boss is READABLE: no telegraph shorter than a human reaction, and
##      every action leaves a punish window.
##
## Run: godot --headless --path . scenes/ArsenalProbe.tscn

## Below this, a tell is not something a player reads, it is something they
## memorise after dying to it. 0.3s is roughly a considered reaction.
const MIN_TELEGRAPH := 0.3
## Every action must leave a window, or the fight has no rhythm.
const MIN_RECOVERY := 0.3

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
	print("=== arsenal and boss probe ===\n")

	var bosses := BossRoster.all()
	var weapons := Arsenal.all_recovered()

	print("-- the roster --")
	_say("there are eight units", bosses.size() == 8, "%d" % bosses.size())
	_say("there are eight recovered weapons", weapons.size() == 8,
		"%d" % weapons.size())

	# ---- every boss grants a real, distinct weapon
	var granted := {}
	var bad_grant: Array = []
	for b in bosses:
		if Arsenal.by_id(b.grants) == null:
			bad_grant.append("%s -> %s" % [b.designation, b.grants])
		granted[b.grants] = true
	_say("every unit grants a weapon that exists", bad_grant.is_empty(),
		String(", ".join(bad_grant)) if not bad_grant.is_empty() else "8 of 8")
	_say("no two units grant the same weapon", granted.size() == bosses.size(),
		"%d distinct grants" % granted.size())
	var ungranted: Array = []
	for w in weapons:
		if not granted.has(w.id):
			ungranted.append(w.id)
	_say("every weapon is granted by some unit", ungranted.is_empty(),
		"unreachable: " + String(", ".join(ungranted)) if not ungranted.is_empty()
			else "none orphaned")

	# ---- THE CYCLE. The load-bearing property.
	print("\n-- the weakness graph is one closed cycle over all eight --")
	var ids: Array = []
	for w in weapons:
		ids.append(w.id)

	var every_has := true
	for id in ids:
		if Arsenal.weakness_of(id) == "":
			every_has = false
	_say("every unit has exactly one weakness", every_has,
		"%d entries" % Arsenal.WEAKNESS.size())

	# walk it: from any node, following weaknesses must visit all eight and
	# return to the start. Two 4-cycles would satisfy "everything has a
	# weakness" and would still be a broken game.
	var start: String = String(ids[0])
	var seen := {}
	var node := start
	var steps := 0
	while steps < 100:
		if seen.has(node):
			break
		seen[node] = true
		node = Arsenal.weakness_of(node)
		steps += 1
		if node == "":
			break
	_say("the walk visits all eight", seen.size() == 8,
		"visited %d: %s" % [seen.size(), String(", ".join(seen.keys()))])
	_say("...and closes back on where it started", node == start,
		"ended on '%s', started on '%s'" % [node, start])

	# ---- nothing is weak to the buster
	var buster_weak: Array = []
	for id in ids:
		if Arsenal.weakness_of(id) == "buster":
			buster_weak.append(id)
	_say("nothing is weak to the buster", buster_weak.is_empty(),
		"or the intended route would be optional")

	# ---- nothing is weak to itself
	var self_weak: Array = []
	for id in ids:
		if Arsenal.weakness_of(id) == id:
			self_weak.append(id)
	_say("nothing is weak to its own weapon", self_weak.is_empty())

	# ---- the multiplier actually applies, and only to the right pairing
	print("\n-- the correct weapon feels like an answer --")
	var probe_boss := "culture"          # weak to incendiary
	_say("the right weapon multiplies damage",
		Arsenal.multiplier("incendiary", probe_boss) > 3.0,
		"x%.1f" % Arsenal.multiplier("incendiary", probe_boss))
	_say("control: a wrong weapon does not",
		is_equal_approx(Arsenal.multiplier("cold", probe_boss), 1.0),
		"x%.1f" % Arsenal.multiplier("cold", probe_boss))
	_say("control: the buster is never boosted",
		is_equal_approx(Arsenal.multiplier("buster", probe_boss), 1.0),
		"x%.1f" % Arsenal.multiplier("buster", probe_boss))

	# ---- READABILITY. A boss you cannot read is a boss you memorise deaths at.
	print("\n-- every fight is readable --")
	var unreadable: Array = []
	var no_window: Array = []
	for b in bosses:
		if b.shortest_telegraph() < MIN_TELEGRAPH:
			unreadable.append("%s (%.2fs)" % [b.troop_name, b.shortest_telegraph()])
		var all_acts: Array = b.pattern + b.pattern_two
		for a in all_acts:
			# an action that deals no damage is a rest beat and may recover fast
			if a.damage > 0.0 and a.recover < MIN_RECOVERY:
				no_window.append("%s/%s" % [b.troop_name, a.name])
	_say("no telegraph is shorter than %.2fs" % MIN_TELEGRAPH,
		unreadable.is_empty(),
		String(", ".join(unreadable)) if not unreadable.is_empty()
			else "%d units checked" % bosses.size())
	_say("every damaging action leaves a punish window", no_window.is_empty(),
		String(", ".join(no_window)) if not no_window.is_empty() else "all clear")

	# ---- phase two changes the PATTERN, not the numbers
	print("\n-- phase two changes what it does, not how hard it hits --")
	var stat_bumps: Array = []
	for b in bosses:
		if b.pattern_two.is_empty():
			continue
		# find same-named actions and confirm the damage did not simply rise
		for a2 in b.pattern_two:
			for a1 in b.pattern:
				if a1.name == a2.name and a2.damage > a1.damage + 0.01:
					stat_bumps.append("%s/%s %.0f->%.0f"
						% [b.troop_name, a1.name, a1.damage, a2.damage])
	_say("no action simply hits harder in phase two", stat_bumps.is_empty(),
		String(", ".join(stat_bumps)) if not stat_bumps.is_empty()
			else "phase two is a new pattern, not a stat increase")
	var has_two := 0
	for b in bosses:
		if not b.pattern_two.is_empty():
			has_two += 1
	_say("every unit has a second pattern", has_two == bosses.size(),
		"%d of %d" % [has_two, bosses.size()])

	# ---- the register: none of them has a frightening name
	print("\n-- the Office does not name monsters, it numbers products --")
	var scary := ["doom", "death", "slayer", "reaper", "destroyer", "terror",
		"nightmare", "dread", "killer"]
	var offenders: Array = []
	for b in bosses:
		var n := (b.designation + " " + b.troop_name).to_lower()
		for s in scary:
			if n.contains(s):
				offenders.append(b.designation)
	_say("no unit carries a frightening name", offenders.is_empty(),
		"%d units, all numbered or nicknamed" % bosses.size())
	var no_docket: Array = []
	for b in bosses:
		if b.docket.strip_edges() == "":
			no_docket.append(b.designation)
	_say("every unit has paperwork about it", no_docket.is_empty(),
		String(", ".join(no_docket)) if not no_docket.is_empty()
			else "8 dockets")

	# ---- ammunition: recovered weapons are metered, the buster is not
	print("\n-- the buster is unlimited; everything taken is metered --")
	_say("the buster is unlimited", WeaponSpec.buster().unlimited)
	var unmetered: Array = []
	for w in weapons:
		if w.unlimited:
			unmetered.append(w.id)
	_say("no recovered weapon is unlimited", unmetered.is_empty(),
		"or choosing one stops being a decision")

	print("\n-- the route, as designed --")
	for b in bosses:
		print("    %-32s %-18s grants %-11s weak to %s" % [
			b.designation, "(" + b.troop_name + ")", b.grants,
			Arsenal.weakness_of(b.grants)])

	print("\n%d checks, %d failed." % [_checks, _fails])
	if _checks < 15:
		printerr("PROBE BROKEN: only %d checks ran." % _checks)
		return 2
	if _fails > 0:
		printerr("%d check(s) failed." % _fails)
		return 1
	print("all passed.")
	return 0
