"""Builds the same ship as a hand-structured SVG: named groups per part, shared defs for shading."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ship_png import (NACELLE, HULL_PTS, DECK, NOSE, BAND_HULL, BAND_NAC, mirror, cw, inset, facing,
                      HULL, HULL_LIGHT, ACCENT, OUTLINE, W, H)

OUT = sys.argv[1] if len(sys.argv) > 1 else "ship.svg"


def hexc(c, k=1.0):
    return "#%02x%02x%02x" % tuple(max(0, min(255, int(v * k))) for v in c[:3])


def pts(p):
    return " ".join(f"{x:.1f},{y:.1f}" for x, y in p)


def plate(pid, p, base, bevel, band=None):
    """A chamfered plate: bevel facets shaded by normal, flat face, lit lips and creases."""
    p = cw(p)
    inner = inset(p, bevel)
    n = len(p)
    out = [f'<g id="{pid}">']
    facets, lips = [], []
    for i in range(n):
        a, b = p[i], p[(i + 1) % n]
        ia, ib = inner[i], inner[(i + 1) % n]
        f = facing(a, b)
        c = hexc(base, 1 + .30 * f)
        facets.append(f'<polygon points="{pts([a, b, ib, ia])}" fill="{c}" stroke="{c}" stroke-width=".6" stroke-linejoin="round"/>')
        if f > .4:
            lips.append(f'<line x1="{ia[0]:.1f}" y1="{ia[1]:.1f}" x2="{ib[0]:.1f}" y2="{ib[1]:.1f}" '
                        f'stroke="{hexc(base, min(1.30, 238 / max(base)))}"/>')
        elif f < -.4:
            lips.append(f'<line x1="{ia[0]:.1f}" y1="{ia[1]:.1f}" x2="{ib[0]:.1f}" y2="{ib[1]:.1f}" '
                        f'stroke="{hexc(base, .70)}"/>')
    out.append('<g class="bevel">' + "".join(facets) + "</g>")
    out.append(f'<polygon class="face" points="{pts(inner)}" fill="{hexc(base)}"/>')
    out.append(f'<polygon class="sheen" points="{pts(inner)}" fill="url(#sheen)"/>')
    out.append('<g class="lips" stroke-width="1" stroke-linecap="round">' + "".join(lips) + "</g>")
    if band:
        bid = pid + "-band"
        tint = []
        for i in range(n):
            a, b = p[i], p[(i + 1) % n]
            tint.append(f'<polygon points="{pts([a, b, inner[(i + 1) % n], inner[i]])}" '
                        f'fill="{hexc(ACCENT, 1 + .30 * facing(a, b))}" stroke="{hexc(ACCENT, 1 + .30 * facing(a, b))}" stroke-width=".6"/>')
        tint.append(f'<polygon points="{pts(inner)}" fill="{hexc(ACCENT)}"/>')
        out.append(f'<clipPath id="{bid}-clip"><polygon points="{pts(band)}"/></clipPath>')
        out.append(f'<g class="accent" clip-path="url(#{bid}-clip)">' + "".join(tint) + "</g>")
    out.append(f'<polygon class="outline" points="{pts(p)}" fill="none" stroke="{hexc(OUTLINE)}" '
               f'stroke-width="2" stroke-linejoin="round"/>')
    out.append("</g>")
    return "\n".join(out)


def thruster(x, y, length=26, r=10):
    ribs = "".join(
        f'<line x1="{x - length * i / 4:.1f}" y1="{y - r * (.65 + .35 * i / 4):.1f}" '
        f'x2="{x - length * i / 4:.1f}" y2="{y + r * (.65 + .35 * i / 4):.1f}"/>' for i in range(1, 4))
    return f'''<g class="thruster">
  <polygon points="{pts([(x, y - r * .65), (x - length, y - r), (x - length, y + r), (x, y + r * .65)])}" fill="#54565a"/>
  <polygon points="{pts([(x, y - r * .65), (x - length, y - r), (x - length, y - r * .2), (x, y - r * .1)])}" fill="#3e4044"/>
  <polygon points="{pts([(x, y + r * .25), (x - length, y + r * .35), (x - length, y + r), (x, y + r * .65)])}" fill="#787a7e"/>
  <g stroke="#303236" stroke-width="1">{ribs}</g>
  <polygon points="{pts([(x, y - r * .65), (x - length, y - r), (x - length, y + r), (x, y + r * .65)])}" fill="none" stroke="#1e2024" stroke-width="2" stroke-linejoin="round"/>
  <rect x="{x - length - 3}" y="{y - r + 1}" width="3" height="{2 * r - 2}" fill="#1e2024"/>
  <ellipse class="engine-glow" cx="{x - length - 4}" cy="{y}" rx="5" ry="{r * .7:.1f}" fill="#ff9a40" opacity=".75" filter="url(#glow)"/>
  <rect x="{x - length - 2}" y="{y - r * .55:.1f}" width="1.5" height="{r * 1.1:.1f}" fill="#ffd9a0"/>
</g>'''


def seam(a, b):
    return (f'<line x1="{a[0]}" y1="{a[1]}" x2="{b[0]}" y2="{b[1]}" stroke="#606263"/>'
            f'<line x1="{a[0] + .8}" y1="{a[1] + .8}" x2="{b[0] + .8}" y2="{b[1] + .8}" stroke="#d4d6cf"/>')


def rivet(x, y):
    return f'<use href="#rivet" x="{x}" y="{y}"/>'


ident = lambda p: p
parts = []

# nacelles (with engines behind them)
for side, flip in (("port", ident), ("starboard", mirror)):
    g = [f'<g id="nacelle-{side}">']
    for dy in (-16, 0, 16):
        g.append(thruster(52, flip([(0, 73 + dy)])[0][1]))
    g.append(plate(f"nacelle-{side}-hull", flip(NACELLE), HULL, 9, band=flip(BAND_NAC)))
    det = []
    for x in (104, 196):
        a, b = sorted(flip([(x, 52), (x, 94)]), key=lambda q: q[1])
        det.append(seam(a, b))
    (x0, y0), (x1, y1) = flip([(176, 64), (196, 70)])
    det.append(f'<rect x="{min(x0, x1)}" y="{min(y0, y1)}" width="20" height="6" fill="#3c3e40"/>')
    for x in (62, 238):
        for y in (48, 98):
            det.append(rivet(*flip([(x, y)])[0]))
    g.append('<g class="details">' + "".join(det) + "</g></g>")
    parts.append("\n".join(g))

parts.append(thruster(90, 165, length=24, r=12))
parts.append(f'<polygon id="hull-shadow" points="{pts([(x + 5, y + 8) for x, y in HULL_PTS])}" '
             f'fill="#14161a" opacity=".8" filter="url(#soft)" clip-path="url(#nacelles-clip)"/>')
parts.append(plate("hull", HULL_PTS, HULL, 14, band=BAND_HULL))
parts.append(plate("nose", NOSE, HULL, 7))
parts.append(plate("deck", DECK, HULL_LIGHT, 7))

det = ['<g id="hull-details">']
for x in (210, 280):
    det.append(seam((x, 128), (x, 202)))
det.append(seam((142, 165), (208, 165)))
det.append('<g id="vent"><rect x="228" y="152" width="34" height="26" fill="#424446" stroke="#1e2024"/>' +
           "".join(f'<rect x="{231 + i * 4}" y="154" width="2" height="22" fill="#969894"/>' for i in range(8)) + "</g>")
for y in (140, 172):
    det.append(f'<rect class="hatch" x="166" y="{y}" width="34" height="18" rx="3" fill="none" stroke="#686a6a"/>'
               f'<line x1="168" y1="{y + 17}" x2="198" y2="{y + 17}" stroke="#e8eae4"/>')
for side in (ident, mirror):
    for x0 in (116, 128):
        det.append(f'<polygon points="{pts(side([(x0, 118), (x0 + 8, 118), (x0 + 8, 140), (x0, 140)]))}" '
                   f'fill="#969893" stroke="#626464" stroke-width=".5"/>')
det.append('<g id="sensor-dome"><circle cx="367" cy="165" r="11" fill="#46484c" stroke="#1e2024"/>'
           '<circle cx="367" cy="165" r="8" fill="#70b4c8"/><circle cx="365" cy="162" r="3" fill="#dcf4fa"/></g>')
glass = [(468, 154), (498, 161), (506, 165), (498, 169), (468, 176), (474, 165)]
det.append(f'<g id="cockpit"><polygon points="{pts(glass)}" fill="#1e3e58" stroke="#1e2024" stroke-linejoin="round"/>'
           f'<polygon points="{pts([(472, 156), (496, 161.5), (484, 162.5), (475, 161)])}" fill="#96d2ec"/></g>')
for x in range(176, 306, 16):
    det.append(rivet(x, 106) + rivet(x, 224))
for y in (94, 236):
    det.append(f'<rect x="232" y="{y - 3}" width="30" height="6" fill="#46484a" stroke="#1e2024"/>')
for y in (132, 198):
    det.append(f'<rect class="hardpoint" x="420" y="{y - 4}" width="14" height="8" fill="#505256" stroke="#1e2024"/>')
det.append('<g id="antenna"><line x1="120" y1="40" x2="120" y2="24" stroke="#1e2024" stroke-width="2"/>'
           '<circle cx="120" cy="23" r="3" fill="#d65642" stroke="#1e2024"/></g>')
det.append("</g>")
parts.append("".join(det))

nacelle_clip = "".join(f'<polygon points="{pts(f(NACELLE))}"/>' for f in (ident, mirror))
svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">
<title>Infall test scout</title>
<defs>
  <filter id="soft" x="-10%" y="-10%" width="120%" height="120%"><feGaussianBlur stdDeviation="4"/></filter>
  <filter id="grain" x="0" y="0" width="100%" height="100%">
    <feTurbulence type="fractalNoise" baseFrequency=".55" numOctaves="2" seed="7" result="n"/>
    <feColorMatrix in="n" type="saturate" values="0" result="g"/>
    <feComposite in="g" in2="SourceAlpha" operator="in" result="gm"/>
    <feBlend in="SourceGraphic" in2="gm" mode="overlay" result="b"/>
    <feComposite in="b" in2="SourceGraphic" operator="arithmetic" k2=".10" k3=".90"/>
  </filter>
  <linearGradient id="sheen" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#000" stop-opacity=".07"/>
    <stop offset=".55" stop-color="#000" stop-opacity="0"/>
    <stop offset="1" stop-color="#fff" stop-opacity=".10"/>
  </linearGradient>
  <filter id="glow" x="-100%" y="-100%" width="300%" height="300%"><feGaussianBlur stdDeviation="2.5"/></filter>
  <clipPath id="nacelles-clip">{nacelle_clip}</clipPath>
  <g id="rivet"><circle r="1.2" fill="#686a6a"/><circle cx=".2" cy=".4" r=".7" fill="#e2e4de"/></g>
</defs>
<g id="ship" filter="url(#grain)">
{chr(10).join(parts)}
</g>
</svg>
'''
open(OUT, "w").write(svg)
print("saved", OUT, len(svg), "bytes")
