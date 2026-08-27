class_name ChronoRewind
extends RefCounted

## CHRONO -- rewind your own position and velocity.
##
## Project 42's first pillar is the retrieval programme: reaching into the past
## and pulling something out of it. Rewinding yourself is the smallest possible
## version of the thing the whole faction does, which is why this is the verb
## rather than a generic time-slow.
##
## Design intent: make the game GENEROUS WITHOUT MAKING IT EASY. A missed jump
## should cost you seconds, not a checkpoint reload -- retry friction is what
## makes a hard platformer feel mean, and it is entirely separable from
## difficulty. The levels are then free to be sharp.
##
## Implementation is a fixed-size ring buffer of snapshots taken once per
## physics frame. Ring rather than an appending Array on purpose: this records
## every single frame forever, and an Array that grows unboundedly during a
## long session is a memory leak with a stopwatch on it.

## Seconds of history kept. At 60Hz this is the ring's length in frames.
var duration: float = 3.0
## How many seconds of recorded time are consumed per second of rewinding.
## Above 1 the rewind reads as a snap rather than a scrub, which is what keeps
## it feeling like a correction instead of a cutscene.
var rate: float = 2.4

var _pos := PackedVector2Array()
var _vel := PackedVector2Array()
var _capacity: int = 0
var _head: int = 0        # next write slot
var _count: int = 0       # how many valid samples are stored
var _tick: float = 1.0 / 60.0

var _rewinding: bool = false
var _debt: float = 0.0    # fractional frames owed, so rate need not be integral


func _init(physics_tick: float = 1.0 / 60.0, seconds: float = 3.0,
		rewind_rate: float = 2.4) -> void:
	_tick = physics_tick
	duration = seconds
	rate = rewind_rate
	_capacity = maxi(2, int(ceil(duration / _tick)))
	_pos.resize(_capacity)
	_vel.resize(_capacity)


## Seconds of history currently available to rewind through.
func available() -> float:
	return float(_count) * _tick


func fraction() -> float:
	return clampf(available() / maxf(duration, 0.0001), 0.0, 1.0)


func is_rewinding() -> bool:
	return _rewinding


func clear() -> void:
	_count = 0
	_head = 0
	_debt = 0.0
	_rewinding = false


func record(pos: Vector2, vel: Vector2) -> void:
	_pos[_head] = pos
	_vel[_head] = vel
	_head = (_head + 1) % _capacity
	_count = mini(_count + 1, _capacity)


## Pop the most recent sample. Returns false when history is exhausted, which
## is the caller's cue to hand control back to normal physics.
func _pop() -> bool:
	if _count <= 0:
		return false
	_head = (_head - 1 + _capacity) % _capacity
	_count -= 1
	return true


func _peek() -> Dictionary:
	var i := (_head - 1 + _capacity) % _capacity
	return {"pos": _pos[i], "vel": _vel[i]}


## Drive one physics frame.
##
## Returns a Dictionary: {active: bool, pos: Vector2, vel: Vector2}.
## When active is true the caller must place the body at pos and set vel,
## and must NOT run gravity or movement for that frame.
func step(delta: float, wants_rewind: bool, pos: Vector2, vel: Vector2) -> Dictionary:
	if wants_rewind and _count > 0:
		_rewinding = true
		# Consume history at `rate` times real time, carrying the fraction so a
		# non-integral rate does not quietly round down to a slower rewind.
		_debt += (delta * rate) / _tick
		var frames := int(_debt)
		_debt -= float(frames)
		var last := _peek()
		for i in range(frames):
			if not _pop():
				break
			if _count > 0:
				last = _peek()
		if _count <= 0:
			_rewinding = false
			_debt = 0.0
		# Velocity is negated so that releasing rewind mid-arc hands back a
		# body moving the way it appears to be moving. Handing back the
		# original forward velocity makes the release read as a lurch.
		return {"active": true, "pos": last.pos, "vel": -last.vel}

	if _rewinding:
		_rewinding = false
		_debt = 0.0
	record(pos, vel)
	return {"active": false, "pos": pos, "vel": vel}
