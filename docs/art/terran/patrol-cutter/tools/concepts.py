"""Silhouette concepts for the Patrol Cutter, drawn around its rooms, for picking one (the 3-6 rule).
Usage: python3 concepts.py OUT_DIR"""
import os
import sys
import layout
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "tools"))
from art_kit import rounded_path  # noqa: E402

CX = layout.CX


def sym(half, radius=0):
    """A closed outline from its left half, top to bottom; the right half is the mirror image. With a radius, the
    corners are rounded."""
    pts = half + [(2 * CX - x, y) for x, y in reversed(half)]
    if radius:
        return rounded_path(pts, radius)
    return "M" + " L".join(f"{x:.1f},{y:.1f}" for x, y in pts) + " Z"


CONCEPTS = {
    "A chined wedge": [sym([(132, 40), (98, 72), (88, 148), (52, 156), (46, 300), (84, 308), (88, 410), (108, 430)])],
    "B sponsons on struts": [sym([(136, 42), (110, 66), (100, 150), (100, 300), (96, 410), (116, 430)]),
                             sym([(56, 138), (44, 160), (44, 296), (60, 312), (100, 312), (100, 138)])],
    "C rounded cutter": [f"M150,38 C196,38 214,90 214,140 C250,150 252,170 252,226 C252,290 236,306 210,312 "
                         f"C210,380 200,430 150,430 C100,430 90,380 90,312 C64,306 48,290 48,226 C48,170 50,150 86,140 "
                         f"C86,90 104,38 150,38 Z"],
    "E swept cutter": [sym([(134, 34), (100, 64), (90, 120), (50, 148), (44, 262), (84, 328), (88, 410), (108, 432)], 9)],
    "D sensor-bar bow": [sym([(140, 50), (70, 54), (60, 78), (92, 90), (90, 150), (52, 158), (50, 300), (88, 308),
                              (90, 412), (112, 430)])],
}

if __name__ == "__main__":
    out = sys.argv[1]; os.makedirs(out, exist_ok=True)
    cells = []
    for name, paths in CONCEPTS.items():
        body = "".join(f'<path d="{d}" fill="#dfe5ec" stroke="#1b2230" stroke-width="2.4" stroke-linejoin="round"/>'
                       for d in paths)
        cells.append((name, body))
    w = len(cells) * 320
    svg = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="520"><rect width="{w}" height="520" fill="#141821"/>']
    for n, (name, body) in enumerate(cells):
        svg.append(f'<g transform="translate({n * 320 + 10},0)">{body}{layout.rooms_svg()}'
                   f'<text x="10" y="505" fill="#c8ccd6" font-family="sans-serif" font-size="15">{name}</text></g>')
    svg.append("</svg>")
    open(os.path.join(out, "concepts.svg"), "w").write("".join(svg))
