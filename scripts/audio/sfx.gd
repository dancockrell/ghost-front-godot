class_name Sfx
extends RefCounted

## Every sound in the game, as a synthesis recipe rather than a file.
##
## WHY PROCEDURAL. Three reasons, in order of weight:
##
## 1. **Sounds here are gameplay signals with timing requirements.** The
##    whistle must fire a specific lead before a unit commits; a boss telegraph
##    must be audible before the strike; the attenuation tone must track a
##    continuous meter. A sample is one performance forever. A recipe can be
##    retimed, retuned and repositioned per event.
##
## 2. **Licence.** docs/RESOURCES.md records what happened when I checked:
##    Freesound hosts CC-BY-NC beside CC0, and a search summary confidently
##    told me a shader site defaulted to CC0 when it does not. Generated audio
##    has no licence question at all.
##
## 3. The retired build proved a fully procedural audio engine works on this
##    project, so this is a known-good road rather than an experiment.
##
## THE MIX IS A DESIGN DOCUMENT. Every entry carries a `bus` and a `duck`
## priority, because the thing that ruins game audio is not bad sounds, it is
## twelve good sounds at once. The whistle must cut through a firefight, or the
## warning it exists to give does not arrive.

enum Bus { MASTER, MUSIC, SFX, VOICE, UI }

## Waveform families. Kept small on purpose: four shapes and an envelope cover
## everything this game needs, and a larger vocabulary would invite fiddling.
enum Wave { SINE, SQUARE, SAW, NOISE }

class Recipe extends RefCounted:
	var id: String = ""
	var bus: int = Bus.SFX
	## Higher wins the duck. The whistle outranks gunfire because it is a
	## warning; a warning nobody hears is worse than no warning.
	var priority: int = 5
	var wave: int = Wave.SINE
	## Start and end frequency, Hz. A falling tone reads as impact, a rising
	## one as charge, and that is most of sound design for a game like this.
	var f0: float = 440.0
	var f1: float = 440.0
	var duration: float = 0.2
	var attack: float = 0.005
	var release: float = 0.06
	var gain: float = 0.5
	## Noise mixed in over the tone, 0..1. Breath, grit, impact.
	var noise: float = 0.0
	## Amplitude wobble, Hz. 0 for none.
	var trill: float = 0.0
	## Second voice, detuned by this many Hz. 0 for none. Two close tones beat
	## against each other and read as mechanical rather than electronic.
	var beat: float = 0.0

	func _init(sid: String) -> void:
		id = sid


static func _r(id: String, bus: int, prio: int, wave: int, f0: float,
		f1: float, dur: float, gain: float, noise: float = 0.0,
		trill: float = 0.0, beat: float = 0.0) -> Recipe:
	var x := Recipe.new(id)
	x.bus = bus
	x.priority = prio
	x.wave = wave
	x.f0 = f0
	x.f1 = f1
	x.duration = dur
	x.gain = gain
	x.noise = noise
	x.trill = trill
	x.beat = beat
	return x


