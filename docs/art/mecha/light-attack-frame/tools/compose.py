"""Places weapon art at a hull's mounts, for previews, at 1.4x the file size as the game would show it:
python3 compose.py HULL.svg WEAPON.svg OUT.svg"""
import re
import sys

hull, weapon, out = sys.argv[1:4]
text = open(hull).read()
w = open(weapon).read()
inner = re.search(r'<g transform="translate\([\d.]+,[\d.]+\)">(.*)</g></svg>', w, re.S).group(1)
wdefs = re.search(r"<defs>(.*?)</defs>", w, re.S).group(1)
mounts = re.findall(r'<circle id="mount-[\w-]+" cx="([\d.]+)" cy="([\d.]+)"', text)
placed = "".join(f'<g transform="translate({x},{y}) scale(1.4)">{inner}</g>' for x, y in mounts)
text = text.replace("<defs>", "<defs>" + wdefs, 1)
open(out, "w").write(text.replace('<g id="weapon-mounts" display="none">',
                                  f'<g id="weapons-preview">{placed}</g><g id="weapon-mounts" display="none">'))
