"""Floor layout test 1 for the SC-1 Outrider: rooms, single-tile systems and the conduit ring.

Usage: python3 floor.py HULL_SVG OUT_SVG [conduit_style]
conduit_style: glow (green glowing wire), black (plain dark cable), track (twin rails with a lit core).

Rooms sit on a 30 px tile grid laid over the hull. A room holds any number of single-tile systems, and rooms run
from 1x1 to 4x4. The conduit ring runs over the floor from the core through every system and back, so each system
has two paths to the core.
"""
import base64
import sys

T = 30            # tile size
X0, Y0 = 140, 110 # grid origin on the hull
W, H = 820, 740   # hull on the left, legend on the right

FLOOR = "#c6ccd5"
FLOOR_EDGE = "#aab2be"
WALL = "#1f2633"
DOOR = "#7fb2ff"
CONSOLE = "#2a3446"
ON = "#5dffa8"      # powered conduit glow
OFF = "#56606f"     # switched off
CUT = "#ff6a4d"
SPARE_TINT = "#b4bac4"


def cell(c, r):
    return X0 + c * T, Y0 + r * T


def centre(c, r):
    x, y = cell(c, r)
    return x + T / 2, y + T / 2


# rooms: (name, col, row, width, height, is_spare)
ROOMS = [
    ("Bridge", 1, 0, 4, 3, False),
    ("Spare", 1, 3, 1, 1, True),
    ("Sensors", 2, 3, 2, 1, False),
    ("Doors", 4, 3, 1, 1, False),
    ("Spare", 1, 4, 2, 2, True),
    ("Medbay", 3, 4, 2, 2, False),
    ("Hall", 2, 6, 2, 1, False),
    ("Spare", 0, 6, 2, 3, True),
    ("Spare", 4, 6, 2, 2, True),
    ("Core", 2, 7, 2, 4, False),
    ("Quarters", 0, 9, 2, 3, False),
    ("Life Support", 4, 8, 2, 3, False),
    ("Hall", 2, 11, 2, 3, False),
    ("Storage", 1, 12, 1, 2, False),
    ("Airlock", 0, 12, 1, 2, False),
    ("Spare", 4, 11, 2, 3, True),
    ("Engines", 1, 14, 4, 2, False),
]

# single-tile systems: (name, col, row, glyph, powered)
SYSTEMS = [
    ("Weapons", 1, 0, "weapons", True),
    ("Piloting", 2, 0, "piloting", True),
    ("Shields", 1, 2, "shields", True),
    ("Sensors", 3, 3, "sensors", True),
    ("Doors", 4, 3, "doors", True),
    ("Medbay", 4, 5, "medbay", False),     # switched off, to show the switch
    ("Life Support", 5, 9, "life", True),
    ("Engines", 3, 14, "engines", True),
]

# doors between rooms: (col, row, side) where side is the tile edge the door sits on
DOORS = [
    (2, 2, "s"), (3, 3, "e"), (1, 3, "n"), (1, 3, "s"), (4, 3, "s"), (2, 5, "s"), (3, 5, "s"),
    (2, 6, "w"), (3, 6, "e"), (2, 6, "s"), (1, 8, "s"), (4, 7, "s"), (2, 10, "s"), (1, 11, "e"),
    (2, 12, "w"), (1, 12, "w"), (3, 12, "e"), (2, 13, "s"), (3, 13, "s"), (0, 12, "w"),
]

# the conduit ring, as tile centres: core, Shields, Weapons, Piloting, Sensors, Doors, Medbay, Life Support,
# Engines, back to the core
RING = [(2, 8), (2, 7), (2, 6), (1, 6), (1, 5), (1, 4), (1, 3), (1, 2), (1, 1), (1, 0), (2, 0), (2, 1), (2, 2), (3, 2),
        (3, 3), (4, 3), (4, 4), (4, 5), (4, 6), (4, 7), (5, 7), (5, 8), (5, 9), (5, 10), (5, 11), (5, 12),
        (4, 12), (4, 13), (4, 14), (3, 14), (3, 13), (3, 12), (3, 11), (3, 10), (3, 9)]
CUT_AFTER = 4          # the ring is cut between RING[3] and RING[4], on the port side
SPARE_TAPS = [((1, 4), (2, 4)), ((1, 6), (0, 6)), ((4, 6), (5, 6)), ((5, 12), (5, 13))]


