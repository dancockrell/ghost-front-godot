class_name MissionState
extends RefCounted

## Insert, traverse, secure, extract with the alarm up.
##
## THE SHAPE, and why it is this shape: the level is walked TWICE. Out is quiet
## and yours to plan; back is loud, and it is the same geometry with every
## assumption removed. That gets a set piece out of level content already built,
## and more importantly it makes the return leg *legible* -- the player already
## knows the room, so every change to it reads as a change rather than as
## unfamiliar level design.
##
## SECURING THE SUBJECT ALWAYS RAISES THE ALARM. Not on a detection roll, not
## as a punishment for sloppiness: always. A stealth game where perfect play
## skips the climax has built its best content for the players least likely to
## see it. The quiet leg rewards you by deciding *how much* the loud leg knows,
## which is a real reward that does not cost the set piece.
##
## THE CONSISTENCY FINDING sits under all of this and is never stated. The
## subject's absence was already accommodated by the record before the agent
## was sent. Whatever happens on this level, it was always going to have gone
## that way. Nothing here says so and nothing should -- but the structure
## assumes it, so the eventual dialogue has somewhere to stand.

enum Phase { INSERT, TRAVERSE, SECURED, EXTRACT, COMPLETE, FAILED }

signal phase_changed(from: int, to: int)
signal alarm_raised(reason: String)
signal alarm_level_changed(level: float)

## Where the agent came in, and where they must return to.
var insertion_point := Vector2.ZERO
## Where the subject is.
var subject_point := Vector2.ZERO

var phase: int = Phase.INSERT

## 0 = nobody knows anything. 1 = the whole site is looking.
## A float rather than a bool so the quiet leg can pay off in degrees: arriving
## at the subject unseen means the extraction starts at the floor of the alarm
## rather than at its ceiling.
var alarm: float = 0.0
## Where the alarm starts when the subject is secured. Set by how quietly the
## outbound leg went; see record_detection().
var _carried_suspicion: float = 0.0

## True once the subject is in hand.
var carrying: bool = false

## Seconds elapsed, for the debrief rather than for pressure. There is no timer
## on the extraction: a countdown would turn the return leg into an execution
## test, and the return leg is meant to be about a route you already know
## becoming hostile, not about speed.
var elapsed: float = 0.0

## How much the alarm decays per second when nothing can see the agent. Slow:
## the site does not forget a breach, it only stops actively looking.
var alarm_decay: float = 0.06
## The alarm never falls below this once raised. A site that can return to
## total ignorance makes the loud leg optional again.
var alarm_floor_after_raise: float = 0.35
var _has_been_raised: bool = false


func _set_phase(p: int) -> void:
	if p == phase:
		return
	var from := phase
	phase = p
	phase_changed.emit(from, p)


## Called by the level when an enemy reaches ALERT on the outbound leg.
## Does NOT raise the alarm outright -- being seen once on the way in is a
## setback, not a failure, and it is banked into how bad the way out will be.
func record_detection(weight: float = 0.25) -> void:
	_carried_suspicion = clampf(_carried_suspicion + weight, 0.0, 1.0)
	if phase == Phase.EXTRACT or phase == Phase.SECURED:
		raise_alarm("seen")
	else:
		set_alarm(maxf(alarm, _carried_suspicion * 0.6))


func set_alarm(v: float) -> void:
	var lo := alarm_floor_after_raise if _has_been_raised else 0.0
	var nv := clampf(v, lo, 1.0)
	if not is_equal_approx(nv, alarm):
		alarm = nv
		alarm_level_changed.emit(alarm)


func raise_alarm(reason: String) -> void:
	_has_been_raised = true
	var was := alarm
	set_alarm(1.0)
	if was < 1.0:
		alarm_raised.emit(reason)


## The agent has reached the subject.
func secure_subject() -> void:
	if phase != Phase.INSERT and phase != Phase.TRAVERSE:
		return
	carrying = true
	_set_phase(Phase.SECURED)
	# Always. See the class comment.
	raise_alarm("subject secured")
	_set_phase(Phase.EXTRACT)


## The agent is back at the insertion point with the subject.
func complete() -> void:
	if phase != Phase.EXTRACT or not carrying:
		return
	_set_phase(Phase.COMPLETE)


func fail(_reason: String = "") -> void:
	_set_phase(Phase.FAILED)


func is_over() -> bool:
	return phase == Phase.COMPLETE or phase == Phase.FAILED


## Where the agent should currently be heading. The objective marker reads this
## so there is exactly one source of truth about what the mission wants.
func objective() -> Vector2:
	return insertion_point if carrying else subject_point


func step(delta: float, anyone_sees_agent: bool) -> void:
	if is_over():
		return
	elapsed += delta
	if phase == Phase.INSERT and elapsed > 0.5:
		_set_phase(Phase.TRAVERSE)
	if not anyone_sees_agent:
		set_alarm(alarm - alarm_decay * delta)


## How much the site knows, as a multiplier enemies apply to their own starting
## awareness. Kept here rather than in EnemyBrain so that "what the site knows"
## is one number in one place, and an enemy spawned late inherits it.
func awareness_bias() -> float:
	return alarm * 0.9


func phase_name() -> String:
	match phase:
		Phase.INSERT: return "INSERT"
		Phase.TRAVERSE: return "TRAVERSE"
		Phase.SECURED: return "SECURED"
		Phase.EXTRACT: return "EXTRACT"
		Phase.COMPLETE: return "COMPLETE"
		_: return "FAILED"
