from figure import *
from crew1 import head_key, HAND

SKIN = ["#2a1612", "#5e3426", "#87523a", "#a8704e"]
LEATHER = ["#08080c", "#16161e", "#262632", "#44465a"]
SHIRT = ["#2a0e0c", "#5e1e18", "#8a2e22", "#ad4a34"]          # a faded red long shirt
JEANS = ["#0e1424", "#1f2d48", "#33466a", "#4f6690"]
BOOTS = ["#0a0807", "#1e1612", "#2e221a", "#4a382a"]
HAIR = ["#08080a", "#16141a", "#26232a", "#3c3842"]
BANDANA = ["#2a2410", "#6e5e22", "#a08a34", "#c8b050"]

# shaved sides, a longer slicked-back top (no mohawk); a hard jaw, a short scar through the brow
HEAD = ["....ooooo...",
        "..ooHHhhHo..",
        ".oHhHhhHhhdo",
        ".kdhhHhhhhdo",
        ".kSddhdhddko",
        ".kSLLLLLLsko",
        ".kSLbbsbbsk.",
        ".kSLLesesSk.",
        ".kSLLssssnk.",
        ".kSLsssssnk.",
        "..kSsmmmsk..",
        "..kSSsssSk..",
        "...kkkkkk..."]


def parts():
    hk = head_key(SKIN, HAIR)
    return [
        part("arm-far", poly([(40, 26), (46, 27.5), (47.5, 35), (46.5, 43), (43, 43), (42.5, 35)]), LEATHER, "round"),
        part("bandana", poly([(42.5, 31.5), (47, 31.5), (47.3, 34), (42.5, 34)]), BANDANA),
        sprite("hand-far", grid(43, 42, HAND, hk)),
        part("leg-far", poly([(35.5, 45), (41.5, 45), (41, 55), (36.5, 55)]), JEANS, "round"),
        part("cuff-far", poly([(36, 53.5), (41.5, 53.5), (41.5, 55.5), (36, 55.5)]), JEANS),
        part("boot-far", poly([(35.5, 55), (41.5, 55), (42.5, 58.5), (44, 60), (35.5, 60.5)]), BOOTS),
        part("leg-near", poly([(27.5, 45), (34.5, 45), (34, 56), (28.5, 56)]), JEANS, "round"),
        part("cuff-near", poly([(28, 54.5), (34.5, 54.5), (34.5, 56.5), (28, 56.5)]), JEANS),
        part("boot-near", poly([(27.5, 56), (34.5, 56), (35.5, 59), (37.5, 61.5), (27, 62)]), BOOTS),
        part("shirt", poly([(27, 24.5), (42, 24.5), (42.5, 46), (27, 47)]), SHIRT),          # hangs below the jacket
        part("jacket-far", poly([(36.5, 23.5), (43.5, 25), (44, 38.5), (37.5, 39)]), LEATHER),
        part("jacket-near", poly([(24.5, 24), (33, 23.5), (32, 30), (32, 39.5), (24.5, 39)]), LEATHER),
        part("arm-near", poly([(22.5, 25), (28, 26), (27.5, 35), (27, 43), (23, 43.5), (21.5, 35)]), LEATHER, "round"),
        sprite("hand-near", grid(22.5, 42, HAND, hk)),
        part("neck", poly([(31.5, 21), (37, 21), (37, 25), (31.5, 25)]), SKIN),
        part("collar", poly([(29, 22.5), (32.5, 21.5), (33, 27), (30.5, 28)]) | poly([(36, 21.5), (39.5, 22.5), (39, 28), (36.5, 27)]), LEATHER),
        sprite("head", grid(28, 10, HEAD, hk)),
    ]


def details():
    d = []
    d += [((x, 39), LEATHER[0]) for x in range(25, 33)] + [((x, 39), LEATHER[0]) for x in range(38, 44)]   # waistband
    d += [((26, 31), "#8a8e9a"), ((26, 34), "#8a8e9a")]          # zip pulls on the near panel
    d += [((32, y), LEATHER[3]) for y in range(25, 38, 2)]       # zip teeth on the open front
    # personal emblem on the far chest: a small rust-red broken circle (painted, not sewn)
    d += [((39, 29), "#c0503a"), ((40, 28), "#c0503a"), ((41, 29), "#c0503a"), ((40, 31), "#c0503a"), ((41, 30), "#8e3a2a")]
    d += [((35, 9 + 6), "#3a1e18")]                              # the brow scar
    # leather catching the light: curved streaks on the shoulders and sleeves
    d += [((24, 27), LEATHER[3]), ((25, 26), LEATHER[3]), ((23, 30), LEATHER[3]), ((23, 34), LEATHER[3]),
          ((41, 26), LEATHER[3]), ((42, 26), LEATHER[3]), ((26, 36), LEATHER[3]), ((44, 30), LEATHER[3])]
    d += [((29, y), SHIRT[1]) for y in range(40, 46)] + [((33, y), SHIRT[1]) for y in range(41, 46)]   # shirt folds
    d += [((40, 44), SHIRT[1]), ((40, 45), SHIRT[1]), ((28, 46), SHIRT[0])]
    d += [((30, 50), JEANS[3]), ((31, 51), JEANS[3]), ((39, 49), JEANS[1])]   # worn knee
    return d
