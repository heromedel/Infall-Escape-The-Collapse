import importlib, sys
from figure import render
mods = sys.argv[1:-1]; out = sys.argv[-1]
def svg(px, x0, y0, s):
    return "".join(f'<rect x="{x0 + x * s}" y="{y0 + y * s}" width="{s}" height="{s}" fill="{c}"/>' for (x, y), c in px.items())
cells = []
y = 10
for m in mods:
    M = importlib.import_module(m)
    P, D = M.parts(), M.details()
    for st in range(1, 6):
        x0 = 10 + (st - 1) * (70 * 4 + 10)
        cells.append(f'<rect x="{x0}" y="{y}" width="{70*4}" height="{70*4}" fill="#9da2aa"/>' + svg(render(P, D, st), x0, y, 4))
    fin = render(P, D, 5)
    x0 = 10 + 5 * (70 * 4 + 10)
    cells.append(f'<rect x="{x0}" y="{y}" width="140" height="140" fill="#9da2aa"/>' + svg(fin, x0, y, 2))
    # 1x: the 2x figure halved (each 2x2 block takes its most common colour)
    half = {}
    for yy in range(0, 70, 2):
        for xx in range(0, 70, 2):
            cs = [fin[q] for q in ((xx, yy), (xx+1, yy), (xx, yy+1), (xx+1, yy+1)) if q in fin]
            if len(cs) >= 2:
                half[(xx // 2, yy // 2)] = max(set(cs), key=cs.count)
    cells.append(f'<rect x="{x0}" y="{y + 150}" width="70" height="70" fill="#9da2aa"/>' + svg(fin, x0, y + 150, 1))
    cells.append(f'<rect x="{x0 + 80}" y="{y + 150}" width="35" height="35" fill="#9da2aa"/>' + svg(half, x0 + 80, y + 150, 1))
    y += 70 * 4 + 20
open(out, "w").write(f'<svg xmlns="http://www.w3.org/2000/svg" width="{10 + 5*(70*4+10) + 150}" height="{y}" shape-rendering="crispEdges"><rect width="100%" height="100%" fill="#141920"/>{"".join(cells)}</svg>')
