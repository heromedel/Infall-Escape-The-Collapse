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


# pass 3 (heromedel: the wings should merge with the centre so it reads as one whole ship, not a column): one hull
# outline for the body and both wings, a smooth fillet where they meet. Its left half, top to bottom: the chisel bow,
# the wing root, the forward-swept leading edge to the sharp tip, the trailing edge back in to the stern.
HULL = [(214, 12), (160, 78), (158, 104), (146, 124), (22, 114), (34, 150), (124, 300), (150, 322), (160, 344),
        (160, 404), (182, 434)]
HULL_RADII = [2, 4, 8, 10, 0, 2, 8, 8, 4, 6, 6]
# the port wing's panel inside the outline (a step darker, no outline of its own)
WING_PANEL = [(150, 128), (22, 114), (34, 150), (124, 300), (150, 318)]
# the port nacelle, tucked under the wing's trailing edge, its nozzle set into its tail
NACELLE_PORT = [(140, 220), (116, 240), (114, 384), (126, 396), (154, 396), (158, 384), (158, 230)]


def nozzle(x, y, w):
    """An engine nozzle set into a plate's tail: a dark recess with the glow inside it."""
    return (f'<rect x="{x - w / 2}" y="{y}" width="{w}" height="10" rx="3" fill="#24211e"/>'
            f'<rect x="{x - w / 2 + 3}" y="{y + 3}" width="{w - 6}" height="5" rx="2.5" fill="{ENGINE_GLOW}"/>')


def build(edge=None):
    """The hull. `edge` maps a column to the y of the hull's top edge there (from `top_edge`), for the mounts."""
    edge = edge or {}
    h = Hull(W, H, "GATOS Patrol Cutter")
    # the nacelles first, under the wings, each with its nozzle set into its tail (pass 3: not a loose port below it)
    for name, half in (("nacelle-port", NACELLE_PORT), ("nacelle-starboard", mirror(NACELLE_PORT))):
        x = sum(p[0] for p in half) / len(half)
        h.plate(name, rounded_path(half, 4), DARK, bevel=3, shadow=3,
                details=seam(x - 14, 330, x + 14, 330, DARK) + nozzle(x, 383, 30))
    # the hull: body and wings as one plate; the wings a step darker (no panel line along their roots: it traced the
    # old column again), a rust-ochre band raked along each leading edge, the body's seams, soft scorching aft, the stern nozzles set in
    wings = ""
    for port in (True, False):
        s = 1 if port else -1
        sx = lambda x: CX + s * (x - CX)
        pts = " L".join(f"{sx(x)},{y}" for x, y in WING_PANEL)
        wings += (f'<path d="M{pts} Z" fill="{shade(WING, .92)}" opacity=".55"/>'
                  + f'<path d="M{sx(28)},124 L{sx(140)},140 L{sx(140)},150 L{sx(36)},140 Z" fill="{RUST}" opacity=".85"/>'
                  + seam(sx(60), 164, sx(140), 182, WING) + seam(sx(84), 204, sx(142), 220, WING))
    details = (wings + seam(162, 150, 278, 150, PLATE) + seam(160, 300, 280, 300, PLATE) + seam(160, 370, 280, 370, PLATE)
               + scorch(220, 424, 40, 8) + nozzle(206, 423, 18) + nozzle(234, 423, 18))
    h.plate("hull", sym(HULL, HULL_RADII), PLATE, bevel=5, shadow=4, details=details)
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
    # the engines' glow, behind the nozzles set into the nacelles and the stern
    h.raw("engines", {5: "".join(f'<ellipse cx="{x}" cy="{y}" rx="{w}" ry="9" fill="{ENGINE_GLOW}" opacity=".5" '
                                 f'filter="url(#glow)"/>' for x, y, w in ((136, 400, 17), (304, 400, 17),
                                                                          (206, 438, 10), (234, 438, 10)))})
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
