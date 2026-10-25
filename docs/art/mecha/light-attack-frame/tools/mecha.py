"""Mecha Light Attack Frame hull: wide, squat and military, one standard frame with two loadouts.

Usage: python3 mecha.py OUT_DIR [name ...]
Writes NAME.svg, NAME-mounts.svg and NAME-stage1..5.svg for each version and loadout.

Gunmetal and black with yellow and orange hazard markings, uniform panels and stencilled functional markings, no
emblems. Mechanical and self-powered: no core, no conduits. The starboard sponson carries the loadout module: a
weapon pod with a hardpoint (Hull Laser loadout) or a suit launch bay (Suit Dock loadout). Weapons and the
battlesuit are separate art (mecha_weapons.py). Facing up, light from the upper left. Shaped around the room plan in
rooms.py. v12 is the final frame; v1-v11 are the versions tried.
"""
import os
import sys

from art_kit import Hull, rounded_path, mirror_x, shade, INK

W, H, CX = 440, 330, 220

GUNMETAL = "#4b5159"
GUN_DARK = "#3c4148"
BLACK = "#202328"
STEEL = "#7b838d"
YELLOW = "#f0c02c"
ORANGE = "#ec7a1e"
GLASS = "#18222e"
THRUST = "#ffd27a"
STENCIL = "#e9e2c8"
VISOR = "#ffb43c"


def line(x1, y1, x2, y2, colour, width=1.0, opacity=1.0):
    return (f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" stroke="{colour}" '
            f'stroke-width="{width}" opacity="{opacity}"/>')


def seam(x1, y1, x2, y2, base):
    return line(x1, y1, x2, y2, shade(base, .6), 1.1) + line(x1 + .8, y1 + .8, x2 + .8, y2 + .8, shade(base, 1.3), .7)


def bolts(points, base):
    return "".join(f'<rect x="{x - 1.3:.1f}" y="{y - 1.3:.1f}" width="2.6" height="2.6" fill="{shade(base, .6)}"/>'
                   f'<rect x="{x - 1.1:.1f}" y="{y - 1.1:.1f}" width="1" height="1" fill="{shade(base, 1.5)}"/>'
                   for x, y in points)


def hazard(points, colour=YELLOW, width=6, opacity=1.0):
    """A band of diagonal hazard stripes filling a polygon."""
    pts = " ".join(f"{x:.1f},{y:.1f}" for x, y in points)
    pid = "hz-y" if colour == YELLOW else "hz-o"
    return f'<polygon points="{pts}" fill="url(#{pid})" opacity="{opacity}"/>'


def stencil(x, y, text, size=8, colour=STENCIL, anchor="middle", rotate=0, opacity=.85):
    rot = f' transform="rotate({rotate} {x} {y})"' if rotate else ""
    return (f'<text x="{x}" y="{y}" font-family="\'DejaVu Sans Mono\', monospace" font-weight="bold" font-size="{size}" '
            f'letter-spacing="1.2" fill="{colour}" text-anchor="{anchor}" opacity="{opacity}"{rot}>{text}</text>')


def defs(h):
    for pid, colour in (("hz-y", YELLOW), ("hz-o", ORANGE)):
        h.add_def(pid, f'<pattern id="{pid}" width="8" height="8" patternUnits="userSpaceOnUse" '
                       f'patternTransform="rotate(45)"><rect width="8" height="8" fill="{BLACK}"/>'
                       f'<rect width="4" height="8" fill="{colour}"/></pattern>')
    h.add_def("scorch", '<radialGradient id="scorch"><stop offset="0" stop-color="#121417" stop-opacity=".85"/>'
              '<stop offset="1" stop-color="#121417" stop-opacity="0"/></radialGradient>')


def P(points):
    return rounded_path(points, 3)


# ---------- shapes: each returns the plates as point lists, drawn around the room plan (x 80-360, y 100-240) ----------

