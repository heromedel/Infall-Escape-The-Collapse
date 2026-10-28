"""One command per try (heromedel, round 3: the process has to be faster): build the 2x drifter with every goal and
check, then put everything worth looking at on one sheet, so each try is one build and one look.

The sheet: the whole figure enlarged, the figure at true size (and doubled), and close-ups of the head, the near hand
and the boots, each found from the part map so they follow the figure when it changes.

Usage: python3 review.py OUT_DIR     (writes OUT_DIR/review.png and prints the checks)"""
import json
import os
import subprocess
import sys
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
BG = (157, 162, 170)


def box(parts, names, pad=2):
    ps = [p for p, v in parts.items() if v in names]
    xs = [x for x, _ in ps]; ys = [y for _, y in ps]
    return min(xs) - pad, min(ys) - pad, max(xs) + pad + 1, max(ys) + pad + 1


def main(out_dir):
    checks = subprocess.run([sys.executable, os.path.join(HERE, "hires2.py"), out_dir], capture_output=True, text=True)
    print(checks.stdout + checks.stderr, end="")
    pixels = json.load(open(os.path.join(out_dir, "pixels.json")))
    im = Image.new("RGB", (140, 140), BG)                 # straight from the pixels: no browser scaling or blur
    for k, c in pixels.items():
        im.putpixel(tuple(map(int, k.split(","))), tuple(int(c[i:i + 2], 16) for i in (1, 3, 5)))
    parts = {tuple(map(int, k.split(","))): v for k, v in json.load(open(os.path.join(out_dir, "parts.json"))).items()}
    zoom = lambda b, k: im.crop(b).resize(((b[2] - b[0]) * k, (b[3] - b[1]) * k), Image.NEAREST)
    figure = zoom(box(parts, set(parts.values()), 3), 4)
    tiles = [im.crop(box(parts, set(parts.values()), 3)),
             zoom(box(parts, set(parts.values()), 3), 2),
             zoom(box(parts, {"hair", "face", "eye", "brow", "mouth", "neck"}), 10),
             zoom(box(parts, {"hand-near"}, 3), 10),
             zoom(box(parts, {"boot-near", "boot-far"}), 6)]
    w = figure.width + 20 + max(t.width for t in tiles[2:]) + 20 + tiles[1].width + 20
    h = max(figure.height, sum(t.height + 12 for t in tiles[2:])) + 20
    sheet = Image.new("RGB", (w, h), BG)
    sheet.paste(figure, (10, 10))
    x = figure.width + 30
    sheet.paste(tiles[1], (x, 10)); sheet.paste(tiles[0], (x, tiles[1].height + 30))
    x += tiles[1].width + 20; y = 10
    for t in tiles[2:]:
        sheet.paste(t, (x, y)); y += t.height + 12
    sheet = sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST)    # big enough to read at a glance
    sheet.save(os.path.join(out_dir, "review.png"))
    print("sheet:", os.path.join(out_dir, "review.png"))


if __name__ == "__main__":
    main(sys.argv[1])
