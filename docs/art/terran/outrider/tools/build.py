"""Builds the GATOS light battle scout hull: four versions of one shuttle-cruiser concept.

Usage: python3 build.py OUT_DIR
Writes, for each version: vN.svg (final), vN-mounts.svg (review copy showing weapon mount spots) and
vN-stage1..5.svg (outline, fill, shade, highlight, details).

Hull only: no floor or rooms, and no weapons. Weapon mounts are invisible spots; the weapons are separate art.
Facing up, light from the upper left.
"""
import os
import sys

from art_kit import Hull, rounded_path, symmetric, mirror_x, shade, INK

W, H, CX = 460, 740, 230

# GATOS palette: white and pale grey with blue trim (race profile, Terrans 1)
WHITE = "#eceff3"
PALE = "#cdd3db"
STEEL = "#8d96a3"
DARK = "#4a5260"
TRIM = "#2f6bd3"
GLASS = "#1d3a66"
ENGINE_GLOW = "#a8d8ff"


# ---------- shared detail builders ----------

def line(x1, y1, x2, y2, colour, width=1.0, opacity=1.0):
    return (f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" stroke="{colour}" '
            f'stroke-width="{width}" opacity="{opacity}" stroke-linecap="round"/>')


def seam(x1, y1, x2, y2, base):
    """A panel seam: a dark groove with a lit edge below and right of it."""
    return line(x1, y1, x2, y2, shade(base, .58), 1.1) + line(x1 + .8, y1 + .8, x2 + .8, y2 + .8, shade(base, 1.6), .8)


def rivets(points, base):
    return "".join(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="1.3" fill="{shade(base, .6)}"/>'
                   f'<circle cx="{x - .3:.1f}" cy="{y - .4:.1f}" r=".6" fill="#ffffff" opacity=".8"/>'
                   for x, y in points)


def window_row(x, y0, count, gap, base):
    """Small cabin portholes down the hull side."""
    out = []
    for i in range(count):
        y = y0 + i * gap
        out.append(f'<rect x="{x - 3:.1f}" y="{y - 2:.1f}" width="6" height="4" rx="1.5" fill="{GLASS}" '
                   f'stroke="{shade(base, .55)}" stroke-width=".7"/>'
                   f'<rect x="{x - 2:.1f}" y="{y - 1.5:.1f}" width="2.4" height="1.2" rx=".6" fill="#9fd0ff"/>')
    return "".join(out)


def cockpit(y_top, y_bottom, half_width):
    """Curved bridge canopy at the nose."""
    d = (f"M{CX - half_width},{y_bottom} Q{CX - half_width * .9},{y_top + 6} {CX},{y_top} "
         f"Q{CX + half_width * .9},{y_top + 6} {CX + half_width},{y_bottom} "
         f"Q{CX},{y_bottom - 7} {CX - half_width},{y_bottom} Z")
    glint = (f"M{CX - half_width * .7},{y_bottom - 5} Q{CX - half_width * .6},{y_top + 8} {CX - 4},{y_top + 4} "
             f"Q{CX - half_width * .4},{y_top + 12} {CX - half_width * .55},{y_bottom - 6} Z")
    frame = "".join(line(CX + dx, y_top + 3 + abs(dx) * .25, CX + dx * 1.05, y_bottom - 4, INK, 1.2, .8)
                    for dx in (-half_width * .45, half_width * .45))
    return (f'<g id="cockpit"><path d="{d}" fill="{GLASS}" stroke="{INK}" stroke-width="1.6" stroke-linejoin="round"/>'
            f'<path d="{d}" fill="url(#glass-sheen)"/>'
            f'<path d="{glint}" fill="#bfe3ff" opacity=".75"/>{frame}</g>')


def sensor_array(x, y, r):
    """Sensors 2: a dorsal dish with a ring of pickups, the ship's scouting strength made visible."""
    ticks = "".join(
        f'<circle cx="{x + (r + 4) * c:.1f}" cy="{y + (r + 4) * s:.1f}" r="1.6" fill="{TRIM}"/>'
        for c, s in ((1, 0), (.707, .707), (0, 1), (-.707, .707), (-1, 0), (-.707, -.707), (0, -1), (.707, -.707)))
    return (f'<g id="sensor-array">'
            f'<circle cx="{x + 1.5}" cy="{y + 2}" r="{r + 6}" fill="#0b0f18" opacity=".25"/>'
            f'<circle cx="{x}" cy="{y}" r="{r + 6}" fill="{PALE}" stroke="{INK}" stroke-width="1.4"/>'
            f'{ticks}'
            f'<circle cx="{x}" cy="{y}" r="{r}" fill="url(#dish)" stroke="{INK}" stroke-width="1.2"/>'
            f'<circle cx="{x}" cy="{y}" r="{r * .55:.1f}" fill="none" stroke="{shade(STEEL, .7)}" stroke-width=".8"/>'
            f'{line(x - r * .7, y + r * .7, x + r * .7, y - r * .7, shade(STEEL, .6), 1)}'
            f'<circle cx="{x}" cy="{y}" r="3" fill="{DARK}" stroke="{INK}" stroke-width=".8"/>'
            f'<circle cx="{x - .8}" cy="{y - .8}" r="1.1" fill="#d9f0ff"/>'
            f'</g>')


