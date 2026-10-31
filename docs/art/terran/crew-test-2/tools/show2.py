import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from crews2 import CREWS
s = 7; cells = []
for i, (name, fn) in enumerate(CREWS):
    px = fn(); x0 = i * 32 * s
    cells.append("".join(f'<rect x="{x0 + (x - 19) * s}" y="{(y - 4) * s}" width="{s}" height="{s}" fill="{c}"/>' for (x, y), c in px.items()))
    cells.append("".join(f'<rect x="{x0 + 8 + x * 2}" y="{62 * s + 10 + y * 2 - 40}" width="2" height="2" fill="{c}"/>' for (x, y), c in px.items()))
open(sys.argv[1], 'w').write(f'<svg xmlns="http://www.w3.org/2000/svg" width="{96 * s}" height="{62 * s + 120}" shape-rendering="crispEdges"><rect width="100%" height="100%" fill="#9da2aa"/>{"".join(cells)}</svg>')
