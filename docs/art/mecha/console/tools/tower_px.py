"""Mecha console, the tower, as pixel art on the 35 x 35 tile (north wall at the top).

Usage: python3 tower_px.py OUT.svg   (writes the picked console: stepped cheeks, no ports)
Three cheek shapes (blade, stepped, claw; the option sheets are in git history). Each part is a pixel mask; outlines, lit and shaded edges and a gritty shade variation are worked
out per pixel from the Mecha palette. The picked console has no ports (they only lined up with the hands on the north
wall); the option sheet was made with them, at x 9 and 26, y 3-4.
"""
import random
import sys

OUTLINE, SHADOW, DARK, ARMOUR, EDGE = "#0a0a0e", "#1c1d24", "#2e3039", "#4a4d5a", "#7a7f8e"
PURPLE, DEEP = "#aa28eb", "#5a128c"
SCREEN = "#101217"
GREEN = "#66ff66"


def poly_mask(rows):
    """rows: {y: (x0, x1)} inclusive spans."""
    return {(x, y) for y, (a, b) in rows.items() for x in range(a, b + 1)}


def mirror(mask):
    return {(34 - x, y) for x, y in mask}


def tower_mask():
    rows = {y: (12, 22) for y in range(0, 17)}
    rows.update({17: (13, 21), 18: (14, 20), 19: (15, 19)})
    return poly_mask(rows)


def cheeks(kind):
    if kind == "blade":      # cheeks that narrow down into hooked blade points
        rows = {0: (4, 11), 1: (4, 11), 2: (5, 11), 3: (5, 11), 4: (5, 11), 5: (6, 11), 6: (6, 11), 7: (6, 11),
                8: (7, 11), 9: (7, 11), 10: (7, 11), 11: (8, 11), 12: (8, 10), 13: (8, 10), 14: (8, 9), 15: (7, 8), 16: (6, 7)}
    elif kind == "stepped":  # heavy stepped armour blocks
        rows = {0: (3, 11), 1: (3, 11), 2: (3, 11), 3: (4, 11), 4: (4, 11), 5: (4, 11), 6: (4, 11), 7: (5, 11),
                8: (5, 11), 9: (5, 11), 10: (6, 11), 11: (6, 11), 12: (7, 11), 13: (8, 11)}
    else:                    # "claw": cheeks that curl inward under the screen like closing claws
        rows = {0: (4, 11), 1: (4, 11), 2: (4, 11), 3: (5, 11), 4: (5, 11), 5: (5, 11), 6: (5, 11), 7: (6, 11),
                8: (6, 11), 9: (7, 11), 10: (7, 11), 11: (8, 11), 12: (9, 11), 13: (10, 12), 14: (11, 13)}
    m = poly_mask(rows)
    return m | mirror(m)


def shade_parts(parts, seed):
    """parts: list of (mask, base tone). Outlines on the mask edge, lit pixels along top-left edges, shaded along
    bottom-right edges, and a gritty variation between neighbouring shades inside."""
    rnd = random.Random(seed)
    tones = [SHADOW, DARK, ARMOUR, EDGE]
    px = {}
    for mask, base in parts:
        bi = tones.index(base)
        for (x, y) in mask:
            nb = lambda dx, dy: (x + dx, y + dy) in mask
            if not (nb(1, 0) and nb(-1, 0) and nb(0, 1) and nb(0, -1)) and y > 0:
                px[(x, y)] = OUTLINE
                continue
            t = bi
            if not nb(-1, -1) or not nb(-2, 0) or not nb(0, -2):
                t += 1                                   # lit, facing the light (upper left)
            if not nb(1, 1) or not nb(2, 0) or not nb(0, 2):
                t -= 1                                   # shaded, facing away
            r = rnd.random()
            if r < .22:
                t -= 1                                   # grit: a darker pixel
            elif r > .9:
                t += 1                                   # grit: a brighter fleck
            px[(x, y)] = tones[max(0, min(3, t))]
    return px


def weapons_px():
    """The weapons symbol in pixels: a 7 x 7 ring with a cross."""
    ring = [(2, 0), (3, 0), (4, 0), (1, 1), (5, 1), (0, 2), (6, 2), (0, 3), (6, 3), (0, 4), (6, 4), (1, 5), (5, 5),
            (2, 6), (3, 6), (4, 6)]
    cross = [(3, 1), (3, 2), (3, 4), (3, 5), (1, 3), (2, 3), (3, 3), (4, 3), (5, 3)]
    return set(ring + cross)


def console(kind, seed=3, ports=False):
    tower = tower_mask()
    cheek = cheeks(kind)
    px = shade_parts([(cheek, ARMOUR), (tower, DARK)], seed)
    # screen with the symbol
    for x in range(14, 21):
        for y in range(4, 13):
            px[(x, y)] = SCREEN
    for dx, dy in weapons_px():
        px[(14 + dx, 5 + dy)] = GREEN
    # ports where the hands land: a dark socket with a deep purple rim
    for hx in ((9, 26) if ports else ()):
        for x in range(hx - 1, hx + 2):
            for y in range(2, 6):
                px[(x, y)] = DEEP if (x in (hx - 1, hx + 1) or y in (2, 5)) else OUTLINE
        px[(hx, 3)] = OUTLINE
        px[(hx, 4)] = OUTLINE
    # hints of purple: a slit at the base of the tower and one pixel low on each cheek
    for x in range(16, 19):
        px[(x, 16)] = PURPLE
    return px


def to_svg(px):
    return '<g shape-rendering="crispEdges">' + "".join(
        f'<rect x="{x}" y="{y}" width="1" height="1" fill="{c}"/>' for (x, y), c in px.items()) + "</g>"


if __name__ == "__main__":
    # the picked console: stepped cheeks, no ports
    open(sys.argv[-1], "w").write(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 35 35" width="35" height="35">{to_svg(console("stepped"))}</svg>\n')
