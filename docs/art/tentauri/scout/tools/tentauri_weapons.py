"""Tentauri Defense Laser weapon art: separate files, centred on the mount point at (0, 0), pointing up.

Usage: python3 tentauri_weapons.py OUT_DIR
First pass (2026-10-23): three styles from the race's anatomy: a siphon emitter, a coiled tendril, a grasping cradle.
Second pass (2026-10-25): narrower and longer, a glowing emitter tip instead of an eye-like mouth, darker teal and
lavender accents for contrast on the pale hull: sac and barrel, paired fronds, swept siphon, and segmented, the
Defense Laser now (a plain jointed barrel that fits other races' ships too).
"""
import os
import sys

INK = "#1b2230"
PEARL = "#eef2f3"
TEAL = "#3aa9a6"
AQUA = "#7fe0dc"
CORAL = "#f0a99f"
LAVENDER = "#b9b2e6"
DEEP = "#24485a"
GLOW = "#8ff5e6"


def defs():
    return ('<defs><linearGradient id="tw-nacre" x1="0" y1="0" x2="1" y2="1">'
            f'<stop offset="0" stop-color="{PEARL}"/><stop offset=".45" stop-color="{AQUA}"/>'
            f'<stop offset=".8" stop-color="{LAVENDER}"/><stop offset="1" stop-color="{TEAL}"/></linearGradient>'
            '<filter id="tw-glow" x="-100%" y="-100%" width="300%" height="300%"><feGaussianBlur stdDeviation="2"/></filter>'
            '</defs>')


def base():
    """A soft rounded seat that grows out of the hull lobe."""
    return (f'<ellipse cx="0" cy="6" rx="15" ry="11" fill="url(#tw-nacre)" stroke="{INK}" stroke-width="1.4"/>'
            f'<ellipse cx="-4" cy="3" rx="6" ry="3" fill="#ffffff" opacity=".35"/>')


def lens(y):
    return (f'<circle cx="0" cy="{y}" r="6" fill="{GLOW}" opacity=".6" filter="url(#tw-glow)"/>'
            f'<circle cx="0" cy="{y}" r="3.6" fill="{DEEP}" stroke="{INK}" stroke-width="1"/>'
            f'<circle cx="0" cy="{y}" r="1.8" fill="{GLOW}"/>')


def siphon():
    """A siphon emitter: a smooth tapered tube with a ringed mouth and a lens inside."""
    tube = (f'<path d="M-8,4 C-9,-14 -7,-28 -6,-34 L6,-34 C7,-28 9,-14 8,4 Z" fill="url(#tw-nacre)" stroke="{INK}" '
            f'stroke-width="1.4"/>'
            + "".join(f'<path d="M-7.5,{y} Q0,{y + 2.5} 7.5,{y}" fill="none" stroke="{TEAL}" stroke-width="1" '
                      f'opacity=".7"/>' for y in (-6, -16, -26))
            + f'<ellipse cx="0" cy="-35" rx="8.5" ry="4.5" fill="{PEARL}" stroke="{INK}" stroke-width="1.3"/>')
    return f'<g id="weapon-defense-laser">{base()}{tube}{lens(-35)}</g>'


def tendril():
    """A coiled tendril: a curled stalk rising from the seat, holding the lens at its tip."""
    coil = (f'<path d="M0,2 C-14,-4 -14,-18 -2,-20 C10,-22 10,-34 0,-38" fill="none" stroke="{INK}" stroke-width="8" '
            f'stroke-linecap="round"/><path d="M0,2 C-14,-4 -14,-18 -2,-20 C10,-22 10,-34 0,-38" fill="none" '
            f'stroke="{AQUA}" stroke-width="5.4" stroke-linecap="round"/><path d="M-1,1 C-12,-5 -12,-17 -3,-19" '
            f'fill="none" stroke="#ffffff" stroke-width="1.4" opacity=".5"/>')
    return f'<g id="weapon-defense-laser">{base()}{coil}{lens(-40)}</g>'


