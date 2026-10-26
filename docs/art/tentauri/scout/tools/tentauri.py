"""Tentauri scout hull: compact, wide and organic, built for space; prismatic mother-of-pearl colours.

Usage: python3 tentauri.py OUT_DIR [name ...]
Writes NAME.svg, NAME-mounts.svg and NAME-stage1..5.svg.

Biomechanical: no core, no conduits, no engine bells. Propulsion is a nozzle at the tail of each flank lobe plus side
thrusters, set wide apart. The Supershield Generator shows as a pearl organ at the stern. Weapons are separate art
(tentauri_weapons.py). v13 is the final hull (tentauri-scout-hull.svg); the others are the versions tried.
Facing up, light from the upper left.
"""
import math
import os
import sys

from art_kit import Hull, rounded_path, mirror_x, shade, INK

W, H, CX = 340, 380, 170

PEARL = "#e6edf0"
PEARL_SHADE = "#c9d6dc"
TEAL = "#3aa9a6"
AQUA = "#7fe0dc"
CORAL = "#f0a99f"
CORAL_WHITE = "#fbe8e1"
LAVENDER = "#b9b2e6"
DEEP = "#24485a"
GLOW = "#8ff5e6"


def ellipse_path(cx, cy, rx, ry, n=48, squash=None):
    """A smooth closed path around an ellipse; squash(t) can flatten parts of it."""
    pts = []
    for i in range(n):
        a = 2 * math.pi * i / n
        x, y = math.cos(a), math.sin(a)
        k = squash(a) if squash else 1.0
        pts.append((cx + rx * x * k, cy + ry * y))
    return rounded_path(pts, 6)


def mottle(clip_d, spots):
    """Soft prismatic mottling, chameleon or mother-of-pearl: blurred patches of aqua, teal, coral and lavender."""
    out = []
    for x, y, r, col, op in spots:
        out.append(f'<ellipse cx="{x}" cy="{y}" rx="{r}" ry="{r * .7:.1f}" fill="{col}" opacity="{op}" '
                   f'filter="url(#soft-mottle)"/>')
    return "".join(out)


def ribs(cx, cy, rx, ry, count, colour):
    """Faint curved bands wrapping the hull, the one tentacle-like cue: no suckers, nothing ocean."""
    out = []
    for i in range(count):
        t = (i + 1) / (count + 1)
        y = cy - ry + 2 * ry * t
        half = rx * math.sqrt(max(0.0, 1 - ((y - cy) / ry) ** 2))
        out.append(f'<path d="M{cx - half * .92:.1f},{y + 6:.1f} Q{cx},{y - 10:.1f} {cx + half * .92:.1f},{y + 6:.1f}" '
                   f'fill="none" stroke="{colour}" stroke-width="1.4" opacity=".45"/>')
    return "".join(out)


def visor(cx, y, half_w):
    """A wide curved band of dark glass along the front edge, with a prismatic glint."""
    d = (f"M{cx - half_w},{y + 10} Q{cx},{y - 12} {cx + half_w},{y + 10} "
         f"Q{cx},{y - 2} {cx - half_w},{y + 10} Z")
    glint = f"M{cx - half_w * .7},{y + 5} Q{cx - half_w * .3},{y - 5} {cx - 4},{y - 4}"
    return (f'<g id="visor"><path d="{d}" fill="{DEEP}" stroke="{INK}" stroke-width="1.3"/>'
            f'<path d="{glint}" fill="none" stroke="{AQUA}" stroke-width="1.6" opacity=".8"/></g>')


def stern_vents(cx, y, gap):
    """Organic propulsion: two soft slit vents with a teal glow (no engine bells)."""
    out = []
    for x in (cx - gap, cx + gap):
        out.append(f'<ellipse cx="{x}" cy="{y + 8}" rx="11" ry="9" fill="{GLOW}" opacity=".55" filter="url(#glow)"/>'
                   f'<path d="M{x - 11},{y} Q{x},{y + 7} {x + 11},{y} Q{x},{y + 3} {x - 11},{y} Z" fill="{DEEP}" '
                   f'stroke="{INK}" stroke-width="1.1"/><path d="M{x - 7},{y + 2} Q{x},{y + 5} {x + 7},{y + 2}" '
                   f'fill="none" stroke="{GLOW}" stroke-width="1.4"/>')
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


def lobe(h, part_id, d, cx, cy, rx, ry, spots, rib_count, colour=PEARL):
    det = (f'<path d="{d}" fill="url(#prism)"/>' + mottle(d, spots) + ribs(cx, cy, rx, ry, rib_count, TEAL)
           + f'<path d="{d}" fill="none" stroke="#ffffff" stroke-width="2.4" opacity=".35"/>')
    h.plate(part_id, d, colour, bevel=7, details=det, shadow=4)


