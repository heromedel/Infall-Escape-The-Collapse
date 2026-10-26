"""Checks a hull's weapon mounts against the art rules: each sits on the hull's outer edge, and the line ahead of the
weapon, slid out in its slide direction, is clear of the ship.

Usage: python3 check_mounts.py HULL.svg [HULL.svg ...]   (renders each with render.js beside this script; fails on a
mount that is off the edge or has the ship ahead of it)
"""
import os
import re
import subprocess
import sys
import tempfile

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
MOUNT = re.compile(r'<circle id="(mount-[\w-]+)" cx="([\d.]+)" cy="([\d.]+)" r="3" data-weapon="([^"]*)" '
                   r'data-slide="(\w+)"')
SLIDE, HALF_WIDTH = 12, 6


def check(svg):
    png = os.path.join(tempfile.mkdtemp(), "hull.png")
    subprocess.run(["node", os.path.join(HERE, "render.js"), svg, png, "1"], check=True, capture_output=True)
    a = Image.open(png).convert("RGBA").load()
    solid = lambda x, y: a[int(x), int(y)][3] > 128
    bad = []
    mounts = MOUNT.findall(open(svg).read())
    for mid, x, y, weapon, slide in mounts:
        x, y = float(x), float(y)
        d = -1 if slide == "left" else 1
        on_edge = any(solid(x - d * k, y) for k in range(4)) and a[int(x + d * 4), int(y)][3] < 60
        sx = x + d * SLIDE
        clear = not any(solid(xx, yy) for xx in range(int(sx - HALF_WIDTH), int(sx + HALF_WIDTH + 1))
                        for yy in range(0, int(y) - 10))
        if not (on_edge and clear):
            bad.append((mid, "off the edge" if not on_edge else "ship ahead of it"))
    assert len(mounts) >= 4, f"{svg}: plan at least 4-6 mounts, found {len(mounts)}"
    assert not bad, f"{svg}: {bad}"
    return len(mounts)


if __name__ == "__main__":
    for f in sys.argv[1:]:
        print(f, check(f), "mounts: all on the edge with a clear line forward")