def grasp():
    """A grasping cradle: three short curved fingers closing around a lens."""
    fingers = "".join(f'<path d="M{x},2 C{x * 1.6},-12 {x * 1.2},-26 {x * .3},-34" fill="none" stroke="{INK}" '
                      f'stroke-width="7" stroke-linecap="round"/><path d="M{x},2 C{x * 1.6},-12 {x * 1.2},-26 '
                      f'{x * .3},-34" fill="none" stroke="{CORAL}" stroke-width="4.4" stroke-linecap="round"/>'
                      for x in (-7, 7))
    mid = (f'<path d="M0,2 L0,-24" stroke="{INK}" stroke-width="7" stroke-linecap="round"/>'
           f'<path d="M0,2 L0,-24" stroke="{AQUA}" stroke-width="4.4" stroke-linecap="round"/>')
    return f'<g id="weapon-defense-laser">{base()}{mid}{fingers}{lens(-30)}</g>'


STYLES = {"siphon": siphon, "tendril": tendril, "grasp": grasp}


# ---------- second pass ----------

TEAL2 = "#2f8f8c"
TEAL_D = "#1f5f63"
LAV = "#b9b2e6"
LAV_D = "#7468b8"
CORAL = "#f0a99f"
GLOW = "#8ff5e6"


def defs2():
    return ('<defs>'
            f'<linearGradient id="l2-nacre" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="{PEARL}"/>'
            f'<stop offset=".35" stop-color="{AQUA}"/><stop offset=".75" stop-color="{TEAL2}"/><stop offset="1" stop-color="{TEAL_D}"/></linearGradient>'
            f'<linearGradient id="l2-sac" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="{LAV}"/>'
            f'<stop offset="1" stop-color="{LAV_D}"/></linearGradient>'
            '<filter id="l2-glow" x="-200%" y="-200%" width="500%" height="500%"><feGaussianBlur stdDeviation="1.8"/></filter>'
            '</defs>')


def tip(y, r=3.2):
    """A glowing emitter bud at the barrel's tip, seen from above: a soft bright point, no ring, no pupil."""
    return (f'<ellipse cx="0" cy="{y}" rx="{r * 1.8}" ry="{r * 2.2}" fill="{GLOW}" opacity=".55" filter="url(#l2-glow)"/>'
            f'<path d="M{-r},{y + r} Q{-r},{y - r * 1.4} 0,{y - r * 1.7} Q{r},{y - r * 1.4} {r},{y + r} Z" fill="{GLOW}" stroke="{TEAL_D}" stroke-width=".9"/>'
            f'<ellipse cx="-.8" cy="{y - r * .4}" rx="{r * .35}" ry="{r * .7}" fill="#ffffff" opacity=".8"/>')


def ribs(x0, x1, ys):
    return "".join(f'<path d="M{x0},{y} Q0,{y + 1.6} {x1},{y}" fill="none" stroke="{TEAL_D}" stroke-width=".8" opacity=".7"/>' for y in ys)


def barrel(top, bottom, w_top, w_bot):
    return (f'<path d="M{-w_bot},{bottom} C{-w_bot},{bottom - 10} {-w_top},{top + 8} {-w_top},{top} L{w_top},{top} '
            f'C{w_top},{top + 8} {w_bot},{bottom - 10} {w_bot},{bottom} Z" fill="url(#l2-nacre)" stroke="{INK}" stroke-width="1.3"/>')


def sac_barrel():
    """Sac and barrel: a long tapered barrel rising from a soft energy sac set to one side."""
    sac = (f'<path d="M-9,8 C-14,6 -14,-6 -8,-8 C-2,-10 6,-6 8,0 C10,6 6,12 0,12 C-4,12 -7,10 -9,8 Z" fill="url(#l2-sac)" stroke="{INK}" stroke-width="1.3"/>'
           f'<ellipse cx="-6" cy="-3" rx="3" ry="2" fill="#ffffff" opacity=".35"/>')
    return sac + barrel(-40, 2, 3.2, 6) + ribs(-4.6, 4.6, (-8, -18, -28)) + tip(-41)


def paired_fronds():
    """Paired fronds: the barrel held between two soft lavender fronds curling up its sides."""
    fronds = "".join(f'<path d="M{s * 3},6 C{s * 12},2 {s * 11},-14 {s * 5},-22 C{s * 7},-12 {s * 6},-2 {s * 2},2 Z" '
                     f'fill="url(#l2-sac)" stroke="{INK}" stroke-width="1.1"/>' for s in (-1, 1))
    base = f'<ellipse cx="0" cy="7" rx="8" ry="6" fill="{TEAL2}" stroke="{INK}" stroke-width="1.2"/>'
    return base + fronds + barrel(-42, 4, 3, 5.4) + ribs(-4, 4, (-10, -20, -30)) + tip(-43)


