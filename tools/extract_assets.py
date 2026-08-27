"""Pull every base64-embedded image out of the single-file game into real files.

Ghost Front ships as one 13MB index.html; 84% of that is data: URIs. A Godot
port needs them as actual files on disk WITH their frame metadata, and so does
anyone wanting the cast art for another project.

Two binding shapes exist in the source and both are parsed here:

  IMGSPR.NAME = {w:128,h:192,n:6,...};  IMGSPR.NAME.img.src="data:..."
      -> a strip of n frames, each w x h.

  const ARTDATA = { NAME_pose: [frames, frameW, frameH, figureH, footPad, png] }
      -> the painted library. Format is documented at PART 4 of index.html.
         figureH and footPad are the registration data that stop the cast
         bobbing between frames, so they matter as much as the pixels.

It is deliberately loud about anything it cannot name or decode. A silent skip
here reads exactly like "there were fewer images than we thought", and an
unnamed sheet is useless downstream even though it extracted fine.

Usage:
  python tools/extract_assets.py [--src index.html] [--out assets/extracted]
"""

import argparse
import base64
import binascii
import hashlib
import io
import json
import os
import re
import sys

from PIL import Image

B64 = r"[A-Za-z0-9+/=]+"

# IMGSPR.NAME={w:..,h:..,n:..,...};  ... IMGSPR.NAME.img.src="data:image/png;base64,...."
IMGSPR_DECL = re.compile(
    r"IMGSPR\.(?P<name>\w+)\s*=\s*\{(?P<meta>[^}]*)\}"
)
IMGSPR_SRC = re.compile(
    r"IMGSPR\.(?P<name>\w+)\.img\.src\s*=\s*['\"]data:image/(?P<fmt>png|jpeg|jpg);base64,(?P<b64>" + B64 + r")['\"]"
)

# NAME:[frames,frameW,frameH,figureH,footPad,"data:image/png;base64,...."]
ARTDATA_ENTRY = re.compile(
    r"(?P<name>\w+)\s*:\s*\[\s*(?P<nums>[\d\s,.-]+?),\s*['\"]data:image/(?P<fmt>png|jpeg|jpg);base64,(?P<b64>" + B64 + r")['\"]\s*\]"
)

# NAME:["data:image/jpeg;base64,....", width, height]  -- the painted backdrops
BGDATA_ENTRY = re.compile(
    r"(?P<name>\w+)\s*:\s*\[\s*['\"]data:image/(?P<fmt>png|jpeg|jpg);base64,(?P<b64>" + B64 + r")['\"]\s*,\s*(?P<w>\d+)\s*,\s*(?P<h>\d+)\s*\]"
)

ANY_URI = re.compile(r"data:image/(?:png|jpeg|jpg);base64," + B64)


