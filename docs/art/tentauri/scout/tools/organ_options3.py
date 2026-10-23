"""Option sheet, round 2: Medbay (bubble, bud), Life Support (tube cactus, air sacs), Engines (levers).

Usage: python3 organ_options3.py OUT.svg
"""
import sys
import tentauri_floor as f
import tentauri_weapons as tw
from tentauri_floor import T, ORGAN, ORGAN_EDGE, CORAL, LAVENDER_NODE, _pad, _stroke, bulb, organ_symbol
from organ_options2 import at, PINK


# ---- Medbay ----
def med_bubble(name, c, r, kind):
    """A clear soft bubble resting on a pad, the orb floating inside it like a patient in care."""
    x, y, cx = at(c, r)
    cy = y + 16
    return (f'<g>{_pad(cx, y + T - 5, 12)}'
            f'<circle cx="{cx}" cy="{cy}" r="14" fill="{ORGAN}" fill-opacity=".28" stroke="{ORGAN_EDGE}" stroke-width="1.3"/>'
            f'{bulb(cx, cy + 1, 7.5)}{organ_symbol(kind, cx, cy + 1, .55)}'
            f'<path d="M{cx - 10},{cy - 5} Q{cx - 8},{cy - 11} {cx - 2},{cy - 12}" fill="none" stroke="#ffffff" '
            f'stroke-width="2" stroke-linecap="round" opacity=".85"/></g>')


def med_bud(name, c, r, kind):
    """A half-open lavender bud: petals rising either side and behind, cupping the orb."""
    x, y, cx = at(c, r)
    back = (f'<path d="M{cx - 6},{y + 20} C{cx - 7},{y + 8} {cx - 2},{y + 3} {cx},{y + 2} C{cx + 2},{y + 3} {cx + 7},{y + 8} '
            f'{cx + 6},{y + 20} Z" fill="{PINK}" stroke="{ORGAN_EDGE}" stroke-width="1.1"/>')
    side = "".join(f'<path d="M{cx},{y + T - 6} C{cx + s * 16},{y + 28} {cx + s * 17},{y + 12} {cx + s * 13},{y + 5} '
                   f'C{cx + s * 10},{y + 12} {cx + s * 6},{y + 18} {cx},{y + T - 6} Z" fill="{LAVENDER_NODE}" '
                   f'stroke="{ORGAN_EDGE}" stroke-width="1.2"/>' for s in (-1, 1))
    return f'<g>{_pad(cx, y + T - 5)}{back}{side}{bulb(cx, y + 19, 7.5)}{organ_symbol(kind, cx, y + 19, .55)}</g>'


# ---- Life Support ----
def life_cactus(name, c, r, kind):
    """A soft cactus of tubes: rounded stalks of different heights, each open at the top, breathing."""
    x, y, cx = at(c, r)
    tubes = [(-10, 13, 4), (10, 10, 4), (-4, 4, 4.2), (4, 7, 4.2)]
    out = []
    for dx, top, w in tubes:
        tx = cx + dx
        out.append(f'<path d="M{tx - w},{y + 26} L{tx - w},{y + top + w} A{w},{w} 0 0 1 {tx + w},{y + top + w} '
                   f'L{tx + w},{y + 26} Z" fill="{ORGAN}" stroke="{ORGAN_EDGE}" stroke-width="1.2"/>'
                   f'<ellipse cx="{tx}" cy="{y + top + w - .5}" rx="{w - 1.6}" ry="1.6" fill="{ORGAN_EDGE}"/>')
    return f'<g>{_pad(cx, y + T - 6, 14)}{"".join(out)}{bulb(cx, y + 22, 7.5)}{organ_symbol(kind, cx, y + 22, .55)}</g>'


def life_sacs(name, c, r, kind):
    """A bunch of small air sacs under and around the orb, fewer and lighter than the first try."""
    x, y, cx = at(c, r)
    pts = [(-11, 26, 4.2), (0, 29, 4.4), (11, 26, 4.2), (-13, 17, 3.6), (13, 17, 3.6)]
    sacs = "".join(f'<circle cx="{cx + dx}" cy="{y + dy}" r="{rr}" fill="{ORGAN}" stroke="{ORGAN_EDGE}" stroke-width="1.1"/>'
                   f'<circle cx="{cx + dx - 1.2}" cy="{y + dy - 1.2}" r="1.1" fill="#ffffff" opacity=".7"/>'
                   for dx, dy, rr in pts)
    return f'<g>{_pad(cx, y + T - 5, 13)}{sacs}{bulb(cx, y + 15, 8.5)}{organ_symbol(kind, cx, y + 15)}</g>'


