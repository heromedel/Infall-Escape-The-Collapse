"""MOCKUP: system symbol colours by side and state (an idea, not finished art).

Usage: python3 mockup.py OUT_SVG [GREEN ORANGE RED]

The player's Outrider (floor layout test 4) shows powered systems with green symbols; the pirate Hijacker shows
them in orange; one system on each is damaged and shows a distinct red. Reuses the real floor plan tools and only
swaps the symbol colours.
"""
import base64
import os
import sys

ART = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
sys.path.insert(0, os.path.join(ART, "terran", "outrider", "floor-layout-tests", "tools"))
sys.path.insert(0, os.path.join(ART, "terran", "pirate-hijacker", "tools"))
import floor4  # noqa: E402  the Outrider, floor layout test 4
import floorplan  # noqa: E402  the pirate dagger floor plans

GREEN, ORANGE, RED = (sys.argv[2:5] if len(sys.argv) >= 5 else ("#57e07a", "#ff9a3c", "#ff3b3b"))
DAMAGED = {"outrider": "Shields", "pirate": "Weapons"}


def damaged_desk(svg_text):
    """A damaged console also gets a red rim on its desk, so the state reads at a glance."""
    return svg_text.replace('stroke="#7d8696"', f'stroke="{RED}" stroke-width="1.6"', 1).replace(
        'stroke="#6d7581"', f'stroke="{RED}" stroke-width="1.6"', 1)


# Outrider: player side, green; one damaged system red
_outrider_terminal = floor4.terminal


def outrider_terminal(name, c, r, kind):
    floor4.SHIP_BLUE = RED if name == DAMAGED["outrider"] else GREEN
    out = _outrider_terminal(name, c, r, kind)
    return damaged_desk(out) if name == DAMAGED["outrider"] else out


floor4.terminal = outrider_terminal

# pirate: enemy side, orange; one damaged system red
_pirate_terminal = floorplan.terminal


def pirate_terminal(name, c, r, kind):
    floorplan.SYMBOL = RED if name == DAMAGED["pirate"] else ORANGE
    out = _pirate_terminal(name, c, r, kind)
    return damaged_desk(out) if name == DAMAGED["pirate"] else out


floorplan.terminal = pirate_terminal


def main(out):
    outrider_hull = os.path.join(ART, "terran", "outrider", "outrider-hull.svg")
    pirate_hull = os.path.join(ART, "terran", "pirate-hijacker", "pirate-hijacker-armed-preview.svg")
    hull_data = base64.b64encode(open(outrider_hull, "rb").read()).decode()
    left = floor4.ship(hull_data, 0, True).replace("Selected: conduits glow", "Player: SC-1 Outrider")
    right = (f'<g transform="translate(480,0)">{floorplan.plan(pirate_hull, "hijacker", False)}'
             f'<text x="240" y="20" font-size="13" font-family="sans-serif" fill="#cfd6e2" text-anchor="middle">'
             f'Enemy: Terran Pirate Hijacker</text></g>')
    x0 = 975
    swatch = lambda y, col, text: (f'<rect x="{x0}" y="{y - 12}" width="16" height="16" rx="3" fill="{col}"/>'
                                   f'<text x="{x0 + 26}" y="{y + 1}" font-size="13" font-family="sans-serif" '
                                   f'fill="#cfd6e2">{text}</text>')
    legend = (f'<text x="{x0}" y="48" font-size="18" font-family="sans-serif" font-weight="700" fill="#ffb347">'
              f'MOCKUP</text>'
              f'<text x="{x0}" y="70" font-size="13" font-family="sans-serif" fill="#e3e8f1">System symbol colours</text>'
              f'<text x="{x0}" y="88" font-size="11.5" font-family="sans-serif" fill="#97a3b8">An idea to try, not '
              f'finished art (ideas.md)</text>'
              + swatch(124, GREEN, "Player system, powered")
              + swatch(152, ORANGE, "Pirate system, powered")
              + swatch(180, RED, "Damaged, either side")
              + f'<text x="{x0}" y="222" font-size="12" font-family="sans-serif" fill="#cfd6e2">Damaged here:</text>'
              f'<text x="{x0}" y="240" font-size="12" font-family="sans-serif" fill="#cfd6e2">Outrider Shields,</text>'
              f'<text x="{x0}" y="256" font-size="12" font-family="sans-serif" fill="#cfd6e2">pirate Weapons.</text>')
    w, h = 1200, 760
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">'
           f'<title>MOCKUP: system symbol colours</title>'
           f'<defs><filter id="cglow" filterUnits="userSpaceOnUse" x="0" y="0" width="{w}" height="{h}">'
           f'<feGaussianBlur stdDeviation="1.6" result="b"/><feMerge><feMergeNode in="b"/>'
           f'<feMergeNode in="SourceGraphic"/></feMerge></filter></defs>'
           f'<rect width="100%" height="100%" fill="#0d1220"/>{left}{right}{legend}</svg>\n')
    open(out, "w").write(svg)
    print("saved", out)


if __name__ == "__main__":
    main(sys.argv[1])
