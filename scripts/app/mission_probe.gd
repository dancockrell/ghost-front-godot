extends Node

## Does the mission run its arc, and does the alarm mean anything?
##
## The property worth guarding here is subtle: the outbound leg must MATTER
## without being able to skip the extraction. Those pull against each other,
## and the failure mode is silent in both directions -- a quiet run that
## changes nothing makes stealth pointless, and a quiet run that skips the
## climax builds the best content for the players least likely to see it.
##
## So both are asserted, and each is run where the opposite outcome is
## available: a clean run and a seen-repeatedly run are compared against each
## other rather than against a constant.
##
## Run: godot --headless --path . scenes/MissionProbe.tscn

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
	print("  [%s] %-50s %s" % ["PASS" if cond else "FAIL", label, detail])


func _fresh() -> MissionState:
	var m := MissionState.new()
	m.insertion_point = Vector2(0, 0)
	m.subject_point = Vector2(3000, 0)
	return m


func _run() -> int:
	print("=== mission probe ===\n")

	# ---- the arc
	print("-- the arc runs in order --")
	var m := _fresh()
	_say("starts at INSERT", m.phase == MissionState.Phase.INSERT, m.phase_name())
	for i in range(60):
		m.step(TICK, false)
	_say("becomes TRAVERSE", m.phase == MissionState.Phase.TRAVERSE, m.phase_name())
	_say("objective is the subject while empty-handed",
		m.objective() == m.subject_point, str(m.objective()))

	m.secure_subject()
	_say("securing moves to EXTRACT", m.phase == MissionState.Phase.EXTRACT, m.phase_name())
	_say("and the objective flips to the way out",
		m.objective() == m.insertion_point, str(m.objective()))
	_say("carrying the subject", m.carrying)

	m.complete()
	_say("returning completes the mission",
		m.phase == MissionState.Phase.COMPLETE, m.phase_name())
	_say("mission is over", m.is_over())

	# ---- securing ALWAYS raises the alarm, even on a flawless run
	print("\n-- a perfect run still gets the set piece --")
	var perfect := _fresh()
	for i in range(600):
		perfect.step(TICK, false)
	_say("alarm is at zero after a completely unseen approach",
		is_zero_approx(perfect.alarm), "alarm=%.2f" % perfect.alarm)
	var fired := [false]
	perfect.alarm_raised.connect(func(_r): fired[0] = true)
	perfect.secure_subject()
	_say("securing the subject raises the alarm anyway", fired[0],
		"alarm=%.2f" % perfect.alarm)
	_say("...to full", is_equal_approx(perfect.alarm, 1.0), "alarm=%.2f" % perfect.alarm)

	# ---- but the quiet leg still pays: it decides what the loud leg knows
	print("\n-- and the quiet leg still pays, in what the site retains --")
	var clean := _fresh()
	for i in range(600):
		clean.step(TICK, false)
	# captured BEFORE securing, because after securing it is 1.0 by design and
	# the interesting number is gone
	var clean_before := clean.alarm
	clean.secure_subject()
	# ten seconds of the extraction with nobody currently seeing the agent
	for i in range(600):
		clean.step(TICK, false)
	var clean_settled := clean.alarm

	var sloppy := _fresh()
	for i in range(300):
		sloppy.step(TICK, false)
	for k in range(4):
		sloppy.record_detection(0.25)   # seen four times on the way in
	for i in range(300):
		sloppy.step(TICK, false)
	var sloppy_before := sloppy.alarm
	sloppy.secure_subject()
	for i in range(600):
		sloppy.step(TICK, false)

	_say("being seen on the way in raises suspicion before securing",
		sloppy_before > 0.0, "alarm=%.2f pre-secure" % sloppy_before)
	# THE CONTROL, and the first version of this line was a tautology --
	# `is_zero_approx(x) == false or true` is always true, so it passed green
	# while checking nothing. Written inside a probe whose whole subject is
	# checks that cannot fail. Left documented rather than quietly deleted,
	# because the lesson is that `or true` reads as a control at a glance.
	_say("control: a clean approach reaches the subject at zero",
		is_zero_approx(clean_before),
		"clean pre-secure %.2f vs sloppy %.2f" % [clean_before, sloppy_before])
	_say("...so the two approaches genuinely differ before securing",
		sloppy_before > clean_before + 0.1,
		"%.2f vs %.2f" % [sloppy_before, clean_before])
	_say("the alarm decays when nobody can see you",
		clean_settled < 1.0, "1.00 -> %.2f over 10s" % clean_settled)
	_say("but never back to ignorance once raised",
		clean_settled >= clean.alarm_floor_after_raise,
		"floor %.2f, settled %.2f" % [clean.alarm_floor_after_raise, clean_settled])

	# ---- the alarm has to actually reach enemies, or it is a number
	print("\n-- the alarm reaches the enemies (or it is just a number) --")
	var m2 := _fresh()
	m2.set_alarm(0.0)
	var bias_quiet := m2.awareness_bias()
	m2.raise_alarm("test")
	var bias_loud := m2.awareness_bias()
	_say("a quiet site biases nothing", is_zero_approx(bias_quiet),
		"bias=%.2f" % bias_quiet)
	_say("a raised alarm biases enemy awareness upward",
		bias_loud > 0.5, "bias=%.2f" % bias_loud)

	var prof := EnemyProfile.bestiarium()
	var quiet_brain := EnemyBrain.new(prof)
	var loud_brain := EnemyBrain.new(prof)
	loud_brain.awareness = bias_loud
	quiet_brain.set_facing(1.0)
	loud_brain.set_facing(1.0)
	var t_quiet := _alert_time(quiet_brain, 200.0)
	var t_loud := _alert_time(loud_brain, 200.0)
	_say("an alerted site notices you sooner", t_loud < t_quiet,
		"%.2fs quiet vs %.2fs alerted" % [t_quiet, t_loud])

	# ---- the escort rule
	print("\n-- carrying the subject makes phasing cost more --")
	var p := PhaseDash.new(3)
	p.reset()
	p.try_dash(Vector2.RIGHT)
	var solo_cost := p.attenuation

	var p2 := PhaseDash.new(3)
	p2.reset()
	p2.cost_multiplier = 2.0
	p2.try_dash(Vector2.RIGHT)
	var carry_cost := p2.attenuation

	_say("a dash costs attenuation at all", solo_cost > 0.0, "%.3f" % solo_cost)
	_say("carrying doubles the cost", carry_cost > solo_cost * 1.9,
		"%.3f solo vs %.3f carrying" % [solo_cost, carry_cost])
	_say("control: multiplier of 1 changes nothing",
		is_equal_approx(solo_cost, 0.22), "%.3f" % solo_cost)
	# This asserted `can_dash() == false` under a name claiming the ability is
	# still AVAILABLE, which is the opposite of what it says -- it was only
	# observing that the cooldown from the dash two lines above was running.
	# The claim is that a carrying agent can dash again once the cooldown ends,
	# at a higher price. So run the cooldown out and try.
	for i in range(int((p2.dash_time + p2.cooldown) / TICK) + 4):
		p2.step(TICK)
	var before_second: float = p2.attenuation
	var second_ok := p2.try_dash(Vector2.RIGHT)
	_say("the ability is NOT removed while carrying -- it is a choice",
		second_ok, "second dash while carrying: %s" % ("allowed" if second_ok else "REFUSED"))
	_say("...and the second dash is charged at the escort rate too",
		p2.attenuation - before_second > 0.4,
		"cost %.3f" % (p2.attenuation - before_second))

	# ---- failure
	print("\n-- and it can be lost --")
	var f := _fresh()
	f.fail("agent lost")
	_say("failing ends the mission", f.phase == MissionState.Phase.FAILED, f.phase_name())
	_say("a failed mission cannot be completed by calling complete()",
		(func():
			f.complete()
			return f.phase == MissionState.Phase.FAILED).call())

	print("\n%d checks, %d failed." % [_checks, _fails])
	if _checks < 15:
		printerr("PROBE BROKEN: only %d checks ran." % _checks)
		return 2
	if _fails > 0:
		printerr("%d check(s) failed." % _fails)
		return 1
	print("all passed.")
	return 0


func _alert_time(b: EnemyBrain, dist: float, limit: float = 12.0) -> float:
	var t := 0.0
	while t < limit:
		b.step(TICK, Vector2.ZERO, Vector2(dist, 0.0), 1.0, false)
		t += TICK
		if b.state == EnemyBrain.State.ALERT:
			return t
	return limit
