"""Takes a round 5 sprite to 2x resolution (70 -> 140) without losing what works: every pixel first becomes a 2 x 2
block (identical look), then refinements the extra pixels allow:
  1. the outline goes from 2 sub-pixels thick to 1, its inner sub-pixel taking the part's shadow tone;
  2. the one-pixel stair-steps on the silhouette get their outer corner trimmed, so diagonals read smoother;
  3. shading gets in-between tones: each material's 4-tone ramp becomes 7 tones, and each sub-pixel is a soft average
     of its same-material neighbours, snapped to that ramp, so bands blend instead of stepping hard.
Details that are not part of a ramp (eyes, emblem, buckle) are kept as they are.

Usage: python3 hires.py NAME OUT.svg [SCALE]   (NAME: drifter, leather-jacket or vest-merc)"""
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import crews as C
from crews2 import CREWS


def hexrgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))


def rgbhex(c):
    return "#%02x%02x%02x" % tuple(max(0, min(255, round(v))) for v in c)


RAMPS = [v for k, v in vars(C).items() if isinstance(v, list) and len(v) == 4 and all(isinstance(c, str) and c.startswith("#") for c in v)]
TONE = {}                    # colour -> (ramp number, tone 0..3)
for i, r in enumerate(RAMPS):
    for t, c in enumerate(r):
        TONE.setdefault(c.lower(), (i, t))


def ramp7(r):
    """Seven tones: the ramp's four plus a mix between each pair."""
    out = []
    for a, b in zip(r, r[1:]):
        out += [hexrgb(a), tuple((x + y) / 2 for x, y in zip(hexrgb(a), hexrgb(b)))]
    return out + [hexrgb(r[-1])]


def hires(px):
    big = {(2 * x + i, 2 * y + j): c.lower() for (x, y), c in px.items() for i in (0, 1) for j in (0, 1)}
    inside = lambda p: p in big
    nb4 = lambda x, y: ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1))
    # 2. trim the outer corner of one-pixel stair-steps
    # (decided on the untouched picture first, then applied, so trims never cascade)
    trim = []
    for (x, y) in big:
        empty = [q for q in nb4(x, y) if not inside(q)]
        if len(empty) == 2 and empty[0][0] != empty[1][0] and empty[0][1] != empty[1][1]:
            dx = sum(q[0] - x for q in empty); dy = sum(q[1] - y for q in empty)
            # only the outer corner of a real one-pixel stair: the original pixel's 2 x 2 block sits on a diagonal
            # step, with the block beside it along each axis filled
            if inside((x - dx, y - dy)) and inside((x - 2 * dx, y)) and inside((x, y - 2 * dy)) \
                    and inside((x + dx * 0, y - 2 * dy)) and not inside((x + dx, y + dy)):
                trim.append((x, y))
    for q in trim:
        del big[q]
    # 3. soft shading within each material, snapped to a 7-tone ramp
    edge = {p for p in big if any(not inside(q) for q in nb4(*p))}
    soft = {}
    for p, c in big.items():
        if c not in TONE or p in edge or (p[1] < 2 * 17 and 2 * 29 <= p[0] < 2 * 41):
            continue                                      # the face keeps its hand-placed pixels
        ri, t = TONE[c]
        vals, w = [t * 2.0 * 2], 2 * 2
        for q in [(p[0] + i, p[1] + j) for i in (-2, -1, 0, 1, 2) for j in (-2, -1, 0, 1, 2) if (i, j) != (0, 0)]:
            if q in big and big[q] in TONE and TONE[big[q]][0] == ri and q not in edge:
                vals.append(TONE[big[q]][1] * 2.0); w += 1
        level = round(sum(vals) / w)                      # 0..6 on the 7-tone ramp
        level = max(2, level) if t >= 1 else level        # keep interior shading off the outline tones
        soft[p] = rgbhex(ramp7(RAMPS[ri])[level])
    big.update(soft)
    # 1. a one-sub-pixel outline: the edge in the part's darkest tone, the old outline's inner half lifts to its shadow
    for p in list(big):
        c = big[p]
        if c in TONE and TONE[c][1] == 0 and p not in edge:
            big[p] = RAMPS[TONE[c][0]][1].lower()
    for p in edge:
        if p in big and big[p] in TONE:
            big[p] = RAMPS[TONE[big[p]][0]][0].lower()
        elif p in big:
            pass
    return big


if __name__ == "__main__":
    sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "mecha", "light-attack-frame", "pixel-redo", "tools"))
    from pixel_svg import paths
    name, out = sys.argv[1], sys.argv[2]
    scale = int(sys.argv[3]) if len(sys.argv) > 3 else 2
    fn = dict(zip(["drifter", "leather-jacket", "vest-merc"], [f for _, f in CREWS]))[name]
    big = hires(fn())
    open(out, "w").write(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 140 140" width="{140 * scale}" height="{140 * scale}" '
                         f'shape-rendering="crispEdges">{paths(big)}</svg>\n')
