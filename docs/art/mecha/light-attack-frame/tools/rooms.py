"""Mecha Light Attack Frame: the room plan, drawn first so the hull can be shaped around it.

Usage: python3 rooms.py OUT.svg
"""
import sys

T = 35
W, H, CX = 440, 330, 220
COLS, ROWS = 8, 4
X0, Y0 = CX - COLS / 2 * T, 100

# (name, col, row, width, height); spare rooms stay blank
ROOMS = [("Bridge", 3, 0, 2, 1), ("Shields", 1, 0, 2, 2), ("Doors", 5, 0, 2, 1), ("Port spare", 0, 1, 1, 2),
         ("Life Support", 1, 2, 2, 1), ("Servicing Core", 3, 1, 2, 2), ("Weapon bay", 5, 1, 3, 2),
         ("Engines", 1, 3, 4, 1), ("Aft spare", 5, 3, 2, 1)]


def cell(c, r):
    return X0 + c * T, Y0 + r * T


if __name__ == "__main__":
    out = []
    for name, c, r, w, h in ROOMS:
        x, y = cell(c, r)
        out.append(f'<rect x="{x}" y="{y}" width="{w * T}" height="{h * T}" fill="#d6dade" stroke="#16181c" stroke-width="3"/>'
                   f'<text x="{x + w * T / 2}" y="{y + h * T / 2 + 4}" font-size="10" text-anchor="middle" '
                   f'font-family="sans-serif">{name}</text>')
    open(sys.argv[1], "w").write(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">'
                                 f'<rect width="100%" height="100%" fill="#0f131a"/>{"".join(out)}</svg>')