def azc(y, half_width, half_height):
    """The Armoured ZeroPoint Core housing: a heavy octagonal armour cap with bolted segments and a sealed seam.

    Drawn as its own raised plate so it reads as the ship's armoured heart, even when small.
    """
    hw, hh = half_width, half_height
    c = hw * .42
    octagon = [(CX - hw + c, y - hh), (CX + hw - c, y - hh), (CX + hw, y - hh + c), (CX + hw, y + hh - c),
               (CX + hw - c, y + hh), (CX - hw + c, y + hh), (CX - hw, y + hh - c), (CX - hw, y - hh + c)]
    return octagon


def azc_details(y, half_width, half_height):
    hw, hh = half_width, half_height
    inner_hw, inner_hh = hw * .52, hh * .52
    c = inner_hw * .42
    inner = [(CX - inner_hw + c, y - inner_hh), (CX + inner_hw - c, y - inner_hh), (CX + inner_hw, y - inner_hh + c),
             (CX + inner_hw, y + inner_hh - c), (CX + inner_hw - c, y + inner_hh), (CX - inner_hw + c, y + inner_hh),
             (CX - inner_hw, y + inner_hh - c), (CX - inner_hw, y - inner_hh + c)]
    outer_c = hw * .42
    outer = [(CX - hw + outer_c, y - hh), (CX + hw - outer_c, y - hh), (CX + hw, y - hh + outer_c),
             (CX + hw, y + hh - outer_c), (CX + hw - outer_c, y + hh), (CX - hw + outer_c, y + hh),
             (CX - hw, y + hh - outer_c), (CX - hw, y - hh + outer_c)]
    out = []
    # armour segment joints: from each outer corner to the matching inner corner
    for (ox, oy), (ix, iy) in zip(outer, inner):
        out.append(seam(ox, oy, ix, iy, STEEL))
    # the cap
    pts = " ".join(f"{x:.1f},{yy:.1f}" for x, yy in inner)
    out.append(f'<polygon points="{pts}" fill="{shade(STEEL, .9)}" stroke="{INK}" stroke-width="1.3"/>')
    out.append(f'<polygon points="{pts}" fill="url(#cap-sheen)"/>')
    # sealed core seam: a thin cool glow ring that hints at the core inside without opening the armour
    out.append(f'<circle cx="{CX}" cy="{y}" r="{inner_hw * .45:.1f}" fill="none" stroke="{ENGINE_GLOW}" '
               f'stroke-width="2.2" opacity=".9" filter="url(#glow)"/>'
               f'<circle cx="{CX}" cy="{y}" r="{inner_hw * .45:.1f}" fill="none" stroke="#e9f6ff" stroke-width=".9"/>')
    out.append(f'<circle cx="{CX}" cy="{y}" r="{inner_hw * .28:.1f}" fill="{DARK}" stroke="{INK}" stroke-width="1"/>')
    # heavy bolts on each segment
    bolts = []
    for (ox, oy), (ix, iy) in zip(outer, inner[1:] + inner[:1]):
        pass
    for i in range(8):
        (ax, ay), (bx, by) = outer[i], outer[(i + 1) % 8]
        (cx2, cy2), (dx2, dy2) = inner[i], inner[(i + 1) % 8]
        mx, my = (ax + bx + cx2 + dx2) / 4, (ay + by + cy2 + dy2) / 4
        bolts.append((mx, my))
    out.append("".join(f'<circle cx="{x:.1f}" cy="{yy:.1f}" r="2.4" fill="{shade(STEEL, .7)}" stroke="{INK}" '
                       f'stroke-width=".7"/><circle cx="{x - .6:.1f}" cy="{yy - .7:.1f}" r=".9" fill="#f2f5f8"/>'
                       for x, yy in bolts))
    return "".join(out)


def engine_bell(hull, part_id, x, y_top, top_w, bottom_w, length):
    """A thruster bell flaring toward the rear, with its exhaust glow behind it."""
    pts = [(x - top_w / 2, y_top), (x + top_w / 2, y_top), (x + bottom_w / 2, y_top + length),
           (x - bottom_w / 2, y_top + length)]
    ribs = "".join(seam(x - (top_w + (bottom_w - top_w) * t) / 2 + 1, y_top + length * t,
                        x + (top_w + (bottom_w - top_w) * t) / 2 - 1, y_top + length * t, STEEL)
                   for t in (.33, .66))
    hull.raw(part_id + "-glow", {
        5: f'<ellipse class="engine-glow" cx="{x}" cy="{y_top + length + 9}" rx="{bottom_w * .42:.1f}" '
           f'ry="{length * .55:.1f}" fill="{ENGINE_GLOW}" opacity=".85" filter="url(#glow)"/>'
           f'<ellipse cx="{x}" cy="{y_top + length + 2}" rx="{bottom_w * .3:.1f}" ry="3" fill="#ffffff" opacity=".9"/>'})
    hull.add_def("bell-metal", '<linearGradient id="bell-metal" x1="0" y1="0" x2="1" y2="0">'
                 '<stop offset="0" stop-color="#ffffff" stop-opacity=".35"/>'
                 '<stop offset=".3" stop-color="#ffffff" stop-opacity=".05"/>'
                 '<stop offset=".7" stop-color="#000000" stop-opacity=".12"/>'
                 '<stop offset="1" stop-color="#000000" stop-opacity=".35"/></linearGradient>')
    metal = f'<path d="{rounded_path(pts, [2, 2, 3, 3])}" fill="url(#bell-metal)"/>'
    hull.plate(part_id, rounded_path(pts, [2, 2, 3, 3]), STEEL, bevel=3, outline=2, details=metal + ribs,
               gloss=False)
    # nozzle mouth
    hull.raw(part_id + "-mouth", {
        2: f'<rect x="{x - bottom_w / 2 + 2:.1f}" y="{y_top + length - 4:.1f}" width="{bottom_w - 4:.1f}" height="4" '
           f'rx="1.5" fill="{DARK}"/>',
        5: f'<rect x="{x - bottom_w / 2 + 4:.1f}" y="{y_top + length - 2.5:.1f}" width="{bottom_w - 8:.1f}" '
           f'height="1.6" fill="#d8efff" opacity=".9"/>'})


