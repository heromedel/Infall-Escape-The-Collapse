"""Tentauri scout hull: compact, wide and organic, built for space; prismatic mother-of-pearl colours.

Usage: python3 tentauri.py OUT_DIR [v13]
Writes v13.svg, v13-mounts.svg and v13-stage1..5.svg.

Biomechanical: no core, no conduits, no engine bells. Propulsion is a nozzle at the tail of each flank lobe plus side
thrusters, set wide apart. The Supershield Generator shows as a pearl organ at the stern. Weapons are separate art
(tentauri_weapons.py). v13 is the final hull (tentauri-scout-hull.svg); the versions tried are in git history.
Facing up, light from the upper left.
"""
import os
import sys

from art_kit import Hull, rounded_path, INK

W, H, CX = 340, 380, 170

TEAL = "#3aa9a6"
AQUA = "#7fe0dc"
CORAL = "#f0a99f"
CORAL_WHITE = "#fbe8e1"
LAVENDER = "#b9b2e6"
DEEP = "#24485a"
GLOW = "#8ff5e6"


def mottle(clip_d, spots):
    """Soft prismatic mottling, chameleon or mother-of-pearl: blurred patches of aqua, teal, coral and lavender."""
    out = []
    for x, y, r, col, op in spots:
        out.append(f'<ellipse cx="{x}" cy="{y}" rx="{r}" ry="{r * .7:.1f}" fill="{col}" opacity="{op}" '
                   f'filter="url(#soft-mottle)"/>')
    return "".join(out)


def supershield_organ(cx, cy):
    """The Supershield Generator's emitter organ: a domed node with concentric rings and a soft glow."""
    return (f'<g id="supershield-emitter"><circle cx="{cx}" cy="{cy}" r="15" fill="{LAVENDER}" opacity=".35" '
            f'filter="url(#glow)"/><circle cx="{cx}" cy="{cy}" r="11" fill="url(#organ)" stroke="{INK}" '
            f'stroke-width="1.2"/><circle cx="{cx}" cy="{cy}" r="7" fill="none" stroke="{CORAL_WHITE}" '
            f'stroke-width="1" opacity=".8"/><circle cx="{cx - 3}" cy="{cy - 3}" r="2.2" fill="#ffffff" opacity=".85"/></g>')


def extra_defs(h):
    h.add_def("soft-mottle", '<filter id="soft-mottle" x="-50%" y="-50%" width="200%" height="200%">'
              '<feGaussianBlur stdDeviation="7"/></filter>')
    h.add_def("organ", '<radialGradient id="organ" cx=".35" cy=".35" r=".8">'
              f'<stop offset="0" stop-color="{CORAL_WHITE}"/><stop offset=".55" stop-color="{LAVENDER}"/>'
              f'<stop offset="1" stop-color="{TEAL}"/></radialGradient>')
    h.add_def("prism", '<linearGradient id="prism" x1="0" y1="0" x2="1" y2="1">'
              f'<stop offset="0" stop-color="{AQUA}" stop-opacity=".25"/>'
              f'<stop offset=".45" stop-color="{CORAL_WHITE}" stop-opacity="0"/>'
              f'<stop offset=".7" stop-color="{LAVENDER}" stop-opacity=".18"/>'
              f'<stop offset="1" stop-color="{CORAL}" stop-opacity=".22"/></linearGradient>')


# ---------- the room layout comes first; the hull is drawn around it ----------


def single_canopy(cx, y, half_w):
    """One wide canopy pane set into the nose (a single pane, so the front never reads as a pair of eyes)."""
    d = (f"M{cx - half_w},{y + 14} Q{cx - half_w * .5},{y - 2} {cx},{y - 4} Q{cx + half_w * .5},{y - 2} "
         f"{cx + half_w},{y + 14} Q{cx},{y + 8} {cx - half_w},{y + 14} Z")
    return (f'<g id="canopy"><path d="{d}" fill="{DEEP}" stroke="{INK}" stroke-width="1.3" stroke-linejoin="round"/>'
            f'<path d="M{cx - half_w * .75},{y + 9} Q{cx - half_w * .4},{y + 1} {cx - 4},{y}" fill="none" '
            f'stroke="{AQUA}" stroke-width="1.5" opacity=".8"/></g>')


