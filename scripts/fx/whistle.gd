class_name Whistle
extends Node

## The whistle that precedes a Baureihe 7, generated rather than sampled.
##
## CANON, and it is the best tell in the game: whistlers do not hunt, they
## ANSWER. Allied troops worked that out in the field before intelligence did.
## The things respond, and somewhere behind them a man is blowing.
##
## **The horror is not the thing coming at you. It is that it was sent.**
##
## HARD RULE, carried into code so it cannot be lost to a good idea about a
## boss fight: **NEVER SHOW THE HANDLER.** There is no handler entity, no spawn
## marker, no silhouette. A whistle with nobody visible behind it is the whole
## faction. EnemyProbe asserts no unit in the roster is a handler; this class
## asserts the other half by having no position of its own that resolves to a
## body -- it plays from OFF-SCREEN, always, by construction.
##
## WHY PROCEDURAL RATHER THAN A SAMPLE. This is a gameplay signal with timing
## requirements, not a sound effect: it must fire a specific lead time before
## the unit commits, from a direction, at a distance the player can judge. A
## generated tone can be retimed, retuned and repositioned per encounter; a
## sample is one whistle forever. The original build ran a fully procedural
## audio engine, so the approach is proven on this project.
##
## The sound itself is a two-tone parade whistle: a breathy fundamental with a
## trill, which is what a real pea whistle does and what makes it read as a
## man rather than as an alarm.

const SAMPLE_HZ := 22050.0

## Fundamental, Hz. Around 2.2kHz is where a real whistle sits.
@export var pitch: float = 2180.0
## The trill: a second tone slightly off, beating against the first.
@export var beat_hz: float = 7.0
@export var duration: float = 0.42
## 0 = far left, 1 = far right. Set from the unit's direction, never its exact
## position -- the player should learn a SIDE, not a coordinate.
@export var pan: float = 0.5
## 0..1, from distance. Quiet does not mean safe; it means not yet.
@export var loudness: float = 0.8

var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _t: float = 0.0
var _left: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = SAMPLE_HZ
	gen.buffer_length = 0.25
	_player.stream = gen
	add_child(_player)
	_rng.randomize()


## Blow it. Returns false if audio is unavailable, so a caller can fall back to
## a visual cue rather than silently losing the tell -- a warning that does not
## arrive is worse than no warning, because the player has learned to expect it.
func blow() -> bool:
	if _player == null:
		return false
	_player.play()
	_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback
	if _playback == null:
		return false
	_t = 0.0
	_left = duration
	return true


func is_blowing() -> bool:
	return _left > 0.0


func _process(_delta: float) -> void:
	if _playback == null or _left <= 0.0:
		return
	_fill()


func _fill() -> void:
	var frames := _playback.get_frames_available()
	if frames <= 0:
		return
	var step := 1.0 / SAMPLE_HZ
	for i in range(frames):
		if _left <= 0.0:
			_playback.push_frame(Vector2.ZERO)
			continue
		var s := _sample(_t)
		# Equal-power pan, so moving the whistle across the field does not
		# change how loud it seems -- distance is the loudness channel and
		# direction must not steal it.
		var l := s * cos(pan * PI * 0.5)
		var r := s * sin(pan * PI * 0.5)
		_playback.push_frame(Vector2(l, r))
		_t += step
		_left -= step


## One sample of the whistle at time t.
func _sample(t: float) -> float:
	# Envelope: fast attack, a body, a quick release. A slow attack would make
	# the lead time meaningless because the player would notice it late.
	var a := 0.012
	var rel := 0.09
	var env := 1.0
	if t < a:
		env = t / a
	elif t > duration - rel:
		env = maxf(0.0, (duration - t) / rel)

	# Two tones a few Hz apart give the beat that reads as a pea whistle.
	var f1 := pitch
	var f2 := pitch + beat_hz * 9.0
	var tone := sin(TAU * f1 * t) * 0.6 + sin(TAU * f2 * t) * 0.4

	# The trill: amplitude wobble at beat_hz.
	tone *= 0.75 + 0.25 * sin(TAU * beat_hz * t)

	# Breath. A pure tone is a machine; a whistle is a person out of breath.
	var breath := (_rng.randf() - 0.5) * 0.18

	return clampf((tone + breath) * env * loudness * 0.5, -1.0, 1.0)


## Set direction and distance from the listener. Distance only affects
## loudness; the pan is quantised to left/centre/right so the player learns a
## side rather than trying to triangulate.
func aim_from(listener: Vector2, source: Vector2, max_range: float = 1600.0) -> void:
	var d := listener.distance_to(source)
	loudness = clampf(1.0 - d / maxf(max_range, 1.0), 0.12, 1.0)
	var dx := source.x - listener.x
	if dx < -60.0:
		pan = 0.12
	elif dx > 60.0:
		pan = 0.88
	else:
		pan = 0.5