def trim_band(path_d, clip_id_hint, polygon):
    pts = " ".join(f"{x:.1f},{y:.1f}" for x, y in polygon)
    return (f'<polygon points="{pts}" fill="{TRIM}"/>'
            f'<polygon points="{pts}" fill="url(#trim-sheen)"/>')


def airlock(x, y, facing_left=True):
    """Side airlock hatch (every ship has one): a framed door with blue safety marks."""
    w, h = 12, 22
    marks = "".join(f'<rect x="{x - w / 2 - 4 if facing_left else x + w / 2 + 1:.1f}" y="{y - h / 2 + 2 + i * 6:.1f}" '
                    f'width="3" height="3" fill="{TRIM}"/>' for i in range(4))
    return (f'<g id="airlock"><rect x="{x - w / 2:.1f}" y="{y - h / 2:.1f}" width="{w}" height="{h}" rx="3" '
            f'fill="{PALE}" stroke="{INK}" stroke-width="1.2"/>'
            f'{line(x - w / 2 + 2, y, x + w / 2 - 2, y, shade(PALE, .55), 1)}'
            f'<rect x="{x - 2:.1f}" y="{y - h / 2 + 3:.1f}" width="4" height="3" rx="1" fill="{GLASS}"/>'
            f'{marks}</g>')


def vent(x, y, w, h, slats):
    out = [f'<rect x="{x:.1f}" y="{y:.1f}" width="{w}" height="{h}" rx="1.5" fill="{DARK}" stroke="{INK}" stroke-width=".8"/>']
    for i in range(slats):
        sy = y + 2 + i * (h - 4) / max(1, slats - 1)
        out.append(line(x + 2, sy, x + w - 2, sy, shade(STEEL, 1.3), .8))
    return "".join(out)


def extra_defs(hull):
    hull.add_def("glass-sheen", '<linearGradient id="glass-sheen" x1="0" y1="0" x2="1" y2="1">'
                 '<stop offset="0" stop-color="#6fa8e8" stop-opacity=".55"/>'
                 '<stop offset=".6" stop-color="#1d3a66" stop-opacity="0"/></linearGradient>')
    hull.add_def("dish", '<radialGradient id="dish" cx=".38" cy=".35" r=".75">'
                 f'<stop offset="0" stop-color="#f4f7fa"/><stop offset=".6" stop-color="{PALE}"/>'
                 f'<stop offset="1" stop-color="{shade(STEEL, .8)}"/></radialGradient>')
    hull.add_def("cap-sheen", '<linearGradient id="cap-sheen" x1="0" y1="0" x2="1" y2="1">'
                 '<stop offset="0" stop-color="#fff" stop-opacity=".35"/>'
                 '<stop offset=".5" stop-color="#fff" stop-opacity="0"/>'
                 '<stop offset="1" stop-color="#000" stop-opacity=".2"/></linearGradient>')
    hull.add_def("trim-sheen", '<linearGradient id="trim-sheen" x1="0" y1="0" x2="1" y2="1">'
                 '<stop offset="0" stop-color="#fff" stop-opacity=".25"/>'
                 '<stop offset=".5" stop-color="#fff" stop-opacity="0"/>'
                 '<stop offset="1" stop-color="#000" stop-opacity=".25"/></linearGradient>')


# ---------- the ship builder: every version is a spec read by one function ----------

def mirror_points(points):
    return mirror_x(points, CX)


def draw_plates(h, plates):
    """Extra plates; a mirrored plate is drawn on both flanks, its details mirrored with it."""
    for plate in plates:
        sides = ("port", "starboard") if plate.get("mirror") else ("",)
        for side in sides:
            pts = plate["points"] if side != "starboard" else mirror_points(plate["points"])[::-1]
            radii = plate["radii"] if side != "starboard" else plate["radii"][::-1]
            det = plate.get("details", "")
            if side == "starboard":
                det = f'<g transform="translate({2 * CX},0) scale(-1,1)">{det}</g>'
            pid = plate["id"] + (f"-{side}" if side else "")
            h.plate(pid, rounded_path(pts, radii), plate.get("colour", WHITE), bevel=plate.get("bevel", 5),
                    details=det, shadow=plate.get("shadow", 3), gloss=plate.get("gloss", True))


