"""The Mecha Cybernetic Servicing Core, as pixel art on one 35 x 35 tile (its wall at the top).

Usage: python3 core_px.py ../../crew/mecha-crew-sheet.svg OUT_DIR
Writes a test sheet of the core options: each on a deck tile, empty and with a HalfMech standing in it, and turned
to an east wall. A non-controlled system: it may look big, but crew walk over its tile (art rules). The machinery sits
against the wall and round the edges; the middle of the tile stays a flat pad the crew stands on.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "console", "tools"))
from tower_px import poly_mask, mirror, shade_parts, OUTLINE, SHADOW, DARK, ARMOUR, EDGE, PURPLE, DEEP, SCREEN  # noqa: E402
from consoles import frame, T  # noqa: E402

PALE = "#ebe1fa"
FLOOR = ["#6f747d", "#878c95", "#9da2aa", "#b3b8bf"]
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


def core_a():
    """A. Wall core and arms: a stepped housing against the wall with the core's light slit, and two jointed
    servicing arms reaching down either side of the pad, claws turned in."""
    body = housing({0: (10, 17), 1: (10, 17), 2: (10, 17), 3: (11, 17), 4: (11, 17), 5: (11, 17), 6: (12, 17),
                    7: (12, 17), 8: (13, 17), 9: (14, 17)})
    arm = poly_mask({3: (6, 9), 4: (5, 9), 5: (4, 8), 6: (4, 7)} | {y: (4, 6) for y in range(7, 20)} |
                    {20: (4, 8), 21: (5, 9), 22: (7, 9)})
    px = {}
    pad(px, 9, 13, 26, 32, corners=False)
    px.update(shade_parts([(arm | mirror(arm), ARMOUR), (body, DARK)], 5))
    core_window(px, 16, 2, 19, 8)
    for x, y in ((5, 9), (29, 9)):       # elbow joints: one dim purple pixel each
        px[(x, y)] = DEEP
    return px


def core_b():
    """B. Clamp ring: a low core block on the wall and four clamp jaws at the pad's corners, pointing in, that close
    on a mech's limbs while it is serviced."""
    body = housing({0: (11, 17), 1: (11, 17), 2: (11, 17), 3: (12, 17), 4: (12, 17), 5: (13, 17), 6: (14, 17)})
    jaw = poly_mask({11: (4, 9), 12: (4, 9), 13: (4, 10), 14: (5, 11), 15: (6, 8), 16: (6, 7)})
    jaw_low = {(x, 45 - y) for x, y in jaw}
    jaws = jaw | mirror(jaw) | jaw_low | mirror(jaw_low)
    px = {}
    pad(px, 8, 10, 27, 34, corners=False)
    px.update(shade_parts([(jaws, ARMOUR), (body, DARK)], 7))
    core_window(px, 15, 1, 20, 4)
    for x, y in ((10, 14), (24, 14), (10, 31), (24, 31)):
        px[(x, y)] = PURPLE
    return px


def core_c():
    """C. Service arch: a stepped arch of armour over the pad, rising from the wall, with the core's slit at its
    crown and a tool head hanging over the HalfMech's shoulders."""
    arch = housing({0: (3, 17), 1: (3, 17), 2: (3, 17), 3: (3, 9), 4: (3, 8), 5: (4, 8), 6: (4, 7), 7: (4, 7),
                    8: (4, 7), 9: (4, 7), 10: (4, 7), 11: (5, 7), 12: (5, 7), 13: (5, 7), 14: (5, 7), 15: (6, 7),
                    16: (6, 7), 17: (6, 7)})
    head = poly_mask({3: (13, 21), 4: (13, 21), 5: (14, 20), 6: (15, 19)})
    px = {}
    pad(px, 9, 8, 26, 33, corners=False)
    px.update(shade_parts([(arch, ARMOUR), (head, DARK)], 9))
    core_window(px, 12, 1, 23, 2)
    for y in (18, 19):
        px[(6, y)] = DEEP
        px[(28, y)] = DEEP
    return px


def core_d():
    """D. A's wall panel with C's arms (heromedel's mix): the stepped housing and the core's light slit, flanked by
    the arch's stepped arms reaching down either side of the pad. Always drawn upright, never turned."""
    body = housing({0: (10, 17), 1: (10, 17), 2: (10, 17), 3: (11, 17), 4: (11, 17), 5: (11, 17), 6: (12, 17),
                    7: (12, 17), 8: (13, 17), 9: (14, 17)})
    arms = housing({0: (3, 9), 1: (3, 9), 2: (3, 9), 3: (3, 9), 4: (3, 8), 5: (4, 8), 6: (4, 7), 7: (4, 7),
                    8: (4, 7), 9: (4, 7), 10: (4, 7), 11: (5, 7), 12: (5, 7), 13: (5, 7), 14: (5, 7), 15: (6, 7),
                    16: (6, 7), 17: (6, 7)})
    px = {}
    pad(px, 9, 13, 26, 32, corners=False)
    px.update(shade_parts([(arms, ARMOUR), (body, DARK)], 9))
    core_window(px, 16, 2, 19, 8)
    return px


