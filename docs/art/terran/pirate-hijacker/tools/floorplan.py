"""Floor plans for the Terran pirate dagger: one room layout, two loadouts (Hijacker and Cutpurse).

Usage: python3 floorplan.py HIJACKER_ARMED_SVG CUTPURSE_ARMED_SVG OUT_DIR

Writes, per loadout: floor-LOADOUT.svg (rooms, doors, airlocks, consoles), conduits-LOADOUT.svg (the conduit layer
on its own, as the art rules ask) and plan-LOADOUT.svg (hull + floor + conduits), plus floorplans.svg, the two side
by side with a legend.

Same hull, so one room layout. Systems go into rooms of the player's choice (GDD 5E): the Cutpurse simply has fewer
installed, and its unused rooms stand empty and stripped. Conduits: a plain ring from the AZC through the system
rooms, plus one spur out to the Sporewing hardpoint, the readable weak point. A cut shows as a red flash (GDD 14C).
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
ON = "#5dffa8"
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

# consoles: (name, col, row, glyph, loadouts that have it). The core is drawn on its own.
CONSOLES = [
    ("Piloting", 1, 0, "piloting", {"hijacker", "cutpurse"}),
    ("Sensors", 2, 0, "sensors", {"hijacker"}),
    ("Doors", 1, 2, "doors", {"hijacker"}),
    ("Shields", 0, 3, "shields", {"hijacker", "cutpurse"}),
    ("Weapons", 3, 3, "weapons", {"hijacker", "cutpurse"}),
    ("Medbay", 0, 8, "medbay", {"hijacker"}),
    ("Crew Teleporter", 3, 8, "teleporter", {"hijacker", "cutpurse"}),
    ("Engines", 1, 12, "engines", {"hijacker", "cutpurse"}),
    ("Life Support", 2, 12, "life", {"hijacker", "cutpurse"}),
]
# which rooms a loadout leaves empty (the room's only systems are not installed)
EMPTY = {"hijacker": {"port-flank", "starboard-flank", "aft-hall"},
         "cutpurse": {"port-flank", "starboard-flank", "aft-hall", "doors-room", "medbay"}}

DOORS = [(2, 1, "s"), (2, 2, "s"), (1, 4, "e"), (0, 4, "s"), (3, 4, "s"), (1, 5, "w"), (2, 6, "e"),
         (1, 4, "s"), (1, 6, "s"), (2, 6, "s"), (1, 8, "e"), (1, 8, "s"), (2, 8, "s"), (1, 10, "s"), (2, 10, "s")]
AIRLOCKS = [(0, 9, "w"), (0, 10, "w"), (3, 9, "e"), (3, 10, "e")]
CORE_TILES = [(1, 5), (2, 5), (1, 6), (2, 6)]

# the ring: out of the core's top, up the starboard side to the bridge, down the port side to the engine room,
# then up the starboard side and back into the core
RING = [(2, 5), (2, 4), (2, 3), (2, 2), (2, 1), (2, 0), (1, 0), (1, 1), (1, 2), (1, 3), (0, 3), (0, 4), (0, 5),
        (0, 6), (0, 7), (0, 8), (0, 9), (0, 10), (0, 11), (1, 11), (1, 12), (2, 12), (2, 11), (3, 11), (3, 10),
        (3, 9), (3, 8), (3, 7), (3, 6), (2, 6)]
# weapon hardpoints and their conduit feeds. Each feed is a run of tiles from the network out to the hull wall,
# then on to the hardpoint. The Sporewing, a crude refit of stolen tech, has one spur: the readable weak point. The
# Twinshot, Terran-built, is fed twice: a run from the weapons room and a tap off the ring, so no single cut drops it.
HARDPOINTS = {
    "Sporewing": {"at": (345.2, 296), "loadouts": {"hijacker", "cutpurse"}, "feeds": [[(2, 4), (3, 4)]],
                  "intended_weak_point": True},
    "Twinshot": {"at": (134.8, 296), "loadouts": {"hijacker"}, "feeds": [[(2, 4), (1, 4), (0, 4)], [(0, 3)]],
                 "intended_weak_point": False},
}


def door_tiles():
    step = {"n": (0, -1), "s": (0, 1), "w": (-1, 0), "e": (1, 0)}
    tiles = set()
    for c, r, side in DOORS + AIRLOCKS:
        dc, dr = step[side]
        tiles |= {(c, r), (c + dc, r + dr)}
    return tiles


def check():
    blocked = [n for n, c, r, _, _ in CONSOLES if (c, r) in door_tiles()]
    assert not blocked, f"consoles on door tiles: {blocked}"


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
        fill = FLOOR_STRIPPED if (loadout == "cutpurse" and rid in EMPTY["cutpurse"] - EMPTY["hijacker"]) else FLOOR
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
    for name, c, r, kind, loadouts in CONSOLES:
        if loadout in loadouts:
            out.append(terminal(name, c, r, kind))
    return "".join(out)


def door(c, r, side, colour):
    x, y = cell(c, r)
    if side in ("n", "s"):
        yy = y if side == "n" else y + T
        return f'<rect x="{x + 9}" y="{yy - 3}" width="{T - 18}" height="6" fill="{colour}" stroke="{WALL}" stroke-width="1"/>'
    xx = x if side == "w" else x + T
    return f'<rect x="{xx - 3}" y="{y + 9}" width="6" height="{T - 18}" fill="{colour}" stroke="{WALL}" stroke-width="1"/>'


def core_block():
    """The AZC: a dark armoured block centred in the core room (a pirate's worn housing, not the Outrider's plating)."""
    x, y = cell(1, 5)
    cx, cy = x + T, y + T
    return (f'<g id="core"><rect x="{x + 8}" y="{y + 8}" width="{2 * T - 16}" height="{2 * T - 16}" rx="7" '
            f'fill="#3c424a" stroke="{WALL}" stroke-width="2"/>'
            f'<rect x="{x + 15}" y="{y + 15}" width="{2 * T - 30}" height="{2 * T - 30}" rx="4" fill="#262a31"/>'
            f'<circle cx="{cx}" cy="{cy}" r="10" fill="#0c1018" stroke="{ON}" stroke-width="2.2" filter="url(#cglow)"/>'
            f'<circle cx="{cx}" cy="{cy}" r="4" fill="#e8fff2"/></g>')


def wall_side(c, r):
    here = room_of(c, r)
    step = {"n": (0, -1), "w": (-1, 0), "e": (1, 0), "s": (0, 1)}
    for side in ("n", "w", "e", "s"):
        dc, dr = step[side]
        if room_of(c + dc, r + dr) != here:
            return side
    return "n"


def terminal(name, c, r, kind):
    """A wall desk with a screen; the symbol, in the ship's accent colour, stays upright."""
    x, y = cell(c, r)
    side = wall_side(c, r)
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
    """Every conduit segment for a loadout: the ring, plus each fitted hardpoint's feeds."""
    edges = set()
    for a, b in zip(RING, RING[1:] + RING[:1]):
        edges.add(frozenset((a, b)))
    for name, hp in HARDPOINTS.items():
        if loadout not in hp["loadouts"]:
            continue
        for feed in hp["feeds"]:
            path = feed + [("hardpoint", name)]
            for a, b in zip(path, path[1:]):
                edges.add(frozenset((a, b)))
    return edges


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
    """The conduit check, run before anything is sent: every installed system's room is on the network, every
    fitted hardpoint has a run, each traces back to the AZC, and every single point of failure is listed."""
    edges = network_edges(loadout)
    live = reachable(edges)
    room_tiles = {rid: {(cc, rr) for cc in range(c, c + w) for rr in range(r, r + h)} for rid, c, r, w, h in ROOMS}
    targets = {}
    for name, c, r, _, loadouts in CONSOLES:
        if loadout in loadouts:
            targets[name] = room_tiles[room_of(c, r)]
    for name, hp in HARDPOINTS.items():
        if loadout in hp["loadouts"]:
            targets[f"{name} hardpoint"] = {("hardpoint", name)}
    unpowered = [t for t, tiles in targets.items() if not tiles & live]
    assert not unpowered, f"{loadout}: not connected to the AZC: {unpowered}"
    weak = {}
    for e in edges:
        after = reachable(edges - {e})
        lost = [t for t, tiles in targets.items() if not tiles & after]
        if lost:
            weak.setdefault(tuple(sorted(lost)), []).append(e)
    intended = {f"{n} hardpoint" for n, hp in HARDPOINTS.items() if hp["intended_weak_point"]}
    unexpected = [lost for lost in weak if not set(lost) <= intended]
    assert not unexpected, f"{loadout}: unintended single points of failure: {unexpected}"
    return {"systems": sorted(t for t in targets if "hardpoint" not in t),
            "hardpoints": sorted(t for t in targets if "hardpoint" in t),
            "weak points": {", ".join(lost): len(segs) for lost, segs in weak.items()}}


