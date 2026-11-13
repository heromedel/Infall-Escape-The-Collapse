"""Floor plans for the Terran pirate dagger: one room layout, three loadouts (Hijacker, Cutpurse, Pickpocket).

Usage: python3 floorplan.py HIJACKER_ARMED_SVG CUTPURSE_ARMED_SVG PICKPOCKET_ARMED_SVG OUT_DIR

Writes, per loadout: floor-LOADOUT.svg (rooms, doors, airlocks, consoles), conduits-LOADOUT.svg (the conduit layer
on its own, as the art rules ask) and plan-LOADOUT.svg (hull + floor + conduits), plus floorplans.svg, the three side
by side with a legend.

Drawn from the Hijacker's layout in docs/ship-suggestions.md (Ship Designs, step 8, 2026-10-27; the Cutpurse and
Pickpocket as its patches). Same hull, so one room layout; each loadout installs fewer systems and its unused rooms
stand empty and stripped. Conduits feed systems, not weapon mounts (GDD 5H): a ring from the AZC through the system
rooms, and one spur to Weapons B, the Sporewing's own system: the readable weak point. A cut shows as a red flash
(GDD 14C), only in the separate mockup.
"""
import base64
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "outrider", "floor-layout-tests", "tools"))
from floor import glyph  # noqa: E402  (shared console symbols)

sys.path.insert(0, os.path.join(HERE, "..", "..", ".."))
from palette import PIRATE_POWER_ORANGE  # noqa: E402

T = 35
CX = 240
X0 = CX - 2 * T          # four columns, c0..c3, centred on the hull
Y0 = 125
SHIP_W, SHIP_H = 480, 760

PLATE = "#4a5058"
FLOOR = "#c3c8cf"
FLOOR_STRIPPED = "#9fa5ad"   # empty rooms on the Cutpurse: bare and unlit
FLOOR_LINE = "#a7aeb8"
WALL = "#161b25"
DOOR = "#c9a24a"             # door bars in a muted pirate amber
AIRLOCK = "#e07a3a"
TERMINAL = "#d9dde3"
TERMINAL_EDGE = "#6d7581"
SCREEN = "#1c2028"
SYMBOL = PIRATE_POWER_ORANGE   # a powered, intact pirate system (palette.md); never red, which means cut off (GDD 14C)
ON = PIRATE_POWER_ORANGE   # powered conduits and core: an enemy ship shows its own power colour (palette.md)
ON_CORE = "#fff0e0"   # the hot core of a powered conduit, warm white for orange
CUT = "#ff4a3a"


def cell(c, r):
    return X0 + c * T, Y0 + r * T


def centre(c, r):
    x, y = cell(c, r)
    return x + T / 2, y + T / 2


# rooms: (id, col, row, width, height)
ROOMS = [
    ("bridge", 1, 0, 2, 2),
    ("doors-room", 1, 2, 2, 1),
    ("shields", 0, 3, 2, 2),
    ("weapons", 2, 3, 2, 2),
    ("port-flank", 0, 5, 1, 2),
    ("core", 1, 5, 2, 2),
    ("starboard-flank", 3, 5, 1, 2),
    ("medbay", 0, 7, 2, 2),
    ("teleporter", 2, 7, 2, 2),
    ("aft-hall", 0, 9, 4, 2),
    ("engine-room", 0, 11, 4, 2),
]

LOADOUTS = ("hijacker", "cutpurse", "pickpocket")
ALL = set(LOADOUTS)
# the layout's tiles (x, y) to plan cells (column, row): centre X is a point, so x runs -2, -1, 1, 2; y runs -6..6
COL = {-2: 0, -1: 1, 1: 2, 2: 3}


def tile(x, y):
    return COL[x], y + 6


# consoles: (name, tile in the layout, wall, glyph, loadouts that have it). The core is drawn on its own.
CONSOLES = [
    ("Piloting", tile(-1, -6), "n", "piloting", ALL),
    ("Sensors", tile(1, -6), "n", "sensors", {"hijacker"}),
    ("Doors", tile(-1, -4), "w", "doors", {"hijacker"}),
    ("Shields", tile(-2, -3), "w", "shields", ALL),
    ("Weapons A", tile(2, -3), "e", "weapons", {"hijacker", "pickpocket"}),
    ("Weapons B", tile(2, -1), "e", "weapons", {"hijacker", "cutpurse"}),
    ("Medbay", tile(-2, 2), "w", "medbay", {"hijacker"}),
    ("Crew Teleporter", tile(2, 2), "e", "teleporter", ALL),
    ("Engines", tile(-1, 6), "s", "engines", ALL),
    ("Life Support", tile(1, 6), "s", "life", ALL),
]
# Weapons B sits on a door tile, as the layout places it: the starboard flank's two tiles are both door tiles. It is
# against the art rule (no controlled system on a door tile), so the check names it and it is raised with Ship Designs.
FLAGGED_ON_DOOR = {"Weapons B"}
# which rooms a loadout leaves empty (none of its systems are installed)
EMPTY = {"hijacker": {"port-flank", "aft-hall"},
         "cutpurse": {"port-flank", "aft-hall", "doors-room", "medbay", "weapons"},
         "pickpocket": {"port-flank", "aft-hall", "doors-room", "medbay", "starboard-flank"}}

