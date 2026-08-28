# GHOST FRONT — art bible

Everything that needs drawing, why it exists, and what it must communicate.

**The rule that governs the whole document:** every asset here has a
**gameplay job** as well as a look. If a prop cannot answer "what does the
player learn from seeing this", it is decoration and it gets cut. A screen
full of decoration is a screen where the player cannot find the tell.

Governed by `world-aflame-godot/docs/ART-SPEC.md` and the lore bible. Where
they and this disagree, they win.

---

## 0. The two-layer rule, restated because everything below obeys it

**The poster layer is period-honest and FLAT.** Limited palette, halftone or
screenprint texture, heavy blacks, paper grain, registration slightly off.

**The effects layer is modern and LIT.** Glow, motion, energy.

**Keep the seam visible.** Do not blend them. The gap between the two *is* the
style, because the gap is the idea: something inhuman happening inside an
ordinary printed poster.

Implemented in `shaders/poster.gdshader` (flat layer) and
`shaders/attenuation.gdshader` (lit layer). The seam is not simulated in the
art — the art is drawn flat and the shader supplies the print.

**Every faction is drawn in its own tradition, as it wished to be seen.** Never
through an enemy's eyes. That makes the opposition *scarier*, not softer.

**Consequence that touches every asset here: Project 42's clean heroic look is
propaganda too.** Their poster, not the game's verdict.

---

## 1. Canvas, scale and the pixel budget

| | |
|---|---|
| Reference resolution | 1920 × 1080 |
| Player height | **150 px** — the unit everything else is measured in |
| Jump height | 210 px (1.4 player heights) |
| Jump distance | 376 px (2.5 player heights) |
| Camera zoom in play | 0.72 |

**Read every size below in player-heights, not pixels.** If the movement is
retuned the pixel figures move and the ratios do not — the same discipline the
levels already use.

---

## 2. The agent — the only character the player controls

**Working name: the agent.** Native to 1944, deployed and recovered rather than
retrieved. Not mined; they discover the criteria alongside the player.

### Silhouette rules, in priority order

1. **Readable at 150 px against every one of the four palettes.** Test against
   the Werk's near-black stock before anything else — that is where a dark
   costume disappears.
2. **Asymmetric.** One shoulder rig, one bare arm. A symmetric silhouette
   reads as a doll and gives the eye nothing to track a flip by.
3. **No cape, no coat tails, no loose fabric.** Movement is the game; anything
   that trails will lag the pose and make the jump feel late.
4. **The Current arm is the loudest thing on the figure**, because it is the
   primary weapon and the player must always know which way it is pointing.

### Poses required

Ordered by how often the player sees them, which is the order to draw them in.

| pose | frames | notes |
|---|---|---|
| idle | 4 | a breath, and the arm rig settling. Not a stance. |
| run | 8 | driven by DISTANCE, not a clock — see below |
| jump rise | 2 | |
| jump apex | 1 | held; the apex hang is a real mechanic and needs a pose |
| fall | 2 | |
| land | 2 | a compress, ~0.1 s |
| fire, standing | 3 | the recoil is in the arm only; the legs never break stance |
| fire, running | 3 | **the run must not stop.** Mega Man's rule and it is right |
| fire, airborne | 2 | |
| charge, holding | 4 loop | builds visibly. See §2a |
| charge, released | 2 | |
| phase dash | 3 | see §2b — this one is not a normal animation |
| hurt | 2 | a stagger, never a knockdown; a knockdown steals control |
| death | 6 | see §2c |
| carry (subject) | idle 2 + run 6 | one arm occupied, gait heavier |

**The run cycle is driven by distance travelled, not by a timer.** A frame of
the walk must be worth a fixed number of pixels of ground at every speed, or
the feet skate. This is inherited from the retired build, which got it wrong
and then fixed it, and it is worth not relearning.

### 2a. The charge — the one piece of UI that lives on the character

The charge meter is **on the arm, not on the HUD.** Reason: the HUD is a
document Camp Iron Bell wrote and it is allowed to lie, so it is the wrong
place for information the player must trust. The arm is the world.

Four stages, each visibly distinct **in silhouette alone**, so a colourblind
player and a player looking at the enemy both still read it.

### 2b. Phase — drawn as an absence

Phase is not a dash with a trail. **The agent is briefly less present.** Draw
the pose as a *hole* in the scene rather than a lit figure: the silhouette
punched through, the backdrop showing where the body was.

That is the canon reading — attenuation is becoming a fact for fewer
observers, not becoming see-through — and it costs one alpha mask.