def shape_slab():
    """v1 slab: a broad rectangular body with a flat armoured prow wider than the body, square sponsons."""
    return {
        "body": [(102, 92), (338, 92), (346, 104), (346, 252), (334, 262), (106, 262), (94, 252), (94, 104)],
        "prow": [(84, 66), (356, 66), (362, 80), (346, 98), (94, 98), (78, 80)],
        "port": [(62, 122), (96, 116), (96, 226), (62, 220), (56, 210), (56, 132)],
        "stern": [(118, 258), (322, 258), (322, 280), (118, 280)],
    }


def shape_hammer():
    """v2 hammer: a wide armoured crossbar across the bow, a narrower body behind it."""
    return {
        "body": [(108, 100), (332, 100), (344, 112), (344, 250), (330, 262), (110, 262), (96, 250), (96, 112)],
        "prow": [(40, 70), (400, 70), (408, 84), (392, 106), (330, 112), (110, 112), (48, 106), (32, 84)],
        "port": [(64, 112), (98, 112), (98, 226), (66, 222), (58, 212), (58, 120)],
        "stern": [(118, 258), (322, 258), (322, 280), (118, 280)],
    }


def shape_wedge():
    """v3 blunt wedge: a squat body widening to a broad stern, a flat blunt bow."""
    return {
        "body": [(130, 84), (310, 84), (350, 150), (360, 236), (346, 262), (94, 262), (80, 236), (90, 150)],
        "prow": [(126, 64), (314, 64), (322, 76), (306, 92), (134, 92), (118, 76)],
        "port": [(58, 140), (92, 130), (86, 232), (56, 228), (50, 216), (52, 150)],
        "stern": [(112, 258), (328, 258), (328, 282), (112, 282)],
    }


def shape_shoulders():
    """v4 shouldered: a hexagonal body with angled armour shoulders reaching forward over the sponsons."""
    return {
        "body": [(150, 86), (290, 86), (346, 104), (352, 250), (336, 264), (104, 264), (88, 250), (94, 104)],
        "prow": [(140, 66), (300, 66), (306, 80), (290, 94), (150, 94), (134, 80)],
        "port": [(54, 106), (100, 100), (100, 228), (64, 228), (52, 216), (46, 120)],
        "stern": [(118, 260), (322, 260), (322, 282), (118, 282)],
    }


def shape_tiered():
    """v5 tiered: a stepped fortress, a raised central spine block over a wide lower deck."""
    return {
        "body": [(96, 96), (344, 96), (352, 108), (352, 250), (340, 262), (100, 262), (88, 250), (88, 108)],
        "prow": [(150, 66), (290, 66), (300, 78), (290, 100), (150, 100), (140, 78)],
        "port": [(60, 124), (90, 120), (90, 224), (60, 220), (54, 210), (54, 134)],
        "stern": [(118, 258), (322, 258), (322, 280), (118, 280)],
        "spine": [(176, 104), (264, 104), (270, 112), (270, 246), (262, 254), (178, 254), (170, 246), (170, 112)],
    }


def shape_bull():
    """v6 bull: the bow crossbar swept forward into horn tips, angled cheeks, the body tapering a little aft."""
    return {
        "body": [(112, 98), (328, 98), (348, 120), (342, 252), (326, 264), (114, 264), (98, 252), (92, 120)],
        "prow": [(26, 46), (46, 54), (150, 70), (290, 70), (394, 54), (414, 46), (404, 78), (352, 108), (300, 116),
                 (140, 116), (88, 108), (36, 78)],
        "port": [(60, 116), (98, 112), (98, 228), (70, 226), (58, 214), (54, 126)],
        "stern": [(118, 258), (322, 258), (322, 280), (118, 280)],
        "armour": [[(98, 120), (128, 104), (128, 150), (98, 156)], [(342, 120), (312, 104), (312, 150), (342, 156)]],
    }


