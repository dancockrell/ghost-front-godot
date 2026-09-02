# Free and permissive resources — verified list

Sources for effects, audio, fonts and tooling that can go into a commercial,
closed-source game. **Licence verified before use, not after**, because the
alternative is finding out at ship time.

**Standing rule for this project: nothing GPL, nothing non-commercial, nothing
"free for personal use".** Ghost Front is closed-source. CC0, MIT, BSD, Apache
and SIL OFL are fine. Anything else needs a decision, not an assumption.

Last checked 27 Aug 2026.

---

## ⚠ The trap that nearly caught me

**godotshaders.com has NO default licence.** A search summary told me CC0 was
the default; the site's own policy page says otherwise. Authors choose per
submission from:

- **CC0** — fine
- **MIT** — fine
- **GNU GPL v3** — ***not usable here.*** Linking GPL-3 shader code into a
  closed-source game is exactly the contamination the licence exists to cause.

So **every single shader must be checked individually on its own page.** There
is no site-wide answer, and the plausible-sounding one is wrong.

Also from that policy, and easy to miss: *"the featured image, screenshots and
videos, and assets used in these, do not fall under this license."* The code
may be CC0 while the preview art is not. Do not lift the screenshots.

> <https://godotshaders.com/license/>

---

## Effects and shaders

| Source | Licence | Use | Status |
|---|---|---|---|
| [godotshaders.com](https://godotshaders.com) | **per shader** — CC0 / MIT / GPL-3 | halftone, film grain, CRT, outline | reference only; check each |
| Godot demo projects | MIT | particles, post-process patterns | safe |
| Godot engine source | MIT | anything | safe |

**Current decision: the shaders in `shaders/` are written for this project, not
imported.** Three reasons, in order of weight:

1. They must be driven by *game state* — the attenuation shader reads the true
   meter — and an imported shader would need rewriting to do that anyway.
2. A shader is thirty lines. Vendoring one to save twenty minutes buys a
   licence-audit obligation forever.
3. The art direction is specific (halftone poster layer with a *visible seam*
   against a lit effects layer). Generic post-process does not do that.

godotshaders remains the right place to *read* for technique.

## Art and particles — when characters arrive

| Source | Licence | Notes |
|---|---|---|
| [Kenney](https://kenney.nl) | **CC0** across all asset pages | Particle Pack (80), Smoke Particles (70). Attribution optional. The safest bulk source that exists. |
| [OpenGameArt](https://opengameart.org) | **mixed** — per asset | CC0, CC-BY, and **GPL** all present. Filter hard. |
| [Kenney on OpenGameArt](https://opengameart.org/content/all-cc0-uploader-kenney) | CC0 | same assets, mirrored |

**OpenGameArt needs the same per-item discipline as godotshaders** — it hosts
CC-BY-SA and GPL assets beside CC0 ones, and the filter is easy to skip.

## Fonts

Ghost Front needs three faces: a **form** face (the HUD is a War Department
document), a **stencil** for crates and signage, and a **typewriter** for found
paper.

| Font | Licence | Role |
|---|---|---|
| Special Elite | SIL OFL 1.1 | typewriter — found documents |
| Courier Prime | SIL OFL 1.1 | monospace — Form 42-C |
| Black Ops One | SIL OFL 1.1 | stencil display |
| Oswald / Archivo | SIL OFL 1.1 | condensed poster sans |

**SIL OFL permits commercial embedding** and is the right default. It does
require the font keep its name if modified, which affects nobody here.

**Avoid** the aggregator sites (dafont, 1001fonts, fontspace) as a *source* —
they mix "free for personal use" with genuinely free, per-file, and the
distinction is exactly the one that matters. Take OFL fonts from Google Fonts
or the upstream repository instead, where the licence ships in the file.

## Audio

| Source | Licence | Notes |
|---|---|---|
| Godot `AudioStreamGenerator` | MIT (engine) | **procedural — the current plan** |
| [Kenney audio packs](https://kenney.nl) | CC0 | impacts, UI, interface |
| [Freesound](https://freesound.org) | **mixed** — CC0 / CC-BY / CC-BY-NC | **CC-BY-NC is present and unusable.** Filter to CC0. |

**Current decision: audio is procedural**, and one canon requirement decides
it. The whistle that precedes a Baureihe 7 must fire from *off-screen* at a
specific lead time before the unit commits — it is a gameplay signal with
timing requirements, not a sound effect. A sample cannot be positioned and
retimed as freely as a generated tone, and the original build proved a fully
procedural audio engine is achievable.

## Tooling already on this machine

| Tool | Where | Use |
|---|---|---|
| Godot 4.7.2 | `AppData/Local/Programs/Godot/Standard` | the engine |
| Python + PIL | `AppData\Local\Programs\Python\Python313\python.exe` | working interpreter with Pillow |
| GitHub CLI | `C:\Program Files\GitHub CLI` | verification of pushes |

**Trap:** the machine's default `python`/`python3` are WindowsApps stubs that
fail with "Permission denied". Use the full path above, not bare `python`.

**Updated 29 Aug 2026:** this previously pointed at `dev/visual-rig/.venv`,
which was this machine's only working Python+PIL and is now deleted — that
tool is gone entirely, and its venv going with it silently broke this
dependency, since it was never recorded anywhere the deletion could have
checked against. Pillow has been installed directly into the base Python
above instead, which needs nothing else to keep working.

---

## What is still missing

Honestly, so the gap is not mistaken for coverage:

- **Characters.** Blocked on art, by Dan's instruction. Everything below the
  character layer is being built to accept them.
- **A poster-grade background pass.** The art spec wants period print stock per
  faction; that is generation work, not a download.
- **Music.** Not sourced and not written. The original had a procedural score;
  nothing here replaces it yet.