def build_ship(spec):
    """Draws a hull from a spec, back to front: wings, engines, body, spine, core housing, then fittings."""
    h = Hull(W, H, spec["title"])
    extra_defs(h)

    for wing in spec.get("wings", []):
        for side in ("port", "starboard"):
            flip = (lambda p: p) if side == "port" else (lambda p: mirror_points(p)[::-1])
            flip_keep = (lambda p: p) if side == "port" else mirror_points
            det = ""
            if wing.get("trim"):
                det += trim_band("", "", flip_keep(wing["trim"]))
            for a, b in wing.get("seams", []):
                (x1, y1), (x2, y2) = flip_keep([a, b])
                det += seam(x1, y1, x2, y2, wing.get("colour", PALE))
            det += rivets(flip_keep(wing.get("rivets", [])), wing.get("colour", PALE))
            if spec.get("wing_extra") and wing["id"] == "wing":
                fl = flip_keep(spec["wing_extra"])
                pts_txt = " ".join(f"{x:.1f},{y:.1f}" for x, y in fl)
                det = (f'<polygon points="{pts_txt}" fill="{shade(PALE, .86)}"/>'
                       f'{line(fl[0][0], fl[0][1], fl[1][0], fl[1][1], shade(PALE, .55), 1.1)}') + det
            radii = wing["radii"] if side == "port" else wing["radii"][::-1]
            h.plate(f'{wing["id"]}-{side}', rounded_path(flip(wing["points"]), radii), wing.get("colour", PALE),
                    bevel=wing.get("bevel", 6), details=det, shadow=4)

    for pod in spec.get("pods", []):
        for side in ("port", "starboard"):
            pts = pod["points"] if side == "port" else mirror_points(pod["points"])[::-1]
            radii = pod["radii"] if side == "port" else pod["radii"][::-1]
            det = ""
            if pod.get("trim"):
                det += trim_band("", "", pod["trim"] if side == "port" else mirror_points(pod["trim"]))
            for a, b in pod.get("seams", []):
                (x1, y1), (x2, y2) = [a, b] if side == "port" else mirror_points([a, b])
                det += seam(x1, y1, x2, y2, pod.get("colour", WHITE))
            h.plate(f'{pod["id"]}-{side}', rounded_path(pts, radii), pod.get("colour", WHITE), bevel=6,
                    details=det, shadow=4)

    for e in spec["engines"]:
        engine_bell(h, e["id"], *e["at"])
        if e.get("mirror"):
            x, y, tw, bw, ln = e["at"]
            engine_bell(h, e["id"].replace("port", "starboard"), 2 * CX - x, y, tw, bw, ln)

    draw_plates(h, [p for p in spec.get("extra_plates", []) if p.get("under")])
    body = symmetric(spec["body_half"], CX)
    half_r = spec["body_radii"]
    radii = half_r + half_r[1:-1][::-1]
    det = []
    for band in spec.get("body_trim", []):
        det.append(trim_band("", "", band))
        if band[0][0] != CX * 2 - band[0][0] and spec.get("mirror_trim", True) and band[0][0] < CX - 1 and band[1][0] < CX:
            det.append(trim_band("", "", mirror_points(band)))
    for a, b in spec.get("body_seams", []):
        det.append(seam(a[0], a[1], b[0], b[1], WHITE))
        if a[0] < CX - 1 and b[0] < CX - 1:
            m = mirror_points([a, b])
            det.append(seam(m[0][0], m[0][1], m[1][0], m[1][1], WHITE))
    for x, y0, n, gap in spec.get("windows", []):
        det.append(window_row(x, y0, n, gap, WHITE) + window_row(2 * CX - x, y0, n, gap, WHITE))
    for v in spec.get("vents", []):
        det.append(vent(*v))
    det.append(rivets(spec.get("rivets", []), WHITE))
    if spec.get("rounded_body"):
        # a soft sweep across the body: brightest left of centre (facing the light), darker toward both flanks,
        # so the hull reads as a rounded fuselage instead of a flat plate
        h.add_def("roundness", '<linearGradient id="roundness" x1="0" y1="0" x2="1" y2="0">'
                  '<stop offset="0" stop-color="#3a4558" stop-opacity=".22"/>'
                  '<stop offset=".18" stop-color="#ffffff" stop-opacity=".0"/>'
                  '<stop offset=".36" stop-color="#ffffff" stop-opacity=".30"/>'
                  '<stop offset=".6" stop-color="#ffffff" stop-opacity="0"/>'
                  '<stop offset="1" stop-color="#3a4558" stop-opacity=".32"/></linearGradient>')
        det.insert(0, f'<path d="{rounded_path(body, radii)}" fill="url(#roundness)"/>')
    h.plate("hull", rounded_path(body, radii), WHITE, bevel=8, details="".join(det), shadow=5)

    if spec.get("spine"):
        sp = spec["spine"]
        sdet = "".join(seam(a[0], a[1], b[0], b[1], PALE) for a, b in sp.get("seams", []))
        h.plate("spine", rounded_path(sp["points"], sp.get("radius", 10)), shade(WHITE, .96), bevel=5,
                details=sdet, shadow=2)

    draw_plates(h, [p for p in spec.get("extra_plates", []) if not p.get("under")])

    y, hw, hh = spec["azc"]
    h.plate("azc", rounded_path(azc(y, hw, hh), 4), STEEL, bevel=5, details=azc_details(y, hw, hh), shadow=4,
            gloss=False)
    for raw_id, svg in spec.get("extra_raw", []):
        h.raw(raw_id, {5: svg})
    h.raw("cockpit", {5: cockpit(*spec["cockpit"])})
    h.raw("sensor-array", {5: sensor_array(*spec["sensor"])})
    h.raw("airlock", {5: airlock(*spec["airlock"])})
    for m in spec["mounts"]:
        h.mount(*m)
    return h


