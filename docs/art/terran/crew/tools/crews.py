import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from paint import paint, poly, grid

BOOTS = ["#0b0a0c", "#1c1819", "#2d2727", "#463b37"]


def head(skin, hair, rows, x0=30, y0=6):
    key = {"o": (hair, 0), "d": (hair, 1), "h": (hair, 2), "H": (hair, 3), "k": (skin, 0), "S": (skin, 1),
           "s": (skin, 2), "L": (skin, 3), "b": (hair, 1), "e": "#16100e", "m": "#5e2c24", "z": (skin, 1)}
    return grid(x0, y0, rows, key)


# 1. long-coat drifter
S1 = ["#4a2622", "#a0604e", "#d0927a", "#ecbc9a"]
DUSTER = ["#24130f", "#57301f", "#7c4a2b", "#a26a40"]
SHIRT1 = ["#10262a", "#2a5054", "#3f7470", "#64a094"]
PANTS1 = ["#11141c", "#222936", "#333d4e", "#4a566a"]
HAIR1 = ["#120b09", "#2c1b13", "#47301f", "#664530"]
H1 = ["..oooooo..",
      ".oHHhhhho.",
      "oHHhhhhdoo",
      "oHhhhhdooo",
      "ohhhhohdoo",
      "oLLssssSko",
      "oLkkSkkSko",
      "kLsssSsSkk",
      "kLsssSSSkk",
      "kLssSSSSk.",
      ".kLssSSSk.",
      ".kkkkkkkk."]


def crew1(stage=5):
    mats = {"torso": SHIRT1, "arm-near": DUSTER, "arm-far": DUSTER, "hand-near": S1, "hand-far": S1,
            "leg-near": PANTS1, "leg-far": PANTS1, "boot": BOOTS}
    over = [(poly([(27, 15.5), (33.5, 16), (33, 34), (32.5, 55), (24, 54.5), (25.5, 34), (27.5, 24)]), DUSTER),
            (poly([(37, 16), (42.5, 15.5), (43, 24), (44, 34), (46, 54), (37.5, 55), (37, 34)]), DUSTER)]
    d = [((33, y), DUSTER[3]) for y in range(18, 33)]                       # the near lapel's lit edge
    d += [((35, y), SHIRT1[1]) for y in (21, 25, 29)]                       # shirt buttons
    d += [((x, 33), "#2a1c14") for x in range(34, 37)] + [((35, 33), "#c8a860")]   # belt and buckle
    d += [((29, 20), "#c8a050"), ((28, 21), "#c8a050"), ((30, 21), "#a07c38"), ((29, 22), "#a07c38"), ((29, 21), "#3a2416")]
    d += [((26, 50), DUSTER[1]), ((28, 53), DUSTER[1]), ((44, 49), DUSTER[1])]
    return paint(mats, over, head(S1, HAIR1, H1), d, stage)


# 2. leather jacket
S2 = ["#2a1612", "#5e3426", "#87523a", "#a8704e"]
LEATHER = ["#08080c", "#16161e", "#262632", "#44465a"]
SHIRT2 = ["#2a0e0c", "#5e1e18", "#8a2e22", "#ad4a34"]
JEANS = ["#0e1424", "#1f2d48", "#33466a", "#4f6690"]
HAIR2 = ["#08080a", "#16141a", "#26232a", "#3c3842"]
BANDANA = ["#2a2410", "#6e5e22", "#a08a34", "#c8b050"]
H2 = ["...oooo...",
      ".oohhhhoo.",
      "oHhhhhhdoo",
      "ohhhhhdooo",
      "kddddddoko",
      "kLLssssSkk",
      "kLkkSkkSkk",
      "kLsssSsSkk",
      "kLsssSSSkk",
      "kLssSSSSk.",
      ".kLssSSSk.",
      ".kkkkkkkk."]


