class_name Enemy
extends CharacterBody2D

## A Werk Nachtigall unit.
##
## Nothing it does is elegant, and that is canon rather than a limitation of the
## prototype. Rule 4 as the lore thread reframed it: they get no magic because
## they could not get any, so they brute-force with meat and machinery what the
## other factions get gracefully. Mechanically that means no teleports, no
## phasing, no rewinding -- it closes ground by running at you and solves
## problems by applying more of itself.
##
## THE ATTACK CYCLE IS THE WHOLE FIGHT: telegraph -> strike -> recover.
## Every attack announces itself. The recovery window is the player's turn, and
## it is a named tunable rather than an accident of animation length, because
## "how long do I get to punish this" is a design decision and should be edited
## as one.

signal telegraphed(kind: String)
signal struck()
signal died()

enum Act { IDLE, CHASE, WINDUP, STRIKE, RECOVER, DEAD }

@export var profile: EnemyProfile

var brain: EnemyBrain
var health: float
var act: int = Act.IDLE

## Written by the level each frame. The enemy does not go looking for the
## player; it is told where the player is and how present they are.
var player_pos := Vector2.ZERO
var player_perception: float = 1.0
var sight_blocked: bool = false

var _timer: float = 0.0
var _gravity: float = 2900.0
var _strike_hit_sent: bool = false


func _ready() -> void:
	if profile == null:
		profile = EnemyProfile.seuche()
	brain = EnemyBrain.new(profile)
	health = profile.max_health


## True only during the active strike frames. The level asks this to decide
## whether the player is hit; the enemy never reaches into the player itself.
func is_striking() -> bool:
	return act == Act.STRIKE


## True while wound up or recovering: the readable moments.
func is_telegraphing() -> bool:
	return act == Act.WINDUP


func is_vulnerable() -> bool:
	return act == Act.RECOVER


func is_dead() -> bool:
	return act == Act.DEAD


func take_damage(amount: float, from: Vector2) -> void:
	if act == Act.DEAD:
		return
	health -= amount
	# Knockback scaled by mass. A Kadaver at 0.35 barely registers a hit, which
	# is the same fact as its 220 health told a second way -- through the body
	# rather than through a number the player cannot see.
	var away := (global_position - from).normalized()
	velocity += away * 260.0 * profile.mass_knockback
	if health <= 0.0:
		act = Act.DEAD
		died.emit()


func _physics_process(delta: float) -> void:
	step(delta)


## Split out so a headless probe can drive it at a fixed delta.
func step(delta: float) -> void:
	if act == Act.DEAD:
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
		velocity.y += _gravity * delta
		move_and_slide()
		return

	brain.step(delta, global_position, player_pos, player_perception, sight_blocked)

	match act:
		Act.IDLE, Act.CHASE:
			_think(delta)
		Act.WINDUP:
			_timer -= delta
			if _timer <= 0.0:
				act = Act.STRIKE
				_timer = profile.strike
				_strike_hit_sent = false
				struck.emit()
		Act.STRIKE:
			_timer -= delta
			if _timer <= 0.0:
				act = Act.RECOVER
				_timer = profile.recover
		Act.RECOVER:
			_timer -= delta
			if _timer <= 0.0:
				act = Act.CHASE

	# Committed to the swing: no steering out of a telegraph. Being able to
	# cancel a wind-up would make the tell a lie, and the tell is the contract.
	if act == Act.WINDUP or act == Act.STRIKE or act == Act.RECOVER:
		velocity.x = move_toward(velocity.x, 0.0, 1400.0 * delta)

	velocity.y += _gravity * delta
	move_and_slide()


func _think(delta: float) -> void:
	var want = brain.desired_target()
	if want == null:
		act = Act.IDLE
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		return

	act = Act.CHASE
	var to: Vector2 = want - global_position
	brain.set_facing(to.x)

	if brain.state == EnemyBrain.State.ALERT and to.length() <= profile.attack_range:
		act = Act.WINDUP
		_timer = profile.windup
		velocity.x = 0.0
		telegraphed.emit("leap" if profile.can_leap else "strike")
		return

	velocity.x = move_toward(velocity.x, signf(to.x) * profile.move_speed,
		profile.move_speed * 6.0 * delta)
