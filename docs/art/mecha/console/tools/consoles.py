"""Mecha console versions for a north-wall tile: three shapes, each without limb ports and with two ports exactly where
the HalfMech's hands land in its power-pulse typing frame (tile pixels (9, 3-4) and (26, 3-4)).

Usage: python3 consoles.py ../../crew/mecha-crew-sheet.svg OUT.svg
"""
import re
import sys

T = 35
OUTLINE, SHADOW, DARK, ARMOUR, EDGE = "#0a0a0e", "#1c1d24", "#2e3039", "#4a4d5a", "#7a7f8e"
PURPLE, DEEP = "#aa28eb", "#5a128c"
SCREEN = "#101217"
FLOOR, LINE = "#a4aab1", "#8c939b"
GREEN = "#66ff66"
HANDS = [(9.5, 4), (26.5, 4)]   # centres of the hand pixels in the typing-up frame


def frame(sheet, col, row):
    """One 35 x 35 frame of the crew sheet as SVG rects (opaque pixels only)."""
    out = []
    for fill, d in re.findall(r'<path fill="(#[0-9a-fA-F]{6})" d="([^"]*)"', sheet):
        for x, y, w in re.findall(r'M(\d+) (\d+)h(\d+)v1', d):
            x, y, w = int(x), int(y), int(w)
            if col * T <= x < col * T + T and row * T <= y < row * T + T:
                out.append(f'<rect x="{x - col * T}" y="{y - row * T}" width="{w}" height="1" fill="{fill}"/>')
    return f'<g shape-rendering="crispEdges">{"".join(out)}</g>'


def weapons_symbol(x, y, c, k=.5):
    s = 7
    return (f'<g transform="translate({x},{y}) scale({k}) translate({-x},{-y})">'
            f'<circle cx="{x}" cy="{y}" r="{s * .75}" fill="none" stroke="{c}" stroke-width="1.8"/>'
            f'<path d="M{x - s},{y} H{x + s} M{x},{y - s} V{y + s}" stroke="{c}" stroke-width="1.6"/></g>')


def port(x, y):
    return (f'<circle cx="{x}" cy="{y}" r="2.6" fill="{SHADOW}" stroke="{OUTLINE}" stroke-width=".6"/>'
            f'<circle cx="{x}" cy="{y}" r="1.7" fill="{OUTLINE}" stroke="{DEEP}" stroke-width=".8"/>')


def slab(ports):
    """Slab: a chamfered near-black desk, the screen in its face, a purple trim line along the front."""
    body = (f'<path d="M3,1 H32 V15 L29,19 H6 L3,15 Z" fill="{DARK}" stroke="{OUTLINE}" stroke-width="1"/>'
            f'<path d="M4,2 H31 V6 H4 Z" fill="{SHADOW}"/>'
            f'<rect x="12" y="7" width="11" height="8" rx="1" fill="{SCREEN}" stroke="{OUTLINE}" stroke-width=".6"/>'
            f'<path d="M7,18 H28" stroke="{PURPLE}" stroke-width=".9"/>'
            + weapons_symbol(17.5, 11, GREEN))
    return body + ("".join(port(*h) for h in HANDS) if ports else "")


def tower(ports):
    """Tower: a narrow armoured column with an angled screen, armoured cheeks on either side for the hands."""
    body = (f'<path d="M5,1 H12 V12 L9,14 H5 Z" fill="{ARMOUR}" stroke="{OUTLINE}" stroke-width=".8"/>'
            f'<path d="M30,1 H23 V12 L26,14 H30 Z" fill="{ARMOUR}" stroke="{OUTLINE}" stroke-width=".8"/>'
            f'<path d="M11,1 H24 V16 L21,20 H14 L11,16 Z" fill="{DARK}" stroke="{OUTLINE}" stroke-width="1"/>'
            f'<path d="M13,5 H22 L21,14 H14 Z" fill="{SCREEN}" stroke="{OUTLINE}" stroke-width=".6"/>'
            f'<path d="M15,18.2 H20" stroke="{PURPLE}" stroke-width=".9"/>'
            + weapons_symbol(17.5, 9.6, GREEN, .45))
    return body + ("".join(port(*h) for h in HANDS) if ports else "")


def lowbar(ports):
    """Low bar: a wide, low console across the wall, a purple light strip, the screen raised in its middle."""
    body = (f'<path d="M2,1 H33 V9 L31,11 H4 L2,9 Z" fill="{DARK}" stroke="{OUTLINE}" stroke-width="1"/>'
            f'<path d="M3,9.5 H32" stroke="{PURPLE}" stroke-width=".8"/>'
            f'<path d="M12,4 H23 V16 L21,18 H14 L12,16 Z" fill="{ARMOUR}" stroke="{OUTLINE}" stroke-width=".9"/>'
            f'<rect x="13.5" y="6" width="8" height="8" rx="1" fill="{SCREEN}"/>'
            + weapons_symbol(17.5, 10, GREEN, .42))
    return body + ("".join(port(*h) for h in HANDS) if ports else "")


SHAPES = [("Slab", slab), ("Tower", tower), ("Low bar", lowbar)]

if __name__ == "__main__":
    sheet = open(sys.argv[1]).read()
    typing = frame(sheet, 3, 15)   # power-pulse typing, facing up, the pulse at the hands
    S = 5
    cells = []
    for i, (name, fn) in enumerate(SHAPES):
        for j, ports in enumerate((False, True)):
            x0 = 20 + (i * 2 + j) * (T * S + 24)
            tile = f'<rect width="{T}" height="{T}" fill="{FLOOR}"/><path d="M0,0 H35" stroke="#16181c" stroke-width="2"/>'
            label = f'{name}, {"ports at the hands" if ports else "no ports"}'
            cells.append(f'<text x="{x0 + T * S / 2}" y="24" font-size="13" fill="#e6ebf2" text-anchor="middle" font-family="sans-serif">{label}</text>'
                         f'<g transform="translate({x0},36) scale({S})">{tile}{fn(ports)}</g>'
                         f'<g transform="translate({x0},{36 + T * S + 14}) scale({S})">{tile}{fn(ports)}{typing}</g>'
                         f'<g transform="translate({x0 + T * S - T},{36 + 2 * (T * S + 14)})">{tile}{fn(ports)}{typing}</g>')
    W = 20 + 6 * (T * S + 24)
    H = 36 + 2 * (T * S + 14) + T + 44
    open(sys.argv[2], "w").write(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}"><rect width="100%" height="100%" fill="#141920"/>'
                                 f'<text x="20" y="{H - 10}" font-size="12" fill="#9aa6b8" font-family="sans-serif">Top: the console. Middle: with the power-pulse typing frame over it. Bottom right of each: true size.</text>'
                                 f'{"".join(cells)}</svg>')
