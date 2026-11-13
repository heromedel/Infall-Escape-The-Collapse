"""Builds the GATOS Patrol Cutter's hull (concept E, the swept cutter) around its rooms (`layout.py`).

Usage: python3 build.py OUT_DIR
Writes patrol-cutter-hull.svg (final, named parts, hidden mounts), patrol-cutter-hull-mounts.svg (review copy showing
the mount spots), stage1..5.svg (outline, fill, shade, highlight, details) and a rooms review copy.

Hull only: no floor and no weapons. Weapon mounts are invisible spots; the weapons are separate art. Facing up, light
from the upper left. A tidy doing-fine GATOS patrol cutter in white and pale grey with blue trim (race profiles,
Terrans 1): a classic spaceship, not a rocket (no nose cone, fins or engine bells).
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "tools"))
sys.path.insert(0, HERE)
from art_kit import Hull, rounded_path, shade, INK  # noqa: E402
import layout  # noqa: E402

W, H, CX = layout.W, layout.H, layout.CX

WHITE = "#eceff3"
PALE = "#cdd3db"
STEEL = "#8d96a3"
DARK = "#4a5260"
TRIM = "#2f6bd3"
GLASS = "#1d3a66"
ENGINE_GLOW = "#a8d8ff"


def sym(half, radius):
    """A closed rounded outline from its left half, top to bottom; the right half is the mirror image."""
    pts = half + [(2 * CX - x, y) for x, y in reversed(half)]
    return rounded_path(pts, radius)


def line(x1, y1, x2, y2, colour, width=1.0, opacity=1.0):
    return (f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" stroke="{colour}" '
            f'stroke-width="{width}" opacity="{opacity}" stroke-linecap="round"/>')


def seam(x1, y1, x2, y2, base):
    """A panel seam: a dark groove with a lit edge below and right of it."""
    return line(x1, y1, x2, y2, shade(base, .6), 1.1) + line(x1 + .8, y1 + .8, x2 + .8, y2 + .8, shade(base, 1.6), .8)


# the outer hull, concept E: a blunt chined bow over the bridge, sponsons swept back either side of the middle rooms,
# a squared stern round the engine room
HULL = [(145, 16), (103, 52), (88, 96), (88, 120), (48, 148), (44, 284), (86, 340), (90, 412), (112, 434)]
# pass 5 (blind check: "a utility shuttle, not a fast cutter"): a longer chined bow tapering to a blunt tip; pass 6:
# a narrower tip


def build():
    h = Hull(W, H, "GATOS Patrol Cutter")
    hull_d = sym(HULL, 9)
    seams = (seam(66, 160, 66, 276, WHITE) + seam(234, 160, 234, 276, WHITE)             # the sponsons' frames
             + seam(96, 300, 204, 300, WHITE) + seam(94, 380, 206, 380, WHITE))         # the stern's frames
    h.plate("hull", hull_d, WHITE, bevel=5, details=seams, shadow=4)
    # the sponsons (pass 1) as raised plates of their own either side of the middle rooms, out to the hull's edge
    # (pass 2), their swept leading edges in the blue trim (pass 6 tried tapering them back into swept tips past the
    # hull: the blind check read them as rocket boosters, so they stay tucked in)
    for side in (1, -1):
        sx = lambda x: CX + side * (x - CX)
        pod = rounded_path([(sx(x), y) for x, y in ((94, 122), (49, 151), (45, 282), (86, 336), (100, 308),
                                                    (100, 140))][::side], 7)
        h.plate(f"sponson-{'port' if side == 1 else 'starboard'}", pod, PALE, bevel=4,
                details=seam(sx(60), 200, sx(96), 200, PALE) + seam(sx(60), 252, sx(96), 252, PALE)
                + f'<path d="M{sx(96)},122 L{sx(48)},153 L{sx(48)},164 L{sx(96)},133 Z" fill="{TRIM}"/>', shadow=2)
    # the raised spine from the bridge to the engine room, a step pale grey, narrower than the rooms beneath
    spine = sym([(144, 46), (120, 70), (116, 120), (116, 300), (118, 384), (128, 396)], 7)
    h.plate("spine", spine, WHITE, bevel=4,
            # pass 4: panel seams across the spine (its portholes came out in pass 6: they read as stitching)
            details=seam(118, 150, 182, 150, WHITE) + seam(150, 150, 150, 238, WHITE) + seam(118, 238, 182, 238, WHITE)
            + seam(118, 318, 182, 318, WHITE) + seam(150, 318, 150, 384, WHITE) + seam(118, 352, 182, 352, WHITE)
            # pass 3: the GATOS blue double stripe across the spine under the canopy, as on the Outrider
            + f'<rect x="112" y="115" width="76" height="3.2" fill="{TRIM}"/>'
              f'<rect x="112" y="120.5" width="76" height="3.2" fill="{TRIM}"/>', shadow=2)
    # the bridge canopy at the bow
    canopy = sym([(140, 70), (124, 80), (120, 100), (130, 106)], 4)
    h.plate("cockpit", canopy, GLASS, bevel=2, outline=1.6,
            details=f'<path d="M136,76 L128,84 L127,96" fill="none" stroke="#9fd0ff" stroke-width="1.6" '
                    f'stroke-linecap="round" opacity=".8"/>')
    # the armoured housing over the AZC, on the core room's middle tile (0, 1)
    ax, ay = CX, layout.CY + layout.TILE
    r = 22                       # pass 4: as big and armoured as the Outrider's, with an inner ring and bolts
    octagon = rounded_path([(ax - r * .42, ay - r), (ax + r * .42, ay - r), (ax + r, ay - r * .42), (ax + r, ay + r * .42),
                            (ax + r * .42, ay + r), (ax - r * .42, ay + r), (ax - r, ay + r * .42), (ax - r, ay - r * .42)], 2)
    h.plate("azc", octagon, STEEL, bevel=3, outline=2,
            details=f'<circle cx="{ax}" cy="{ay}" r="12" fill="{shade(STEEL, .82)}" stroke="{INK}" stroke-width="1.2"/>'
                    f'<circle cx="{ax}" cy="{ay}" r="6" fill="{DARK}"/><circle cx="{ax}" cy="{ay}" r="3" '
                    f'fill="{ENGINE_GLOW}" opacity=".9"/>'
                    + "".join(f'<circle cx="{ax + dx * 16:.1f}" cy="{ay + dy * 16:.1f}" r="1.3" fill="{DARK}"/>'
                              for dx, dy in ((0, -1), (1, 0), (0, 1), (-1, 0))), shadow=2)
    # a small sensor dish on the spine, behind the canopy (Sensors on the bridge)
    # pass 5: the dial read as a clock
    # pass 6: no dome either (it read as a button); the Sensors are inside, as the room's console
    # the engines: three nozzles set flush into the stern (pass 5: the separate engine block read as bolted on)
    nozzles = "".join(f'<rect x="{x - 13}" y="422" width="26" height="13" rx="4" fill="{DARK}" stroke="{INK}" '
                      f'stroke-width="1.4"/><rect x="{x - 9}" y="428" width="18" height="6" rx="2.5" fill="{ENGINE_GLOW}"/>'
                      for x in (122, 150, 178))                   # pass 4, pass 6: larger nozzles
    glow = "".join(f'<ellipse cx="{x}" cy="443" rx="13" ry="8" fill="{ENGINE_GLOW}" opacity=".5" filter="url(#glow)"/>'
                   for x in (122, 150, 178))
    h.raw("engines", {2: nozzles, 5: glow})
    # six planned mounts on the outer edge, odd port, even starboard (art rules)
    for mid, x, y, slide in ((1, 122, 36, "up"), (2, 178, 36, "up"), (3, 63, 136, "left"), (4, 237, 136, "right"),
                             (5, 45, 250, "left"), (6, 255, 250, "right")):
        h.mount(f"mount-{mid}", x, y, layout.WEAPONS.get(mid, ""), slide)
    return h


if __name__ == "__main__":
    out = sys.argv[1]; os.makedirs(out, exist_ok=True)
    h = build()
    open(os.path.join(out, "patrol-cutter-hull.svg"), "w").write(h.svg())
    open(os.path.join(out, "patrol-cutter-hull-mounts.svg"), "w").write(h.svg(show_mounts=True))
    for s in range(1, 6):
        open(os.path.join(out, f"stage{s}.svg"), "w").write(h.svg(stage=s))
    rooms = h.svg(background="#141821").replace("</svg>", layout.rooms_svg() + "</svg>")
    open(os.path.join(out, "patrol-cutter-rooms.svg"), "w").write(rooms)