DOORS = [(2, 1, "s"), (2, 2, "s"), (1, 4, "e"), (0, 4, "s"), (3, 4, "s"), (1, 5, "w"), (2, 6, "e"),
         (1, 4, "s"), (1, 6, "s"), (2, 6, "s"), (1, 8, "e"), (1, 8, "s"), (2, 8, "s"), (1, 10, "s"), (2, 10, "s")]
AIRLOCKS = [(0, 9, "w"), (0, 10, "w"), (3, 9, "e"), (3, 10, "e")]
CORE_TILES = [tile(1, -1)]   # the AZC takes one tile (no system takes more), the core room's only tile free of doors

# the conduits, tile by tile as the layout gives them: (x, y, the sides it runs out of)
CONDUITS = """(-1,-6,S,E) (1,-6,S,W) (-1,-5,N,S) (1,-5,N,S) (-1,-4,N,S) (1,-4,N,S)
    (-2,-3,S,E) (-1,-3,N,W) (1,-3,N,S) (-2,-2,N,S) (1,-2,N,S,E) (2,-2,S,W)
    (-2,-1,N,S) (1,-1,N,S) (2,-1,N) (-2,0,N,S) (1,0,N,S) (-2,1,N,S)
    (1,1,N,E) (2,1,S,W) (-2,2,N,S) (2,2,N,S) (-2,3,N,S) (2,3,N,S)
    (-2,4,N,S) (2,4,N,S) (-2,5,N,E) (-1,5,S,W) (1,5,S,E) (2,5,N,W)
    (-1,6,N,E) (1,6,N,W)"""
# the spur to Weapons B (the Sporewing's system): the one intended weak point; the Pickpocket has no spur
SPUR = {frozenset((tile(1, -2), tile(2, -2))), frozenset((tile(2, -2), tile(2, -1)))}
INTENDED_WEAK = {"Weapons B"}


def conduit_edges():
    """Every conduit segment, from the layout's list: a tile and the sides it runs out of."""
    import re
    step = {"N": (0, -1), "S": (0, 1), "W": (-1, 0), "E": (1, 0)}
    edges = set()
    for x, y, sides in re.findall(r"\((-?\d+),(-?\d+),([NSEW,]+)\)", CONDUITS):
        c, r = tile(int(x), int(y))
        for side in sides.split(","):
            dc, dr = step[side]
            edges.add(frozenset(((c, r), (c + dc, r + dr))))
    return edges


def door_tiles():
    step = {"n": (0, -1), "s": (0, 1), "w": (-1, 0), "e": (1, 0)}
    tiles = set()
    for c, r, side in DOORS + AIRLOCKS:
        dc, dr = step[side]
        tiles |= {(c, r), (c + dc, r + dr)}
    return tiles


def check():
    blocked = [n for n, (c, r), _, _, _ in CONSOLES if (c, r) in door_tiles()]
    assert set(blocked) <= FLAGGED_ON_DOOR, f"consoles on door tiles: {blocked}"
    if blocked:
        print("flagged, raised with Ship Designs: console on a door tile:", blocked)
    assert len(CORE_TILES) == 1, "no system takes more than one tile"
    assert not set(CORE_TILES) & door_tiles(), "the AZC needs a free tile of its own"
    assert not set(CORE_TILES) & {t for _, t, _, _, _ in CONSOLES}, "the AZC shares a tile with a console"


def room_of(c, r):
    for rid, rc, rr, w, h in ROOMS:
        if rc <= c < rc + w and rr <= r < rr + h:
            return rid
    return None


