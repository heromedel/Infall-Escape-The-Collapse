from figure import *

SKIN = ["#4a2622", "#a0604e", "#d0927a", "#ecbc9a"]
DUSTER = ["#24130f", "#57301f", "#7c4a2b", "#a26a40"]
SHIRT = ["#10262a", "#2a5054", "#3f7470", "#64a094"]
PANTS = ["#11141c", "#222936", "#333d4e", "#4a566a"]
BOOTS = ["#0b0a0c", "#1c1819", "#2d2727", "#463b37"]
HAIR = ["#120b09", "#2c1b13", "#47301f", "#664530"]
BELT = ["#0e0b0a", "#2a1c14", "#3e2a1c", "#5a3e28"]


def head_key(skin, hair):
    return {"o": (hair, 0), "d": (hair, 1), "h": (hair, 2), "H": (hair, 3),
            "k": (skin, 0), "S": (skin, 1), "s": (skin, 2), "L": (skin, 3), "n": (skin, 1),
            "e": "#16100e", "b": (hair, 1), "m": "#5e2c24"}


HEAD = ["....oooo....",
        "..ooHHhhoo..",
        ".oHHhhhhhdo.",
        ".ohhhhhhhhdo",
        ".ohhhhdddhdo",
        ".ohhdLLLLsko",
        ".ohdLbbsbbko",
        ".oSLLLesesSk",
        ".kSLLssssnk.",
        "..kLsssssnk.",
        "..ksssmmsk..",
        "...kssssk...",
        "....kkkk...."]
HAND = [".kk.", "kLsk", "ksSk", ".kk."]


def parts():
    hk = head_key(SKIN, HAIR)
    return [
        part("arm-far", poly([(40, 27), (45, 28), (46.5, 36), (46, 43), (42.5, 43), (42, 36)]), DUSTER, "round"),
        sprite("hand-far", grid(42, 42, HAND, hk)),
        part("leg-far", poly([(35, 43), (41, 43), (40, 55), (36, 55)]), PANTS, "round"),
        part("boot-far", poly([(35.5, 54), (40.5, 54), (41.5, 58), (43, 60), (35.5, 60)]), BOOTS),
        part("leg-near", poly([(28, 43), (34.5, 43), (33.5, 57), (29, 57)]), PANTS, "round"),
        part("boot-near", poly([(28.5, 56), (33.5, 56), (34.5, 59.5), (36.5, 61.5), (28, 62)]), BOOTS),
        part("shirt", poly([(28, 25), (41, 25), (40.5, 41), (28.5, 41)]), SHIRT),
        part("belt", poly([(28.5, 40), (40.5, 40), (40.5, 42.5), (28.5, 42.5)]), BELT),
        part("coat-far", poly([(36.5, 24.5), (42.5, 25.5), (43.5, 40), (45, 55), (39, 55.5), (37.5, 41), (37, 31)]), DUSTER),
        part("coat-near", poly([(26, 24.5), (32.5, 24.5), (31.5, 32), (31, 41), (30.5, 56.5), (24, 57), (24.5, 41), (25, 30)]), DUSTER),
        part("arm-near", poly([(23.5, 26), (28.5, 27), (27.8, 36), (27.5, 43), (23.5, 43.5), (22.5, 36)]), DUSTER, "round"),
        sprite("hand-near", grid(23, 42, HAND, hk)),
        part("neck", poly([(32, 21), (36.5, 21), (36.5, 25), (32, 25)]), SKIN),
        part("collar", poly([(29.5, 22.5), (32.5, 21.5), (33, 26.5), (31, 28)]) | poly([(36, 21.5), (39, 22.5), (38.5, 28), (36.5, 26.5)]), DUSTER),
        sprite("head", grid(28, 10, HEAD, hk)),
    ]


def details():
    d = []
    d += [((34, 40), "#a8884a"), ((35, 40), "#d8bc7a"), ((34, 41), "#d8bc7a"), ((35, 41), "#a8884a")]   # buckle
    d += [((34, 30), SHIRT[1]), ((34, 34), SHIRT[1]), ((34, 38), SHIRT[1])]   # shirt buttons
    # personal emblem on the near shoulder: a faded gold diamond with a dark centre
    d += [((26, 29), "#c8a050"), ((25, 30), "#c8a050"), ((27, 30), "#a07c38"), ((26, 31), "#a07c38"), ((26, 30), "#3a2416")]
    d += [((31, y), DUSTER[3]) for y in range(27, 40)]    # the near lapel's lit edge
    d += [((25, 52), DUSTER[1]), ((27, 55), DUSTER[1]), ((42, 50), DUSTER[1])]   # scuffs on the hem
    return d
