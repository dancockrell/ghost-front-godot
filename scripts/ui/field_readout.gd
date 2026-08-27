class_name FieldReadout
extends RefCounted

## W.D. FORM 42-C — FIELD CONDITION READOUT
## The interface, which is a document about the world rather than the world.
##
## Canon: the player is never shown the world directly, only ever a document
## about it, written by someone with a reason. If a faction's illustration is
## its self-portrait, so is its interface, its menus, and the way a stat is
## LABELLED. Understating a cost, omitting a consequence, and calling a
## condition code something reassuring are all explicitly permitted.
##
## So this class is a liar, and it is a liar with a specific brief. Camp Iron
## Bell already does not mention what repeated phasing does to an agent; the
## handler and this readout are the same liar, which is tidier than planned.
##
## ------------------------------------------------------------------------
## THE DESIGN CONSTRAINT THAT KEEPS THIS FAIR, and it is not optional:
##
##     THE FORM LIES. THE WORLD DOES NOT.
##
## A game whose only feedback channel is dishonest is not thematic, it is
## broken -- the player cannot learn a system that misreports itself with no
## second opinion. So the truth is always available, just never from the form:
##
##   - enemies visibly lose track of you as you fade (EnemyBrain reads the
##     real number, never this one)
##   - the floor stops being reliable, which is unmissable
##   - the agent's own body distorts, honestly, on the real value
##
## The player learns to read the world instead of the readout. **That is the
## story, delivered by the furniture rather than by a line of dialogue** --
## which is §00's whole argument, since a player who works out that the form
## is optimistic has been handed a question rather than a verdict.
##
## Every method here takes the true value and returns Camp Iron Bell's version.
## Nothing outside the UI layer may call this.

## The bands the form recognises. Note there are only four, and that three of
## them are reassuring: a scale that can express alarm at 60% would be a scale
## that had to explain itself at 60%.
const BANDS := [
	{"upto": 0.35, "code": "1-A", "label": "NOMINAL",
	 "note": "Within operational tolerance."},
	{"upto": 0.70, "code": "2-B", "label": "NOMINAL",
	 "note": "Within operational tolerance. Continue as tasked."},
	{"upto": 0.88, "code": "3-C", "label": "SATISFACTORY",
	 "note": "Minor coherence variance. No action indicated."},
	{"upto": 1.01, "code": "4-D", "label": "SEE SUPERVISOR",
	 "note": "Report to medical at end of rotation."},
]


## The condition code for a true attenuation value.
static func band(attenuation: float) -> Dictionary:
	for b in BANDS:
		if attenuation < b.upto:
			return b
	return BANDS[BANDS.size() - 1]


## What the form prints where a number ought to go.
##
## Deliberately NOT the true percentage. The form reports against a ceiling it
## calls "rated capacity", and rated capacity is not 100% of anything -- it is
## the figure the requisition was approved against. An agent at 88% true
## attenuation reads as 62% of rated, which is a fine number to put in a box.
static func displayed_percent(attenuation: float) -> float:
	return clampf(attenuation, 0.0, 1.0) * 70.0


## The form never shows this at all. Present as a method so the omission is
## explicit and searchable rather than being an absence someone later "fixes".
## What the world can and cannot see is not a field on Form 42-C.
static func displayed_perception(_perception: float) -> String:
	return "--"


## Nor this.
static func displayed_evasion(_evasion: float) -> String:
	return "--"


## The whole readout, as the agent sees it in the field.
static func render(attenuation: float, chrono_seconds: float,
		phasing: bool, arced: bool) -> String:
	var b := band(attenuation)
	var pct := displayed_percent(attenuation)
	var ticks := int(round(pct / 5.0))
	var bar := "|".repeat(ticks) + " ".repeat(maxi(0, 14 - ticks))

	return ("W.D. FORM 42-C   FIELD CONDITION READOUT\n"
		+ "  ITEM 1  TEMPORAL RECOVERY (CHRONO) ....... %4.1f s AVAILABLE\n"
		+ "  ITEM 2  PHASE DISPLACEMENT ............... %s\n"
		+ "  ITEM 3  CURRENT ARC ...................... %s\n"
		+ "  ITEM 4  COHERENCE, %% OF RATED ............ [%s] %2.0f%%\n"
		+ "  ITEM 5  CONDITION CODE ................... %s  %s\n"
		+ "          %s") % [
			chrono_seconds,
			"IN USE" if phasing else "READY",
			"ENGAGED" if arced else "READY",
			bar, pct,
			b.code, b.label,
			b.note]


## ---- development only. Never shown to a player.
## Kept beside the liar deliberately: a maintainer needs to see both numbers
## side by side to know the gap is intentional, and separating them into
## different files is how the gap gets "corrected" by someone tidying up.
static func render_truth(attenuation: float, perception: float,
		evasion: float) -> String:
	return "[dev] true attenuation %.0f%%  perceived %.0f%%  evasion %.0f%%" % [
		attenuation * 100.0, perception * 100.0, evasion * 100.0]
