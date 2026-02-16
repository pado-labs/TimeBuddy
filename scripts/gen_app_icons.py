#!/usr/bin/env python3
from PIL import Image, ImageDraw
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
ICONSET = ROOT/"apps"/"macos"/"TimeBuddy"/"Resources"/"Assets.xcassets"/"AppIcon.appiconset"

BASE_SIZE = 1024

# Colors
BG = (248, 249, 251, 255)    # light neutral
RING = (20, 20, 23, 255)      # dark ring
HANDS = (20, 20, 23, 255)
SHADOW = (0, 0, 0, 25)


def polar(cx, cy, r, deg):
    import math
    rad = math.radians(deg)
    return (cx + r * math.cos(rad), cy + r * math.sin(rad))


def draw_base(size=BASE_SIZE):
    img = Image.new("RGBA", (size, size), BG)
    d = ImageDraw.Draw(img, "RGBA")

    cx = cy = size//2
    radius = int(size*0.38)

    # subtle backdrop shadow circle
    d.ellipse([cx-radius-6, cy-radius-6, cx+radius+6, cy+radius+6], fill=SHADOW)

    # clock face (white)
    FACE = (255,255,255,255)
    d.ellipse([cx-radius, cy-radius, cx+radius, cy+radius], fill=FACE, outline=RING, width=max(2, size//64))

    # hour hand (~2 o'clock)
    hour_len = int(radius*0.55)
    xh, yh = polar(cx, cy, hour_len, -60)  # -60° from +x is ~2 o'clock when 0°=+x
    d.line([cx, cy, xh, yh], fill=HANDS, width=max(12, size//48), joint="curve")

    # minute hand (at 0 minutes)
    min_len = int(radius*0.85)
    xm, ym = polar(cx, cy, min_len, -90)  # straight up
    d.line([cx, cy, xm, ym], fill=HANDS, width=max(8, size//64))

    # center cap
    cap_r = max(10, size//64)
    d.ellipse([cx-cap_r, cy-cap_r, cx+cap_r, cy+cap_r], fill=HANDS)

    return img


def ensure_filenames():
    # Build a filename for each entry in Contents.json
    cj_path = ICONSET/"Contents.json"
    data = json.loads(cj_path.read_text())
    out = []
    for item in data["images"]:
        size = item["size"]  # e.g., "16x16"
        scale = item["scale"]  # "1x" or "2x"
        b = int(size.split("x")[0])
        scale_n = int(scale[:-1])
        px = b * scale_n
        filename = f"appicon_{b}x{b}@{scale}.png"
        item["filename"] = filename
        out.append((px, filename))
    cj_path.write_text(json.dumps(data, indent=2)+"\n")
    return sorted(set(out))


def main():
    ICONSET.mkdir(parents=True, exist_ok=True)

    # Generate base 1024 then resize to all targets
    targets = ensure_filenames()
    base = draw_base(BASE_SIZE)

    for px, filename in targets:
        im = base.resize((px, px), Image.LANCZOS)
        im.save(ICONSET/filename, format="PNG")
    print("Generated:", ", ".join(fn for _, fn in targets))

if __name__ == "__main__":
    main()
