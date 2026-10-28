"""The 2x drifter brought down to game size, the Mecha crew's: a 25-pixel-tall figure in a 35-pixel frame, as pixel
art (no blur), in two outline styles for heromedel to compare (round 3c):

  clean   the figure's own edge, with the unneeded corner pixels taken off its stair-steps
  black   a one-pixel black outline all round outside a slightly smaller figure, drawn as a single line (no doubled
          corners), like the Mecha crew's; the line between the sleeves and the coat goes black too

Each target pixel takes the part that covers most of its cell, and that part's mean colour there, snapped to the
nearest colour the sprite already uses, so the small figure keeps the big one's palette.

Usage: python3 small.py PIXELS.json PARTS.json OUT_DIR"""
import json
import os
import sys
from collections import Counter

NB4 = ((1, 0), (-1, 0), (0, 1), (0, -1))
FRAME = 35
FLOOR = 32                      # the row the feet stand on, as in the Mecha crew frame
BLACK = "#0a0a0e"               # the Mecha crew's outline colour


def load(path):
    return {tuple(map(int, k.split(","))): v for k, v in json.load(open(path)).items()}


def rgb(c):
    return tuple(int(c[i:i + 2], 16) for i in (1, 3, 5))


def downsample(px, parts, height):
    """The figure scaled to `height` pixels tall, centred in the frame, feet on the floor row."""
    xs = [x for x, _ in px]; ys = [y for _, y in px]
    top, bottom = min(ys), max(ys) + 1
    k = (bottom - top) / height
    cx = (min(xs) + max(xs) + 1) / 2
    palette = sorted(set(px.values()))
    out, out_parts = {}, {}
    for ty in range(FRAME):
        for tx in range(FRAME):
            sy0 = top + (ty - (FLOOR + 1 - height)) * k
            sx0 = cx + (tx - FRAME / 2) * k
            cell = [(x, y) for x in range(int(sx0), int(sx0 + k + .999)) for y in range(int(sy0), int(sy0 + k + .999))
                    if sx0 - .5 <= x < sx0 + k - .5 and sy0 - .5 <= y < sy0 + k - .5]
            inside = [p for p in cell if p in px]
            if not cell or len(inside) < .5 * len(cell):
                continue
            part = Counter(parts.get(p) for p in inside).most_common(1)[0][0]
            mine = [rgb(px[p]) for p in inside if parts.get(p) == part]
            mean = tuple(sum(c[i] for c in mine) / len(mine) for i in range(3))
            out[(tx, ty)] = min(palette, key=lambda c: sum((a - b) ** 2 for a, b in zip(rgb(c), mean)))
            out_parts[(tx, ty)] = part
    return out, out_parts


def thin_line(px):
    """A one-pixel line drawn pixel-perfect: drop each L-corner pixel whose two neighbours already touch diagonally,
    so the line has no doubled corners. Decided on the untouched line first, so one removal can't trigger the next."""
    drop = []
    for (x, y) in px:
        for dx, dy in ((1, 1), (1, -1), (-1, 1), (-1, -1)):
            if (x + dx, y) in px and (x, y + dy) in px and (x - dx, y) not in px and (x, y - dy) not in px:
                drop.append((x, y)); break
    return {p: c for p, c in px.items() if p not in drop}


def trim_stairs(px):
    """The silhouette's unneeded corners: on a one-pixel stair-step, the step's outer corner pixel (empty space on two
    sides meeting at a corner, with the stair going on diagonally from it) comes off, so the edge runs as a clean
    diagonal. Real corners (a boot's toe, the hem) aren't stairs and stay."""
    drop = []
    for (x, y) in px:
        for dx, dy in ((1, 1), (1, -1), (-1, 1), (-1, -1)):
            open_sides = (x - dx, y) not in px and (x, y - dy) not in px
            stair = (x + dx, y - dy) not in px and ((x - dx, y + dy) in px)
            if open_sides and (x + dx, y) in px and (x, y + dy) in px and stair:
                drop.append((x, y)); break
    return {p: c for p, c in px.items() if p not in drop}


def black_outline(px, parts):
    """A black line all round, outside the figure, as one pixel-perfect line; seams between sleeve and coat black."""
    out = dict(px)
    ring = {(x + dx, y + dy) for (x, y) in px for dx, dy in NB4} - set(px)
    ring = set(thin_line({p: BLACK for p in ring}))
    for p in ring:
        out[p] = BLACK
    for (x, y), v in parts.items():
        if v in ("arm-near", "arm-far") and any(parts.get((x + dx, y)) in ("coat-near", "coat-far") for dx in (1, -1)) \
                and y > min(yy for (_, yy), vv in parts.items() if vv == v) + 2:
            out[(x, y)] = BLACK
    return out


def svg(px):
    rects = "".join(f'<rect x="{x}" y="{y}" width="1" height="1" fill="{c}"/>' for (x, y), c in sorted(px.items()))
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {FRAME} {FRAME}" width="{FRAME * 4}" '
            f'height="{FRAME * 4}" shape-rendering="crispEdges">{rects}</svg>\n')


if __name__ == "__main__":
    px, parts = load(sys.argv[1]), load(sys.argv[2])
    out_dir = sys.argv[3]; os.makedirs(out_dir, exist_ok=True)
    small, small_parts = downsample(px, parts, 25)
    clean = trim_stairs(small)
    open(os.path.join(out_dir, "drifter-small-clean.svg"), "w").write(svg(clean))
    small, small_parts = downsample(px, parts, 23)
    open(os.path.join(out_dir, "drifter-small-black.svg"), "w").write(svg(black_outline(small, small_parts)))
    print("clean:", len(clean), "px; black:", len(small), "px + outline")
