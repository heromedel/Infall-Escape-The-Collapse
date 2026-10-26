"""The Mecha Cybernetic Servicing Core, as pixel art on one 35 x 35 tile (its wall at the top).

Usage: python3 core_px.py OUT_DIR   (writes mecha-servicing-core.svg; floor_bc.py draws it with servicing_core())
heromedel's pick (option N), always upright, never turned; the option rounds are in git history. A non-controlled system: it may look big, but crew walk over its tile (art rules). The machinery sits
against the wall and round the edges; the middle of the tile stays a flat pad the crew stands on.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "console", "tools"))
from tower_px import poly_mask, mirror, shade_parts, OUTLINE, DARK, ARMOUR, PURPLE, DEEP, SCREEN  # noqa: E402

PALE = "#ebe1fa"
PAD, PAD_LIP = "#3d414d", "#5f6576"


def rect(px, x0, y0, x1, y1, col):
    for y in range(y0, y1):
        for x in range(x0, x1):
            px[(x, y)] = col


def core_window(px, x0, y0, x1, y1):
    """The core itself: a slit of light, pale in the middle, deep purple at its ends."""
    rect(px, x0 - 1, y0 - 1, x1 + 1, y1 + 1, OUTLINE)
    for y in range(y0, y1):
        for x in range(x0, x1):
            edge = x in (x0, x1 - 1) or y in (y0, y1 - 1)
            px[(x, y)] = DEEP if edge else (PALE if x == (x0 + x1 - 1) // 2 and y0 + 1 < y < y1 - 2 else PURPLE)


def pad(px, x0, y0, x1, y1, corners=True):
    """The flat stand pad the HalfMech stands on: dark plate, lit upper-left lip, chamfered corners."""
    for y in range(y0, y1):
        for x in range(x0, x1):
            cut = min(x - x0, x1 - 1 - x) + min(y - y0, y1 - 1 - y)
            if cut < 2:
                continue
            ring = cut < 3 or x in (x0, x1 - 1) or y in (y0, y1 - 1)
            px[(x, y)] = OUTLINE if ring else (PAD_LIP if x == x0 + 1 or y == y0 + 1 else PAD)
    if corners:   # four small purple guide lights, set in from the corners
        for x, y in ((x0 + 3, y0 + 3), (x1 - 4, y0 + 3), (x0 + 3, y1 - 4), (x1 - 4, y1 - 4)):
            px[(x, y)] = PURPLE


def housing(rows):
    m = poly_mask(rows)
    return m | mirror(m)


C_ARMS = {0: (3, 9), 1: (3, 9), 2: (3, 9), 3: (3, 9), 4: (3, 8), 5: (4, 8), 6: (4, 7), 7: (4, 7), 8: (4, 7),
          9: (4, 7), 10: (4, 7), 11: (5, 7), 12: (5, 7), 13: (5, 7), 14: (5, 7), 15: (6, 7), 16: (6, 7), 17: (6, 7)}


def core_h(top=10, table=True):
    """H. G with E's arms back (C's tapered arms, unchanged): the table narrowed and its upper jaws drawn compact so
    the arms stay 2 px clear; four jaws with a purple light each, and a purple light inside each arm near its foot."""
    body = housing({0: (10, 17), 1: (10, 17), 2: (10, 17), 3: (11, 17), 4: (11, 17), 5: (11, 17), 6: (12, 17),
                    7: (12, 17), 8: (13, 17), 9: (14, 17)})
    arms = housing(C_ARMS)
    shape = poly_mask({1: (10, 14), 2: (10, 14), 3: (10, 15), 4: (11, 15), 5: (11, 13), 6: (11, 12)})
    jaw = {(x, y + top) for x, y in shape}
    low = {(x, 2 * top + 24 - y) for x, y in jaw}
    jaws = jaw | mirror(jaw) | low | mirror(low)
    px = {}
    if table:
        pad(px, 11, top, 24, 34, corners=False)
    px.update(shade_parts([(jaws, ARMOUR)], 9))
    px.update(shade_parts([(arms, ARMOUR), (body, DARK)], 9))
    core_window(px, 16, 2, 19, 8)
    lights = [(12, top + 3), (22, top + 3), (12, top + 21), (22, top + 21), (6, 13), (28, 13)]
    for xy in lights:
        px[xy] = PURPLE
    near = {(x + dx, y + dy) for x, y in arms if y > 9 for dx in range(-2, 3) for dy in range(-2, 3)}
    table = jaws | {(x, y) for x in range(11, 24) for y in range(top, 34)}
    assert not (near & table), "the arms must stay 2 px clear of the table"
    parts = arms | jaws
    for x, y in lights:   # each light sits inside its part, never on an edge pixel
        assert all((x + dx, y + dy) in parts for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))), (x, y)
    return px


def core_k():
    """K. H with its table and the table's jaws removed (and their lights); nothing else changed."""
    px = core_h()
    keep = core_h(table=False)
    jaw_px = {xy for xy in keep if xy[1] >= 10 and 9 <= xy[0] <= 25}
    for xy in set(px) - set(keep) | jaw_px:
        px.pop(xy, None)
    return px


def core_m(top=10, left=11):
    """M. L with smaller shoulders (the same flared style, scaled down) so the table can be wider."""
    shape = poly_mask({1: (-2, 1), 2: (-2, 1), 3: (-2, 2), 4: (-1, 3), 5: (0, 1), 6: (0, 0)})
    jaw = {(x + left, y + top) for x, y in shape}
    low = {(x, 2 * top + 24 - y) for x, y in jaw}
    jaws = jaw | mirror(jaw) | low | mirror(low)
    px = {}
    pad(px, left, top, 35 - left, 34, corners=False)
    px.update(shade_parts([(jaws, ARMOUR)], 7))
    for y in (top + 3, top + 21):
        px[(left + 1, y)] = PURPLE
        px[(33 - left, y)] = PURPLE
    arms = core_k()
    assert not {(x + dx, y) for x, y in arms if y > 9 for dx in (-1, 0, 1)} & set(px), "the table must not touch the arms"
    px.update(arms)
    return px


MEDBAY = ["..###..", "..###..", "#######", "#######", "#######", "..###..", "..###.."]


def core_n():
    """N. M with the core's light slit widened into a screen like a console's, holding the medbay symbol in Mecha
    power purple (the floor plans' symbol)."""
    px = core_m()
    rect(px, 13, 0, 22, 9, OUTLINE)
    rect(px, 14, 1, 21, 8, SCREEN)
    for j, row in enumerate(MEDBAY):
        for i, ch in enumerate(row):
            if ch == "#":
                px[(14 + i, 1 + j)] = PURPLE
    return px


servicing_core = core_n   # heromedel's pick (2026-10-26)


def to_svg(px, turn=None):
    out = []
    for (x, y), c in px.items():
        if turn:
            x, y = turn(x, y)
        out.append(f'<rect x="{x}" y="{y}" width="1" height="1" fill="{c}"/>')
    return '<g shape-rendering="crispEdges">' + "".join(out) + "</g>"


if __name__ == "__main__":
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    open(os.path.join(out, "mecha-servicing-core.svg"), "w").write(
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 35 35" width="35" height="35">{to_svg(servicing_core())}</svg>\n')
