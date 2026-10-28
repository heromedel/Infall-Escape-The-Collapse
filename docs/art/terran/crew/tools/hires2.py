"""The drifter at 2x (70 -> 140), one goal at a time (docs/art/sprite-process.md): each goal may only change its
own parts, and every goal is checked (detail survival, changes outside its parts, stray pixels, holes; the boots also
for symmetry). Each stage is saved so it can be looked at.

Usage: python3 hires2.py OUT_DIR"""
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import crews as C
import crews2
import coat3
import legs3
import paint2
import qa
from hires import TONE, RAMPS, ramp7, rgbhex, hexrgb

PROTECTED = ["belt", "buckle", "button", "lapel-near", "lapel-far", "emblem", "eye", "mouth"]
NB4 = qa.NB4


def up2(px, parts):
    big = {(2 * x + i, 2 * y + j): c.lower() for (x, y), c in px.items() for i in (0, 1) for j in (0, 1)}
    bp = {(2 * x + i, 2 * y + j): v for (x, y), v in parts.items() for i in (0, 1) for j in (0, 1)}
    return big, bp


def soften(big, bp, part_names):
    """Goal: softer, rounder shading inside the coat and sleeves only. Each sub-pixel becomes a soft average of its
    own part's neighbours, snapped to a 7-tone ramp; edges and every other part are left alone."""
    edge = {p for p in big if any(q not in big for q in ((p[0] + dx, p[1] + dy) for dx, dy in NB4))}
    out = dict(big)
    for p, c in big.items():
        if bp.get(p) not in part_names or c not in TONE or p in edge:
            continue
        ri, t = TONE[c]
        if t == 0:
            continue
        vals, w = [t * 2.0 * 4], 4
        for i in range(-2, 3):
            for j in range(-2, 3):
                q = (p[0] + i, p[1] + j)
                if (i or j) and bp.get(q) == bp[p] and big.get(q) in TONE and TONE[big[q]][0] == ri and q not in edge \
                        and TONE[big[q]][1] > 0:
                    vals.append(TONE[big[q]][1] * 2.0); w += 1
        out[p] = rgbhex(ramp7(RAMPS[ri])[max(2, round(sum(vals) / w))])
    return out


def thin_outline(big, bp, part_names):
    """Goal: a one-sub-pixel outline on the given parts. The 2 x 2 blocks made the outline two sub-pixels thick; its
    inner half lifts to the part's shadow tone, the outer edge stays dark."""
    out = dict(big)
    for p, c in big.items():
        if bp.get(p) not in part_names or c not in TONE or TONE[c][1] != 0:
            continue
        if all((p[0] + dx, p[1] + dy) in big for dx, dy in NB4):
            out[p] = RAMPS[TONE[c][0]][1].lower()
    return out


BOOT2 = ["...kkkkkkkk...",
         "..kLLbbbbbdk..",
         "..kLbbbbbbdk..",
         "..kLbbbbbbdk..",
         "..kLbbbbbbdk..",
         ".kLLbbbbbbbdk.",
         ".kLbbbbbbbbdk.",
         "kLLbbbbbbbbbdk",
         "kLbbbbbbbbbbdk",
         "kLbbbbbbbbbbdk",
         "kLbbbbbbbbbbdk",
         "kbbbbbbbbbbddk",
         "kbdbbbbbbbbddk",
         ".kddddddddddk.",
         ".kssssssssssk.",
         "..kkkkkkkkkk.."]


def boots2(big, bp):
    """Goal: a matched pair of boots, the same rounded shape on both feet, lit from the upper left on both."""
    out, parts = dict(big), dict(bp)
    for p, v in bp.items():
        if v in ("boot-near", "boot-far"):
            del out[p]; del parts[p]
    B = C.BOOTS
    key = {"k": B[0], "d": B[1], "b": B[2], "L": B[3], "s": "#0a0809"}
    nb = [p for p, v in bp.items() if v == "boot-near"]; fb = [p for p, v in bp.items() if v == "boot-far"]
    left, right = min(x for x, _ in nb), max(x for x, _ in fb)
    y0 = max(y for _, y in nb + fb) + 1 - len(BOOT2)
    for name, x0 in (("boot-near", left), ("boot-far", right + 1 - len(BOOT2[0]))):
        for j, row in enumerate(BOOT2):
            for i, ch in enumerate(row):
                if ch in key:
                    out[(x0 + i, y0 + j)] = key[ch].lower(); parts[(x0 + i, y0 + j)] = name
    return out, parts


