class_name WeaponSystem
extends RefCounted

## What the agent is carrying, and what happens when they pull the trigger.
##
## THE BUSTER IS ALWAYS THERE AND ALWAYS FREE. That is what makes the recovered
## weapons a CHOICE rather than an upgrade path: you can always fall back, so
## spending metered ammunition is a decision about this fight rather than about
## the whole run. A game where the starting weapon becomes obsolete has thrown
## away its own economy.
##
## Recovered weapons are issued by Camp Iron Bell after something is destroyed.
## Canon §5: the victors bought the research. The system does not comment; it
## just records which unit each one came off, and the requisitions do the rest.

signal fired(spec: WeaponSpec, charged: bool)
signal charge_started()
signal charge_ready()
signal weapon_changed(spec: WeaponSpec)
signal out_of_ammo(spec: WeaponSpec)

## id -> remaining ammo. The buster is absent from this by design.
var ammo := {}
## Ids in carry order. Always starts with the buster.
var carried: Array = ["buster"]
var current_index: int = 0

var _cooldown: float = 0.0
var _charge: float = 0.0
var _charging: bool = false
var _live: Array = []          # projectiles currently on screen, by weapon id


func current() -> WeaponSpec:
	return Arsenal.by_id(String(carried[current_index]))


func current_id() -> String:
	return String(carried[current_index])


## Camp Iron Bell issues a recovered principle. Idempotent: beating a unit
## twice does not grant it twice.
func issue(weapon_id: String) -> bool:
	if carried.has(weapon_id):
		return false
	var w := Arsenal.by_id(weapon_id)
	if w == null:
		return false
	carried.append(weapon_id)
	ammo[weapon_id] = w.max_ammo
	return true


func has(weapon_id: String) -> bool:
	return carried.has(weapon_id)


func ammo_of(weapon_id: String) -> float:
	var w := Arsenal.by_id(weapon_id)
	if w != null and w.unlimited:
		return INF
	return float(ammo.get(weapon_id, 0.0))


func refill_all() -> void:
	for id in carried:
		var w := Arsenal.by_id(String(id))
		if w != null and not w.unlimited:
			ammo[id] = w.max_ammo


func cycle(dir: int) -> void:
	if carried.size() <= 1:
		return
	current_index = wrapi(current_index + dir, 0, carried.size())
	_charge = 0.0
	_charging = false
	weapon_changed.emit(current())


func select(weapon_id: String) -> void:
	var i := carried.find(weapon_id)
	if i >= 0 and i != current_index:
		current_index = i
		_charge = 0.0
		_charging = false
		weapon_changed.emit(current())


## How many of this weapon's shots are currently alive.
func live_count(weapon_id: String) -> int:
	var n := 0
	for id in _live:
		if String(id) == weapon_id:
			n += 1
	return n


func note_spawned(weapon_id: String) -> void:
	_live.append(weapon_id)


func note_despawned(weapon_id: String) -> void:
	var i := _live.find(weapon_id)
	if i >= 0:
		_live.remove_at(i)


func charge_fraction() -> float:
	var w := current()
	if w == null or not w.can_charge:
		return 0.0
	return clampf(_charge / maxf(w.charge_time, 0.01), 0.0, 1.0)


func is_charged() -> bool:
	return charge_fraction() >= 1.0


func can_fire() -> bool:
	var w := current()
	if w == null or _cooldown > 0.0:
		return false
	if live_count(w.id) >= w.max_live:
		return false
	if not w.unlimited and ammo_of(w.id) < w.ammo_per_shot:
		return false
	return true


## Drive one frame. `holding` is the fire button state.
##
## Returns a Dictionary describing what to spawn this frame, or an empty one:
##   {spec, charged}
func step(delta: float, holding: bool, pressed: bool) -> Dictionary:
	_cooldown = maxf(0.0, _cooldown - delta)
	var w := current()
	if w == null:
		return {}

	var out := {}

	# ---- charging. Only the buster charges; a recovered weapon that also
	# charged would make the buster strictly worse and collapse the economy.
	if w.can_charge:
		if holding:
			if not _charging:
				_charging = true
				charge_started.emit()
			var was := is_charged()
			_charge += delta
			if not was and is_charged():
				charge_ready.emit()
		else:
			# RELEASE fires the charge. A charged shot that fires on its own
			# would take the decision away at the moment it matters.
			if _charging and is_charged() and can_fire():
				out = {"spec": w, "charged": true}
			_charging = false
			_charge = 0.0

	# ---- ordinary fire on the press edge.
	if out.is_empty() and pressed and can_fire():
		out = {"spec": w, "charged": false}

	if not out.is_empty():
		_cooldown = w.cooldown
		if not w.unlimited:
			ammo[w.id] = maxf(0.0, ammo_of(w.id) - w.ammo_per_shot)
			if ammo_of(w.id) < w.ammo_per_shot:
				out_of_ammo.emit(w)
		fired.emit(w, bool(out.get("charged", false)))
	return out


## One line for the HUD, in the form's register.
func readout() -> String:
	var w := current()
	if w == null:
		return "NONE"
	if w.unlimited:
		return "%s ...... UNLIMITED" % w.issue_name
	return "%s ...... %d" % [w.issue_name, int(ammo_of(w.id))]