def b_table(px, top, jaws_top=True):
    """B's table: the stand pad with a clamp jaw at each corner, pointing in, a purple light on each jaw."""
    shape = poly_mask({11: (4, 9), 12: (4, 9), 13: (4, 10), 14: (5, 11), 15: (6, 8), 16: (6, 7)})
    jaw = {(x, y + top - 10) for x, y in shape}
    low = {(x, 45 - y) for x, y in shape}
    jaws = low | mirror(low) | ((jaw | mirror(jaw)) if jaws_top else set())
    pad(px, 8, top, 27, 34, corners=False)
    return jaws, [(10, top + 4), (24, top + 4)] * jaws_top + [(10, 31), (24, 31)]


def mix(arm_rows, top, jaws_top, seed=9):
    body = housing({0: (10, 17), 1: (10, 17), 2: (10, 17), 3: (11, 17), 4: (11, 17), 5: (11, 17), 6: (12, 17),
                    7: (12, 17), 8: (13, 17), 9: (14, 17)})
    arms = housing(arm_rows)
    px = {}
    jaws, lights = b_table(px, top, jaws_top)
    px.update(shade_parts([(jaws, ARMOUR)], seed))
    px.update(shade_parts([(arms, ARMOUR), (body, DARK)], seed))
    core_window(px, 16, 2, 19, 8)
    for xy in lights:
        px[xy] = PURPLE
    return px


C_ARMS = {0: (3, 9), 1: (3, 9), 2: (3, 9), 3: (3, 9), 4: (3, 8), 5: (4, 8), 6: (4, 7), 7: (4, 7), 8: (4, 7),
          9: (4, 7), 10: (4, 7), 11: (5, 7), 12: (5, 7), 13: (5, 7), 14: (5, 7), 15: (6, 7), 16: (6, 7), 17: (6, 7)}


def core_e():
    """E. D with B's table: the arms reach down over the table's upper corners (its upper jaws left off)."""
    return mix(C_ARMS, 10, False)


def core_f():
    """F. D with B's table: shorter arms ending above the table, which keeps all four jaws."""
    return mix({y: C_ARMS[y] for y in range(12)}, 12, True)


def core_g(top=10):
    """G. heromedel's notes on E: long arms that stop clear of the table (2 px gap), the table narrowed so all four
    jaws (shoulders) fit, a purple light on each jaw, and a purple light near the foot of each arm, inside it."""
    body = housing({0: (10, 17), 1: (10, 17), 2: (10, 17), 3: (11, 17), 4: (11, 17), 5: (11, 17), 6: (12, 17),
                    7: (12, 17), 8: (13, 17), 9: (14, 17)})
    arm_rows = {0: (1, 9), 1: (1, 9), 2: (1, 9), 3: (1, 8), 4: (1, 6), 5: (1, 6)}
    arm_rows.update({y: (1, 5) for y in range(6, 18)})
    arm_rows.update({18: (2, 4), 19: (3, 3)})
    arms = housing(arm_rows)
    shape = poly_mask({1: (8, 13), 2: (8, 13), 3: (8, 14), 4: (9, 15), 5: (10, 12), 6: (10, 11)})
    jaw = {(x, y + top) for x, y in shape}
    low = {(x, 2 * top + 24 - y) for x, y in jaw}
    jaws = jaw | mirror(jaw) | low | mirror(low)
    px = {}
    pad(px, 11, top, 24, 34, corners=False)
    px.update(shade_parts([(jaws, ARMOUR)], 9))
    px.update(shade_parts([(arms, ARMOUR), (body, DARK)], 9))
    core_window(px, 16, 2, 19, 8)
    lights = [(10, top + 3), (24, top + 3), (10, top + 21), (24, top + 21), (3, 16), (31, 16)]
    for xy in lights:
        px[xy] = PURPLE
    near = {(x + dx, y + dy) for x, y in arms if y > 9 for dx in range(-2, 3) for dy in range(-2, 3)}
    table = jaws | {(x, y) for x in range(11, 24) for y in range(top, 34)}
    assert not (near & table), "the arms must stay 2 px clear of the table"
    for x, y in lights:   # each light sits inside its part, never on an edge pixel
        assert all(px.get((x + dx, y + dy)) not in (None, OUTLINE) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))), (x, y)
    return px


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


def core_i(top=20):
    """I. E's arms with F's table (B's, unchanged in shape): the table moved down so its upper jaws sit 2 px below
    the arm tips; a purple light inside each arm near its foot."""
    body = housing({0: (10, 17), 1: (10, 17), 2: (10, 17), 3: (11, 17), 4: (11, 17), 5: (11, 17), 6: (12, 17),
                    7: (12, 17), 8: (13, 17), 9: (14, 17)})
    arms = housing(C_ARMS)
    px = {}
    jaws, lights = b_table(px, top, True)
    px.update(shade_parts([(jaws, ARMOUR)], 9))
    px.update(shade_parts([(arms, ARMOUR), (body, DARK)], 9))
    core_window(px, 16, 2, 19, 8)
    for xy in lights + [(6, 13), (28, 13)]:
        px[xy] = PURPLE
    near = {(x + dx, y + dy) for x, y in arms if y > 9 for dx in range(-2, 3) for dy in range(-2, 3)}
    table = jaws | {(x, y) for x in range(8, 27) for y in range(top, 34)}
    assert not (near & table), "the arms must stay 2 px clear of the table"
    return px


