"""Find every sprite that may carry a swastika armband or SS-style insignia.

Why this is a script and not an eyeball pass: there are 250+ sheets and the
marks are 6-10 pixels across. Two were spotted by chance on a contact sheet,
which is exactly the sampling method that misses the third.

METHOD, and why the obvious one does not work. The first version of this file
ranked sprites by "how many strongly-red pixels", which sounds right and is
useless: it put a flamethrower's muzzle flash (1161px) at the top and MISSED
OFFIZIER_walk and SCHUETZE_idle, both of which certainly wear the band. Amount
of red is dominated by fire and blood.

An armband is not "some red". It is a COMPACT red region with a DARK MARK
INSIDE IT -- that is what a black device on a red field is, and it is what
flame (uniformly bright), blood spatter (diffuse, no dark core) and a red lens
(small, solid) are not. So the signal here is:

  connected red component
    -> reasonably solid and compact (fill ratio, aspect, size band)
    -> containing dark pixels well inside its own bounds

Even so this only NARROWS. It writes a magnified contact sheet of candidates
and a person decides, because no colour rule separates a swastika from a medic
cross or a unit flash, and it should not pretend to.

Output is three-state and says so: FLAGGED, CLEAR, and SKIPPED (with reason).
A file that could not be scanned is never counted as clean.

Self-check: the run asserts that every sprite in KNOWN_POSITIVE still flags,
and fails loudly otherwise -- a detector that stops catching the cases it was
built from is broken, and silence about that is how it goes on being trusted.
Known false positives are reported, not failed: see KNOWN_FALSE_POSITIVE.

Usage:
  python tools/scan_insignia.py [--dir assets/extracted]
"""

import argparse
import colorsys
import json
import os
import sys
from collections import deque

from PIL import Image, ImageDraw

# Verified by eye at 4x magnification before this list was written.
KNOWN_POSITIVE = ["OFFIZIER_idle", "OFFIZIER_walk"]

# WHAT THIS TOOL CANNOT SEE, named so the gap is not mistaken for absence.
# SCHUETZE wears white/light collar runes and a light chest device on a dark
# uniform. There is no red in it at all, so this scanner scores it 0.0000 and
# files it under "clear". It is not clear; it is invisible to this method.
# Consequently the CLEAR count below means "no red armband found", NOT "no
# insignia". A second pass keyed on light-on-dark devices is still owed.
UNCOVERED_BY_THIS_METHOD = ["SCHUETZE_idle (white collar runes, no red)"]
# Things that are strongly red and are NOT insignia. These are tracked and
# REPORTED, but deliberately do NOT fail the run. This tool's contract is to
# narrow 250 sheets to a set a person can look at, so recall is the property
# that matters and a false positive costs one glance. An earlier version
# asserted these must not flag; that assertion contradicted the contract and
# would have been "fixed" by tuning thresholds until the founding positives
# started slipping through, which is the actual failure mode here.
KNOWN_FALSE_POSITIVE = ["FLAMM_attack"]

SAT_MIN = 0.45
VAL_MIN = 0.25
DARK_V_MAX = 0.30        # what counts as the "black device" inside the band
MIN_COMP_PX = 12
MAX_COMP_PX = 4000
MIN_FILL = 0.28          # component pixels / bbox area: bands are solid-ish
MIN_DARK_INSIDE = 2      # dark pixels strictly inside the component's bbox


