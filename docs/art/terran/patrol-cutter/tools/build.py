"""Builds the GATOS Patrol Cutter's hull around its rooms (`layout.py`): round 2, concept W2.

heromedel (2026-11-13) on round 1 (a clean white shuttle, now in git history): the rooms already make it nearly
rocket-shaped; the GATOS are a loose alliance of mercenaries, not a clean white Federation; go with a merc ship, wings
or nacelles, a sharp look for a "cutter". So: forward-swept blade wings that break up the vertical stack of rooms, a
wedge prow like a blade, engine nacelles tucked against the body under the wings, in worn, warm mercenary colours
(grey-olive plates, faded rust-ochre markings, a couple of replaced panels, a little scorching; nothing drips).

Usage: python3 build.py OUT_DIR
Writes patrol-cutter-hull.svg (final, named parts, hidden mounts), patrol-cutter-hull-mounts.svg (review copy showing
the mount spots), stage1..5.svg (outline, fill, shade, highlight, details) and a rooms review copy.

Hull only: no floor and no weapons. Weapon mounts are invisible spots; the weapons are separate art. Facing up, light
from the upper left.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "tools"))
sys.path.insert(0, HERE)
from art_kit import Hull, rounded_path, shade, INK  # noqa: E402
import layout  # noqa: E402

W, H, CX, CY = layout.W, layout.H, layout.CX, layout.CY

PLATE = "#7a7266"          # the main hull plates: warm grey-olive, sun-faded
WING = "#6d6a61"
DARK = "#4c4842"           # nacelles, the prow blade, armour
STEEL = "#8b8d8c"
RUST = "#a85a2e"           # faded rust-ochre markings
PATCH_A = "#6a7062"        # replaced panels, a slightly different shade
PATCH_B = "#86776a"
GLASS = "#22302f"
GLINT = "#e2b36c"
ENGINE_GLOW = "#bfe6ff"


def sym(half, radius=0):
    """A closed outline from its left half, top to bottom; the right half is the mirror image."""
    pts = half + [(2 * CX - x, y) for x, y in reversed(half)]
    if isinstance(radius, list):                      # one radius per corner of the half, mirrored too
        radius = radius + radius[::-1]
    return rounded_path(pts, radius) if radius else "M" + " L".join(f"{x:.1f},{y:.1f}" for x, y in pts) + " Z"


def mirror(half):
    return [(2 * CX - x, y) for x, y in half]


def line(x1, y1, x2, y2, colour, width=1.0, opacity=1.0):
    return (f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" stroke="{colour}" '
            f'stroke-width="{width}" opacity="{opacity}" stroke-linecap="round"/>')


def seam(x1, y1, x2, y2, base):
    """A panel seam: a dark groove with a lit edge below and right of it."""
    return line(x1, y1, x2, y2, shade(base, .6), 1.1) + line(x1 + .8, y1 + .8, x2 + .8, y2 + .8, shade(base, 1.4), .8)


def scorch(x, y, rx, ry):
    """Soft scorching, sparing (art rules: wear as scorching, not drips)."""
    return f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="#1c1a17" opacity=".28" filter="url(#soft)"/>'


# the body round the rooms: a wedge prow over the bridge, straight flanks, a stern tapering in round the engine room
BODY = [(214, 12), (160, 78), (156, 150), (152, 300), (160, 330), (160, 404), (182, 434)]   # pass 2: a chisel bow
# the port wing, forward-swept: its root along the body's flank, its leading edge raking forward to a sharp tip
WING_PORT = [(158, 134), (122, 140), (22, 114), (34, 150), (124, 300), (154, 316)]
# the port nacelle, tucked against the body under the wing's trailing edge
# pass 2: wider and merged into the wing root (the thin stubs read as landing legs)
NACELLE_PORT = [(140, 220), (116, 240), (114, 372), (128, 384), (152, 384), (156, 372), (156, 230)]


def build(edge=None):
    """The hull. `edge` maps a column to the y of the hull's top edge there (from `top_edge`), for the mounts."""
    edge = edge or {}
    h = Hull(W, H, "GATOS Patrol Cutter")
    # the nacelles first, under the wings
    for name, half in (("nacelle-port", NACELLE_PORT), ("nacelle-starboard", mirror(NACELLE_PORT))):
        x = sum(p[0] for p in half) / len(half)
        h.plate(name, rounded_path(half, 4), DARK, bevel=3, shadow=3,
                details=seam(x - 14, 300, x + 14, 300, DARK) + seam(x - 14, 344, x + 14, 344, DARK))
    # the wings, sharp at the tips: a rust-ochre band raked along each leading edge, a replaced panel on the port wing
    for name, half, port in (("wing-port", WING_PORT, True), ("wing-starboard", mirror(WING_PORT), False)):
        s = 1 if port else -1
        sx = lambda x: CX + s * (x - CX)
        band = (f'<path d="M{sx(28)},124 L{sx(126)},156 L{sx(126)},166 L{sx(36)},140 Z" fill="{RUST}" '
                f'opacity=".85"/>')
        seams = seam(sx(60), 160, sx(126), 182, WING) + seam(sx(84), 200, sx(132), 214, WING)
        patch = ""                      # pass 2: the wing's replaced panel read as a placeholder
        h.plate(name, rounded_path(half, [3, 4, 0, 2, 4, 3]), WING, bevel=4, shadow=4,
                details=band + seams + patch)
    # the body over the rooms, with its seams, a replaced panel and soft scorching aft
    body_details = (seam(162, 150, 278, 150, PLATE) + seam(160, 222, 280, 222, PLATE) + seam(156, 300, 284, 300, PLATE)
                    + seam(158, 370, 282, 370, PLATE)
                    + f'<path d="M244,312 L276,312 L278,350 L246,350 Z" fill="{PATCH_B}" '
                      f'stroke="{shade(PATCH_B, .6)}" stroke-width="1"/>'
                    + scorch(220, 424, 40, 8))
    h.plate("hull", sym(BODY, [2, 4, 4, 6, 4, 6, 6]), PLATE, bevel=5, shadow=4, details=body_details)
    # the canopy: a narrow wedge of dark glass set into the chisel bow (pass 2: no separate prow blade, simpler)
    canopy = sym([(216, 50), (196, 78), (196, 100), (212, 106)], 2)
    h.plate("cockpit", canopy, GLASS, bevel=2, outline=1.6,
            details=f'<path d="M212,58 L201,76 L201,94" fill="none" stroke="{GLINT}" stroke-width="1.5" '
                    f'stroke-linecap="round" opacity=".7"/>')
    # the armoured housing over the AZC, on the core room's middle tile (0, 1): pass 2, a flush armoured panel across
    # the core room with two vent slits (the raised octagon read as a pasted-on turret)
    ax, ay = CX, CY + layout.TILE
    panel = rounded_path([(ax - 34, ay - 26), (ax + 34, ay - 26), (ax + 38, ay + 22), (ax - 38, ay + 22)], 4)
    h.plate("azc", panel, DARK, bevel=3, outline=1.8, shadow=1.5,
            details="".join(f'<rect x="{ax - 22}" y="{ay - 12 + i * 14}" width="44" height="5" rx="2" fill="#24221f"/>'
                            f'<rect x="{ax - 20}" y="{ay - 11 + i * 14}" width="40" height="1.6" rx=".8" fill="{RUST}" '
                            f'opacity=".55"/>' for i in range(2)))
    # the engines: a nozzle at the back of each nacelle and a smaller pair at the stern, glowing
    nozzles, glow = [], []
    for x, y, w in ((135, 386, 34), (305, 386, 34), (206, 432, 18), (234, 432, 18)):     # pass 2: chunky nozzles
        nozzles.append(f'<rect x="{x - w / 2}" y="{y - 6}" width="{w}" height="13" rx="4" fill="#2a2724" stroke="{INK}" '
                       f'stroke-width="1.6"/><rect x="{x - w / 2 + 4}" y="{y - 2}" width="{w - 8}" height="6" rx="3" '
                       f'fill="{ENGINE_GLOW}"/>')
        glow.append(f'<ellipse cx="{x}" cy="{y + 12}" rx="{w * .6}" ry="10" fill="{ENGINE_GLOW}" opacity=".55" '
                    f'filter="url(#glow)"/>')
    h.raw("engines", {2: "".join(nozzles), 5: "".join(glow)})
    # six planned mounts on the outer edge, odd port, even starboard (art rules): 1-2 on the wingtips, 3-4 on the
    # wings' leading edges by the body (the cutter's guns), 5-6 on the prow's chines. Each sits on the edge measured
    # from the rendered hull (`edge`), so it is really on it.
    for mid, x, slide in ((1, 30, "up"), (2, 410, "up"), (3, 116, "up"), (4, 324, "up"), (5, 174, "up"), (6, 266, "up")):
        h.mount(f"mount-{mid}", x, edge.get(x, 0), layout.WEAPONS.get(mid, ""), slide)
    return h


