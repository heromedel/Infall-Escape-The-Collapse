import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from crews import CREWS
s = 4; cells = []
for r, (name, fn) in enumerate(CREWS):
    for st in range(1, 6):
        px = fn(st); x0 = (st - 1) * 34 * s; y0 = r * 62 * s
        cells.append("".join(f'<rect x="{x0 + (x - 18) * s}" y="{y0 + (y - 4) * s}" width="{s}" height="{s}" fill="{c}"/>' for (x, y), c in px.items()))
open(sys.argv[1], 'w').write(f'<svg xmlns="http://www.w3.org/2000/svg" width="{5 * 34 * s}" height="{3 * 62 * s}" shape-rendering="crispEdges"><rect width="100%" height="100%" fill="#9da2aa"/>{"".join(cells)}</svg>')
