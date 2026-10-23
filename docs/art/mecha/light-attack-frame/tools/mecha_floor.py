"""Mecha Light Attack Frame floor plan: one room layout, two loadouts; self-powered systems, so no conduits.

Usage: python3 mecha_floor.py HULL_LASER_ARMED_SVG SUIT_DOCK_HULL_SVG OUT_DIR
(the shared console symbols come from docs/art/terran/outrider/floor-layout-tests/tools/floor.py)
Writes, per loadout: floor-LOADOUT.svg (rooms, doors, airlocks, consoles) and plan-LOADOUT.svg (hull + floor).
Plans show the ship intact and powered.

Every console is a tall unit with a computer panel any crew member can use, and arm and leg slots a mech plugs into
at low, mid and high-mid points, three each side of the panel. The tile in front of each unit is left clear for the
mech that integrates with it.
"""
import base64
import os
import sys

from rooms import T, W, H, X0, Y0, ROOMS, cell

GLYPHS = os.environ.get("GLYPH_DIR", os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..",
                                                  "terran", "outrider", "floor-layout-tests", "tools"))
sys.path.insert(0, GLYPHS)
from floor import glyph  # noqa: E402  (shared console symbols)

INK = "#1b2230"
PLATE = "#2a2e34"
FLOOR = "#a4aab1"
FLOOR_LINE = "#8c939b"
WALL = "#16181c"
UNIT = "#3c4148"
UNIT_TOP = "#2a2e34"
FACE = "#555c65"
SCREEN = "#14181d"
YELLOW = "#f0c02c"
POWERED = "#57e07a"
DOOR = "#c9a640"
AIRLOCK = "#ec7a1e"

# systems: (name, col, row, symbol, wall the unit stands against); the Core's cradle and the suit clamp are drawn
# separately
CONSOLES = [("Piloting", 4, 0, "piloting", "n"), ("Shields", 1, 0, "shields", "n"), ("Doors", 5, 0, "doors", "n"),
            ("Life Support", 1, 2, "life", "w"), ("Engines", 2, 3, "engines", "s")]
WEAPON_POD = ("Weapon pod", 7, 1, "weapons", "e")
EVB_CONSOLE = ("EVB Dock", 5, 1, "evb", "w")
CORE = ("Cybernetic Servicing Core", 3, 1)      # a cradle over two tiles, against the north wall
CLAMP = (7, 1)                                  # the suit's launch clamp, at the bay mouth
DOORS = [(3, 0, "w"), (1, 1, "w"), (2, 1, "s"), (2, 2, "e"), (4, 2, "s"), (4, 2, "e"), (6, 0, "s"), (4, 3, "e"),
         (6, 2, "s")]
AIRLOCKS = [(0, 2, "w"), (5, 3, "s")]
STEP = {"n": (0, -1), "s": (0, 1), "w": (-1, 0), "e": (1, 0)}


def room_of(c, r):
    for name, rc, rr, w, h in ROOMS:
        if rc <= c < rc + w and rr <= r < rr + h:
            return name
    return None


def check(loadout):
    """No console or cradle on a door tile, every door between two rooms, every airlock to space."""
    tiles = set()
    for c, r, side in DOORS + AIRLOCKS:
        dc, dr = STEP[side]
        tiles |= {(c, r), (c + dc, r + dr)}
    for c, r, side in DOORS:
        dc, dr = STEP[side]
        a, b = room_of(c, r), room_of(c + dc, r + dr)
        assert a and b and a != b, ("door not between rooms", c, r, side)
    for c, r, side in AIRLOCKS:
        dc, dr = STEP[side]
        assert room_of(c, r) and not room_of(c + dc, r + dr), ("airlock not to space", c, r, side)
    used = [(n, c, r) for n, c, r, _, _ in CONSOLES + [WEAPON_POD if loadout == "hull-laser" else EVB_CONSOLE]]
    used += [(CORE[0], CORE[1], CORE[2]), (CORE[0], CORE[1] + 1, CORE[2])]
    if loadout == "suit-dock":
        used.append(("suit clamp", *CLAMP))
    blocked = [n for n, c, r in used if (c, r) in tiles]
    assert not blocked, ("on a door tile", blocked)


def evb_glyph(x, y, colour):
    """EVB Dock: a battlesuit's helm and shoulders."""
    return (f'<rect x="{x - 3.5}" y="{y - 6.5}" width="7" height="6" rx="2" fill="{colour}"/>'
            f'<rect x="{x - 2.4}" y="{y - 4.6}" width="4.8" height="1.4" fill="{SCREEN}"/>'
            f'<path d="M{x - 7},{y + 6} V{y + 1.5} Q{x - 7},{y} {x - 5},{y} H{x + 5} Q{x + 7},{y} {x + 7},{y + 1.5} V{y + 6} Z" fill="{colour}"/>')


