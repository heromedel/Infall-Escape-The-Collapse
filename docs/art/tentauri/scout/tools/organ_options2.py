"""Option sheet: new Medbay and Life Support bases for the Tentauri scout, shown one tile each at 4x.

Usage: python3 organ_options2.py OUT.svg
"""
import math
import sys
import tentauri_floor as f
from tentauri_floor import T, ORGAN, ORGAN_EDGE, CORAL, LAVENDER_NODE, _pad, _stroke, bulb, organ_symbol

PINK = "#f6c9c0"


def at(c, r):
    x, y = f.cell(c, r)
    return x, y, x + T / 2


# ---- Medbay ----
def med_cocoon(name, c, r, kind):
    """An upright soft cocoon pod, seam down the middle, the orb set in its top."""
    x, y, cx = at(c, r)
    pod = (f'<ellipse cx="{cx}" cy="{y + 19}" rx="10" ry="13" fill="{PINK}" stroke="{ORGAN_EDGE}" stroke-width="1.3"/>'
           f'<path d="M{cx},{y + 20} L{cx},{y + 30}" stroke="{ORGAN_EDGE}" stroke-width=".9" opacity=".5"/>')
    return f'<g>{_pad(cx, y + T - 5, 12)}{pod}{bulb(cx, y + 13, 8)}{organ_symbol(kind, cx, y + 13, .58)}</g>'


def med_bud(name, c, r, kind):
    """A closed lavender bud: three petals cupping the orb from below, like something being tended."""
    x, y, cx = at(c, r)
    petals = "".join(f'<path d="M{cx},{y + T - 7} C{cx + s * 15},{y + 26} {cx + s * 14},{y + 12} {cx + s * 7},{y + 8} '
                     f'C{cx + s * 4},{y + 16} {cx + s * 2},{y + 22} {cx},{y + T - 7} Z" fill="{LAVENDER_NODE}" '
                     f'stroke="{ORGAN_EDGE}" stroke-width="1.2"/>' for s in (-1, 1))
    mid = (f'<path d="M{cx},{y + T - 7} C{cx - 6},{y + 24} {cx - 5},{y + 18} {cx},{y + 15} C{cx + 5},{y + 18} '
           f'{cx + 6},{y + 24} {cx},{y + T - 7} Z" fill="{PINK}" stroke="{ORGAN_EDGE}" stroke-width="1.1"/>')
    return f'<g>{_pad(cx, y + T - 6)}{petals}{mid}{bulb(cx, y + 13, 8)}{organ_symbol(kind, cx, y + 13, .58)}</g>'


def med_frond(name, c, r, kind):
    """A broad curled leaf lying under the orb like a bed, its tip curling up at the foot."""
    x, y, cx = at(c, r)
    leaf = (f'<path d="M{cx - 14},{y + 22} C{cx - 12},{y + 32} {cx + 10},{y + 33} {cx + 15},{y + 24} '
            f'C{cx + 16},{y + 20} {cx + 12},{y + 18} {cx + 10},{y + 21} C{cx + 4},{y + 25} {cx - 6},{y + 24} {cx - 14},{y + 22} Z" '
            f'fill="{ORGAN}" stroke="{ORGAN_EDGE}" stroke-width="1.3"/>'
            f'<path d="M{cx - 11},{y + 25} Q{cx},{y + 29} {cx + 11},{y + 25}" fill="none" stroke="{ORGAN_EDGE}" '
            f'stroke-width=".8" opacity=".5"/>')
    return f'<g>{leaf}{bulb(cx - 2, y + 12, 8.5)}{organ_symbol(kind, cx - 2, y + 12)}</g>'


def med_twin(name, c, r, kind):
    """Two gentle tendrils curving in from either side to touch the orb, like hands laid on a patient."""
    x, y, cx = at(c, r)
    arms = "".join(_stroke(f"M{cx + s * 12},{y + T - 6} C{cx + s * 15},{y + 18} {cx + s * 12},{y + 8} {cx + s * 7},{y + 9}",
                           4.6, 2.6, PINK) for s in (-1, 1))
    return f'<g>{_pad(cx, y + T - 5, 15)}{arms}{bulb(cx, y + 14, 8.5)}{organ_symbol(kind, cx, y + 14)}</g>'