# nacre tints, one per plate: the prismatic look comes from the plates differing, not from busy patterns
TINT_AQUA = "#d4f0ef"
TINT_CORAL = "#f6dcd6"
TINT_LAVENDER = "#e2def5"
TINT_TEAL = "#bfe3df"


def plate_details(d, spots):
    return (f'<path d="{d}" fill="url(#iris)" opacity=".28"/>' + mottle(d, spots)
            + f'<path d="{d}" fill="none" stroke="#ffffff" stroke-width="2.4" opacity=".4"/>')


def nozzle(x, y):
    """A short organic thrust nozzle at the stern: a ring with a glowing core, set into the rear plate."""
    return (f'<ellipse cx="{x}" cy="{y + 9}" rx="10" ry="12" fill="{GLOW}" opacity=".55" filter="url(#glow)"/>'
            f'<ellipse cx="{x}" cy="{y}" rx="11" ry="7" fill="{TINT_TEAL}" stroke="{INK}" stroke-width="1.3"/>'
            f'<ellipse cx="{x}" cy="{y + 1}" rx="7" ry="4" fill="{DEEP}"/>'
            f'<ellipse cx="{x}" cy="{y + 2}" rx="4" ry="2" fill="{GLOW}"/>')


def side_thruster(x, y, side):
    """A small lateral thruster on a flank, glowing outward."""
    gx = x + side * 8
    # toned down (2026-10-26): a soft, dim vent, so it doesn't read as a marked airlock (art rules)
    return (f'<ellipse cx="{gx - side * 2}" cy="{y}" rx="6" ry="5" fill="{GLOW}" opacity=".18" filter="url(#glow)"/>'
            f'<ellipse cx="{x}" cy="{y}" rx="3" ry="6" fill="{DEEP}" opacity=".55"/>'
            f'<ellipse cx="{x + side * 1}" cy="{y}" rx="1.3" ry="3.5" fill="{GLOW}" opacity=".45"/>')


