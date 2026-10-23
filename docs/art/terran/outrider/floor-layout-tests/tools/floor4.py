"""Floor layout test 4 for the SC-1 Outrider: test 3 with Shields forward, two conduit views, and terminal consoles.

Usage: python3 floor4.py HULL_SVG OUT_SVG

Draws the ship twice: selected (conduits glow) and not selected (metal conduits blend into the floor and only broken
ones show). Each system is a terminal against its room's wall with a small symbol in the ship's blue.
"""
import base64
import sys

import floor2 as base
import floor3 as wheel
from floor import glyph
from floor2 import T, cell, centre, ROOMS, DOORS, AIRLOCKS, DOOR, AIRLOCK, WALL, ON, CUT, CORE_TILE

# Shields moves to the bridge's port front corner, so all three bridge consoles face forward
base.SYSTEMS[:] = [s if s[0] != "Shields" else ("Shields", 1, 0, "shields") for s in base.SYSTEMS]
SYSTEMS = base.SYSTEMS

SHIP_BLUE = "#4f8cf0"       # the hull's trim blue, lifted a little to read on a dark screen
TERMINAL = "#e9edf2"
TERMINAL_EDGE = "#7d8696"
SCREEN = "#1b2a44"
METAL = "#c3c9d1"
METAL_EDGE = "#a9b0ba"
SHIP_W = 460


def room_of(c, r):
    for room_id, rc, rr, w, h in ROOMS:
        if rc <= c < rc + w and rr <= r < rr + h:
            return room_id
    return None


def wall_side(c, r):
    """The wall the terminal stands against: forward first, then the sides, then aft."""
    here = room_of(c, r)
    step = {"n": (0, -1), "w": (-1, 0), "e": (1, 0), "s": (0, 1)}
    for side in ("n", "w", "e", "s"):
        dc, dr = step[side]
        if room_of(c + dc, r + dr) != here:
            return side
    return "n"


def terminal(name, c, r, kind):
    """A wall desk with a sloped screen and a keyboard ledge; the symbol stays upright on the screen."""
    x, y = cell(c, r)
    side = wall_side(c, r)
    angle = {"n": 0, "e": 90, "s": 180, "w": 270}[side]
    cx, cy = x + T / 2, y + T / 2
    desk = (f'<rect x="{x + 3}" y="{y + 2}" width="{T - 6}" height="17" rx="3" fill="{TERMINAL}" '
            f'stroke="{TERMINAL_EDGE}" stroke-width="1"/>'
            f'<rect x="{x + 6}" y="{y + 4}" width="{T - 12}" height="12" rx="2" fill="{SCREEN}"/>'
            f'<rect x="{x + 9}" y="{y + 19.5}" width="{T - 18}" height="3" rx="1" fill="#aab2be"/>')
    # where the screen centre ends up after the rotation
    offsets = {"n": (0, -7.5), "e": (7.5, 0), "s": (0, 7.5), "w": (-7.5, 0)}
    sx, sy = cx + offsets[side][0], cy + offsets[side][1]
    symbol = (f'<g transform="translate({sx},{sy}) scale(.78) translate({-sx},{-sy})">'
              f'{glyph(kind, sx, sy, SHIP_BLUE)}</g>')
    return (f'<g class="system" data-name="{name}"><g transform="rotate({angle} {cx} {cy})">{desk}</g>'
            f'{symbol}</g>')


def conduits_metal():
    """Not selected: metal conduits set into the floor. Only the broken runs stand out, with sparks."""
    def path_d(points):
        return "M" + " L".join(f"{centre(c, r)[0]:.1f},{centre(c, r)[1]:.1f}" for c, r in points)
    cut_set = {frozenset(cu) for cu in wheel.DEMO_CUTS}
    out = []
    for path in [wheel.RIM] + list(wheel.SPOKES.values()):
        d = path_d(path)
        out.append(f'<path d="{d}" fill="none" stroke="{METAL_EDGE}" stroke-width="4" stroke-linejoin="round" '
                   f'opacity=".55"/>'
                   f'<path d="{d}" fill="none" stroke="{METAL}" stroke-width="2" stroke-linejoin="round" '
                   f'opacity=".8"/>')
    for a, b in wheel.DEMO_CUTS:
        (ax, ay), (bx, by) = centre(*a), centre(*b)
        mx, my = (ax + bx) / 2, (ay + by) / 2
        out.append(f'<circle cx="{mx}" cy="{my}" r="9" fill="{CUT}" opacity=".25" filter="url(#cglow)"/>'
                   f'<path d="M{ax},{ay} L{bx},{by}" stroke="#0c1018" stroke-width="5"/>'
                   f'<path d="M{mx - 6},{my - 3} l5,2 l-4,2 l6,1 M{mx + 6},{my + 2} l-5,-1 l4,-2" stroke="{CUT}" '
                   f'stroke-width="1.6" fill="none"/>')
    assert all(frozenset((a, b)) in cut_set for a, b in wheel.DEMO_CUTS)
    return "".join(out)


