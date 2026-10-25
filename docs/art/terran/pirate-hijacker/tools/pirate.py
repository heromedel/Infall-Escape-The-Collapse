"""Terran pirate cruiser, second design: a clean, restrained dagger cruiser with modular weapon bays.

Usage: python3 pirate.py OUT_DIR [name ...]

One hull for both loadouts. The side weapon bays are modules that come with the loadout: the Hijacker carries a
weapon pod in both bays, the Cutpurse only the starboard one, with the port bay faired over. Weapons are separate
art (weapons.py) and only drawn in the previews.
Facing up, light from the upper left.
"""
import copy
import math
import os
import sys

from art_kit import Hull, rounded_path, symmetric, mirror_x, shade, INK

W, H, CX = 480, 760, 240

# falling Gatos: darker colours (race profiles, Terrans 1), kept restrained
HULL = "#545b65"
HULL_DARK = "#434951"
HULL_LIGHT = "#68707b"
PLATE_B = "#4c535c"       # replaced plates, a slightly different shade
ACCENT = "#8e2a26"        # oxblood, the one accent colour
STEEL = "#7c838d"
DARK = "#2b3037"
GLASS = "#1e2a3a"
ENGINE_GLOW = "#ffb070"


def line(x1, y1, x2, y2, colour, width=1.0, opacity=1.0):
    return (f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" stroke="{colour}" '
            f'stroke-width="{width}" opacity="{opacity}" stroke-linecap="round"/>')


def seam(x1, y1, x2, y2, base):
    return line(x1, y1, x2, y2, shade(base, .62), 1.1) + line(x1 + .8, y1 + .8, x2 + .8, y2 + .8, shade(base, 1.3), .7)


def rivets(points, base):
    return "".join(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="1.2" fill="{shade(base, .6)}"/>'
                   f'<circle cx="{x - .3:.1f}" cy="{y - .4:.1f}" r=".5" fill="{shade(base, 1.45)}"/>' for x, y in points)


def poly(points, fill, opacity=1.0, extra=""):
    pts = " ".join(f"{x:.1f},{y:.1f}" for x, y in points)
    return f'<polygon points="{pts}" fill="{fill}" opacity="{opacity}" {extra}/>'


def scorch(x, y, rx, ry, opacity=.45):
    """Soft heat scorching, e.g. behind engines and weapon ports. No drips: it fades out evenly."""
    return f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="url(#scorch)" opacity="{opacity}"/>'


def faded(x, y, rx, ry):
    """A patch of sun-faded, thinner paint: lighter, soft-edged."""
    return f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="url(#faded)"/>'


def pitting(points):
    return "".join(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r}" fill="{shade(HULL, .6)}" opacity=".7"/>'
                   for x, y, r in points)


def engine_bell(h, part_id, x, y_top, top_w, bottom_w, length):
    pts = [(x - top_w / 2, y_top), (x + top_w / 2, y_top), (x + bottom_w / 2, y_top + length),
           (x - bottom_w / 2, y_top + length)]
    h.add_def("bell-metal", '<linearGradient id="bell-metal" x1="0" y1="0" x2="1" y2="0">'
              '<stop offset="0" stop-color="#ffffff" stop-opacity=".25"/>'
              '<stop offset=".7" stop-color="#000000" stop-opacity=".15"/>'
              '<stop offset="1" stop-color="#000000" stop-opacity=".4"/></linearGradient>')
    ribs = "".join(seam(x - (top_w + (bottom_w - top_w) * t) / 2 + 1, y_top + length * t,
                        x + (top_w + (bottom_w - top_w) * t) / 2 - 1, y_top + length * t, STEEL) for t in (.4, .75))
    metal = f'<path d="{rounded_path(pts, [2, 2, 3, 3])}" fill="url(#bell-metal)"/>'
    h.raw(part_id + "-glow", {5: f'<ellipse cx="{x}" cy="{y_top + length + 8}" rx="{bottom_w * .4:.1f}" '
                                 f'ry="{length * .5:.1f}" fill="{ENGINE_GLOW}" opacity=".8" filter="url(#glow)"/>'
                                 f'<ellipse cx="{x}" cy="{y_top + length + 1.5}" rx="{bottom_w * .3:.1f}" ry="2.5" '
                                 f'fill="#fff4e0" opacity=".9"/>'})
    h.plate(part_id, rounded_path(pts, [2, 2, 3, 3]), STEEL, bevel=3, outline=2, details=metal + ribs, gloss=False)


