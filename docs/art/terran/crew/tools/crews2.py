import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from paint2 import paint, poly, grid, J
import crews as C          # palettes and the round 2 heads

HX, HY = 30, 6


# a matched pair of boots, the same shape on both feet (the light still comes from the upper left on both)
BOOT = [".kbbdk.",
        ".kLbdk.",
        ".kLbdk.",
        "kLLbbdk",
        "kLbbbdk",
        "kLbbbdk",
        "kbbbbdk",
        ".kssss."]


def boots(ramp, y0=55):
    key = {"k": (ramp, 0), "d": (ramp, 1), "b": (ramp, 2), "L": (ramp, 3), "s": "#0a0809"}
    cx = (J["ankle_r"][0] + J["ankle_l"][0]) / 2
    near = grid(round(J["ankle_r"][0] - 3.5), y0, BOOT, key)
    far_x = round(2 * cx - J["ankle_r"][0] - 3.5)
    return {**near, **grid(far_x, y0, BOOT, key)}


def boot_pixels(ramp):
    return {p: (v if isinstance(v, str) else v[0][v[1]]) for p, v in boots(ramp).items()}


def coat_tone(panel_lo, panel_hi, folds, belt_rows, lapel=None, inner_edge=None):
    """Trench-coat shading for one panel: shoulder tops lit, a belt band, folds hanging from the belt (a lit column
    and a shadow column each, flaring outward as they fall), a dark lining line on the open front edge below the belt,
    and the hem in shade."""
    def fn(x, y, t, stage):
        if stage < 3:
            return t
        if y <= 16 and t == 2 and x <= (panel_lo + panel_hi) // 2:
            t = 3                                         # shoulder top, facing the light from above
        if y in belt_rows:
            return 0 if y == belt_rows[-1] else 1         # the belt
        if lapel:
            face, edge = lapel
            if face(x, y):
                return 3 if t >= 2 else 2                 # the lapel folded back, catching the light
            if edge(x, y):
                return 1                                  # the shadow under the lapel's edge
        if belt_rows[-1] + 2 < y < 49:
            for fx, direction in folds:
                fx += (y - belt_rows[-1]) // 8 * direction        # the fold drifts outward as the coat flares
                if x == fx:
                    return 1                                      # one soft fold: a shadow line...
                if x == fx - 1 and y > 38 and t == 2:
                    return 3                                      # ...lit on its upper-left side lower down
        if inner_edge is not None and y > belt_rows[-1] and x == inner_edge:
            return 1
        if y >= 49 and t == 2:
            return 1                                              # the hem, turning under
        return t
    return fn


def head(skin, hair, rows):
    return C.head(skin, hair, rows, HX, HY)