# version 1: swept delta wings and three engines
V1 = {
    "title": "GATOS light battle scout, version 1",
    "body_half": [(CX, 34), (204, 44), (182, 68), (166, 108), (152, 170), (142, 250), (136, 330), (134, 450),
                  (136, 560), (146, 612), (168, 636), (CX, 642)],
    "body_radii": [30, 16, 16, 14, 10, 8, 6, 6, 6, 10, 14, 8],
    "wings": [{"id": "wing", "points": [(140, 292), (62, 486), (40, 540), (46, 570), (140, 590)],
               "radii": [4, 10, 12, 8, 4], "trim": [(140, 292), (62, 486), (70, 492), (140, 312)],
               "seams": [((112, 400), (64, 520)), ((126, 470), (72, 548))],
               "rivets": [(96 + k * 9, 568) for k in range(5)]}],
    "engines": [{"id": "engine-centre", "at": (CX, 632, 40, 56, 40)},
                {"id": "engine-port", "at": (186, 622, 30, 42, 36), "mirror": True}],
    "body_trim": [[(CX - 40, 112), (CX + 40, 112), (CX + 41, 118), (CX - 41, 118)],
                  [(CX - 42, 123), (CX + 42, 123), (CX + 43, 127), (CX - 43, 127)]],
    "body_seams": [((150, 200), (310, 200)), ((140, 300), (320, 300)), ((136, 470), (324, 470)),
                   ((138, 560), (322, 560))],
    "windows": [(158, 140, 6, 14)],
    "vents": [(CX - 40, 596, 22, 14, 4), (CX + 18, 596, 22, 14, 4)],
    "rivets": [(x, 616) for x in range(170, 292, 12)],
    "spine": {"points": [(CX - 46, 180), (CX + 46, 180), (CX + 56, 230), (CX + 56, 560), (CX + 40, 590),
                         (CX - 40, 590), (CX - 56, 560), (CX - 56, 230)],
              "seams": [((CX - 56, 260), (CX + 56, 260)), ((CX - 56, 470), (CX + 56, 470)),
                        ((CX - 56, 530), (CX + 56, 530))]},
    "azc": (380, 50, 50),
    "cockpit": (56, 96, 26),
    "sensor": (CX, 150, 15),
    "airlock": (146, 500),
    "mounts": [("mount-triblast", 150, 270, "Gat 3.1 Triblast", "left"),
               ("mount-pathfinder", 310, 270, "Gat M1 Pathfinder", "right")],
}

# version 2: wider cruiser body, engines in pods at the wing roots, small forward canards
V2 = {
    "title": "GATOS light battle scout, version 2",
    "body_half": [(CX, 40), (200, 50), (176, 80), (160, 130), (148, 200), (140, 300), (138, 420), (140, 540),
                  (150, 600), (172, 628), (CX, 634)],
    "body_radii": [34, 18, 18, 14, 10, 8, 6, 8, 12, 14, 8],
    "wings": [{"id": "canard", "points": [(160, 150), (112, 200), (108, 218), (152, 214)],
               "radii": [3, 8, 6, 3], "trim": [(160, 150), (112, 200), (118, 203), (160, 160)]},
              {"id": "wing", "points": [(140, 380), (52, 520), (46, 560), (140, 560)],
               "radii": [4, 10, 8, 4], "trim": [(140, 380), (52, 520), (60, 524), (140, 398)],
               "seams": [((118, 450), (70, 530))]}],
    "pods": [{"id": "engine-pod", "points": [(104, 420), (128, 404), (150, 420), (152, 600), (140, 616), (114, 616),
                                             (102, 600)],
              "radii": [10, 14, 10, 6, 6, 6, 6], "trim": [(102, 450), (152, 450), (152, 458), (102, 458)],
              "seams": [((104, 540), (150, 540))]}],
    "engines": [{"id": "engine-port", "at": (127, 606, 34, 46, 40), "mirror": True},
                {"id": "engine-centre", "at": (CX, 624, 34, 44, 34)}],
    "body_trim": [[(CX - 44, 118), (CX + 44, 118), (CX + 45, 125), (CX - 45, 125)]],
    "body_seams": [((150, 230), (310, 230)), ((140, 330), (320, 330)), ((138, 520), (322, 520))],
    "windows": [(160, 150, 5, 14)],
    "vents": [(CX - 18, 590, 36, 16, 5)],
    "rivets": [(x, 612) for x in range(176, 290, 12)],
    "spine": {"points": [(CX - 50, 200), (CX + 50, 200), (CX + 62, 250), (CX + 62, 560), (CX + 44, 590),
                         (CX - 44, 590), (CX - 62, 560), (CX - 62, 250)],
              "seams": [((CX - 62, 290), (CX + 62, 290)), ((CX - 62, 500), (CX + 62, 500))]},
    "azc": (400, 52, 52),
    "cockpit": (62, 104, 28),
    "sensor": (CX, 160, 16),
    "airlock": (144, 470),
    "mounts": [("mount-triblast", 116, 204, "Gat 3.1 Triblast", "left"),
               ("mount-pathfinder", 344, 204, "Gat M1 Pathfinder", "right")],
}

