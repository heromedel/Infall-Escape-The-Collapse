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
mounts = re.findall(r'<circle id="mount-(\w+)" cx="([\d.]+)" cy="([\d.]+)"', text)
# weapons are drawn at 1.35x their file size on this hull
placed = "".join(f'<g transform="translate({x},{y}) scale(1.35)">{pieces[name]}</g>' for name, x, y in mounts)
body = text.replace('<g id="weapon-mounts" display="none">', f'{weapons.defs()}<g id="weapons-preview">{placed}</g>'
                    '<g id="weapon-mounts" display="none">')
open(out, "w").write(body)
print("saved", out, [m[0] for m in mounts])
