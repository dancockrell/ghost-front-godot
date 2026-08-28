class_name Projectile
extends Node2D

## One shot in flight.
##
## Deliberately NOT a physics body. A Mega Man shot needs exact, predictable
## travel and a hitbox the player can learn -- a rigid body gets nudged by
## collisions, sleeps, and tunnels at speed, none of which a player can read.
## So this is a position, a velocity, and a radius, stepped by hand.
##
## THE THREE-SHOT CAP IS A DESIGN CHOICE, NOT A BUDGET. Mega Man limits shots
## on screen so firing has rhythm: you cannot hold the trigger and win, and
## spacing your shots is a skill. The cap lives in WeaponSpec.max_live and is
## enforced by the weapon system, not here.

signal expired(p: Projectile)
signal struck(p: Projectile, target: Node)

var spec: WeaponSpec
var velocity := Vector2.ZERO
var damage: float = 0.0
var radius: float = 9.0
var life: float = 1.0
## Charged shots are bigger, hit harder, and pass through the first thing they
## kill -- the reward for waiting is not just damage, it is reach.
var charged: bool = false
var pierce: int = 0
var from_player: bool = true

var _age: float = 0.0
var _hit := {}


func setup(w: WeaponSpec, at: Vector2, dir: Vector2, is_charged: bool = false) -> void:
	spec = w
	global_position = at
	charged = is_charged
	damage = w.charge_damage if is_charged else w.damage
	radius = w.charge_radius if is_charged else w.radius
	life = w.lifetime
	pierce = 2 if is_charged else 0
	var d := dir.normalized()
	if d == Vector2.ZERO:
		d = Vector2.RIGHT
	velocity = d * w.speed


## Advance. Returns false when it should be removed.
func step(delta: float) -> bool:
	_age += delta
	if _age >= life:
		return false
	# PLACED weapons sit where they land and do their work over time; a
	# lingering culture is not a bullet and should not behave like one.
	if spec != null and spec.kind == WeaponSpec.Kind.PLACED:
		velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
	global_position += velocity * delta
	return true


func age() -> float:
	return _age


## True if this shot has already hit `who`, so a piercing shot cannot hit the
## same body twice per frame or on consecutive frames.
func already_hit(who: Node) -> bool:
	return _hit.has(who.get_instance_id())


func mark_hit(who: Node) -> void:
	_hit[who.get_instance_id()] = true


func hits(target_pos: Vector2, target_radius: float) -> bool:
	return global_position.distance_to(target_pos) <= radius + target_radius


func _draw() -> void:
	if spec == null:
		return
	var c: Color = spec.tint
	match spec.kind:
		WeaponSpec.Kind.PLACED:
			# fades as it expires, so its remaining life is readable
			var t := 1.0 - clampf(_age / maxf(life, 0.01), 0.0, 1.0)
			draw_circle(Vector2.ZERO, radius, Color(c.r, c.g, c.b, 0.20 * t))
			draw_circle(Vector2.ZERO, radius * 0.42, Color(c.r, c.g, c.b, 0.55 * t))
		WeaponSpec.Kind.SWEEP:
			draw_arc(Vector2.ZERO, radius, -0.9, 0.9, 20, c, 5.0)
		WeaponSpec.Kind.BEAM:
			draw_line(Vector2.ZERO, velocity.normalized() * 900.0, c, 4.0)
		_:
			draw_circle(Vector2.ZERO, radius, c)
			if charged:
				draw_circle(Vector2.ZERO, radius * 1.6, Color(c.r, c.g, c.b, 0.28))


func _process(_d: float) -> void:
	queue_redraw()