def peanut():
    """Version 1: two fused lobes, the forward room and the rear room, wide like a slug's ship."""
    h = Hull(W, H, "Tentauri scout hull, version 1")
    extra_defs(h)
    rear = ellipse_path(CX, 268, 80, 62)
    lobe(h, "hull-rear", rear, CX, 268, 80, 62,
         [(140, 280, 20, CORAL, .45), (205, 255, 16, AQUA, .5), (170, 300, 14, LAVENDER, .4)], 2)
    front = ellipse_path(CX, 156, 112, 96, squash=lambda a: 1 - .12 * max(0, -math.sin(a)))
    lobe(h, "hull-front", front, CX, 156, 112, 96,
         [(110, 150, 26, AQUA, .45), (225, 120, 22, CORAL, .4), (180, 200, 24, TEAL, .35),
          (95, 210, 16, LAVENDER, .4), (250, 190, 14, AQUA, .4)], 3)
    h.raw("visor", {5: visor(CX, 74, 58)})
    h.raw("stern-vents", {5: stern_vents(CX, 322, 28)})
    h.raw("supershield", {5: supershield_organ(CX, 300)})
    h.mount("mount-defense-laser-a", 64, 150, "Tentauri Defense Laser A", "left")
    h.mount("mount-defense-laser-b", 276, 150, "Tentauri Defense Laser B", "right")
    return h


def teardrop():
    """Version 2: one wide teardrop, broad at the front, narrowing aft."""
    h = Hull(W, H, "Tentauri scout hull, version 2")
    extra_defs(h)
    def sq(a):
        s = math.sin(a)
        return 1 - .38 * max(0, s) ** 1.4
    d = ellipse_path(CX, 190, 118, 140, squash=sq)
    lobe(h, "hull", d, CX, 190, 118, 140,
         [(110, 150, 26, AQUA, .45), (225, 120, 22, CORAL, .4), (180, 230, 24, TEAL, .35), (150, 290, 16, LAVENDER, .4)], 4)
    h.raw("visor", {5: visor(CX, 64, 60)})
    h.raw("stern-vents", {5: stern_vents(CX, 326, 18)})
    h.raw("supershield", {5: supershield_organ(CX, 300)})
    h.mount("mount-defense-laser-a", 60, 160, "Tentauri Defense Laser A", "left")
    h.mount("mount-defense-laser-b", 280, 160, "Tentauri Defense Laser B", "right")
    return h


def crescent():
    """Version 3: a wide mantle with swept-back horns and a rear lobe."""
    h = Hull(W, H, "Tentauri scout hull, version 3")
    extra_defs(h)
    rear = ellipse_path(CX, 262, 70, 64)
    lobe(h, "hull-rear", rear, CX, 262, 70, 64, [(150, 270, 18, CORAL, .45), (195, 250, 14, AQUA, .5)], 2)
    pts = [(CX, 52), (236, 66), (296, 128), (300, 196), (262, 176), (220, 214), (CX, 222), (120, 214), (78, 176),
           (40, 196), (44, 128), (104, 66)]
    d = rounded_path(pts, [40, 30, 30, 14, 20, 20, 30, 20, 20, 14, 30, 30])
    lobe(h, "hull-front", d, CX, 140, 128, 86, [(110, 130, 24, AQUA, .45), (230, 120, 20, CORAL, .4),
                                                 (170, 190, 22, TEAL, .35)], 2)
    h.raw("visor", {5: visor(CX, 68, 56)})
    h.raw("stern-vents", {5: stern_vents(CX, 316, 24)})
    h.raw("supershield", {5: supershield_organ(CX, 292)})
    h.mount("mount-defense-laser-a", 52, 160, "Tentauri Defense Laser A", "left")
    h.mount("mount-defense-laser-b", 288, 160, "Tentauri Defense Laser B", "right")
    return h


def iridescence(d):
    """Strong prismatic bands across a plate: aqua, lavender and coral, like mother of pearl."""
    return f'<path d="{d}" fill="url(#iris)" opacity=".55"/>'


def lozenge(spec_width=240, spec_length=196, pods=True, title="Tentauri scout hull, version 4"):
    """Version 4: a broad, flat lozenge, wider than long, with a flattened front, side pods for the lasers and a
    flush rear section: a compact shuttle built for space."""
    h = Hull(W, H, title)
    extra_defs(h)
    h.add_def("iris", '<linearGradient id="iris" x1="0" y1="0" x2="1" y2=".6">'
              f'<stop offset="0" stop-color="{AQUA}"/><stop offset=".3" stop-color="{LAVENDER}"/>'
              f'<stop offset=".55" stop-color="{CORAL_WHITE}"/><stop offset=".8" stop-color="{CORAL}"/>'
              f'<stop offset="1" stop-color="{TEAL}"/></linearGradient>')
    hw, top, bottom = spec_width / 2, 92, 92 + spec_length
    if pods:
        for side in (-1, 1):
            px = CX + side * (hw - 6)
            d = ellipse_path(px, 168, 30, 50)
            det = (iridescence(d) + mottle(d, [(px, 150, 14, TEAL, .55), (px + side * 6, 190, 10, CORAL, .5)])
                   + f'<path d="{d}" fill="none" stroke="#ffffff" stroke-width="2" opacity=".35"/>')
            h.plate("pod-" + ("port" if side < 0 else "starboard"), d, PEARL_SHADE, bevel=5, details=det, shadow=3)
    # rear section, flush, slightly narrower
    rear = rounded_path([(CX - 74, bottom - 40), (CX + 74, bottom - 40), (CX + 70, bottom + 26), (CX + 40, bottom + 44),
                         (CX - 40, bottom + 44), (CX - 70, bottom + 26)], [10, 10, 26, 18, 18, 26])
    rdet = (iridescence(rear) + mottle(rear, [(CX - 34, bottom + 14, 16, CORAL, .55), (CX + 30, bottom, 14, AQUA, .55)])
            + ribs(CX, bottom + 6, 70, 34, 2, TEAL))
    h.plate("hull-rear", rear, PEARL, bevel=6, details=rdet, shadow=4)
    # main body: broad lozenge, flattened front
    pts = [(CX - 60, top), (CX + 60, top), (CX + hw - 10, top + 40), (CX + hw, top + spec_length * .55),
           (CX + hw - 26, bottom - 10), (CX + 40, bottom + 6), (CX - 40, bottom + 6), (CX - hw + 26, bottom - 10),
           (CX - hw, top + spec_length * .55), (CX - hw + 10, top + 40)]
    body = rounded_path(pts, [26, 26, 40, 40, 40, 30, 30, 40, 40, 40])
    bdet = (iridescence(body)
            + mottle(body, [(CX - 70, top + 60, 24, TEAL, .55), (CX + 62, top + 52, 20, CORAL, .55),
                            (CX + 20, top + 120, 26, AQUA, .5), (CX - 40, top + 150, 18, LAVENDER, .55),
                            (CX + 90, top + 140, 14, TEAL, .5)])
            + ribs(CX, top + spec_length / 2, hw, spec_length / 2, 3, DEEP)
            + f'<path d="{body}" fill="none" stroke="#ffffff" stroke-width="2.6" opacity=".35"/>')
    h.plate("hull", body, PEARL, bevel=8, details=bdet, shadow=5)
    h.raw("visor", {5: visor(CX, top + 8, 56)})
    h.raw("stern-vents", {5: stern_vents(CX, bottom + 46, 26)})
    h.raw("supershield", {5: supershield_organ(CX, bottom + 22)})
    mx = CX - hw - 14 if pods else CX - hw + 6
    h.mount("mount-defense-laser-a", mx, 168, "Tentauri Defense Laser A", "left")
    h.mount("mount-defense-laser-b", 2 * CX - mx, 168, "Tentauri Defense Laser B", "right")
    return h


