"""Tentauri Seedpod hull (ship id tentauri-warden): a closed bud. Two coral petals wrap a pearly dorsal plate from
stern to bow, three teal sepals cup the stern, a soft thruster sits on each side sepal and the Supershield organ at the
tail. Hull only: no airlocks, no mounts, no weapons, no floor plan.

Usage: python3 seedpod.py OUT_DIR
Writes tentauri-seedpod-hull.svg, the five stage SVGs and a room-check copy (review only).
Rooms from infall-godot/content/ships/tentauri-warden/ship.xml, center="Tile": tile (0,0)'s centre is at (180, 205).
"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "tools"))  # docs/art/tools
sys.path.insert(0, os.path.join(HERE, "..", "..", "scout", "tools"))  # the scout's palette and parts
from art_kit import Hull, rounded_path, symmetric, INK
import tentauri as T

W, H, CX, CY, TILE = 360, 400, 180, 205, 35
ROOMS = [(-2, -3, 2, -1), (-1, 0, 1, 1), (-2, 2, 2, 2)]

def rect(r):
    x0, y0, x1, y1 = r
    return (CX + (x0 - .5) * TILE, CY + (y0 - .5) * TILE, CX + (x1 + .5) * TILE, CY + (y1 + .5) * TILE)

def rooms_svg():
    out = ['<g id="rooms-overlay" fill="none" stroke="#ff5eca" stroke-width="1.5" stroke-dasharray="4 3">']
    for r in ROOMS:
        a, b, c, d = rect(r)
        out.append(f'<rect x="{a}" y="{b}" width="{c-a}" height="{d-b}"/>')
    return "".join(out) + "</g>"

def base(title):
    h = Hull(W, H, title); T.extra_defs(h)
    h.add_def("iris", '<linearGradient id="iris" x1="0" y1="0" x2="1" y2=".7">'
              f'<stop offset="0" stop-color="{T.AQUA}"/><stop offset=".3" stop-color="{T.LAVENDER}"/>'
              f'<stop offset=".55" stop-color="{T.CORAL_WHITE}"/><stop offset=".8" stop-color="{T.CORAL}"/>'
              f'<stop offset="1" stop-color="{T.TEAL}"/></linearGradient>')
    return h

def sym(half, r):
    pts = symmetric(half, CX)
    if isinstance(r, list):
        rr = r + [x for x, p in zip(r[::-1], half[::-1]) if abs(p[0] - CX) > .01]
        return rounded_path(pts, rr)
    return rounded_path(pts, r)

def glow(x, y, rx=11, ry=15):
    return f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="{T.GLOW}" opacity=".55" filter="url(#glow)"/>'

def vent(x, y):
    return (f'<ellipse cx="{x}" cy="{y}" rx="9" ry="5.5" fill="{T.TINT_TEAL}" stroke="{INK}" stroke-width="1.2"/>'
            f'<ellipse cx="{x}" cy="{y+1}" rx="5.5" ry="3" fill="{T.DEEP}"/><ellipse cx="{x}" cy="{y+1.5}" rx="3" ry="1.5" fill="{T.GLOW}"/>')

def build(p):
    h = base("Tentauri Seedpod hull")
    dw = p.get("dw", 100)
    # calyx: two side sepals and a middle one; thrusters set into the side sepals, wide apart
    vx, vy = p.get("vx", 104), p.get("vy", 322)
    for s in (-1, 1): h.raw(f"thrust-glow-{s}", {5: glow(CX + s * vx, vy + 14, 10, 14)})
    for s, name in ((-1, "port"), (1, "starboard")):
        pts = [(CX + s * 30, 238), (CX + s * 126, 244), (CX + s * 148, 316), (CX + s * 112, 332), (CX + s * p.get("sin", 72), 304)]
        rr = [20, 34, p.get("sepal_tip", 4), 22, 30]
        if s > 0: pts, rr = pts[::-1], rr[::-1]
        d = rounded_path(pts, rr)
        h.plate(f"sepal-{name}", d, T.TINT_TEAL, bevel=6, shadow=4, details=T.plate_details(d, [(CX + s * 116, 288, 14, T.CORAL, .35)]))
        h.raw(f"thruster-{name}", {5: vent(CX + s * vx, vy)})
    mid = sym([(CX, 250), (CX - 46, 262), (CX - 36, 322), (CX, 350)], [0, 30, 26, 6])
    h.plate("sepal-mid", mid, T.TINT_TEAL, bevel=6, shadow=4, details=T.plate_details(mid, [(CX, 310, 12, T.LAVENDER, .4)]))
    # petals
    tip, curl = p.get("tip", 22), p.get("curl", 0)
    for s, name in ((-1, "port"), (1, "starboard")):
        pts = [(CX + s * (14 + curl), 66 - tip), (CX + s * 100, 70), (CX + s * 140, 122), (CX + s * 148, 210),
               (CX + s * 124, 266), (CX + s * 60, 276), (CX + s * 72, 200)]
        rr = [p.get("tip_r", 4), 44, 40, 36, 30, 20, 40]
        if s > 0: pts, rr = pts[::-1], rr[::-1]
        d = rounded_path(pts, rr)
        veins = "".join(f'<path d="M{CX+s*(64+k*14)},{266-k*4} Q{CX+s*(112+k*12)},{186} {CX+s*(54+k*20)},{78+k*8}" fill="none" '
                        f'stroke="{T.DEEP}" stroke-width="1" opacity="{.28-k*.06:.2f}"/>' for k in range(p.get("veins", 1)))
        h.plate(f"petal-{name}", d, T.TINT_CORAL, bevel=6, shadow=4,
                details=T.plate_details(d, [(CX + s * 124, 140, 16, T.TEAL, .35), (CX + s * 120, 236, 12, T.LAVENDER, .35)]) + veins)
    nose = p.get("nose", 60)
    mid = sym([(CX, nose), (CX - 70, nose + 8), (CX - dw, 112), (CX - dw + 4, 190), (CX - dw + 22, 282), (CX - 32, 312), (CX, 314)],
              [0, 40, 36, 40, 30, 24, 0])
    lines = "".join(f'<path d="M{CX-dw+10+k*16},{232+k*14} Q{CX},{252+k*16} {CX+dw-10-k*16},{232+k*14}" fill="none" '
                    f'stroke="#ffffff" stroke-width="1.4" opacity="{.35-k*.08:.2f}"/>' for k in range(p.get("growth", 0)))
    h.plate("dorsal", mid, T.TINT_LAVENDER, bevel=7, shadow=4,
            details=T.plate_details(mid, p.get("spots", [(CX + 34, 150, 20, T.AQUA, .35), (CX - 44, 246, 14, T.CORAL, .3)])) + lines)
    h.raw("canopy", {5: T.single_canopy(CX, nose + 14, p.get("canopy", 28))})
    h.raw("supershield", {5: T.supershield_organ(CX, p.get("organ", 292))})
    return h

P = dict(sin=40, dw=90, tip=14, curl=-6, tip_r=6, veins=3, growth=3, canopy=24,
         spots=[(CX + 30, 140, 22, T.AQUA, .3), (CX - 40, 196, 16, T.CORAL, .22)])

if __name__ == "__main__":
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    h = build(P)
    s = h.svg(5)
    open(os.path.join(out, "tentauri-seedpod-hull.svg"), "w").write(s)
    open(os.path.join(out, "room-check.svg"), "w").write(s.replace("</svg>", rooms_svg() + "</svg>"))
    for st in range(1, 6):
        open(os.path.join(out, f"stage{st}.svg"), "w").write(h.svg(st, background="#ffffff" if st == 1 else None))
