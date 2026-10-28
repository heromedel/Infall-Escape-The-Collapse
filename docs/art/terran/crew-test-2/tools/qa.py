"""Sprite checks (docs/art/sprite-process.md). Each check names the mistake it was born from. A sprite is
{(x, y): "#rrggbb"} with a part map {(x, y): part name}.

Usage: python3 qa.py --selftest      (rebuilds every known mistake on the drifter; each must be caught)"""
import math

NB4 = ((1, 0), (-1, 0), (0, 1), (0, -1))


def lum(c):
    r, g, b = (int(c[i:i + 2], 16) for i in (1, 3, 5))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def stray_pixels(px):
    """Pixels hanging off the silhouette, touching it on one side or none (round 4: a shoulder tip, a fingertip)."""
    return [p for p in px if sum((p[0] + dx, p[1] + dy) in px for dx, dy in NB4) <= 1]


def holes(px, size=None):
    """Background pixels fully enclosed by the silhouette (real gaps open to the outside)."""
    xs = [x for x, _ in px]; ys = [y for _, y in px]
    x0, x1, y0, y1 = min(xs) - 1, max(xs) + 1, min(ys) - 1, max(ys) + 1
    outside, todo = {(x0, y0)}, [(x0, y0)]
    while todo:
        x, y = todo.pop()
        for dx, dy in NB4:
            q = (x + dx, y + dy)
            if x0 <= q[0] <= x1 and y0 <= q[1] <= y1 and q not in px and q not in outside:
                outside.add(q); todo.append(q)
    return [(x, y) for x in range(x0, x1 + 1) for y in range(y0, y1 + 1) if (x, y) not in px and (x, y) not in outside]


def part_contrast(px, parts, part):
    """How much a part stands out: the mean brightness difference between its pixels and the other parts' pixels
    touching it."""
    diffs = [abs(lum(px[p]) - lum(px[q])) for p, n in parts.items() if n == part
             for q in ((p[0] + dx, p[1] + dy) for dx, dy in NB4) if q in px and parts.get(q) != part]
    return sum(diffs) / len(diffs) if diffs else 0.0