def glyph(kind, x, y, colour):
    """Simple console symbols drawn for Infall."""
    s = 7
    g = {
        "piloting": f'<path d="M{x - s},{y + s * .6} L{x},{y - s} L{x + s},{y + s * .6} L{x},{y + s * .1} Z" fill="{colour}"/>',
        "weapons": (f'<circle cx="{x}" cy="{y}" r="{s * .75}" fill="none" stroke="{colour}" stroke-width="1.8"/>'
                    f'<path d="M{x - s},{y} H{x + s} M{x},{y - s} V{y + s}" stroke="{colour}" stroke-width="1.6"/>'),
        "shields": f'<path d="M{x - s},{y + s * .3} Q{x},{y - s * 1.3} {x + s},{y + s * .3}" fill="none" stroke="{colour}" stroke-width="2.2"/>'
                   f'<path d="M{x - s * .55},{y + s * .7} Q{x},{y - s * .4} {x + s * .55},{y + s * .7}" fill="none" stroke="{colour}" stroke-width="1.8"/>',
        "sensors": (f'<path d="M{x - s},{y - 3} Q{x - 1},{y + 6} {x + 4},{y - 7} Z" fill="{colour}"/>'   # a dish
                    f'<path d="M{x - 1},{y + 1} L{x - 2},{y + s} M{x - 5},{y + s} h6" stroke="{colour}" stroke-width="1.8"/>'
                    f'<path d="M{x + 3},{y - 2} q3,0 3,-3 M{x + 3},{y + 2} q7,0 7,-7" fill="none" stroke="{colour}" '
                    f'stroke-width="1.4"/>'),
        "doors": (f'<rect x="{x - s * .7}" y="{y - s}" width="{s * 1.4}" height="{s * 2}" rx="1" fill="none" stroke="{colour}" stroke-width="1.8"/>'
                  f'<path d="M{x},{y - s} V{y + s}" stroke="{colour}" stroke-width="1.4"/>'),
        "medbay": f'<path d="M{x - 2.5},{y - s} h5 v{s - 2.5} h{s - 2.5} v5 h-{s - 2.5} v{s - 2.5} h-5 v-{s - 2.5} h-{s - 2.5} v-5 h{s - 2.5} Z" fill="{colour}"/>',
        "life": (f'<circle cx="{x}" cy="{y}" r="{s * .9}" fill="none" stroke="{colour}" stroke-width="1.6"/>'
                 + "".join(f'<path d="M{x},{y} q{dx * 4},{dy * 4} {dx * 6},{dy * 1}" fill="none" stroke="{colour}" stroke-width="2"/>'
                           for dx, dy in ((1, -1), (-1, 1), (1, 1), (-1, -1)))),
        "engines": (f'<path d="M{x - s * .7},{y - s} h{s * 1.4} l{s * .5},{s * 1.2} h-{s * 2.4} Z" fill="{colour}"/>'
                    f'<path d="M{x - s * .4},{y + s * .5} L{x},{y + s * 1.1} L{x + s * .4},{y + s * .5}" fill="none" stroke="{colour}" stroke-width="1.6"/>'),
    }
    return g[kind]


def room_svg(name, c, r, w, h, spare):
    x, y = cell(c, r)
    pw, ph = w * T, h * T
    fill = SPARE_TINT if spare else FLOOR
    out = [f'<g class="room" data-name="{name}">',
           f'<rect x="{x}" y="{y}" width="{pw}" height="{ph}" fill="{fill}"/>']
    for i in range(1, w):
        out.append(f'<line x1="{x + i * T}" y1="{y}" x2="{x + i * T}" y2="{y + ph}" stroke="{FLOOR_EDGE}" stroke-width="1"/>')
    for j in range(1, h):
        out.append(f'<line x1="{x}" y1="{y + j * T}" x2="{x + pw}" y2="{y + j * T}" stroke="{FLOOR_EDGE}" stroke-width="1"/>')
    if spare:
        out.append(f'<rect x="{x + 3}" y="{y + 3}" width="{pw - 6}" height="{ph - 6}" fill="none" stroke="#8b94a2" '
                   f'stroke-width="1" stroke-dasharray="3 3"/>')
    out.append(f'<rect x="{x}" y="{y}" width="{pw}" height="{ph}" fill="none" stroke="{WALL}" stroke-width="3"/>')
    out.append("</g>")
    return "".join(out)