# ---- Life Support ----
def life_gills(name, c, r, kind):
    """Feathery gill fronds fanning out either side of the orb, the way the race breathes."""
    x, y, cx = at(c, r)
    cy = y + 15
    out = []
    for s in (-1, 1):
        for a in (-30, 0, 30):
            ang = math.radians(a)
            ex, ey = cx + s * 15 * math.cos(ang), cy + 15 * math.sin(ang) * 0.8
            out.append(_stroke(f"M{cx + s * 5},{cy} Q{(cx + ex) / 2 + s * 1},{(cy + ey) / 2 - 2} {ex:.1f},{ey:.1f}", 3.6, 1.8, CORAL))
            for t in (.55, .8):
                fx, fy = cx + s * 5 + (ex - cx - s * 5) * t, cy + (ey - cy) * t
                out.append(f'<path d="M{fx:.1f},{fy:.1f} l{s * 2:.1f},-3" stroke="{CORAL}" stroke-width="1.2" stroke-linecap="round"/>')
    return f'<g>{_pad(cx, y + T - 6)}{"".join(out)}{_stroke(f"M{cx},{y + T - 7} L{cx},{cy + 5}", 4.6, 2.6)}{bulb(cx, cy, 8)}{organ_symbol(kind, cx, cy, .58)}</g>'


def life_bubbles(name, c, r, kind):
    """A cluster of small air sacs like a bunch of grapes, the orb rising from the top."""
    x, y, cx = at(c, r)
    pts = [(-9, 27), (0, 29), (9, 27), (-12, 20), (12, 20), (-5, 22), (5, 22)]
    sacs = "".join(f'<circle cx="{cx + dx}" cy="{y + dy}" r="4.6" fill="{ORGAN}" stroke="{ORGAN_EDGE}" stroke-width="1.1"/>'
                   f'<circle cx="{cx + dx - 1.4}" cy="{y + dy - 1.4}" r="1.3" fill="#ffffff" opacity=".6"/>' for dx, dy in pts)
    return f'<g>{sacs}{bulb(cx, y + 12, 8.5)}{organ_symbol(kind, cx, y + 12)}</g>'


def life_snorkels(name, c, r, kind):
    """Two breathing tubes curving up behind the orb, open mouths at their tips."""
    x, y, cx = at(c, r)
    tubes = "".join(_stroke(f"M{cx + s * 4},{y + T - 7} C{cx + s * 6},{y + 18} {cx + s * 12},{y + 14} {cx + s * 12},{y + 5}", 5.4, 3.4)
                    + f'<ellipse cx="{cx + s * 12}" cy="{y + 5}" rx="3.6" ry="2.4" fill="{ORGAN_EDGE}" stroke="{ORGAN}" stroke-width="1.2"/>'
                    for s in (-1, 1))
    return f'<g>{_pad(cx, y + T - 6)}{tubes}{bulb(cx, y + 20, 8)}{organ_symbol(kind, cx, y + 20, .58)}</g>'


def life_frill(name, c, r, kind):
    """A wavy frilled collar ringing the orb, rippling like breathing tissue."""
    x, y, cx = at(c, r)
    cy = y + 16
    pts = []
    for i in range(37):
        a = i * math.pi * 2 / 36
        rr = 13 + 2 * math.sin(a * 6)
        pts.append(f"{cx + rr * math.cos(a):.1f},{cy + rr * math.sin(a) * .85:.1f}")
    frill = f'<polygon points="{" ".join(pts)}" fill="{PINK}" stroke="{ORGAN_EDGE}" stroke-width="1.2" stroke-linejoin="round"/>'
    return f'<g>{frill}{bulb(cx, cy, 8.5)}{organ_symbol(kind, cx, cy)}</g>'


MED = [("cocoon", med_cocoon), ("bud", med_bud), ("leaf bed", med_frond), ("laying on of tendrils", med_twin)]
LIFE = [("gills", life_gills), ("air sacs", life_bubbles), ("snorkels", life_snorkels), ("frill", life_frill)]

if __name__ == "__main__":
    S, gap = 4, 30
    cells = []
    for row, (label, opts, kind) in enumerate([("Medbay", MED, "medbay"), ("Life Support", LIFE, "life")]):
        cells.append(f'<text x="12" y="{30 + row * 210}" font-family="sans-serif" font-size="16" fill="#cfd6e2">{label}</text>')
        for i, (n, fn) in enumerate(opts):
            ox, oy = 12 + i * (T * S + gap), 40 + row * 210
            cells.append(f'<g transform="translate({ox},{oy}) scale({S}) translate({-f.X0},{-f.Y0})">'
                         f'<rect x="{f.X0}" y="{f.Y0}" width="{T}" height="{T}" fill="{f.FLOOR}"/>{fn(label, 0, 0, kind)}</g>'
                         f'<text x="{ox + T * S / 2}" y="{oy + T * S + 18}" text-anchor="middle" font-family="sans-serif" '
                         f'font-size="13" fill="#9aa4b4">{i + 1}. {n}</text>')
    W = 12 + 4 * (T * S + gap)
    import tentauri_weapons as tw
    open(sys.argv[1], "w").write(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="440">{tw.defs()}'
                                 f'<rect width="100%" height="100%" fill="#141a24"/>{"".join(cells)}</svg>')
