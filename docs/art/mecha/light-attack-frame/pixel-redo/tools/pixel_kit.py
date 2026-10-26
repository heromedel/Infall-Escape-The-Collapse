"""Pixel kit for the Mecha frame redo: canvas, per-pixel plate shading, panels, seams, machinery gaps, light slits
and the console-like tower, plus three earlier hull versions.

Usage: python3 pixel_kit.py OUT_DIR [v7 v8 v9]  (earlier hull versions, kept for the record)
"""
import math, os, random, sys
from PIL import Image, ImageDraw
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pixel_svg import paths  # noqa: E402

W, H, CX = 440, 330, 220
OUTLINE, SHADOW, DARK, ARMOUR, EDGE = "#0a0a0e", "#1c1d24", "#2e3039", "#4a4d5a", "#7a7f8e"
TONES = [OUTLINE, SHADOW, DARK, ARMOUR, EDGE]
PURPLE, DEEP, PALE = "#aa28eb", "#5a128c", "#ebe1fa"
ROOMS = [(115, 100, 325, 135), (80, 135, 360, 205), (115, 205, 325, 240)]


def mirror(pts):
    return [(W - x, y) for x, y in pts][::-1]


class Canvas:
    def __init__(self, seed=3):
        self.px = {}
        self.rnd = random.Random(seed)
        self.cover = set()

    def mask(self, pts):
        im = Image.new("1", (W, H))
        ImageDraw.Draw(im).polygon(pts, fill=1)
        return {(x, y) for y in range(H) for x in range(W) if im.getpixel((x, y))}

    def shade(self, m, base, bevel=2, recessed=False, grit=(.12, .955)):
        bi = TONES.index(base)
        for (x, y) in m:
            nb = lambda dx, dy: (x + dx, y + dy) in m
            if not (nb(1, 0) and nb(-1, 0) and nb(0, 1) and nb(0, -1)):
                self.px[(x, y)] = OUTLINE
                continue
            t = bi
            lit = any(not nb(-i, 0) or not nb(0, -i) or not nb(-i, -i) for i in range(1, bevel + 1))
            dim = any(not nb(i, 0) or not nb(0, i) or not nb(i, i) for i in range(1, bevel + 1))
            if recessed:
                lit, dim = dim, lit
            first = not (nb(-1, 0) and nb(0, -1)) if not recessed else not (nb(1, 0) and nb(0, 1))
            if lit and not dim:
                t += 2 if first else 1
            elif dim and not lit:
                t -= 1
            r = self.rnd.random()
            t += -1 if r < grit[0] else (1 if r > grit[1] else 0)
            self.px[(x, y)] = TONES[max(0, min(4, t))]

    def drop(self, m, d=3):
        for x, y in m:
            p = (x + d, y + d)
            if p in self.px and p not in m:
                c = self.px[p]
                if c in TONES:
                    self.px[p] = TONES[max(0, TONES.index(c) - 2)]

    def part(self, pts, base, both=True, shadow=3, **kw):
        ms = []
        for p in ([pts, mirror(pts)] if both else [pts]):
            m = self.mask(p)
            if shadow:
                self.drop(m, shadow)
            self.shade(m, base, **kw)
            self.cover |= m
            ms.append(m)
        return ms

    def panel(self, pts, base=SHADOW, both=True):
        for p in ([pts, mirror(pts)] if both else [pts]):
            self.shade(self.mask(p), base, bevel=1, recessed=True)

    def seam(self, a, b, both=True):
        (x0, y0), (x1, y1) = a, b
        n = max(abs(x1 - x0), abs(y1 - y0))
        for s in ([1, -1] if both else [1]):
            for i in range(n + 1):
                x = round(x0 + (x1 - x0) * i / n)
                y = round(y0 + (y1 - y0) * i / n)
                if s < 0:
                    x = W - 1 - x
                if (x, y) in self.px and self.rnd.random() > .08:
                    self.px[(x, y)] = SHADOW
                    if (x, y + 1) in self.px and self.px[(x, y + 1)] != OUTLINE:
                        self.px[(x, y + 1)] = EDGE if self.rnd.random() > .4 else ARMOUR

    def gap(self, pts, both=True):
        rnd = random.Random(11)
        blocks = [(rnd.randint(0, W // 2), rnd.randint(0, H), rnd.randint(4, 12), rnd.randint(3, 8)) for _ in range(160)]
        for p in ([pts, mirror(pts)] if both else [pts]):
            m = self.mask(p)
            for (x, y) in m:
                self.px[(x, y)] = OUTLINE
                self.cover.add((x, y))
            for bx, by, bw, bh in blocks:
                if p is not pts:
                    bx = W - bx - bw
                for y in range(by, by + bh):
                    for x in range(bx, bx + bw):
                        if (x, y) in m:
                            edge = x in (bx, bx + bw - 1) or y in (by, by + bh - 1)
                            self.px[(x, y)] = OUTLINE if edge else (DARK if y == by + 1 else SHADOW)
            for _ in range(10):   # a few deep purple conduits glinting between the plates
                x0, y0 = rnd.randint(0, W // 2), rnd.randint(0, H)
                if p is not pts:
                    x0 = W - x0
                for i in range(rnd.randint(4, 10)):
                    if (x0, y0 + i) in m:
                        self.px[(x0, y0 + i)] = DEEP

    def lights(self, a, b, n, length=4, both=True):
        """A row of n light slits along the line a-b, each a short dash along the line."""
        (x0, y0), (x1, y1) = a, b
        L = math.hypot(x1 - x0, y1 - y0)
        ux, uy = (x1 - x0) / L, (y1 - y0) / L
        for s in ([1, -1] if both else [1]):
            for i in range(n):
                t = i / max(n - 1, 1)
                for j in range(length):
                    x = round(x0 + (x1 - x0) * t + ux * j)
                    y = round(y0 + (y1 - y0) * t + uy * j)
                    if s < 0:
                        x = W - 1 - x
                    self.px[(x, y)] = PALE if j in (1, 2) else PURPLE
                    self.px[(x, y + 1)] = PURPLE
                    if self.px.get((x, y + 2)) not in (PURPLE, PALE):
                        self.px[(x, y + 2)] = DEEP


def tower(c, y0=30, y1=304):
    """The spine, drawn like the console's tower: a narrow dark column, a recessed screen, a purple slit at its base."""
    t = [(208, y0), (232, y0), (244, y0 + 16), (246, y1 - 30), (234, y1), (206, y1), (194, y1 - 30), (196, y0 + 16)]
    c.part(t, DARK, both=False, shadow=4)
    c.panel([(209, y0 + 12), (231, y0 + 12), (236, y0 + 22), (236, y0 + 70), (204, y0 + 70), (204, y0 + 22)], both=False)
    for x in range(210, 231):
        c.px[(x, y0 + 58)] = PURPLE
        c.px[(x, y0 + 59)] = DEEP
    for x in range(216, 225):
        c.px[(x, y0 + 58)] = PALE
    for y in range(y0 + 94, y1 - 44, 22):
        c.seam((198, y), (242, y), both=False)
    c.panel([(206, y1 - 40), (234, y1 - 40), (234, y1 - 16), (226, y1 - 8), (214, y1 - 8), (206, y1 - 16)], both=False)
    for x in range(212, 229):
        c.px[(x, y1 - 20)] = PURPLE
        c.px[(x, y1 - 19)] = DEEP


def v7(c):
    """Three feather plates each side, bow ones overlapping aft ones, sweeping out to big hooked tips, each with a
    stepped notch on its trailing edge like the console's cheeks."""
    c.gap([(196, 80), (60, 110), (4, 200), (40, 316), (196, 256)])
    L = [(196, 198), (126, 202), (76, 206), (60, 232), (48, 262), (40, 290), (22, 300), (16, 318), (34, 324), (46, 312),
         (62, 296), (70, 296), (70, 288), (80, 288), (80, 280), (98, 262), (118, 254), (196, 256)]
    M = [(196, 134), (124, 140), (72, 136), (36, 148), (14, 168), (2, 160), (0, 186), (4, 206), (16, 216), (16, 202),
         (28, 188), (44, 188), (44, 194), (56, 194), (56, 200), (70, 206), (126, 214), (196, 214)]
    U = [(196, 72), (150, 76), (96, 86), (46, 96), (36, 74), (18, 66), (8, 76), (20, 104), (36, 124), (56, 132),
         (56, 138), (70, 138), (70, 146), (122, 154), (196, 152)]
    c.part(L, DARK)
    c.panel([(176, 216), (126, 218), (100, 222), (94, 238), (176, 242)])
    c.seam((84, 222), (54, 290))
    c.part(M, ARMOUR, shadow=4)
    c.panel([(180, 168), (110, 168), (96, 176), (96, 198), (180, 202)])
    c.seam((70, 156), (20, 178))
    c.part(U, DARK, shadow=4)
    c.panel([(180, 92), (130, 96), (110, 104), (110, 134), (180, 138)])
    c.seam((90, 100), (40, 110))
    c.lights((96, 116), (58, 124), 4)
    c.lights((64, 166), (26, 182), 4)
    c.lights((76, 236), (58, 274), 4)
    tower(c)


def v8(c):
    """Two broad plates each side: the fore one with a forward hook, the aft one sweeping long to the stern."""
    c.gap([(196, 80), (40, 100), (6, 200), (50, 316), (196, 262)])
    A = [(196, 150), (120, 150), (70, 140), (30, 168), (12, 214), (20, 260), (46, 300), (58, 318), (70, 306), (60, 290), (66, 270), (96, 254), (130, 256), (196, 260)]
    F = [(196, 70), (140, 74), (86, 86), (46, 92), (30, 66), (14, 70), (18, 98), (40, 134), (64, 160), (70, 196), (120, 200), (196, 196)]
    c.part(A, DARK)
    c.panel([(180, 214), (110, 212), (84, 222), (84, 244), (180, 246)])
    c.seam((60, 176), (30, 262))
    c.part(F, ARMOUR, shadow=4)
    c.panel([(182, 92), (124, 96), (96, 108), (90, 150), (100, 180), (182, 180)])
    c.seam((70, 100), (30, 92))
    c.lights((64, 110), (34, 84), 4)
    c.lights((36, 230), (54, 290), 4)
    c.lights((90, 160), (90, 186), 3)
    tower(c)


def v9(c):
    """Shoulder hooks over three aft-swept blades: a raised hooked plate on each shoulder, blades fanned behind it."""
    c.gap([(196, 80), (30, 100), (2, 230), (60, 326), (196, 262)])
    blades = [([(196, 210), (120, 214), (90, 230), (72, 268), (60, 300), (50, 304), (48, 320), (64, 324), (74, 312), (84, 296),
                (90, 296), (90, 288), (98, 288), (104, 262), (196, 258)], DARK),
              ([(196, 168), (110, 170), (60, 186), (32, 226), (22, 238), (16, 262), (26, 282), (34, 274), (36, 256), (48, 244),
                (54, 244), (54, 236), (62, 236), (74, 222), (110, 220), (196, 222)], ARMOUR),
              ([(196, 120), (100, 124), (40, 144), (14, 178), (4, 186), (0, 214), (10, 230), (16, 220), (22, 200), (34, 190),
                (40, 190), (40, 182), (50, 182), (56, 172), (110, 176), (196, 178)], DARK)]
    for pts, base in blades:
        c.part(pts, base, shadow=4)
    S = [(196, 70), (150, 72), (100, 80), (62, 90), (50, 66), (30, 58), (20, 70), (34, 104), (60, 128), (110, 132),
         (110, 138), (130, 138), (150, 132), (196, 132)]
    c.part(S, ARMOUR, shadow=5)
    c.panel([(182, 86), (120, 88), (84, 100), (96, 120), (182, 118)])
    c.seam((60, 96), (36, 72))
    c.lights((80, 112), (46, 98), 4)
    c.lights((50, 196), (24, 226), 4)
    c.lights((94, 236), (74, 286), 4)
    c.panel([(176, 186), (120, 186), (110, 206), (176, 208)])
    tower(c)


VARIANTS = {"v7": v7, "v8": v8, "v9": v9}


def svg(c, rooms=False):
    rects = paths({(x, y): col for (x, y), col in c.px.items() if 0 <= x < W and 0 <= y < H})
    over = "".join(f'<rect x="{a}" y="{b}" width="{cc - a}" height="{d - b}" fill="none" stroke="#66ff66" stroke-width=".6" '
                   f'stroke-dasharray="3 2" opacity=".7"/>' for a, b, cc, d in ROOMS) if rooms else ""
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" '
            f'shape-rendering="crispEdges">{rects}{over}</svg>')


def uncovered(c, margin=5):
    miss = 0
    for a, b, cc, d in ROOMS:
        for y in range(b - margin, d + margin):
            for x in range(a - margin, cc + margin):
                if (x, y) not in c.cover and (x, y) not in c.px:
                    miss += 1
    return miss


if __name__ == "__main__":
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    for name in sys.argv[2:] or VARIANTS:
        c = Canvas()
        VARIANTS[name](c)
        print(name, "uncovered room pixels (5 px margin):", uncovered(c))
        open(os.path.join(out, f"{name}.svg"), "w").write(svg(c))
        open(os.path.join(out, f"{name}-rooms.svg"), "w").write(svg(c, True))
