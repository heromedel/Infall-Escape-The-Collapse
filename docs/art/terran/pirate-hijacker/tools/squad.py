"""Squad view: pirate squads (enemy side, top, facing down) against the Outrider (player side, bottom, facing up).

Usage: python3 squad.py HIJACKER_SVG CUTPURSE_SVG OUTRIDER_SVG OUT_SVG
"""
import base64
import random
import sys

hij, cut, outr, out = sys.argv[1:5]


def data(path):
    return "data:image/svg+xml;base64," + base64.b64encode(open(path, "rb").read()).decode()


H_ART = {"hij": (480, 760, data(hij)), "cut": (480, 760, data(cut)), "out": (460, 740, data(outr))}


def ship(kind, cx, cy, height, facing_down):
    w, h, href = H_ART[kind]
    scale = height / h
    sw = w * scale
    rot = f' transform="rotate(180 {cx} {cy})"' if facing_down else ""
    return (f'<g{rot}><image href="{href}" x="{cx - sw / 2:.1f}" y="{cy - height / 2:.1f}" width="{sw:.1f}" '
            f'height="{height}"/></g>')


def scene(x0, title, enemies, ship_h):
    """One battle: enemies along the top facing down, the Outrider at the bottom facing up, a divider between."""
    w = 560
    parts = [f'<g transform="translate({x0},0)">',
             f'<rect x="0" y="40" width="{w}" height="640" rx="8" fill="#0a0f1c" stroke="#1d2640"/>',
             f'<line x1="20" y1="360" x2="{w - 20}" y2="360" stroke="#2a3557" stroke-dasharray="6 6"/>',
             f'<text x="{w / 2}" y="28" font-size="15" font-family="sans-serif" fill="#e3e8f1" '
             f'text-anchor="middle" font-weight="600">{title}</text>',
             f'<text x="16" y="62" font-size="11" font-family="sans-serif" fill="#97a3b8">Enemy squad</text>',
             f'<text x="16" y="670" font-size="11" font-family="sans-serif" fill="#97a3b8">Player: SC-1 Outrider</text>']
    n = len(enemies)
    for i, kind in enumerate(enemies):
        cx = w / 2 + (i - (n - 1) / 2) * ship_h * .78
        parts.append(ship(kind, cx, 200, ship_h, True))
    parts.append(ship("out", w / 2, 520, ship_h, False))
    parts.append("</g>")
    return "".join(parts)


def far_strip(y0):
    """Zoomed far out: the whole battle as a thumbnail, to check the squads still read apart (concern 2)."""
    parts = [f'<text x="20" y="{y0 + 18}" font-size="15" font-family="sans-serif" fill="#e3e8f1" '
             f'font-weight="600">Zoomed out</text>']
    for k, (enemies, label) in enumerate(((["cut", "cut"], "2 Cutpurses"), (["hij", "hij"], "2 Hijackers"))):
        bx = 20 + k * 300
        parts.append(f'<rect x="{bx}" y="{y0 + 30}" width="280" height="190" rx="6" fill="#0a0f1c" stroke="#1d2640"/>')
        for i, kind in enumerate(enemies):
            parts.append(ship(kind, bx + 115 + i * 50, y0 + 80, 70, True))
        for i in range(3):
            parts.append(ship("out", bx + 90 + i * 50, y0 + 172 - (8 if i == 1 else 0), 66, False))
        parts.append(f'<text x="{bx + 140}" y="{y0 + 236}" font-size="11" font-family="sans-serif" fill="#97a3b8" '
                     f'text-anchor="middle">{label} vs 3 Outriders</text>')
    return "".join(parts)


rnd = random.Random(3)
stars = "".join(f'<circle cx="{rnd.random() * 1180:.0f}" cy="{rnd.random() * 980:.0f}" r="{rnd.random() * 1.1 + .3:.1f}" '
                f'fill="#ffffff" opacity="{rnd.random() * .5 + .2:.2f}"/>' for _ in range(160))
body = (scene(20, "Band 3: 2 Cutpurses", ["cut", "cut"], 230)
        + scene(600, "Bands 4–6: 2 Hijackers", ["hij", "hij"], 230)
        + far_strip(700))
open(out, "w").write(f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1180 980" width="1180" height="980">
<title>Terran pirate squad view</title>
<rect width="100%" height="100%" fill="#070b16"/>{stars}{body}
</svg>
''')
print("saved", out)