def shape_delta():
    """v7 broad delta: a wide angular arrowhead with a flat blunt bow and a broad stern, sponsons as wing roots."""
    return {
        "body": [(150, 80), (290, 80), (372, 196), (378, 246), (360, 266), (80, 266), (62, 246), (68, 196)],
        "prow": [(146, 60), (294, 60), (304, 74), (292, 92), (148, 92), (136, 74)],
        "port": [(30, 196), (78, 150), (98, 150), (98, 234), (42, 236), (26, 222)],
        "stern": [(118, 260), (322, 260), (322, 282), (118, 282)],
        "armour": [[(150, 84), (196, 84), (130, 176), (98, 176)], [(290, 84), (244, 84), (310, 176), (342, 176)]],
    }


def shape_jaws():
    """v8 jaws: two armoured prongs either side of a recessed bow, like a ram that bites."""
    return {
        "body": [(104, 92), (336, 92), (350, 108), (350, 250), (336, 264), (104, 264), (90, 250), (90, 108)],
        "prow": [(150, 76), (290, 76), (300, 86), (290, 100), (150, 100), (140, 86)],
        "port": [(62, 120), (98, 116), (98, 226), (66, 222), (56, 210), (56, 130)],
        "stern": [(118, 258), (322, 258), (322, 280), (118, 280)],
        "armour": [[(92, 104), (100, 40), (120, 34), (150, 74), (150, 132), (92, 140)],
                   [(348, 104), (340, 40), (320, 34), (290, 74), (290, 132), (348, 140)]],
    }


def shape_chevron():
    """v9 forward chevron: armour wings swept forward from the stern corners past the bow, a squat body inside."""
    return {
        "body": [(112, 96), (328, 96), (344, 110), (344, 250), (330, 262), (110, 262), (96, 250), (96, 110)],
        "prow": [(160, 72), (280, 72), (290, 84), (278, 100), (162, 100), (150, 84)],
        "port": [(64, 124), (98, 120), (98, 226), (68, 222), (58, 210), (58, 134)],
        "stern": [(118, 258), (322, 258), (322, 280), (118, 280)],
        "armour": [[(40, 248), (24, 220), (60, 90), (104, 54), (146, 60), (100, 120), (100, 250)],
                   [(400, 248), (416, 220), (380, 90), (336, 54), (294, 60), (340, 120), (340, 250)]],
    }


def shape_pincer():
    """v10 pincer: forward-swept armour wings grown from the body sides, carrying the sponsons; a black spine."""
    return {
        "body": [(112, 92), (328, 92), (342, 106), (342, 252), (328, 264), (112, 264), (98, 252), (98, 106)],
        "prow": [(158, 70), (282, 70), (292, 82), (280, 98), (160, 98), (148, 82)],
        "wing": [(102, 260), (46, 260), (28, 240), (40, 160), (66, 92), (96, 56), (116, 50), (122, 64), (102, 112)],
        "stern": [(118, 258), (322, 258), (322, 280), (118, 280)],
        "spine": [(196, 102), (244, 102), (250, 110), (250, 214), (244, 220), (196, 220), (190, 214), (190, 110)],
    }


def shape_pauldron():
    """v11 pauldron: the frame reads like a mech's torso from above: armoured shoulders over the sponsons, a helm
    block at the bow, chest plates, and the engine pack behind."""
    return {
        "body": [(124, 88), (316, 88), (344, 106), (340, 250), (322, 266), (118, 266), (100, 250), (96, 106)],
        "prow": [(170, 60), (270, 60), (284, 72), (280, 100), (264, 110), (176, 110), (160, 100), (156, 72)],
        "pauldron": [(104, 98), (70, 92), (40, 106), (26, 136), (28, 200), (42, 230), (72, 242), (104, 236)],
        "lame": [(106, 104), (72, 100), (48, 112), (38, 136), (106, 144)],
        "chest": [(126, 96), (162, 96), (172, 112), (172, 138), (150, 152), (108, 146), (104, 112)],
        "stern": [(126, 260), (314, 260), (314, 284), (126, 284)],
    }