def symbol(kind, x, y, k):
    g = evb_glyph(x, y, POWERED) if kind == "evb" else glyph(kind, x, y, POWERED)
    return f'<g transform="translate({x},{y}) scale({k}) translate({-x},{-y})">{g}</g>'


def slot(x, y):
    return (f'<rect x="{x - 1.8}" y="{y - 1.3}" width="3.6" height="2.6" rx=".6" fill="{SCREEN}" stroke="{YELLOW}" '
            f'stroke-width=".7"/>')


def unit(name, c, r, kind, wall):
    """A tall system unit against a wall: its top, then its front face with the panel and the six slots."""
    x, y = cell(c, r)
    cx = x + T / 2
    body = (f'<rect x="{cx - 14}" y="{y + 1.5}" width="28" height="5" rx="1" fill="{UNIT_TOP}" stroke="{INK}" stroke-width="1"/>'
            f'<rect x="{cx - 14}" y="{y + 6.5}" width="28" height="13" rx="1" fill="{FACE}" stroke="{INK}" stroke-width="1"/>'
            f'<rect x="{cx - 6}" y="{y + 7.5}" width="12" height="11" rx="1" fill="{SCREEN}"/>'
            + "".join(slot(cx + s * 10, y + 9.5 + i * 3.6) for s in (-1, 1) for i in range(3))
            + symbol(kind, cx, y + 13, .62))
    rot = {"n": 0, "e": 90, "s": 180, "w": 270}[wall]
    tc = (cx, y + T / 2)
    upright = (f'<g transform="rotate({-rot} {cx} {y + 13})">{symbol(kind, cx, y + 13, .62)}</g>' if rot else "")
    if rot:   # keep the symbol upright when the unit is turned
        body = body.replace(symbol(kind, cx, y + 13, .62), upright)
    return f'<g class="system" data-name="{name}" transform="rotate({rot} {tc[0]} {tc[1]})">{body}</g>'


def core():
    """The Cybernetic Servicing Core: a mech servicing cradle, a gantry over a stand pad with two servicing arms."""
    name, c, r = CORE
    x, y = cell(c, r)
    cx = x + T
    frame = (f'<path d="M{cx - 30},{y + 2} H{cx + 30} V{y + 26} H{cx + 24} V{y + 8} H{cx - 24} V{y + 26} H{cx - 30} Z" '
             f'fill="{UNIT}" stroke="{INK}" stroke-width="1.1"/>'
             f'<rect x="{cx - 30}" y="{y + 2}" width="60" height="3" fill="url(#mf-hz)"/>')
    pad = (f'<circle cx="{cx}" cy="{y + 20}" r="10" fill="#7c838c" stroke="{INK}" stroke-width="1"/>'
           f'<circle cx="{cx}" cy="{y + 20}" r="6.5" fill="none" stroke="{YELLOW}" stroke-width="1" stroke-dasharray="3 2"/>'
           + "".join(f'<rect x="{cx + s * 4 - 2}" y="{y + 22}" width="4" height="5" rx="1" fill="{UNIT_TOP}"/>' for s in (-1, 1)))
    arms = "".join(f'<path d="M{cx + s * 24},{y + 14} L{cx + s * 17},{y + 18} L{cx + s * 12},{y + 15}" fill="none" '
                   f'stroke="{INK}" stroke-width="3.4" stroke-linejoin="round"/>'
                   f'<path d="M{cx + s * 24},{y + 14} L{cx + s * 17},{y + 18} L{cx + s * 12},{y + 15}" fill="none" '
                   f'stroke="{YELLOW}" stroke-width="1.8" stroke-linejoin="round"/>'
                   f'<circle cx="{cx + s * 17}" cy="{y + 18}" r="1.6" fill="{UNIT_TOP}"/>' for s in (-1, 1))
    screen = f'<rect x="{cx - 6}" y="{y + 6}" width="12" height="10" rx="1" fill="{SCREEN}" stroke="{INK}" stroke-width=".8"/>'
    return (f'<g class="system" data-name="{name}">{frame}{pad}{arms}{screen}{symbol("medbay", cx, y + 11, .55)}</g>')


