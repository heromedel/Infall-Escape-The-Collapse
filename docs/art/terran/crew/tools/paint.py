"""Paints GATOS crew over the 45-degree template. The template is mirrored so the light comes from the upper left.
Body regions come from the template's geometry; each region's lightness picks a tone from the outfit's ramp.
Overlays (coat skirts, vests) are shapes shaded by rule. The head is hand-placed and larger than the template's
(pixel sprites exaggerate the head). Then a selective outline, then details."""
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from base import template, lightness
from figure import poly, ellipse, grid

F = 70
_T = {(F - 1 - x, y): v for (x, y), v in template().items()}     # mirrored: light from the upper left


def region(x, y):
    if y <= 15:
        return "head"
    if y <= 33:
        if x <= 27:
            return "arm-near"
        if x >= 42:
            return "arm-far"
        return "torso"
    if y <= 39 and (x <= 28 or x >= 42):
        return "hand-near" if x <= 28 else "hand-far"
    if y >= 55:
        return "boot"
    return "leg-near" if x <= 33 else "leg-far"


def body():
    """(x, y) -> (region, lightness 0..1 within its region)."""
    by = {}
    for p, rgb in _T.items():
        by.setdefault(region(*p), []).append((p, lightness(rgb)))
    # smooth the render's lightness within each region (3 x 3 average), so the shading is clean bands, not noise
    L = {p: l for items in by.values() for p, l in items}
    reg = {p: r for r, items in by.items() for p, _ in items}
    for r in by:
        by[r] = [(p, sum(L[q] for q in [(p[0] + i, p[1] + j) for i in (-2, -1, 0, 1, 2) for j in (-2, -1, 0, 1, 2)] if reg.get(q) == r)
                  / sum(1 for q in [(p[0] + i, p[1] + j) for i in (-2, -1, 0, 1, 2) for j in (-2, -1, 0, 1, 2)] if reg.get(q) == r))
                 for p, _ in by[r]]
    out = {}
    for r, items in by.items():
        ls = sorted(l for _, l in items)
        lo, hi = ls[len(ls) // 10], ls[-len(ls) // 10 - 1]
        for p, l in items:
            out[p] = (r, max(0.0, min(1.0, (l - lo) / max(1, hi - lo))))
    return out


def tone_of(v):
    """Flat, cartoon-style shading: one shadow shape and the base, with highlights only on lit edges."""
    return 1 if v < .45 else 2


def paint(materials, overlays=(), head=None, details=(), stage=5):
    """materials: region -> ramp. overlays: (mask, ramp) drawn over the body, shaded by rule.
    head: {(x, y): (ramp, tone) or colour}. Returns {(x, y): colour}."""
    B = body()
    px, owner = {}, {}
    for p, (r, v) in B.items():
        if r == "head":
            continue
        ramp = materials[r]
        if callable(ramp):
            ramp = ramp(*p)
        px[p] = ramp[2] if stage == 2 else ramp[tone_of(v)]
        owner[p] = ("body", ramp)
    for i, (mask, ramp) in enumerate(overlays):
        for (x, y) in mask:
            t = 2
            if stage >= 3:
                # a cloth panel, lit from the upper left: its right quarter in shade, its left edge lit
                row = [xx for (xx, yy) in mask if yy == y]
                lo, hi = min(row), max(row)
                if x > hi - max(1, (hi - lo + 1) // 4):
                    t = 1
                if stage >= 4 and x == lo and t == 2:
                    t = 3
            px[(x, y)] = ramp[2] if stage == 2 else ramp[t]
            owner[(x, y)] = ("over%d" % i, ramp)
    if head:
        for p, v in head.items():
            px[p] = v if isinstance(v, str) else (v[0][2] if stage == 2 else v[0][v[1]])
            owner[p] = ("head", v[0] if not isinstance(v, str) else None)
    if stage == 1:
        return {p: "#20242c" for p in px}
    if stage >= 4:
        for p in list(px):
            x, y = p
            if owner[p][0] == "head" or owner[p][1] is None:
                continue
            if any(q not in px for q in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1))):
                lit = (x + 1, y) in px and (x, y + 1) in px
                px[p] = owner[p][1][1 if lit else 0]
    if stage >= 5:
        for p, c in details:
            px[p] = c
    return px
