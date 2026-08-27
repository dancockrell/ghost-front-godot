# GHOST FRONT — design

**Lore status: APPROVED.** All six open questions were ruled by the lore thread
on 27 Aug 2026. Two rulings (attenuation, Tesla) are now canon in
`world-aflame-godot/docs/LORE-BIBLE.md` §5. Where this document and the bible
disagree, the bible wins.

---

## 1. The pitch

A 2D action platformer. You are a Project 42 retrieval agent, sent into the
past to bring one person out. You have time, phase and current. The Werk has
everything else.

## 2. Why this shape

The old Ghost Front was a run-right-and-hit-things platformer whose identity
lived entirely in its art. Strip the art and nothing distinguished it.

This one's identity is in the **verbs**, and the verbs were already canon. The
bible gives Project 42 three pillars — Chrono, Phase, Current — and all three
are, unmodified, good platformer mechanics. The lore thread reached the same
conclusion independently, which is the strongest signal available that the
setting is load-bearing rather than decorative.

**Standing rule from that ruling: no fourth verb without a pillar behind it.**

## 3. The three verbs — all built and tested

### CHRONO — rewind
Hold to rewind your position and velocity through a rolling 3s history.
Rewind **pre-empts everything**: it is not an ability used alongside the
others, it is a claim that the last two seconds did not happen, so no gravity
or dash simulates during it.

Makes the game **generous without making it easy**. Retry friction is what
makes a hard platformer feel mean, and it is entirely separable from
difficulty — so the levels are free to be sharp.

### PHASE — go intangible
A short dash through thin matter and through enemies. Movement and defence on
one button, which keeps the game aggressive instead of turning defence into
waiting.

**Attenuation is the core resource, and the ruling made it much better than
the proposal.** It is not becoming see-through. It is **becoming a fact for
fewer observers** — there is no floor, and nobody knows where it ends.

So the meter is *seductive*, not punitive:

| attenuation | the world perceives you | you are hit | the floor |
|---|---|---|---|
| 0% | 100% | always | solid |
| 50% | 58% | 30% miss | solid |
| 100% | 15% | 60% miss | **gone at random** |

The soldier furthest along is the most effective one in the room, right up
until they are not in the room at all. A resource the player is tempted to
spend toward their own erasure is worth ten they merely manage.

Both halves are asserted in `AbilityProbe`, including that the advantage is
**monotonic** — a version that only punishes would be the wrong mechanic and
would still pass a test that only checked the downside.

**Camp Iron Bell knows what repeated phasing does. The handler does not
mention it.** That is the programme's actual lie: about survivability, not
about geography.

### CURRENT — arc
Throw an electrical arc at a conductive anchor and get pulled to it. Grapple
and zipline; also powers dead machinery.

Selection is deliberately forgiving — anchors are chosen by a blend of aim
alignment and distance rather than an exact raycast, because a grapple that
demands precision to *start* spends the player's attention on the wrong half
of the move. The interesting decision is where to go.

Per the bible, Current runs on theory the programme does not understand, so of
the three it is the one allowed to be unruly: it snaps, it earths on the wrong
thing, it occasionally embarrasses you. Characterisation as game feel.

**Anchors never gate progress.** Every gap in the greybox is jumpable without
the arc. A traversal ability that gates progress stops being expressive and
becomes a key.

## 4. The loop

**Insert → traverse → find the subject → get out with the alarm up.**

Discrete missions. Each teaches one thing, then combines it with everything
before. The extraction run back is the set piece: same level, alarm raised,
and you are escorting rather than travelling.

## 5. The protagonist — native to 1944

Ruled. Not mined. The apparent collision with "retrieval is one-way" resolves
cleanly: **that rule governs the retrieved** — people lifted out of their own
time permanently at ruinous cost. An agent is deployed and recovered. Different
operation, different physics, no exception needed.

Native also serves the arc better. A mined agent already knows how it ends; a
native one discovers the criteria alongside the player, which is what the
denied-requisition collectibles are built to deliver.

## 6. Tone — Project 42 is the funny faction

The bible is explicit that this faction carries the comedy, and that Fallout's
move is one move rather than a compromise.