def face2(big, bp):
    """Goal: a better jaw and neck, eyes and mouth, drawn at 2x over the face only: the jaw tapers to a rounded chin
    with a shadow under it on the neck, the eyes get a lid, a white and an iris under short brows, the mouth is a
    thin line."""
    S = [c.lower() for c in C.S1]; Hd = C.HAIR1[1].lower()
    out, parts = dict(big), dict(bp)
    D = [c.lower() for c in C.DUSTER]
    face = [p for p, v in bp.items() if v in ("face", "eye", "mouth")]
    # the lower face, rows 28-33: the jaw tapers to a rounded chin (columns given as [first, last])
    JAW = {28: (61, 78), 29: (61, 78), 30: (62, 77), 31: (63, 76), 32: (64, 75), 33: (66, 73)}
    cx = 69.5
    for (x, y) in face:
        if y in JAW and not JAW[y][0] <= x <= JAW[y][1]:
            out[(x, y)] = D[1] if x < cx else D[0]        # what shows there now: the coat collar, in shadow
            parts[(x, y)] = "collar-near" if x < cx else "collar-far"
    for y, (x0, x1) in JAW.items():
        for x in range(x0, x1 + 1):
            rel = (x - x0) / (x1 - x0)
            col = S[3] if rel < .18 else S[2] if rel < .66 else S[1]
            if x in (x0, x1) or y == 33:
                col = S[0]
            out[(x, y)] = col; parts[(x, y)] = "face"
    for (x, y), v in list(parts.items()):                  # a softer cheek: the lit stripe narrows to the cheekbone's edge
        if v == "face" and 24 <= y <= 29 and out[(x, y)] == S[3] and x > 62:
            out[(x, y)] = S[2]
    for x in range(67, 73):                                # the neck under the chin, in its shadow
        y = 34
        if parts.get((x, y)) in ("torso", "lapel-near", "lapel-far", "coat-near", "coat-far", "collar-near", "collar-far"):
            out[(x, y)] = S[1]; parts[(x, y)] = "neck"
    # eyes: brows, a lid line, the white and an iris looking slightly down
    for ex in (65, 72):
        for x in range(ex, ex + 3):
            out[(x, 24)] = Hd; parts[(x, 24)] = "brow"
            out[(x, 25)] = S[2] if x != ex + 2 else S[1]; parts[(x, 25)] = "face"
            out[(x, 26)] = S[0]; parts[(x, 26)] = "eye"
        out[(ex, 27)] = "#e6dacb"; out[(ex + 1, 27)] = "#3a2418"; out[(ex + 2, 27)] = "#d8c8b8"
        for x in range(ex, ex + 3):
            parts[(x, 27)] = "eye"
    # the mouth: a short line, its far corner softer, with a soft lower lip
    for x in range(68, 71):
        out[(x, 30)] = "#6a3a2e"; parts[(x, 30)] = "mouth"
    out[(70, 30)] = "#7a4a3c"
    out[(71, 30)] = S[2]; parts[(71, 30)] = "face"
    for x in range(68, 71):
        out[(x, 31)] = S[2]; parts[(x, 31)] = "face"
    return out, parts


def belt_collar(big, bp):
    """Goal: the belt and collar stand out more. The belt goes a step darker with a lit top edge along its strap; the
    buckle gets a bright rim; the collar stands up either side of the neck in the coat's lit tone."""
    out, parts = dict(big), dict(bp)
    D = [c.lower() for c in C.DUSTER]
    belt = [p for p, v in bp.items() if v == "belt"]
    top = min(y for _, y in belt)
    for p in belt:
        out[p] = D[1] if p[1] == top else "#1e140e"
    for p, v in bp.items():
        if v == "buckle":
            out[p] = "#e0c070" if (p[0] + p[1]) % 2 == 0 else "#a8884a"
    for side, xs in (("collar-near", range(60, 64)), ("collar-far", range(76, 80))):
        for x in xs:
            for y in (29, 30, 31, 32):
                if (x, y) in out and bp.get((x, y)) in ("lapel-near", "lapel-far", "coat-near", "coat-far", "face", "torso"):
                    lit = side == "collar-near"
                    out[(x, y)] = D[0] if x in (xs[0], xs[-1]) or y == 29 else (D[3] if lit else D[2])
                    parts[(x, y)] = side
    return out, parts