def crew1(stage=5):
    D = C.DUSTER
    mats = {"torso": C.SHIRT1, "arm-near": D, "arm-far": D, "hand-near": C.S1, "hand-far": C.S1,
            "leg-near": C.PANTS1, "leg-far": C.PANTS1, "boot": None}
    belt = [29, 30]
    near_lapel = (lambda x, y: 15 <= y <= 23 and 33 - (23 - y) // 3 <= x <= 33,
                  lambda x, y: 15 <= y <= 23 and x == 33 - (23 - y) // 3 - 1)
    far_lapel = (lambda x, y: 15 <= y <= 23 and 36 <= x <= 36 + (23 - y) // 3,
                 lambda x, y: 15 <= y <= 23 and x == 36 + (23 - y) // 3 + 1)
    over = [(poly([(27.5, 14.5), (34, 15), (34, 31), (33.5, 51), (25, 50.5), (26.5, 31)]), D,
             coat_tone(25, 34, [(29, -1)], belt, near_lapel, inner_edge=33)),
            (poly([(36, 15), (42.5, 14.5), (43.5, 31), (45.5, 50.5), (36.5, 51), (36, 31)]), D,
             coat_tone(36, 46, [(41, 1)], belt, far_lapel, inner_edge=36)),
            (set(boots(C.BOOTS)), C.BOOTS, lambda x, y, t, s: t)]
    over[-1] = None
    over = [o for o in over if o]
    d = [((35, y), C.SHIRT1[1]) for y in (20, 24)]
    d += [((34, 29), "#c8a860"), ((35, 29), "#a8884a")]                                    # belt buckle
    d += [((29, 19), "#c8a050"), ((28, 20), "#c8a050"), ((30, 20), "#a07c38"), ((29, 21), "#a07c38"), ((29, 20), "#3a2416")]
    d += [(p, c) for p, c in boot_pixels(C.BOOTS).items()]
    return paint(mats, over, head(C.S1, C.HAIR1, C.H1), d, stage)


def crew2(stage=5):
    L = C.LEATHER
    mats = {"torso": L, "arm-near": L, "arm-far": L, "hand-near": C.S2, "hand-far": C.S2,
            "leg-near": C.JEANS, "leg-far": C.JEANS, "boot": None}
    over = [(poly([(33.5, 16.5), (36.5, 16.5), (37, 27.5), (33, 27.5)]), C.SHIRT2),
            (poly([(28.5, 27), (41.5, 27), (42, 34.5), (28, 35)]), C.SHIRT2),
            (poly([(45, 20), (49, 20.5), (49.5, 22.5), (45.5, 22.5)]), C.BANDANA)]
    d = [((x, 26), L[0]) for x in list(range(29, 34)) + list(range(37, 42))]
    d += [((33, y), L[3]) for y in range(17, 26, 2)]
    d += [((24, 18), L[3]), ((25, 17), L[3]), ((23, 22), L[3]), ((45, 18), L[3])]
    d += [((39, 20), "#c0503a"), ((40, 19), "#c0503a"), ((41, 20), "#c0503a"), ((40, 22), "#c0503a"), ((41, 21), "#8e3a2a")]
    d += [((31, y), C.SHIRT2[1]) for y in range(29, 34)] + [((38, y), C.SHIRT2[1]) for y in range(30, 34)]
    d += list(boot_pixels(C.BOOTS).items())
    return paint(mats, over, head(C.S2, C.HAIR2, C.H2), d, stage)


def crew3(stage=5):
    sleeve = lambda x, y: C.SHIRT3 if y <= 24 else C.S3
    mats = {"torso": C.SHIRT3, "arm-near": sleeve, "arm-far": sleeve, "hand-near": C.S3, "hand-far": C.S3,
            "leg-near": C.CARGO, "leg-far": C.CARGO, "boot": None}
    over = [(poly([(28.5, 16), (33.5, 16), (33.5, 31), (28.5, 31)]), C.VEST),
            (poly([(36.5, 16), (41.5, 16), (41.5, 31), (36.5, 31)]), C.VEST),
            (poly([(21, 28), (26, 28), (26, 30), (21, 30)]), C.WRAP), (poly([(45.5, 28), (50.5, 28), (50.5, 30), (45.5, 30)]), C.WRAP),
            (poly([(29.5, 14), (32, 15), (31.5, 26), (30, 27)]), C.HAIR3)]
    d = [((x, 21), C.VEST[0]) for x in (31, 32)] + [((x, 21), C.VEST[0]) for x in (38, 39, 40)]
    d += [((38, 26), "#3fa0a0"), ((38, 27), "#3fa0a0"), ((38, 28), "#3fa0a0"), ((37, 28), "#2e7a7a"), ((39, 25), "#3fa0a0")]
    d += [((30, 18), C.HAIR3[3]), ((30, 22), C.HAIR3[3]), ((30, 25), C.HAIR3[3])]
    d += [((x, 31), "#1e1a12") for x in range(29, 41)]
    d += [((28, 42), C.CARGO[1]), ((28, 43), C.CARGO[1]), ((41, 41), C.CARGO[1]), ((41, 42), C.CARGO[1])]
    d += list(boot_pixels(C.BOOTS).items())
    return paint(mats, over, head(C.S3, C.HAIR3, C.H3), d, stage)


CREWS = [("1. Long-coat drifter", crew1), ("2. Leather jacket", crew2), ("3. Vest merc", crew3)]
