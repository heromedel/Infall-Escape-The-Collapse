"""Floor layout test 2 for the SC-1 Outrider: a simpler plan on 35 px tiles.

Usage: python3 floor2.py HULL_SVG OUT_SVG

Layers, bottom to top: the hull art; the floor plate (the flat floor art under the rooms); rooms with their tile
grid and walls; doors (airlock doors open to space); the conduit ring; system consoles. Rooms with no console are
left blank.
"""
import base64
import sys

from floor import glyph

T = 35
CX = 230
COLS = 5
X0 = CX - COLS * T / 2      # 142.5: five tiles centred on the hull
Y0 = 135
W, H = 820, 740

PLATE = "#5d6573"
FLOOR = "#cfd4db"
FLOOR_LINE = "#b3bac4"
WALL = "#161b25"
DOOR = "#7fb2ff"
AIRLOCK = "#f0b54a"
CONSOLE = "#2a3446"
ON = "#5dffa8"
CUT = "#ff6a4d"


def cell(c, r):
    return X0 + c * T, Y0 + r * T


def centre(c, r):
    x, y = cell(c, r)
    return x + T / 2, y + T / 2


# Adapted from the Kestrel's real layout, turned nose up, with nearby systems merged into shared rooms:
# the nose pilot room and the room behind it become the bridge; the doors and sensors rooms become one room; the
# engines and oxygen rooms at the stern become one engine room. The wide mid-ship section keeps its airlock rooms
# on both flanks, and the core takes the centre.
# rooms: (id, col, row, width, height)
ROOMS = [
    ("bridge", 1, 0, 3, 2),
    ("sensors-doors", 1, 2, 3, 2),
    ("medbay", 0, 4, 2, 2),
    ("corridor", 2, 4, 1, 2),
    ("starboard-forward", 3, 4, 2, 2),
    ("port-airlock", 0, 6, 1, 2),
    ("core", 1, 6, 3, 3),
    ("starboard-airlock", 4, 6, 1, 2),
    ("aft-hall", 1, 9, 3, 2),
    ("engine-room", 1, 11, 3, 2),
]

# single-tile systems: (name, col, row, glyph). No console sits on a tile with a door.
SYSTEMS = [
    ("Piloting", 2, 0, "piloting"),
    ("Weapons", 3, 0, "weapons"),
    ("Shields", 3, 1, "shields"),
    ("Sensors", 1, 2, "sensors"),
    ("Doors", 1, 3, "doors"),
    ("Medbay", 0, 4, "medbay"),
    ("Life Support", 1, 12, "life"),
    ("Engines", 2, 12, "engines"),
]
CORE_TILE = (2, 7)

# doors: (col, row, side); side is the tile edge it sits on
DOORS = [
    (2, 1, "s"),             # bridge to the sensors and doors room
    (2, 3, "s"), (3, 3, "s"),  # sensors and doors room to the corridor and the starboard room
    (1, 4, "e"),             # medbay to the corridor
    (2, 5, "s"), (3, 5, "s"),  # corridor and starboard room into the core room
    (1, 6, "w"), (3, 6, "e"),  # core room to both airlock rooms
    (2, 8, "s"),             # core room to the aft hall
    (2, 10, "s"),            # aft hall to the engine room
]
AIRLOCKS = [(0, 6, "w"), (0, 7, "w"), (4, 6, "e"), (4, 7, "e")]

# the conduit ring through tile centres: core, up the starboard side to Shields, Weapons, Piloting, then down the
# port side through Sensors, Doors, Medbay, Life Support and Engines, and back up into the core
RING = [(2, 7), (3, 7), (3, 6), (3, 5), (3, 4), (3, 3), (3, 2), (3, 1), (3, 0), (2, 0), (1, 0), (1, 1), (1, 2),
        (1, 3), (1, 4), (0, 4), (0, 5), (0, 6), (0, 7), (1, 7), (1, 8), (1, 9), (1, 10), (1, 11), (1, 12), (2, 12),
        (2, 11), (2, 10), (2, 9), (2, 8), (2, 7)]
CUT_AFTER = 5   # cut between RING[5] and RING[6], inside the sensors and doors room, clear of any door


def door_tiles():
    """Every tile with a door on one of its edges, on both sides of the door."""
    tiles = set()
    step = {"n": (0, -1), "s": (0, 1), "w": (-1, 0), "e": (1, 0)}
    for c, r, side in DOORS + AIRLOCKS:
        dc, dr = step[side]
        tiles |= {(c, r), (c + dc, r + dr)}
    return tiles


def check_layout():
    """Fails if a console blocks a door, or a room leaves the grid."""
    blocked = [name for name, c, r, _ in SYSTEMS if (c, r) in door_tiles()]
    if CORE_TILE in door_tiles():
        blocked.append("Core")
    assert not blocked, f"consoles blocking doors: {blocked}"


