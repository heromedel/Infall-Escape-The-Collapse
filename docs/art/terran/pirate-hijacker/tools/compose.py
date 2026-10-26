"""Previews: a hull with its weapons placed at their mounts (weapons are separate art; the game does the same).

Usage: python3 compose.py HULL_SVG OUT_SVG weapon-name=WEAPON_SVG_ID ...
Mount spots are read from the hull's hidden weapon-mounts group; each mount's id names its weapon.
"""
import re
import sys

import weapons

hull_svg, out = sys.argv[1], sys.argv[2]
pieces = {"sporewing": weapons.sporewing_c(), "twinshot": weapons.twinshot()}
text = open(hull_svg).read()
mounts = re.findall(r'<circle id="mount-(\w+)" cx="([\d.]+)" cy="([\d.]+)" r="3" data-weapon="([^"]*)" '
                    r'data-slide="(\w+)"', text)
WEAPON = {"Sporewing": "sporewing", "Gat 2.1 Twinshot": "twinshot"}
SLIDE = {"left": (-12, 0), "right": (12, 0), "up": (0, -12), "down": (0, 12)}
# weapons are drawn at 1.35x their file size on this hull, slid out from their mount and under the hull, so only the
# part past the hull's edge shows (as when a weapon slides out)
placed = "".join(f'<g transform="translate({float(x) + SLIDE[s][0]},{float(y) + SLIDE[s][1]}) scale(1.35)">'
                 f'{pieces[WEAPON[w]]}</g>' for _, x, y, w, s in mounts if w)
start = text.index(">", text.index("<svg")) + 1
body = text[:start] + f'{weapons.defs()}<g id="weapons-preview">{placed}</g>' + text[start:]
open(out, "w").write(body)
print("saved", out, [(m[0], m[3]) for m in mounts if m[3]])