# version 3: broad shuttle, a rounded wide body with short fins and a four-bell engine block
V3 = {
    "title": "GATOS light battle scout, version 3",
    "body_half": [(CX, 50), (190, 58), (150, 90), (124, 150), (114, 240), (112, 400), (114, 540), (124, 596),
                  (150, 618), (CX, 622)],
    "body_radii": [40, 30, 30, 24, 10, 8, 14, 18, 14, 8],
    "wings": [{"id": "fin", "points": [(118, 470), (64, 556), (62, 590), (118, 590)],
               "radii": [4, 10, 8, 4], "trim": [(118, 470), (64, 556), (72, 560), (118, 488)]}],
    "engines": [{"id": "engine-port-outer", "at": (170, 612, 30, 40, 34), "mirror": True},
                {"id": "engine-port-inner", "at": (210, 616, 30, 40, 38), "mirror": True}],
    "body_trim": [[(124, 150), (138, 150), (126, 560), (114, 560)],
                  [(CX - 60, 128), (CX + 60, 128), (CX + 64, 136), (CX - 64, 136)]],
    "body_seams": [((124, 220), (336, 220)), ((116, 330), (344, 330)), ((114, 450), (346, 450)),
                   ((118, 560), (342, 560))],
    "windows": [(134, 170, 8, 14)],
    "vents": [(150, 580, 22, 14, 4), (288, 580, 22, 14, 4)],
    "rivets": [(x, 600) for x in range(160, 304, 12)],
    "spine": {"points": [(CX - 70, 170), (CX + 70, 170), (CX + 84, 210), (CX + 84, 550), (CX + 64, 576),
                         (CX - 64, 576), (CX - 84, 550), (CX - 84, 210)],
              "seams": [((CX - 84, 260), (CX + 84, 260)), ((CX - 84, 500), (CX + 84, 500))]},
    "azc": (370, 54, 54),
    "cockpit": (66, 108, 34),
    "sensor": (CX, 150, 0) if False else (CX, 146, 15),
    "airlock": (126, 500),
    "mounts": [("mount-triblast", 118, 250, "Gat 3.1 Triblast", "left"),
               ("mount-pathfinder", 342, 250, "Gat M1 Pathfinder", "right")],
}

# version 4: rocket cruiser, a slim nose flaring to a wide stern with big swept fins and one main engine
V4 = {
    "title": "GATOS light battle scout, version 4",
    "body_half": [(CX, 28), (212, 40), (196, 70), (184, 120), (174, 200), (164, 300), (152, 400), (140, 500),
                  (132, 580), (142, 622), (170, 640), (CX, 644)],
    "body_radii": [22, 14, 16, 14, 10, 8, 8, 8, 10, 14, 14, 8],
    "wings": [{"id": "fin", "points": [(160, 360), (60, 540), (52, 640), (78, 652), (136, 610)],
               "radii": [4, 14, 10, 8, 4], "trim": [(160, 360), (60, 540), (68, 546), (160, 380)],
               "seams": [((140, 450), (80, 560)), ((134, 540), (76, 620))]}],
    "engines": [{"id": "engine-centre", "at": (CX, 630, 52, 72, 46)},
                {"id": "engine-port", "at": (164, 626, 22, 30, 26), "mirror": True}],
    "body_trim": [[(CX - 30, 112), (CX + 30, 112), (CX + 32, 119), (CX - 32, 119)],
                  [(CX - 34, 125), (CX + 34, 125), (CX + 35, 129), (CX - 35, 129)]],
    "body_seams": [((176, 220), (284, 220)), ((160, 330), (300, 330)), ((146, 450), (314, 450)),
                   ((136, 560), (324, 560))],
    "windows": [(186, 150, 5, 14)],
    "vents": [(CX - 40, 596, 22, 14, 4), (CX + 18, 596, 22, 14, 4)],
    "rivets": [(x, 618) for x in range(160, 304, 12)],
    "spine": {"points": [(CX - 36, 180), (CX + 36, 180), (CX + 48, 240), (CX + 62, 560), (CX + 46, 592),
                         (CX - 46, 592), (CX - 62, 560), (CX - 48, 240)],
              "seams": [((CX - 50, 280), (CX + 50, 280)), ((CX - 60, 500), (CX + 60, 500))]},
    "azc": (400, 48, 48),
    "cockpit": (50, 90, 20),
    "sensor": (CX, 150, 14),
    "airlock": (160, 470),
    "mounts": [("mount-triblast", 172, 250, "Gat 3.1 Triblast", "left"),
               ("mount-pathfinder", 288, 250, "Gat M1 Pathfinder", "right")],
}


# ---------- version 1 refinement passes ----------
import copy


def hatch(x, y, w, h, base):
    """A flush dorsal access hatch: a seam rectangle with a lit lower edge and a small handle."""
    return (f'<rect x="{x:.1f}" y="{y:.1f}" width="{w}" height="{h}" rx="2.5" fill="none" stroke="{shade(base, .6)}" '
            f'stroke-width="1"/>'
            f'{line(x + 2, y + h + .8, x + w - 2, y + h + .8, shade(base, 1.6), .8)}'
            f'<rect x="{x + w / 2 - 3:.1f}" y="{y + h - 4:.1f}" width="6" height="2" rx="1" fill="{shade(base, .55)}"/>')