def ship(hull_data, dx, selected):
    parts = [f'<g transform="translate({dx},0)">',
             f'<image href="data:image/svg+xml;base64,{hull_data}" x="0" y="0" width="460" height="740"/>',
             base.floor_plate()]
    parts += [base.room_svg(*rm) for rm in ROOMS]
    parts += [base.door_svg(c, r, s, DOOR) for c, r, s in DOORS]
    parts += [base.door_svg(c, r, s, AIRLOCK) for c, r, s in AIRLOCKS]
    parts.append(f'<g class="conduits">{wheel.conduits() if selected else conduits_metal()}</g>')
    parts.append(base.core())
    parts += [terminal(*s) for s in SYSTEMS]
    label = "Selected: conduits glow" if selected else "Not selected: metal conduits, only breaks show"
    parts.append(f'<text x="230" y="20" font-size="13" font-family="sans-serif" fill="#cfd6e2" '
                 f'text-anchor="middle">{label}</text></g>')
    return "".join(parts)


def legend(x0, stats):
    y = 46
    out = [f'<text x="{x0}" y="{y}" font-size="17" font-family="sans-serif" font-weight="600" fill="#e3e8f1">'
           f'Floor layout test 4</text>',
           f'<text x="{x0}" y="{y + 18}" font-size="11.5" font-family="sans-serif" fill="#97a3b8">'
           f'SC-1 Outrider · test 3 with these changes</text>']
    notes = [
        "Shields moved to the bridge's port front corner, so Piloting, Weapons and Shields all face forward.",
        "Each system is a terminal against its room's wall: a pale desk that blends into the floor, with a small "
        "symbol on its screen in the ship's blue.",
        "The ship is drawn twice. Selected (left): the conduits glow. Not selected (right): the conduits are metal "
        "set into the floor and blend in; only the broken runs show, with sparks.",
        f"Conduit wheel as in test 3: no single cut unpowers a system, two cuts lose at most {stats['worst pair']}, "
        f"and it takes {stats['cuts to kill all']} to lose them all.",
    ]
    yy = y + 52
    for text in notes:
        words, line, lines = text.split(), "", []
        for wd in words:
            if len(line) + len(wd) + 1 > 38:
                lines.append(line)
                line = wd
            else:
                line = (line + " " + wd).strip()
        lines.append(line)
        for i, ln in enumerate(lines):
            out.append(f'<text x="{x0}" y="{yy + i * 15}" font-size="12" font-family="sans-serif" '
                       f'fill="#cfd6e2">{ln}</text>')
        yy += 15 * len(lines) + 14
    # symbol key
    icons = [("piloting", "Piloting"), ("weapons", "Weapons"), ("shields", "Shields"), ("sensors", "Sensors"),
             ("doors", "Doors"), ("medbay", "Medbay"), ("life", "Life Support"), ("engines", "Engines")]
    yy += 6
    for i, (kind, name) in enumerate(icons):
        col, row = i % 2, i // 2
        ix, iy = x0 + col * 140, yy + row * 28
        out.append(f'<rect x="{ix}" y="{iy - 11}" width="22" height="20" rx="3" fill="{SCREEN}"/>'
                   f'<g transform="translate({ix + 11},{iy - 1}) scale(.75) translate({-ix - 11},{-iy + 1})">'
                   f'{glyph(kind, ix + 11, iy - 1, SHIP_BLUE)}</g>'
                   f'<text x="{ix + 30}" y="{iy + 3}" font-size="12" font-family="sans-serif" fill="#cfd6e2">{name}</text>')
    return "".join(out)


def build(hull_svg):
    base.check_layout()
    stats = wheel.check_power()
    hull_data = base64.b64encode(open(hull_svg, "rb").read()).decode()
    w, h = SHIP_W * 2 + 300, 740
    body = ship(hull_data, 0, True) + ship(hull_data, SHIP_W, False) + legend(SHIP_W * 2 + 10, stats)
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">
<title>SC-1 Outrider floor layout test 4</title>
<defs><filter id="cglow" filterUnits="userSpaceOnUse" x="0" y="0" width="{w}" height="{h}">
<feGaussianBlur stdDeviation="1.6" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge>
</filter></defs>
<rect width="100%" height="100%" fill="#0d1220"/>
{body}
</svg>
''', stats


if __name__ == "__main__":
    svg, stats = build(sys.argv[1])
    open(sys.argv[2], "w").write(svg)
    print("saved", sys.argv[2], stats)
