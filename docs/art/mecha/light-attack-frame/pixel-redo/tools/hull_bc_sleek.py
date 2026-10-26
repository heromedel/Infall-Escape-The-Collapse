"""Mecha Light Attack Frame on the battle cross, the sleek version: the Mecha hull style reference.

Usage: python3 hull_bc_sleek.py OUT_DIR
Dark, sleek metal in crisp bands (no grit, seams, bolts or machinery), light from the upper left; purple only in the
light slits and vents. Writes hull.svg (mounts as hidden data), mounts.svg and rooms.svg (overlays for review).
Every light and vent is checked for a clear margin of one even shade (art rules: detail passes); the bow slit crosses
the prow's centre line on purpose.
"""
import math, os, sys
from PIL import Image, ImageDraw
from pixel_svg import paths
W, H, CX = 340, 300, 170
RAMP = ["#050507", "#0b0b0e", "#111216", "#17181d", "#1c1d24", "#2a2d35", "#3d414d", "#5f6576"]   # 4: Mecha shadow grey
OUT = 0
PURPLE, DEEP, PALE = "#aa28eb", "#5a128c", "#ebe1fa"


def mirror(pts):
    return [(W - x, y) for x, y in pts][::-1]


def mask(pts):
    im = Image.new("1", (W, H))
    ImageDraw.Draw(im).polygon(pts, fill=1)
    return {(x, y) for y in range(H) for x in range(W) if im.getpixel((x, y))}


class Hull:
    def __init__(self):
        self.lv = {}      # pixel -> ramp level
        self.glow = {}    # pixel -> colour, drawn over

    def cast(self, m, length=7, core=2):
        """A crisp shadow down and to the right onto what is already drawn: two steps under the edge, one beyond."""
        hit = {}
        for x, y in m:
            for k in range(1, length + 1):
                p = (x + k, y + k)
                if p in m:
                    break
                if p in self.lv:
                    hit[p] = min(hit.get(p, 99), k)
        for p, k in hit.items():
            if self.lv[p] > OUT:
                self.lv[p] = max(1, self.lv[p] - (2 if k <= core else 1))

    def blade(self, pts, ridge, base, both=True, lights=None, thin=False, thin_below=None, slim=False, glints=(), reflect=True):
        for side in ((1, -1) if both else (1,)):
            poly = pts if side > 0 else mirror(pts)
            (rx0, ry0), (rx1, ry1) = ridge
            if side < 0:
                rx0, rx1 = W - rx0, W - rx1
            m = mask(poly)
            self.cast(m)
            L = math.hypot(rx1 - rx0, ry1 - ry0)
            for (x, y) in m:
                nb = lambda dx, dy: (x + dx, y + dy) in m
                if not (nb(1, 0) and nb(-1, 0) and nb(0, 1) and nb(0, -1)):
                    self.lv[(x, y)] = OUT
                    continue
                thin_here = thin or (thin_below is not None and y > thin_below)
                # signed distance from the ridge: negative on the bow side (facing the light)
                d = ((rx1 - rx0) * (y - ry0) - (ry1 - ry0) * (x - rx0)) / L
                if (rx1 - rx0) < 0:
                    d = -d
                if d < 0:     # lit facet: a bright band along the ridge, falling off in steps
                    a = -d
                    t = base + ((3 if a < 1 else 2 if a < 2.5 else 1 if a < 7 else 0) if thin_here else
                                (3 if a < 1.5 else 2 if a < 5 else 1 if a < 9 else 0) if slim else
                                (3 if a < 1.5 else 2 if a < 6 else 1 if a < 16 else 0))
                else:         # shaded facet: a dark crease at the ridge, a faint reflected band beyond
                    t = base - (2 if d < 4 else 1) + (1 if reflect and 14 < d < 18 else 0)
                if not (nb(-1, 0) and nb(0, -1)):
                    t += 1 if thin_here else 2    # rim light on edges facing the light
                elif not (nb(1, 0) and nb(0, 1)):
                    t -= 1
                for (gx0, gy0), (gx1, gy1) in glints:   # a glint along a whole edge, two pixels deep
                    if side < 0:
                        gx0, gx1 = W - gx0, W - gx1
                    sl = math.hypot(gx1 - gx0, gy1 - gy0)
                    u = ((x - gx0) * (gx1 - gx0) + (y - gy0) * (gy1 - gy0)) / sl ** 2
                    if -.05 <= u <= 1.05:
                        dd = abs((gx1 - gx0) * (y - gy0) - (gy1 - gy0) * (x - gx0)) / sl
                        if dd < 2.2:
                            t = max(t, base + 3)
                        elif dd < 3.5:
                            t = max(t, base + 2)
                self.lv[(x, y)] = max(1, min(len(RAMP) - 1, t))

    def column(self, pts, base):
        """The spine, shaded like a polished column: lit on the left, a bright streak, darkening to the right."""
        m = mask(pts)
        self.cast(m, 8, 3)
        xs = [x for x, _ in m]
        x0, x1 = min(xs), max(xs)
        for (x, y) in m:
            nb = lambda dx, dy: (x + dx, y + dy) in m
            if not (nb(1, 0) and nb(-1, 0) and nb(0, 1) and nb(0, -1)):
                self.lv[(x, y)] = OUT
                continue
            u = (x - x0) / (x1 - x0)
            t = base + (1 if u < .18 else 3 if u < .26 else 1 if u < .4 else 0 if u < .7 else -1)
            if not nb(0, -1):
                t += 2
            self.lv[(x, y)] = max(1, min(len(RAMP) - 1, t))

    def recess(self, pts):
        for (x, y) in mask(pts):
            self.lv[(x, y)] = 1

    def slit(self, x0, y0, x1, y1, both=False, shift=0):
        for s in ((1, -1) if both else (1,)):
            for y in range(y0, y1):
                for x in range(x0, x1):
                    xx = x if s > 0 else W - 1 - x + shift
                    self.glow[(xx, y)] = PALE if (x0 < x < x1 - 1 and y0 < y < y1 - 1) else PURPLE

    def svg(self):
        r = paths({**{p: RAMP[l] for p, l in self.lv.items()}, **self.glow})
        return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" shape-rendering="crispEdges">{r}</svg>'


