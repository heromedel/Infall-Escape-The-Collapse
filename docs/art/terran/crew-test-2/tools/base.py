"""Reads the 45-degree standing render into a 70 x 70 template: a mask, a lightness map and body regions."""
import os

from PIL import Image
BG = (150, 154, 162)
SRC = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "reference", "stance-45-standing.png")


def template(height=56, frame=70):
    im = Image.open(SRC).convert("RGB")
    W, H = im.size
    fg = [[sum(abs(a - b) for a, b in zip(im.getpixel((x, y)), BG)) > 24 for x in range(W)] for y in range(H)]
    ys = [y for y in range(H) if any(fg[y])]; xs = [x for x in range(W) if any(fg[y][x] for y in range(H))]
    y0, y1, x0, x1 = min(ys), max(ys) + 1, min(xs), max(xs) + 1
    k = (y1 - y0) / height
    cx = (x0 + x1) / 2
    ox, oy = frame / 2, frame - 6 - height
    cells = {}
    for ty in range(frame):
        for tx in range(frame):
            sx0, sy0 = cx + (tx - ox) * k, y0 + (ty - oy) * k
            pts = [(int(sx0 + i * k / 3), int(sy0 + j * k / 3)) for i in range(3) for j in range(3)]
            pts = [(x, y) for x, y in pts if 0 <= x < W and 0 <= y < H]
            on = [p for p in pts if fg[p[1]][p[0]]]
            if len(on) >= 5:
                rgb = [sum(im.getpixel(p)[c] for p in on) / len(on) for c in range(3)]
                cells[(tx, ty)] = rgb
    return cells


def lightness(rgb):
    return 0.3 * rgb[0] + 0.59 * rgb[1] + 0.11 * rgb[2]


def regions(cells):
    """skin (warm), shirt (mid grey), lower (dark: trousers, boots), hair (dark, at the head)."""
    ys = sorted(y for _, y in cells); top, bottom = ys[0], ys[-1]
    out = {}
    for (x, y), (r, g, b) in cells.items():
        L = lightness((r, g, b)); f = (y - top) / (bottom - top)
        warm = r - b > 14
        if warm and L > 45:
            out[(x, y)] = "skin"
        elif f < 0.2:
            out[(x, y)] = "hair"
        elif f > 0.9:
            out[(x, y)] = "boot"
        elif L > 58 and f < 0.62:
            out[(x, y)] = "shirt"
        else:
            out[(x, y)] = "pants" if f > 0.5 else "shirt"
    return out


if __name__ == "__main__":
    c = template(); r = regions(c)
    COL = {"skin": "#d0927a", "hair": "#2c1b13", "shirt": "#3f7470", "pants": "#333d4e", "boot": "#1c1819"}
    s = 8
    rects = "".join(f'<rect x="{x*s}" y="{y*s}" width="{s}" height="{s}" fill="{COL[r[(x,y)]]}"/>' for (x, y) in c)
    grey = "".join(f'<rect x="{560+x*s}" y="{y*s}" width="{s}" height="{s}" fill="rgb({int(v[0])},{int(v[1])},{int(v[2])})"/>' for (x, y), v in c.items())
    open("tmpl.svg", "w").write(f'<svg xmlns="http://www.w3.org/2000/svg" width="1120" height="560" shape-rendering="crispEdges"><rect width="100%" height="100%" fill="#9da2aa"/>{rects}{grey}</svg>')
    print(len(c), min(y for _, y in c), max(y for _, y in c))
