"""Raster FTL-style ship test. Draws in stages: 1 outline, 2 fill, 3 shade, 4 highlight, 5 details."""
import math, sys, random
from PIL import Image, ImageDraw, ImageChops, ImageFilter

S = 4                      # supersample factor
W, H = 580, 330
STAGE = int(sys.argv[1]) if __name__ == "__main__" and len(sys.argv) > 1 else 5
OUT = sys.argv[2] if __name__ == "__main__" and len(sys.argv) > 2 else f"stage{STAGE}.png"

LIGHT = (0.35, 0.94)       # FTL convention: lower edges catch the light, upper edges fall in shadow
OUTLINE = (30, 32, 36)
HULL = (176, 178, 172)
HULL_LIGHT = (196, 198, 191)
HULL_DARK = (122, 125, 124)
ACCENT = (58, 146, 166)
random.seed(7)


def sc(pts):
    return [(x * S, y * S) for x, y in pts]


def box(x0, y0, x1, y1):
    return [x0 * S, y0 * S, x1 * S, y1 * S]


def mirror(pts, cy=165):
    return [(x, 2 * cy - y) for x, y in reversed(pts)]


def cw(pts):
    a = sum(pts[i][0] * pts[(i + 1) % len(pts)][1] - pts[(i + 1) % len(pts)][0] * pts[i][1]
            for i in range(len(pts)))
    return pts if a > 0 else list(reversed(pts))


def inset(pts, d):
    """Mitred inward offset of a clockwise (screen space) polygon."""
    n = len(pts)
    lines = []
    for i in range(n):
        (x1, y1), (x2, y2) = pts[i], pts[(i + 1) % n]
        dx, dy = x2 - x1, y2 - y1
        L = math.hypot(dx, dy)
        lines.append(((x1 - dy / L * d, y1 + dx / L * d), (dx, dy)))
    out = []
    for i in range(n):
        (p, r), (q, s) = lines[i - 1], lines[i]
        cross = r[0] * s[1] - r[1] * s[0]
        if abs(cross) < 1e-9:
            out.append(q); continue
        t = ((q[0] - p[0]) * s[1] - (q[1] - p[1]) * s[0]) / cross
        out.append((p[0] + t * r[0], p[1] + t * r[1]))
    return out


def tone(color, k):
    return tuple(max(0, min(255, int(c * k))) for c in color[:3]) + (255,)


def facing(a, b):
    """How much an edge's outward normal faces the light (-1..1)."""
    dx, dy = b[0] - a[0], b[1] - a[1]
    L = math.hypot(dx, dy)
    return (dy / L) * LIGHT[0] + (-dx / L) * LIGHT[1]


def layer():
    return Image.new("RGBA", (W * S, H * S), (0, 0, 0, 0))


def mask_of(pts):
    m = Image.new("L", (W * S, H * S), 0)
    ImageDraw.Draw(m).polygon(sc(pts), fill=255)
    return m


def plate_layer(pts, base, bevel, stage):
    """Render one chamfered plate to its own layer."""
    pts = cw(pts)
    L = layer(); d = ImageDraw.Draw(L)
    if stage <= 2:
        d.polygon(sc(pts), fill=(base + (255,)) if stage == 2 else None)
        return L
    inner = inset(pts, bevel)
    n = len(pts)
    for i in range(n):
        a, b = pts[i], pts[(i + 1) % n]
        f = facing(a, b)
        d.polygon(sc([a, b, inner[(i + 1) % n], inner[i]]), fill=tone(base, 1.0 + 0.30 * f))
    d.polygon(sc(inner), fill=base + (255,))
    if stage >= 4:
        for i in range(n):
            a, b = pts[i], pts[(i + 1) % n]
            ia, ib = inner[i], inner[(i + 1) % n]
            f = facing(a, b)
            if f > 0.4:     # lit lip on the lower edges
                lip = min(1.30, 238 / max(base))
                d.line(sc([ia, ib]), fill=tone(base, lip), width=S)
                d.line(sc([a, b]), fill=tone(base, min(1.22, 228 / max(base))), width=S)
            elif f < -0.4:  # crease shadow on the upper edges
                d.line(sc([ia, ib]), fill=tone(base, 0.70), width=S)
    return L