def canopy(y_top, y_bottom, half_width):
    """A narrow, swept cockpit canopy: lower and meaner than the Outrider's rounded bubble."""
    d = (f"M{CX},{y_top} L{CX + half_width},{y_bottom - 6} L{CX + half_width * .6},{y_bottom} "
         f"L{CX - half_width * .6},{y_bottom} L{CX - half_width},{y_bottom - 6} Z")
    glint = f"M{CX - 3},{y_top + 8} L{CX - half_width * .7},{y_bottom - 8} L{CX - half_width * .45},{y_bottom - 7} Z"
    return (f'<g id="cockpit"><path d="{d}" fill="{GLASS}" stroke="{INK}" stroke-width="1.5" stroke-linejoin="round"/>'
            f'<path d="{glint}" fill="#7f9ab8" opacity=".6"/>{line(CX, y_top + 4, CX, y_bottom - 1, INK, 1, .7)}</g>')


def extra_defs(h):
    h.add_def("scorch", '<radialGradient id="scorch"><stop offset="0" stop-color="#16181b" stop-opacity=".9"/>'
              '<stop offset=".6" stop-color="#23262a" stop-opacity=".45"/>'
              '<stop offset="1" stop-color="#23262a" stop-opacity="0"/></radialGradient>')
    h.add_def("faded", '<radialGradient id="faded"><stop offset="0" stop-color="#9aa1aa" stop-opacity=".35"/>'
              '<stop offset="1" stop-color="#9aa1aa" stop-opacity="0"/></radialGradient>')


POD_DX = 0


def bay_pod(side):
    """A weapon pod module filling a side bay: a squared housing with a hardpoint ring, where a weapon sits."""
    pts = [(178 - POD_DX, 224), (148 - POD_DX, 230), (134 - POD_DX, 248), (134 - POD_DX, 330), (148 - POD_DX, 346),
           (178 - POD_DX, 350)]
    if side == "starboard":
        pts = mirror_x(pts, CX)[::-1]
    return pts


def bay_pod_details(side):
    x = 154 - POD_DX if side == "port" else 2 * CX - 154 + POD_DX
    a, b = (144 - POD_DX, 174 - POD_DX) if side == "port" else (2 * CX - 174 + POD_DX, 2 * CX - 144 + POD_DX)
    det = (f'<rect x="{x - 17}" y="266" width="34" height="40" rx="4" fill="{DARK}" stroke="{INK}" stroke-width="1.2"/>'
           f'<rect x="{x - 13}" y="270" width="26" height="32" rx="3" fill="none" stroke="{STEEL}" stroke-width="1"/>'
           + seam(a - 6, 246, b, 246, HULL_DARK) + seam(a - 6, 330, b, 330, HULL_DARK)
           + rivets([(x - 12, 238), (x + 12, 238), (x - 12, 338), (x + 12, 338)], HULL_DARK))
    return det


def fairing_details():
    """The port bay faired over flush on the Cutpurse: a neat cover plate, a shade lighter, with a bolt line."""
    x0 = 178 - POD_DX + 8
    pts = [(x0, 236), (x0 + 22, 236), (x0 + 22, 338), (x0, 338)]
    return (poly(pts, HULL_LIGHT, 1, f'stroke="{shade(HULL_LIGHT, .6)}" stroke-width="1"')
            + rivets([(x0 + 5, y) for y in range(246, 336, 14)], HULL_LIGHT))


def rim(path_d):
    """A faint pale inner edge, so the dark hull keeps its outline against space."""
    return (f'<path d="{path_d}" fill="none" stroke="#b4bcc6" stroke-width="3" opacity=".35"/>'
            f'<path d="{path_d}" fill="none" stroke="#eef2f6" stroke-width=".9" opacity=".3"/>')