def swept_siphon():
    """Swept siphon: the barrel leans off a bulbous base, with a coral gill frill at its root on one side."""
    base = (f'<path d="M-10,10 C-13,0 -8,-8 0,-8 C8,-8 12,0 10,10 C6,14 -6,14 -10,10 Z" fill="url(#l2-sac)" stroke="{INK}" stroke-width="1.3"/>'
            f'<path d="M6,-4 C11,-6 13,-2 12,2 C10,0 8,0 6,1 Z" fill="{CORAL}" stroke="{INK}" stroke-width=".9"/>'
            f'<path d="M7,2 C12,1 13,5 11,8 C10,6 8,5 7,6 Z" fill="{CORAL}" stroke="{INK}" stroke-width=".9"/>')
    return base + barrel(-40, -2, 3, 5.6) + ribs(-4.4, 4.4, (-12, -22, -31)) + tip(-41)


def segmented():
    """Segmented: a jointed barrel of three soft segments, narrowing to the tip, on a small teal pad."""
    pad = f'<ellipse cx="0" cy="6" rx="9" ry="7" fill="{TEAL_D}" stroke="{INK}" stroke-width="1.2"/><ellipse cx="-2" cy="4" rx="5" ry="3" fill="{TEAL2}"/>'
    segs = ""
    for i, (t, b, wt, wb) in enumerate(((-14, 4, 4.8, 6), (-28, -12, 3.9, 4.8), (-40, -26, 3, 3.9))):
        segs += (f'<path d="M{-wb},{b} C{-wb - 1},{(t + b) / 2} {-wt - 1},{t + 2} {-wt},{t} L{wt},{t} C{wt + 1},{t + 2} {wb + 1},{(t + b) / 2} {wb},{b} Z" '
                 f'fill="url(#l2-nacre)" stroke="{INK}" stroke-width="1.2"/>')
    return pad + segs + tip(-41)


STYLES2 = {"sac-and-barrel": sac_barrel, "paired-fronds": paired_fronds, "swept-siphon": swept_siphon, "segmented": segmented}



def file(body, w=60, h=80, ox=30, oy=56):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">{defs()}{defs2()}'
            f'<g transform="translate({ox},{oy})">{body}</g></svg>\n')


if __name__ == "__main__":
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    cells = ""
    for i, (name, fn) in enumerate(STYLES.items()):
        open(os.path.join(out, f"defense-laser-{name}.svg"), "w").write(file(fn()))
        cells += (f'<g transform="translate({60 + i * 120},100) scale(2)">{fn()}</g>'
                  f'<text x="{60 + i * 120}" y="150" font-size="12" fill="#cfd6e2" text-anchor="middle" '
                  f'font-family="sans-serif">{name}</text>')
    open(os.path.join(out, "defense-laser-options.svg"), "w").write(
        f'<svg xmlns="http://www.w3.org/2000/svg" width="370" height="165">{defs()}'
        f'<rect width="100%" height="100%" fill="#f2dcd6"/>{cells}</svg>')
    for name, fn in STYLES2.items():
        open(os.path.join(out, f"defense-laser-{name}.svg"), "w").write(file(fn()))
    open(os.path.join(out, "defense-laser.svg"), "w").write(file(segmented()))
    cells = "".join(f'<g transform="translate({60 + i * 110},130) scale(2)">{fn()}</g>'
                    f'<text x="{60 + i * 110}" y="165" font-size="12" fill="#cfd6e2" text-anchor="middle" '
                    f'font-family="sans-serif">{name.replace("-", " ")}</text>' for i, (name, fn) in enumerate(STYLES2.items()))
    open(os.path.join(out, "defense-laser-options-2.svg"), "w").write(
        f'<svg xmlns="http://www.w3.org/2000/svg" width="450" height="180">{defs2()}'
        f'<rect width="100%" height="100%" fill="#f2dcd6"/>{cells}</svg>')
    print("saved")