## THE CATALOGUE. Every sound the game makes, in one place, so the mix can be
## reasoned about as a whole rather than discovered by playing.
static func catalogue() -> Array:
	return [
		# ---- the agent's own kit. Current is Tesla's work, so it is
		# electrical and slightly unstable rather than clean sci-fi.
		_r("buster", Bus.SFX, 4, Wave.SQUARE, 620.0, 300.0, 0.09, 0.30, 0.25),
		_r("buster_charged", Bus.SFX, 6, Wave.SAW, 340.0, 120.0, 0.28, 0.45, 0.30, 0.0, 7.0),
		_r("charge_loop", Bus.SFX, 3, Wave.SAW, 180.0, 900.0, 0.95, 0.16, 0.08),
		_r("charge_ready", Bus.SFX, 5, Wave.SINE, 900.0, 1200.0, 0.10, 0.22),
		_r("phase", Bus.SFX, 6, Wave.NOISE, 1400.0, 220.0, 0.16, 0.34, 0.85),
		_r("arc_attach", Bus.SFX, 5, Wave.SAW, 240.0, 760.0, 0.14, 0.30, 0.35),
		_r("rewind", Bus.SFX, 7, Wave.SINE, 700.0, 190.0, 0.5, 0.26, 0.10, 5.0),
		_r("jump", Bus.SFX, 3, Wave.SINE, 380.0, 560.0, 0.07, 0.16),
		_r("land", Bus.SFX, 3, Wave.NOISE, 200.0, 90.0, 0.08, 0.20, 0.7),

		# ---- THE WHISTLE. Highest priority in the game. It is the one sound
		# that must never be lost in a mix, because the player has been taught
		# to act on it and a warning that does not arrive is worse than none.
		_r("whistle", Bus.SFX, 10, Wave.SINE, 2180.0, 2180.0, 0.42, 0.55, 0.18, 7.0, 63.0),

		# ---- the Werk. Nothing they do is elegant, so nothing they do is
		# clean: everything is mass, machinery and air.
		_r("werk_telegraph", Bus.SFX, 8, Wave.SAW, 90.0, 130.0, 0.35, 0.28, 0.20),
		_r("werk_strike", Bus.SFX, 7, Wave.NOISE, 160.0, 60.0, 0.18, 0.42, 0.75),
		_r("werk_hurt", Bus.SFX, 5, Wave.SQUARE, 210.0, 150.0, 0.10, 0.24, 0.40),
		_r("werk_down", Bus.SFX, 8, Wave.SAW, 220.0, 40.0, 0.75, 0.40, 0.45),
		_r("bread", Bus.SFX, 2, Wave.NOISE, 300.0, 260.0, 1.2, 0.07, 0.9),

		# ---- the agent taking damage. Deliberately NOT a scream: the horror
		# in this game is bureaucratic, and a hit is a coherence event.
		_r("hurt", Bus.SFX, 9, Wave.SQUARE, 320.0, 140.0, 0.16, 0.36, 0.35),
		_r("attenuate", Bus.SFX, 6, Wave.SINE, 120.0, 118.0, 0.9, 0.20, 0.05, 0.0, 3.0),
		_r("unstable", Bus.SFX, 8, Wave.SAW, 60.0, 58.0, 1.4, 0.24, 0.15, 0.0, 2.0),
		_r("death", Bus.SFX, 10, Wave.SINE, 440.0, 55.0, 1.6, 0.45, 0.20),

		# ---- pickups and paperwork
		_r("document", Bus.UI, 6, Wave.SINE, 700.0, 940.0, 0.13, 0.24),
		_r("issue", Bus.UI, 7, Wave.SINE, 520.0, 1040.0, 0.4, 0.32, 0.0, 0.0, 3.0),
		_r("subject", Bus.UI, 8, Wave.SINE, 300.0, 700.0, 0.5, 0.30),

		# ---- the front end. A War Department form makes typewriter noises.
		_r("ui_move", Bus.UI, 4, Wave.NOISE, 900.0, 700.0, 0.035, 0.16, 0.8),
		_r("ui_select", Bus.UI, 6, Wave.SQUARE, 240.0, 240.0, 0.05, 0.26, 0.5),
		_r("ui_back", Bus.UI, 5, Wave.SQUARE, 180.0, 140.0, 0.07, 0.22, 0.4),
		_r("stamp", Bus.UI, 8, Wave.NOISE, 140.0, 70.0, 0.13, 0.42, 0.85),
		_r("typewriter", Bus.UI, 3, Wave.NOISE, 1200.0, 800.0, 0.02, 0.12, 0.9),

		# ---- alarm
		_r("alarm", Bus.SFX, 9, Wave.SQUARE, 480.0, 640.0, 0.7, 0.30, 0.0, 4.0),
	]


static func by_id(id: String) -> Recipe:
	for r in catalogue():
		if r.id == id:
			return r
	return null


static func ids() -> Array:
	var a: Array = []
	for r in catalogue():
		a.append(r.id)
	return a


## Render one sample of a recipe at time t. Shared by the live player and by
## any offline renderer, so what a test measures is what a player hears.
static func sample(r: Recipe, t: float, rng: RandomNumberGenerator) -> float:
	var p := clampf(t / maxf(r.duration, 0.0001), 0.0, 1.0)
	var f: float = lerpf(r.f0, r.f1, p)

	var v := 0.0
	match r.wave:
		Wave.SINE:
			v = sin(TAU * f * t)
		Wave.SQUARE:
			v = 1.0 if sin(TAU * f * t) >= 0.0 else -1.0
		Wave.SAW:
			v = 2.0 * (fmod(f * t, 1.0)) - 1.0
		Wave.NOISE:
			v = rng.randf_range(-1.0, 1.0)

	if r.beat > 0.0:
		v = v * 0.6 + sin(TAU * (f + r.beat) * t) * 0.4
	if r.noise > 0.0:
		v = v * (1.0 - r.noise) + rng.randf_range(-1.0, 1.0) * r.noise
	if r.trill > 0.0:
		v *= 0.72 + 0.28 * sin(TAU * r.trill * t)

	# envelope
	var env := 1.0
	if t < r.attack:
		env = t / maxf(r.attack, 0.0001)
	elif t > r.duration - r.release:
		env = maxf(0.0, (r.duration - t) / maxf(r.release, 0.0001))

	return clampf(v * env * r.gain, -1.0, 1.0)