def detail_survival(before, bparts, after, aparts, protected, scale=1):
    """Every protected detail is still there and still stands out (2x drifter: a whole-image softening erased the
    belt, collar and buttons). Returns the failures."""
    bad = []
    for part in protected:
        n0 = sum(1 for v in bparts.values() if v == part) * scale * scale
        n1 = sum(1 for v in aparts.values() if v == part)
        if n0 and n1 < 0.7 * n0:
            bad.append(f"{part}: {n1} pixels left of {n0}")
            continue
        c0, c1 = part_contrast(before, bparts, part), part_contrast(after, aparts, part)
        if n0 and c1 < 0.7 * c0:
            bad.append(f"{part}: contrast {c1:.0f}, was {c0:.0f}")
        changed = [p for p, v in aparts.items() if v == part and before.get((p[0] // scale, p[1] // scale), "").lower() != after[p].lower()]
        if n0 and len(changed) > 0.1 * n1 and part not in ("eye", "mouth", "belt", "lapel-near", "lapel-far"):
            bad.append(f"{part}: {len(changed)} of {n1} pixels changed")
    return bad


def part_diff(before, after, aparts, allowed, scale=1, bparts=None):
    """Pixels changed outside the parts the goal may touch (a pixel removed from an allowed part is fine)."""
    out = []
    for p in set(after) | {(x * scale + i, y * scale + j) for (x, y) in before for i in range(scale) for j in range(scale)}:
        b = before.get((p[0] // scale, p[1] // scale))
        a = after.get(p)
        was = (bparts or {}).get((p[0] // scale, p[1] // scale))
        if (b or "").lower() != (a or "").lower() and aparts.get(p) not in allowed and was not in allowed:
            out.append(p)
    return out


def pair_symmetry(parts, left, right):
    """A matched pair (boots) has the same shape: the right one mirrored about the pair's centre lands on the left
    one (round 5: uneven boots). Returns the fraction of pixels that don't match (0 = identical shapes)."""
    L = {p for p, v in parts.items() if v == left}
    R0 = {p for p, v in parts.items() if v == right}
    if not L or not R0:
        return 1.0
    span = min(x for x, _ in L) + max(x for x, _ in R0)
    R = {(span - x, y) for (x, y) in R0}
    return len(L ^ R) / max(len(L), len(R))


def attached(parts, a, b):
    """Part a touches part b along an edge (round 2 at 2x: the boots looked severed from the legs)."""
    A = {p for p, v in parts.items() if v == a}
    return any((x + dx, y + dy) in A for (x, y), v in parts.items() if v == b for dx, dy in NB4)


def hand_hangs(parts, hand, arm):
    """A relaxed hanging hand (round 2 at 2x: the hands read as sideways fists): attached to its sleeve, taller than
    wide, hanging below the sleeve's end, and no wider than the sleeve's cuff plus a pixel either side."""
    H = [p for p, v in parts.items() if v == hand]
    A = [p for p, v in parts.items() if v == arm]
    if not H or not A:
        return ["missing"]
    w = max(x for x, _ in H) - min(x for x, _ in H) + 1
    h = max(y for _, y in H) - min(y for _, y in H) + 1
    cuff_y = max(y for _, y in A)
    cuff = [x for x, y in A if y >= cuff_y - 1]
    bad = []
    if not attached(parts, hand, arm):
        bad.append("not attached to the sleeve")
    if h < 1.2 * w:
        bad.append(f"not hanging: {w} wide, {h} tall")
    if max(y for _, y in H) <= cuff_y:
        bad.append("doesn't hang below the cuff")
    if w > max(cuff) - min(cuff) + 3:
        bad.append(f"wider ({w}) than the cuff ({max(cuff) - min(cuff) + 1})")
    return bad


def boot_forward(parts, boot):
    """A boot's toe points forward, toward the viewer, not splayed out (round 2 at 2x: duck feet): the bottom rows'
    centre stays within 2 pixels of the shaft's centre."""
    B = [p for p, v in parts.items() if v == boot]
    top, bottom = min(y for _, y in B), max(y for _, y in B)
    row = lambda y: [x for x, yy in B if yy == y] or [x for x, yy in B if yy == y + 1]
    c = lambda xs: (min(xs) + max(xs)) / 2
    return abs(c(row(bottom - 1)) - c(row(top + 1)))


def shading_steps(px, parts, part):
    """The biggest brightness jumps between neighbouring pixels inside a part, ignoring its edge (round 5: shading so
    contrasty it read as embossed panels). Returns (mean step, 90th percentile step)."""
    mask = {p for p, v in parts.items() if v == part}
    inner = {p for p in mask if all((p[0] + dx, p[1] + dy) in mask for dx, dy in NB4)}
    steps = sorted(abs(lum(px[p]) - lum(px[(p[0] + 1, p[1])])) for p in inner if (p[0] + 1, p[1]) in inner)
    steps += sorted(abs(lum(px[p]) - lum(px[(p[0], p[1] + 1)])) for p in inner if (p[0], p[1] + 1) in inner)
    steps = sorted(s for s in steps if s > 0)
    if not steps:
        return 0.0, 0.0
    return sum(steps) / len(steps), steps[int(.9 * (len(steps) - 1))]


def selftest():
    import os, sys
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import crews2, paint2
    good = crews2.crew1(); gparts = dict(paint2.PARTS)
    protected = ["belt", "buckle", "button", "lapel-near", "lapel-far", "emblem", "eye", "mouth"]
    ok = True

    def expect(name, cond):
        nonlocal ok
        ok &= cond
        print(f"{name:<34} {'caught' if cond else 'NOT CAUGHT'}")
    print("known-good drifter:", "PASS" if not stray_pixels(good) and not holes(good) and
          not detail_survival(good, gparts, good, gparts, protected) else "FAIL")
    bad = dict(good); bad[(10, 10)] = "#000000"; bad[(min(x for x, _ in good) - 1, 40)] = "#000000"
    expect("stray pixel", bool(stray_pixels(bad)))
    inner = next(p for p, v in gparts.items() if v == "coat-near" and all((p[0] + dx, p[1] + dy) in good for dx, dy in NB4))
    bad = dict(good); del bad[inner]
    expect("hole in the silhouette", bool(holes(bad)))
    from collections import Counter                 # a blur pulls the belt to the coat's main tone
    coat = Counter(good[p] for p, v in gparts.items() if v == "coat-near").most_common(1)[0][0]
    bad = dict(good)
    for p, v in gparts.items():
        if v == "belt":
            bad[p] = coat                       # the belt blurred into the coat
    expect("belt blurred away", any(s.startswith("belt") for s in detail_survival(good, gparts, bad, gparts, protected)))
    bad = dict(good); bp = dict(gparts)
    for p, v in gparts.items():
        if v == "button":
            bad[p] = good[(p[0] + 1, p[1])]; bp[p] = "torso"
    expect("buttons gone", any(s.startswith("button") for s in detail_survival(good, gparts, bad, bp, protected)))
    bp = dict(gparts)
    for p, v in list(bp.items()):
        if v == "boot-far" and p[1] > 59:
            del bp[p]
    expect("mismatched boots", pair_symmetry(bp, "boot-near", "boot-far") > 0.1 and
           pair_symmetry(gparts, "boot-near", "boot-far") <= 0.1)
    bad = dict(good)
    for p, v in gparts.items():
        if v == "torso":
            bad[p] = "#ff00ff"
    expect("change outside the goal's parts", bool(part_diff(good, bad, gparts, {"coat-near"})))
    btop = min(y for (x, y), v in gparts.items() if v == "boot-near")
    sev = {p: v for p, v in gparts.items() if not ((v == "boot-near" and p[1] == btop) or (v == "leg-near" and p[1] >= btop - 1))}
    expect("severed boot", attached(gparts, "boot-near", "leg-near") and not attached(sev, "boot-near", "leg-near"))
    fist = dict(gparts)
    hy = max(y for (x, y), v in gparts.items() if v == "hand-near")
    hx = min(x for (x, y), v in gparts.items() if v == "hand-near")
    for p in [p for p, v in fist.items() if v == "hand-near"]:
        del fist[p]
    for i in range(6):
        for j in range(2):
            fist[(hx - 2 + i, hy + j)] = "hand-near"
    expect("sideways fist", bool(hand_hangs(fist, "hand-near", "arm-near")))
    duck = {p: v for p, v in gparts.items() if v != "boot-near"}
    by = [y for (x, y), v in gparts.items() if v == "boot-near"]
    for y in range(min(by), max(by) + 1):
        for x in range(28, 32):
            duck[(x - (y - min(by)), y)] = "boot-near"
    expect("duck-foot boot", boot_forward(duck, "boot-near") > 2)
    print("QA SELF-TEST", "PASSED" if ok else "HAS PROBLEMS")
    return ok


if __name__ == "__main__":
    import sys
    if "--selftest" in sys.argv:
        sys.exit(0 if selftest() else 1)