def shape_pauldron2():
    """v12 pauldron, refined: faceted shoulders laid over the torso's edge and reaching forward, a torso that narrows
    to a waist, abdominal armour bands."""
    return {
        "body": [(124, 88), (316, 88), (342, 104), (338, 196), (326, 252), (310, 266), (130, 266), (114, 252), (102, 196),
                 (98, 104)],
        "prow": [(170, 58), (270, 58), (284, 70), (280, 100), (264, 110), (176, 110), (160, 100), (156, 70)],
        "pauldron": [(118, 92), (96, 78), (56, 82), (30, 104), (22, 140), (24, 196), (36, 226), (66, 242), (100, 240),
                     (118, 226)],
        "lame": [(120, 98), (98, 86), (60, 90), (40, 108), (34, 134), (120, 140)],
        "chest": [(128, 98), (164, 98), (174, 114), (174, 138), (152, 152), (124, 148)],
        "stern": [(134, 260), (306, 260), (306, 286), (134, 286)],
        "bands": [208, 226, 242],
        "over": True,
    }


SHAPES = {"v1": shape_slab, "v2": shape_hammer, "v3": shape_wedge, "v4": shape_shoulders, "v5": shape_tiered, "v6": shape_bull,
          "v7": shape_delta, "v8": shape_jaws, "v9": shape_chevron, "v10": shape_pincer, "v11": shape_pauldron, "v12": shape_pauldron2}


# ---------- builder ----------

def build(shape, loadout, title):
    s = shape()
    h = Hull(W, H, title)
    defs(h)
    code = {"hull-laser": "LAF-HL", "suit-dock": "LAF-SD"}[loadout]

    # engines: rectangular thrust ports in the stern block, glowing hot yellow-white
    xs = [146, 194, 246, 294]
    glow = "".join(f'<rect x="{x - 15}" y="281" width="30" height="16" rx="5" fill="{THRUST}" opacity=".7" filter="url(#glow)"/>'
                   f'<rect x="{x - 11}" y="279" width="22" height="4" rx="1.5" fill="#fff6dc"/>' for x in xs)
    h.raw("thrust", {5: glow})
    nozzle_det = "".join(f'<rect x="{x - 14}" y="262" width="28" height="18" rx="2" fill="{BLACK}" stroke="{INK}" stroke-width="1"/>'
                         + "".join(line(x - 11, 266 + i * 4, x + 11, 266 + i * 4, STEEL, .8, .6) for i in range(3)) for x in xs)
    h.plate("stern", P(s["stern"]), GUN_DARK, bevel=3, details=nozzle_det, gloss=False)

    # sponsons: port is plain armour with an airlock; starboard carries the loadout module
    if "wing" in s:
        return build_winged(h, s, loadout, code)
    if "pauldron" in s:
        return build_pauldron(h, s, loadout, code)
    port = s["port"]
    stbd = mirror_x(port, CX)[::-1]
    px0 = min(x for x, _ in port)
    py0, py1 = min(y for _, y in port), max(y for _, y in port)
    port_det = (seam(px0 + 6, (py0 + py1) / 2, 96, (py0 + py1) / 2, GUN_DARK)
                + f'<rect x="{px0 + 3}" y="{(py0 + py1) / 2 + 10}" width="10" height="22" rx="1.5" fill="{BLACK}" stroke="{YELLOW}" stroke-width="1.4"/>'
                + bolts([(px0 + 10, py0 + 10), (px0 + 10, py1 - 10)], GUN_DARK)
                + stencil(px0 + 20, (py0 + py1) / 2 - 12, "07", 9, rotate=-90))
    h.plate("sponson-port", P(port), GUN_DARK, bevel=4, details=port_det, shadow=4)
    sx1 = max(x for x, _ in stbd)
    if loadout == "hull-laser":
        # weapon pod: an armoured housing on the sponson with a hardpoint ring forward; the laser is separate art
        mx, my = sx1 - 16, py0 + 26
        det = (hazard([(sx1 - 30, py1 - 22), (sx1 - 2, py1 - 22), (sx1 - 2, py1 - 12), (sx1 - 30, py1 - 12)], ORANGE)
               + f'<circle cx="{mx}" cy="{my}" r="13" fill="{BLACK}" stroke="{INK}" stroke-width="1.2"/>'
               + f'<circle cx="{mx}" cy="{my}" r="9.5" fill="none" stroke="{YELLOW}" stroke-width="1.4"/>'
               + seam(sx1 - 34, py0 + 50, sx1, py0 + 50, GUN_DARK)
               + stencil(sx1 - 16, py0 + 70, "HL", 9) + bolts([(sx1 - 30, py0 + 82), (sx1 - 4, py0 + 82)], GUN_DARK))
        h.plate("sponson-starboard", P(stbd), GUN_DARK, bevel=4, details=det, shadow=4)
        h.mount("mount-hull-laser", mx, my, "DS-ST Hull Laser", "forward")
    else:
        # suit launch bay: an open hangar mouth facing outboard, hazard-framed, with a launch rail
        bx = sx1 - 30
        det = (f'<rect x="{bx}" y="{py0 + 18}" width="30" height="{py1 - py0 - 36}" fill="{BLACK}"/>'
               + hazard([(bx - 6, py0 + 12), (sx1, py0 + 12), (sx1, py0 + 18), (bx - 6, py0 + 18)])
               + hazard([(bx - 6, py1 - 18), (sx1, py1 - 18), (sx1, py1 - 12), (bx - 6, py1 - 12)])
               + line(bx + 6, (py0 + py1) / 2, sx1 + 2, (py0 + py1) / 2, YELLOW, 1.6, .9)
               + "".join(line(bx + 4 + i * 6, (py0 + py1) / 2 - 3, bx + 4 + i * 6, (py0 + py1) / 2 + 3, YELLOW, 1, .7) for i in range(5))
               + stencil(bx - 10, (py0 + py1) / 2, "EVB", 8, rotate=90))
        h.plate("sponson-starboard", P(stbd), GUN_DARK, bevel=4, details=det, shadow=4)

    return body_and_prow(h, s, code)


