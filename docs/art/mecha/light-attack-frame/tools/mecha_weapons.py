"""Mecha weapon art, separate files centred on their mount point at (0, 0), pointing up: the DS-ST Hull Laser and
the laser battlesuit (the EVB Dock's suit type).

Usage: python3 mecha_weapons.py OUT_DIR
Three styles of each, plus option sheets. Mechanical: gunmetal, black, hazard yellow and orange, stencils.
"""
import os
import sys

INK = "#1b2230"
GUN = "#4b5159"
GUN_D = "#3c4148"
GUN_L = "#6a717a"
BLACK = "#202328"
STEEL = "#8a929c"
YELLOW = "#f0c02c"
ORANGE = "#ec7a1e"
HEAT = "#ff8a3c"
VISOR = "#ffb43c"


def defs():
    return ('<defs><linearGradient id="mw-metal" x1="0" y1="0" x2="1" y2="0">'
            f'<stop offset="0" stop-color="{GUN_L}"/><stop offset=".5" stop-color="{GUN}"/><stop offset="1" stop-color="{GUN_D}"/>'
            '</linearGradient><filter id="mw-glow" x="-100%" y="-100%" width="300%" height="300%" filterUnits="objectBoundingBox">'
            '<feGaussianBlur stdDeviation="1.6"/></filter>'
            f'<pattern id="mw-hz" width="5" height="5" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">'
            f'<rect width="5" height="5" fill="{BLACK}"/><rect width="2.5" height="5" fill="{YELLOW}"/></pattern></defs>')


def r(x, y, w, h, fill, rx=1.5, sw=1.2):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{fill}" stroke="{INK}" stroke-width="{sw}"/>'


def ring():
    """The hardpoint ring the weapon turns on (matches the pod's ring)."""
    return f'<circle cx="0" cy="0" r="12" fill="{BLACK}" stroke="{INK}" stroke-width="1.3"/><circle cx="0" cy="0" r="9" fill="none" stroke="{STEEL}" stroke-width="1"/>'


def emitter(x, y, w=6):
    return (f'<rect x="{x - w / 2}" y="{y - 2}" width="{w}" height="3" fill="{HEAT}" opacity=".7" filter="url(#mw-glow)"/>'
            f'<rect x="{x - w / 2 + 1}" y="{y - 1}" width="{w - 2}" height="1.6" fill="#ffd9a8"/>')


# ---------- DS-ST Hull Laser ----------

def hl_twin():
    """Twin barrels side by side on a squat turret block: one barrel per shot of the double shot."""
    body = r(-13, -10, 26, 22, "url(#mw-metal)", 3)
    barrels = "".join(r(x - 4, -40, 8, 32, GUN_D, 1.2) + f'<rect x="{x - 4}" y="-28" width="8" height="2" fill="{BLACK}"/>'
                      + r(x - 5, -44, 10, 6, BLACK, 1) + emitter(x, -44, 6) for x in (-6, 6))
    det = (f'<rect x="-11" y="4" width="22" height="5" fill="url(#mw-hz)"/>'
           + f'<rect x="-9" y="-6" width="18" height="6" rx="1" fill="{BLACK}"/>')
    return f'<g id="weapon-ds-st-hull-laser">{ring()}{barrels}{body}{det}</g>'


def hl_breaker():
    """A heavy breaker: one broad flat barrel with two emitter jaws, heat fins along its sides."""
    body = r(-14, -8, 28, 20, "url(#mw-metal)", 3)
    barrel = (r(-8, -42, 16, 36, GUN_D, 2) + "".join(f'<rect x="{s * 8 - (2 if s > 0 else 0)}" y="{-34 + i * 6}" width="2" height="3" fill="{ORANGE}" opacity=".85"/>'
                                                     for s in (-1, 1) for i in range(4))
              + r(-9, -48, 7, 9, BLACK, 1) + r(2, -48, 7, 9, BLACK, 1) + emitter(-5.5, -48, 5) + emitter(5.5, -48, 5))
    det = f'<rect x="-12" y="4" width="24" height="5" fill="url(#mw-hz)"/><circle cx="0" cy="-2" r="4" fill="{BLACK}"/>'
    return f'<g id="weapon-ds-st-hull-laser">{ring()}{barrel}{body}{det}</g>'


def hl_stacked():
    """Over-and-under: a long barrel with two capacitor drums, one per shot, slung beneath."""
    body = r(-12, -6, 24, 18, "url(#mw-metal)", 3)
    barrel = r(-5, -46, 10, 42, GUN_D, 1.5) + r(-6.5, -50, 13, 6, BLACK, 1) + emitter(0, -50, 8)
    drums = "".join(f'<circle cx="{x}" cy="-14" r="6" fill="{GUN}" stroke="{INK}" stroke-width="1.2"/><circle cx="{x}" cy="-14" r="2.5" fill="{YELLOW}"/>'
                    for x in (-9, 9))
    det = f'<rect x="-10" y="4" width="20" height="5" fill="url(#mw-hz)"/>'
    return f'<g id="weapon-ds-st-hull-laser">{ring()}{drums}{barrel}{body}{det}</g>'


# ---------- laser battlesuit ----------

