extends Node

## Can the player always get home, and does the audio director actually decide?
##
## THE DEAD-END CHECK IS THE POINT OF THIS FILE. A game that boots, plays and
## dies is easy; what gets skipped is the graceful way back, and the symptom is
## a screen you have to alt-F4 out of. That failure is invisible in testing
## because you only find it by getting stuck, which nobody does on purpose.
##
## So it is a graph problem, not a play-through: from EVERY state, some
## sequence of legal transitions must reach the title. Walked exhaustively.
##
## Run: godot --headless --path . scenes/FlowProbe.tscn

var _checks := 0
var _fails := 0


func _ready() -> void:
	var code := await _run()
	get_tree().quit(code)


func _say(label: String, cond: bool, detail: String = "") -> void:
	_checks += 1
	if not cond:
		_fails += 1
	print("  [%s] %-54s %s" % ["PASS" if cond else "FAIL", label, detail])


## Breadth-first: can `from` reach `to` through ALLOWED?
func _reaches(from: int, to: int) -> bool:
	var seen := {from: true}
	var queue: Array = [from]
	while not queue.is_empty():
		var n: int = queue.pop_front()
		if n == to:
			return true
		for nxt in GameFlow.ALLOWED.get(n, []):
			if not seen.has(nxt):
				seen[nxt] = true
				queue.append(nxt)
	return false


