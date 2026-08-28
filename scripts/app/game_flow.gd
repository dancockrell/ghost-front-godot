class_name GameFlow
extends RefCounted

## Every screen the game has, and every way to get between them.
##
## THE WHOLE POINT OF THIS FILE IS THE RETURN PATH. It is easy to build a game
## that boots, plays and dies; what gets skipped is the graceful way back, and
## the symptom is a game you have to close and relaunch after a death. So every
## terminal state here has an explicit route home, and the probe asserts that
## NO STATE IS A DEAD END -- from any screen, some sequence of inputs reaches
## the title.
##
## THE DEATH LOOP IS THE DESIGN. In this genre you will die a great deal, so
## the cost of dying must be small and the return must be fast:
##
##   die -> a short beat to read what killed you -> retry the SAME level,
##   from the last checkpoint, with the loadout you had.
##
## Anything longer than about two seconds between death and control is the
## thing players quit over. There is no "you died" screen with a menu on it,
## because a menu after a death is a punishment for playing.
##
## GAME OVER is separate and rarer: lives exhausted. That one returns to stage
## select rather than to the title, because sending a player to the title after
## an hour is throwing their session away.
##
## Camp Iron Bell frames all of it. A death is not a failure screen, it is a
## RECOVERY: the programme pulls the agent back and files the attempt. That is
## the fiction doing the work of a retry prompt.

enum State {
	## Engine warm-up. No input accepted. Exists so the first frame is never
	## a black screen with a live control scheme behind it.
	BOOT,
	## The title. W.D. letterhead, one prompt.
	TITLE,
	## Chapter select. The mission board.
	SELECT,
	## The pre-mission briefing, skippable. Handler speaks.
	BRIEF,
	## Playing.
	PLAY,
	## Paused. Nothing simulates.
	PAUSE,
	## The short beat after death, before control returns.
	RECOVERING,
	## Lives exhausted.
	GAME_OVER,
	## The level was completed. Weapon issued, docket filed.
	DEBRIEF,
	## The campaign is finished.
	CREDITS,
}

## Transitions, as data rather than as a pile of ifs. Every allowed move is
## here, so an illegal one is impossible rather than merely unlikely, and the
## reachability check below can be a graph walk instead of a play-through.
const ALLOWED := {
	State.BOOT: [State.TITLE],
	State.TITLE: [State.SELECT, State.CREDITS],
	State.SELECT: [State.BRIEF, State.TITLE],
	State.BRIEF: [State.PLAY, State.SELECT],
	State.PLAY: [State.PAUSE, State.RECOVERING, State.DEBRIEF],
	State.PAUSE: [State.PLAY, State.SELECT, State.TITLE],
	State.RECOVERING: [State.PLAY, State.GAME_OVER],
	State.GAME_OVER: [State.SELECT, State.TITLE],
	State.DEBRIEF: [State.SELECT, State.CREDITS],
	State.CREDITS: [State.TITLE],
}

## How long the player is out of control after a death. Short on purpose:
## long enough to read what happened, short enough not to punish.
const RECOVER_SECONDS := 1.35
## Lives before a game over. Generous, because the levels are meant to be
## sharp and the retry loop is meant to be cheap.
const STARTING_LIVES := 4

signal changed(from: int, to: int)
signal died(lives_left: int)
signal game_over()

var state: int = State.BOOT
var lives: int = STARTING_LIVES
var current_level: int = 0
## Which chapters have been completed, by id.
var cleared := {}
## Weapons issued so far, carried across levels.
var issued: Array = []

var _recover_t: float = 0.0


func can_go(to: int) -> bool:
	return ALLOWED.get(state, []).has(to)


## Attempt a transition. Refuses illegal moves rather than allowing them,
## because a state machine that permits anything is not a state machine.
func go(to: int) -> bool:
	if not can_go(to):
		return false
	var from := state
	state = to
	if to == State.RECOVERING:
		_recover_t = RECOVER_SECONDS
	changed.emit(from, to)
	return true


func start_new_run() -> void:
	lives = STARTING_LIVES
	cleared.clear()
	issued.clear()
	current_level = 0


## The agent went down. Camp Iron Bell files it and pulls them back.
func on_death() -> void:
	if state != State.PLAY:
		return
	lives -= 1
	died.emit(lives)
	go(State.RECOVERING)


## The level was completed; the weapon is issued.
func on_cleared(level_id: String, grants: String) -> void:
	cleared[level_id] = true
	if grants != "" and not issued.has(grants):
		issued.append(grants)
	go(State.DEBRIEF)


func step(delta: float) -> void:
	if state != State.RECOVERING:
		return
	_recover_t -= delta
	if _recover_t > 0.0:
		return
	# THE RETURN PATH. Out of lives goes to game over; otherwise straight back
	# into play with no menu in between.
	if lives <= 0:
		go(State.GAME_OVER)
		game_over.emit()
	else:
		go(State.PLAY)


func recover_remaining() -> float:
	return maxf(0.0, _recover_t)


func all_cleared() -> bool:
	return cleared.size() >= Campaign.all().size()


static func state_name(s: int) -> String:
	match s:
		State.BOOT: return "BOOT"
		State.TITLE: return "TITLE"
		State.SELECT: return "SELECT"
		State.BRIEF: return "BRIEF"
		State.PLAY: return "PLAY"
		State.PAUSE: return "PAUSE"
		State.RECOVERING: return "RECOVERING"
		State.GAME_OVER: return "GAME OVER"
		State.DEBRIEF: return "DEBRIEF"
		State.CREDITS: return "CREDITS"
		_: return "?"


static func all_states() -> Array:
	return [State.BOOT, State.TITLE, State.SELECT, State.BRIEF, State.PLAY,
		State.PAUSE, State.RECOVERING, State.GAME_OVER, State.DEBRIEF,
		State.CREDITS]


## What Camp Iron Bell says on each screen. The programme frames a death as a
## recovery and files it, which is the fiction doing the work of a retry prompt.
static func caption(s: int) -> String:
	match s:
		State.TITLE:
			return "WAR DEPARTMENT -- PROJECT 42 -- CAMP IRON BELL, MISSISSIPPI"
		State.SELECT:
			return "TASKING BOARD. Select an operation."
		State.BRIEF:
			return "Form 42-A attached. Read it or don't; it'll be filed either way."
		State.RECOVERING:
			return "Recovery in progress. Hold still. This is normal."
		State.GAME_OVER:
			return "Operation suspended pending review. Nobody is blaming anybody."
		State.DEBRIEF:
			return "Return logged. The recovered principle has been issued to you."
		State.CREDITS:
			return "File closed."
		_:
			return ""