def lozenge_narrow():
    return lozenge(212, 210, True, "Tentauri scout hull, version 5")


def lozenge_bare():
    return lozenge(250, 186, False, "Tentauri scout hull, version 6")


def swept_seams(cx, top, half_w, length, colour):
    """Flowing seams sweeping back from the nose to the flanks: a tentacle-like cue that also gives direction."""
    out = []
    for i, k in enumerate((.35, .62, .88)):
        for side in (-1, 1):
            x0 = cx + side * 10 * (i + 1)
            out.append(f'<path d="M{x0},{top + 18 + i * 6} C{cx + side * half_w * k * .6:.1f},{top + 40 + i * 18} '
                       f'{cx + side * half_w * k:.1f},{top + length * .45:.1f} {cx + side * half_w * (k + .06):.1f},'
                       f'{top + length * (.78 + i * .06):.1f}" fill="none" stroke="{colour}" stroke-width="1.3" '
                       f'opacity=".5"/>')
    return "".join(out)


def canopy(cx, y):
    """A narrow canopy set into the nose: two curved panes either side of a spine."""
    out = []
    for side in (-1, 1):
        d = (f"M{cx + side * 3},{y} Q{cx + side * 26},{y + 2} {cx + side * 34},{y + 14} "
             f"Q{cx + side * 18},{y + 16} {cx + side * 3},{y + 14} Z")
        out.append(f'<path d="{d}" fill="{DEEP}" stroke="{INK}" stroke-width="1.2" stroke-linejoin="round"/>')
    out.append(f'<path d="M{cx - 28},{y + 9} Q{cx - 16},{y + 3} {cx - 6},{y + 4}" fill="none" stroke="{AQUA}" '
               f'stroke-width="1.4" opacity=".8"/>')
    return '<g id="canopy">' + "".join(out) + "</g>"


def blister(cx, cy, length, width):
    """A weapon blister blended along the flank: a long smooth teardrop, half under the hull."""
    pts = [(cx, cy - length / 2), (cx + width / 2, cy - length * .1), (cx + width / 2 * .8, cy + length * .35),
           (cx, cy + length / 2), (cx - width / 2 * .8, cy + length * .35), (cx - width / 2, cy - length * .1)]
    return rounded_path(pts, [12, 14, 12, 10, 12, 14])


