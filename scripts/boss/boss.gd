class_name Boss
extends CharacterBody2D

## A flagship Muster unit, running its pattern.
##
## THE PATTERN IS FIXED AND LOOPS. That is not a limitation, it is the contract:
## the player is allowed to learn this fight, and a fight that varies randomly
## cannot be learned, only survived. Randomness in a boss is a way of hiding
## that the designer did not build a rhythm.
##
## Phase two swaps the pattern rather than the numbers. Asserted in
## ArsenalProbe, because "make it hit harder at half health" is the default
## instinct and it punishes the player for winning.
##
## THE WEAKNESS IS A LOCK WITH A KEY IN THE ROOM. Four times damage from the
## right weapon is deliberately huge -- it should feel like an answer, not an
## optimisation. A player who works out the order from the bestiary has been
## rewarded for reading, which is the same instinct the requisitions reward.

signal telegraphed(action_name: String, tell: String)
signal committed(action_name: String, damage: float)
signal phase_two()
signal defeated(grants: String)

enum State { WAIT, TELEGRAPH, ACTIVE, RECOVER, DEAD }

var spec: BossSpec
var health: float = 0.0
var state: int = State.WAIT

## Which pattern is running, and where in it.
var _in_phase_two: bool = false
var _step: int = 0
var _timer: float = 0.0
var _gravity: float = 2900.0
var _announced := false

## Set by the arena each frame.
var player_pos := Vector2.ZERO


func _ready() -> void:
	if spec == null:
		spec = BossRoster.muster_9()
	health = spec.max_health


func pattern() -> Array:
	return spec.pattern_two if _in_phase_two else spec.pattern


func current_action() -> BossSpec.Action:
	var p := pattern()
	if p.is_empty():
		return null
	return p[_step % p.size()]


func is_vulnerable() -> bool:
	## The recovery window is the player's turn. Everything else is
	## survivable but not profitable, which is what gives the fight a rhythm.
	return state == State.RECOVER


func is_dangerous() -> bool:
	return state == State.ACTIVE


func is_dead() -> bool:
	return state == State.DEAD


func health_fraction() -> float:
	return clampf(health / maxf(spec.max_health, 1.0), 0.0, 1.0)


## Apply damage from a weapon. The weakness multiplier is applied HERE rather
## than at the weapon, so one rule governs every source and nothing can bypass
## it by constructing its own damage number.
func take_damage(amount: float, weapon_id: String) -> float:
	if state == State.DEAD:
		return 0.0
	var mult := Arsenal.multiplier(weapon_id, spec.grants)
	var dealt := amount * mult
	health -= dealt

	if not _in_phase_two and health_fraction() <= spec.phase_two_at \
			and not spec.pattern_two.is_empty():
		_in_phase_two = true
		_step = 0
		_timer = 0.0
		state = State.WAIT
		phase_two.emit()

	if health <= 0.0:
		state = State.DEAD
		defeated.emit(spec.grants)
	return dealt


func step(delta: float) -> void:
	if state == State.DEAD:
		velocity.y += _gravity * delta
		velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
		move_and_slide()
		return

	var act := current_action()
	if act == null:
		return

	_timer -= delta
	match state:
		State.WAIT:
			state = State.TELEGRAPH
			_timer = act.telegraph
			_announced = false
			telegraphed.emit(act.name, act.tell)
		State.TELEGRAPH:
			if _timer <= 0.0:
				state = State.ACTIVE
				_timer = act.active
				if not _announced:
					_announced = true
					committed.emit(act.name, act.damage)
		State.ACTIVE:
			if _timer <= 0.0:
				state = State.RECOVER
				_timer = act.recover
		State.RECOVER:
			if _timer <= 0.0:
				_step += 1
				state = State.WAIT
				_timer = 0.0

	# Nothing they do is elegant. It closes ground by walking, and it does not
	# steer out of a committed action -- a cancellable tell is a lie.
	if state == State.WAIT or state == State.RECOVER:
		var to := player_pos.x - global_position.x
		if absf(to) > spec.contact_damage * 6.0:
			velocity.x = move_toward(velocity.x, signf(to) * 90.0, 400.0 * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 1600.0 * delta)

	velocity.y += _gravity * delta
	move_and_slide()


## Seconds remaining in the current state. The arena draws this so the tell is
## visible without art.
func phase_remaining() -> float:
	return maxf(0.0, _timer)


func state_name() -> String:
	match state:
		State.TELEGRAPH: return "TELEGRAPH"
		State.ACTIVE: return "ACTIVE"
		State.RECOVER: return "OPEN"
		State.DEAD: return "DOWN"
		_: return "WAIT"
