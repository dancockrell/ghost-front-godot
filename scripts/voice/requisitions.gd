class_name Requisitions
extends RefCounted

## The found documents. Werk Nachtigall's paperwork, and Camp Iron Bell's.
##
## THIS IS THE FALLOUT TURN AND THE WHOLE TONE WAS BUILT FOR IT. Vault-Tec's
## cheerfulness is the indictment; you can play forty hours and enjoy a shooter,
## and the horror is there for whoever reads the terminals. These are the
## terminals.
##
## Rules, carried from Volume IX and non-negotiable:
##
##   - Nothing is ever threatened. Things are SCHEDULED, APPROVED IN PART, or
##     HELD PENDING CLARIFICATION.
##   - Objections are forwarded upward, never refused. Everyone knows what
##     forwarded upward means.
##   - The most frightening sentence available is a favourable one.
##   - Menace is supplied by the reader. If a document sounds threatening it is
##     wrong and it is cut.
##   - Show the paperwork, not the laboratory.
##
## AND THE §00 TEST, applied to every single one before it goes in:
## does it hand down a verdict, or leave a question the reader carries out of
## the room? If it concludes, cut it. If it asks, keep it.
##
## The Allied ones matter as much as the Werk ones, and they are the harder
## write. Camp Iron Bell is the funny faction; its documents are cheerful,
## procedural, and the horror is in what the procedure is FOR. A denied
## requisition is a joke until you have read four of them.

enum Side { WERK, ALLIED }

## side, title, body. `found_in` is a level id, or "" for anywhere.
const DOCUMENTS := [
	# ---- WERK NACHTIGALL ----------------------------------------------
	{
		"side": Side.WERK,
		"found_in": "ch3",
		"title": "SECTION VI (ACCOUNTS AND ESTIMATES) TO BESTIARIUM",
		"body": "Your requisition for four hundred (400) muzzles is approved "
			+ "in part. Two hundred are released against the current quarter. "
			+ "The remainder is held pending clarification of the discrepancy "
			+ "between your stated establishment and your feed returns, which "
			+ "do not reconcile.\n\n"
			+ "Section VI notes that the discrepancy has been favourable in "
			+ "every quarter since 1941 and would welcome an explanation it "
			+ "can file.",
	},
	{
		"side": Side.WERK,
		"found_in": "ch3",
		"title": "PROCEDURE SEUCHE -- QUARTERLY, ABSTRACT",
		"body": "Yield continues to improve against projection. Attrition is "
			+ "within tolerance and is, per the doctrine adopted 1942, an "
			+ "input rather than a loss.\n\n"
			+ "The Sector Physician's observation regarding personnel "
			+ "retention on this detail is appended at her request. It is "
			+ "being forwarded upward.",
	},
	{
		"side": Side.WERK,
		"found_in": "ch5",
		"title": "DISPOSITION -- GESTELL 4",
		"body": "The unit remains in the field at grid reference appended. "
			+ "Recovery has been costed twice and declined twice.\n\n"
			+ "The occupant is entered on the establishment as present. "
			+ "Section VI has queried whether he should be entered as "
			+ "*present* or as *equipment in the field*, since the two are "
			+ "drawn against different appropriations, and requests guidance "
			+ "before the next return.",
	},
	{
		"side": Side.WERK,
		"found_in": "ch5",
		"title": "ABT. GLOCKE -- CALIBRATION, ELEVENTH RING",
		"body": "The rig has run continuously since the eleventh ring and "
			+ "measures the falloff at intervals as instructed.\n\n"
			+ "No instruction to stop has been received. Abt. Glocke notes "
			+ "that the instruction to start was countersigned and the "
			+ "instruction to stop would also require countersignature, and "
			+ "that the officer who countersigned is no longer at this "
			+ "establishment.",
	},

	# ---- CAMP IRON BELL -----------------------------------------------
	# Cheerful, procedural, and the horror is what the procedure is FOR.
	{
		"side": Side.ALLIED,
		"found_in": "ch1",
		"title": "W.D. FORM 19 -- REQUISITION, DENIED",
		"body": "Item: winter issue, field, one hundred and forty (140).\n"
			+ "Denied. Establishment for this site is thirty-one (31).\n\n"
			+ "Resubmit against the correct establishment. Camp Iron Bell "
			+ "reminds requisitioning officers that the establishment figure "
			+ "is the figure the site is FUNDED for and not the figure "
			+ "presently on it.",
	},
	{
		"side": Side.ALLIED,
		"found_in": "ch2",
		"title": "W.D. FORM 19 -- REQUISITION, DENIED",
		"body": "Item: retrieval, one (1) subject, schedule attached.\n"
			+ "Denied. Subject does not meet the criteria at Part II.\n\n"
			+ "The requisitioning officer's note that the subject is nine "
			+ "years old has been read and does not alter Part II. "
			+ "Resubmission is not indicated.",
	},
	{
		"side": Side.ALLIED,
		"found_in": "ch4",
		"title": "W.D. FORM 19 -- REQUISITION, DENIED",
		"body": "Item: retrieval, one (1) subject. N. Tesla.\n"
			+ "Denied at Part I. Record is closed and consistent.\n\n"
			+ "Camp Iron Bell notes that this is the fourth submission of "
			+ "this item and that the answer at Part I does not change with "
			+ "resubmission. The officer is referred to the Consistency "
			+ "Finding and to his section head.",
	},
	{
		"side": Side.ALLIED,
		"found_in": "ch4",
		"title": "MEMORANDUM -- CRITERIA, PART II",
		"body": "Part II is not a ranking of persons. Part II is a schedule of "
			+ "what the programme is able to bring back and hold.\n\n"
			+ "Officers are asked to stop writing to this office about the "
			+ "difference. This office is aware of the difference.",
	},
	{
		"side": Side.ALLIED,
		"found_in": "ch5",
		"title": "MEDICAL -- CONDITION CODES, NOTE TO FILE",
		"body": "The bands at Item 5 were set against rated capacity in 1943 "
			+ "and have not been revised.\n\n"
			+ "The undersigned has twice recommended that band 3-C be "
			+ "retitled, on the grounds that agents read *satisfactory* as "
			+ "satisfactory. The recommendation was forwarded upward.",
	},
]


static func for_level(level_id: String) -> Array:
	var out: Array = []
	for d in DOCUMENTS:
		if d.found_in == level_id or d.found_in == "":
			out.append(d)
	return out


static func count_by_side(side: int) -> int:
	var n := 0
	for d in DOCUMENTS:
		if d.side == side:
			n += 1
	return n


static func side_name(side: int) -> String:
	return "WERK NACHTIGALL" if side == Side.WERK else "CAMP IRON BELL"
