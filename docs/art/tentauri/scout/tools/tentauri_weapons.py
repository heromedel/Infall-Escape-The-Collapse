"""Tentauri Defense Laser weapon art: separate files, centred on the mount point at (0, 0), pointing up.

Usage: python3 tentauri_weapons.py OUT_DIR
Three styles from the race's anatomy (not ocean themes): a siphon emitter, a coiled tendril, and a grasping cradle.
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


def file(body, w=60, h=80, ox=30, oy=56):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">{defs()}'
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
    print("saved")