def floor_plate():
    """The floor art: one flat plate a few pixels larger than the rooms, notched at each airlock."""
    pad = 4
    parts = []
    for _, c, r, w, h in ROOMS:
        x, y = cell(c, r)
        parts.append(f'<rect x="{x - pad}" y="{y - pad}" width="{w * T + 2 * pad}" height="{h * T + 2 * pad}" '
                     f'rx="5"/>')
    notches = []
    for c, r, side in AIRLOCKS:
        x, y = cell(c, r)
        xx = x - pad - 3 if side == "w" else x + T + pad - 3
        notches.append(f'<rect x="{xx}" y="{y + 7}" width="6" height="{T - 14}" fill="{PLATE}"/>')
    return (f'<g id="floor-plate" fill="{PLATE}">{"".join(parts)}</g>'
            f'<g id="floor-plate-shade" fill="none" stroke="#3b424e" stroke-width="1.5">'
            + "".join(p.replace("/>", ' fill="none"/>') for p in parts) + f'</g>{"".join(notches)}')


def room_svg(room_id, c, r, w, h):
    x, y = cell(c, r)
    pw, ph = w * T, h * T
    out = [f'<g class="room" id="room-{room_id}"><rect x="{x}" y="{y}" width="{pw}" height="{ph}" fill="{FLOOR}"/>']
    for i in range(1, w):
        out.append(f'<line x1="{x + i * T}" y1="{y}" x2="{x + i * T}" y2="{y + ph}" stroke="{FLOOR_LINE}"/>')
    for j in range(1, h):
        out.append(f'<line x1="{x}" y1="{y + j * T}" x2="{x + pw}" y2="{y + j * T}" stroke="{FLOOR_LINE}"/>')
    out.append(f'<rect x="{x}" y="{y}" width="{pw}" height="{ph}" fill="none" stroke="{WALL}" stroke-width="3.5"/></g>')
    return "".join(out)


def door_svg(c, r, side, colour):
    x, y = cell(c, r)
    if side in ("n", "s"):
        yy = y if side == "n" else y + T
        return f'<rect x="{x + 9}" y="{yy - 3}" width="{T - 18}" height="6" fill="{colour}" stroke="{WALL}" stroke-width="1"/>'
    xx = x if side == "w" else x + T
    return f'<rect x="{xx - 3}" y="{y + 9}" width="6" height="{T - 18}" fill="{colour}" stroke="{WALL}" stroke-width="1"/>'


def conduits():
    def path(points):
        return "M" + " L".join(f"{centre(c, r)[0]:.1f},{centre(c, r)[1]:.1f}" for c, r in points)
    out = []
    for seg in (RING[:CUT_AFTER + 1], RING[CUT_AFTER + 1:]):
        d = path(seg)
        out.append(f'<path d="{d}" fill="none" stroke="#0c1018" stroke-width="6" stroke-linejoin="round"/>'
                   f'<path d="{d}" fill="none" stroke="{ON}" stroke-width="2.2" stroke-linejoin="round" '
                   f'filter="url(#cglow)"/>'
                   f'<path d="{d}" fill="none" stroke="#e8fff2" stroke-width=".8" stroke-linejoin="round"/>')
    (ax, ay), (bx, by) = centre(*RING[CUT_AFTER]), centre(*RING[CUT_AFTER + 1])
    mx, my = (ax + bx) / 2, (ay + by) / 2
    out.append(f'<path d="M{ax},{ay} L{mx},{my + 5} M{mx},{my - 5} L{bx},{by}" stroke="#0c1018" stroke-width="6"/>'
               f'<path d="M{mx - 6},{my - 3} l5,2 l-4,2 l6,1 M{mx + 6},{my + 2} l-5,-1 l4,-2" stroke="{CUT}" '
               f'stroke-width="1.5" fill="none"/>')
    return "".join(out)


def console(name, c, r, kind):
    x, y = cell(c, r)
    return (f'<g class="system" data-name="{name}"><rect x="{x + 4}" y="{y + 4}" width="{T - 8}" height="{T - 8}" '
            f'rx="5" fill="{CONSOLE}" stroke="{WALL}" stroke-width="1.2"/>{glyph(kind, x + T / 2, y + T / 2 + 1, ON)}</g>')


def core():
    x, y = cell(*CORE_TILE)
    cx, cy = x + T / 2, y + T / 2
    return (f'<g id="core-console"><rect x="{x - 6}" y="{y - 6}" width="{T + 12}" height="{T + 12}" rx="8" '
            f'fill="#5c6676" stroke="{WALL}" stroke-width="2"/>'
            f'<rect x="{x}" y="{y}" width="{T}" height="{T}" rx="5" fill="#3a4352"/>'
            f'<circle cx="{cx}" cy="{cy}" r="10" fill="#0c1018" stroke="{ON}" stroke-width="2.2" filter="url(#cglow)"/>'
            f'<circle cx="{cx}" cy="{cy}" r="4" fill="#e8fff2"/></g>')


