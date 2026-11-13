"""Checks the hull covers every room with a margin (rooms first: docs/art/ship-art-process.md).

Usage: python3 check_rooms.py HULL.svg [MARGIN]    (renders the hull with render.js; fails on a room whose
rectangle, grown by MARGIN pixels (default 4), isn't all solid hull)"""
import os
import subprocess
import sys
import tempfile

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import layout  # noqa: E402

svg, margin = sys.argv[1], int(sys.argv[2]) if len(sys.argv) > 2 else 4
png = os.path.join(tempfile.mkdtemp(), "hull.png")
subprocess.run(["node", os.path.join(HERE, "..", "..", "..", "tools", "render.js"), svg, png, "1"], check=True,
               capture_output=True)
alpha = Image.open(png).convert("RGBA").load()
short = [name for name, first, last in layout.ROOMS
         for x0, y0, x1, y1 in [layout.rect(first, last)]
         if any(alpha[x, y][3] < 200 for x in range(int(x0) - margin, int(x1) + margin)
                for y in range(int(y0) - margin, int(y1) + margin))]
assert not short, f"rooms not covered with a {margin} px margin: {short}"
print(svg, f"rooms: all {len(layout.ROOMS)} inside the hull with a {margin} px margin")
