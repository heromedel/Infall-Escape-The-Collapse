"""Option sheet, round 3: new Shields bases (the hood moves to Piloting).

Usage: python3 organ_options4.py OUT.svg
"""
import math
import sys
import tentauri_floor as f
import tentauri_weapons as tw
from tentauri_floor import T, ORGAN, ORGAN_EDGE, CORAL, LAVENDER_NODE, PINK, _pad, bulb, organ_symbol
from organ_options2 import at


def sh_bubble(name, c, r, kind):
    """A clear dome bubble over the orb: the shield itself, in small."""
    x, y, cx = at(c, r)
    cy = y + 17
    return (f'<g>{_pad(cx, y + T - 5, 13)}{bulb(cx, cy + 3, 7.5)}{organ_symbol(kind, cx, cy + 3, .55)}'
            f'<path d="M{cx - 14},{y + T - 6} A14,21 0 0 1 {cx + 14},{y + T - 6}" fill="{ORGAN}" fill-opacity=".25" '
            f'stroke="{ORGAN_EDGE}" stroke-width="1.3"/>'
            f'<path d="M{cx - 10},{y + 18} Q{cx - 9},{y + 12} {cx - 4},{y + 10}" fill="none" stroke="#ffffff" stroke-width="2" '
            f'stroke-linecap="round" opacity=".85"/></g>')


def sh_shell(name, c, r, kind):
    """A ribbed fan shell standing behind the orb, like a scallop guarding it."""
    x, y, cx = at(c, r)
    by = y + T - 7
    shell = (f'<path d="M{cx},{by} L{cx - 15},{y + 13} A15,13 0 0 1 {cx + 15},{y + 13} Z" fill="{LAVENDER_NODE}" '
             f'stroke="{ORGAN_EDGE}" stroke-width="1.3" stroke-linejoin="round"/>'
             + "".join(f'<path d="M{cx},{by} L{cx + 15 * math.sin(a):.1f},{y + 15 - 13 * math.cos(a):.1f}" stroke="{ORGAN_EDGE}" '
                       f'stroke-width=".8" opacity=".55"/>' for a in [math.radians(d) for d in (-55, -28, 0, 28, 55)]))
    return f'<g>{_pad(cx, y + T - 5, 10)}{shell}{bulb(cx, y + 20, 7.5)}{organ_symbol(kind, cx, y + 20, .55)}</g>'


def sh_bell(name, c, r, kind):
    """A soft bell canopy above the orb with a scalloped hem, sheltering it."""
    x, y, cx = at(c, r)
    hem = "".join(f'<path d="M{cx - 14 + i * 7},{y + 15} q3.5,4 7,0" fill="{PINK}" stroke="{ORGAN_EDGE}" stroke-width="1.1"/>'
                  for i in range(4))
    bell = (f'<path d="M{cx - 14},{y + 15} C{cx - 14},{y + 2} {cx + 14},{y + 2} {cx + 14},{y + 15} Z" fill="{PINK}" '
            f'stroke="{ORGAN_EDGE}" stroke-width="1.3"/>')
    return f'<g>{_pad(cx, y + T - 5, 11)}{hem}{bell}{bulb(cx, y + 23, 7.5)}{organ_symbol(kind, cx, y + 23, .55)}</g>'


def sh_carapace(name, c, r, kind):
    """A small domed carapace of plates under the orb, like armour grown in place."""
    x, y, cx = at(c, r)
    cy = y + 23
    dome = f'<ellipse cx="{cx}" cy="{cy}" rx="15" ry="9" fill="{ORGAN}" stroke="{ORGAN_EDGE}" stroke-width="1.3"/>'
    plates = "".join(f'<path d="M{cx + dx - 4},{cy + dy} l2,-3 h4 l2,3 l-2,3 h-4 Z" fill="none" stroke="{ORGAN_EDGE}" '
                     f'stroke-width=".9" opacity=".6"/>' for dx, dy in ((-9, 1), (9, 1), (-4.5, 4.5), (4.5, 4.5)))
    return f'<g>{dome}{plates}{bulb(cx, y + 13, 8.5)}{organ_symbol(kind, cx, y + 13)}</g>'


OPTS = [("bubble dome", sh_bubble), ("fan shell", sh_shell), ("bell canopy", sh_bell), ("carapace", sh_carapace)]

if __name__ == "__main__":
    S, gap = 4, 30
    cells = ['<text x="12" y="30" font-family="sans-serif" font-size="16" fill="#cfd6e2">Shields</text>']
    for i, (n, fn) in enumerate(OPTS):
        ox, oy = 12 + i * (T * S + gap), 40
        cells.append(f'<g transform="translate({ox},{oy}) scale({S}) translate({-f.X0},{-f.Y0})">'
                     f'<rect x="{f.X0}" y="{f.Y0}" width="{T}" height="{T}" fill="{f.FLOOR}"/>{fn("Shields", 0, 0, "shields")}</g>'
                     f'<text x="{ox + T * S / 2}" y="{oy + T * S + 18}" text-anchor="middle" font-family="sans-serif" '
                     f'font-size="13" fill="#9aa4b4">{i + 1}. {n}</text>')
    open(sys.argv[1], "w").write(f'<svg xmlns="http://www.w3.org/2000/svg" width="{12 + 4 * (T * S + gap)}" height="220">'
                                 f'{tw.defs()}<rect width="100%" height="100%" fill="#141a24"/>{"".join(cells)}</svg>')
