"""Mecha Light Attack Frame, built around the battle-cross room plan (heromedel's pick): the B style (horns, raked
cleavers, a console-like spine, an engine block) fitted to this ship's own rooms.

Usage: python3 hull_l1.py OUT_DIR
Writes hull.svg (one hull for both loadouts; mounts are hidden data, the weapon art marks them), mounts.svg (the
planned mounts marked) and rooms.svg (the rooms outlined over the hull).
"""
import os, sys
import pixel_kit as pk
from pixel_kit import Canvas, OUTLINE, SHADOW, DARK, ARMOUR, EDGE, TONES, PURPLE, DEEP, PALE

pk.W, pk.H = 340, 300            # sized to this ship's rooms, not the old frame's
W, H, CX, T = pk.W, pk.H, 170, 35
X0, Y0 = CX - 3 * T, 72
# the battle cross: (name, col, row, w, h)
ROOMS = [("Command deck", 2, 0, 2, 2), ("Second bay", 0, 1, 2, 2), ("Weapon bay", 4, 1, 2, 2),
         ("Servicing Core", 2, 2, 2, 2), ("Engine room", 2, 4, 2, 1)]
pk.ROOMS = [(X0 + c * T, Y0 + r * T, X0 + (c + w) * T, Y0 + (r + h) * T) for _, c, r, w, h in ROOMS]


def mirror(pts):
    return [(W - x, y) for x, y in pts][::-1]


def cleaver(c, pts, ridge, base=ARMOUR, shadow=4):
    """A straight-edged plate split by its ridge into a lit and a darker facet (as in B)."""
    c.part(pts, base, shadow=shadow, bevel=1)
    (rx0, ry0), (rx1, ry1) = ridge
    for side in (1, -1):
        m = c.mask(pts if side > 0 else mirror(pts))
        for (x, y) in m:
            xx = x if side > 0 else W - 1 - x
            col = c.px.get((x, y))
            if col in (ARMOUR, EDGE, DARK) and (rx1 - rx0) * (y - ry0) - (ry1 - ry0) * (xx - rx0) > 0:
                c.px[(x, y)] = TONES[max(1, TONES.index(col) - 1)]
        n = int(max(abs(rx1 - rx0), abs(ry1 - ry0)))
        for i in range(n):
            x, y = round(rx0 + (rx1 - rx0) * i / n), round(ry0 + (ry1 - ry0) * i / n)
            if side < 0:
                x = W - 1 - x
            if (x, y) in m and c.px.get((x, y)) != OUTLINE:
                c.px[(x, y)] = EDGE


def slit(c, x0, y0, x1, y1, both=False):
    for s in ((1, -1) if both else (1,)):
        for y in range(y0, y1):
            for x in range(x0, x1):
                xx = x if s > 0 else W - 1 - x
                c.px[(xx, y)] = PALE if (x0 < x < x1 - 1 and y0 < y < y1 - 1) else PURPLE


def lights(c, a, b, n):
    (x0, y0), (x1, y1) = a, b
    for i in range(n):
        t = i / max(n - 1, 1)
        x, y = round(x0 + (x1 - x0) * t), round(y0 + (y1 - y0) * t)
        for xx in (x, W - 1 - x - 3):
            for j in range(4):
                c.px[(xx + j, y)] = PALE if j in (1, 2) else PURPLE
                c.px[(xx + j, y + 1)] = PURPLE
                c.px[(xx + j, y + 2)] = DEEP