def outrigger(title="Tentauri scout hull", spread=1.0):
    """Version 13: the flank plates sweep back into two engine lobes set wide apart, with the main thrusters at their
    tails and small lateral thrusters on the flanks; the rear module sits between them with the Supershield
    emitter. Rooms as planned: a 5x3 forward room and a 3x2 rear room."""
    h = Hull(W, H, title)
    extra_defs(h)
    h.add_def("iris", '<linearGradient id="iris" x1="0" y1="0" x2="1" y2=".7">'
              f'<stop offset="0" stop-color="{AQUA}"/><stop offset=".3" stop-color="{LAVENDER}"/>'
              f'<stop offset=".55" stop-color="{CORAL_WHITE}"/><stop offset=".8" stop-color="{CORAL}"/>'
              f'<stop offset="1" stop-color="{TEAL}"/></linearGradient>')
    k = spread
    # rear module between the engine lobes
    rear = rounded_path([(CX - 70, 206), (CX + 70, 206), (CX + 66, 282), (CX + 38, 312), (CX - 38, 312),
                         (CX - 66, 282)], [18, 18, 28, 20, 20, 28])
    h.plate("plate-rear", rear, TINT_TEAL, bevel=6, details=plate_details(rear, [(CX - 34, 258, 14, CORAL, .4)]),
            shadow=4)
    # engine glows first, under the lobes
    for side in (-1, 1):
        tx = CX + side * 118 * k
        h.raw(f"thrust-glow-{side}", {5: f'<ellipse cx="{tx}" cy="{322}" rx="12" ry="16" fill="{GLOW}" opacity=".6" '
                                         f'filter="url(#glow)"/>'})
    # flank plates sweeping back into engine lobes
    for side in (-1, 1):
        pts = [(CX + side * 64, 82), (CX + side * 116 * k, 98), (CX + side * 140 * k, 150), (CX + side * 142 * k, 236),
               (CX + side * 134 * k, 300), (CX + side * 118 * k, 314), (CX + side * 100 * k, 300),
               (CX + side * 92 * k, 250), (CX + side * 72, 214), (CX + side * 68, 120)]
        if side > 0:
            pts = pts[::-1]
        d = rounded_path(pts, [24, 26, 28, 24, 16, 12, 16, 22, 18, 22] if side < 0 else
                         [24, 26, 28, 24, 16, 12, 16, 22, 18, 22][::-1])
        nx = CX + side * 117 * k
        det = (plate_details(d, [(CX + side * 108 * k, 124, 16, TEAL, .4), (CX + side * 120 * k, 260, 12, LAVENDER, .4)])
               + f'<path d="M{CX + side * 96 * k:.1f},{240} Q{CX + side * 120 * k:.1f},{232} {CX + side * 138 * k:.1f},{244}" '
                 f'fill="none" stroke="{DEEP}" stroke-width="1.2" opacity=".45"/>')
        h.plate("plate-flank-" + ("port" if side < 0 else "starboard"), d, TINT_CORAL, bevel=6, details=det, shadow=4)
        h.raw(f"nozzle-{side}", {5: nozzle(nx, 306)})
        h.raw(f"side-thruster-{side}", {5: side_thruster(CX + side * 141 * k, 196, side)})
    # central dorsal plate and the broad front plate
    centre = rounded_path([(CX - 74, 96), (CX + 74, 96), (CX + 94, 140), (CX + 90, 222), (CX + 60, 250),
                           (CX - 60, 250), (CX - 90, 222), (CX - 94, 140)], [30, 30, 24, 24, 20, 20, 24, 24])
    cseams = (f'<path d="M{CX - 82},{178} Q{CX},{188} {CX + 82},{178}" fill="none" stroke="{DEEP}" '
              f'stroke-width="1.1" opacity=".3"/>')
    h.plate("plate-dorsal", centre, TINT_LAVENDER, bevel=7,
            details=plate_details(centre, [(CX + 40, 200, 18, AQUA, .4), (CX - 50, 140, 16, CORAL, .35)]) + cseams,
            shadow=4)
    front = rounded_path([(CX, 54), (CX + 70, 62), (CX + 112, 94), (CX + 92, 112), (CX, 104), (CX - 92, 112),
                          (CX - 112, 94), (CX - 70, 62)], [30, 26, 16, 20, 30, 20, 16, 26])
    h.plate("plate-front", front, TINT_AQUA, bevel=6, details=plate_details(front, [(CX + 50, 80, 14, LAVENDER, .4)]),
            shadow=4)
    h.raw("canopy", {5: single_canopy(CX, 66, 30)})
    h.raw("supershield", {5: supershield_organ(CX, 300)})
    # six planned mounts on the outer edge, each with a clear line forward and its slide direction (art rules):
    # 1-2 on the front plate's leading edge, 3-4 on the flank plates' outer edges (the two Defense Lasers), 5-6 on the
    # front plate's tips. Odd port, even starboard.
    h.mount("mount-1", CX - 30, 57, "", "up")
    h.mount("mount-2", CX + 30, 57, "", "up")
    h.mount("mount-3", CX - 137 * k, 150, "Tentauri Defense Laser A", "left")
    h.mount("mount-4", CX + 137 * k, 150, "Tentauri Defense Laser B", "right")
    h.mount("mount-5", CX - 110, 98, "", "left")
    h.mount("mount-6", CX + 110, 98, "", "right")
    return h


VERSIONS = {"v13": outrigger}

if __name__ == "__main__":
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    for name in sys.argv[2:] or list(VERSIONS):
        hull = VERSIONS[name]()
        open(os.path.join(out, f"{name}.svg"), "w").write(hull.svg(5))
        open(os.path.join(out, f"{name}-mounts.svg"), "w").write(hull.svg(5, show_mounts=True))
        for st in range(1, 6):
            open(os.path.join(out, f"{name}-stage{st}.svg"), "w").write(
                hull.svg(st, background="#ffffff" if st == 1 else None))
        print("built", name)
