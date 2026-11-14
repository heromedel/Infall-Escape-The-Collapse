"""Tentauri attack ship hull (Ai-Generated-Proposal: no such ship is designed yet): a barbed arrowhead seed.
A broad lilac shell with two hooked barbs at the rear corners and a domed periwinkle seed plate with the canopy;
gold veins run to the barbs, two thrusters glow pink at the stern. Hull only: no airlocks, mounts, weapons or floor plan.

Usage: python3 attack_ship.py OUT_DIR [SCHEME ...]
Writes tentauri-attack-ship-hull.svg (lilac), the five stages, a room-check copy (review only) and one SVG per scheme.
Proposed rooms (center="Tile", tile (0,0)'s centre at (180, 218)): Bow 3x2, Main 5x2, Stern 3x2.
"""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "tools"))  # docs/art/tools
from art_kit import Hull, rounded_path, symmetric, INK

W, H, CX, CY, TILE = 360, 430, 180, 218, 35
# proposed rooms: Bow 3x2, Main 5x2, Stern 3x2 (a cross) (few rooms, many systems, as the race profile asks)
ROOMS = [(-1, -3, 1, -2), (-2, -1, 2, 0), (-1, 1, 1, 2)]
INDIGO, VIOLET, DTEAL, PLUM = "#3d3478", "#5a4a9a", "#2c6470", "#6a3a78"
GOLD, SHEEN, PINK, DEEP = "#e2bf62", "#7fe0dc", "#ff5eca", "#151a2c"

def rect(r):
    x0, y0, x1, y1 = r
    return (CX + (x0 - .5) * TILE, CY + (y0 - .5) * TILE, CX + (x1 + .5) * TILE, CY + (y1 + .5) * TILE)

def rooms_svg():
    o = ['<g fill="none" stroke="#ff5eca" stroke-width="1.5" stroke-dasharray="4 3">']
    for r in ROOMS:
        a, b, c, d = rect(r); o.append(f'<rect x="{a}" y="{b}" width="{c-a}" height="{d-b}"/>')
    return "".join(o) + "</g>"

def sym(half, r):
    pts = symmetric(half, CX)
    rr = r + [x for x, p in zip(r[::-1], half[::-1]) if abs(p[0] - CX) > .01]
    return rounded_path(pts, rr)

def side(pts, rr, s):
    pts = [(CX + s * x, y) for x, y in pts]
    if s > 0: pts, rr = pts[::-1], rr[::-1]
    return rounded_path(pts, rr)

def base():
    h = Hull(W, H, "Tentauri attack ship hull")
    h.add_def("mottle", '<filter id="mottle" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="8"/></filter>')
    h.add_def("abalone", '<linearGradient id="abalone" x1="0" y1="0" x2="1" y2="1">'
              f'<stop offset="0" stop-color="{SHEEN}" stop-opacity=".35"/><stop offset=".35" stop-color="{VIOLET}" stop-opacity="0"/>'
              f'<stop offset=".6" stop-color="{GOLD}" stop-opacity=".22"/><stop offset="1" stop-color="{PINK}" stop-opacity=".2"/></linearGradient>')
    return h

def det(d, spots):
    s = "".join(f'<ellipse cx="{x}" cy="{y}" rx="{r}" ry="{r*.7:.1f}" fill="{c}" opacity="{o}" filter="url(#mottle)"/>' for x, y, r, c, o in spots)
    return f'<path d="{d}" fill="url(#abalone)"/>' + s + f'<path d="{d}" fill="none" stroke="{SHEEN}" stroke-width="1.6" opacity=".35"/>'

def glow(x, y, rx=8, ry=14):
    return f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="{PINK}" opacity=".6" filter="url(#glow)"/>'

def vent(x, y):
    return (f'<ellipse cx="{x}" cy="{y}" rx="8" ry="5" fill="{DTEAL}" stroke="{INK}" stroke-width="1.2"/>'
            f'<ellipse cx="{x}" cy="{y+1}" rx="5" ry="2.8" fill="{DEEP}"/><ellipse cx="{x}" cy="{y+1.5}" rx="2.6" ry="1.4" fill="{PINK}"/>')

def eye(y, w=18):
    return (f'<path d="M{CX-w},{y+10} Q{CX},{y-8} {CX+w},{y+10} Q{CX},{y+4} {CX-w},{y+10} Z" fill="{DEEP}" stroke="{INK}" stroke-width="1.2"/>'
            f'<path d="M{CX-w*.6},{y+6} Q{CX-w*.3},{y} {CX-2},{y}" fill="none" stroke="{SHEEN}" stroke-width="1.4" opacity=".8"/>')

