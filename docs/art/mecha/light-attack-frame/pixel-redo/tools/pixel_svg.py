"""Pixel art as compact SVG: one path per colour, each row's runs of that colour merged into one rectangle.

paths(px) takes {(x, y): colour} and returns the SVG elements. compact(svg_text) rewrites an SVG drawn as one 1 x 1
rect per pixel (later rects over earlier ones) into the same picture with paths, keeping every other element.
Usage: python3 pixel_svg.py FILE.svg ... (rewrites the files in place)
"""
import re
import sys

RECT = re.compile(r'<rect x="(-?\d+)" y="(-?\d+)" width="1" height="1" fill="(#[0-9a-fA-F]{6})"/>')


def paths(px):
    by_colour = {}
    for (x, y), c in px.items():
        by_colour.setdefault(c, set()).add((x, y))
    out = []
    for c, pts in by_colour.items():
        d = []
        for x, y in sorted(pts, key=lambda p: (p[1], p[0])):
            if (x - 1, y) in pts:
                continue
            n = 1
            while (x + n, y) in pts:
                n += 1
            d.append(f"M{x} {y}h{n}v1h-{n}z")
        out.append(f'<path fill="{c}" d="{"".join(d)}"/>')
    return "".join(out)


def compact(text):
    """Replaces each unbroken stretch of 1 x 1 rects with paths giving the same final pixels."""
    def run(m):
        px = {}
        for x, y, c in RECT.findall(m.group(0)):
            px[(int(x), int(y))] = c
        return paths(px)
    return re.sub(r'(?:<rect x="-?\d+" y="-?\d+" width="1" height="1" fill="#[0-9a-fA-F]{6}"/>)+', run, text)


if __name__ == "__main__":
    for f in sys.argv[1:]:
        t = open(f).read()
        open(f, "w").write(compact(t))
