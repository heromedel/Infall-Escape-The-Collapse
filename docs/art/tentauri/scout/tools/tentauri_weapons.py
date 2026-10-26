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
LAVENDER = "#b9b2e6"
GLOW = "#8ff5e6"


def defs():
    return ('<defs><linearGradient id="tw-nacre" x1="0" y1="0" x2="1" y2="1">'
            f'<stop offset="0" stop-color="{PEARL}"/><stop offset=".45" stop-color="{AQUA}"/>'
            f'<stop offset=".8" stop-color="{LAVENDER}"/><stop offset="1" stop-color="{TEAL}"/></linearGradient>'
            '<filter id="tw-glow" x="-100%" y="-100%" width="300%" height="300%"><feGaussianBlur stdDeviation="2"/></filter>'
            '</defs>')


# ---------- second pass ----------

TEAL2 = "#2f8f8c"
TEAL_D = "#1f5f63"
LAV = "#b9b2e6"
LAV_D = "#7468b8"
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


def segmented():
    """Segmented: a jointed barrel of three soft segments, narrowing to the tip, on a small teal pad."""
    pad = f'<ellipse cx="0" cy="6" rx="9" ry="7" fill="{TEAL_D}" stroke="{INK}" stroke-width="1.2"/><ellipse cx="-2" cy="4" rx="5" ry="3" fill="{TEAL2}"/>'
    segs = ""
    for i, (t, b, wt, wb) in enumerate(((-14, 4, 4.8, 6), (-28, -12, 3.9, 4.8), (-40, -26, 3, 3.9))):
        segs += (f'<path d="M{-wb},{b} C{-wb - 1},{(t + b) / 2} {-wt - 1},{t + 2} {-wt},{t} L{wt},{t} C{wt + 1},{t + 2} {wb + 1},{(t + b) / 2} {wb},{b} Z" '
                 f'fill="url(#l2-nacre)" stroke="{INK}" stroke-width="1.2"/>')
    return pad + segs + tip(-41)


def file(body, w=60, h=80, ox=30, oy=56):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">{defs()}{defs2()}'
            f'<g transform="translate({ox},{oy})">{body}</g></svg>\n')


if __name__ == "__main__":
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    open(os.path.join(out, "defense-laser.svg"), "w").write(file(segmented()))
    print("saved")