BOOT4 = "\n".join(["..kkkkkkkk..",
                    "..kddddddk..",
                    "..kLbbbbdk..",
                    "..kLbbbbdk..",
                    "..kLbbbbdk..",
                    ".kLbbbbbbdk.",
                    "kLbbLLLbbbdk",
                    "kLbLLLLLbbdk",
                    "kLbbLLLbbbdk",
                    "kdbbbbbbbddk",
                    "kddddddddddk",
                    "kssssssssssk",
                    ".kkkkkkkkkk."]).split("\n")    # the ankle narrow, the foot wider below it, its rounded top
                                                    # (the vamp) catching the light, a sole jutting out under it


def boots4(big, bp):
    """Goal (round 2 at 2x: severed boots, toes turned out like duck feet): boots seen from above and in front. The
    shaft sits right over its trouser leg with the trousers tucked into it (no gap), the toe points at the viewer, so
    the foot only widens a pixel either side below the shaft, with a lit toe cap. One shape for both, lit from the
    upper left on both."""
    out, parts = dict(big), dict(bp)
    old = [p for p, v in bp.items() if v in ("boot-near", "boot-far")]
    bottom = max(y for _, y in old)
    for p in old:
        del out[p]; del parts[p]
    B = C.BOOTS
    key = {"k": B[0], "d": B[1], "b": B[2], "L": B[3], "s": "#0a0809"}
    y0 = bottom + 1 - len(BOOT4)
    for leg, boot in (("leg-near", "boot-near"), ("leg-far", "boot-far")):
        cells = [p for p, v in parts.items() if v == leg]
        low = max(y for _, y in cells)
        xs = [x for x, y in cells if y == low]
        for y in range(low + 1, y0 + 2):                    # the trousers reach down into the boot's mouth
            for x in xs:
                out[(x, y)] = out[(x, low)]; parts[(x, y)] = leg
        x0 = round((min(xs) + max(xs) + 1) / 2 - len(BOOT4[0]) / 2)
        for j, row in enumerate(BOOT4):
            for i, ch in enumerate(row):
                if ch in key:
                    out[(x0 + i, y0 + j)] = key[ch].lower(); parts[(x0 + i, y0 + j)] = boot
    return out, parts


def neck2(big, bp):
    """Goal (blind check: no neck, he looks hunched): a short neck under the chin, in the chin's shadow at the top,
    between the collar's two sides."""
    S = [c.lower() for c in C.S1]; D = [c.lower() for c in C.DUSTER]
    out, parts = dict(big), dict(bp)
    for y, (x0, x1) in {34: (66, 73), 35: (66, 73), 36: (67, 72)}.items():
        for x in range(x0, x1 + 1):
            out[(x, y)] = S[0] if x in (x0, x1) else (S[1] if y == 34 else S[2] if x < 70 else S[1])
            parts[(x, y)] = "neck"
    for x, y in ((65, 34), (65, 35), (66, 36), (74, 34), (74, 35), (73, 36)):     # the collar's edges either side
        out[(x, y)] = D[0]; parts[(x, y)] = "collar-near" if x < 70 else "collar-far"
    return out, parts


def eyes_jaw2(big, bp):
    """Goal (blind check: the pupils sat to one side, looking shifty; a stray pale patch on the left jaw): the irises
    centred with an even white either side, and the jaw's lit edge kept to the cheekbone."""
    S = [c.lower() for c in C.S1]
    out, parts = dict(big), dict(bp)
    for ex in (65, 72):
        out[(ex, 27)] = "#e6dacb"; out[(ex + 1, 27)] = "#3a2418"; out[(ex + 2, 27)] = "#e6dacb"
    for (x, y), v in bp.items():
        if v == "face" and y >= 30 and out[(x, y)] == S[3]:
            out[(x, y)] = S[2]
    return out, parts


