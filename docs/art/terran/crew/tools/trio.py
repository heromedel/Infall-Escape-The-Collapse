import importlib, sys
from figure import render
s=int(sys.argv[-2]); out=sys.argv[-1]; mods=sys.argv[1:-2]
cells=[]
for i,m in enumerate(mods):
    px=render(importlib.import_module(m).parts(),importlib.import_module(m).details(),5)
    x0=i*30*s
    cells.append("".join(f'<rect x="{x0+(x-20)*s}" y="{(y-8)*s}" width="{s}" height="{s}" fill="{c}"/>' for (x,y),c in px.items()))
open(out,'w').write(f'<svg xmlns="http://www.w3.org/2000/svg" width="{30*s*len(mods)}" height="{56*s}" shape-rendering="crispEdges"><rect width="100%" height="100%" fill="#9da2aa"/>{"".join(cells)}</svg>')