def body_and_prow(h, s, code):
    # main body: uniform panels on a grid, a stencilled frame code, a dark deck band
    bx0 = min(x for x, _ in s["body"])
    bx1 = max(x for x, _ in s["body"])
    det = "".join(seam(x, 106, x, 252, GUNMETAL) for x in (150, 220, 290))
    det += "".join(seam(bx0 + 6, y, bx1 - 6, y, GUNMETAL) for y in (150, 205))
    det += bolts([(x, y) for x in (124, 186, 254, 316) for y in (118, 242)], GUNMETAL)
    det += stencil(CX, 196 if s.get("bands") else 232, code, 11)
    if not s.get("bands"):
        det += stencil(CX, 176, "▲ 07", 8, opacity=.5)
    for y in s.get("bands", []):
        det += (f'<rect x="{bx0}" y="{y}" width="{bx1 - bx0}" height="9" fill="{GUN_DARK}"/>'
                + line(bx0, y, bx1, y, shade(GUNMETAL, .55), 1.2) + line(bx0, y + 9, bx1, y + 9, shade(GUNMETAL, 1.35), .8))
    det += hazard([(bx0 + 4, 255), (bx1 - 4, 255), (bx1 - 4, 261), (bx0 + 4, 261)], YELLOW, opacity=.9)
    if s.get("bands"):   # the stern airlock hatch, level with the floor plan's aft airlock
        det += (f'<rect x="262" y="243" width="20" height="11" rx="1.5" fill="{BLACK}" stroke="{ORANGE}" stroke-width="1.4"/>'
                + line(272, 244, 272, 253, ORANGE, .8, .8))
    det += f'<ellipse cx="{CX}" cy="252" rx="90" ry="14" fill="url(#scorch)" opacity=".35"/>'
    h.plate("body", P(s["body"]), GUNMETAL, bevel=5, details=det, shadow=6)

    for i, pts in enumerate(s.get("armour", [])):
        ax = sum(x for x, _ in pts) / len(pts)
        ay = sum(y for _, y in pts) / len(pts)
        det = bolts([(ax - 6, ay), (ax + 6, ay)], BLACK) + hazard(
            [(ax - 10, ay + 14), (ax + 10, ay + 14), (ax + 10, ay + 19), (ax - 10, ay + 19)], ORANGE, opacity=.9)
        h.plate(f"armour-{i}", P(pts), BLACK, bevel=4, details=det, shadow=5)

    if "spine" in s:
        sp = s["spine"]
        det = seam(178, 180, 262, 180, BLACK) + bolts([(186, 116), (254, 116), (186, 242), (254, 242)], BLACK)
        h.plate("spine", P(sp), BLACK, bevel=4, details=det, shadow=4)

    # prow: black armour with hazard chevrons on the bow edge and a narrow visor slit over the bridge
    pr = s["prow"]
    x0, x1 = min(x for x, _ in pr), max(x for x, _ in pr)
    y0, y1 = min(y for _, y in pr), max(y for _, y in pr)
    det = hazard([(x0 + 4, y0 + 1), (x1 - 4, y0 + 1), (x1 - 4, y0 + 7), (x0 + 4, y0 + 7)], YELLOW)
    if s.get("bands"):   # the helm's visor: a narrow amber slit
        det += (f'<rect x="{CX - 34}" y="{y1 - 22}" width="68" height="7" rx="2" fill="#15171b" stroke="{INK}" stroke-width="1"/>'
                f'<rect x="{CX - 30}" y="{y1 - 20}" width="60" height="3" rx="1.5" fill="{VISOR}" opacity=".95"/>'
                f'<rect x="{CX - 30}" y="{y1 - 22}" width="60" height="7" fill="{VISOR}" opacity=".45" filter="url(#glow)"/>')
    else:
        det += (f'<rect x="{CX - 30}" y="{y1 - 16}" width="60" height="7" rx="1.5" fill="{GLASS}" stroke="{INK}" stroke-width="1"/>'
                f'<rect x="{CX - 27}" y="{y1 - 15}" width="16" height="2" fill="#6e8aa6" opacity=".6"/>')
    det += bolts([(x0 + 12, y1 - 10), (x1 - 12, y1 - 10)], BLACK)
    h.plate("prow", P(pr), BLACK, bevel=4, details=det, shadow=5)
    return h