def decode(b64, tag, failures):
    try:
        raw = base64.b64decode(b64, validate=True)
    except (binascii.Error, ValueError) as exc:
        failures.append((tag, "b64 decode failed: %s" % exc))
        return None, None
    try:
        im = Image.open(io.BytesIO(raw))
        im.load()
    except Exception as exc:  # noqa: BLE001 - want every failure reason
        failures.append((tag, "not a decodable image: %s" % exc))
        return None, None
    return raw, im


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", default="index.html")
    ap.add_argument("--out", default=os.path.join("assets", "extracted"))
    args = ap.parse_args()

    if not os.path.isfile(args.src):
        print("FATAL: source not found: %s" % args.src, file=sys.stderr)
        return 2

    with open(args.src, "r", encoding="utf-8", errors="replace") as fh:
        text = fh.read()

    # Independent denominator: a plain substring count owes nothing to the
    # parsers below, so a disagreement indicts the parser, not the file.
    raw_count = len(ANY_URI.findall(text))
    print("raw data: URIs in file : %d" % raw_count)
    if raw_count == 0:
        print("FATAL: no data URIs at all -- wrong file?", file=sys.stderr)
        return 3

    os.makedirs(args.out, exist_ok=True)

    failures = []
    entries = []
    claimed_spans = []

    # ---- pass 1: IMGSPR strips, with their declared w/h/n metadata.
    meta_by_name = {}
    for m in IMGSPR_DECL.finditer(text):
        meta = {}
        for k, v in re.findall(r"(\w+)\s*:\s*(\d+)", m.group("meta")):
            meta[k] = int(v)
        meta_by_name[m.group("name")] = meta

    for m in IMGSPR_SRC.finditer(text):
        name = m.group("name")
        raw, im = decode(m.group("b64"), "IMGSPR.%s" % name, failures)
        if raw is None:
            continue
        meta = meta_by_name.get(name, {})
        entries.append({
            "kind": "IMGSPR",
            "name": name,
            "frames": meta.get("n"),
            "frame_w": meta.get("w"),
            "frame_h": meta.get("h"),
            "figure_h": None,
            "foot_pad": None,
            "raw": raw,
            "size": im.size,
            "mode": im.mode,
            "fmt": (im.format or m.group("fmt")).lower(),
        })
        claimed_spans.append(m.span("b64"))

    # ---- pass 2: the ARTDATA painted library.
    for m in ARTDATA_ENTRY.finditer(text):
        name = m.group("name")
        nums = [n.strip() for n in m.group("nums").split(",") if n.strip()]
        raw, im = decode(m.group("b64"), "ARTDATA.%s" % name, failures)
        if raw is None:
            continue

        def num(i):
            try:
                return int(float(nums[i]))
            except (IndexError, ValueError):
                return None

        entries.append({
            "kind": "ARTDATA",
            "name": name,
            "frames": num(0),
            "frame_w": num(1),
            "frame_h": num(2),
            "figure_h": num(3),
            "foot_pad": num(4),
            "raw": raw,
            "size": im.size,
            "mode": im.mode,
            "fmt": (im.format or m.group("fmt")).lower(),
        })
        claimed_spans.append(m.span("b64"))

    # ---- pass 3: the painted backdrops.
    for m in BGDATA_ENTRY.finditer(text):
        name = m.group("name")
        raw, im = decode(m.group("b64"), "BGDATA.%s" % name, failures)
        if raw is None:
            continue
        entries.append({
            "kind": "BGDATA",
            "name": "bg_" + name,
            "frames": 1,
            "frame_w": int(m.group("w")),
            "frame_h": int(m.group("h")),
            "figure_h": None,
            "foot_pad": None,
            "raw": raw,
            "size": im.size,
            "mode": im.mode,
            "fmt": (im.format or m.group("fmt")).lower(),
        })
        claimed_spans.append(m.span("b64"))

    print("IMGSPR strips parsed   : %d" % sum(1 for e in entries if e["kind"] == "IMGSPR"))
    print("ARTDATA entries parsed : %d" % sum(1 for e in entries if e["kind"] == "ARTDATA"))
    print("BGDATA plates parsed   : %d" % sum(1 for e in entries if e["kind"] == "BGDATA"))
    print("total named            : %d" % len(entries))

    unclaimed = raw_count - len(entries)
    if unclaimed > 0:
        print("WARNING: %d data URIs are not claimed by either parser." % unclaimed,
              file=sys.stderr)
        # Show where they are so they can be chased rather than guessed at.
        claimed = set(s for s, _ in claimed_spans)
        shown = 0
        for m in ANY_URI.finditer(text):
            head = m.start() + m.group(0).index("base64,") + len("base64,")
            if head in claimed:
                continue
            line = text.count("\n", 0, m.start()) + 1
            ctx = text[max(0, m.start() - 90):m.start()].replace("\n", " ")
            print("   unclaimed at line %d: ...%s" % (line, ctx[-80:]), file=sys.stderr)
            shown += 1
            if shown >= 12:
                print("   (further unclaimed suppressed)", file=sys.stderr)
                break

    # ---- write files.
    manifest = []
    seen = {}
    used = {}
    for e in entries:
        digest = hashlib.sha256(e["raw"]).hexdigest()[:12]
        rec = {k: e[k] for k in
               ("kind", "name", "frames", "frame_w", "frame_h", "figure_h", "foot_pad")}
        rec["sheet_w"], rec["sheet_h"] = e["size"]
        rec["mode"] = e["mode"]
        rec["bytes"] = len(e["raw"])
        rec["sha256_12"] = digest

        if digest in seen:
            rec["file"] = seen[digest]
            rec["duplicate_of"] = seen[digest]
            manifest.append(rec)
            continue

        stem = re.sub(r"[^\w.-]", "_", e["name"])
        n = used.get(stem, 0)
        used[stem] = n + 1
        if n:
            stem = "%s__%d" % (stem, n)
        fname = "%s.%s" % (stem, "png" if e["fmt"] == "png" else "jpg")
        with open(os.path.join(args.out, fname), "wb") as fh:
            fh.write(e["raw"])
        seen[digest] = fname
        rec["file"] = fname
        rec["duplicate_of"] = None
        manifest.append(rec)

    # ---- consistency check: does the declared frame grid fit the real sheet?
    grid_bad = []
    for r in manifest:
        fw, fh_, n = r["frame_w"], r["frame_h"], r["frames"]
        if not (fw and fh_ and n):
            continue
        if r["sheet_w"] < fw * n and r["sheet_h"] < fh_ * n:
            grid_bad.append(r)

    with open(os.path.join(args.out, "manifest.json"), "w", encoding="utf-8") as fh:
        json.dump({
            "source": os.path.basename(args.src),
            "raw_uris": raw_count,
            "parsed": len(entries),
            "unclaimed": unclaimed,
            "unique_files": len(seen),
            "failures": [{"what": w, "why": y} for w, y in failures],
            "grid_mismatch": [r["name"] for r in grid_bad],
            "images": manifest,
        }, fh, indent=1)

    print("")
    print("unique files written   : %d" % len(seen))
    print("duplicate URIs         : %d" % sum(1 for r in manifest if r["duplicate_of"]))
    print("decode failures        : %d" % len(failures))
    for w, y in failures:
        print("   FAILED %s: %s" % (w, y))
    if grid_bad:
        print("frame-grid mismatches  : %d (%s)"
              % (len(grid_bad), ", ".join(r["name"] for r in grid_bad[:6])))
    print("manifest               : %s" % os.path.join(args.out, "manifest.json"))

    if not seen:
        print("FATAL: decoded nothing.", file=sys.stderr)
        return 4
    if unclaimed > 0:
        return 5
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