def build():
    c = Canvas()
    c.gap([(150, 66), (60, 96), (52, 186), (110, 252), (150, 262)])
    # aft blades: over the Core's flanks and the engine room, raked to the stern
    cleaver(c, [(150, 176), (92, 182), (58, 214), (50, 262), (58, 294), (70, 282), (74, 266), (80, 266), (80, 256),
                (90, 256), (112, 236), (150, 252)], ((150, 214), (58, 290)), DARK)
    # main cleavers: over the flank bays, raked aft to a point
    cleaver(c, [(150, 96), (100, 98), (58, 102), (24, 128), (12, 184), (16, 236), (26, 244), (30, 222), (34, 196),
                (44, 188), (50, 188), (50, 180), (60, 180), (82, 184), (150, 184)], ((150, 130), (14, 234)))
    # horns: from the shoulders forward past the prow
    cleaver(c, [(150, 64), (124, 66), (78, 4), (66, 8), (70, 22), (92, 82), (92, 92), (106, 102), (150, 104)],
            ((150, 86), (72, 8)), DARK)
    # engine block at the stern, under the engine room
    c.part([(170, 236), (140, 240), (132, 270), (142, 296), (170, 296)], DARK, shadow=3, bevel=1)
    for x0 in (146, 158):
        slit(c, x0, 272, x0 + 4, 288, both=True)
    # the spine, drawn like the console's tower
    c.part([(158, 52), (182, 52), (194, 66), (196, 236), (186, 262), (154, 262), (144, 236), (146, 66)], DARK,
           both=False, shadow=4, bevel=1)
    c.panel([(158, 108), (182, 108), (188, 116), (188, 150), (152, 150), (152, 116)], both=False)
    slit(c, 160, 142, 181, 145)
    for y in range(168, 240, 20):
        c.seam((148, y), (192, y), both=False)
    # the prow: two ridged armour plates meeting at a point over the command deck
    cleaver(c, [(170, 2), (170, 100), (144, 96), (132, 62), (150, 22)], ((170, 12), (140, 84)), DARK)
    slit(c, 164, 40, 177, 43)
    lights(c, (128, 84), (98, 50), 3)
    lights(c, (120, 132), (34, 160), 6)
    lights(c, (124, 202), (70, 232), 4)
    return c


# planned mounts (art rules: 4-6), invisible, on the hull's outer edge: a weapon slides out past the edge when armed.
# (row, the hull row it sits on); odd numbers port, even starboard. 3 and 4 sit level with the flank bays, so 4 takes
# the Hull Laser.
MOUNT_ROWS = [("horn", 44), ("cleaver", 150), ("aft blade", 270)]


def mounts(c):
    """Find each mount on the silhouette's outer edge at its row, 3 px in from the edge, sliding outward."""
    out = []
    for _, y in MOUNT_ROWS:
        xs = [x for (x, yy) in c.px if yy == y]
        out += [(min(xs) + 3, y, "left"), (max(xs) - 3, y, "right")]
    return out


def doc(c, extra=""):
    data = "".join(f'<circle id="mount-{i + 1}" cx="{x}" cy="{y}" r="7" data-slide="{sl}"/>'
                   for i, (x, y, sl) in enumerate(mounts(c)))
    return pk.svg(c).replace("</svg>", f'<g id="weapon-mounts" display="none">{data}</g>{extra}</svg>')


def marks(c):
    out = []
    for i, (x, y, sl) in enumerate(mounts(c)):
        col = "#ffd040" if i == 3 else "#7fd9ff"
        d = -1 if sl == "left" else 1
        out.append(f'<circle cx="{x}" cy="{y}" r="5" fill="none" stroke="{col}" stroke-width="1.3"/>'
                   f'<path d="M{x + d * 6},{y} h{d * 14} m{-d * 5},-4 l{d * 5},4 l{-d * 5},4" fill="none" stroke="{col}" stroke-width="1.3"/>'
                   f'<text x="{x - d * 14}" y="{y + 4}" text-anchor="middle" font-family="sans-serif" font-size="9" fill="{col}" '
                   f'stroke="#141a22" stroke-width="2" paint-order="stroke">{i + 1}</text>')
    return "".join(out)


if __name__ == "__main__":
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    c = build()
    print("rooms uncovered (5 px margin):", pk.uncovered(c))
    open(os.path.join(out, "hull.svg"), "w").write(doc(c))
    open(os.path.join(out, "mounts.svg"), "w").write(doc(c, marks(c)))
    open(os.path.join(out, "rooms.svg"), "w").write(pk.svg(c, True))