def room_label(name, c, r, w, h, spare):
    """Room name centred on the free tiles of the room's bottom row, raised clear of the door bars.
    A 1x1 room with a console needs no label: the console says what it is."""
    label = "spare" if spare else name
    taken = {(sc, sr) for _, sc, sr, _, _ in SYSTEMS}
    if name == "Core":
        taken |= {(2, 8), (3, 8), (2, 9), (3, 9)}
    for row in range(r + h - 1, r - 1, -1):
        free = [cc for cc in range(c, c + w) if (cc, row) not in taken]
        if free:
            break
    else:
        return ""
    if w == 1 and h == 1 and not spare:
        return ""
    x_left, _ = cell(free[0], row)
    x_right, y = cell(free[-1], row)
    span = x_right + T - x_left
    size = 7 if span > T else (5.4 if len(label) > 6 else 6.2)
    return (f'<text x="{x_left + span / 2}" y="{y + T - 9}" font-size="{size}" font-family="sans-serif" '
            f'font-weight="600" text-anchor="middle" fill="#3a4354" letter-spacing=".3">{label.upper()}</text>')


def door_svg(c, r, side):
    x, y = cell(c, r)
    if side in ("n", "s"):
        yy = y if side == "n" else y + T
        return (f'<rect x="{x + 8}" y="{yy - 2.5}" width="{T - 16}" height="5" fill="{DOOR}" stroke="{WALL}" '
                f'stroke-width="1"/>')
    xx = x if side == "w" else x + T
    return f'<rect x="{xx - 2.5}" y="{y + 8}" width="5" height="{T - 16}" fill="{DOOR}" stroke="{WALL}" stroke-width="1"/>'


def conduit_path(points):
    return "M" + " L".join(f"{centre(c, r)[0]:.1f},{centre(c, r)[1]:.1f}" for c, r in points)


def conduits(style):
    """The ring drawn over the floor; the cut segment and spare taps are drawn without power."""
    live_a = RING[:CUT_AFTER + 1]
    live_b = RING[CUT_AFTER + 1:] + [RING[0]]
    out = []
    for seg in (live_a, live_b):
        d = conduit_path(seg)
        if style == "black":
            out.append(f'<path d="{d}" fill="none" stroke="#0c1018" stroke-width="5" stroke-linejoin="round"/>')
        elif style == "track":
            out.append(f'<path d="{d}" fill="none" stroke="#0c1018" stroke-width="8" stroke-linejoin="round"/>'
                       f'<path d="{d}" fill="none" stroke="#3b4556" stroke-width="5" stroke-linejoin="round"/>'
                       f'<path d="{d}" fill="none" stroke="#0c1018" stroke-width="2.4" stroke-linejoin="round"/>'
                       f'<path d="{d}" fill="none" stroke="{ON}" stroke-width="1.1" stroke-linejoin="round" '
                       f'filter="url(#cglow)"/>')
            # sleepers across the track, like ties under a rail line
            out.append(f'<path d="{d}" fill="none" stroke="#0c1018" stroke-width="10" stroke-dasharray="1.6 6" '
                       f'opacity=".9"/>')
        else:
            out.append(f'<path d="{d}" fill="none" stroke="#0c1018" stroke-width="5.5" stroke-linejoin="round"/>'
                       f'<path d="{d}" fill="none" stroke="{ON}" stroke-width="2" stroke-linejoin="round" '
                       f'filter="url(#cglow)"/>'
                       f'<path d="{d}" fill="none" stroke="#e8fff2" stroke-width=".8" stroke-linejoin="round"/>')
    # flow chevrons: power leaves the core both ways and meets at the cut, so every system stays powered
    if style == "glow":
        for seg, every in ((live_a, 2), (live_b, 4)):
            pts = [centre(c, r) for c, r in seg]
            if seg is live_b:
                pts = pts[::-1]          # live_b flows from the core backwards round the ring
            for i in range(0, len(pts) - 1, every):
                (x1, y1), (x2, y2) = pts[i], pts[i + 1]
                if (x1, y1) == (x2, y2):
                    continue
                mx, my = (x1 + x2) / 2, (y1 + y2) / 2
                dx, dy = (x2 - x1), (y2 - y1)
                n = (dx * dx + dy * dy) ** .5
                ux, uy = dx / n, dy / n
                px, py = -uy, ux
                tip = (mx + ux * 3, my + uy * 3)
                a = (mx - ux * 2 + px * 3, my - uy * 2 + py * 3)
                b = (mx - ux * 2 - px * 3, my - uy * 2 - py * 3)
                out.append(f'<path d="M{a[0]:.1f},{a[1]:.1f} L{tip[0]:.1f},{tip[1]:.1f} L{b[0]:.1f},{b[1]:.1f}" '
                           f'fill="none" stroke="#0c1018" stroke-width="1.3"/>')
    # the cut: a dead gap with sparks
    (ax, ay), (bx, by) = centre(*RING[CUT_AFTER]), centre(*RING[CUT_AFTER + 1])
    mx, my = (ax + bx) / 2, (ay + by) / 2
    out.append(f'<path d="M{ax},{ay} L{mx},{my - 4} M{mx},{my + 4} L{bx},{by}" stroke="#0c1018" stroke-width="5"/>'
               f'<path d="M{mx - 5},{my - 3} l4,2 l-3,2 l5,1 M{mx + 5},{my + 2} l-4,-1 l3,-2" stroke="{CUT}" '
               f'stroke-width="1.4" fill="none"/>')
    for a, b in SPARE_TAPS:
        (x1, y1), (x2, y2) = centre(*a), centre(*b)
        out.append(f'<path d="M{x1},{y1} L{(x1 + x2) / 2},{(y1 + y2) / 2}" stroke="#0c1018" stroke-width="4"/>'
                   f'<circle cx="{(x1 + x2) / 2}" cy="{(y1 + y2) / 2}" r="3" fill="{OFF}" stroke="#0c1018"/>')
    return "".join(out)