def crew2(stage=5):
    mats = {"torso": LEATHER, "arm-near": LEATHER, "arm-far": LEATHER, "hand-near": S2, "hand-far": S2,
            "leg-near": JEANS, "leg-far": JEANS, "boot": BOOTS}
    over = [(poly([(33.5, 16.5), (36.5, 16.5), (37, 30), (33, 30)]), SHIRT2),            # open front
            (poly([(28, 29.5), (42, 29.5), (42.5, 37.5), (27.5, 38)]), SHIRT2),          # long shirt below the jacket
            (poly([(43, 22), (47, 22), (47, 24.5), (43, 24.5)]), BANDANA)]
    d = [((x, 29), LEATHER[0]) for x in list(range(28, 34)) + list(range(37, 43))]    # the jacket's waistband
    d += [((33, y), LEATHER[3]) for y in range(17, 29, 2)]                             # zip teeth
    d += [((25, 18), LEATHER[3]), ((26, 17), LEATHER[3]), ((24, 22), LEATHER[3]), ((44, 18), LEATHER[3])]
    d += [((39, 21), "#c0503a"), ((40, 20), "#c0503a"), ((41, 21), "#c0503a"), ((40, 23), "#c0503a"), ((41, 22), "#8e3a2a")]
    d += [((31, y), SHIRT2[1]) for y in range(32, 37)] + [((38, y), SHIRT2[1]) for y in range(33, 37)]
    d += [((28, 46), JEANS[3]), ((29, 47), JEANS[3])]
    return paint(mats, over, head(S2, HAIR2, H2), d, stage)


# 3. vest merc
S3 = ["#3a2018", "#7e4c38", "#b47a5a", "#d49e7a"]
VEST = ["#161a0e", "#353c22", "#525a34", "#747c4c"]
SHIRT3 = ["#2e2620", "#5e5244", "#857864", "#ab9e86"]
CARGO = ["#161410", "#2e2a22", "#454033", "#625b4a"]
HAIR3 = ["#0e0806", "#2a1610", "#44261a", "#663c28"]
WRAP = ["#2a2420", "#5a5048", "#8a7e70", "#b0a494"]
H3 = ["..oooooo..",
      ".oHHhhhho.",
      "oHhhhhhdoo",
      "oHhhhhdooo",
      "ohhdhhhooo",
      "ohLLssSSko",
      "ohLkkSkkko",
      "ohLssSsSk.",
      "ohLssSSSk.",
      "oh.kLSSk..",
      "oh.kLSSk..",
      "oh..kkk..."]


def crew3(stage=5):
    sleeve = lambda x, y: SHIRT3 if y <= 25 else S3
    mats = {"torso": SHIRT3, "arm-near": sleeve, "arm-far": sleeve, "hand-near": S3, "hand-far": S3,
            "leg-near": CARGO, "leg-far": CARGO, "boot": BOOTS}
    over = [(poly([(28, 16), (33.5, 16), (33.5, 33.5), (28.5, 33.5)]), VEST),
            (poly([(36.5, 16), (42, 16), (41.5, 33.5), (36.5, 33.5)]), VEST),
            (poly([(23, 29), (28, 29), (28, 31), (23, 31)]), WRAP), (poly([(42, 29), (46.5, 29), (46.5, 31), (42, 31)]), WRAP),
            (poly([(29, 15), (31.5, 16), (31, 27), (29.5, 28)]), HAIR3)]                  # the braid over the near shoulder
    d = [((x, 22), VEST[0]) for x in (32, 33)] + [((x, 22), VEST[0]) for x in (38, 39, 40)]   # pocket flaps
    d += [((38, 27), "#3fa0a0"), ((38, 28), "#3fa0a0"), ((38, 29), "#3fa0a0"), ((37, 29), "#2e7a7a"), ((39, 26), "#3fa0a0")]
    d += [((30, 19), HAIR3[3]), ((30, 23), HAIR3[3]), ((30, 26), HAIR3[3])]
    d += [((x, 33), "#1e1a12") for x in range(29, 42)]
    d += [((27, y), CARGO[1]) for y in (44, 45)] + [((39, y), CARGO[1]) for y in (43, 44)]
    return paint(mats, over, head(S3, HAIR3, H3), d, stage)


CREWS = [("1. Long-coat drifter", crew1), ("2. Leather jacket", crew2), ("3. Vest merc", crew3)]