def chevron(title="Tentauri scout hull, version 7"):
    """Version 7: a broad, flat hull with a blunt chevron nose, widest mid-ship, tapering into the rear section;
    weapon blisters blended into the flanks; swept seams instead of ribs."""
    h = Hull(W, H, title)
    extra_defs(h)
    h.add_def("iris", '<linearGradient id="iris" x1="0" y1="0" x2="1" y2=".6">'
              f'<stop offset="0" stop-color="{AQUA}"/><stop offset=".3" stop-color="{LAVENDER}"/>'
              f'<stop offset=".55" stop-color="{CORAL_WHITE}"/><stop offset=".8" stop-color="{CORAL}"/>'
              f'<stop offset="1" stop-color="{TEAL}"/></linearGradient>')
    top = 70
    for side in (-1, 1):
        d = blister(CX + side * 112, 176, 112, 34)
        det = (iridescence(d) + mottle(d, [(CX + side * 112, 160, 12, TEAL, .6)])
               + f'<path d="{d}" fill="none" stroke="#ffffff" stroke-width="2" opacity=".35"/>')
        h.plate("blister-" + ("port" if side < 0 else "starboard"), d, PEARL_SHADE, bevel=5, details=det, shadow=3)
    rear = rounded_path([(CX - 66, 238), (CX + 66, 238), (CX + 62, 298), (CX + 34, 314), (CX - 34, 314),
                         (CX - 62, 298)], [10, 10, 24, 16, 16, 24])
    rdet = (iridescence(rear) + mottle(rear, [(CX - 30, 280, 15, CORAL, .55), (CX + 28, 266, 13, AQUA, .55)])
            + f'<path d="{rear}" fill="none" stroke="#ffffff" stroke-width="2" opacity=".3"/>')
    h.plate("hull-rear", rear, PEARL, bevel=6, details=rdet, shadow=4)
    pts = [(CX, top), (CX + 54, top + 14), (CX + 112, top + 62), (CX + 124, top + 112), (CX + 110, top + 168),
           (CX + 66, top + 196), (CX - 66, top + 196), (CX - 110, top + 168), (CX - 124, top + 112),
           (CX - 112, top + 62), (CX - 54, top + 14)]
    body = rounded_path(pts, [22, 30, 36, 36, 34, 26, 26, 34, 36, 36, 30])
    bdet = (iridescence(body)
            + mottle(body, [(CX - 72, top + 70, 24, TEAL, .6), (CX + 64, top + 60, 20, CORAL, .55),
                            (CX + 26, top + 130, 26, AQUA, .5), (CX - 44, top + 150, 18, LAVENDER, .6),
                            (CX + 92, top + 140, 14, TEAL, .55)])
            + swept_seams(CX, top, 118, 196, DEEP)
            + f'<path d="{body}" fill="none" stroke="#ffffff" stroke-width="2.6" opacity=".35"/>')
    h.plate("hull", body, PEARL, bevel=8, details=bdet, shadow=5)
    h.raw("canopy", {5: canopy(CX, top + 16)})
    h.raw("stern-vents", {5: stern_vents(CX, 316, 24)})
    h.raw("supershield", {5: supershield_organ(CX, 288)})
    h.mount("mount-defense-laser-a", CX - 112, 150, "Tentauri Defense Laser A", "left")
    h.mount("mount-defense-laser-b", CX + 112, 150, "Tentauri Defense Laser B", "right")
    return h


def shield_hull(title="Tentauri scout hull, version 8", front_w=124, waist=72, top=92, depth=150):
    """Version 8: a broad shield-shaped hull: a wide, gently curved front edge, sides converging aft into the rear
    section, weapon blisters at the two front corners. Large calm nacre plates and a darker spine."""
    h = Hull(W, H, title)
    extra_defs(h)
    h.add_def("iris", '<linearGradient id="iris" x1="0" y1="0" x2="1" y2=".7">'
              f'<stop offset="0" stop-color="{AQUA}"/><stop offset=".3" stop-color="{LAVENDER}"/>'
              f'<stop offset=".55" stop-color="{CORAL_WHITE}"/><stop offset=".8" stop-color="{CORAL}"/>'
              f'<stop offset="1" stop-color="{TEAL}"/></linearGradient>')
    bottom = top + depth
    # weapon blisters on the front corners
    for side in (-1, 1):
        bx = CX + side * (front_w - 4)
        d = blister(bx, top + 26, 70, 30)
        det = (iridescence(d) + mottle(d, [(bx, top + 20, 10, TEAL, .6)])
               + f'<path d="{d}" fill="none" stroke="#ffffff" stroke-width="2" opacity=".35"/>')
        h.plate("blister-" + ("port" if side < 0 else "starboard"), d, PEARL_SHADE, bevel=5, details=det, shadow=3)
    # rear section
    rear = rounded_path([(CX - waist + 6, bottom - 30), (CX + waist - 6, bottom - 30), (CX + waist - 10, bottom + 46),
                         (CX + 36, bottom + 62), (CX - 36, bottom + 62), (CX - waist + 10, bottom + 46)],
                        [8, 8, 22, 14, 14, 22])
    rdet = (iridescence(rear) + mottle(rear, [(CX - 28, bottom + 30, 14, CORAL, .55), (CX + 26, bottom + 16, 12, AQUA, .55)])
            + f'<path d="{rear}" fill="none" stroke="#ffffff" stroke-width="2" opacity=".3"/>')
    h.plate("hull-rear", rear, PEARL, bevel=6, details=rdet, shadow=4)
    # main shield-shaped body
    pts = [(CX, top - 8), (CX + front_w, top + 4), (CX + front_w + 6, top + 40), (CX + waist + 18, bottom - 6),
           (CX + waist, bottom + 10), (CX - waist, bottom + 10), (CX - waist - 18, bottom - 6),
           (CX - front_w - 6, top + 40), (CX - front_w, top + 4)]
    body = rounded_path(pts, [60, 18, 22, 30, 14, 14, 30, 22, 18])
    spine = rounded_path([(CX - 12, top), (CX + 12, top), (CX + 16, bottom + 4), (CX - 16, bottom + 4)], 6)
    inset = rounded_path([(CX - 26, top + 14), (CX - front_w + 18, top + 18), (CX - front_w + 12, top + 44),
                          (CX - waist - 2, bottom - 14), (CX - 26, bottom - 6)], [6, 14, 18, 18, 6])
    inset_r = rounded_path(mirror_x([(CX - 26, top + 14), (CX - front_w + 18, top + 18), (CX - front_w + 12, top + 44),
                                     (CX - waist - 2, bottom - 14), (CX - 26, bottom - 6)], CX), [6, 14, 18, 18, 6])
    bdet = (iridescence(body)
            + mottle(body, [(CX - 80, top + 40, 22, TEAL, .6), (CX + 74, top + 34, 18, CORAL, .55),
                            (CX + 40, top + 100, 20, AQUA, .5), (CX - 50, top + 110, 16, LAVENDER, .6)])
            + f'<path d="{inset}" fill="none" stroke="{DEEP}" stroke-width="1.2" opacity=".45"/>'
            + f'<path d="{inset_r}" fill="none" stroke="{DEEP}" stroke-width="1.2" opacity=".45"/>'
            + f'<path d="{spine}" fill="{TEAL}" opacity=".55"/>'
            + f'<path d="{body}" fill="none" stroke="#ffffff" stroke-width="2.6" opacity=".35"/>')
    h.plate("hull", body, PEARL, bevel=8, details=bdet, shadow=5)
    h.raw("canopy", {5: canopy(CX, top + 2)})
    h.raw("stern-vents", {5: stern_vents(CX, bottom + 64, 22)})
    h.raw("supershield", {5: supershield_organ(CX, bottom + 34)})
    h.mount("mount-defense-laser-a", CX - front_w + 4, top + 16, "Tentauri Defense Laser A", "left")
    h.mount("mount-defense-laser-b", CX + front_w - 4, top + 16, "Tentauri Defense Laser B", "right")
    return h


