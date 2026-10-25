"""Mecha frame hull, round 5: wide straight-edged cleaver plates, ridged into a lit and a dark facet, sharp tips.

Usage: python3 cleavers.py OUT_DIR [v13 v14 v15]  (earlier hull versions, kept for the record)
"""
import os, sys
from pixel_kit import Canvas, mirror, tower, svg, uncovered, W, H, OUTLINE, SHADOW, DARK, ARMOUR, EDGE, TONES, PURPLE, DEEP, PALE


def cleaver(c, pts, ridge, base=ARMOUR, shadow=4, both=True):
    """A straight-edged plate; the part beyond the ridge line (away from the light) is a shade darker."""
    c.part(pts, base, both=both, shadow=shadow, bevel=1)
    (rx0, ry0), (rx1, ry1) = ridge
    for side in ([1, -1] if both else [1]):
        m = c.mask(pts if side > 0 else mirror(pts))
        for (x, y) in m:
            xx = x if side > 0 else W - 1 - x
            ridge_y = ry0 + (ry1 - ry0) * (xx - rx0) / (rx1 - rx0)
            col = c.px.get((x, y))
            if col in (ARMOUR, EDGE, DARK) and y > ridge_y:   # the facet below the ridge faces away from the light
                c.px[(x, y)] = TONES[max(1, TONES.index(col) - 1)]
        # the ridge itself: a lit line
        n = int(max(abs(rx1 - rx0), abs(ry1 - ry0)))
        for i in range(n):
            x = round(rx0 + (rx1 - rx0) * i / n)
            y = round(ry0 + (ry1 - ry0) * i / n)
            if side < 0:
                x = W - 1 - x
            if (x, y) in m and c.px.get((x, y)) != OUTLINE:
                c.px[(x, y)] = EDGE


def lights_along(c, a, b, n, both=True):
    (x0, y0), (x1, y1) = a, b
    for i in range(n):
        t = i / max(n - 1, 1)
        x, y = round(x0 + (x1 - x0) * t), round(y0 + (y1 - y0) * t)
        for s in ([1, -1] if both else [1]):
            xx = x if s > 0 else W - 1 - x - 3
            for j in range(4):
                c.px[(xx + j, y)] = PALE if j in (1, 2) else PURPLE
                c.px[(xx + j, y + 1)] = PURPLE
                c.px[(xx + j, y + 2)] = DEEP


def v13(c):
    """Three cleavers each side: forward, outward and aft, bow ones over aft ones."""
    c.gap([(196, 76), (100, 90), (70, 130), (64, 214), (100, 256), (196, 262)])
    lower = [(196, 198), (82, 204), (60, 236), (30, 300), (22, 324), (40, 316), (52, 302), (58, 304), (72, 288), (72, 280),
             (82, 280), (104, 258), (196, 258)]
    cleaver(c, lower, ((196, 228), (24, 320)), DARK)
    mid = [(196, 134), (64, 136), (2, 166), (0, 182), (10, 190), (22, 186), (20, 196), (40, 200), (40, 206), (54, 206),
           (64, 212), (196, 214)]
    cleaver(c, mid, ((196, 176), (2, 176)))
    upper = [(196, 72), (120, 76), (12, 52), (4, 60), (14, 72), (40, 92), (36, 100), (60, 118), (60, 126), (72, 126),
             (90, 140), (196, 150)]
    cleaver(c, upper, ((196, 112), (8, 58)), DARK)
    lights_along(c, (150, 100), (60, 92), 5)
    lights_along(c, (150, 160), (40, 168), 5)
    lights_along(c, (150, 236), (70, 262), 5)
    tower(c)


def v14(c):
    """Two great cleavers each side raked aft, a forward horn plate at each bow corner."""
    c.gap([(196, 76), (100, 90), (70, 130), (64, 214), (100, 256), (196, 262)])
    aft = [(196, 176), (90, 180), (40, 230), (34, 290), (40, 324), (54, 310), (60, 292), (66, 292), (66, 282), (76, 282),
           (110, 260), (196, 262)]
    cleaver(c, aft, ((196, 220), (40, 320)), DARK)
    main = [(196, 110), (96, 116), (40, 132), (4, 176), (0, 250), (8, 262), (16, 248), (22, 214), (34, 196), (40, 196),
            (40, 188), (50, 188), (76, 186), (196, 186)]
    cleaver(c, main, ((196, 150), (2, 252)))
    horn = [(196, 70), (140, 74), (50, 16), (40, 22), (46, 34), (90, 92), (90, 100), (110, 112), (196, 120)]
    cleaver(c, horn, ((196, 96), (44, 20)), DARK)
    lights_along(c, (156, 92), (100, 76), 4)
    lights_along(c, (150, 150), (40, 176), 6)
    lights_along(c, (150, 222), (80, 244), 4)
    tower(c)


def v15(c):
    """Swept cleavers: three plates each side, all raked aft and stacked like a folded blade fan, points out."""
    c.gap([(196, 76), (100, 90), (70, 130), (64, 214), (100, 256), (196, 262)])
    for pts, ridge, base in [
            ([(196, 200), (100, 204), (64, 250), (56, 324), (70, 318), (78, 298), (84, 298), (84, 288), (96, 288), (116, 262), (196, 262)],
             ((196, 230), (58, 322)), DARK),
            ([(196, 140), (80, 144), (24, 200), (6, 262), (20, 262), (30, 238), (36, 238), (36, 230), (46, 230), (70, 212), (196, 212)],
             ((196, 176), (8, 260)), ARMOUR),
            ([(196, 72), (110, 78), (30, 110), (2, 150), (4, 168), (18, 160), (40, 146), (40, 140), (52, 140), (90, 150), (196, 150)],
             ((196, 110), (4, 160)), DARK)]:
        cleaver(c, pts, ridge, base)
    lights_along(c, (150, 96), (60, 112), 5)
    lights_along(c, (150, 166), (60, 196), 5)
    lights_along(c, (150, 236), (90, 266), 4)
    tower(c)


VARIANTS = {"v13": v13, "v14": v14, "v15": v15}
if __name__ == "__main__":
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    for name in sys.argv[2:] or VARIANTS:
        c = Canvas()
        VARIANTS[name](c)
        print(name, "uncovered:", uncovered(c))
        open(os.path.join(out, f"{name}.svg"), "w").write(svg(c))
        open(os.path.join(out, f"{name}-rooms.svg"), "w").write(svg(c, True))
