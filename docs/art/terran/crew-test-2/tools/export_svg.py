"""Exports the round 5 pixel crew to SVG, pixel for pixel: one unit square per pixel, merged into one path per colour
(no change to the art). The viewBox is the 70 x 70 frame, so the SVG scales to any size with crisp pixels.

Usage: python3 export_svg.py OUT_DIR [SCALE]   (SCALE sets the SVG's default display size, e.g. 4 = 280 px)"""
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "mecha", "light-attack-frame",
                                "pixel-redo", "tools"))
from crews2 import CREWS
from pixel_svg import paths

NAMES = ["gatos-drifter", "gatos-leather-jacket", "gatos-vest-merc"]

if __name__ == "__main__":
    out = sys.argv[1]
    scale = int(sys.argv[2]) if len(sys.argv) > 2 else 4
    os.makedirs(out, exist_ok=True)
    for name, (label, fn) in zip(NAMES, CREWS):
        px = fn()
        open(os.path.join(out, f"{name}.svg"), "w").write(
            f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 70 70" width="{70 * scale}" height="{70 * scale}" '
            f'shape-rendering="crispEdges"><title>{label}</title>{paths(px)}</svg>\n')
        print("wrote", name, len(px), "pixels")
