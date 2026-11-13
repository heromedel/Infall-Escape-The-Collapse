#!/usr/bin/env python3
"""Brings the console art from docs/art into the game's content (GV 7G): content/consoles/<style>/.

Usage: python3 tools/import_console_art.py        (from infall-godot/)

Each console is redrawn by the art session's own script, without its symbol: the game draws the symbol on the
console's screen or bulb, so its colour can show the system's state. Writes each style's art and its console.xml.

  desk    the Outrider's wall desk (floor layout test 4): the default, for any race without consoles of its own
  tower   the Mecha tower with stepped cheeks
  organs  the Tentauri organs, one shape for each system, and the tendril for a system that has none
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ART = os.path.join(HERE, "..", "..", "docs", "art")
OUT = os.path.join(HERE, "..", "content", "consoles")
sys.path.insert(0, os.path.join(ART, "tentauri", "scout", "tools"))
sys.path.insert(0, os.path.join(ART, "mecha", "console", "tools"))
import tentauri_floor as organs_art  # noqa: E402
import tower_px  # noqa: E402

TILE = 35
KEEP = '[remap]\n\nimporter="keep"\n'      # the game reads the SVG's own text, so Godot is told not to import it
# the game's system ids for the systems the Tentauri scout's floor plan gives an organ
ORGAN_SYSTEMS = {"piloting": "Piloting", "weapons": "Weapons A", "sensors": "Sensors", "medbay": "Medbay",
                 "shields": "Shields", "engines": "Engines", "doors": "Doors", "life-support": "Life Support",
                 "supershield": "Supershield Generator"}
OTHER_ORGAN = "tendril"


def svg(body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {TILE} {TILE}" width="{TILE}" height="{TILE}">'
            f'{body}</svg>\n')


def save(style, name, text):
    folder = os.path.join(OUT, style)
    os.makedirs(folder, exist_ok=True)
    open(os.path.join(folder, name), "w").write(text)
    if name.endswith(".svg"):
        open(os.path.join(folder, name + ".import"), "w").write(KEEP)


def desk():
    """The wall desk of the Outrider's floor layout test 4 (its `terminal`), against the north wall."""
    body = (f'<rect x="3" y="2" width="{TILE - 6}" height="17" rx="3" fill="#e9edf2" stroke="#7d8696" stroke-width="1"/>'
            f'<rect x="6" y="4" width="{TILE - 12}" height="12" rx="2" fill="#1b2a44"/>'
            f'<rect x="9" y="19.5" width="{TILE - 18}" height="3" rx="1" fill="#aab2be"/>')
    save("desk", "desk.svg", svg(body))
    save("desk", "console.xml", f'''<?xml version="1.0" encoding="UTF-8"?>
<!-- The wall desk (GV 7G): a pale desk against the wall with a dark screen, from the Outrider's floor layout test 4.
     The default: a race that names no consoles of its own gets this one. Made by tools/import_console_art.py.

     fit="turned": the art is drawn for the north wall and turned to face its own wall.
     symbol: where on the art the game draws the system's symbol, and how big. -->
<console_style id="desk" default="true" fit="turned">
	<console art="desk.svg" symbol="17.5,10" symbol_size="13"/>
</console_style>
''')


def tower():
    """The Mecha tower, its screen left dark for the game's symbol."""
    pixels = tower_px.console("stepped")
    for x in range(14, 21):
        for y in range(4, 13):
            pixels[(x, y)] = tower_px.SCREEN
    save("tower", "tower.svg", svg(tower_px.to_svg(pixels)))
    save("tower", "console.xml", '''<?xml version="1.0" encoding="UTF-8"?>
<!-- The Mecha console (GV 7G): the pixel tower with stepped cheeks, docs/art/mecha/console. Turned to face its wall.
     Made by tools/import_console_art.py. -->
<console_style id="tower" fit="turned">
	<console art="tower.svg" symbol="17.5,8.5" symbol_size="9.5"/>
</console_style>
''')


def organs():
    """The Tentauri organs at full size, each with its bulb left dark; the game shrinks them against the wall."""
    organs_art.X0, organs_art.Y0 = 0, 0
    organs_art.bulb = lambda x, y, r=8.5: (f'<circle cx="{x}" cy="{y}" r="{r}" fill="{organs_art.SCREEN}" '
                                           f'stroke="{organs_art.ORGAN_EDGE}" stroke-width="1.6"/>')
    spots = []
    organs_art.organ_symbol = lambda kind, x, y, k=.62: (spots.append((x, y, k)), "")[1]
    lines = []
    forms = [(system, organs_art.FORM_BY_SYSTEM[name]) for system, name in ORGAN_SYSTEMS.items()] + [("", OTHER_ORGAN)]
    for system, form in forms:
        spots.clear()
        body = organs_art.ORGANS[form]("organ", 0, 0, "weapons")
        x, y, k = spots[0]
        file_name = form.replace(" ", "-") + ".svg"
        save("organs", file_name, svg(body))
        # the art's symbol is 14 * k pixels across at full size; the game's symbols fill about 0.8 of their size
        size = 14 * k * organs_art.ON_WALL_SYMBOL / organs_art.ON_WALL / 0.8 * 0.72
        which = f'system="{system}" ' if system else ""
        lines.append(f'\t<console {which}art="{file_name}" symbol="{x:g},{y:g}" symbol_size="{size:g}"/>')
    listed = "\n".join(lines)
    save("organs", "console.xml", f'''<?xml version="1.0" encoding="UTF-8"?>
<!-- The Tentauri consoles (GV 7G): organic bases, one for each system, shaped by what it does, with the system's
     symbol lit in a dark bulb (docs/art/style-guides.md, Tentauri ships). Made by tools/import_console_art.py.

     fit="upright": the art is never turned. It is drawn at `scale` and slid against its wall, the edge of its
     `box` (left, top, right, bottom of the drawing in its 35-pixel frame) `gap` pixels from the wall.
     glow: the radius, in the art's pixels, of the soft light round the bulb, in the symbol's colour.
     A console that names no system is the one for every system not listed. -->
<console_style id="organs" fit="upright" scale="{organs_art.ON_WALL:g}" box="1,2,32,34" gap="1.5" glow="11.5">
{listed}
</console_style>
''')


if __name__ == "__main__":
    desk()
    tower()
    organs()
    for style in sorted(os.listdir(OUT)):
        print(style + ":", ", ".join(sorted(f for f in os.listdir(os.path.join(OUT, style)) if not f.endswith(".import"))))