func _run() -> int:
	print("=== flow and audio probe ===\n")

	# ================= THE RETURN PATH =================
	print("-- no state is a dead end: everything reaches the title --")
	var stuck: Array = []
	for s in GameFlow.all_states():
		if s == GameFlow.State.TITLE:
			continue
		if not _reaches(s, GameFlow.State.TITLE):
			stuck.append(GameFlow.state_name(s))
	_say("every state can reach TITLE", stuck.is_empty(),
		String(", ".join(stuck)) if not stuck.is_empty()
			else "%d states walked" % GameFlow.all_states().size())

	# and the two that matter most, named explicitly so a regression says which
	_say("GAME OVER is not a dead end",
		_reaches(GameFlow.State.GAME_OVER, GameFlow.State.TITLE),
		"the screen players are most likely to be stranded on")
	_say("PAUSE is not a dead end",
		_reaches(GameFlow.State.PAUSE, GameFlow.State.TITLE))
	_say("CREDITS returns to the title rather than hanging",
		_reaches(GameFlow.State.CREDITS, GameFlow.State.TITLE))

	print("\n-- and everything is reachable FROM the boot --")
	var unreachable: Array = []
	for s in GameFlow.all_states():
		if s == GameFlow.State.BOOT:
			continue
		if not _reaches(GameFlow.State.BOOT, s):
			unreachable.append(GameFlow.state_name(s))
	_say("every state is reachable from BOOT", unreachable.is_empty(),
		String(", ".join(unreachable)) if not unreachable.is_empty()
			else "no orphaned screens")

	print("\n-- illegal moves are refused, not merely unlikely --")
	var f := GameFlow.new()
	_say("starts at BOOT", f.state == GameFlow.State.BOOT)
	_say("cannot jump straight from BOOT into PLAY",
		not f.go(GameFlow.State.PLAY), "still %s" % GameFlow.state_name(f.state))
	_say("control: the legal move IS allowed", f.go(GameFlow.State.TITLE),
		GameFlow.state_name(f.state))

	# ================= THE DEATH LOOP =================
	print("\n-- dying returns you to play, fast, with no menu --")
	f.go(GameFlow.State.SELECT)
	f.go(GameFlow.State.BRIEF)
	f.go(GameFlow.State.PLAY)
	f.start_new_run()
	var lives_before := f.lives
	f.on_death()
	_say("a death moves to RECOVERING", f.state == GameFlow.State.RECOVERING,
		GameFlow.state_name(f.state))
	_say("...and costs a life", f.lives == lives_before - 1,
		"%d -> %d" % [lives_before, f.lives])

	var t := 0.0
	while f.state == GameFlow.State.RECOVERING and t < 10.0:
		f.step(1.0 / 60.0)
		t += 1.0 / 60.0
	_say("recovery returns straight to PLAY", f.state == GameFlow.State.PLAY,
		GameFlow.state_name(f.state))
	_say("...within a beat, not a menu", t <= 2.0,
		"%.2fs out of control -- anything past ~2s is what players quit over" % t)

	print("\n-- running out of lives is a different, rarer thing --")
	var f2 := GameFlow.new()
	f2.go(GameFlow.State.TITLE)
	f2.go(GameFlow.State.SELECT)
	f2.go(GameFlow.State.BRIEF)
	f2.go(GameFlow.State.PLAY)
	f2.start_new_run()
	var deaths := 0
	var guard := 0
	while f2.state != GameFlow.State.GAME_OVER and guard < 200:
		if f2.state == GameFlow.State.PLAY:
			f2.on_death()
			deaths += 1
		f2.step(1.0 / 30.0)
		guard += 1
	_say("lives eventually run out", f2.state == GameFlow.State.GAME_OVER,
		"%d deaths" % deaths)
	_say("...after exactly the starting lives", deaths == GameFlow.STARTING_LIVES,
		"%d of %d" % [deaths, GameFlow.STARTING_LIVES])
	_say("game over goes to SELECT, not the title",
		f2.can_go(GameFlow.State.SELECT),
		"sending a player to the title after an hour throws the session away")

	print("\n-- clearing a level issues the weapon and keeps it --")
	var f3 := GameFlow.new()
	f3.go(GameFlow.State.TITLE)
	f3.go(GameFlow.State.SELECT)
	f3.go(GameFlow.State.BRIEF)
	f3.go(GameFlow.State.PLAY)
	f3.on_cleared("ch1", "mass")
	_say("clearing moves to DEBRIEF", f3.state == GameFlow.State.DEBRIEF)
	_say("the weapon is issued", f3.issued.has("mass"), String(", ".join(f3.issued)))
	_say("the level is marked cleared", f3.cleared.has("ch1"))
	f3.go(GameFlow.State.SELECT)
	f3.go(GameFlow.State.BRIEF)
	f3.go(GameFlow.State.PLAY)
	f3.on_cleared("ch1", "mass")
	_say("clearing the same level twice does not duplicate the weapon",
		f3.issued.size() == 1, "%d issued" % f3.issued.size())

	# ================= AUDIO =================
	print("\n-- the audio director decides rather than just plays --")
	var ad := AudioDirector.new()
	ad.set_muted(true)          # headless: no device, and we measure decisions
	add_child(ad)
	await get_tree().process_frame

	_say("the catalogue is populated", Sfx.catalogue().size() >= 20,
		"%d sounds" % Sfx.catalogue().size())
	var dup := {}
	var dupes: Array = []
	for r in Sfx.catalogue():
		if dup.has(r.id):
			dupes.append(r.id)
		dup[r.id] = true
	_say("no duplicate sound ids", dupes.is_empty(),
		String(", ".join(dupes)) if not dupes.is_empty() else "all distinct")

	_say("an unknown id is refused rather than silently ignored",
		not ad.play("no_such_sound"), "refused=%d" % ad.refused_count)

	print("\n-- identical sounds on one frame are collapsed --")
	var before := ad.played_count
	for i in range(6):
		ad.play("buster")
	_say("six requests for the same sound in one frame play once",
		ad.played_count - before == 1,
		"%d played, %d coalesced" % [ad.played_count - before, ad.coalesced_count])

	print("\n-- and the whistle outranks a firefight --")
	var w := Sfx.by_id("whistle")
	var b := Sfx.by_id("buster")
	var s := Sfx.by_id("werk_strike")
	_say("the whistle is the highest priority sound in the game",
		w.priority > b.priority and w.priority > s.priority,
		"whistle %d vs buster %d, strike %d" % [w.priority, b.priority, s.priority])

	# fill every voice with low-priority sound, then prove the whistle still lands
	var ad2 := AudioDirector.new()
	ad2.set_muted(true)
	add_child(ad2)
	await get_tree().process_frame
	for i in range(AudioDirector.MAX_VOICES + 4):
		# distinct ids so coalescing does not do the work instead of stealing
		ad2.play(["jump", "land", "ui_move", "typewriter", "bread",
			"ui_select", "ui_back", "document", "werk_hurt", "arc_attach",
			"charge_ready", "buster"][i % 12])
	var full := ad2.active_voices()
	_say("the voice budget fills", full >= AudioDirector.MAX_VOICES - 1,
		"%d of %d voices" % [full, AudioDirector.MAX_VOICES])
	var got := ad2.play("whistle")
	_say("the whistle still gets through a full mix", got,
		"stole a voice (%d steals)" % ad2.stolen_count)

	# the control: a LOW priority sound must NOT steal
	var ad3 := AudioDirector.new()
	ad3.set_muted(true)
	add_child(ad3)
	await get_tree().process_frame
	for i in range(AudioDirector.MAX_VOICES + 2):
		ad3.play(["whistle", "death", "hurt", "alarm", "werk_down",
			"buster_charged", "rewind", "phase", "issue", "subject",
			"stamp", "unstable"][i % 12])
	var low := ad3.play("typewriter")
	_say("control: a low-priority sound cannot steal from high ones", not low,
		"refused=%d -- priority is a rule, not a suggestion" % ad3.refused_count)

	print("\n-- panning teaches a side, not a coordinate --")
	_say("a source to the left pans left", ad.pan_for(0.0, -400.0) < 0.4)
	_say("a source to the right pans right", ad.pan_for(0.0, 400.0) > 0.6)
	_say("close to you it centres", is_equal_approx(ad.pan_for(0.0, 10.0), 0.5))
	_say("distance reduces gain",
		ad.gain_for(Vector2.ZERO, Vector2(1500, 0))
			< ad.gain_for(Vector2.ZERO, Vector2(100, 0)),
		"%.2f far vs %.2f near" % [ad.gain_for(Vector2.ZERO, Vector2(1500, 0)),
			ad.gain_for(Vector2.ZERO, Vector2(100, 0))])
	_say("...but a distant sound is never silent",
		ad.gain_for(Vector2.ZERO, Vector2(9999, 0)) > 0.0,
		"far away must not teach the player that far means safe")

	print("\n-- every sound actually synthesises a signal --")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var silent: Array = []
	for r in Sfx.catalogue():
		var peak := 0.0
		var steps := 200
		for i in range(steps):
			var tt: float = float(r.duration) * float(i) / float(steps)
			peak = maxf(peak, absf(Sfx.sample(r, tt, rng)))
		if peak < 0.01:
			silent.append(r.id)
	_say("no sound in the catalogue is silent", silent.is_empty(),
		String(", ".join(silent)) if not silent.is_empty()
			else "%d sounds all produce signal" % Sfx.catalogue().size())

	ad.queue_free()
	ad2.queue_free()
	ad3.queue_free()

	print("\n%d checks, %d failed." % [_checks, _fails])
	if _checks < 20:
		printerr("PROBE BROKEN: only %d checks ran." % _checks)
		return 2
	if _fails > 0:
		printerr("%d check(s) failed." % _fails)
		return 1
	print("all passed.")
	return 0