def build(spec):
    global POD_DX
    POD_DX = spec.get("pod_dx", 0)
    h = Hull(W, H, spec["title"])
    extra_defs(h)
    if spec.get("canard"):
        for side in ("port", "starboard"):
            pts = spec["canard"] if side == "port" else mirror_x(spec["canard"], CX)[::-1]
            h.plate(f"canard-{side}", rounded_path(pts, 3), HULL_DARK, bevel=4, shadow=3)

    # rear fins, small and canted
    for side in ("port", "starboard"):
        pts = spec["fin"] if side == "port" else mirror_x(spec["fin"], CX)[::-1]
        det = seam(*(spec["fin_seam"] if side == "port" else
                     (2 * CX - spec["fin_seam"][0], spec["fin_seam"][1], 2 * CX - spec["fin_seam"][2], spec["fin_seam"][3])),
                   HULL_DARK)
        band = spec.get("fin_band")
        if band:
            bpts = band if side == "port" else mirror_x(band, CX)
            det = poly(bpts, ACCENT) + det
        det += rim(rounded_path(pts, 3))
        h.plate(f"fin-{side}", rounded_path(pts, 3), HULL_DARK, bevel=5, details=det, shadow=4)

    # weapon bay pods: modules that come with the loadout
    for side in spec["pods"]:
        h.plate(f"weapon-pod-{side}", rounded_path(bay_pod(side), 4), HULL_DARK, bevel=5,
                details=bay_pod_details(side) + rim(rounded_path(bay_pod(side), 4)), shadow=4, gloss=False)

    for e in spec["engines"]:
        engine_bell(h, e[0], *e[1:])

    body = symmetric(spec["body_half"], CX)
    radii = spec["body_radii"] + spec["body_radii"][1:-1][::-1]
    bd = []
    # a darker dorsal plate band down the spine and the one oxblood accent
    bd.append(poly(spec["spine"], HULL_DARK, .9))
    for stripe in spec.get("stripes", []):
        bd.append(poly(stripe, ACCENT))
        if stripe[0][0] < CX:
            bd.append(poly(mirror_x(stripe, CX), ACCENT))
    for a, b in spec["seams"]:
        bd.append(seam(a[0], a[1], b[0], b[1], HULL))
        if a[0] < CX - 1 and b[0] < CX - 1:
            (m1, m2) = mirror_x([a, b], CX)
            bd.append(seam(m1[0], m1[1], m2[0], m2[1], HULL))
    for p in spec.get("replaced", []):
        bd.append(poly(p, PLATE_B, 1, f'stroke="{shade(PLATE_B, .62)}" stroke-width="1"'))
    for f in spec.get("faded", []):
        bd.append(faded(*f))
    for sc in spec.get("scorch", []):
        bd.append(scorch(*sc))
    bd.append(pitting(spec.get("pits", [])))
    if "port" not in spec["pods"]:
        bd.append(fairing_details())
    bd.append(rivets(spec.get("rivets", []), HULL))
    bd.append(rim(rounded_path(body, radii)))
    h.plate("hull", rounded_path(body, radii), HULL, bevel=8, details="".join(bd), shadow=5)

    for raw_id, svg in spec.get("raw", []):
        h.raw(raw_id, {5: svg})
    for m in spec["mounts"]:
        h.mount(*m)
    return h


def hatch(x, y, w, h):
    return (f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="2" fill="none" stroke="{shade(HULL_DARK, .6)}" '
            f'stroke-width="1"/>{line(x + 2, y + h + .8, x + w - 2, y + h + .8, shade(HULL_DARK, 1.4), .8)}')


def teleporter(x, y):
    """The crew teleporter's dorsal emitter: a recessed ring with a faint violet core."""
    return (f'<g id="teleporter"><circle cx="{x}" cy="{y}" r="13" fill="{DARK}" stroke="{INK}" stroke-width="1.2"/>'
            f'<circle cx="{x}" cy="{y}" r="9" fill="none" stroke="{STEEL}" stroke-width="1"/>'
            f'<circle cx="{x}" cy="{y}" r="4.5" fill="#9b7fd8" opacity=".7" filter="url(#glow)"/></g>')


def airlock(x, y):
    return (f'<g id="airlock"><rect x="{x - 5}" y="{y - 10}" width="10" height="20" rx="2" fill="{HULL_DARK}" '
            f'stroke="{INK}" stroke-width="1.1"/>{line(x - 3, y, x + 3, y, DARK, 1)}</g>')


def widen(spec, k):
    """Scales a spec's shapes outward from the centreline by k, so the hull holds a mid-tier ship's rooms."""
    def wx(p):
        return (CX + (p[0] - CX) * k, p[1])
    for key in ("body_half", "fin", "spine"):
        spec[key] = [wx(p) for p in spec[key]]
    spec["stripes"] = [[wx(p) for p in st] for st in spec.get("stripes", [])]
    spec["replaced"] = [[wx(p) for p in r] for r in spec.get("replaced", [])]
    spec["seams"] = [(wx(a), wx(b)) for a, b in spec["seams"]]
    x1, y1, x2, y2 = spec["fin_seam"]
    spec["fin_seam"] = (CX + (x1 - CX) * k, y1, CX + (x2 - CX) * k, y2)
    spec["pod_dx"] = (k - 1) * 64
    return spec