def shield_deep():
    return shield_hull("Tentauri scout hull, version 9", front_w=114, waist=64, top=84, depth=176)


# ---------- the room layout comes first; the hull is drawn around it ----------
T = 35
FWD = (CX - 2.5 * T, 110, 5, 3)      # forward room: x, y, width and height in tiles
REAR = (CX - 1.5 * T, 110 + 3 * T, 3, 2)


def room_rects():
    return [(x, y, w * T, h * T) for x, y, w, h in (FWD, REAR)]


def fitted(title="Tentauri scout hull, version 10"):
    """Version 10: a hull drawn around the planned rooms (a 5x3 forward room and a 3x2 rear room) with a margin all
    round: a wide forward section with a soft chevron nose, a narrower rear module, weapon blisters mid-side."""
    h = Hull(W, H, title)
    extra_defs(h)
    h.add_def("iris", '<linearGradient id="iris" x1="0" y1="0" x2="1" y2=".7">'
              f'<stop offset="0" stop-color="{AQUA}"/><stop offset=".3" stop-color="{LAVENDER}"/>'
              f'<stop offset=".55" stop-color="{CORAL_WHITE}"/><stop offset=".8" stop-color="{CORAL}"/>'
              f'<stop offset="1" stop-color="{TEAL}"/></linearGradient>')
    fx, fy, fw, fh = FWD
    rx, ry, rw, rh = REAR
    left, right = fx - 24, fx + fw * T + 24          # forward section edges
    rl, rr = rx - 22, rx + rw * T + 22               # rear module edges
    fb, rb = fy + fh * T, ry + rh * T                # bottoms of the two rooms
    for side in (-1, 1):
        bx = (left - 6) if side < 0 else (right + 6)
        d = blister(bx, fy + 1.5 * T, 82, 30)
        det = (iridescence(d) + mottle(d, [(bx, fy + 40, 10, TEAL, .6)])
               + f'<path d="{d}" fill="none" stroke="#ffffff" stroke-width="2" opacity=".35"/>')
        h.plate("blister-" + ("port" if side < 0 else "starboard"), d, PEARL_SHADE, bevel=5, details=det, shadow=3)
    pts = [(CX, fy - 48), (CX + 70, fy - 40), (right - 8, fy - 14), (right, fy + 40), (right - 6, fb + 6),
           (rr + 18, fb + 22), (rr, fb + 34), (rr - 2, rb + 14), (rr - 30, rb + 30), (rl + 30, rb + 30),
           (rl + 2, rb + 14), (rl, fb + 34), (rl - 18, fb + 22), (left + 6, fb + 6), (left, fy + 40),
           (left + 8, fy - 14), (CX - 70, fy - 40)]
    body = rounded_path(pts, [40, 30, 26, 20, 24, 16, 12, 18, 16, 16, 18, 12, 16, 24, 20, 26, 30])
    spine = rounded_path([(CX - 10, fy - 40), (CX + 10, fy - 40), (CX + 14, rb + 22), (CX - 14, rb + 22)], 6)
    bdet = (iridescence(body)
            + mottle(body, [(left + 40, fy + 10, 22, TEAL, .6), (right - 36, fy, 18, CORAL, .55),
                            (CX + 50, fb - 20, 20, AQUA, .5), (CX - 56, fb - 10, 16, LAVENDER, .6),
                            (CX - 30, rb - 10, 14, CORAL, .5), (CX + 34, rb - 24, 12, AQUA, .55)])
            + f'<path d="M{left + 22},{fb + 14} Q{CX},{fb + 26} {right - 22},{fb + 14}" fill="none" stroke="{DEEP}" '
              f'stroke-width="1.3" opacity=".45"/>'
            + f'<path d="{spine}" fill="{TEAL}" opacity=".45"/>'
            + f'<path d="{body}" fill="none" stroke="#ffffff" stroke-width="2.6" opacity=".35"/>')
    h.plate("hull", body, PEARL, bevel=8, details=bdet, shadow=5)
    h.raw("canopy", {5: canopy(CX, fy - 38)})
    h.raw("stern-vents", {5: stern_vents(CX, rb + 30, 24)})
    h.raw("supershield", {5: supershield_organ(CX, rb + 14)})
    h.mount("mount-defense-laser-a", left - 8, fy + 1.5 * T - 18, "Tentauri Defense Laser A", "left")
    h.mount("mount-defense-laser-b", right + 8, fy + 1.5 * T - 18, "Tentauri Defense Laser B", "right")
    return h


