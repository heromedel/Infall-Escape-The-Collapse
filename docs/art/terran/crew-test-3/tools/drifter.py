"""The Terran drifter, drawn a pixel at a time: a 35 by 35 crew sprite seen from about 45 degrees above.

Each part is rows of text, one character a pixel (the colours are in pix.py), on a grid 17 wide and 26 tall whose
corner sits at (9, 6) in the frame, so the boots stand on the same line as the Mecha's. A frame is parts laid over
each other; a walking frame moves the upper body a pixel down when a foot lands.
"""
import sys
sys.path.insert(0, "tools")
from pix import *

LEFT, TOP, WIDE = 9, 6, 17


def part(first_row, rows):
    for row in rows:
        assert len(row) == WIDE, (row, len(row))
    return (first_row, rows)


def compose(*layers):
    """Layers are (part, down) pairs, drawn in order."""
    image = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
    for (first_row, rows), down in layers:
        for index, row in enumerate(rows):
            for x, code in enumerate(row):
                if code != ".":
                    image.putpixel((LEFT + x, TOP + first_row + index + down), rgba(code))
    return image


def swap(a_part, changes):
    """A copy of a part with some rows replaced: {row number: text}."""
    first_row, rows = a_part
    rows = list(rows)
    for number, text in changes.items():
        rows[number - first_row] = text
    return part(first_row, rows)


# --- Facing the camera -------------------------------------------------------------------------------------------

FRONT = part(0, [
    "......ooo........",
    ".....oiiho.......",
    ".....oijihoo.....",
    ".....ouihhuo.....",
    ".....otsssto.....",
    ".....otvsvto.....",
    "...ooosssttooo...",
    "..offwosttoWcdo..",
    ".offewWbBbWccddo.",
    ".ofeccenbndccddo.",
    ".oeecccaAadcccdo.",
    ".oeecccaAadccddo.",
    ".oeecccaaxdccddo.",
    ".oeeccckykdccddo.",
    ".oeecccpPmdccddo.",
    ".ostccepmpdcctuo.",
    ".ottccPpmpmdctuo.",
    ".oooecPpmpmdcooo.",
    "...oeePpmpmdco...",
    "...ooo.....ooo...",
])
# the arm on the viewer's left swings back (its hand rises), the other comes forward (its hand drops)
FRONT_ARMS_A = swap(FRONT, {
    14: ".ostcccpPmdccddo.",
    15: ".ottccepmpdccddo.",
    16: ".oooccPpmpmdctuo.",
    17: "...oecPpmpmdctuo.",
    18: "...oeePpmpmdcooo.",
})
FRONT_ARMS_C = swap(FRONT, {
    14: ".oeecccpPmdcctuo.",
    15: ".oeeccepmpdcctuo.",
    16: ".ostccPpmpmdcooo.",
    17: ".ottecPpmpmdco...",
    18: ".oooeePpmpmdco...",
})
FRONT_LEGS = part(19, [
    ".....oPpopmo.....",
    ".....oPpopmo.....",
    ".....oPpopmo.....",
    ".....oPpopmo.....",
    ".....oZzozzo.....",
    "....oZZzozzzo....",
    "....ooooooooo....",
])
FRONT_LEGS_A = part(19, [      # the leg on the viewer's left lands; the other trails, lifted and in shade
    ".....oPpopmo.....",
    ".....oPpopmo.....",
    ".....oPpommo.....",
    ".....oPpozzo.....",
    ".....oZzozzo.....",
    "....oZZzoooo.....",
    "....ooooo........",
])
FRONT_LEGS_C = part(19, [
    ".....oPpopmo.....",
    ".....oPpopmo.....",
    ".....oppopmo.....",
    ".....oZzopmo.....",
    ".....oZzozzo.....",
    ".....oooozzzo....",
    "........ooooo....",
])

# --- Facing away -------------------------------------------------------------------------------------------------