def clamp():
    """The suit's launch clamp at the bay mouth, with the launch rail running out through the hull."""
    x, y = cell(*CLAMP)
    return (f'<g class="system" data-name="EVB launch clamp">'
            f'<rect x="{x + 3}" y="{y + 4}" width="29" height="27" rx="2" fill="none" stroke="url(#mf-hz)" stroke-width="3"/>'
            f'<line x1="{x - 24}" y1="{y + T / 2}" x2="{x + T}" y2="{y + T / 2}" stroke="{YELLOW}" stroke-width="1.6" opacity=".85"/>'
            + "".join(f'<line x1="{x - 20 + i * 8}" y1="{y + T / 2 - 3}" x2="{x - 20 + i * 8}" y2="{y + T / 2 + 3}" stroke="{YELLOW}" stroke-width="1" opacity=".7"/>' for i in range(7))
            + f'<rect x="{x + 12}" y="{y + 9}" width="11" height="17" rx="2" fill="{UNIT}" stroke="{INK}" stroke-width="1"/>'
            f'<path d="M{x + 12},{y + 13} h-3 M{x + 12},{y + 22} h-3 M{x + 23},{y + 13} h3 M{x + 23},{y + 22} h3" stroke="{YELLOW}" stroke-width="1.6"/>'
            f'<rect x="{x + T - 3}" y="{y + 3}" width="5" height="29" fill="url(#mf-hz)" stroke="{INK}" stroke-width=".8"/></g>')


def door(c, r, side, colour):
    x, y = cell(c, r)
    if side in "ns":
        yy = y if side == "n" else y + T
        return (f'<rect x="{x + 8}" y="{yy - 3}" width="{T - 16}" height="6" fill="{colour}" stroke="{INK}" stroke-width="1"/>'
                f'<line x1="{x + T / 2}" y1="{yy - 3}" x2="{x + T / 2}" y2="{yy + 3}" stroke="{INK}" stroke-width="1"/>')
    xx = x if side == "w" else x + T
    return (f'<rect x="{xx - 3}" y="{y + 8}" width="6" height="{T - 16}" fill="{colour}" stroke="{INK}" stroke-width="1"/>'
            f'<line x1="{xx - 3}" y1="{y + T / 2}" x2="{xx + 3}" y2="{y + T / 2}" stroke="{INK}" stroke-width="1"/>')


def defs():
    return (f'<defs><pattern id="mf-hz" width="5" height="5" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">'
            f'<rect width="5" height="5" fill="#202328"/><rect width="2.5" height="5" fill="{YELLOW}"/></pattern></defs>')


def floor_layer(loadout):
    check(loadout)
    out = []
    for _, c, r, w, h in ROOMS:
        x, y = cell(c, r)
        out.append(f'<rect x="{x - 4}" y="{y - 4}" width="{w * T + 8}" height="{h * T + 8}" fill="{PLATE}"/>')
    for _, c, r, w, h in ROOMS:
        x, y = cell(c, r)
        out.append(f'<rect x="{x}" y="{y}" width="{w * T}" height="{h * T}" fill="{FLOOR}"/>')
        out += [f'<line x1="{x + i * T}" y1="{y}" x2="{x + i * T}" y2="{y + h * T}" stroke="{FLOOR_LINE}"/>' for i in range(1, w)]
        out += [f'<line x1="{x}" y1="{y + j * T}" x2="{x + w * T}" y2="{y + j * T}" stroke="{FLOOR_LINE}"/>' for j in range(1, h)]
        out.append(f'<rect x="{x}" y="{y}" width="{w * T}" height="{h * T}" fill="none" stroke="{WALL}" stroke-width="3.5"/>')
    out += [door(c, r, s, DOOR) for c, r, s in DOORS] + [door(c, r, s, AIRLOCK) for c, r, s in AIRLOCKS]
    out += [unit(*k) for k in CONSOLES] + [core()]
    out += [unit(*WEAPON_POD)] if loadout == "hull-laser" else [unit(*EVB_CONSOLE), clamp()]
    return "".join(out)


def svg(body, title):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">'
            f'<title>{title}</title>{defs()}{body}</svg>\n')


if __name__ == "__main__":
    hl, sd, out = sys.argv[1:4]
    os.makedirs(out, exist_ok=True)
    for lo, hull in (("hull-laser", hl), ("suit-dock", sd)):
        floor = floor_layer(lo)
        open(os.path.join(out, f"floor-{lo}.svg"), "w").write(svg(floor, f"Mecha Light Attack Frame floor, {lo.replace('-', ' ')}"))
        data = base64.b64encode(open(hull).read().encode()).decode()
        open(os.path.join(out, f"plan-{lo}.svg"), "w").write(svg(
            f'<image href="data:image/svg+xml;base64,{data}" x="0" y="0" width="{W}" height="{H}"/>{floor}',
            f"Mecha Light Attack Frame plan, {lo.replace('-', ' ')}"))
    print("saved to", out)