class Ship:
    def __init__(self, stage):
        self.stage = stage
        self.img = layer()
        self.d = ImageDraw.Draw(self.img)

    def plate(self, pts, base, bevel=8, band=None, band_color=ACCENT):
        L = plate_layer(pts, base, bevel, self.stage)
        if band and self.stage >= 5:
            B = plate_layer(pts, band_color, bevel, self.stage)
            bm = ImageChops.multiply(mask_of(band), B.getchannel("A"))
            L.paste(B, (0, 0), bm)
        self.img.alpha_composite(L)
        self.d.line(sc(pts + [pts[0]]), fill=OUTLINE + (255,), width=2 * S, joint="curve")

    def seam(self, a, b):
        self.d.line(sc([a, b]), fill=(96, 98, 99, 255), width=S)
        self.d.line(sc([(a[0] + .8, a[1] + .8), (b[0] + .8, b[1] + .8)]), fill=(212, 214, 207, 255), width=S)

    def rivet(self, x, y):
        r = 1.2 * S
        self.d.ellipse([x * S - r, y * S - r, x * S + r, y * S + r], fill=(104, 106, 106, 255))
        self.d.ellipse([x * S - r * .5, y * S - r * .2, x * S + r * .7, y * S + r * .9], fill=(226, 228, 222, 255))

    def thruster(self, x, y, length=26, r=10):
        """Engine bell seen from above: ribbed trapezoid pointing aft with a hot core."""
        d = self.d
        bell = [(x, y - r * .65), (x - length, y - r), (x - length, y + r), (x, y + r * .65)]
        d.polygon(sc(bell), fill=(84, 86, 90, 255))
        d.polygon(sc([(x, y - r * .65), (x - length, y - r), (x - length, y - r * .2), (x, y - r * .1)]),
                  fill=(62, 64, 68, 255))
        d.polygon(sc([(x, y + r * .25), (x - length, y + r * .35), (x - length, y + r), (x, y + r * .65)]),
                  fill=(120, 122, 126, 255))
        for i in range(1, 4):
            xx = x - length * i / 4
            h = r * (.65 + .35 * i / 4)
            d.line(sc([(xx, y - h), (xx, y + h)]), fill=(48, 50, 54, 255), width=S)
        d.line(sc(bell + [bell[0]]), fill=OUTLINE + (255,), width=2 * S, joint="curve")
        d.rectangle(box(x - length - 3, y - r + 1, x - length, y + r - 1), fill=OUTLINE + (255,))
        d.rectangle(box(x - length - 2, y - r * .55, x - length - 1, y + r * .55), fill=(255, 176, 92, 255))

    def finish(self):
        img = self.img.resize((W, H), Image.LANCZOS)
        if self.stage >= 5:
            # faint metal grain, kept inside the silhouette
            alpha = img.getchannel("A")
            noise = Image.effect_noise((W, H), 18).point(lambda v: 128 + (v - 128) // 3)
            grain = Image.merge("RGBA", (noise, noise, noise, alpha))
            img = Image.blend(img, ImageChops.overlay(img, grain), 0.35)
            img.putalpha(alpha)
        return img


# ---------------- geometry (mirrored about y=165) ----------------
NACELLE = [(64, 40), (226, 40), (250, 60), (250, 92), (232, 106), (64, 106), (50, 92), (50, 54)]
HULL_PTS = [(110, 110), (150, 86), (316, 86), (350, 116), (440, 124), (500, 146), (526, 165),
            (500, 184), (440, 206), (350, 214), (316, 244), (150, 244), (110, 220), (84, 165)]
DECK = [(158, 126), (322, 126), (346, 146), (430, 146), (450, 165), (430, 184), (346, 184), (322, 204),
        (158, 204), (140, 186), (140, 144)]
NOSE = [(440, 124), (500, 146), (526, 165), (500, 184), (440, 206), (456, 165)]
SIDE_ARMOR = [(172, 92), (300, 92), (300, 112), (172, 112)]
BAND_HULL = [(392, 80), (408, 80), (408, 250), (392, 250)]
BAND_NAC = [(150, 30), (166, 30), (166, 116), (150, 116)]


def nacelle_details(s, flip):
    d = s.d
    for x in (104, 196):
        a, b = flip([(x, 52), (x, 94)])
        s.seam(*sorted([a, b], key=lambda p: p[1]))
    (x0, y0), (x1, y1) = flip([(176, 64), (196, 70)])
    d.rectangle(box(min(x0, x1), min(y0, y1), max(x0, x1), max(y0, y1)), fill=(60, 62, 64, 255))
    for x in (62, 238):
        for y in (48, 98):
            s.rivet(*flip([(x, y)])[0])


def hull_shadow(s):
    """Soft shadow the main hull casts onto the nacelles."""
    m = mask_of([(x + 5, y + 8) for x, y in HULL_PTS]).filter(ImageFilter.GaussianBlur(4 * S))
    sh = Image.new("RGBA", s.img.size, (20, 22, 26, 255))
    m = ImageChops.multiply(m, s.img.getchannel("A")).point(lambda v: v * 0.8)
    s.img.paste(sh, (0, 0), m)


def draw(stage):
    s = Ship(stage)
    for flip in (lambda p: p, mirror):
        if stage >= 5:
            for dy in (-16, 0, 16):
                s.thruster(52, flip([(0, 73 + dy)])[0][1])
        s.plate(flip(NACELLE), HULL, bevel=9, band=flip(BAND_NAC))
        if stage >= 5:
            nacelle_details(s, flip)
    if stage >= 5:
        s.thruster(90, 165, length=24, r=12)
        hull_shadow(s)
    s.plate(HULL_PTS, HULL, bevel=14, band=BAND_HULL)
    if stage >= 3:
        s.plate(NOSE, HULL, bevel=7)
        s.plate(DECK, HULL_LIGHT, bevel=7)
    if stage >= 5:
        details(s)
    return s.finish()


def details(s):
    d = s.d
    # deck seams and hatches
    for x in (210, 280):
        s.seam((x, 128), (x, 202))
    s.seam((142, 165), (208, 165))
    d.rectangle(box(228, 152, 262, 178), fill=(66, 68, 70, 255), outline=OUTLINE + (255,), width=S)
    for i in range(8):
        x = 231 + i * 4
        d.rectangle(box(x, 154, x + 2, 176), fill=(150, 152, 148, 255))
    d.rounded_rectangle(box(166, 140, 200, 158), radius=3 * S, outline=(104, 106, 106, 255), width=S)
    d.line(sc([(168, 157), (198, 157)]), fill=(232, 234, 228, 255), width=S)
    d.rounded_rectangle(box(166, 172, 200, 190), radius=3 * S, outline=(104, 106, 106, 255), width=S)
    d.line(sc([(168, 189), (198, 189)]), fill=(232, 234, 228, 255), width=S)
    # service panels on the aft hull faces
    for flip in (lambda p: p, mirror):
        for x0 in (116, 128):
            pts = flip([(x0, 118), (x0 + 8, 118), (x0 + 8, 140), (x0, 140)])
            d.polygon(sc(pts), fill=(150, 152, 147, 255), outline=(98, 100, 100, 255))
    # forward sensor dome on the deck
    d.ellipse(box(356, 154, 378, 176), fill=(70, 72, 76, 255), outline=OUTLINE + (255,), width=S)
    d.ellipse(box(359, 157, 375, 173), fill=(112, 180, 200, 255))
    d.ellipse(box(362, 159, 368, 165), fill=(220, 244, 250, 255))
    # cockpit glass in the nose
    glass = [(468, 154), (498, 161), (506, 165), (498, 169), (468, 176), (474, 165)]
    d.polygon(sc(glass), fill=(30, 62, 88, 255))
    d.polygon(sc([(472, 156), (496, 161.5), (484, 162.5), (475, 161)]), fill=(150, 210, 236, 255))
    d.line(sc(glass + [glass[0]]), fill=OUTLINE + (255,), width=S, joint="curve")
    # rivets along armour edges
    for x in range(176, 306, 16):
        s.rivet(x, 106); s.rivet(x, 224)
    for y in (94, 236):
        d.rectangle(box(232, y - 3, 262, y + 3), fill=(70, 72, 74, 255), outline=OUTLINE + (255,), width=S)
    # weapon hardpoints on the forward hull
    for y in (132, 198):
        d.rectangle(box(420, y - 4, 434, y + 4), fill=(80, 82, 86, 255), outline=OUTLINE + (255,), width=S)
    # antenna
    d.line(sc([(120, 40), (120, 24)]), fill=OUTLINE + (255,), width=2 * S)
    d.ellipse(box(117, 20, 123, 26), fill=(214, 86, 66, 255), outline=OUTLINE + (255,), width=S)


if __name__ == "__main__":
    draw(STAGE).save(OUT)
    print("saved", OUT)