### 2c. Death — a recovery, not a corpse

Canon: Camp Iron Bell *pulls the agent back and files the attempt.* So the
death animation is **an extraction, not a body falling.** The figure comes
apart the way the attenuation shader comes apart — channel separation, then
gone — and the game cuts to RECOVERING.

**Never draw a corpse of the agent.** It is the wrong fiction and it is the
wrong feeling for something the player will see four hundred times.

---

## 3. The Werk — six units, and what each must teach on sight

Every unit is scalpels, cultures, machinery and budget. **No magic, ever.**
And the Office's register throughout: nothing here was given a frightening
name by the people who made it.

**Every unit needs a TELEGRAPH POSE that is distinct in silhouette from its
idle.** That is the single most important frame in each set. A tell you can
read is what separates a fair death from a cheap one.

| unit | troop name | reads as | telegraph must show |
|---|---|---|---|
| Verfahren Seuche, Muster 4 | bakers | a room becoming unavailable | the bloom starting, low and wide |
| Verfahren Seuche, Muster 6 | the quiet ones | **a Muster 4, almost exactly** | same tell — the difference is §3a |
| Baureihe 7 | whistlers | the thing that closes distance | the crouch before the leap |
| Muster 3 | the litter | numbers, not a duel | the pack turning together |
| Gestell 4 | walkers | an obstacle with an occupant | the long lean back |
| Muster 12 | patients | a negotiation with a schedule | both arms up, and held |

### 3a. The bread smell — the most important art note in this document

A Muster 4 **announces itself by smell.** A Muster 6 does not, and *that is
how you know it is a six.*

Smell is not drawable, so it is rendered as a **warm haze in the air around
the unit** — currently a faint radial in `level_runner.gd`. Two hard rules:

1. **The haze must be legible enough to learn** and subtle enough that a
   player only notices they were relying on it once it is missing.
2. **A Muster 6 gets NO substitute tell.** Not a different colour, not a
   subtle marker. **Nothing.** The absence is the mechanic, and any
   compensating cue destroys it.

The two units must otherwise be **near-identical in silhouette.** If a six
reads as different at a glance, the missing haze carries nothing. This is
asserted mechanically in `EnemyProbe`; the art must hold the same line.

### 3b. Never draw the handler

Whistlers *answer a whistle*. Somewhere behind them a man is blowing.

**There is no handler sprite, no silhouette, no spawn marker, no shadow in a
doorway.** Ever. A whistle with nobody visible behind it is the whole faction,
and the moment a player sees who is blowing, the horror becomes a target.

Enforced in code: `EnemyProbe` asserts no unit in the roster is a handler.

---

## 4. The eight — flagship Muster units

Each needs: idle, its pattern's telegraph poses (2–3), an active frame per
action, a recovery pose, a phase-two variant, and a defeat.

**The recovery pose is the player's turn and must look like it** — open,
off-balance, obviously exploitable. If recovery looks like idle, the fight has
no rhythm and the player never learns when to hit.

| unit | troop name | the one thing the art must sell |
|---|---|---|
| Muster 9 | the coat | there is nothing in the sleeves but the rig |
| Verfahren Seuche, Muster 4 | the proving floor | the floor is the enemy, not the shape |
| Gestell 4 | the walker | **a man is inside it and cannot get out** |
| Muster 11 | the dome | a surgeon's rig, and the requisition has a name on it |
| Muster 14 | the chamber | a gauge that tops out and holds |
| Muster 2 | the lamp | an examination light, still in service |
| Abt. Glocke rig | the pendulum | it has been measuring since the eleventh ring |
| Muster 12 | the ward | post-operative, ambulatory, nine times |

**Gestell 4 is the comic one and must be played that way.** §0 of the lore
bible: if every beat is solemn, we have failed. A walker stuck with a man
inside who cannot get out, while the war happens elsewhere, is the register.

---

## 5. Props — and every one has a job

**A prop with no gameplay job is decoration and gets cut.** These all have one.

### Read by the player

| prop | size | job |
|---|---|---|
| conductive anchor | 0.25 h | the arc target. Must read as *catchable* from a screen away |
| requisition | 0.2 h | a document to pick up. Paper white against every palette |
| the subject | 1 h | the extraction target. A person, never a crate |
| insertion marker | 0.6 h | the way home. Visible from a distance |
| checkpoint | 0.8 h | a field telephone on a post. Reads as "somebody knows I got here" |

### Read as danger