def floor_layer(loadout):
    out = []
    pad = 4
    for _, c, r, w, h in ROOMS:
        x, y = cell(c, r)
        out.append(f'<rect x="{x - pad}" y="{y - pad}" width="{w * T + 2 * pad}" height="{h * T + 2 * pad}" rx="4" '
                   f'fill="{PLATE}"/>')
    for rid, c, r, w, h in ROOMS:
        x, y = cell(c, r)
        fill = FLOOR_STRIPPED if rid in EMPTY[loadout] - EMPTY["hijacker"] else FLOOR
        out.append(f'<rect x="{x}" y="{y}" width="{w * T}" height="{h * T}" fill="{fill}"/>')
        for i in range(1, w):
            out.append(f'<line x1="{x + i * T}" y1="{y}" x2="{x + i * T}" y2="{y + h * T}" stroke="{FLOOR_LINE}"/>')
        for j in range(1, h):
            out.append(f'<line x1="{x}" y1="{y + j * T}" x2="{x + w * T}" y2="{y + j * T}" stroke="{FLOOR_LINE}"/>')
        out.append(f'<rect x="{x}" y="{y}" width="{w * T}" height="{h * T}" fill="none" stroke="{WALL}" '
                   f'stroke-width="3.5"/>')
    for c, r, side in DOORS:
        out.append(door(c, r, side, DOOR))
    for c, r, side in AIRLOCKS:
        out.append(door(c, r, side, AIRLOCK))
    out.append(core_block())
    for name, (c, r), wall, kind, loadouts in CONSOLES:
        if loadout in loadouts:
            out.append(terminal(name, c, r, wall, kind))
    return "".join(out)


def door(c, r, side, colour):
    x, y = cell(c, r)
    if side in ("n", "s"):
        yy = y if side == "n" else y + T
        return f'<rect x="{x + 9}" y="{yy - 3}" width="{T - 18}" height="6" fill="{colour}" stroke="{WALL}" stroke-width="1"/>'
    xx = x if side == "w" else x + T
    return f'<rect x="{xx - 3}" y="{y + 9}" width="6" height="{T - 18}" fill="{colour}" stroke="{WALL}" stroke-width="1"/>'


def core_block():
    """The AZC: a dark armoured block on its one tile (a pirate's worn housing, not the Outrider's plating)."""
    x, y = cell(*CORE_TILES[0])
    cx, cy = x + T / 2, y + T / 2
    return (f'<g id="core"><rect x="{x + 4}" y="{y + 4}" width="{T - 8}" height="{T - 8}" rx="5" '
            f'fill="#3c424a" stroke="{WALL}" stroke-width="1.6"/>'
            f'<rect x="{x + 8}" y="{y + 8}" width="{T - 16}" height="{T - 16}" rx="3" fill="#262a31"/>'
            f'<circle cx="{cx}" cy="{cy}" r="7" fill="#0c1018" stroke="{ON}" stroke-width="2" filter="url(#cglow)"/>'
            f'<circle cx="{cx}" cy="{cy}" r="3" fill="{ON_CORE}"/></g>')


def terminal(name, c, r, side, kind):
    """A wall desk against its wall (as the layout gives it) with a screen; the symbol, in the ship's power colour,
    stays upright."""
    x, y = cell(c, r)
    angle = {"n": 0, "e": 90, "s": 180, "w": 270}[side]
    cx, cy = x + T / 2, y + T / 2
    desk = (f'<rect x="{x + 3}" y="{y + 2}" width="{T - 6}" height="17" rx="3" fill="{TERMINAL}" '
            f'stroke="{TERMINAL_EDGE}" stroke-width="1"/>'
            f'<rect x="{x + 6}" y="{y + 4}" width="{T - 12}" height="12" rx="2" fill="{SCREEN}"/>'
            f'<rect x="{x + 9}" y="{y + 19.5}" width="{T - 18}" height="3" rx="1" fill="#9aa1ab"/>')
    off = {"n": (0, -7.5), "e": (7.5, 0), "s": (0, 7.5), "w": (-7.5, 0)}[side]
    sx, sy = cx + off[0], cy + off[1]
    if kind == "teleporter":
        sym = (f'<circle cx="{sx}" cy="{sy}" r="5.5" fill="none" stroke="{SYMBOL}" stroke-width="1.5"/>'
               f'<circle cx="{sx}" cy="{sy}" r="2" fill="{SYMBOL}"/>')
    else:
        sym = f'<g transform="translate({sx},{sy}) scale(.78) translate({-sx},{-sy})">{glyph(kind, sx, sy, SYMBOL)}</g>'
    return f'<g class="system" data-name="{name}"><g transform="rotate({angle} {cx} {cy})">{desk}</g>{sym}</g>'