def dagger():
    """Version 1: a long chined dagger cruiser, side weapon bays, a broad engine section."""
    s = {
        "title": "Terran pirate cruiser",
        "body_half": [(CX, 36), (226, 58), (206, 126), (190, 190), (180, 236), (176, 340), (176, 470),
                      (166, 520), (162, 598), (178, 640), (206, 654), (CX, 656)],
        "body_radii": [4, 6, 6, 6, 5, 4, 4, 5, 5, 8, 8, 4],
        "fin": [(170, 520), (126, 590), (118, 626), (130, 632), (164, 618)],
        "fin_seam": (160, 548, 128, 610),
        "fin_band": [(146, 556), (154, 548), (128, 600), (120, 606)],
        "pods": ["port", "starboard"],
        "engines": [("engine-port", 204, 644, 32, 42, 36), ("engine-starboard", 276, 644, 32, 42, 36)],
        "spine": [(CX - 16, 130), (CX + 16, 130), (CX + 24, 230), (CX + 24, 600), (CX - 24, 600), (CX - 24, 230)],
        "stripes": [[(206, 126), (214, 118), (198, 190), (190, 190)]],
        "seams": [((190, 200), (290, 200)), ((176, 360), (304, 360)), ((176, 470), (304, 470)),
                  ((166, 560), (314, 560))],
        "replaced": [[(184, 380), (212, 380), (212, 440), (184, 440)],
                     [(270, 476), (300, 476), (300, 520), (272, 520)]],
        "faded": [(206, 290, 26, 40), (268, 420, 20, 30)],
        "scorch": [(204, 632, 24, 14), (276, 632, 24, 14), (140, 286, 18, 22, .3), (340, 286, 18, 22, .3)],
        "pits": [(196, 150, .8), (200, 162, .6), (284, 330, .7), (288, 340, .6), (190, 590, .8)],
        "rivets": [(x, 360) for x in range(186, 300, 14)],
        "raw": [("cockpit", canopy(54, 120, 18)), ("teleporter", teleporter(CX, 300)),
                ("hatches", hatch(CX - 11, 400, 22, 26) + hatch(CX - 11, 500, 22, 30)),
                ("airlock", airlock(172, 420))],
        "mounts": [],
    }
    s = widen(s, 1.3)
    # airlock hatches on both flanks, level with the floor plan's aft-hall airlock doors
    ax = CX - (CX - 176) * 1.3 + 3
    s["raw"][-1] = ("airlocks", airlock(ax, 475) + airlock(2 * CX - ax, 475))
    px = 154 - s["pod_dx"]
    s["mounts"] = [("mount-sporewing", 2 * CX - px, 296, "Sporewing", "right"),
                   ("mount-twinshot", px, 296, "Gat 2.1 Twinshot", "left")]
    s["scorch"][2:4] = [(px - 4, 286, 18, 22, .3), (2 * CX - px + 4, 286, 18, 22, .3)]
    return s


def canard():
    """Version 2: the dagger with small forward canards."""
    s = dagger()
    s["title"] = "Terran pirate cruiser, version 2"
    s["canard"] = [(206, 150), (160, 186), (154, 200), (196, 196)]
    return s


def stepped():
    """Version 3: a stepped hull: a narrow forward section, a wider armoured midsection, an engine block."""
    s = dagger()
    s["title"] = "Terran pirate cruiser, version 3"
    s["body_half"] = [(CX, 36), (224, 60), (210, 130), (204, 196), (172, 212), (162, 236), (162, 470),
                      (176, 488), (176, 600), (180, 640), (206, 654), (CX, 656)]
    s["body_radii"] = [4, 6, 6, 3, 3, 4, 4, 3, 3, 8, 8, 4]
    return s


VERSIONS = {"v1": dagger, "v2": canard, "v3": stepped}


def hijacker():
    s = dagger()
    s["title"] = "Terran Pirate Hijacker hull"
    return s


def cutpurse():
    """The leaner loadout: the port weapon pod is not fitted; the bay is faired over. Plainer: no accent stripe."""
    s = dagger()
    s["title"] = "Terran Pirate Cutpurse hull"
    s["pods"] = ["starboard"]
    s["stripes"] = []
    s["mounts"] = [m for m in s["mounts"] if m[0] != "mount-twinshot"]
    return s


VERSIONS.update({"hijacker": hijacker, "cutpurse": cutpurse})

if __name__ == "__main__":
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    for name in sys.argv[2:] or ["v1", "v2", "v3"]:
        hull = build(VERSIONS[name]())
        open(os.path.join(out, f"{name}.svg"), "w").write(hull.svg(5))
        open(os.path.join(out, f"{name}-mounts.svg"), "w").write(hull.svg(5, show_mounts=True))
        for st in range(1, 6):
            open(os.path.join(out, f"{name}-stage{st}.svg"), "w").write(
                hull.svg(st, background="#ffffff" if st == 1 else None))
        print("built", name)