def top_edge(svg):
    """For each column, the y two pixels inside the hull's top edge, from a render of the hull."""
    import subprocess
    import tempfile
    from PIL import Image
    png = os.path.join(tempfile.mkdtemp(), "hull.png")
    open(png[:-3] + "svg", "w").write(svg)
    subprocess.run(["node", os.path.join(HERE, "..", "..", "..", "tools", "render.js"), png[:-3] + "svg", png, "1"],
                   check=True, capture_output=True)
    alpha = Image.open(png).convert("RGBA").load()
    return {x: next((y + 2 for y in range(H) if alpha[x, y][3] > 200), 0) for x in range(W)}


if __name__ == "__main__":
    out = sys.argv[1]; os.makedirs(out, exist_ok=True)
    h = build(top_edge(build().svg()))
    open(os.path.join(out, "patrol-cutter-hull.svg"), "w").write(h.svg())
    open(os.path.join(out, "patrol-cutter-hull-mounts.svg"), "w").write(h.svg(show_mounts=True))
    for s in range(1, 6):
        open(os.path.join(out, f"stage{s}.svg"), "w").write(h.svg(stage=s))
    rooms = h.svg(background="#141821").replace("</svg>", layout.rooms_svg() + "</svg>")
    open(os.path.join(out, "patrol-cutter-rooms.svg"), "w").write(rooms)
