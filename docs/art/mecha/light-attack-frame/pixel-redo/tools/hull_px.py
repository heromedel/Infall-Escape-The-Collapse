"""Mecha frame hull, round 6: the horns-and-cleavers design (heromedel's pick) given a ship's shape: a pointed armoured
prow, a fuselage spine, an engine block at the stern, and planned weapon mounts.

Usage: python3 hull_px.py OUT_DIR [s1 s2]   (s1 is version A, s2 version B)
"""
import os, sys
from pixel_kit import Canvas, mirror, svg, uncovered, W, H, OUTLINE, SHADOW, DARK, ARMOUR, EDGE, TONES, PURPLE, DEEP, PALE
from cleavers import lights_along


def cleaver(c, pts, ridge, base=ARMOUR, shadow=4, both=True):
    """A straight-edged plate split by its ridge into two facets (the shading heromedel picked)."""
    c.part(pts, base, both=both, shadow=shadow, bevel=1)
    (rx0, ry0), (rx1, ry1) = ridge
    for side in ([1, -1] if both else [1]):
        m = c.mask(pts if side > 0 else mirror(pts))
        for (x, y) in m:
            xx = x if side > 0 else W - 1 - x
            cross = (rx1 - rx0) * (y - ry0) - (ry1 - ry0) * (xx - rx0)
            col = c.px.get((x, y))
            if col in (ARMOUR, EDGE, DARK) and cross > 0:
                c.px[(x, y)] = TONES[max(1, TONES.index(col) - 1)]
        n = int(max(abs(rx1 - rx0), abs(ry1 - ry0)))
        for i in range(n):
            x = round(rx0 + (rx1 - rx0) * i / n)
            y = round(ry0 + (ry1 - ry0) * i / n)
            if side < 0:
                x = W - 1 - x
            if (x, y) in m and c.px.get((x, y)) != OUTLINE:
                c.px[(x, y)] = EDGE


def slit(c, x0, y0, x1, y1, both=False):
    for s in ([1, -1] if both else [1]):
        for y in range(y0, y1):
            for x in range(x0, x1):
                xx = x if s > 0 else W - 1 - x
                c.px[(xx, y)] = PALE if (x0 < x < x1 - 1 and y0 < y < y1 - 1) else PURPLE


def spine(c, prow_y=6, stern_y=326, long_prow=False):
    """The fuselage: a pointed prow of two armour plates, the tower (like the console's) down the middle, an engine
    block at the stern with purple vents."""
    # stern engine block
    eng = [(220, 262), (176, 268), (168, 300), (180, stern_y), (220, stern_y)]
    c.part(eng, DARK, shadow=3, bevel=1)
    for x0 in (186, 202):
        slit(c, x0, 300, x0 + 5, 318, both=True)
    # tower
    t = [(208, 40), (232, 40), (246, 58), (248, 262), (238, 290), (202, 290), (192, 262), (194, 58)]
    c.part(t, DARK, both=False, shadow=4, bevel=1)
    c.panel([(208, 104), (232, 104), (238, 112), (238, 150), (202, 150), (202, 112)], both=False)
    slit(c, 210, 140, 231, 143)
    for y in range(170, 256, 21):
        c.seam((196, y), (244, y), both=False)
    # prow: two armour plates meeting at a point, ridged
    p = [(220, prow_y), (220, 104), (192, 100), (180, 70), (196, 34)] if not long_prow else \
        [(220, prow_y), (220, 104), (190, 100), (176, 66), (200, 24)]
    cleaver(c, p, ((220, prow_y + 10), (188, 86)), DARK)
    slit(c, 214, 46, 227, 49)          # the bow slit, like the console's


def plan_marks(c, marks):
    """Planning overlay: a ring at each planned mount."""
    out = []
    for x, y, col in marks:
        out.append(f'<circle cx="{x}" cy="{y}" r="7" fill="none" stroke="{col}" stroke-width="1.5"/>'
                   f'<circle cx="{x}" cy="{y}" r="1.5" fill="{col}"/>')
    return "".join(out)


def s1(c):
    """Horns and cleavers on a spine: horns frame the prow, cleavers raked aft, the engine block between the aft blades."""
    c.gap([(196, 76), (100, 90), (70, 130), (64, 214), (100, 256), (196, 270)])
    aft = [(196, 182), (96, 186), (50, 232), (44, 290), (52, 326), (64, 312), (70, 294), (76, 294), (76, 284), (86, 284),
           (118, 262), (196, 266)]
    cleaver(c, aft, ((196, 224), (50, 322)), DARK)
    main = [(196, 112), (96, 118), (40, 134), (8, 178), (4, 254), (12, 266), (20, 252), (26, 218), (38, 200), (44, 200),
            (44, 192), (54, 192), (80, 190), (196, 190)]
    cleaver(c, main, ((196, 152), (6, 256)))
    horn = [(196, 74), (150, 78), (66, 14), (54, 20), (60, 32), (100, 92), (100, 100), (118, 112), (196, 120)]
    cleaver(c, horn, ((196, 98), (58, 18)), DARK)
    lights_along(c, (150, 92), (106, 74), 4)
    lights_along(c, (150, 152), (44, 178), 6)
    lights_along(c, (150, 226), (86, 250), 4)
    spine(c)