def conduit_layer(loadout, cut_spur):
    """The conduit layer on its own: the ring, and the feeds to each fitted weapon hardpoint."""
    def wire(d):
        return (f'<path d="{d}" fill="none" stroke="#0c1018" stroke-width="6" stroke-linejoin="round" '
                f'stroke-linecap="round"/><path d="{d}" fill="none" stroke="{ON}" stroke-width="2.2" '
                f'stroke-linejoin="round" filter="url(#cglow)"/><path d="{d}" fill="none" stroke="#e8fff2" '
                f'stroke-width=".8" stroke-linejoin="round"/>')
    ring = "M" + " L".join(f"{centre(c, r)[0]:.1f},{centre(c, r)[1]:.1f}" for c, r in RING) + " Z"
    out = [wire(ring)]
    for name, hp in HARDPOINTS.items():
        if loadout not in hp["loadouts"]:
            continue
        tx, ty = hp["at"]
        side = 1 if tx > CX else -1
        for feed in hp["feeds"]:
            pts = [centre(*t) for t in feed]
            lx, ly = pts[-1]
            # out through the hull wall, then into the hardpoint
            pts += [(tx - side * 6, ly), (tx, ty)]
            if cut_spur and hp["intended_weak_point"]:
                # GDD 14C: a broken conduit flashes red, and the cut-off part may turn red too
                mx = (lx + tx) / 2
                head = pts[:-2] + [(mx - side * 6, ly)]
                out.append(wire("M" + " L".join(f"{x:.1f},{y:.1f}" for x, y in head)))
                tail = f"M{mx + side * 6},{ly} L{tx - side * 6},{ly} L{tx},{ty}"
                out.append(f'<path d="{tail}" fill="none" stroke="#0c1018" stroke-width="6"/>'
                           f'<path d="{tail}" fill="none" stroke="{CUT}" stroke-width="2" opacity=".8"/>'
                           f'<circle cx="{mx}" cy="{ly}" r="14" fill="{CUT}" opacity=".35" filter="url(#cglow)"/>'
                           f'<circle cx="{mx}" cy="{ly}" r="6" fill="{CUT}"/><circle cx="{mx}" cy="{ly}" r="2.5" '
                           f'fill="#fff1ec"/><circle cx="{tx}" cy="{ty}" r="9" fill="none" stroke="{CUT}" '
                           f'stroke-width="2"/>')
            else:
                out.append(wire("M" + " L".join(f"{x:.1f},{y:.1f}" for x, y in pts)))
        if not (cut_spur and hp["intended_weak_point"]):
            out.append(f'<circle cx="{tx}" cy="{ty}" r="4" fill="#0c1018"/><circle cx="{tx}" cy="{ty}" r="2.2" '
                       f'fill="{ON}"/>')
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
        "Same hull and room layout for both loadouts. Systems go into rooms of the player's choice (GDD 5E): the "
        "Cutpurse has fewer installed, so its Doors and Medbay rooms stand empty and stripped (darker, bare floor).",
        "Hijacker: Piloting and Sensors share the bridge; Doors, Shields, Weapons, Medbay and the Crew Teleporter "
        "each have a room; Engines and Life Support share the engine room.",
        "Cutpurse: Piloting, Shields, Weapons, Crew Teleporter, Engines and Life Support.",
        "Conduits: a plain ring from the AZC through the system rooms. The Twinshot hardpoint is fed twice (a run "
        "from the weapons room and a tap off the ring). The Sporewing has one spur: the readable weak point.",
        "Everything is shown intact and powered. A cut is shown separately, in mockup-damage-14c.",
        "Airlocks: doors to space, two on each side of the aft hall. No console sits on a door tile.",
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
    hij, cut, out_dir = sys.argv[1:4]
    os.makedirs(out_dir, exist_ok=True)
    check()
    for loadout in ("hijacker", "cutpurse"):
        print("conduit check,", loadout, check_network(loadout))
    for loadout, hull, cut_spur in (("hijacker", hij, False), ("cutpurse", cut, False)):
        open(os.path.join(out_dir, f"floor-{loadout}.svg"), "w").write(
            svg(floor_layer(loadout), title=f"Pirate dagger floor, {loadout}"))
        open(os.path.join(out_dir, f"conduits-{loadout}.svg"), "w").write(
            svg(conduit_layer(loadout, False), title=f"Pirate dagger conduits, {loadout}"))
        open(os.path.join(out_dir, f"plan-{loadout}.svg"), "w").write(
            svg(plan(hull, loadout, cut_spur), title=f"Pirate dagger plan, {loadout}"))
    body = []
    for i, (loadout, hull, cut_spur, label) in enumerate((("hijacker", hij, False, "Hijacker (bands 4–6)"),
                                                          ("cutpurse", cut, False, "Cutpurse (bands 1–3)"))):
        body.append(f'<g transform="translate({i * SHIP_W},0)">{plan(hull, loadout, cut_spur)}'
                    f'<text x="{SHIP_W / 2}" y="22" font-size="14" font-family="sans-serif" fill="#e3e8f1" '
                    f'text-anchor="middle">{label}</text></g>')
    body.append(legend(2 * SHIP_W + 10))
    open(os.path.join(out_dir, "floorplans.svg"), "w").write(
        svg('<rect width="100%" height="100%" fill="#0d1220"/>' + "".join(body), 2 * SHIP_W + 300, SHIP_H,
            "Pirate dagger floor plans"))
    # a separate mockup, clearly labelled, of damage (GDD 14C): not part of the floor plans
    demo = (f'<rect width="100%" height="100%" fill="#0d1220"/>{plan(hij, "hijacker", True)}'
            f'<rect x="0" y="0" width="{SHIP_W}" height="30" fill="#0d1220" opacity=".85"/>'
            f'<text x="{SHIP_W / 2}" y="21" font-size="14" font-family="sans-serif" fill="#ff8a7a" '
            f'text-anchor="middle">MOCKUP, not the floor plan: Sporewing spur cut (GDD 14C)</text>')
    open(os.path.join(out_dir, "mockup-damage-14c.svg"), "w").write(
        svg(demo, title="Mockup: Sporewing spur cut (GDD 14C)"))
    print("saved floor plans to", out_dir)