def smooth_part_edges(big, bp, part_names):
    """Goal (blind check: jagged stair-steps on the sleeves): trim the outer corner of one-pixel stair-steps on the
    given parts' outer edges only, decided on the untouched picture first."""
    out, parts = dict(big), dict(bp)
    trim = []
    for (x, y), v in bp.items():
        if v not in part_names:
            continue
        empty = [(x + dx, y + dy) for dx, dy in NB4 if (x + dx, y + dy) not in big]
        if len(empty) == 2 and empty[0][0] != empty[1][0] and empty[0][1] != empty[1][1]:
            dx = sum(q[0] - x for q in empty); dy = sum(q[1] - y for q in empty)
            if (x - dx, y - dy) in big and (x - 2 * dx, y) in big and (x, y - 2 * dy) in big:
                trim.append((x, y))
    for q in trim:
        nbr = (q[0] - (1 if (q[0] + 1, q[1]) not in big else -1), q[1])
        del out[q]; del parts[q]
        if nbr in out and out[nbr] in TONE:                 # the pixel now on the edge takes the outline tone
            out[nbr] = RAMPS[TONE[out[nbr]][0]][0].lower()
    return out, parts


# a relaxed hand hanging from the sleeve, palm toward the leg, the thumb in front on the body side; "f" are the
# finger lines, "w" the wrist in the sleeve's shadow. Drawn for the near hand; the far hand is its mirror image, still lit from the left.
HAND = ["kwwwwk.",
        "kLssSk.",
        "kLsssSk",
        "kLsssSk",
        "kLssSSk",
        "kLsfsk.",
        "kLsfsk.",
        ".kfsSk.",
        "..kkk.."]


def hands3(big, bp):
    """Goal (round 2 at 2x: the hands read as sideways fists): hands that hang. Taller than wide, from the sleeve's
    cuff down, no wider than the cuff plus the thumb, fingers pointing at the floor."""
    S = [c.lower() for c in C.S1]
    out, parts = dict(big), dict(bp)
    key = {"k": S[0], "S": S[1], "s": S[2], "L": S[3], "f": S[1], "w": S[1]}
    for name, arm in (("hand-near", "arm-near"), ("hand-far", "arm-far")):
        # the far hand mirrored; swapping the lit and shaded edges keeps the light on its left
        grid = HAND if name == "hand-near" else [r[::-1].translate(str.maketrans("LS", "SL")) for r in HAND]
        cells = [p for p, v in bp.items() if v == name]
        for p in cells:
            del out[p]; del parts[p]
        sleeve = [p for p, v in parts.items() if v == arm]
        cuff_y = max(y for _, y in sleeve)
        cuff = [x for x, y in sleeve if y == cuff_y]
        body = 1 if name == "hand-near" else -1            # the side the thumb sits on, toward the body
        width = len(HAND[0]) - 1                            # without the thumb
        x0 = round((min(cuff) + max(cuff) + 1) / 2 - width / 2) - (0 if body == 1 else 1)
        for j, row in enumerate(grid):
            for i, ch in enumerate(row):
                if ch in key:
                    out[(x0 + i, cuff_y + 1 + j)] = key[ch]; parts[(x0 + i, cuff_y + 1 + j)] = name
    return out, parts


def coat_light2(big, bp):
    """Goal (blind check: the coat skirt is lit about equally on both sides): the far panel, on the shadow side, loses
    its brightest highlights below the belt."""
    D = [c.lower() for c in C.DUSTER]
    out = dict(big)
    belt_bottom = max(y for (x, y), v in bp.items() if v == "belt")
    hi = {D[3], rgbhex(ramp7(C.DUSTER)[5]), rgbhex(ramp7(C.DUSTER)[6])}
    for p, v in bp.items():
        if v == "coat-far" and p[1] > belt_bottom and out[p] in hi:
            out[p] = D[2]
    return out, dict(bp)


def eyes3(big, bp):
    """Goal (round 2 at 2x, and a lash line tried in round 3: he looked sleepy, a heavy lid over the eye): open eyes.
    Skin between the brow and the eye, then an eye two rows tall with a dark outer corner: the whites either side of
    an iris that fills both rows, the lower lid in soft shade."""
    S = [c.lower() for c in C.S1]
    out, parts = dict(big), dict(bp)
    for ex in (65, 72):
        for x in range(ex, ex + 3):                        # the brow a row higher, skin between it and the eye
            out[(x, 23)] = C.HAIR1[1].lower(); parts[(x, 23)] = "brow"
            for y in (24, 25):
                out[(x, y)] = S[2] if ex == 65 else S[1]; parts[(x, y)] = "face"
        out[(ex, 26)] = "#e6dacb"; out[(ex + 1, 26)] = "#2a1810"; out[(ex + 2, 26)] = "#e6dacb"
        out[(ex, 27)] = S[2]; out[(ex + 1, 27)] = S[1]; out[(ex + 2, 27)] = S[2]    # a light lower lid; the
                                                    # iris's dark lower half read as a dark spot under the eye
        out[(ex - 1 if ex == 65 else ex + 3, 26)] = S[0]    # the outer corner, so the eye has an edge
        for x in range(ex, ex + 3):
            parts[(x, 26)] = parts[(x, 27)] = "eye"
    return out, parts