def s2(c):
    """Mandibles: longer horns reaching past a long prow, cleavers raked further aft."""
    c.gap([(196, 76), (100, 90), (70, 130), (64, 214), (100, 256), (196, 270)])
    aft = [(196, 186), (100, 190), (60, 240), (60, 300), (70, 328), (82, 314), (86, 296), (92, 296), (92, 286), (102, 286),
           (124, 264), (196, 268)]
    cleaver(c, aft, ((196, 228), (66, 324)), DARK)
    main = [(196, 116), (100, 120), (44, 140), (14, 190), (14, 280), (24, 290), (30, 270), (34, 226), (46, 206), (52, 206),
            (52, 198), (62, 198), (86, 194), (196, 194)]
    cleaver(c, main, ((196, 156), (16, 282)))
    horn = [(196, 74), (156, 78), (96, 4), (84, 8), (88, 22), (112, 90), (112, 100), (126, 112), (196, 120)]
    cleaver(c, horn, ((196, 98), (90, 8)), DARK)
    lights_along(c, (154, 92), (118, 50), 4)
    lights_along(c, (150, 156), (40, 196), 6)
    lights_along(c, (150, 230), (90, 256), 4)
    spine(c, prow_y=2, long_prow=True)


def hardpoint(c, x, y):
    """A weapon hardpoint: a raised octagonal socket, a dark ring and a purple glint (the weapon is separate art)."""
    r, k = 9, 4
    c.part([(x - k, y - r), (x + k, y - r), (x + r, y - k), (x + r, y + k), (x + k, y + r), (x - k, y + r), (x - r, y + k),
            (x - r, y - k)], DARK, both=False, shadow=2, bevel=1)
    for yy in range(y - 5, y + 6):
        for xx in range(x - 5, x + 6):
            d = ((xx - x) ** 2 + (yy - y) ** 2) ** .5
            if d < 5.5:
                c.px[(xx, yy)] = OUTLINE if d > 3.5 else SHADOW
    c.px[(x, y)] = PURPLE
    c.px[(x - 1, y - 4)] = c.px[(x + 1, y - 4)] = DEEP


def suit_bay(c, x, y):
    """The suit launch bay: a recessed mouth through the starboard blade, guide lights down both sides, a launch rail
    running out to the bay mouth."""
    x0, y0, x1, y1 = x - 16, y - 13, x + 22, y + 11
    for yy in range(y0, y1):
        for xx in range(x0, x1):
            edge = xx in (x0, x1 - 1) or yy in (y0, y1 - 1)
            c.px[(xx, yy)] = OUTLINE if edge else (SHADOW if yy < y0 + 3 else OUTLINE)
    for xx in range(x0 + 3, x1 - 2, 4):
        for yy in (y0 + 2, y1 - 3):
            c.px[(xx, yy)] = PURPLE
            c.px[(xx + 1, yy)] = DEEP
    for xx in range(x0 + 2, x1 + 6):
        c.px[(xx, y - 1)] = DARK
        c.px[(xx, y)] = EDGE if xx % 5 else ARMOUR
        c.px[(xx, y + 1)] = OUTLINE


LOADOUTS = {"hull-laser": lambda c, name: hardpoint(c, *MOUNTS[name][1]),
            "suit-dock": lambda c, name: suit_bay(c, *BAY[name])}

VARIANTS = {"s1": s1, "s2": s2}
# planned mounts (starboard is the right of the image, nose up)
MOUNTS = {"s1": [(134, 96), (306, 96), (58, 150), (382, 150), (80, 240), (360, 240)],
          "s2": [(144, 96), (296, 96), (62, 156), (378, 156), (92, 246), (348, 246)]}
BAY = {"s1": (372, 196), "s2": (364, 200)}


def plan_marks(c, marks, bay):
    out = []
    for i, (x, y) in enumerate(marks):
        col = "#ffd040" if i == 1 else "#7fd9ff"
        out.append(f'<circle cx="{x}" cy="{y}" r="7" fill="none" stroke="{col}" stroke-width="1.5"/>'
                   f'<text x="{x + 9}" y="{y + 4}" font-family="sans-serif" font-size="10" fill="{col}" '
                   f'stroke="#141a22" stroke-width="2" paint-order="stroke">{i + 1}</text>')
    x, y = bay
    out.append(f'<rect x="{x - 7}" y="{y - 7}" width="14" height="14" fill="none" stroke="#ff7fd0" stroke-width="1.5"/>')
    return "".join(out)


if __name__ == "__main__":
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    for name in sys.argv[2:] or VARIANTS:
        c = Canvas()
        VARIANTS[name](c)
        print(name, "uncovered:", uncovered(c))
        base = svg(c)
        # weapon mounts are invisible spots stored as data (art rules); 2 takes the Hull Laser in that loadout
        data = "".join(f'<circle id="mount-{i + 1}" cx="{x}" cy="{y}" r="7"/>' for i, (x, y) in enumerate(MOUNTS[name]))
        bx, by = BAY[name]
        data += f'<rect id="suit-bay" x="{bx - 7}" y="{by - 7}" width="14" height="14"/>'
        base = base.replace("</svg>", f'<g id="weapon-mounts" display="none">{data}</g></svg>')
        open(os.path.join(out, f"{name}.svg"), "w").write(base)
        open(os.path.join(out, f"{name}-mounts.svg"), "w").write(base.replace("</svg>", plan_marks(c, MOUNTS[name], BAY[name]) + "</svg>"))
        open(os.path.join(out, f"{name}-rooms.svg"), "w").write(svg(c, True))
        if name == "s2":   # heromedel picked B: build its two loadouts
            for lo, add in LOADOUTS.items():
                c = Canvas()
                VARIANTS[name](c)
                add(c, name)
                open(os.path.join(out, f"{name}-{lo}.svg"), "w").write(svg(c).replace("</svg>", f'<g id="weapon-mounts" display="none">{data}</g></svg>'))