def rooms_overlay():
    """A plain outline of the planned rooms, used only to check the fit."""
    return "".join(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="none" stroke="#ff4fd8" stroke-width="1.5" '
                   f'stroke-dasharray="4 3"/>' for x, y, w, h in room_rects())


def single_canopy(cx, y, half_w):
    """One wide canopy pane set into the nose (a single pane, so the front never reads as a pair of eyes)."""
    d = (f"M{cx - half_w},{y + 14} Q{cx - half_w * .5},{y - 2} {cx},{y - 4} Q{cx + half_w * .5},{y - 2} "
         f"{cx + half_w},{y + 14} Q{cx},{y + 8} {cx - half_w},{y + 14} Z")
    return (f'<g id="canopy"><path d="{d}" fill="{DEEP}" stroke="{INK}" stroke-width="1.3" stroke-linejoin="round"/>'
            f'<path d="M{cx - half_w * .75},{y + 9} Q{cx - half_w * .4},{y + 1} {cx - 4},{y}" fill="none" '
            f'stroke="{AQUA}" stroke-width="1.5" opacity=".8"/></g>')


def flank_emitters(points):
    """The Supershield Generator's emitter nodes on the rear module's flanks."""
    return "".join(f'<circle cx="{x}" cy="{y}" r="9" fill="{LAVENDER}" opacity=".4" filter="url(#glow)"/>'
                   f'<circle cx="{x}" cy="{y}" r="6" fill="url(#organ)" stroke="{INK}" stroke-width="1"/>'
                   f'<circle cx="{x - 1.5}" cy="{y - 1.5}" r="1.4" fill="#ffffff" opacity=".85"/>' for x, y in points)


def fitted2(title="Tentauri scout hull, version 11"):
    """Version 11: version 10's room fit with a longer chevron nose, one canopy pane, flowing side stripes instead of
    a spine, forward-pointing weapon blisters at the front corners, and emitter nodes on the rear flanks."""
    h = Hull(W, H, title)
    extra_defs(h)
    h.add_def("iris", '<linearGradient id="iris" x1="0" y1="0" x2="1" y2=".7">'
              f'<stop offset="0" stop-color="{AQUA}"/><stop offset=".3" stop-color="{LAVENDER}"/>'
              f'<stop offset=".55" stop-color="{CORAL_WHITE}"/><stop offset=".8" stop-color="{CORAL}"/>'
              f'<stop offset="1" stop-color="{TEAL}"/></linearGradient>')
    fx, fy, fw, fh = FWD
    rx, ry, rw, rh = REAR
    left, right = fx - 22, fx + fw * T + 22
    rl, rr = rx - 22, rx + rw * T + 22
    fb, rb = fy + fh * T, ry + rh * T
    for side in (-1, 1):
        bx = (left + 4) if side < 0 else (right - 4)
        d = blister(bx, fy + 14, 96, 26)
        det = (iridescence(d) + f'<path d="{d}" fill="none" stroke="#ffffff" stroke-width="2" opacity=".35"/>')
        h.plate("blister-" + ("port" if side < 0 else "starboard"), d, PEARL_SHADE, bevel=5, details=det, shadow=3)
    pts = [(CX, fy - 70), (CX + 56, fy - 50), (right - 6, fy - 12), (right, fy + 52), (right - 8, fb + 4),
           (rr + 10, fb + 24), (rr, fb + 40), (rr - 4, rb + 20), (rr - 28, rb + 40), (rl + 28, rb + 40),
           (rl + 4, rb + 20), (rl, fb + 40), (rl - 10, fb + 24), (left + 8, fb + 4), (left, fy + 52),
           (left + 6, fy - 12), (CX - 56, fy - 50)]
    body = rounded_path(pts, [26, 34, 30, 22, 26, 18, 12, 18, 16, 16, 18, 12, 18, 26, 22, 30, 34])
    stripes = "".join(
        f'<path d="M{CX + s * 22},{fy - 44} C{CX + s * 70},{fy - 10} {CX + s * 92},{fy + 60} {CX + s * 70},{fb + 12} '
        f'C{CX + s * 60},{fb + 30} {CX + s * 50},{rb} {CX + s * 40},{rb + 26}" fill="none" stroke="{TEAL}" '
        f'stroke-width="7" stroke-linecap="round" opacity=".45"/>' for s in (-1, 1))
    bdet = (iridescence(body)
            + mottle(body, [(left + 40, fy + 20, 22, TEAL, .55), (right - 36, fy + 4, 18, CORAL, .5),
                            (CX + 30, fb - 30, 20, AQUA, .45), (CX - 40, fb - 6, 16, LAVENDER, .55),
                            (CX - 20, rb, 14, CORAL, .45)])
            + stripes
            + f'<path d="{body}" fill="none" stroke="#ffffff" stroke-width="2.6" opacity=".35"/>')
    h.plate("hull", body, PEARL, bevel=8, details=bdet, shadow=5)
    h.raw("canopy", {5: single_canopy(CX, fy - 50, 30)})
    h.raw("stern-vents", {5: stern_vents(CX, rb + 40, 24)})
    h.raw("supershield", {5: flank_emitters([(rl + 6, fb + 52), (rr - 6, fb + 52)])})
    h.mount("mount-defense-laser-a", left + 4, fy - 6, "Tentauri Defense Laser A", "left")
    h.mount("mount-defense-laser-b", right - 4, fy - 6, "Tentauri Defense Laser B", "right")
    return h


