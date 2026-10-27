from figure import *
from crew1 import head_key, HAND

SKIN = ["#3a2018", "#7e4c38", "#b47a5a", "#d49e7a"]
VEST = ["#161a0e", "#353c22", "#525a34", "#747c4c"]          # canvas utility vest
SHIRT = ["#2e2620", "#5e5244", "#857864", "#ab9e86"]          # rolled-sleeve shirt, dusty sand
CARGO = ["#161410", "#2e2a22", "#454033", "#625b4a"]
BOOTS = ["#0b0908", "#1e1a16", "#302922", "#4a3f34"]
HAIR = ["#0e0806", "#2a1610", "#44261a", "#663c28"]
WRAP = ["#2a2420", "#5a5048", "#8a7e70", "#b0a494"]

# long hair pulled back into a braid over the near shoulder; a narrower face
HEAD = ["....oooo....",
        "..ooHHhhoo..",
        ".oHHhhhhhdo.",
        ".ohhhhhhhhdo",
        ".ohhhdddhhdo",
        ".ohhdLLLLsko",
        ".ohdLbbsbbk.",
        ".ohdLLesesk.",
        ".ohdLssssnk.",
        ".ohhkLsssnk.",
        "..ohkssmmk..",
        "..oh.kssk...",
        "...h..kk...."]


def parts():
    hk = head_key(SKIN, HAIR)
    sk = {"k": (SKIN, 0), "s": (SKIN, 2), "L": (SKIN, 3), "S": (SKIN, 1)}
    return [
        part("arm-far", poly([(39.5, 26), (44, 27), (44.5, 33), (40.5, 33)]), SHIRT, "round"),
        part("forearm-far", poly([(40.5, 32.5), (44.5, 32.5), (44.5, 41), (41.5, 41)]), SKIN, "round"),
        part("wrap-far", poly([(41, 37), (44.6, 37), (44.6, 39.5), (41.2, 39.5)]), WRAP),
        sprite("hand-far", grid(40.5, 40, HAND, hk)),
        part("leg-far", poly([(35, 42), (40.5, 42), (40, 55), (36, 55)]), CARGO, "round"),
        part("boot-far", poly([(35.5, 54), (40.5, 54), (41.5, 58), (43, 60), (35.5, 60)]), BOOTS),
        part("leg-near", poly([(29, 42), (34.5, 42), (34, 57), (29.5, 57)]), CARGO, "round"),
        part("boot-near", poly([(29, 56), (34, 56), (35, 59.5), (37, 61.5), (28.5, 62)]), BOOTS),
        part("shirt", poly([(29, 25), (40, 25), (39.5, 42.5), (29.5, 42.5)]), SHIRT),
        part("vest-far", poly([(36, 24.5), (40.5, 25.5), (40.5, 41), (36.5, 41.5)]), VEST),
        part("vest-near", poly([(28, 25), (33.5, 24.5), (33, 41.5), (28.5, 41)]), VEST),
        part("arm-near", poly([(25, 26), (29.5, 26.5), (29, 33), (24.5, 33)]), SHIRT, "round"),
        part("forearm-near", poly([(24.5, 32.5), (29, 32.5), (28.5, 41), (25, 41)]), SKIN, "round"),
        part("wrap-near", poly([(24.6, 37), (28.8, 37), (28.7, 39.5), (24.8, 39.5)]), WRAP),
        sprite("hand-near", grid(24.5, 40, HAND, hk)),
        part("neck", poly([(32, 21), (36, 21), (36, 25), (32, 25)]), SKIN),
        part("braid", poly([(29, 20), (31.5, 21), (31, 30), (29.5, 31)]), HAIR, "round"),
        sprite("head", grid(28, 10, HEAD, hk)),
    ]


def details():
    d = []
    d += [((x, 30), VEST[0]) for x in (29, 30, 31)] + [((x, 30), VEST[0]) for x in (37, 38, 39)]   # vest pocket flaps
    d += [((x, 34), VEST[1]) for x in (29, 30, 31)] + [((x, 34), VEST[1]) for x in (37, 38, 39)]
    d += [((30, 31), "#2a2a20")]
    # personal emblem: a stitched teal fish hook on the far vest panel
    d += [((38, 37), "#3fa0a0"), ((38, 38), "#3fa0a0"), ((38, 39), "#3fa0a0"), ((37, 39), "#2e7a7a"), ((39, 36), "#3fa0a0")]
    d += [((30, 31 + k), HAIR[3]) for k in (0, 3, 6)]            # braid ties catching the light
    d += [((x, 42), "#1e1a12") for x in range(29, 40)]           # belt line
    d += [((30, y), CARGO[1]) for y in (48, 49)] + [((39, y), CARGO[1]) for y in (47, 48)]   # cargo pocket seams
    return d