BACK = part(0, [
    "........ooo......",
    ".......oiiho.....",
    ".....ooijiho.....",
    ".....ohiihho.....",
    ".....ohhhhho.....",
    ".....othhhto.....",
    "...oooohhhoooo...",
    "..offewwwWWccdo..",
    ".offeecccccccddo.",
    ".ofeecccbccccddo.",
    ".oeecccbBbcccddo.",
    ".oeeccbcccbccddo.",
    ".oeecccccccccddo.",
    ".oeecccckccccddo.",
    ".oeeccccdccccddo.",
    ".ostccccdcccctuo.",
    ".ottecccdcccdtuo.",
    ".oooecccdcccdooo.",
    "...oeeccdcccdo...",
    "...ooo.....ooo...",
])
BACK_ARMS_A = swap(BACK, {
    14: ".ostccccdccccddo.",
    15: ".ottccccdccccddo.",
    16: ".oooecccdcccdtuo.",
    17: "...oecccdcccdtuo.",
    18: "...oeeccdcccdooo.",
})
BACK_ARMS_C = swap(BACK, {
    14: ".oeeccccdcccctuo.",
    15: ".oeeccccdcccctuo.",
    16: ".ostecccdcccdooo.",
    17: ".ottecccdcccdo...",
    18: ".oooeeccdcccdo...",
})
BACK_LEGS = part(19, [
    ".....oPpopmo.....",
    ".....oPpopmo.....",
    ".....oPpopmo.....",
    ".....oPpopmo.....",
    ".....oZzozzo.....",
    ".....oZzozzo.....",
    ".....ooooooo.....",
])
BACK_LEGS_A = part(19, [       # walking away: the leading leg is the far one, so it ends higher
    ".....oPpopmo.....",
    ".....oPpopmo.....",
    ".....oPpopmo.....",
    ".....oZzopmo.....",
    ".....oZzozzo.....",
    ".....oooozzo.....",
    "........oooo.....",
])
BACK_LEGS_C = part(19, [
    ".....oPpopmo.....",
    ".....oPpopmo.....",
    ".....oPpopmo.....",
    ".....oPpozzo.....",
    ".....oZzozzo.....",
    ".....oZzoooo.....",
    ".....oooo........",
])

# --- Facing right ------------------------------------------------------------------------------------------------

SIDE = part(0, [
    "........ooo......",
    "......oooiio.....",
    ".....ohhijiio....",
    ".....ohhhhso.....",
    ".....ohhtvso.....",
    ".....ohutssto....",
    "......outtto.....",
    ".....owwWbBo.....",
    "....odcfecbao....",
    "....oddeeccao....",
    "....oddeeccAo....",
    "....oddeeccao....",
    "....oddeeccao....",
    "....oddeeccko....",
    "....oddeeccpo....",
    "....odcstccpo....",
    "...oddctuccpo....",
    "...oddccccepo....",
    "...odcccccepo....",
    "...oooo...oo.....",
])
SIDE_ARM_BACK = swap(SIDE, {     # the near arm swings back
    11: "....odeedccao....",
    12: "....odeedccao....",
    13: "...oeedcdccko....",
    14: "...oeedcdccpo....",
    15: "..ostdcccccpo....",
    16: "..otudcccccpo....",
})
SIDE_ARM_FORWARD = swap(SIDE, {  # the near arm swings forward
    10: "....oddceecAo....",
    11: "....oddceecao....",
    12: "....oddcceeao....",
    13: "....oddcceeeo....",
    14: "....oddccceeo....",
    15: "....odccccpsto...",
    16: "...oddccccctuo...",
    17: "...oddcccceooo...",
})
SIDE_LEGS = part(19, [
    "......oPpmo......",
    "......oPpmo......",
    "......oPpmo......",
    "......oPpmo......",
    "......oZzzo......",
    "......oZzzzo.....",
    "......oooooo.....",
])
SIDE_LEGS_PASS = part(19, [      # one foot lifts past the standing leg
    "......oPpmo......",
    "......oPpmo......",
    "......oPpmo......",
    ".....ozPpmo......",
    ".....ozZzzo......",
    "......oZzzzo.....",
    "......oooooo.....",
])
SIDE_LEGS_NEAR = part(19, [      # the near leg lands ahead, the far one trails
    "......ommPpo.....",
    ".....ommoPpo.....",
    "....ommo.oPpo....",
    "...ozzo...oZzo...",
    "...ozzzo..oZzzo..",
    "...ooooo..ooooo..",
])
SIDE_LEGS_FAR = part(19, [       # the far leg lands ahead, the near one trails
    "......oPpmmo.....",
    ".....oPpommo.....",
    "....oPpo.ommo....",
    "...oZzo...ozzo...",
    "...oZzzo..ozzzo..",
    "...ooooo..ooooo..",
])