def network_edges(loadout):
    """Every conduit segment for a loadout: the layout's conduits, without the Weapons B spur on the Pickpocket."""
    edges = conduit_edges()
    return edges - SPUR if loadout == "pickpocket" else edges


def reachable(edges):
    """Everything the AZC still powers through the given segments."""
    seen, todo = set(CORE_TILES), list(CORE_TILES)
    while todo:
        n = todo.pop()
        for e in edges:
            if n in e:
                (other,) = e - {n}
                if other not in seen:
                    seen.add(other)
                    todo.append(other)
    return seen


def check_network(loadout):
    """The conduit check, run before anything is sent: every installed system's room is on the network and traces
    back to the AZC, and every single point of failure is listed (only the Weapons B spur may be one)."""
    edges = network_edges(loadout)
    live = reachable(edges)
    room_tiles = {rid: {(cc, rr) for cc in range(c, c + w) for rr in range(r, r + h)} for rid, c, r, w, h in ROOMS}
    targets = {name: room_tiles[room_of(c, r)] for name, (c, r), _, _, loadouts in CONSOLES if loadout in loadouts}
    unpowered = [t for t, tiles in targets.items() if not tiles & live]
    assert not unpowered, f"{loadout}: not connected to the AZC: {unpowered}"
    weak = {}
    for e in edges:
        after = reachable(edges - {e})
        lost = [t for t, tiles in targets.items() if not tiles & after]
        if lost:
            weak.setdefault(tuple(sorted(lost)), []).append(e)
    unexpected = [lost for lost in weak if not set(lost) <= INTENDED_WEAK]
    assert not unexpected, f"{loadout}: unintended single points of failure: {unexpected}"
    return {"systems": sorted(targets), "weak points": {", ".join(lost): len(segs) for lost, segs in weak.items()}}


def conduit_layer(loadout, cut_spur):
    """The conduit layer on its own: every segment between tile centres. With `cut_spur` (the mockup only), the spur
    to Weapons B is shown cut: a red flash at the break and the cut-off part red (GDD 14C)."""
    def wire(d, colour=ON, core=ON_CORE):
        return (f'<path d="{d}" fill="none" stroke="#0c1018" stroke-width="6" stroke-linejoin="round" '
                f'stroke-linecap="round"/><path d="{d}" fill="none" stroke="{colour}" stroke-width="2.2" '
                f'stroke-linejoin="round" stroke-linecap="round" filter="url(#cglow)"/><path d="{d}" fill="none" '
                f'stroke="{core}" stroke-width=".8" stroke-linecap="round"/>')
    out = []
    for e in sorted(network_edges(loadout), key=lambda e: sorted(e)):
        (a, b) = sorted(e)
        (ax, ay), (bx, by) = centre(*a), centre(*b)
        d = f"M{ax:.1f},{ay:.1f} L{bx:.1f},{by:.1f}"
        if cut_spur and e == frozenset((tile(2, -2), tile(2, -1))):
            mx, my = (ax + bx) / 2, (ay + by) / 2
            out.append(wire(f"M{ax:.1f},{ay:.1f} L{mx:.1f},{my - 5:.1f}"))
            out.append(wire(f"M{mx:.1f},{my + 5:.1f} L{bx:.1f},{by:.1f}", CUT, "#fff1ec"))
            out.append(f'<circle cx="{mx}" cy="{my}" r="14" fill="{CUT}" opacity=".35" filter="url(#cglow)"/>'
                       f'<circle cx="{mx}" cy="{my}" r="6" fill="{CUT}"/><circle cx="{mx}" cy="{my}" r="2.5" '
                       f'fill="#fff1ec"/>')
        else:
            out.append(wire(d))
    return "".join(out)


DEFS = ('<defs><filter id="cglow" filterUnits="userSpaceOnUse" x="0" y="0" width="1300" height="800"><feGaussianBlur stdDeviation="1.6" '
        'result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter></defs>')


def svg(body, w=SHIP_W, h=SHIP_H, title=""):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">'
            f'<title>{title}</title>{DEFS}{body}</svg>\n')


def plan(hull_svg, loadout, cut_spur):
    data = base64.b64encode(open(hull_svg, "rb").read()).decode()
    return (f'<image href="data:image/svg+xml;base64,{data}" x="0" y="0" width="{SHIP_W}" height="{SHIP_H}"/>'
            f'<g id="floor">{floor_layer(loadout)}</g><g id="conduits">{conduit_layer(loadout, cut_spur)}</g>')