# ---- Engines ----
def _lever(x0, y0, x1, y1, knob=CORAL):
    return (_stroke(f"M{x0},{y0} L{x1},{y1}", 3.6, 1.8)
            + f'<circle cx="{x1}" cy="{y1}" r="3" fill="{knob}" stroke="{ORGAN_EDGE}" stroke-width="1.1"/>')


def eng_fan(name, c, r, kind):
    """A fan of three knobbed levers rising behind the orb, one pushed further forward: a throttle bank."""
    x, y, cx = at(c, r)
    base = y + T - 8
    lev = _lever(cx - 3, base, cx - 13, y + 7) + _lever(cx, base, cx, y + 3) + _lever(cx + 3, base, cx + 12, y + 10)
    return f'<g>{_pad(cx, y + T - 6, 13)}{lev}{bulb(cx, y + 21, 7.5)}{organ_symbol(kind, cx, y + 21, .55)}</g>'


def eng_row(name, c, r, kind):
    """A soft ridge with a row of three short handles at different pulls, the orb beside it."""
    x, y, cx = at(c, r)
    ridge = (f'<rect x="{cx - 14}" y="{y + 23}" width="28" height="7" rx="3.5" fill="{ORGAN}" stroke="{ORGAN_EDGE}" '
             f'stroke-width="1.2"/>')
    lev = "".join(_lever(cx + dx, y + 26, cx + dx + tilt, y + 15) for dx, tilt in ((-9, -3), (0, 0), (9, 4)))
    return f'<g>{ridge}{lev}{bulb(cx, y + 9, 7.5)}{organ_symbol(kind, cx, y + 9, .55)}</g>'


def eng_grips(name, c, r, kind):
    """Two curled handle grips either side of the orb, like twin throttles held in tendrils."""
    x, y, cx = at(c, r)
    grips = "".join(_stroke(f"M{cx + s * 5},{y + T - 7} L{cx + s * 11},{y + 10}", 4.4, 2.4)
                    + f'<rect x="{cx + s * 11 - 3.5}" y="{y + 4}" width="7" height="10" rx="3.5" fill="{CORAL}" '
                      f'stroke="{ORGAN_EDGE}" stroke-width="1.1" transform="rotate({s * 20} {cx + s * 11} {y + 9})"/>'
                    for s in (-1, 1))
    return f'<g>{_pad(cx, y + T - 6, 13)}{grips}{bulb(cx, y + 20, 7.5)}{organ_symbol(kind, cx, y + 20, .55)}</g>'


ROWS = [("Medbay", "medbay", [("bubble", med_bubble), ("bud", med_bud)]),
        ("Life Support", "life", [("tube cactus", life_cactus), ("air sacs", life_sacs)]),
        ("Engines", "engines", [("lever fan", eng_fan), ("lever row", eng_row), ("twin grips", eng_grips)])]

if __name__ == "__main__":
    S, gap, rowh = 4, 30, 210
    cells = []
    for row, (label, kind, opts) in enumerate(ROWS):
        cells.append(f'<text x="12" y="{30 + row * rowh}" font-family="sans-serif" font-size="16" fill="#cfd6e2">{label}</text>')
        for i, (n, fn) in enumerate(opts):
            ox, oy = 12 + i * (T * S + gap), 40 + row * rowh
            cells.append(f'<g transform="translate({ox},{oy}) scale({S}) translate({-f.X0},{-f.Y0})">'
                         f'<rect x="{f.X0}" y="{f.Y0}" width="{T}" height="{T}" fill="{f.FLOOR}"/>{fn(label, 0, 0, kind)}</g>'
                         f'<text x="{ox + T * S / 2}" y="{oy + T * S + 18}" text-anchor="middle" font-family="sans-serif" '
                         f'font-size="13" fill="#9aa4b4">{i + 1}. {n}</text>')
    W = 12 + 3 * (T * S + gap)
    open(sys.argv[1], "w").write(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{len(ROWS) * rowh + 20}">'
                                 f'{tw.defs()}<rect width="100%" height="100%" fill="#141a24"/>{"".join(cells)}</svg>')
