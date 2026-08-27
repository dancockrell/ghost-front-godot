class_name HandlerVoice
extends RefCounted

## Camp Iron Bell, on the radio.
##
## Somebody at a desk in Mississippi reading from a script written by a third
## person who has never been where the agent is. Cheerful, competent, fond of
## the agent, and structurally unable to tell the truth about cost.
##
## HE IS THE SAME LIAR AS FORM 42-C. The programme knows what repeated phasing
## does to an agent. He does not say it. One institution, two mouths -- and
## that is why `on_attenuation()` below reads the band rather than the true
## value: he is looking at the same optimistic form the player is.
##
## THE TELL IS THE PAUSE. When he goes off script he gets SHORTER, not longer.
##
## ---------------------------------------------------------------------------
## THE LITTER, and it is the most delicate thing in this file.
##
## Volume VIII said the troops have no good name for Muster 3 and that the
## flatness is the point. It is not, on its own: a player cannot perceive the
## absence of a joke they never heard. The flatness reads to somebody holding
## the bestiary and to nobody else.
##
## So the handler carries it. He has a light line for EVERY unit type. For the
## litter he does not, and the player hears him not have one:
##
##     "Muster 3s in the sector. The --"  (pause)  "-- Muster 3s."
##
## THIS LINE IS PARASITIC. It only reads as an absence because the player has
## heard him make the joke every other time. Two consequences that are easy to
## lose later and are therefore asserted in VoiceProbe:
##
##   1. every other unit MUST have a bark, or there is no pattern to break
##   2. those barks must actually be light
##
## If anyone ever tunes the humour down, this line silently stops meaning
## anything and nothing else will report it.

const LITTER_DESIGNATION := "Muster 3"

## Sighting barks, keyed by Office designation. Every unit has one except the
## litter, whose entry is the shape of a missing one.
const SIGHTING := {
	"Muster 12": "That'll be Muster 12s. Patients. ... You'll see why.",
	"Baureihe 7": "If you hear a whistle, that's not one of ours.",
	"Verfahren Seuche, Muster 4":
		"Bakers in there. Smells like a Sunday, which it is not.",
	"Verfahren Seuche, Muster 6":
		"Sixes. Same procedure, later. You'll know because you won't smell them.",
	"Gestell 4":
		"Walker's in the road. Costed for recovery twice, declined twice. "
		+ "There's a man in it.",
	# The absence. One pause, and the joke that does not arrive is audible.
	LITTER_DESIGNATION: "Muster 3s in the sector. The -- ... -- Muster 3s.",
}

## Which entries are deliberately NOT jokes. Kept as data rather than as a
## comment so a test can check the shape of the set rather than trusting prose.
const NOT_A_JOKE := [LITTER_DESIGNATION]

const MISSION := {
	"insert": "Morning. Weather's fine here, which I'm told is not useful "
		+ "information.",
	"traverse": "You're cleared to Item 4 usage at your discretion. "
		+ "Discretion's the word they gave me.",
	"secured": "Command's asked me to remind you the subject's absence is "
		+ "already consistent with the record. Which means -- ... -- it means "
		+ "go get them, is what it means.",
	"extract": "Alarm's up site-wide. Nobody's expecting heroics. Nobody's "
		+ "expecting anything, that's the -- that's not how I meant that.",
	"complete": "Return's logged. That's a good day's work by anyone's "
		+ "reckoning, and I'll be putting it that way on the form.",
	"failed": "We'll stand you down. Form's already filed, so -- ... -- "
		+ "we'll stand you down.",
}


## What he says about the agent's condition.
##
## Reads the FORM's band, never the true attenuation, because that is the whole
## characterisation: he is looking at the same optimistic document the player
## is. At 80% true he is genuinely reassured, and he is not lying on purpose.
static func on_attenuation(true_attenuation: float) -> String:
	var band := FieldReadout.band(true_attenuation)
	match band.code:
		"1-A":
			return "Coherence nominal. Nothing to say about it, which is how "  \
				+ "we like it."
		"2-B":
			return "Condition code 2-B. Still nominal. Carry on as tasked."
		"3-C":
			return "Condition code reads 3-C, satisfactory. That's a "  \
				+ "*satisfactory*, so -- carry on. Minor coherence variance. "  \
				+ "No action indicated."
		_:
			# Even here he defers. The form says end of rotation, so he says
			# end of rotation, and he is shorter than usual about it.
			return "That's a 4-D. Medical at end of rotation. ... "  \
				+ "End of rotation."


static func on_sighting(designation: String) -> String:
	return SIGHTING.get(designation, "")


static func on_phase(phase_name: String) -> String:
	return MISSION.get(phase_name.to_lower(), "")


## Every designation the handler can speak about.
static func covered() -> Array:
	return SIGHTING.keys()