def legend():
    x0, y = 500, 46
    out = [f'<text x="{x0}" y="{y}" font-size="17" font-family="sans-serif" font-weight="600" fill="#e3e8f1">'
           f'Floor layout test 2</text>',
           f'<text x="{x0}" y="{y + 18}" font-size="11.5" font-family="sans-serif" fill="#97a3b8">'
           f'SC-1 Outrider · 35 px tiles · {len(ROOMS)} rooms</text>']
    yy = y + 52
    icons = [("piloting", "Piloting"), ("weapons", "Weapons"), ("shields", "Shields"), ("sensors", "Sensors"),
             ("doors", "Doors"), ("medbay", "Medbay"), ("life", "Life Support"), ("engines", "Engines")]
    for i, (kind, name) in enumerate(icons):
        col, row = i % 2, i // 2
        ix, iy = x0 + col * 150, yy + row * 30
        out.append(f'<rect x="{ix}" y="{iy - 13}" width="24" height="24" rx="4" fill="{CONSOLE}"/>'
                   f'{glyph(kind, ix + 12, iy, ON)}'
                   f'<text x="{ix + 32}" y="{iy + 4}" font-size="12" font-family="sans-serif" fill="#cfd6e2">{name}</text>')
    yy += 4 * 30 + 8
    out.append(f'<circle cx="{x0 + 12}" cy="{yy}" r="9" fill="#0c1018" stroke="{ON}" stroke-width="2" '
               f'filter="url(#cglow)"/><circle cx="{x0 + 12}" cy="{yy}" r="3.5" fill="#e8fff2"/>'
               f'<text x="{x0 + 32}" y="{yy + 4}" font-size="12" font-family="sans-serif" fill="#cfd6e2">'
               f'Core (AZC)</text>')
    yy += 34
    notes = [
        (lambda y: f'<rect x="{x0 + 5}" y="{y - 9}" width="14" height="6" fill="{DOOR}"/>', "Door between rooms."),
        (lambda y: f'<rect x="{x0 + 5}" y="{y - 9}" width="14" height="6" fill="{AIRLOCK}"/>',
         "Airlock: a door to space. Two on each mid-ship flank room."),
        (lambda y: f'<path d="M{x0},{y - 6} h24" stroke="#0c1018" stroke-width="6"/><path d="M{x0},{y - 6} h24" '
                   f'stroke="{ON}" stroke-width="2.2" filter="url(#cglow)"/>',
         "Conduit ring: one loop from the core through every system and back."),
        (lambda y: f'<path d="M{x0},{y - 6} h9 M{x0 + 15},{y - 6} h9" stroke="#0c1018" stroke-width="6"/>'
                   f'<path d="M{x0 + 10},{y - 9} l3,3 l-2,2 l3,1" stroke="{CUT}" stroke-width="1.5" fill="none"/>',
         "A cut conduit. Power still reaches every system the other way round."),
        (None, "Rooms with no console are empty."),
        (None, "Shared rooms: the bridge holds Piloting, Weapons and Shields; one room holds Sensors and Doors; "
               "the engine room holds Engines and Life Support."),
        (None, "No console sits on a door tile."),
    ]
    for mark_at, text in notes:
        mark = mark_at(yy) if mark_at else ""
        words, line, lines = text.split(), "", []
        for wd in words:
            if len(line) + len(wd) + 1 > 40:
                lines.append(line)
                line = wd
            else:
                line = (line + " " + wd).strip()
        lines.append(line)
        tx = x0 + (32 if mark else 0)
        out.append(mark)
        for i, ln in enumerate(lines):
            out.append(f'<text x="{tx}" y="{yy + i * 15 - 2}" font-size="12" font-family="sans-serif" '
                       f'fill="#cfd6e2">{ln}</text>')
        yy += 15 * len(lines) + 12
    return "".join(out)


def build(hull_svg):
    check_layout()
    hull_data = base64.b64encode(open(hull_svg, "rb").read()).decode()
    parts = [f'<image href="data:image/svg+xml;base64,{hull_data}" x="0" y="0" width="460" height="740"/>',
             floor_plate()]
    parts += [room_svg(*rm) for rm in ROOMS]
    parts += [door_svg(c, r, s, DOOR) for c, r, s in DOORS]
    parts += [door_svg(c, r, s, AIRLOCK) for c, r, s in AIRLOCKS]
    parts.append(f'<g id="conduits">{conduits()}</g>')
    parts.append(core())
    parts += [console(*s) for s in SYSTEMS]
    parts.append(legend())
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">
<title>SC-1 Outrider floor layout test 2</title>
<defs><filter id="cglow" filterUnits="userSpaceOnUse" x="0" y="0" width="{W}" height="{H}">
<feGaussianBlur stdDeviation="1.6" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge>
</filter></defs>
<rect width="100%" height="100%" fill="#0d1220"/>
{chr(10).join(parts)}
</svg>
'''


if __name__ == "__main__":
    open(sys.argv[2], "w").write(build(sys.argv[1]))
    print("saved", sys.argv[2])