def build_winged(h, s, loadout, code):
    """The pincer frame: the swept wings are the sponsons. Port wing: the spare room and its airlock. Starboard wing:
    the loadout module over the weapon bay (rooms x 325-360, y 135-205)."""
    port = s["wing"]
    stbd = mirror_x(port, CX)[::-1]
    lead = lambda pts: [pts[3], pts[4], pts[5], pts[6], pts[7], (pts[7][0] - 8, pts[7][1] + 26), (pts[4][0] + 12, pts[4][1] + 12), (pts[3][0] + 12, pts[3][1])]
    port_det = (seam(40, 206, 100, 206, GUN_DARK) + seam(48, 132, 100, 132, GUN_DARK)
                + f'<rect x="40" y="168" width="10" height="24" rx="1.5" fill="{BLACK}" stroke="{YELLOW}" stroke-width="1.4"/>'
                + bolts([(60, 222), (88, 222), (60, 150), (88, 150)], GUN_DARK) + stencil(74, 186, "07", 9, rotate=-90)
                + hazard([(40, 248), (96, 248), (96, 254), (40, 254)], YELLOW, opacity=.85))
    h.plate("wing-port", P(port), GUN_DARK, bevel=5, details=port_det, shadow=5)
    h.plate("wing-port-edge", P(lead(port)), BLACK, bevel=3, details=bolts([(70, 112), (92, 76)], BLACK), shadow=0)
    sx1 = 2 * CX - 28
    if loadout == "hull-laser":
        mx, my = 372, 150
        det = (seam(340, 206, 400, 206, GUN_DARK) + seam(340, 132, 392, 132, GUN_DARK)
               + f'<rect x="352" y="134" width="40" height="66" rx="4" fill="{BLACK}" stroke="{INK}" stroke-width="1.2"/>'
               + f'<circle cx="{mx}" cy="{my}" r="13" fill="#15171b" stroke="{INK}" stroke-width="1.2"/>'
               + f'<circle cx="{mx}" cy="{my}" r="9.5" fill="none" stroke="{YELLOW}" stroke-width="1.4"/>'
               + hazard([(356, 186), (388, 186), (388, 194), (356, 194)], ORANGE)
               + stencil(372, 178, "DS-ST", 7) + bolts([(352, 222), (380, 222)], GUN_DARK)
               + hazard([(344, 248), (400, 248), (400, 254), (344, 254)], YELLOW, opacity=.85))
        h.plate("wing-starboard", P(stbd), GUN_DARK, bevel=5, details=det, shadow=5)
        h.mount("mount-hull-laser", mx, my, "DS-ST Hull Laser", "forward")
    else:
        det = (seam(340, 132, 392, 132, GUN_DARK)
               + f'<path d="M352,140 H{sx1 + 6} V214 H352 Z" fill="#121418"/>'
               + "".join(line(356, y, sx1 + 2, y, "#2b2f35", 1) for y in (152, 164, 190, 202))
               + hazard([(348, 134), (sx1 + 8, 134), (sx1 + 8, 140), (348, 140)])
               + hazard([(348, 214), (sx1 + 8, 214), (sx1 + 8, 220), (348, 220)])
               + line(358, 177, sx1 + 8, 177, YELLOW, 1.8, .9)
               + "".join(line(362 + i * 7, 173, 362 + i * 7, 181, YELLOW, 1, .7) for i in range(6))
               + stencil(346, 177, "EVB", 7, rotate=90) + bolts([(352, 230), (380, 230)], GUN_DARK)
               + hazard([(344, 248), (400, 248), (400, 254), (344, 254)], YELLOW, opacity=.85))
        h.plate("wing-starboard", P(stbd), GUN_DARK, bevel=5, details=det, shadow=5)
    h.plate("wing-starboard-edge", P(mirror_x(lead(port), CX)[::-1]), BLACK, bevel=3,
            details=bolts([(370, 112), (348, 76)], BLACK), shadow=0)
    return body_and_prow(h, s, code)