# nacre tints, one per plate: the prismatic look comes from the plates differing, not from busy patterns
TINT_AQUA = "#d4f0ef"
TINT_CORAL = "#f6dcd6"
TINT_LAVENDER = "#e2def5"
TINT_TEAL = "#bfe3df"
TINT_PEARL = "#eef2f3"


def plate_details(d, spots):
    return (f'<path d="{d}" fill="url(#iris)" opacity=".28"/>' + mottle(d, spots)
            + f'<path d="{d}" fill="none" stroke="#ffffff" stroke-width="2.4" opacity=".4"/>')


def nozzle(x, y):
    """A short organic thrust nozzle at the stern: a ring with a glowing core, set into the rear plate."""
    return (f'<ellipse cx="{x}" cy="{y + 9}" rx="10" ry="12" fill="{GLOW}" opacity=".55" filter="url(#glow)"/>'
            f'<ellipse cx="{x}" cy="{y}" rx="11" ry="7" fill="{TINT_TEAL}" stroke="{INK}" stroke-width="1.3"/>'
            f'<ellipse cx="{x}" cy="{y + 1}" rx="7" ry="4" fill="{DEEP}"/>'
            f'<ellipse cx="{x}" cy="{y + 2}" rx="4" ry="2" fill="{GLOW}"/>')


def segmented(title="Tentauri scout hull, version 12"):
    """Version 12: a hull of overlapping smooth nacre plates laid around the planned rooms (a 5x3 forward room and a
    3x2 rear room): rear module, two flank plates, a central dorsal plate and a broad front plate."""
    h = Hull(W, H, title)
    extra_defs(h)
    h.add_def("iris", '<linearGradient id="iris" x1="0" y1="0" x2="1" y2=".7">'
              f'<stop offset="0" stop-color="{AQUA}"/><stop offset=".3" stop-color="{LAVENDER}"/>'
              f'<stop offset=".55" stop-color="{CORAL_WHITE}"/><stop offset=".8" stop-color="{CORAL}"/>'
              f'<stop offset="1" stop-color="{TEAL}"/></linearGradient>')
    # rear module
    rear = rounded_path([(CX - 74, 206), (CX + 74, 206), (CX + 78, 286), (CX + 48, 320), (CX - 48, 320),
                         (CX - 78, 286)], [18, 18, 26, 20, 20, 26])
    h.plate("plate-rear", rear, TINT_TEAL, bevel=6, details=plate_details(rear, [(CX - 40, 260, 14, CORAL, .4)]),
            shadow=4)
    # flank plates, long and curved, running from the nose back past the forward room
    for side in (-1, 1):
        pts = [(CX + side * 62, 78), (CX + side * 118, 96), (CX + side * 134, 150), (CX + side * 124, 214),
               (CX + side * 92, 244), (CX + side * 66, 226), (CX + side * 70, 120)]
        if side > 0:
            pts = pts[::-1]
        d = rounded_path(pts, 22)
        h.plate("plate-flank-" + ("port" if side < 0 else "starboard"), d, TINT_CORAL, bevel=6,
                details=plate_details(d, [(CX + side * 110, 150, 16, TEAL, .4)]), shadow=4)
    # central dorsal plate, over the rooms
    centre = rounded_path([(CX - 74, 96), (CX + 74, 96), (CX + 96, 140), (CX + 92, 222), (CX + 60, 252),
                           (CX - 60, 252), (CX - 92, 222), (CX - 96, 140)], [30, 30, 24, 24, 20, 20, 24, 24])
    h.plate("plate-dorsal", centre, TINT_LAVENDER, bevel=7,
            details=plate_details(centre, [(CX + 40, 200, 18, AQUA, .4), (CX - 50, 140, 16, CORAL, .35)]), shadow=4)
    # broad front plate across the nose
    front = rounded_path([(CX, 52), (CX + 70, 60), (CX + 112, 92), (CX + 92, 112), (CX, 104), (CX - 92, 112),
                          (CX - 112, 92), (CX - 70, 60)], [30, 26, 16, 20, 30, 20, 16, 26])
    h.plate("plate-front", front, TINT_AQUA, bevel=6, details=plate_details(front, [(CX + 50, 80, 14, LAVENDER, .4)]),
            shadow=4)
    h.raw("canopy", {5: single_canopy(CX, 64, 30)})
    h.raw("stern", {5: nozzle(CX - 26, 318) + nozzle(CX + 26, 318)})
    h.raw("supershield", {5: flank_emitters([(CX - 70, 272), (CX + 70, 272)])})
    h.mount("mount-defense-laser-a", CX - 128, 150, "Tentauri Defense Laser A", "left")
    h.mount("mount-defense-laser-b", CX + 128, 150, "Tentauri Defense Laser B", "right")
    return h


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


def outrigger_wide():
    return outrigger("Tentauri scout hull, version 14", 1.12)