- The HUD is a **War Department form**. Abilities are line items with form
  numbers. Attenuation is a *condition code*.
- Your handler is cheerful, encouraging, and reading from a script written by
  someone who has never been where you are.
- Collectible **denied requisitions**, played straight, funny by accumulation.
- Then the turn: read them, and you find out what the criteria were.

**Tesla is the best of these and it is canon.** They cannot have him. He died
7 January 1943 in the Hotel New Yorker; the body was found, the death
certified, the papers seized. **History is certain about Nikola Tesla**, so no
retrieval taking him can close. Somebody filled out that form. It came back
denied. The denial is in a drawer and people know which drawer.

The general rule is crueller than the case: **the better documented a life,
the more unreachable it is.** The programme can only ever have the people
history was careless with. For an outfit that believes it is mining greatness,
that is devastating.

Per rule 10, anything funny about the wrong thing is cut. The comedy is aimed
at the bureaucracy, never at what the bureaucracy processes.

## 7. The people you do not extract

Ruled, with two **binding** additions beyond what was proposed.

- No counter, no score, no rescue-them-all mode. Texture and dialogue,
  discoverable, never quantified, never a fail state.
- **Never make it a choice.** No level where the player selects who comes out.
  That is a trolley problem and it makes the player the selector, which is
  exactly what rule 2 exists to prevent. The form was initialled before the
  agent deployed. **The player has no choice, and finding that out is the
  point.**
- **They are never depicted as victims.** They are people the form did not
  clear. The horror is bureaucratic, not graphic — a name on a page with a box
  unticked.

## 8. Opposition — Werk Nachtigall

Rule 4 is load-bearing: **no magic**, everything is science however appalling.
Rule 5: genuinely capable, not shambling.

- **Seuche** — fungal. Slow, numerous, spatial pressure. Cordyceps-shaped, no
  reanimation.
- **Bestiarium** — grafts and powered frames. Fast, leaping. The reason you
  need Phase.
- **Kadaver** — surgical augmentation. Armoured, telegraphed, deliberate. The
  reason you need Current and Chrono.

Everything telegraphs. The old build got that right and it is worth keeping: a
tell you can read is what separates a fair death from a cheap one.

Enemies read `phase.perception_scale()` for detection range and
`phase.hit_evaded()` for whether a hit lands, so the seduction is wired
through opposition rather than being a number on the HUD.

## 9. The name

**Ghost Front, re-founded.** Not inherited from the dead build — taken from
the real thing: the Ardennes was nicknamed the *Ghost Front* in late 1944, a
quiet sector where tired units were parked, right up until December. Documented
period vocabulary. The phase-shift resonance is a bonus, not the origin.

## 10. Inherited names that are going

WEWELSBURG and GERMANIA go — Himmler's castle and Speer's capital cannot exist
in a timeline with no Third Reich. Those chapters are not being ported.

**Sharp edge, protected:** chapter 6's "Germania Magna, year 9" is the *Roman*
one, doing legitimate Teutoburg work. A blind find-and-replace fixes two bad
names and silently breaks a good one, and the breakage is invisible because the
result still reads fine.

Nuance from the lore thread worth carrying: the Nazis appropriated Teutoburg
heavily as founding myth, so the reference is not neutral merely because it is
genuinely ancient. That does not make it illegitimate — it makes it a choice
that should be deliberate.

---

## 11. Built and verified

| | |
|---|---|
| Movement | designer-facing profile; gravity derived from jump height and time to apex; orthogonal knobs |
| Forgiveness | coyote time, jump buffering, variable jump height, asymmetric gravity, apex hang, corner correction, air jump |
| Chrono | ring-buffer rewind, pre-empts all other simulation |
| Phase | dash, attenuation, seduction curve, involuntary phasing |
| Current | forgiving anchor selection, pull, release with momentum |
| Greybox | builds itself from the movement profile; anchors never gate progress |
| Tests | `MovementProbe` 16 checks, `AbilityProbe` 24 checks, both measuring a real body in a real collision world |

Not built: enemies, combat, missions, art, audio, HUD-as-form.
