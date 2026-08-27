"""Build a contact sheet of the extracted cast so the art can be judged by eye.

Reading a manifest tells you a file decoded. It does not tell you the sheet is
the right character, that the frames are registered, or that the cut landed on
frame boundaries. Only looking does that.

Usage:
  python tools/contact_sheet.py [--out assets/contact_sheet.png] [--pose idle]
"""

import argparse
import json
import os

from PIL import Image, ImageDraw

CELL_W, CELL_H = 150, 190
COLS = 8
PAD = 6
LABEL_H = 16
BG = (24, 22, 28)
FG = (222, 216, 204)


def first_frame(im, frames, frame_w):
    if frames and frame_w and im.width >= frame_w * frames:
        return im.crop((0, 0, frame_w, im.height))
    return im


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir", default=os.path.join("assets", "extracted"))
    ap.add_argument("--out", default=os.path.join("assets", "contact_sheet.png"))
    ap.add_argument("--pose", default="idle",
                    help="preferred pose; falls back to walk, then any")
    args = ap.parse_args()

    manifest_path = os.path.join(args.dir, "manifest.json")
    with open(manifest_path, encoding="utf-8") as fh:
        man = json.load(fh)

    # one entry per character, preferring the requested pose
    best = {}
    for e in man["images"]:
        if e["kind"] != "ARTDATA":
            continue
        base, _, pose = e["name"].rpartition("_")
        base = base or e["name"]
        rank = 0 if pose == args.pose else (1 if pose == "walk" else 2)
        if base not in best or rank < best[base][0]:
            best[base] = (rank, e)

    names = sorted(best)
    if not names:
        print("FATAL: no ARTDATA characters in manifest")
        return 2

    rows = (len(names) + COLS - 1) // COLS
    W = COLS * (CELL_W + PAD) + PAD
    H = rows * (CELL_H + LABEL_H + PAD) + PAD
    sheet = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(sheet)

    drawn = 0
    for i, name in enumerate(names):
        _, e = best[name]
        path = os.path.join(args.dir, e["file"])
        try:
            im = Image.open(path).convert("RGBA")
        except Exception as exc:  # noqa: BLE001
            print("could not open %s: %s" % (path, exc))
            continue
        im = first_frame(im, e.get("frames"), e.get("frame_w"))
        im.thumbnail((CELL_W, CELL_H), Image.LANCZOS)

        cx = PAD + (i % COLS) * (CELL_W + PAD)
        cy = PAD + (i // COLS) * (CELL_H + LABEL_H + PAD)
        # paste bottom-centred, the way the game registers on the floor row
        px = cx + (CELL_W - im.width) // 2
        py = cy + (CELL_H - im.height)
        sheet.paste(im, (px, py), im)
        draw.text((cx + 2, cy + CELL_H + 2),
                  "%s %s" % (name[:18], e["name"].rpartition("_")[2][:8]), fill=FG)
        drawn += 1

    if drawn == 0:
        print("FATAL: drew zero characters")
        return 3

    os.makedirs(os.path.dirname(args.out) or ".", exist_ok=True)
    sheet.save(args.out)
    print("contact sheet: %s  (%d of %d characters, %dx%d)"
          % (args.out, drawn, len(names), W, H))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