def bs_brute():
    """A squat armoured suit: broad shoulders, a hunched helm with a visor slit, the laser on the right arm, a jump pack."""
    pack = r(-9, 6, 18, 12, BLACK, 2) + "".join(f'<rect x="{x - 3}" y="17" width="6" height="5" rx="1" fill="{HEAT}" opacity=".7" filter="url(#mw-glow)"/>' for x in (-5, 5))
    body = r(-11, -8, 22, 18, "url(#mw-metal)", 4)
    arms = r(-19, -6, 8, 14, GUN, 3) + r(11, -14, 7, 20, GUN_D, 2) + r(12, -22, 5, 9, BLACK, 1) + emitter(14.5, -22, 4)
    shoulders = r(-21, -10, 11, 9, BLACK, 3) + r(10, -10, 11, 9, BLACK, 3) + f'<rect x="-20" y="-9" width="9" height="3" fill="url(#mw-hz)"/>'
    helm = r(-6, -14, 12, 10, GUN_D, 4) + f'<rect x="-4.5" y="-12" width="9" height="2" rx="1" fill="{VISOR}"/>'
    return f'<g id="battlesuit-laser">{pack}{arms}{body}{shoulders}{helm}</g>'


def bs_beetle():
    """A rounded shell suit like a beetle's back, a short laser snout forward, two thrusters behind."""
    thr = "".join(f'<rect x="{x - 3}" y="13" width="6" height="6" rx="1" fill="{HEAT}" opacity=".7" filter="url(#mw-glow)"/>' for x in (-6, 6))
    shell = f'<path d="M-15,8 Q-16,-12 0,-16 Q16,-12 15,8 Q0,14 -15,8 Z" fill="url(#mw-metal)" stroke="{INK}" stroke-width="1.3"/>'
    seam = f'<path d="M0,-15 V10" stroke="{BLACK}" stroke-width="1.2"/><path d="M-14,2 Q0,6 14,2" fill="none" stroke="{YELLOW}" stroke-width="1.6"/>'
    snout = r(-3, -27, 6, 13, GUN_D, 1.2) + emitter(0, -27, 4)
    visor = f'<rect x="-6" y="-12" width="12" height="2" rx="1" fill="{VISOR}"/>'
    return f'<g id="battlesuit-laser">{thr}{snout}{shell}{seam}{visor}</g>'


def bs_frame():
    """An angular frame suit: a narrow torso, long arms with the laser on one and a clamp on the other, wide feet."""
    feet = r(-14, 8, 9, 8, BLACK, 2) + r(5, 8, 9, 8, BLACK, 2) + f'<rect x="-3" y="10" width="6" height="6" rx="1" fill="{HEAT}" opacity=".7" filter="url(#mw-glow)"/>'
    torso = f'<path d="M-9,-10 L9,-10 L12,0 L7,10 L-7,10 L-12,0 Z" fill="url(#mw-metal)" stroke="{INK}" stroke-width="1.3"/>'
    arms = (r(12, -26, 5, 24, GUN_D, 1.5) + emitter(14.5, -26, 4) + r(-17, -18, 5, 16, GUN, 1.5)
            + f'<path d="M-18,-18 l-2,-5 M-13,-18 l2,-5" stroke="{STEEL}" stroke-width="1.6"/>')
    shoulders = f'<path d="M-16,-9 L-8,-12 L-8,-3 L-17,-2 Z" fill="{YELLOW}" stroke="{INK}" stroke-width="1"/><path d="M16,-9 L8,-12 L8,-3 L17,-2 Z" fill="{BLACK}" stroke="{INK}" stroke-width="1"/>'
    helm = r(-4, -16, 8, 7, BLACK, 2) + f'<rect x="-3" y="-14" width="6" height="1.6" fill="{VISOR}"/>'
    return f'<g id="battlesuit-laser">{feet}{arms}{torso}{shoulders}{helm}</g>'


HULL_LASERS = {"twin": hl_twin, "breaker": hl_breaker, "stacked": hl_stacked}
SUITS = {"brute": bs_brute, "beetle": bs_beetle, "frame": bs_frame}


def file(body, w, h, ox, oy):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">{defs()}'
            f'<g transform="translate({ox},{oy})">{body}</g></svg>\n')


def sheet(items, label_y, scale=3, centre=-40):
    cells = ""
    for i, (name, fn) in enumerate(items.items()):
        x = 90 + i * 170
        cells += (f'<g transform="translate({x},{label_y + centre}) scale({scale})">{fn()}</g>'
                  f'<text x="{x}" y="{label_y + 40}" font-size="13" fill="#cfd6e2" text-anchor="middle" font-family="sans-serif">{i + 1}. {name}</text>')
    return cells


if __name__ == "__main__":
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    for name, fn in HULL_LASERS.items():
        open(os.path.join(out, f"ds-st-hull-laser-{name}.svg"), "w").write(file(fn(), 40, 70, 20, 54))
    for name, fn in SUITS.items():
        open(os.path.join(out, f"battlesuit-laser-{name}.svg"), "w").write(file(fn(), 50, 56, 25, 30))
    open(os.path.join(out, "mecha-weapon-options.svg"), "w").write(
        f'<svg xmlns="http://www.w3.org/2000/svg" width="520" height="470">{defs()}<rect width="100%" height="100%" fill="#2a2f36"/>'
        f'<text x="14" y="24" font-size="15" fill="#e6ebf2" font-family="sans-serif">DS-ST Hull Laser</text>{sheet(HULL_LASERS, 200, 2.6, -20)}'
        f'<text x="14" y="276" font-size="15" fill="#e6ebf2" font-family="sans-serif">Laser battlesuit</text>{sheet(SUITS, 400)}</svg>')
    print("saved")