def build(lights=False):
    h = Hull()
    for p in (mask([(150, 66), (60, 96), (52, 186), (94, 258), (150, 264)]) | mask(mirror([(150, 66), (60, 96), (52, 186), (94, 258), (150, 264)]))):
        h.lv[p] = 1   # the shadowed body between the plates, plain
    h.blade([(150, 176), (92, 182), (58, 214), (50, 262), (58, 294), (70, 282), (74, 266), (80, 266), (80, 256), (90, 256),
             (112, 236), (150, 252)], ((150, 214), (58, 290)), 3, thin=True)
    h.blade([(150, 96), (100, 98), (58, 102), (24, 128), (12, 184), (16, 236), (26, 244), (30, 222), (34, 196), (44, 188),
             (50, 188), (50, 180), (60, 180), (82, 184), (150, 184)], ((150, 130), (14, 234)), 4, thin_below=190, slim=True)
    h.blade([(150, 64), (124, 66), (78, 4), (66, 8), (70, 22), (92, 82), (92, 92), (106, 102), (150, 104)], ((150, 86), (72, 8)), 3)
    h.blade([(170, 236), (140, 240), (132, 270), (142, 296), (170, 296)], ((170, 250), (136, 290)), 2, thin=True)
    # the vents sit in the dark band between the block's highlight and its reflected band, stepped to follow it
    h.slit(145, 284, 149, 294, both=True, shift=1)
    h.slit(151, 277, 155, 287, both=True, shift=1)
    h.column([(158, 52), (182, 52), (194, 66), (196, 236), (186, 262), (154, 262), (144, 236), (146, 66)], 3)
    h.recess([(160, 110), (180, 110), (186, 117), (186, 148), (154, 148), (154, 117)])
    h.slit(160, 142, 181, 145)
    h.blade([(170, 2), (170, 100), (144, 96), (132, 62), (150, 22)], ((170, 12), (140, 84)), 3)
    h.slit(164, 40, 177, 43)   # the bow slit: one band across the prow's centre line (intentional)
    if lights:   # the rows of light slits along the blades, as before
        for a, b, n in [((114, 84), (90, 60), 3), ((120, 132), (34, 160), 6), ((124, 202), (70, 232), 4)]:
            for i in range(n):
                t = i / max(n - 1, 1)
                x, y = round(a[0] + (b[0] - a[0]) * t), round(a[1] + (b[1] - a[1]) * t)
                for xx in (x, W - 1 - x - 3):
                    for j in range(4):
                        h.glow[(xx + j, y)] = PALE if j in (1, 2) else PURPLE
                        h.glow[(xx + j, y + 1)] = PURPLE
                        h.glow[(xx + j, y + 2)] = DEEP
    return h