def core_j():
    """J. H with its table removed, nothing else changed (heromedel): the four jaws stand on the deck."""
    return core_h(table=False)


def core_k():
    """K. H with its table and the table's jaws removed (and their lights); nothing else changed."""
    px = core_h()
    keep = core_h(table=False)
    jaw_px = {xy for xy in keep if xy[1] >= 10 and 9 <= xy[0] <= 25}
    for xy in set(px) - set(keep) | jaw_px:
        px.pop(xy, None)
    return px


def core_l(top=10, shift=5):
    """L. K with F's table style (B's flared jaws and lights, unchanged in shape) made skinnier, as tall as H's table,
    clear of the arms."""
    shape = poly_mask({11: (4, 9), 12: (4, 9), 13: (4, 10), 14: (5, 11), 15: (6, 8), 16: (6, 7)})
    jaw = {(x + shift, y + top - 10) for x, y in shape}
    low = {(x + shift, 45 - y) for x, y in shape}
    jaws = jaw | mirror(jaw) | low | mirror(low)
    px = {}
    pad(px, 8 + shift, top, 27 - shift, 34, corners=False)
    px.update(shade_parts([(jaws, ARMOUR)], 7))
    for x, y in ((10, top + 4), (24, top + 4), (10, 31), (24, 31)):
        px[(x + shift if x < 17 else x - shift, y)] = PURPLE
    arms = core_k()
    table = set(px)
    assert not {(x + dx, y) for x, y in arms if y > 9 for dx in (-1, 0, 1)} & table, "the table must not touch the arms"
    px.update(arms)
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


OPTIONS = [("A. Wall core and arms", core_a), ("B. Clamp ring", core_b), ("C. Service arch", core_c), ("D. A's panel, C's arms", core_d),
           ("E. D, arms over B's table", core_e), ("F. D, short arms, B's table", core_f),
           ("G. Long arms clear of the table", core_g),
           ("H. E's arms, clear of the table", core_h),
           ("I. E's arms, F's table lower", core_i),
           ("J. H without the table", core_j),
           ("K. H without the table or its jaws", core_k),
           ("L. K with F's table, skinnier and tall", core_l),
           ("M. L with smaller shoulders, wider table", core_m),
           ("N. M with a symbol screen", core_n)]
TURN_E = lambda x, y: (34 - y, x)


def to_svg(px, turn=None):
    out = []
    for (x, y), c in px.items():
        if turn:
            x, y = turn(x, y)
        out.append(f'<rect x="{x}" y="{y}" width="1" height="1" fill="{c}"/>')
    return '<g shape-rendering="crispEdges">' + "".join(out) + "</g>"


def tile(wall="n"):
    px = {}
    for y in range(T):
        for x in range(T):
            px[(x, y)] = FLOOR[0] if x == 0 or y == 0 else FLOOR[3] if x == 1 or y == 1 else FLOOR[2]
    wall_rows = [(x, y) for x in range(T) for y in (0, 1)]
    for x, y in wall_rows:
        px[(x, y) if wall == "n" else TURN_E(x, y)] = "#1c1d24"
    return to_svg(px)


if __name__ == "__main__":
    sheet = open(sys.argv[1]).read()
    out = sys.argv[2]
    os.makedirs(out, exist_ok=True)
    stand = frame(sheet, 0, 0)          # walk down, first frame: standing in the core
    S = 6
    cells = []
    for i, (name, fn) in enumerate(OPTIONS):
        px = fn()
        open(os.path.join(out, f"core-option-{'abcdefghijklmn'[i]}.svg"), "w").write(
            f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 35 35" width="35" height="35">{to_svg(px)}</svg>\n')
        x0 = 20 + i * (T * S + 30)
        cells.append(
            f'<text x="{x0 + T * S / 2}" y="24" font-size="14" fill="#e6ebf2" text-anchor="middle" font-family="sans-serif">{name}</text>'
            f'<g transform="translate({x0},36) scale({S})">{tile()}{to_svg(px)}</g>'
            f'<g transform="translate({x0},{50 + T * S}) scale({S})">{tile()}{to_svg(px)}{stand}</g>'
            f'<g transform="translate({x0 + T * S / 2 - T * 3},{64 + 2 * T * S}) scale(3)">{tile("e")}{to_svg(px, TURN_E)}{stand}</g>'
            f'<g transform="translate({x0},{80 + 2 * T * S + 3 * T})">{tile()}{to_svg(px)}</g>'
            f'<g transform="translate({x0 + 40},{80 + 2 * T * S + 3 * T})">{tile()}{to_svg(px)}{stand}</g>')
    W = 20 + len(OPTIONS) * (T * S + 30)
    H = 100 + 2 * T * S + 4 * T
    open(os.path.join(out, "core-options.svg"), "w").write(
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}"><rect width="100%" height="100%" fill="#141920"/>{"".join(cells)}</svg>')
