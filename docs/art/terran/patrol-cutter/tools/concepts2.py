"""Round 2 silhouettes for the Patrol Cutter (heromedel, 2026-11-13: not a clean white vertical ship; a mercenary
cutter with sharp wings or nacelles). Drawn round the same rooms, on a wider canvas.
Usage: python3 concepts2.py OUT_DIR"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import layout  # noqa: E402

W, H, CX, CY = 440, 470, 220, 235          # the wider canvas; the centre of tile (0, 0)


def sym(half):
    pts = half + [(2 * CX - x, y) for x, y in reversed(half)]
    return "M" + " L".join(f"{x:.1f},{y:.1f}" for x, y in pts) + " Z"


def rooms():
    out = []
    for name, a, b in layout.ROOMS:
        x0, y0 = CX + (a[0] - .5) * 35, CY + (a[1] - .5) * 35
        x1, y1 = CX + (b[0] + .5) * 35, CY + (b[1] + .5) * 35
        out.append(f'<rect x="{x0}" y="{y0}" width="{x1 - x0}" height="{y1 - y0}" fill="none" stroke="#e8453c" '
                   f'stroke-width="1.5" stroke-dasharray="4 3"/>')
    return "".join(out)


CONCEPTS = {
    "W1 swept wings, wingtip nacelles": [
        sym([(210, 22), (160, 70), (158, 118), (124, 140), (20, 318), (122, 304), (156, 330), (160, 404), (182, 432)]),
        sym([(40, 250), (30, 262), (30, 352), (46, 362), (62, 352), (62, 262), (52, 250)])],
    "W2 forward-swept wings, root nacelles": [
        sym([(210, 22), (160, 70), (158, 140), (126, 146), (24, 120), (34, 150), (124, 300), (156, 330), (160, 404),
             (182, 432)]),
        sym([(108, 230), (96, 244), (96, 360), (112, 372), (128, 360), (128, 244), (118, 230)])],
    "W3 crescent wings, mid-wing nacelles": [
        sym([(210, 22), (160, 70), (158, 118), (120, 142), (60, 190), (16, 268), (36, 262), (80, 290), (124, 302),
             (156, 330), (160, 404), (182, 432)]),
        sym([(70, 196), (58, 210), (58, 320), (72, 332), (88, 320), (88, 210), (80, 196)])],
}

if __name__ == "__main__":
    out = sys.argv[1]; os.makedirs(out, exist_ok=True)
    svg = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{len(CONCEPTS) * (W + 20)}" height="{H + 30}">'
           f'<rect width="100%" height="100%" fill="#141821"/>']
    for n, (name, paths) in enumerate(CONCEPTS.items()):
        body = "".join(f'<path d="{d}" fill="#7a7266" stroke="#1b2230" stroke-width="2.4" stroke-linejoin="round"/>'
                       for d in reversed(paths))
        svg.append(f'<g transform="translate({n * (W + 20)},0)">{body}{rooms()}'
                   f'<text x="20" y="{H + 18}" fill="#c8ccd6" font-family="sans-serif" font-size="15">{name}</text></g>')
    svg.append("</svg>")
    open(os.path.join(out, "concepts2.svg"), "w").write("".join(svg))