# the fringe's new edge over the forehead, rows 21-23 between the sideburns (x 62-77): "H" stays hair, "." becomes
# skin. Two locks fall a little lower so the hairline is ragged, not a ruler line.
FRINGE = {21: "HHHH.....HHHHHHH",
          22: "HHH.......HHHHH.",
          23: ".H.........HH..."}


def forehead(big, bp):
    """Goal (blind check, twice: sleepy, the hair sits right on the eyes like a hat): a forehead. The fringe lifts
    off the brows by two to three rows, ragged, with a strip of skin above the brows; the sideburns stay."""
    S = [c.lower() for c in C.S1]; H = [c.lower() for c in C.HAIR1]
    out, parts = dict(big), dict(bp)
    for y, row in FRINGE.items():
        for i, ch in enumerate(row):
            x = 62 + i
            if ch == ".":
                lit = x < 70
                out[(x, y)] = S[3] if (lit and y == 23 and x < 66) else S[2] if lit else S[1]
                parts[(x, y)] = "face"
            elif y == 23 or FRINGE[y + 1][i] == ".":
                out[(x, y)] = H[1]; parts[(x, y)] = "hair"      # the lock's tip, a step darker against the skin
    for x in range(62, 78):                                     # the fringe casts a soft shadow on the skin below it
        for y in (22, 23, 24):
            if parts.get((x, y)) == "face" and parts.get((x, y - 1)) == "hair" and out[(x, y)] in (S[2], S[3]):
                out[(x, y)] = S[1] if x >= 70 else rgbhex(ramp7(C.S1)[3])
    return out, parts


def face_light(big, bp):
    """Goal (blind check: the face's shadow side is cut hard down the middle, like half a mask): the light turns
    round the face. Where the lit tone meets the shadow tone, the shadow's first column takes the tone between them,
    and the line steps out toward the cheek as it goes down, as a rounded face would."""
    S = [c.lower() for c in C.S1]
    mid = rgbhex(ramp7(C.S1)[3])
    out = dict(big)
    face = {p for p, v in bp.items() if v == "face"}
    for (x, y) in sorted(face):
        if big[(x, y)] == S[1] and big.get((x - 1, y)) in (S[2], S[3]) and (x - 1, y) in face:
            out[(x, y)] = mid
            if y >= 27 and (x + 1, y) in face and big.get((x + 1, y)) == S[1]:
                out[(x + 1, y)] = mid                           # lower down the turn is wider: the cheek
    return out, dict(bp)


def check(name, before, bparts, after, aparts, allowed, scale=1):
    bad = qa.detail_survival(before, bparts, after, aparts, [p for p in PROTECTED if p not in allowed], scale)
    outside = qa.part_diff(before, after, aparts, allowed, scale, bparts)
    st, ho = qa.stray_pixels(after), qa.holes(after)
    ok = not bad and not outside and not st and not ho
    print(f"{name:<34} {'PASS' if ok else 'FAIL'}" + ("" if ok else f"  details:{bad} outside:{len(outside)} stray:{st[:6]} holes:{ho[:6]}"))
    return ok