def pass_1(spec):
    """Engines out of hiding, longer swept wings with control surfaces, armour shoulders at the core,
    a dorsal centre strip and hatches on the spine."""
    s = copy.deepcopy(spec)
    s["title"] = "GATOS light battle scout, version 1, pass 1"
    s["wings"] = [{"id": "wing", "points": [(140, 286), (60, 480), (34, 560), (42, 600), (140, 600)],
                   "radii": [4, 12, 10, 8, 4], "trim": [(140, 286), (60, 480), (34, 560), (42, 562), (68, 486), (140, 306)],
                   "seams": [((116, 400), (60, 520)), ((128, 470), (54, 580)), ((60, 582), (124, 582))],
                   "rivets": [(80 + k * 9, 592) for k in range(6)]}]
    # stern block that carries the engines, so they read as part of the ship
    stern = [(CX - 72, 600), (CX + 72, 600), (CX + 78, 634), (CX + 66, 652), (CX - 66, 652), (CX - 78, 634)]
    sdet = (trim_band("", "", [(CX - 78, 618), (CX + 78, 618), (CX + 78, 624), (CX - 78, 624)]) +
            rivets([(x, 642) for x in range(CX - 60, CX + 61, 12)], STEEL))
    s["extra_plates"] = [{"id": "stern", "points": stern, "radii": [6, 6, 8, 8, 8, 8], "colour": PALE,
                          "details": sdet, "gloss": False}]
    s["engines"] = [{"id": "engine-centre", "at": (CX, 646, 44, 60, 40)},
                    {"id": "engine-port", "at": (CX - 50, 642, 32, 44, 34), "mirror": True}]
    # armour shoulders: heavy plates on both flanks at the core, so the armoured heart reads from outside
    shoulder = [(128, 350), (146, 340), (146, 420), (128, 410)]
    shd = seam(131, 366, 143, 362, STEEL) + seam(131, 394, 143, 398, STEEL) + rivets([(137, 380)], STEEL)
    s["extra_plates"].append({"id": "armour-shoulder", "points": shoulder, "radii": [4, 3, 3, 4], "colour": STEEL,
                              "mirror": True, "details": shd,
                              "details_starboard": (seam(2 * CX - 131, 366, 2 * CX - 143, 362, STEEL) +
                                                    seam(2 * CX - 131, 394, 2 * CX - 143, 398, STEEL) +
                                                    rivets([(2 * CX - 137, 380)], STEEL)),
                              "gloss": False, "shadow": 2})
    # spine: a pale centre strip and access hatches, so the deck isn't an empty slab
    s["spine"]["seams"] = [((CX - 56, 260), (CX + 56, 260)), ((CX - 56, 470), (CX + 56, 470)),
                           ((CX - 56, 530), (CX + 56, 530)), ((CX - 14, 190), (CX - 14, 316)),
                           ((CX + 14, 190), (CX + 14, 316)), ((CX - 14, 444), (CX - 14, 580)),
                           ((CX + 14, 444), (CX + 14, 580))]
    s["extra_raw"] = [("spine-hatches", hatch(CX - 46, 200, 24, 16, WHITE) + hatch(CX + 22, 200, 24, 16, WHITE) +
                       hatch(CX - 46, 480, 24, 16, WHITE) + hatch(CX + 22, 480, 24, 16, WHITE) +
                       hatch(CX - 46, 540, 24, 30, WHITE) + hatch(CX + 22, 540, 24, 30, WHITE))]
    s["vents"] = []
    s["rivets"] = []
    s["body_seams"] = [((150, 200), (310, 200)), ((136, 470), (324, 470)), ((138, 560), (322, 560))]
    s["windows"] = [(158, 140, 6, 14)]
    s["mounts"] = [("mount-triblast", 140, 266, "Gat 3.1 Triblast", "left"),
                   ("mount-pathfinder", 320, 266, "Gat M1 Pathfinder", "right")]
    return s


P1 = pass_1(V1)


def pass_2(spec):
    """Stern tucked under the body, chunkier armour shoulders, a larger framed cockpit, wingtip trim and a
    pair of sensor masts."""
    s = copy.deepcopy(spec)
    s["title"] = "GATOS light battle scout, version 1, pass 2"
    stern = [(CX - 80, 580), (CX + 80, 580), (CX + 84, 636), (CX + 70, 654), (CX - 70, 654), (CX - 84, 636)]
    sdet = (trim_band("", "", [(CX - 84, 640), (CX + 84, 640), (CX + 80, 646), (CX - 80, 646)]) +
            rivets([(x, 630) for x in range(CX - 72, CX + 73, 12)], PALE))
    shoulder = [(122, 344), (148, 332), (148, 428), (122, 416)]
    shd = (seam(126, 362, 144, 356, STEEL) + seam(126, 398, 144, 404, STEEL) +
           rivets([(133, 352), (133, 408), (133, 380)], STEEL))
    s["extra_plates"] = [
        {"id": "stern", "points": stern, "radii": [6, 6, 10, 8, 8, 10], "colour": PALE, "details": sdet,
         "gloss": False, "under": True},
        {"id": "armour-shoulder", "points": shoulder, "radii": [5, 3, 3, 5], "colour": STEEL, "mirror": True,
         "details": shd, "gloss": False, "shadow": 3, "bevel": 4}]
    s["wings"][0]["trim"] = [(140, 286), (60, 480), (34, 560), (38, 584), (44, 562), (68, 486), (140, 306)]
    s["cockpit"] = (52, 104, 32)
    s["body_trim"] = [[(CX - 44, 118), (CX + 44, 118), (CX + 45, 124), (CX - 45, 124)],
                      [(CX - 46, 129), (CX + 46, 129), (CX + 47, 132), (CX - 47, 132)]]
    s["extra_raw"] = s["extra_raw"] + [("sensor-masts", "".join(
        line(x, 166, x, 186, INK, 1.6) + f'<circle cx="{x}" cy="164" r="2.4" fill="{TRIM}" stroke="{INK}" '
                                         f'stroke-width=".8"/>' for x in (CX - 24, CX + 24)))]
    s["sensor"] = (CX, 152, 15)
    return s