def outrigger2(title="Tentauri scout hull"):
    """Version 13, pass 1: slimmer tapered engine lobes standing a little off the body with a ring seam at the
    engine section; a thinner, gently pointed front plate; soft seams on the dorsal plate."""
    h = Hull(W, H, title)
    extra_defs(h)
    h.add_def("iris", '<linearGradient id="iris" x1="0" y1="0" x2="1" y2=".7">'
              f'<stop offset="0" stop-color="{AQUA}"/><stop offset=".3" stop-color="{LAVENDER}"/>'
              f'<stop offset=".55" stop-color="{CORAL_WHITE}"/><stop offset=".8" stop-color="{CORAL}"/>'
              f'<stop offset="1" stop-color="{TEAL}"/></linearGradient>')
    rear = rounded_path([(CX - 70, 206), (CX + 70, 206), (CX + 64, 284), (CX + 34, 314), (CX - 34, 314),
                         (CX - 64, 284)], [18, 18, 30, 20, 20, 30])
    h.plate("plate-rear", rear, TINT_TEAL, bevel=6, details=plate_details(rear, [(CX - 34, 258, 14, CORAL, .4)]),
            shadow=4)
    for side in (-1, 1):
        h.raw(f"thrust-glow-{side}", {5: f'<ellipse cx="{CX + side * 118}" cy="{326}" rx="11" ry="16" fill="{GLOW}" '
                                         f'opacity=".6" filter="url(#glow)"/>'})
    for side in (-1, 1):
        # a short pylon joining each lobe to the body
        pylon = rounded_path([(CX + side * 88, 168), (CX + side * 108, 164), (CX + side * 108, 214),
                              (CX + side * 88, 222)] if side < 0 else
                             [(CX + side * 88, 222), (CX + side * 108, 214), (CX + side * 108, 164),
                              (CX + side * 88, 168)], 4)
        h.plate(f"pylon-{side}", pylon, TINT_TEAL, bevel=3, outline=1.8, shadow=2, gloss=False)
        pts = [(CX + side * 114, 92), (CX + side * 134, 110), (CX + side * 142, 170), (CX + side * 138, 264),
               (CX + side * 128, 306), (CX + side * 118, 316), (CX + side * 108, 306), (CX + side * 102, 264),
               (CX + side * 102, 170)]
        if side > 0:
            pts = pts[::-1]
        radii = [14, 18, 22, 22, 10, 8, 10, 22, 22]
        d = rounded_path(pts, radii if side < 0 else radii[::-1])
        det = (plate_details(d, [(CX + side * 122, 150, 12, TEAL, .4), (CX + side * 122, 250, 10, LAVENDER, .4)])
               + f'<path d="M{CX + side * 104},{272} Q{CX + side * 122},{266} {CX + side * 140},{272}" fill="none" '
                 f'stroke="{DEEP}" stroke-width="1.4" opacity=".55"/>'
               + f'<path d="M{CX + side * 103},{278} Q{CX + side * 122},{272} {CX + side * 139},{278}" fill="none" '
                 f'stroke="#ffffff" stroke-width="1" opacity=".45"/>')
        h.plate("lobe-" + ("port" if side < 0 else "starboard"), d, TINT_CORAL, bevel=6, details=det, shadow=4)
        h.raw(f"nozzle-{side}", {5: nozzle(CX + side * 118, 312)})
        h.raw(f"side-thruster-{side}", {5: side_thruster(CX + side * 142, 200, side)})
    # the body: its own rounded nose at full width, so nothing overhangs like a brim
    centre = rounded_path([(CX, 52), (CX + 62, 60), (CX + 92, 96), (CX + 96, 150), (CX + 92, 222), (CX + 56, 252),
                           (CX - 56, 252), (CX - 92, 222), (CX - 96, 150), (CX - 92, 96), (CX - 62, 60)],
                          [40, 34, 30, 26, 30, 22, 22, 30, 26, 30, 34])
    cseams = (f'<path d="M{CX - 84},{176} Q{CX},{186} {CX + 84},{176}" fill="none" stroke="{DEEP}" stroke-width="1.1" '
              f'opacity=".35"/><path d="M{CX},{100} L{CX},{244}" stroke="{DEEP}" stroke-width="1" opacity=".25"/>')
    h.plate("plate-dorsal", centre, TINT_LAVENDER, bevel=7,
            details=plate_details(centre, [(CX + 40, 200, 18, AQUA, .4), (CX - 50, 140, 16, CORAL, .35)]) + cseams,
            shadow=4)
    # a nose cap of a different nacre tint, inset on the body (not a separate overhanging plate)
    front = rounded_path([(CX, 58), (CX + 56, 66), (CX + 82, 94), (CX + 60, 104), (CX, 100), (CX - 60, 104),
                          (CX - 82, 94), (CX - 56, 66)], [30, 26, 16, 20, 30, 20, 16, 26])
    h.plate("plate-front", front, TINT_AQUA, bevel=4, outline=1.6,
            details=plate_details(front, [(CX + 44, 80, 12, LAVENDER, .4)]), shadow=1)
    h.raw("canopy", {5: single_canopy(CX, 70, 28)})
    h.raw("supershield", {5: supershield_organ(CX, 290)})
    h.mount("mount-defense-laser-a", CX - 122, 112, "Tentauri Defense Laser A", "left")
    h.mount("mount-defense-laser-b", CX + 122, 112, "Tentauri Defense Laser B", "right")
    return h


VERSIONS = {"v15": outrigger2, "v13": outrigger, "v14": outrigger_wide, "v12": segmented, "v11": fitted2, "v10": fitted, "v8": shield_hull, "v9": shield_deep, "v7": chevron, "v1": peanut, "v2": teardrop, "v3": crescent, "v4": lozenge, "v5": lozenge_narrow, "v6": lozenge_bare}

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
