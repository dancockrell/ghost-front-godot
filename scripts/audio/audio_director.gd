class_name AudioDirector
extends Node

## Plays the catalogue, and decides what the player actually hears.
##
## THE MIX IS THE DESIGN. Bad game audio is almost never bad sounds; it is
## twelve good sounds arriving at once and the important one losing. So this
## has a voice budget and a priority rule, and the rule is stated rather than
## emergent:
##
##   - A fixed number of voices. When they are full, an incoming sound may
##     STEAL a quieter one, and only if it outranks it.
##   - Priority is the design order, not the loudness order. The whistle is 10
##     because the player has been TAUGHT to act on it, and a warning that does
##     not arrive is worse than no warning at all.
##   - Identical sounds within a few milliseconds are collapsed. Three impacts
##     on the same frame is one impact, three times as loud, and that is what
##     turns a firefight into mush.
##
## Everything is generated. See Sfx for why.

const SAMPLE_HZ := 22050.0
## More than this and a busy moment turns to mush regardless of priority.
const MAX_VOICES := 10
## Two requests for the same id inside this window are one sound.
const COALESCE_SEC := 0.045

class Voice extends RefCounted:
	var recipe: Sfx.Recipe
	var t: float = 0.0
	var pan: float = 0.5
	var gain: float = 1.0
	var player: AudioStreamPlayer
	var playback: AudioStreamGeneratorPlayback
	var rng := RandomNumberGenerator.new()
	var active: bool = false

var _voices: Array = []
var _last_played := {}      # id -> time it last started
var _clock: float = 0.0
var _muted: bool = false
## Per-bus gain, 0..1. Music ducks under a boss telegraph, for example.
var _bus_gain := {
	Sfx.Bus.MASTER: 1.0, Sfx.Bus.MUSIC: 0.55,
	Sfx.Bus.SFX: 0.9, Sfx.Bus.VOICE: 1.0, Sfx.Bus.UI: 0.75,
}

## Counters, for the probe and for a mix pass. A director that silently drops
## everything and one that is simply quiet sound identical.
var played_count: int = 0
var stolen_count: int = 0
var coalesced_count: int = 0
var refused_count: int = 0


func _ready() -> void:
	for i in range(MAX_VOICES):
		var v := Voice.new()
		v.player = AudioStreamPlayer.new()
		var gen := AudioStreamGenerator.new()
		gen.mix_rate = SAMPLE_HZ
		gen.buffer_length = 0.2
		v.player.stream = gen
		add_child(v.player)
		v.rng.randomize()
		_voices.append(v)


func set_muted(m: bool) -> void:
	_muted = m


func is_muted() -> bool:
	return _muted


func set_bus_gain(bus: int, g: float) -> void:
	_bus_gain[bus] = clampf(g, 0.0, 1.0)


func bus_gain(bus: int) -> float:
	return float(_bus_gain.get(bus, 1.0))


## Play a sound by id. `pan` 0..1, `gain` scales it.
## Returns true if it will be heard.
func play(id: String, pan: float = 0.5, gain: float = 1.0) -> bool:
	var r := Sfx.by_id(id)
	if r == null:
		refused_count += 1
		return false

	# ---- coalesce. Three impacts on one frame is one impact, and letting all
	# three through is what makes a busy moment unreadable.
	var last: float = float(_last_played.get(id, -999.0))
	if _clock - last < COALESCE_SEC:
		coalesced_count += 1
		return false

	var slot := _free_voice()
	if slot == null:
		slot = _steal_for(r)
		if slot == null:
			refused_count += 1
			return false
		stolen_count += 1

	_last_played[id] = _clock
	slot.recipe = r
	slot.t = 0.0
	slot.pan = clampf(pan, 0.0, 1.0)
	slot.gain = gain
	slot.active = true
	played_count += 1
	if not _muted and slot.player != null:
		slot.player.play()
		slot.playback = slot.player.get_stream_playback() as AudioStreamGeneratorPlayback
	return true


func _free_voice() -> Voice:
	for v in _voices:
		if not v.active:
			return v
	return null


## Steal only from something this sound OUTRANKS. A high-priority sound never
## loses to a low one, which is the whole reason priority exists.
func _steal_for(r: Sfx.Recipe) -> Voice:
	var worst: Voice = null
	var worst_p := 999
	for v in _voices:
		if v.recipe == null:
			continue
		if v.recipe.priority < worst_p:
			worst_p = v.recipe.priority
			worst = v
	if worst != null and r.priority > worst_p:
		return worst
	return null


func active_voices() -> int:
	var n := 0
	for v in _voices:
		if v.active:
			n += 1
	return n


func _process(delta: float) -> void:
	_clock += delta
	for v in _voices:
		if not v.active:
			continue
		if v.playback != null and not _muted:
			_fill(v)
		v.t += delta
		if v.t >= v.recipe.duration:
			v.active = false
			v.playback = null
			if v.player != null:
				v.player.stop()


func _fill(v: Voice) -> void:
	var frames := v.playback.get_frames_available()
	if frames <= 0:
		return
	var step := 1.0 / SAMPLE_HZ
	var g := v.gain * bus_gain(v.recipe.bus) * bus_gain(Sfx.Bus.MASTER)
	var t := v.t
	for i in range(frames):
		var s := 0.0
		if t < v.recipe.duration:
			s = Sfx.sample(v.recipe, t, v.rng) * g
		# equal-power pan: moving a sound across the field must not change how
		# loud it seems, because loudness is the distance channel
		v.playback.push_frame(Vector2(s * cos(v.pan * PI * 0.5),
			s * sin(v.pan * PI * 0.5)))
		t += step


## Pan from a world position relative to the listener. Quantised to three
## sides on purpose -- the player should learn a DIRECTION, not triangulate.
func pan_for(listener_x: float, source_x: float) -> float:
	var dx := source_x - listener_x
	if dx < -80.0:
		return 0.15
	if dx > 80.0:
		return 0.85
	return 0.5


## Distance falloff. Never reaches zero: a distant whistle is still a whistle,
## and silence would teach the player that far away means safe.
func gain_for(listener: Vector2, source: Vector2, max_range: float = 1800.0) -> float:
	var d := listener.distance_to(source)
	return clampf(1.0 - d / maxf(max_range, 1.0), 0.14, 1.0)
