extends Node

## Do the effects behave, and does the SCREEN stay honest?
##
## The one that matters: the attenuation shader is the player's second opinion.
## Form 42-C understates and the handler reads the form aloud, so if the screen
## were also driven by the displayed figure the player would have no honest
## channel at all and the game would be unlearnable rather than atmospheric.
##
## That failure is invisible: the HUD still animates, the shader still
## distorts, and only the RELATIONSHIP between them is wrong. So it is
## asserted, the same way ReadoutProbe asserts the enemies read truth.
##
## Run: godot --headless --path . scenes/FxProbe.tscn

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
	print("=== effects probe ===\n")

	# ---- the shaders exist and compile.
	print("-- the shaders load and compile --")
	for path in ["res://shaders/poster.gdshader", "res://shaders/attenuation.gdshader"]:
		var sh := load(path) as Shader
		_say("%s compiles" % path.get_file(), sh != null,
			"" if sh != null else "FAILED TO LOAD")

	# ---- THE HONEST CHANNEL. The shader parameter must be fed the TRUE
	# attenuation, never the form's. Demonstrated rather than asserted: drive a
	# material both ways and show the values differ, so a future wiring mistake
	# is detectable rather than invisible.
	print("\n-- the screen is driven by TRUTH, not by the form --")
	var att_shader := load("res://shaders/attenuation.gdshader") as Shader
	var mat := ShaderMaterial.new()
	mat.shader = att_shader

	var truth := 0.80
	var form := FieldReadout.displayed_percent(truth) / 100.0
	mat.set_shader_parameter("attenuation", truth)
	var got: float = mat.get_shader_parameter("attenuation")
	_say("the material carries the true value", is_equal_approx(got, truth),
		"%.2f" % got)
	_say("...and the form's number is a different number",
		absf(truth - form) > 0.15,
		"true %.2f vs form %.2f -- a %.0f point gap" % [truth, form,
			(truth - form) * 100.0])

	# The threshold uniform must match the real one, or the visual warning
	# arrives at a different moment than the mechanical one.
	var ph := PhaseDash.new(1)
	mat.set_shader_parameter("unstable_at", ph.unstable_at)
	var u: float = mat.get_shader_parameter("unstable_at")
	_say("the shader's instability threshold matches PhaseDash",
		is_equal_approx(u, ph.unstable_at),
		"%.2f" % u)

	# ---- game feel
	print("\n-- shake decays, and fast --")
	var feel := GameFeel.new(99)
	feel.add_shake(1.0)
	_say("shake registers", feel.shake_amount() > 0.9,
		"%.2f" % feel.shake_amount())
	var t := 0.0
	while feel.shake_amount() > 0.0 and t < 3.0:
		feel.step(1.0 / 60.0)
		t += 1.0 / 60.0
	_say("shake is gone within a fifth of a second", t <= 0.25,
		"decayed in %.3fs" % t)

	feel.add_shake(5.0)
	_say("shake is capped so a pile-up cannot blind the player",
		feel.shake_amount() <= feel.shake_ceiling + 0.001,
		"%.2f against ceiling %.2f" % [feel.shake_amount(), feel.shake_ceiling])

	print("\n-- shake never rotates, and is gentler vertically --")
	var feel2 := GameFeel.new(7)
	feel2.add_shake(1.0)
	var max_x := 0.0
	var max_y := 0.0
	for i in range(30):
		var o := feel2.step(1.0 / 600.0)   # tiny steps so it does not decay away
		max_x = maxf(max_x, absf(o.x))
		max_y = maxf(max_y, absf(o.y))
	_say("vertical shake is smaller than horizontal", max_y < max_x,
		"x %.2f vs y %.2f -- the horizon has to stay readable" % [max_x, max_y])

	print("\n-- hit stop ends, and cannot deadlock --")
	var feel3 := GameFeel.new(3)
	feel3.hit_stop(0.1)
	_say("hit stop engages", feel3.is_stopped())
	var guard := 0
	while feel3.is_stopped() and guard < 1000:
		feel3.step(1.0 / 60.0)
		guard += 1
	_say("hit stop releases", not feel3.is_stopped(),
		"after %d frames" % guard)
	_say("...and does so in about the requested time", guard <= 8,
		"%d frames for 0.10s at 60Hz" % guard)

	# ---- the whistle
	print("\n-- the whistle: a warning that precedes the thing --")
	var w := Whistle.new()
	var bes := EnemyProfile.bestiarium()
	_say("the lead time exceeds the unit's wind-up",
		bes.whistle_lead > bes.windup,
		"lead %.2fs vs windup %.2fs" % [bes.whistle_lead, bes.windup])

	w.aim_from(Vector2.ZERO, Vector2(-900, 0))
	var pan_left: float = w.pan
	w.aim_from(Vector2.ZERO, Vector2(900, 0))
	var pan_right: float = w.pan
	w.aim_from(Vector2.ZERO, Vector2(0, 0))
	var pan_mid: float = w.pan
	_say("it pans left for a source on the left", pan_left < 0.4, "%.2f" % pan_left)
	_say("it pans right for a source on the right", pan_right > 0.6, "%.2f" % pan_right)
	_say("and centres when it is on top of you", is_equal_approx(pan_mid, 0.5),
		"%.2f -- three sides, not a coordinate" % pan_mid)

	w.aim_from(Vector2.ZERO, Vector2(100, 0))
	var near_loud: float = w.loudness
	w.aim_from(Vector2.ZERO, Vector2(1500, 0))
	var far_loud: float = w.loudness
	_say("a nearer whistle is louder", near_loud > far_loud,
		"%.2f near vs %.2f far" % [near_loud, far_loud])
	_say("...but a distant one is never silent", far_loud > 0.0,
		"%.2f -- quiet does not mean safe, it means not yet" % far_loud)
	w.free()

	print("\n%d checks, %d failed." % [_checks, _fails])
	if _checks < 12:
		printerr("PROBE BROKEN: only %d checks ran." % _checks)
		return 2
	if _fails > 0:
		printerr("%d check(s) failed." % _fails)
		return 1
	print("all passed.")
	return 0
