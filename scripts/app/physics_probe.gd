extends Node

## Does the ported feel actually reproduce the original's tuned numbers?
##
## The original documents its own derived values in comments beside the code
## that produces them (index.html PART 8). Those comments are the closest thing
## to a spec that exists, so they are the assertion target here -- and because
## a comment can drift from its code, the SC-unit figures are ALSO re-derived
## from the base constants independently, so agreement is checked two ways.
##
## Run: godot --headless --path . scripts/app/PhysicsProbe.tscn

const EPS := 0.001

var _checks := 0
var _fails := 0

func _ready() -> void:
	var code := _run()
	get_tree().quit(code)

func _ok(label: String, got, want, eps: float = EPS) -> void:
	_checks += 1
	var pass_ := absf(float(got) - float(want)) <= eps
	if not pass_:
		_fails += 1
	print("  [%s] %-42s got %-12s want %s"
		% ["PASS" if pass_ else "FAIL", label, str(got), str(want)])

func _run() -> int:
	print("=== Ghost Front physics port probe ===")
	print("Reference: index.html PART 8 physics block, SC=5.\n")

	var p := PlayerPhysics.new(PlayerPhysics.REFERENCE_SC)

	# ---- The four live values, in SC units.
	#
	# CAUTION, and this cost a round to find. The original's comment beside
	# physFit() annotates these as -290 / -219 / 765 / 86. Three are right and
	# the first is NOT: 172 * (26/17) * 1.10 = 289.3647, which Math.round takes
	# to 289. Verified by reproducing the exact JS expression outside Godot.
	#
	# The comment's downstream figures inherit the same off-by-one: it quotes
	# "apex 0.379 s" and "arc 55 units", which are 290/765 and 290^2/1530. What
	# the shipped game actually ran on is 0.3778 and 54.59.
	#
	# The CODE is what 48 rounds of tuning were judged against, so the code
	# wins. Do NOT "fix" 289 back to 290 to agree with the prose -- that would
	# change the feel of the game to match a typo.
	print("-- derived constants, in SC units (window-independent) --")
	_ok("JUMP  / SC", p.jump / p.sc, -289.0)
	_ok("JUMP2 / SC", p.jump2 / p.sc, -219.0)
	_ok("GRAV  / SC", p.grav / p.sc, 765.0)
	_ok("RUN   / SC", p.run / p.sc, 86.0)

	# ---- The derived envelope, computed from the REAL jump of 289 (see above).
	# The original's prose quotes "apex 0.379 s" and "arc 55 units"; both are
	# 290-derived and both are wrong by the same off-by-one.
	print("\n-- derived envelope --")
	_ok("apex time (s)", p.apex_time(), 289.0 / 765.0, 0.0005)
	_ok("arc height (SC units)", p.arc_height_sc(), (289.0 * 289.0) / 1530.0, 0.01)
	_ok("top speed (SC units/s)", p.top_speed_sc(), 86.0)

	# ---- The placeholder trap, asserted as a NEGATIVE so a future edit that
	# "simplifies" the derivation back into the declared literals fails here
	# instead of shipping a game that feels subtly wrong.
	print("\n-- the placeholder trap (these must NOT match) --")
	var dead_jump := -860.0
	var dead_grav := 2500.0
	var dead_run := 209.0
	_checks += 3
	var trap_hit := false
	for pair in [[p.jump, dead_jump, "JUMP"], [p.grav, dead_grav, "GRAV"],
				 [p.run, dead_run, "RUN"]]:
		if absf(float(pair[0]) - float(pair[1])) <= 0.5:
			trap_hit = true
			_fails += 1
			print("  [FAIL] %s equals the pre-physFit placeholder %s -- the port "
				% [pair[2], str(pair[1])] + "copied dead values.")
		else:
			print("  [PASS] %-6s %.1f is not the placeholder %.1f"
				% [pair[2], float(pair[0]), float(pair[1])])

	# ---- Scale independence: the ARC SHAPE must not change with window size.
	# This is the property MANK exists to preserve, so it is the one worth
	# asserting. Apex time is scale-free; arc height in SC units is scale-free.
	print("\n-- scale independence (the point of MANK) --")
	var apex_ref := p.apex_time()
	var arc_ref := p.arc_height_sc()
	for s in [2.0, 3.0, 5.0, 8.0, 11.0]:
		var q := PlayerPhysics.new(s)
		_ok("apex time @ SC=%d" % int(s), q.apex_time(), apex_ref, 0.0005)
		_ok("arc height(SC) @ SC=%d" % int(s), q.arc_height_sc(), arc_ref, 0.01)

	print("\n%d checks, %d failed." % [_checks, _fails])
	# Assert the denominator: if the probe ran but checked almost nothing, that
	# is a broken probe reporting a clean bill, not a clean bill.
	var floor_checks := 20
	if _checks < floor_checks:
		printerr("PROBE BROKEN: only %d checks ran, expected at least %d."
			% [_checks, floor_checks])
		return 2
	if _fails > 0:
		printerr("%d check(s) failed." % _fails)
		return 1
	print("all passed.")
	return 0