# --- At a console: the arms come forward and the hands take turns ------------------------------------------------

FRONT_TYPE = swap(FRONT, {
    15: "..oeecepmpdcddo..",
    16: "...ostPpmpmtuo...",
    17: "...ottPpmpmtuo...",
})
FRONT_TYPE_1 = swap(FRONT_TYPE, {
    15: "..oestepmpdcddo..",
    16: "...ottPpmpmtuo...",
    17: "...oecPpmpmtuo...",
})
FRONT_TYPE_2 = swap(FRONT_TYPE, {
    15: "..oeecepmpdtudo..",
    16: "...ostPpmpmtuo...",
    17: "...ottPpmpmdco...",
})
BACK_TYPE = swap(BACK, {
    14: "..ooccccdccccoo..",
    15: "...oecccdcccdo...",
    16: "...oecccdcccdo...",
    17: "...oecccdcccdo...",
})
BACK_TYPE_1 = swap(BACK_TYPE, {
    14: ".oeeccccdccccoo..",
    15: "..ooecccdcccdo...",
})
BACK_TYPE_2 = swap(BACK_TYPE, {
    14: "..ooccccdccccddo.",
    15: "...oecccdcccdoo..",
})
SIDE_TYPE = swap(SIDE, {
    11: "....oddeeecao....",
    12: "....oddceeeesto..",
    13: "....oddccccktuo..",
    14: "....oddccccpoo...",
    15: "....odcccccpo....",
    16: "...oddcccccpo....",
})
SIDE_TYPE_1 = swap(SIDE_TYPE, {
    11: "....oddeeeeesto..",
    12: "....oddccccatuo..",
    13: "....oddcccckoo...",
    14: "....oddccccpo....",
})


def type_down():
    legs = (FRONT_LEGS, 0)
    return [compose(legs, (FRONT_TYPE, 0)), compose(legs, (FRONT_TYPE_1, 0)),
            compose(legs, (FRONT_TYPE, 0)), compose(legs, (FRONT_TYPE_2, 0))]


def type_up():
    legs = (BACK_LEGS, 0)
    return [compose(legs, (BACK_TYPE, 0)), compose(legs, (BACK_TYPE_1, 0)),
            compose(legs, (BACK_TYPE, 0)), compose(legs, (BACK_TYPE_2, 0))]


def type_right():
    legs = (SIDE_LEGS, 0)
    return [compose(legs, (SIDE_TYPE, 0)), compose(legs, (SIDE_TYPE_1, 0)),
            compose(legs, (SIDE_TYPE, 0)), compose(legs, (SIDE_TYPE_1, 0))]


def walk_down():
    return [compose((FRONT_LEGS_A, 0), (FRONT_ARMS_A, 1)), compose((FRONT_LEGS, 0), (FRONT, 0)),
            compose((FRONT_LEGS_C, 0), (FRONT_ARMS_C, 1)), compose((FRONT_LEGS, 0), (FRONT, 0))]


def walk_up():
    return [compose((BACK_LEGS_A, 0), (BACK_ARMS_A, 1)), compose((BACK_LEGS, 0), (BACK, 0)),
            compose((BACK_LEGS_C, 0), (BACK_ARMS_C, 1)), compose((BACK_LEGS, 0), (BACK, 0))]


def walk_right():
    return [compose((SIDE_LEGS_NEAR, 1), (SIDE_ARM_BACK, 1)), compose((SIDE_LEGS_PASS, 0), (SIDE, 0)),
            compose((SIDE_LEGS_FAR, 1), (SIDE_ARM_FORWARD, 1)), compose((SIDE_LEGS_PASS, 0), (SIDE, 0))]


def stand():
    return [compose((FRONT_LEGS, 0), (FRONT, 0)), compose((SIDE_LEGS, 0), (SIDE, 0)),
            compose((BACK_LEGS, 0), (BACK, 0)), mirror(compose((SIDE_LEGS, 0), (SIDE, 0)))]