def build_pauldron(h, s, loadout, code):
    """Shoulders: port carries the spare room and its airlock; starboard the loadout module over the weapon bay."""
    pd = s["pauldron"]
    lame = s["lame"]
    if s.get("over"):
        body_and_prow(h, s, code)
    port_det = (seam(30, 190, 100, 190, GUN_DARK) + seam(32, 160, 100, 160, GUN_DARK)
                + f'<rect x="32" y="166" width="10" height="20" rx="1.5" fill="{BLACK}" stroke="{YELLOW}" stroke-width="1.4"/>'
                + bolts([(52, 220), (88, 226), (50, 150), (90, 150)], GUN_DARK) + stencil(70, 176, "07", 10, rotate=-90)
                + hazard([(40, 226), (100, 232), (100, 238), (44, 232)], YELLOW, opacity=.85))
    h.plate("pauldron-port", P(pd), GUN_DARK, bevel=5, details=port_det, shadow=6)
    h.plate("lame-port", P(lame), BLACK, bevel=3, shadow=3,
            details=hazard([(52, 110), (72, 104), (74, 110), (56, 116)], ORANGE) + bolts([(80, 130), (98, 130)], BLACK))
    spd = mirror_x(pd, CX)[::-1]
    slame = mirror_x(lame, CX)[::-1]
    if loadout == "hull-laser":
        # a shoulder hardpoint: the pod's housing and ring on the starboard shoulder, the laser itself separate art
        mx, my = 378, 178
        det = (seam(340, 160, 410, 160, GUN_DARK)
               + f'<rect x="354" y="152" width="48" height="62" rx="5" fill="{BLACK}" stroke="{INK}" stroke-width="1.2"/>'
               + f'<circle cx="{mx}" cy="{my}" r="14" fill="#15171b" stroke="{INK}" stroke-width="1.2"/>'
               + f'<circle cx="{mx}" cy="{my}" r="10" fill="none" stroke="{YELLOW}" stroke-width="1.5"/>'
               + hazard([(358, 200), (398, 200), (398, 208), (358, 208)], ORANGE)
               + stencil(378, 228, "DS-ST", 7) + bolts([(352, 226), (390, 232)], GUN_DARK)
               + hazard([(340, 232), (400, 226), (396, 232), (340, 238)], YELLOW, opacity=.85))
        h.plate("pauldron-starboard", P(spd), GUN_DARK, bevel=5, details=det, shadow=6)
        h.mount("mount-hull-laser", mx, my, "DS-ST Hull Laser", "forward")
    else:
        # the suit bay: an open hangar mouth through the shoulder's outer face, hazard-framed, with a launch rail
        det = (f'<path d="M352,152 H414 V208 H352 Z" fill="#121418"/>'
               + "".join(line(356, y, 412, y, "#2b2f35", 1) for y in (162, 172, 188, 198))
               + hazard([(348, 146), (416, 146), (416, 152), (348, 152)])
               + hazard([(348, 208), (416, 208), (416, 214), (348, 214)])
               + line(360, 180, 416, 180, YELLOW, 1.8, .9)
               + "".join(line(364 + i * 8, 176, 364 + i * 8, 184, YELLOW, 1, .7) for i in range(6))
               + stencil(346, 180, "EVB", 7, rotate=90) + bolts([(352, 226), (390, 232)], GUN_DARK)
               + hazard([(340, 232), (400, 226), (396, 232), (340, 238)], YELLOW, opacity=.85))
        h.plate("pauldron-starboard", P(spd), GUN_DARK, bevel=5, details=det, shadow=6)
    h.plate("lame-starboard", P(slame), BLACK, bevel=3, shadow=3,
            details=hazard([(388, 110), (368, 104), (366, 110), (384, 116)], ORANGE) + bolts([(360, 130), (342, 130)], BLACK))
    if not s.get("over"):
        body_and_prow(h, s, code)
    for side, pts in (("port", s["chest"]), ("starboard", mirror_x(s["chest"], CX)[::-1])):
        cx_ = sum(x for x, _ in pts) / len(pts)
        h.plate(f"chest-{side}", P(pts), BLACK, bevel=3, shadow=3,
                details=bolts([(cx_ - 8, 108), (cx_ + 8, 108)], BLACK) + seam(cx_ - 14, 128, cx_ + 14, 128, BLACK))
    return h


LOADOUTS = ("hull-laser", "suit-dock")

if __name__ == "__main__":
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    for name in sys.argv[2:] or list(SHAPES):
        for lo in LOADOUTS:
            hull = build(SHAPES[name], lo, f"Mecha Light Attack Frame, {lo.replace('-', ' ')}")
            base = f"{name}-{lo}"
            open(os.path.join(out, f"{base}.svg"), "w").write(hull.svg(5))
            open(os.path.join(out, f"{base}-mounts.svg"), "w").write(hull.svg(5, show_mounts=True))
            for st in range(1, 6):
                open(os.path.join(out, f"{base}-stage{st}.svg"), "w").write(
                    hull.svg(st, background="#ffffff" if st == 1 else None))
        print("built", name)