def legend(x0):
    rows = [
        "Same hull and room layout for all three loadouts (Ship Designs' layout, 2026-10-27). Systems go into rooms "
        "of the player's choice (GDD 5E); rooms a loadout leaves empty stand stripped (darker, bare floor).",
        "Hijacker (bands 4-6): Piloting and Sensors share the bridge; Doors, Shields, Weapons A (Twinshot), Weapons B "
        "(Sporewing, by its launcher), Medbay and the Crew Teleporter each have a room; Engines and Life Support "
        "share the engine room.",
        "Cutpurse (bands 2-3): no Sensors, Doors, Weapons A or Medbay. Pickpocket (band 1): no Sensors, Doors, "
        "Weapons B or Medbay, and no spur.",
        "Conduits feed systems, not weapon mounts (GDD 5H): a ring from the AZC through the system rooms, and one "
        "spur to Weapons B: the readable weak point.",
        "Weapons B sits on a door tile where the layout puts it: flagged to Ship Designs (art rule: no controlled "
        "system on a door tile).",
        "Everything is shown intact and powered. A cut is shown separately, in mockup-damage-14c.",
        "Airlocks: doors to space, two on each side of the aft hall.",
    ]
    out = [f'<text x="{x0}" y="48" font-size="17" font-family="sans-serif" font-weight="600" fill="#e3e8f1">'
           f'Pirate dagger floor plans</text>']
    y = 80
    for text in rows:
        words, line, lines = text.split(), "", []
        for wd in words:
            if len(line) + len(wd) + 1 > 40:
                lines.append(line)
                line = wd
            else:
                line = (line + " " + wd).strip()
        lines.append(line)
        for i, ln in enumerate(lines):
            out.append(f'<text x="{x0}" y="{y + i * 15}" font-size="12" font-family="sans-serif" fill="#cfd6e2">'
                       f'{ln}</text>')
        y += 15 * len(lines) + 12
    return "".join(out)


if __name__ == "__main__":
    hij, cut, pick, out_dir = sys.argv[1:5]
    os.makedirs(out_dir, exist_ok=True)
    check()
    hulls = {"hijacker": hij, "cutpurse": cut, "pickpocket": pick}
    labels = {"hijacker": "Hijacker (bands 4–6)", "cutpurse": "Cutpurse (bands 2–3)", "pickpocket": "Pickpocket (band 1)"}
    for loadout in LOADOUTS:
        print("conduit check,", loadout, check_network(loadout))
        open(os.path.join(out_dir, f"floor-{loadout}.svg"), "w").write(
            svg(floor_layer(loadout), title=f"Pirate dagger floor, {loadout}"))
        open(os.path.join(out_dir, f"conduits-{loadout}.svg"), "w").write(
            svg(conduit_layer(loadout, False), title=f"Pirate dagger conduits, {loadout}"))
        open(os.path.join(out_dir, f"plan-{loadout}.svg"), "w").write(
            svg(plan(hulls[loadout], loadout, False), title=f"Pirate dagger plan, {loadout}"))
    body = []
    for i, loadout in enumerate(LOADOUTS):
        body.append(f'<g transform="translate({i * SHIP_W},0)">{plan(hulls[loadout], loadout, False)}'
                    f'<text x="{SHIP_W / 2}" y="22" font-size="14" font-family="sans-serif" fill="#e3e8f1" '
                    f'text-anchor="middle">{labels[loadout]}</text></g>')
    body.append(legend(3 * SHIP_W + 10))
    open(os.path.join(out_dir, "floorplans.svg"), "w").write(
        svg('<rect width="100%" height="100%" fill="#0d1220"/>' + "".join(body), 3 * SHIP_W + 300, SHIP_H,
            "Pirate dagger floor plans"))
    # a separate mockup, clearly labelled, of damage (GDD 14C): not part of the floor plans
    demo = (f'<rect width="100%" height="100%" fill="#0d1220"/>{plan(hij, "hijacker", True)}'
            f'<rect x="0" y="0" width="{SHIP_W}" height="30" fill="#0d1220" opacity=".85"/>'
            f'<text x="{SHIP_W / 2}" y="21" font-size="14" font-family="sans-serif" fill="#ff8a7a" '
            f'text-anchor="middle">MOCKUP, not the floor plan: Weapons B spur cut (GDD 14C)</text>')
    open(os.path.join(out_dir, "mockup-damage-14c.svg"), "w").write(
        svg(demo, title="Mockup: Weapons B spur cut (GDD 14C)"))
    print("saved floor plans to", out_dir)