def system_svg(name, c, r, kind, powered):
    x, y = cell(c, r)
    cx, cy = x + T / 2, y + T / 2
    col = ON if powered else OFF
    switch = (f'<rect x="{x + T - 10}" y="{y + 2}" width="8" height="5" rx="2.5" fill="#0c1018"/>'
              f'<circle cx="{x + T - (4.5 if powered else 7.5)}" cy="{y + 4.5}" r="2" fill="{col}"/>')
    return (f'<g class="system" data-name="{name}" data-powered="{str(powered).lower()}">'
            f'<rect x="{x + 3}" y="{y + 3}" width="{T - 6}" height="{T - 6}" rx="4" fill="{CONSOLE}" stroke="{WALL}" '
            f'stroke-width="1.2"/>{glyph(kind, cx, cy + 1, col)}{switch}</g>')


def core_block():
    x, y = cell(2, 8)
    return (f'<g id="core-block"><rect x="{x + 2}" y="{y + 2}" width="{2 * T - 4}" height="{2 * T - 4}" rx="6" '
            f'fill="#5c6676" stroke="{WALL}" stroke-width="2"/>'
            f'<rect x="{x + 8}" y="{y + 8}" width="{2 * T - 16}" height="{2 * T - 16}" rx="4" fill="#3a4352"/>'
            f'<circle cx="{x + T}" cy="{y + T}" r="10" fill="#0c1018" stroke="{ON}" stroke-width="2" filter="url(#cglow)"/>'
            f'<circle cx="{x + T}" cy="{y + T}" r="4" fill="#e8fff2"/></g>')


