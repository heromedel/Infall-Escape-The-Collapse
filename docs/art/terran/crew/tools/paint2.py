"""Paints GATOS crew over the 45-degree template. The template is mirrored so the light comes from the upper left.
Body regions come from the template's geometry; each region's lightness picks a tone from the outfit's ramp.
Overlays (coat skirts, vests) are shapes shaded by rule. The head is hand-placed and larger than the template's
(pixel sprites exaggerate the head). Then a selective outline, then details."""
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import template, seg_dist
from figure import poly, ellipse, grid


def lightness(rgb):
    return 0.3 * rgb[0] + 0.59 * rgb[1] + 0.11 * rgb[2]


F = 70
_T, J, HEM = template()
BONES = {"torso": ("neck_base", "pelvis"),
         "arm-near": [("shoulder_r", "elbow_r"), ("elbow_r", "wrist_r")], "arm-far": [("shoulder_l", "elbow_l"), ("elbow_l", "wrist_l")],
         "leg-near": [("hip_r", "knee_r"), ("knee_r", "ankle_r")], "leg-far": [("hip_l", "knee_l"), ("knee_l", "ankle_l")],
         "boot-near": [("ankle_r", "toe_r")], "boot-far": [("ankle_l", "toe_l")]}
BOOT_TOP = 55.5


def region(x, y):
    """The nearest bone (the torso counts as wide); then hands past the wrists, boots below the boot tops."""
    if y < J["neck_base"][1] - .5 and abs(x - J["neck_base"][0]) < 6:
        return "head"
    best, name = 1e9, None
    for n, bones in BONES.items():
        if n == "torso":
            d = seg_dist((x + .5, y + .5), J[bones[0]], J[bones[1]])[0] - 5.5
        else:
            d = min(seg_dist((x + .5, y + .5), J[a], J[b])[0] for a, b in bones)
        if d < best:
            best, name = d, n
    if name in ("arm-near", "arm-far") and y >= J["wrist_r"][1] - .5:
        return "hand-near" if name == "arm-near" else "hand-far"
    if name == "torso" and y >= HEM:
        return "leg-near" if x < J["pelvis"][0] else "leg-far"
    if name.startswith(("leg", "boot")) and y >= BOOT_TOP:
        return "boot"
    if name.startswith("boot"):
        return "leg-near" if name.endswith("near") else "leg-far"
    return name


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


def despeckle(tones, owner):
    """Clean shading: a pixel whose tone matches none of its four neighbours in the same part takes the most common
    neighbouring tone, so shading reads as clean bands with no single stray pixels."""
    out = dict(tones)
    for p, t in tones.items():
        x, y = p
        nb = [tones[q] for q in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)) if q in tones and owner.get(q) == owner.get(p)]
        if len(nb) >= 3 and t not in nb:
            out[p] = max(set(nb), key=nb.count)
    return out


def tone_of(v):
    return 1 if v < .4 else 2 if v < .85 else 3


def paint(materials, overlays=(), head=None, details=(), stage=5):
    """materials: region -> ramp. overlays: (mask, ramp) drawn over the body, shaded by rule.
    head: {(x, y): (ramp, tone) or colour}. Returns {(x, y): colour}."""
    B = body()
    px, owner = {}, {}
    rid = {p: r for p, (r, v) in B.items()}
    tones = {p: (2 if stage == 2 else tone_of(v)) for p, (r, v) in B.items() if r != "head"}
    if stage >= 3:
        # arms and legs are cylinders: shade the far (right) third of each row, keep the rest base
        spans = {}
        for (x, y), r in rid.items():
            if r.startswith(("arm", "leg")):
                lo, hi = spans.get((r, y), (x, x))
                spans[(r, y)] = (min(lo, x), max(hi, x))
        for p in tones:
            r = rid[p]
            if (r, p[1]) in spans:
                lo, hi = spans[(r, p[1])]
                w = hi - lo + 1
                tones[p] = 1 if p[0] > hi - max(1, w // 3) else 2
    if stage >= 3:
        tones = despeckle(despeckle(tones, rid), rid)
    if stage >= 4:
        for p in list(tones):
            x, y = p
            if tones[p] == 2 and rid.get((x - 1, y)) != rid[p] and rid.get((x - 1, y - 1)) != rid[p]:
                tones[p] = 3                      # lit left edge of each body part
    for p, t in list(tones.items()):
        if materials.get(rid[p], 0) is None:
            continue
        ramp = materials[rid[p]]
        if callable(ramp):
            ramp = ramp(*p)
        px[p] = ramp[t]
        owner[p] = ("body", ramp)
    for i, ov in enumerate(overlays):
        mask, ramp = ov[0], ov[1]
        tone_fn = ov[2] if len(ov) > 2 else None
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
                if tone_fn:
                    t = tone_fn(x, y, t, stage)
            px[(x, y)] = ramp[2] if stage == 2 else ramp[t]
            owner[(x, y)] = ("over%d" % i, ramp)
    if head:
        for p, v in head.items():
            px[p] = v if isinstance(v, str) else (v[0][2] if stage == 2 else v[0][v[1]])
            owner[p] = ("head", v[0] if not isinstance(v, str) else None)
    # clean the silhouette: drop stray pixels that hang off it (touching it on one side or none), until none are left
    while True:
        spurs = [q for q in px if sum(n in px for n in ((q[0] + 1, q[1]), (q[0] - 1, q[1]), (q[0], q[1] + 1), (q[0], q[1] - 1))) <= 1]
        if not spurs:
            break
        for q in spurs:
            del px[q]
            owner.pop(q, None)
    if stage == 1:
        return {p: "#20242c" for p in px}
    if stage >= 4:
        for p, t in list(tones.items()):
            x, y = p
            if owner.get(p, ("",))[0] == "body" and rid[p] != rid.get((x + 1, y), rid[p]) and (x + 1, y) in px \
                    and owner[(x + 1, y)][0] == "body":
                px[p] = owner[p][1][max(0, min(t, 2) - 1)]
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