| prop | job |
|---|---|
| pit edge | the lip must be unmistakable; a pit that reads as floor is a cheap death |
| culture bed | Seuche ground. Ground you cannot cross, and it must look crossable-adjacent |
| live rail | Current hazard. Bright, obviously energised |
| press / stamp | Kadaver crush hazard, on a visible cycle |

### Set dressing that carries the fiction

Small, quiet, never in the way of a tell:

- **Filing cabinets.** The Werk's actual weapon. Open drawers, spilled forms.
- **Crates with stencilled Muster numbers.** The Office numbers products.
- **A noticeboard of denied requisitions.**
- **A wall clock, stopped.** Abt. Glocke sites only.
- **Chalked duty rosters** with names rubbed out and rewritten.
- **The Iron Cross**, and *only* the Iron Cross. Rule 8, singular and
  exclusive. **Never design a second imperial mark, and never let a generator
  supply one.**

**Do not draw:** camps, victims, medical procedures in progress, anything
inside an operating theatre. The horror is bureaucratic. **A requisition for
four hundred muzzles is worse than a scene of muzzles being fitted, and it is
cheaper to make.**

---

## 6. Tiles and level construction

Levels are generated from a grammar (`LevelSpec`), so tiles are **skins over
generated rectangles**, not a hand-placed tileset.

Per palette, each needs: floor top edge (the lit lip, ~6 px), floor body,
inner corner, outer corner, ceiling underside, and one 3-variant rubble
overlay to break repetition.

**The top lip of every platform is the most important 6 pixels in the game.**
It is what the player reads to judge a landing. It must be the highest
contrast element in the tile set, in every palette, at every zoom.

---

## 7. UI — a War Department form, and it lies

The HUD is **Form 42-C**, and it is diegetic. Camp Iron Bell wrote it, so it
understates: at 80% true attenuation it reports *"3-C SATISFACTORY."*

Needed: the form letterhead, a box rule set, a typewriter face, a rubber stamp
(APPROVED / DENIED / HELD PENDING CLARIFICATION), a carbon-copy blue variant,
and a paperclip.

**The form lies. The world does not.** The player's honest channel is the
screen itself — enemies losing track, the floor going, the attenuation shader.
**Nothing in the UI may become the honest channel**, or the design collapses.

### Fonts

| role | font | licence |
|---|---|---|
| the form | Courier Prime | SIL OFL 1.1 |
| found documents | Special Elite | SIL OFL 1.1 |
| stencil, crates | Black Ops One | SIL OFL 1.1 |
| poster display | Oswald | SIL OFL 1.1 |

All commercially embeddable. Take them from Google Fonts or upstream, never
from an aggregator — see `docs/RESOURCES.md` for why.

---

## 8. Screens, in the order a player meets them

`GameFlow` implements the state machine; this is what each screen looks like.

1. **BOOT** — W.D. letterhead on paper. No input accepted, so the first frame
   is never a black screen with a live control scheme behind it.
2. **TITLE** — *WAR DEPARTMENT — PROJECT 42 — CAMP IRON BELL, MISSISSIPPI.*
   One prompt.
3. **SELECT** — the tasking board. Eight dockets pinned to cork. Cleared ones
   get a rubber stamp. **This is the stage select and it should read as
   paperwork, not as a level grid.**
4. **BRIEF** — Form 42-A, skippable, handler talking over it.
5. **PLAY**
6. **PAUSE** — the form, held still. No blur; a blur says "cinematic" and this
   is a document.
7. **RECOVERING** — 1.35 s. *"Recovery in progress. Hold still. This is
   normal."* No menu. **A menu after a death is a punishment for playing.**
8. **GAME OVER** — *"Operation suspended pending review. Nobody is blaming
   anybody."* Returns to SELECT, never the title.
9. **DEBRIEF** — the recovered principle is issued on a form, with a stamp.
10. **CREDITS** — *"File closed."*

Asserted in `FlowProbe`: **every state can reach the title**, walked
exhaustively as a graph. A screen you can get stranded on is the failure
players actually hit and testing never finds.

---

## 9. What is NOT drawn yet

Stated plainly so the gap is not mistaken for coverage. **Nothing in §2–§6
exists as art.** The game currently runs on generated silhouettes and
procedural backdrops, which is deliberate: everything below the character
layer is being built to accept art, and the art direction is locked before a
line of it is drawn.

Priority order when art begins:

1. **The agent** — idle, run, jump, fire. Four sets, and the game stops
   looking like a prototype.
2. **The telegraph pose of each Werk unit.** More valuable than their idles:
   the tell is the contract.
3. **The floor lip**, in all four palettes.
4. **The form furniture** — letterhead, stamps, paperclip.
5. Everything else.