SCHEMES = {
 "lilac":  # picked by heromedel (2026-11-14)
             dict(outer="#9c86c9", inner="#7f7cc8", sheen="#9ff0ea", gold="#f0cf7a", accent="#ff8fd6", vent="#3f8f98"),
 "pastel": dict(outer="#8fd6d2", inner="#f3d2cc", sheen="#c9b8f0", gold="#ffd6a0", accent="#ff8fc9", vent="#3aa9a6"),
 "opal":  # kept for a less aggressive Tentauri ship (heromedel)
              dict(outer="#d79bb4", inner="#a9a3e0", sheen="#8fe6dc", gold="#f3d38a", accent="#ff7fcf", vent="#4a8f9a"),
 "seafoam": dict(outer="#6fb8b0", inner="#c8c0ee", sheen="#fbe8e1", gold="#f0c98a", accent="#ff79c8", vent="#2c6470"),
}

def dome_defs(h):
    h.add_def("dome", '<radialGradient id="dome" cx=".36" cy=".3" r=".85">'
              '<stop offset="0" stop-color="#ffffff" stop-opacity=".55"/><stop offset=".28" stop-color="#ffffff" stop-opacity=".12"/>'
              '<stop offset=".55" stop-color="#000000" stop-opacity="0"/><stop offset=".85" stop-color="#0b0f24" stop-opacity=".28"/>'
              '<stop offset="1" stop-color="#0b0f24" stop-opacity=".5"/></radialGradient>')
    h.add_def("spec", '<filter id="spec" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="5"/></filter>')

def domed(d, c, spots, extra=""):
    mot = "".join(f'<ellipse cx="{x}" cy="{y}" rx="{r}" ry="{r*.7:.1f}" fill="{col}" opacity="{o}" filter="url(#mottle)"/>' for x, y, r, col, o in spots)
    return (mot + f'<path d="{d}" fill="url(#dome)"/>' + extra
            + f'<path d="{d}" fill="none" stroke="#ffffff" stroke-width="1.4" opacity=".35"/>')

def build(c):
    h = base(); dome_defs(h)
    st, vx, vy = 26, 36, 328
    for s in (-1, 1): h.raw(f"thrust-glow-{s}", {5: f'<ellipse cx="{CX+s*vx}" cy="{vy+16}" rx="8" ry="14" fill="{c["accent"]}" opacity=".6" filter="url(#glow)"/>'})
    outer = sym([(CX, 40), (CX - 60, 90), (CX - 140, 220), (CX - 150, 290), (CX - 128, 272), (CX - 96, 263),
                 (CX - 62, 326), (CX, 338)], [20, 60, 40, 8, 20, 30, 26, 0])
    ribs = "".join(f'<path d="M{CX+s*20},{120+k*10} Q{CX+s*(70+k*14)},{190+k*20} {CX+s*(126-k*14)},{278-k*6}" fill="none" '
                   f'stroke="{c["gold"]}" stroke-width="1.2" opacity="{.5-k*.12:.2f}"/>' for s in (-1, 1) for k in range(3))
    # the shell: lit from the upper left, darker toward the barbs, so it curves down away from the seed plate
    h.plate("shell", outer, c["outer"], bevel=7, shadow=5,
            details=domed(outer, c, [(CX - 90, 200, 22, c["sheen"], .35), (CX + 100, 240, 18, c["gold"], .3)], ribs))
    inner = sym([(CX, 68), (CX - 40, 102), (CX - 68, 170), (CX - 76, 226), (CX - 50, 312), (CX, 326)], [0, 40, 40, 30, 30, 0])
    spec = (f'<ellipse cx="{CX-26}" cy="{140}" rx="22" ry="34" fill="#ffffff" opacity=".45" filter="url(#spec)" transform="rotate(18 {CX-26} 140)"/>'
            f'<ellipse cx="{CX-30}" cy="{126}" rx="6" ry="11" fill="#ffffff" opacity=".7" filter="url(#glow)" transform="rotate(18 {CX-30} 126)"/>')
    h.plate("seed-plate", inner, c["inner"], bevel=8, shadow=8,
            details=domed(inner, c, [(CX + 30, 180, 22, c["sheen"], .35), (CX - 20, 280, 16, c["accent"], .25)], spec))
    for s in (-1, 1):
        h.raw(f"thruster-{s}", {5: (f'<ellipse cx="{CX+s*vx}" cy="{vy}" rx="8" ry="5" fill="{c["vent"]}" stroke="{INK}" stroke-width="1.2"/>'
              f'<ellipse cx="{CX+s*vx}" cy="{vy+1}" rx="5" ry="2.8" fill="{DEEP}"/><ellipse cx="{CX+s*vx}" cy="{vy+1.5}" rx="2.6" ry="1.4" fill="{c["accent"]}"/>')})
    h.raw("canopy", {5: eye(90, 16)})
    return h

if __name__ == "__main__":
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    h = build(SCHEMES["lilac"])
    s = h.svg(5)
    open(os.path.join(out, "tentauri-attack-ship-hull.svg"), "w").write(s)
    open(os.path.join(out, "room-check.svg"), "w").write(s.replace("</svg>", rooms_svg() + "</svg>"))
    for st in range(1, 6):
        open(os.path.join(out, f"stage{st}.svg"), "w").write(h.svg(st, background="#ffffff" if st == 1 else None))
    for name in sys.argv[2:]:
        open(os.path.join(out, f"scheme-{name}.svg"), "w").write(build(SCHEMES[name]).svg(5))
