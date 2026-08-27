# Ghost Front (Godot port)

A WW2 horror platformer, ported from its original single-file HTML/canvas
build to Godot 4.7.

The original is at [ghost-front](https://github.com/dancockrell/ghost-front):
one 13MB `index.html`, no build step, 48 rounds of iteration, and a cast of 38
characters. It works. This port exists to give it a real engine underneath —
scenes, resources, an asset pipeline, and platform targets the browser cannot
reach — without losing the thing that took 48 rounds to get right.

Set in the same universe as [World Aflame](https://github.com/dancockrell/world-aflame),
and governed by the same lore bible.

## Status

Early. What is actually done, and nothing more:

- **Assets extracted.** All 314 embedded base64 images pulled out to real
  files with their frame metadata intact: 252 sprite sheets across 38
  characters, 57 painted backdrops. `tools/` holds the extractors.
- **Physics ported and verified.** The player movement derivation is ported
  and checked against the original's own arithmetic (`scenes/PhysicsProbe.tscn`,
  20 assertions). See the note below — this was the trap.
- **Nothing else yet.** No rendering, no level builder, no enemies, no audio.
  The original's 14-part architecture is mapped but not moved.

## The physics trap, written down because it will bite the next person

`index.html` declares its movement constants twice. The visible declaration:

```js
var GRAV=2500, JUMP=-860, JUMP2=-650, RUN=209;
```

Those are placeholders. `physFit()` runs immediately after and overwrites all
four from a scale-relative derivation, so the values above never survive a
frame. The live figures at full size are roughly 1.7x larger. A port that
copied the literals would run, look correct, and feel wrong with nothing to
point at.

`scripts/player/player_physics.gd` ports the derivation instead, and
`PhysicsProbe` asserts the placeholders are *not* matched, so a future
"simplification" back to the literals fails loudly.

One further wrinkle: the original's comment annotates the derived jump as
`-290`, but `172 * (26/17) * 1.10 = 289.36`, which rounds to **289**. The
comment's downstream figures ("apex 0.379 s", "arc 55 units") inherit the same
off-by-one. The code is what 48 rounds of tuning were judged against, so the
port follows the code and the probe asserts 289.

## Known issues carried over from the original

- **Insignia.** `OFFIZIER` and `SCHUETZE` carry a swastika armband, and
  `SCHUETZE` additionally wears SS-style collar runes. The governing lore
  bible specifies Iron Cross, not swastika — the setting has no Nazi party —
  and the marks are also unshippable in Germany under §86a StGB. These sheets
  need repainting before any release. `tools/scan_insignia.py` finds the red
  armbands; it explicitly **cannot** see light-on-dark runes, and says so.
- **Six duplicate sprite strips.** The legacy `IMGSPR` entries for
  `SCHUETZE`, `STURM`, `GREN`, `FLAMM`, `OFFZ` and `PION` are byte-identical
  to each other — six enemy types sharing one image. They appear to be
  vestigial fallbacks behind the painted `ARTDATA` path, but that is a
  reading of the code, not something confirmed by running it.
- **Two chapters rest on Nazi-specific proper nouns.** `WEWELSBURG` (Himmler's
  order castle) and `GERMANIA` (Speer's capital) do not fit a setting with no
  Third Reich. The architecture and mood transfer fine; the names do not.
  A lore-owner decision, not a porting one.

## Layout

```
scripts/player/   movement, ported by derivation
scripts/app/      headless probes and tests
scenes/           test scenes
assets/sprites/   252 sheets, 38 characters
assets/backdrops/ 57 painted plates
resources/        art_manifest.json — frame metadata for every sheet
tools/            extractors and the insignia scanner (run against the original)
```

## Running the checks

```bash
godot --headless --path . --import
godot --headless --path . scenes/PhysicsProbe.tscn
```

## Licence

All rights reserved (for now), matching the original.