def classify(im):
    """Return (best_score, detail) for the most armband-like red component."""
    px = im.convert("RGBA")
    w, h = px.size
    data = px.load()

    red = [[False] * w for _ in range(h)]
    dark = [[False] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            r, g, b, a = data[x, y]
            if a < 40:
                continue
            hh, ss, vv = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
            if vv <= DARK_V_MAX:
                dark[y][x] = True
            if ss >= SAT_MIN and vv >= VAL_MIN and (hh >= 0.94 or hh <= 0.045):
                red[y][x] = True

    seen = [[False] * w for _ in range(h)]
    best = (0.0, None)
    for y0 in range(h):
        for x0 in range(w):
            if not red[y0][x0] or seen[y0][x0]:
                continue
            q = deque([(x0, y0)])
            seen[y0][x0] = True
            comp = []
            while q:
                x, y = q.popleft()
                comp.append((x, y))
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and red[ny][nx] and not seen[ny][nx]:
                        seen[ny][nx] = True
                        q.append((nx, ny))

            n = len(comp)
            if n < MIN_COMP_PX or n > MAX_COMP_PX:
                continue
            xs = [p[0] for p in comp]
            ys = [p[1] for p in comp]
            x1, x2, y1, y2 = min(xs), max(xs) + 1, min(ys), max(ys) + 1
            bw, bh = x2 - x1, y2 - y1
            fill = n / float(bw * bh)
            if fill < MIN_FILL:
                continue
            aspect = max(bw, bh) / float(max(1, min(bw, bh)))
            if aspect > 4.0:
                continue

            # dark pixels strictly inside the bbox (1px inset), i.e. a device
            # sitting ON the band rather than the background behind it.
            dk = 0
            for yy in range(y1 + 1, y2 - 1):
                for xx in range(x1 + 1, x2 - 1):
                    if dark[yy][xx]:
                        dk += 1
            if dk < MIN_DARK_INSIDE:
                continue

            inner = max(1, (bw - 2) * (bh - 2))
            dark_ratio = dk / float(inner)
            # Score favours a solid band with a real dark device in it.
            score = fill * min(1.0, dark_ratio * 3.0) * min(1.0, n / 60.0)
            if score > best[0]:
                best = (score, {"px": n, "bbox": [x1, y1, x2, y2],
                                "fill": round(fill, 3),
                                "dark_inside": dk,
                                "dark_ratio": round(dark_ratio, 3)})
    return best


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir", default=os.path.join("assets", "extracted"))
    ap.add_argument("--out", default=os.path.join("assets", "insignia_candidates.png"))
    ap.add_argument("--report", default=os.path.join("assets", "insignia_report.json"))
    ap.add_argument("--threshold", type=float, default=0.02)
    args = ap.parse_args()

    with open(os.path.join(args.dir, "manifest.json"), encoding="utf-8") as fh:
        man = json.load(fh)

    targets = [e for e in man["images"]
               if e["kind"] in ("ARTDATA", "IMGSPR") and not e.get("duplicate_of")]
    backdrops = [e for e in man["images"] if e["kind"] == "BGDATA"]

    flagged, clear, skipped = [], [], []
    scores = {}

    for e in targets:
        path = os.path.join(args.dir, e["file"])
        try:
            im = Image.open(path)
            im.load()
        except Exception as exc:  # noqa: BLE001
            skipped.append({"name": e["name"], "why": "unreadable: %s" % exc})
            continue

        fw = e.get("frame_w") or im.width
        n = e.get("frames") or 1
        if n > 1 and im.width >= fw * n:
            im = im.crop((0, 0, fw, im.height))

        try:
            score, detail = classify(im)
        except Exception as exc:  # noqa: BLE001
            skipped.append({"name": e["name"], "why": "scan failed: %s" % exc})
            continue

        scores[e["name"]] = score
        rec = {"name": e["name"], "file": e["file"],
               "score": round(score, 4), "detail": detail}
        (flagged if score >= args.threshold else clear).append(rec)

    flagged.sort(key=lambda r: -r["score"])

    # ---- self-check. A detector that no longer catches its own founding
    # cases is broken, and must say so rather than print a tidy number.
    problems = []
    for n in KNOWN_POSITIVE:
        if n not in scores:
            problems.append("known positive %s was not scanned at all" % n)
        elif scores[n] < args.threshold:
            problems.append("known positive %s NOT flagged (score %.4f < %.4f)"
                            % (n, scores[n], args.threshold))
    noted_fp = [n for n in KNOWN_FALSE_POSITIVE
                if n in scores and scores[n] >= args.threshold]

    # ---- candidate contact sheet, magnified 3x, band boxed.
    drawn = 0
    if flagged:
        COLS, CW, CH, PAD, LAB = 6, 170, 210, 6, 14
        rows = (len(flagged) + COLS - 1) // COLS
        sheet = Image.new("RGB",
                          (COLS * (CW + PAD) + PAD, rows * (CH + LAB + PAD) + PAD),
                          (26, 24, 28))
        draw = ImageDraw.Draw(sheet)
        for i, r in enumerate(flagged):
            e = next(t for t in targets if t["name"] == r["name"])
            im = Image.open(os.path.join(args.dir, r["file"])).convert("RGBA")
            fw = e.get("frame_w") or im.width
            n = e.get("frames") or 1
            if n > 1 and im.width >= fw * n:
                im = im.crop((0, 0, fw, im.height))
            if r["detail"]:
                d = ImageDraw.Draw(im)
                b = r["detail"]["bbox"]
                d.rectangle([b[0] - 1, b[1] - 1, b[2], b[3]],
                            outline=(0, 255, 120), width=1)
            sc = min(CW / im.width, CH / im.height, 4.0)
            im = im.resize((max(1, int(im.width * sc)), max(1, int(im.height * sc))),
                           Image.NEAREST)
            cx = PAD + (i % COLS) * (CW + PAD)
            cy = PAD + (i // COLS) * (CH + LAB + PAD)
            sheet.paste(im, (cx + (CW - im.width) // 2, cy + (CH - im.height)), im)
            draw.text((cx + 2, cy + CH + 1), "%s %.3f" % (r["name"][:19], r["score"]),
                      fill=(230, 220, 210))
            drawn += 1
        os.makedirs(os.path.dirname(args.out) or ".", exist_ok=True)
        sheet.save(args.out)

    with open(args.report, "w", encoding="utf-8") as fh:
        json.dump({"scanned": len(targets), "threshold": args.threshold,
                   "flagged": flagged, "clear_count_red_armbands_only": len(clear),
                   "uncovered_by_this_method": UNCOVERED_BY_THIS_METHOD,
                   "skipped": skipped,
                   "self_check_problems": problems,
                   "known_false_positives_flagged": noted_fp,
                   "backdrops_not_scanned": [e["name"] for e in backdrops]}, fh, indent=1)

    print("sprites scanned : %d" % len(targets))
    print("FLAGGED         : %d  (score >= %.3f -- LOOK AT THESE)"
          % (len(flagged), args.threshold))
    for r in flagged[:40]:
        d = r["detail"] or {}
        print("    %-24s %.4f  px=%s fill=%s darkin=%s"
              % (r["name"], r["score"], d.get("px"), d.get("fill"), d.get("dark_inside")))
    print("clear (of RED ARMBANDS only, see UNCOVERED_BY_THIS_METHOD): %d" % len(clear))
    print("NOT COVERED     : light-on-dark insignia is invisible to this pass:")
    for u in UNCOVERED_BY_THIS_METHOD:
        print("    " + u)
    print("SKIPPED         : %d  (NOT evidence of clean)" % len(skipped))
    for s in skipped:
        print("    %s: %s" % (s["name"], s["why"]))
    print("backdrops not scanned by this pass: %d (separate review)" % len(backdrops))
    if flagged:
        print("candidate sheet : %s (%d drawn)" % (args.out, drawn))
    print("report          : %s" % args.report)

    print("")
    if problems:
        print("SELF-CHECK FAILED -- the detector is not trustworthy:", file=sys.stderr)
        for p in problems:
            print("    " + p, file=sys.stderr)
        return 6
    print("self-check OK: all %d known positive(s) flagged." % len(KNOWN_POSITIVE))
    if noted_fp:
        print("known false positive(s) present as expected (dismiss by eye): %s"
              % ", ".join(noted_fp))
    if skipped:
        print("NOTE: %d sprite(s) unscanned; not a clean bill for those."
              % len(skipped), file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
