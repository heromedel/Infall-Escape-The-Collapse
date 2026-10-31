"""Reads heromedel's rigged front view (the 1/2, 45-degree view) into a 70 x 70 template: cleaned of the joint and
clothing-edge annotations, scaled, with the joints scaled too, and each pixel assigned to its nearest bone."""
import math
import os
from PIL import Image

BG = (120, 124, 132)
SRC = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "reference", "rig-front-45.png")
# joints in the cropped front panel (character's right = viewer's left)
JOINTS = {"head_top": (147, 68), "skull_base": (147, 101), "neck_base": (147, 115), "chest": (147, 147),
          "shoulder_r": (81, 139), "shoulder_l": (213, 139), "elbow_r": (58, 181), "elbow_l": (237, 181),
          "waist": (147, 198), "pelvis": (147, 234), "hip_r": (114, 233), "hip_l": (181, 233),
          "wrist_r": (43, 247), "wrist_l": (252, 247), "knee_r": (112, 348), "knee_l": (183, 348),
          "ankle_r": (111, 432), "ankle_l": (184, 432), "toe_r": (120, 472), "toe_l": (175, 472)}
SHIRT_HEM = 247


def annotation(rgb):
    mx, mn = max(rgb), min(rgb)
    return mx - mn > 95 or mn > 175


def clean():
    im = Image.open(SRC).convert("RGB")
    W, H = im.size
    px = im.load()
    out = {}
    for y in range(H):
        for x in range(W):
            c = px[x, y]
            if annotation(c):
                near = [px[x + i, y + j] for i in range(-4, 5) for j in range(-4, 5)
                        if 0 <= x + i < W and 0 <= y + j < H and not annotation(px[x + i, y + j])]
                if near:
                    near.sort(key=lambda v: sum(v))
                    c = near[len(near) // 2]
                else:
                    c = BG
            out[(x, y)] = c
    return out, W, H


def template(height=56, frame=70):
    img, W, H = clean()
    fg = {p for p, c in img.items() if sum(abs(a - b) for a, b in zip(c, BG)) > 30}
    ys = [y for _, y in fg]; xs = [x for x, _ in fg]
    y0, y1 = min(ys), max(ys) + 1
    k = (y1 - y0) / height
    cx = JOINTS["pelvis"][0]
    ox, oy = frame / 2, frame - 6 - height
    to_frame = lambda sx, sy: ((sx - cx) / k + ox, (sy - y0) / k + oy)
    cells = {}
    for ty in range(frame):
        for tx in range(frame):
            sx0, sy0 = cx + (tx - ox) * k, y0 + (ty - oy) * k
            pts = [(int(sx0 + (i + .5) * k / 4), int(sy0 + (j + .5) * k / 4)) for i in range(4) for j in range(4)]
            on = [p for p in pts if p in fg]
            if len(on) >= 7:
                cells[(tx, ty)] = tuple(sum(img[p][c] for p in on) / len(on) for c in range(3))
    joints = {n: to_frame(*p) for n, p in JOINTS.items()}
    return cells, joints, to_frame(0, SHIRT_HEM)[1]


def seg_dist(p, a, b):
    (px, py), (ax, ay), (bx, by) = p, a, b
    dx, dy = bx - ax, by - ay
    t = max(0, min(1, ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)))
    return math.hypot(px - ax - t * dx, py - ay - t * dy), t