P2 = pass_2(P1)


def roundel(x, y, r):
    """A generic blue-and-white marking: a blue disc, white ring and a blue chevron."""
    return (f'<circle cx="{x}" cy="{y}" r="{r}" fill="{TRIM}" stroke="{INK}" stroke-width=".9"/>'
            f'<circle cx="{x}" cy="{y}" r="{r * .72:.1f}" fill="#ffffff"/>'
            f'<path d="M{x - r * .45:.1f},{y + r * .2:.1f} L{x},{y - r * .35:.1f} L{x + r * .45:.1f},{y + r * .2:.1f} '
            f'L{x + r * .45:.1f},{y + r * .45:.1f} L{x},{y - r * .05:.1f} L{x - r * .45:.1f},{y + r * .45:.1f} Z" '
            f'fill="{TRIM}"/>')


def pass_3(spec):
    """Trailing-edge flaps and a roundel on each wing, and aft portholes on the body."""
    s = copy.deepcopy(spec)
    s["title"] = "GATOS light battle scout, version 1, pass 3"
    wing = s["wings"][0]
    flap = [(44, 572), (138, 572), (138, 598), (44, 598)]
    wing["seams"] = [((116, 400), (60, 520)), ((128, 470), (54, 572)), ((90, 572), (90, 598)),
                     ((116, 572), (116, 598))]
    wing["rivets"] = []
    s["wing_extra"] = flap
    s["windows"] = [(158, 140, 6, 14), (144, 440, 3, 14)]
    s["extra_raw"] = s["extra_raw"] + [("wing-roundels", roundel(92, 520, 11) + roundel(2 * CX - 92, 520, 11))]
    return s


P3 = pass_3(P2)


def pass_4(spec):
    """A rounded-fuselage light sweep, and bigger engine bells for a cruiser-sized stern."""
    s = copy.deepcopy(spec)
    s["title"] = "GATOS light battle scout, version 1, pass 4"
    s["rounded_body"] = True
    s["engines"] = [{"id": "engine-centre", "at": (CX, 648, 50, 68, 44)},
                    {"id": "engine-port", "at": (CX - 56, 642, 36, 50, 38), "mirror": True}]
    stern = [(CX - 88, 574), (CX + 88, 574), (CX + 92, 640), (CX + 78, 660), (CX - 78, 660), (CX - 92, 640)]
    s["extra_plates"][0]["points"] = stern
    s["extra_plates"][0]["details"] = (
        trim_band("", "", [(CX - 92, 644), (CX + 92, 644), (CX + 86, 651), (CX - 86, 651)]) +
        rivets([(x, 632) for x in range(CX - 80, CX + 81, 12)], PALE))
    return s


P4 = pass_4(P3)


def pass_5(spec):
    """A smooth rear edge, portholes moved inside the hull, and metal shading inside the engine bells."""
    s = copy.deepcopy(spec)
    s["title"] = "GATOS light battle scout, version 1, pass 5"
    s["body_half"] = [(CX, 34), (204, 44), (182, 68), (166, 108), (152, 170), (142, 250), (136, 330), (134, 450),
                      (136, 570), (148, 618), (186, 640), (CX, 642)]
    s["body_radii"] = [30, 16, 16, 14, 10, 8, 6, 6, 18, 24, 20, 8]
    s["windows"] = [(171, 150, 5, 14), (147, 440, 3, 14)]
    s["shaded_bells"] = True
    return s


P5 = pass_5(P4)


def pass_6(spec):
    """Wider wing-edge trim, so the blue still reads at squad zoom."""
    s = copy.deepcopy(spec)
    s["title"] = "SC-1 Outrider hull"
    s["wings"][0]["trim"] = [(140, 286), (60, 480), (34, 560), (38, 586), (48, 564), (74, 490), (140, 314)]
    return s


P6 = pass_6(P5)
VERSIONS = {1: V1, 2: V2, 3: V3, 4: V4, 11: P1, 12: P2, 13: P3, 14: P4, 15: P5, 16: P6}

if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "."
    os.makedirs(out, exist_ok=True)
    which = [int(a) for a in sys.argv[2:]] or list(VERSIONS)
    for n in which:
        hull = build_ship(VERSIONS[n])
        open(os.path.join(out, f"v{n}.svg"), "w").write(hull.svg(5))
        open(os.path.join(out, f"v{n}-mounts.svg"), "w").write(hull.svg(5, show_mounts=True))
        for s in range(1, 6):
            open(os.path.join(out, f"v{n}-stage{s}.svg"), "w").write(
                hull.svg(s, background="#ffffff" if s == 1 else None))
        print("built version", n)
