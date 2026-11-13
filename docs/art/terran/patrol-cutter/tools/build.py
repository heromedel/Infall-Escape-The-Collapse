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
sys.path.insert(0, os.path.join(HERE, "..", "..", ".."))           # docs/art, for palette.py
sys.path.insert(0, HERE)
from art_kit import Hull, rounded_path, shade, INK  # noqa: E402
import layout  # noqa: E402
import palette  # noqa: E402

W, H, CX, CY = layout.W, layout.H, layout.CX, layout.CY

# pass 4 (heromedel, 2026-11-13): the Pirate Hijacker's gunmetal greys (its tools/pirate.py), a little more metallic
PLATE = "#4b5159"          # the main hull plates (pass 5: a tad darker than the pirate's #545b65)
WING = "#3b4047"           # the wings shade toward this, a step darker
DARK = "#2b3037"           # nacelles and armour
STEEL = "#7c838d"
GLASS = "#1e2a3a"
GLINT = "#e2b36c"
ENGINE_GLOW = "#bfe6ff"
STRIPE = palette.POWER_GREEN      # a player ship; pirate power orange on a non-player one


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
HULL = [(214, 12), (160, 78), (158, 104), (146, 124), (22, 114), (34, 150), (124, 300), (148, 324), (158, 352),
        (162, 404), (174, 428), (196, 446), (210, 452)]
# pass 7 (heromedel: the back end tapering down more stylishly): from just behind the engine room the stern curves in
# to a narrow tail, and the wings' trailing edges sweep into it on softer fillets
HULL_RADII = [2, 4, 8, 10, 0, 2, 14, 14, 10, 14, 16, 10, 4]
# the port nacelle, tucked under the wing's trailing edge, its nozzle set into its tail
NACELLE_PORT = [(140, 220), (116, 240), (114, 352), (120, 382), (134, 398), (150, 394), (158, 370), (158, 230)]
# (pass 7: its tail tapered too, to match the stern)


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
                details=seam(x - 14, 330, x + 14, 330, DARK) + nozzle(x - 1, 382, 22))
    # the hull: body and wings as one plate. Pass 4: the wings shade into the body on a smooth gradient, darker toward
    # the tips (a hard tone edge traced the old column); a metallic sheen and a pale rim, as on the Pirate Hijacker.
    # The stripe raked along each wing's leading edge is in the ship's power colour: power green on a player ship,
    # pirate power orange on a non-player one (palette.md).
    h.add_def("wing-blend", f'<linearGradient id="wing-blend" x1="0" y1="0" x2="{W}" y2="0" gradientUnits="userSpaceOnUse">'
                            f'<stop offset="0" stop-color="{WING}" stop-opacity=".95"/>'
                            f'<stop offset=".34" stop-color="{WING}" stop-opacity="0"/>'
                            f'<stop offset=".66" stop-color="{WING}" stop-opacity="0"/>'
                            f'<stop offset="1" stop-color="{WING}" stop-opacity=".95"/></linearGradient>')
    h.add_def("sheen", '<linearGradient id="sheen" x1="0" y1="0" x2="1" y2="1">'
                       '<stop offset="0" stop-color="#ffffff" stop-opacity=".22"/>'
                       '<stop offset=".45" stop-color="#ffffff" stop-opacity="0"/>'
                       '<stop offset=".55" stop-color="#dfe6ee" stop-opacity=".12"/>'
                       '<stop offset=".7" stop-color="#000000" stop-opacity="0"/>'
                       '<stop offset="1" stop-color="#000000" stop-opacity=".3"/></linearGradient>')
    hull_d = sym(HULL, HULL_RADII)
    stripes = ""
    for port in (True, False):
        s = 1 if port else -1
        sx = lambda x: CX + s * (x - CX)
        stripes += (f'<path d="M{sx(28)},124 L{sx(140)},140 L{sx(140)},146 L{sx(34)},134 Z" fill="{STRIPE}"/>'
                    + seam(sx(60), 164, sx(140), 182, PLATE) + seam(sx(84), 204, sx(142), 220, PLATE))
    details = (f'<path d="{hull_d}" fill="url(#wing-blend)"/><path d="{hull_d}" fill="url(#sheen)"/>'
               + stripes + seam(162, 150, 278, 150, PLATE) + seam(160, 300, 280, 300, PLATE)
               + seam(160, 370, 280, 370, PLATE) + scorch(220, 440, 26, 7) + nozzle(211, 440, 14) + nozzle(229, 440, 14)
               + f'<path d="{hull_d}" fill="none" stroke="#b4bcc6" stroke-width="3" opacity=".35"/>'
               + f'<path d="{hull_d}" fill="none" stroke="#eef2f6" stroke-width=".9" opacity=".3"/>')
    h.plate("hull", hull_d, PLATE, bevel=5, shadow=4, details=details)
    # pass 5 (heromedel: a small cockpit, set apart from the wings); pass 6 (heromedel: sleekly down from the wings,
    # not so harsh): the cockpit as a raised teardrop fairing on the bow, tapering back down the spine between the wing
    # roots, with a thin outline, a gentle bevel and only a hint of shadow
    nose = sym([(214, 18), (174, 68), (171, 102), (178, 140), (192, 184), (206, 212), (216, 224)],
               [2, 6, 14, 18, 18, 12, 8])
    h.plate("cockpit-module", nose, PLATE, bevel=3, outline=1.1, shadow=1.2,
            details=f'<path d="{nose}" fill="url(#sheen)"/>')
    # the canopy: a narrow wedge of dark glass set into the cockpit module
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
                            f'<rect x="{ax - 20}" y="{ay - 11 + i * 14}" width="40" height="1.6" rx=".8" fill="{STEEL}" '
                            f'opacity=".55"/>' for i in range(2)))
    # the engines' glow, behind the nozzles set into the nacelles and the stern
    h.raw("engines", {5: "".join(f'<ellipse cx="{x}" cy="{y}" rx="{w}" ry="9" fill="{ENGINE_GLOW}" opacity=".5" '
                                 f'filter="url(#glow)"/>' for x, y, w in ((135, 398, 13), (305, 398, 13),
                                                                          (211, 455, 8), (229, 455, 8)))})
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
