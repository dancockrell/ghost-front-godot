# GHOST FRONT — campaign structure

**Status: PROPOSAL.** Mechanism is being built; fiction awaits the lore thread.

---

## 1. The frame

**Ghost Front** is the Ardennes in late 1944 — a quiet sector where tired units
were parked, right up until December. That is the home board and the name's
real referent.

But the game is not a tour of the Ardennes, because Project 42's defining verb
is not *fighting*, it is *reaching*. So the structure alternates:

- **ODD chapters — 1944/45 Europe.** Werk Nachtigall installations. The
  opposition is the Werk, the fiction is procurement, and the horror is that
  it has a budget.
- **EVEN chapters — deep retrievals.** Somewhere else in history entirely,
  to bring one person out. **No Werk at all.** Different century, different
  hazards, different silence.

The alternation is the whole pitch in one structural decision. It uses the
premise rather than decorating with it, it keeps the Werk from wearing out,
and it makes the war chapters land harder by contrast — you come back from
somewhere quiet and old, into a facility with a filing system.

## 2. What a deep retrieval is for

Every retrieval is one person, and **the criteria are short**. The programme
reaches into a century, takes the one it was sent for, and leaves.

That is where the §00 question lives without a word of commentary: the level
is populated. Nobody is counted. Nobody is chosen by the player. The form was
initialled before the agent deployed.

**And history resists.** The better documented a life, the less reachable it
is — a retrieval that would contradict the record cannot close. So the
programme can only take the people history was careless with, which means
every deep chapter is set somewhere at the edge of the record: a plague year,
a siege, a shipwreck, a fire.

That is a constraint that *generates* levels rather than limiting them.

## 3. Proposed chapters

Working titles. Six is a campaign; the shape survives being cut to four.

| # | working title | when | teaches | opposition |
|---|---|---|---|---|
| 1 | THE QUIET SECTOR | Ardennes, Dec 1944 | movement, Chrono | almost none — the tutorial is the silence |
| 2 | THE CARELESS YEAR | a plague year | Phase, attenuation | the place itself; no Werk |
| 3 | THE COLLECTION POINT | a Werk facility, 1945 | Current, the arc | Seuche, Bestiarium |
| 4 | THE BURNING STACKS | a library fire | all three under pressure | fire, structure, time |
| 5 | THE BELL HOUSE | Abt. Glocke site | attenuation as a resource | Kadaver, and the Bell |
| 6 | — | — | — | — |

**Chapter 1 is a tutorial that teaches by absence.** The Ghost Front was quiet.
You walk a front line where nothing happens, and the game teaches movement in
a place with no threat, which makes the first Werk facility land as a change
of register rather than as level three of a shooter.

**Chapter 4 is the set piece.** A library fire is a retrieval against a
deadline that is not a game timer — the building is going, the record is
going, and the person you are here for is not the thing burning. It is also
the cleanest possible statement of "the better documented a life, the more
unreachable it is," delivered as a level rather than as a line.

## 4. Proposed enemy names

Placeholders are `SEUCHE-A`, `BESTIARIUM-A`, `KADAVER-A`. Proposals below
follow the euphemism rule: **everything is called something else, and the
name is filed under the department that pays for it.**

| branch | proposed | literally | filed as |
|---|---|---|---|
| Seuche | **BODENPFLEGE** | "ground care" | agricultural maintenance |
| Bestiarium | **KURIER** | "courier" | signals and dispatch |
| Kadaver | **FACHARBEITER** | "skilled worker" | labour, grade II |

The joke is the filing, not the monster. A thing that spreads through a room
is *groundskeeping*. A thing that runs you down is a *courier*. A thing built
out of a person is *labour, grade II* — and someone argued about which grade.

None of these sound threatening, which is the point: **menace is supplied by
the player, never by the speaker.**

## 5. Dialogue register — a sample

Werk Nachtigall material is procurement. Found documents, not speeches.

> **REQ 114-8 — REJECTED**
> Item: replacement units, Bodenpflege, twelve (12).
> Rejected. Prior consignment of twelve was signed for on 4 January and is
> unaccounted for on your return. Units are not consumable stores. Please
> locate the previous twelve before submitting again.
> — *Procurement, Abt. Fleisch*

Nothing in that is threatening. An accounts department is winning an argument
about paperwork, and the reader supplies what "unaccounted for" means and what
happened to the previous twelve.

Per §00: it hands down no verdict. **An accounts department winning an
argument is a question. An accounts department gloating is an answer.**

## 6. Project 42's voice, for contrast

Camp Iron Bell is the funny faction and the handler is cheerful. His script
was written by someone who has never been where you are.

> "Coherence is reading nominal, which is what we like to hear. If it starts
> reading anything else, that's still within tolerance, so press on."

The player is at 74% and about to lose the floor. **Nobody says the programme
is lying. The player works it out**, which is the same delivery as the found
requisitions above, aimed the other way.

## 7. Level construction rules

Carried from the greybox and non-negotiable, because they are what stops the
levels drifting out of agreement with the game:

- **Geometry is derived from the movement profile.** Gaps are fractions of
  `jump_distance()`, rises are fractions of `jump_height`. Retune the jump and
  the levels retune.
- **Anchors never gate progress.** Every route the arc opens must also exist
  without it. An ability that gates progress becomes a key.
- **Every attack telegraphs**, and no wind-up can be steered out of.
- **No unit outruns the player.** Asserted in `EnemyProbe`, not left to tuning.
- **Securing the subject always raises the alarm.** The quiet leg is paid in
  what the site retains, never in skipping the set piece.