def legend(style):
    x0, y = 500, 60
    rows = [
        ("Rooms run from 1x1 to 4x4 tiles and can hold several systems.", None),
        ("The bridge holds three single-tile systems: Piloting, Weapons and Shields.", None),
        ("The core sits mid-ship under the armour, and the engines at the stern.", None),
        ("Glowing line: a powered conduit on the floor. Chevrons show power flowing from the core.", "on"),
        ("Gap with sparks: a cut conduit. Power still reaches every system the other way round the ring.", "cut"),
        ("Grey console with its switch left: a system switched off (Medbay).", "off"),
        ("Capped stub: a tap reserved for a system bought later.", "tap"),
        ("Blue bar: a door. Dashed room: a spare room.", "door"),
    ]
    out = [f'<text x="{x0}" y="{y - 22}" font-size="17" font-family="sans-serif" font-weight="600" fill="#e3e8f1">'
           f'Floor layout test 1</text>',
           f'<text x="{x0}" y="{y - 4}" font-size="11.5" font-family="sans-serif" fill="#97a3b8">'
           f'SC-1 Outrider · conduit ring · {style} style</text>']
    yy = y + 22
    for text, mark in rows:
        if mark == "on":
            out.append(f'<path d="M{x0},{yy - 4} h22" stroke="#0c1018" stroke-width="5"/><path d="M{x0},{yy - 4} h22" '
                       f'stroke="{ON}" stroke-width="2" filter="url(#cglow)"/>')
        elif mark == "cut":
            out.append(f'<path d="M{x0},{yy - 4} h8 M{x0 + 14},{yy - 4} h8" stroke="#3b4556" stroke-width="5"/>'
                       f'<path d="M{x0 + 9},{yy - 7} l3,3 l-2,2 l3,1" stroke="{CUT}" stroke-width="1.4" fill="none"/>')
        elif mark == "off":
            out.append(f'<rect x="{x0 + 4}" y="{yy - 14}" width="16" height="16" rx="3" fill="{CONSOLE}"/>'
                       f'<circle cx="{x0 + 12}" cy="{yy - 6}" r="3" fill="{OFF}"/>')
        elif mark == "tap":
            out.append(f'<path d="M{x0},{yy - 4} h14" stroke="#3b4556" stroke-width="4"/><circle cx="{x0 + 15}" '
                       f'cy="{yy - 4}" r="3" fill="{OFF}" stroke="#0c1018"/>')
        elif mark == "door":
            out.append(f'<rect x="{x0 + 4}" y="{yy - 7}" width="14" height="5" fill="{DOOR}"/>')
        tx = x0 + (30 if mark else 0)
        # wrap long lines by hand at about 44 characters
        words, line, lines = text.split(), "", []
        for w in words:
            if len(line) + len(w) + 1 > (40 if mark else 46):
                lines.append(line)
                line = w
            else:
                line = (line + " " + w).strip()
        lines.append(line)
        for i, ln in enumerate(lines):
            out.append(f'<text x="{tx}" y="{yy + i * 15}" font-size="12" font-family="sans-serif" fill="#cfd6e2">{ln}</text>')
        yy += 15 * len(lines) + 12
    # the ring order
    yy += 8
    out.append(f'<text x="{x0}" y="{yy}" font-size="12.5" font-family="sans-serif" font-weight="600" fill="#e3e8f1">'
               f'Ring order</text>')
    order = ["Core", "Shields", "Weapons", "Piloting", "Sensors", "Doors", "Medbay", "Life Support", "Engines", "Core"]
    yy += 18
    for i, name in enumerate(order):
        out.append(f'<text x="{x0 + 10}" y="{yy + i * 15}" font-size="12" font-family="sans-serif" fill="#cfd6e2">'
                   f'{i + 1 if i < 9 else "↺"}  {name}</text>')
    return "".join(out)


def build(hull_svg, style):
    hull_data = base64.b64encode(open(hull_svg, "rb").read()).decode()
    parts = [f'<image href="data:image/svg+xml;base64,{hull_data}" x="0" y="0" width="460" height="740"/>']
    parts += [room_svg(*rm) for rm in ROOMS]
    parts += [door_svg(*d) for d in DOORS]
    parts.append(f'<g id="conduits">{conduits(style)}</g>')
    parts.append(core_block())
    parts += [system_svg(*s) for s in SYSTEMS]
    parts += [room_label(*rm) for rm in ROOMS]
    parts.append(legend(style))
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">
<title>SC-1 Outrider floor layout test 1</title>
<defs><filter id="cglow" filterUnits="userSpaceOnUse" x="0" y="0" width="820" height="740"><feGaussianBlur stdDeviation="1.6" result="b"/>
<feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter></defs>
<rect width="100%" height="100%" fill="#0d1220"/>
{chr(10).join(parts)}
</svg>
'''


if __name__ == "__main__":
    hull, out = sys.argv[1], sys.argv[2]
    style = sys.argv[3] if len(sys.argv) > 3 else "glow"
    open(out, "w").write(build(hull, style))
    print("saved", out)