# rooms (the battle cross, see floor_bc.py) and the six planned mounts: on the front profile, a clear line ahead
T, X0, Y0 = 35, 65, 72
ROOMS = [(2, 0, 2, 2), (0, 1, 2, 2), (4, 1, 2, 2), (2, 2, 2, 2), (2, 4, 2, 1)]
MOUNT_COLS = [(72, "up"), (42, "up"), (16, "out")]


def mounts(h):
    hull = set(h.lv)
    out = []
    for x, sl in MOUNT_COLS:
        for xx, side in ((x, "left"), (W - x, "right")):
            top = min(y for (px_, y) in hull if px_ == xx)
            out.append((xx, top + 3, side if sl == "out" else sl))
    for x, y, sl in out:
        cx = x + {"up": 0, "left": -8, "right": 8}[sl]
        assert not any((xx, yy) in hull for xx in range(cx - 3, cx + 4) for yy in range(0, y - 6)), (x, y)
    return out


def check_details(h):
    """Each light or vent has two pixels of one even shade around it, except the bow slit (intentional)."""
    seen, bad = set(), []
    for p in h.glow:
        if p in seen:
            continue
        group, todo = [], [p]
        seen.add(p)
        while todo:
            x, y = todo.pop()
            group.append((x, y))
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    n = (x + dx, y + dy)
                    if n in h.glow and n not in seen:
                        seen.add(n)
                        todo.append(n)
        if min(y for _, y in group) == 40:
            continue
        ring = {(x + dx, y + dy) for x, y in group for dx in range(-2, 3) for dy in range(-2, 3)} - set(group)
        tones = {h.lv.get(r) for r in ring}
        if len(tones) > 1 or OUT in tones:
            bad.append(min(group))
    assert not bad, bad


if __name__ == "__main__":
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    h = build(lights=True)
    check_details(h)
    ms = mounts(h)
    base = h.svg()
    data = "".join(f'<circle id="mount-{i + 1}" cx="{x}" cy="{y}" r="7" data-slide="{sl}"/>' for i, (x, y, sl) in enumerate(ms))
    open(os.path.join(out, "hull.svg"), "w").write(base.replace("</svg>", f'<g id="weapon-mounts" display="none">{data}</g></svg>'))
    marks = ""
    for i, (x, y, sl) in enumerate(ms):
        col = "#ffd040" if i == 3 else "#7fd9ff"
        dx, dy = {"up": (0, -1), "left": (-1, 0), "right": (1, 0)}[sl]
        marks += (f'<circle cx="{x}" cy="{y}" r="5" fill="none" stroke="{col}" stroke-width="1.3"/>'
                  f'<line x1="{x + dx * 6}" y1="{y + dy * 6}" x2="{x + dx * 18}" y2="{y + dy * 18}" stroke="{col}" stroke-width="1.3"/>'
                  f'<text x="{x + (10 if x > CX else -10)}" y="{y + 12}" text-anchor="middle" font-family="sans-serif" '
                  f'font-size="9" fill="{col}" stroke="#141a22" stroke-width="2" paint-order="stroke">{i + 1}</text>')
    open(os.path.join(out, "mounts.svg"), "w").write(base.replace("</svg>", marks + "</svg>"))
    rooms = "".join(f'<rect x="{X0 + c * T}" y="{Y0 + r * T}" width="{w * T}" height="{hh * T}" fill="none" stroke="#66ff66" '
                    f'stroke-width=".6" stroke-dasharray="3 2" opacity=".8"/>' for c, r, w, hh in ROOMS)
    open(os.path.join(out, "rooms.svg"), "w").write(base.replace("</svg>", rooms + "</svg>"))
    print("details clear; mounts:", ms)