def build():
    """Every goal in order, each checked; returns the finished sprite, its part map and the saved stages."""
    px = crews2.crew1(); parts = dict(paint2.PARTS)
    big, bp = up2(px, parts)
    stages = [("0-blocks", big, bp)]
    s1 = soften(big, bp, {"coat-near", "coat-far", "arm-near", "arm-far"})
    check("1 coat and sleeve shading", big, bp, s1, bp, {"coat-near", "coat-far", "arm-near", "arm-far"})
    stages.append(("1-coat-shading", s1, bp))
    s2 = s1
    for group in ({"coat-near", "coat-far", "arm-near", "arm-far"}, {"hair"}, {"face"}, {"leg-near", "leg-far"},
                  {"hand-near", "hand-far"}):
        s = thin_outline(s2, bp, group)
        check("2 thinner outline: " + "/".join(sorted(group)), s2, bp, s, bp, group)
        s2 = s
    stages.append(("2-outlines", s2, bp))
    s3, p3 = belt_collar(s2, bp)
    check("3 belt and collar stand out", s2, bp, s3, p3, {"belt", "buckle", "collar-near", "collar-far", "lapel-near", "lapel-far", "coat-near", "coat-far", "torso", "face"})
    print("   belt contrast", round(qa.part_contrast(s2, bp, "belt")), "->", round(qa.part_contrast(s3, p3, "belt")))
    stages.append(("3-belt-collar", s3, p3))
    s4, p4 = boots2(s3, p3)
    check("4 matched boots", s3, p3, s4, p4, {"boot-near", "boot-far"})
    print("   boot shape mismatch", round(qa.pair_symmetry(p3, "boot-near", "boot-far"), 2), "->", round(qa.pair_symmetry(p4, "boot-near", "boot-far"), 2))
    stages.append(("4-boots", s4, p4))
    s5, p5 = face2(s4, p4)
    check("5 jaw, neck, eyes, mouth", s4, p4, s5, p5, {"face", "eye", "mouth", "brow", "neck", "torso", "lapel-near", "lapel-far", "coat-near", "coat-far", "collar-near", "collar-far", "hair"})
    stages.append(("5-face", s5, p5))
    s, pr = s5, p5
    for title, fn, allowed in (
            ("6 boots tucked in, toes forward", boots4, {"boot-near", "boot-far", "leg-near", "leg-far"}),
            ("7 a neck", neck2, {"neck", "collar-near", "collar-far", "torso", "lapel-near", "lapel-far", "coat-near", "coat-far"}),
            ("8 centred eyes, cleaner jaw", eyes_jaw2, {"eye", "face"}),
            ("8b a forehead", forehead, {"hair", "face"}),
            ("8c the light turns round the face", face_light, {"face"}),
            ("8d open eyes", eyes3, {"eye", "face", "brow"}),
            ("9 smoother sleeve edges", lambda a, b: smooth_part_edges(a, b, {"arm-near", "arm-far"}), {"arm-near", "arm-far"}),
            ("10 hanging hands", hands3, {"hand-near", "hand-far"}),
            ("11 the coat's far side in shade", coat_light2, {"coat-far"}),
            # the legs are drawn with the coat off, then the coat goes back on, so they're checked as one goal
            ("12 legs drawn bare, then the coat and sleeves by shape over them",
             lambda a, b: coat3.redraw(*legs3.redraw(a, b), [rgbhex(t) for t in ramp7(C.DUSTER)]),
             {"coat-near", "coat-far", "arm-near", "arm-far", "hand-near", "hand-far", "lapel-near", "lapel-far",
              "collar-near", "collar-far", "belt", "leg-near", "leg-far"}),
            ("13 hands hanging from the new cuffs", hands3, {"hand-near", "hand-far", "coat-near", "coat-far"})):
        s2_, p2_ = fn(s, pr)
        check(title, s, pr, s2_, p2_, allowed)
        s, pr = s2_, p2_
    print("   boot shape mismatch", round(qa.pair_symmetry(pr, "boot-near", "boot-far"), 2),
          "| toes off centre", qa.boot_forward(pr, "boot-near"), qa.boot_forward(pr, "boot-far"),
          "| attached", qa.attached(pr, "boot-near", "leg-near"), qa.attached(pr, "boot-far", "leg-far"))
    print("   hands", qa.hand_hangs(pr, "hand-near", "arm-near"), qa.hand_hangs(pr, "hand-far", "arm-far"))
    stages.append(("6-round2", s, pr))
    return s, pr, stages


if __name__ == "__main__":
    sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "mecha", "light-attack-frame", "pixel-redo", "tools"))
    from pixel_svg import paths
    out_dir = sys.argv[1]; os.makedirs(out_dir, exist_ok=True)
    s, pr, stages = build()
    import json
    json.dump({f"{x},{y}": v for (x, y), v in pr.items()}, open(os.path.join(out_dir, "parts.json"), "w"))
    json.dump({f"{x},{y}": c for (x, y), c in s.items()}, open(os.path.join(out_dir, "pixels.json"), "w"))
    for name, im, _ in stages:
        open(os.path.join(out_dir, f"drifter-2x-{name}.svg"), "w").write(
            f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 140 140" width="560" height="560" shape-rendering="crispEdges">'
            f'<rect width="140" height="140" fill="#9da2aa"/>{paths(im)}</svg>\n')
