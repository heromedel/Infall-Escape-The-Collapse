"""The Terran drifter, drawn a pixel at a time: a 35 by 35 crew sprite seen from about 45 degrees above.

Each part is rows of text, one character a pixel (the colours are in pix.py), on a grid 17 wide and 23 tall whose
corner sits at (9, 9) in the frame, so the boots stand on the same line as the Mecha's. A frame is parts laid over
each other; a walking frame moves the upper body a pixel down when a foot lands.
"""
import sys
sys.path.insert(0, "tools")
from pix import *

LEFT, TOP, WIDE = 9, 9, 17


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
    ".oeecccaaxdccddo.",
    ".oeeccckykdccddo.",
    ".oeecccpPmdccddo.",
    ".ostccepmpdcctuo.",
    ".ottccPpmpmdctuo.",
    ".oooecPpmpmdcooo.",
    "...ooo.....ooo...",
])
# the arm on the viewer's left swings back (its hand rises), the other comes forward (its hand drops)
FRONT_ARMS_A = swap(FRONT, {
    13: ".ostcccpPmdccddo.",
    14: ".ottccepmpdccddo.",
    15: ".oooccPpmpmdctuo.",
    16: "...oecPpmpmdctuo.",
    17: "...ooo.....ooooo.",
})
FRONT_ARMS_C = swap(FRONT, {
    13: ".oeecccpPmdcctuo.",
    14: ".oeeccepmpdcctuo.",
    15: ".ostccPpmpmdcooo.",
    16: ".ottecPpmpmdco...",
    17: ".ooooo.....ooo...",
})
FRONT_LEGS = part(17, [
    ".....oPpopmo.....",
    ".....oPpopmo.....",
    ".....oPpopmo.....",
    ".....oZzozzo.....",
    "....oZZzozzzo....",
    "....ooooooooo....",
])
FRONT_LEGS_A = part(17, [      # the leg on the viewer's left lands; the other trails, lifted and in shade
    ".....oPpopmo.....",
    ".....oPpommo.....",
    ".....oPpozzo.....",
    ".....oZzozzo.....",
    "....oZZzoooo.....",
    "....ooooo........",
])
FRONT_LEGS_C = part(17, [
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
    ".oeecccccccccddo.",
    ".ostccccccccctuo.",
    ".ottecccccccdtuo.",
    ".oooecccccccdooo.",
    "...ooo.....ooo...",
])
BACK_ARMS_A = swap(BACK, {
    13: ".ostcccccccccddo.",
    14: ".ottcccccccccddo.",
    15: ".oooecccccccdtuo.",
    16: "...oecccccccdtuo.",
    17: "...ooo.....ooooo.",
})
BACK_ARMS_C = swap(BACK, {
    13: ".oeeccccccccctuo.",
    14: ".oeeccccccccctuo.",
    15: ".ostecccccccdooo.",
    16: ".ottecccccccdo...",
    17: ".ooooo.....ooo...",
})
BACK_LEGS = part(17, [
    ".....oPpopmo.....",
    ".....oPpopmo.....",
    ".....oPpopmo.....",
    ".....oZzozzo.....",
    ".....oZzozzo.....",
    ".....ooooooo.....",
])
BACK_LEGS_A = part(17, [      # walking away: the leading leg is the far one, so it ends higher
    ".....oPpopmo.....",
    ".....oPpopmo.....",
    ".....oZzopmo.....",
    ".....oZzozzo.....",
    ".....oooozzo.....",
    "........oooo.....",
])
BACK_LEGS_C = part(17, [
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
    "....oddeeccAo....",
    "....oddeeccao....",
    "....oddeeccao....",
    "....oddeeccko....",
    "....oddeeccpo....",
    "....odcstccpo....",
    "...oddctuccpo....",
    "...oddccccepo....",
    "...oooo...ooo....",
])
SIDE_ARM_BACK = swap(SIDE, {     # the near arm swings back
    10: "....odeedccao....",
    11: "....odeedccao....",
    12: "...oeedcdccko....",
    13: "...oeedcdccpo....",
    14: "..ostdcccccpo....",
    15: "..otudcccccpo....",
})
SIDE_ARM_FORWARD = swap(SIDE, {     # the near arm swings forward
    9: "....oddceecAo....",
    10: "....oddceecao....",
    11: "....oddcceeao....",
    12: "....oddcceeeo....",
    13: "....oddccceeo....",
    14: "....odccccpsto...",
    15: "...oddccccctuo...",
    16: "...oddcccceooo...",
})
SIDE_LEGS = part(17, [
    "......oPpmo......",
    "......oPpmo......",
    "......oPpmo......",
    "......oZzzo......",
    "......oZzzzo.....",
    "......oooooo.....",
])
SIDE_LEGS_PASS = part(17, [      # one foot lifts past the standing leg
    "......oPpmo......",
    "......oPpmo......",
    ".....ozPpmo......",
    ".....ozZzzo......",
    "......oZzzzo.....",
    "......oooooo.....",
])
SIDE_LEGS_NEAR = part(17, [      # the near leg lands ahead, the far one trails
    ".....ommoPpo.....",
    "....ommo.oPpo....",
    "...ozzo...oZzo...",
    "...ozzzo..oZzzo..",
    "...ooooo..ooooo..",
])
SIDE_LEGS_FAR = part(17, [      # the far leg lands ahead, the near one trails
    ".....oPpommo.....",
    "....oPpo.ommo....",
    "...oZzo...ozzo...",
    "...oZzzo..ozzzo..",
    "...ooooo..ooooo..",
])


# --- At a console: the arms come forward and the hands take turns ------------------------------------------------

FRONT_TYPE = swap(FRONT, {
    14: "..oeecepmpdcddo..",
    15: "...ostPpmpmtuo...",
    16: "...ottPpmpmtuo...",
})
FRONT_TYPE_1 = swap(FRONT_TYPE, {
    14: "..oestepmpdcddo..",
    15: "...ottPpmpmtuo...",
    16: "...oecPpmpmtuo...",
})
FRONT_TYPE_2 = swap(FRONT_TYPE, {
    14: "..oeecepmpdtudo..",
    16: "...ottPpmpmdco...",
})
BACK_TYPE = swap(BACK, {
    13: "..oocccccccccoo..",
    14: "...oecccccccdo...",
    15: "...oecccccccdo...",
    16: "...oecccccccdo...",
})
BACK_TYPE_1 = swap(BACK_TYPE, {
    13: ".oeecccccccccoo..",
    14: "..ooecccccccdo...",
})
BACK_TYPE_2 = swap(BACK_TYPE, {
    13: "..oocccccccccddo.",
    14: "...oecccccccdoo..",
})
SIDE_TYPE = swap(SIDE, {
    10: "....oddeeecao....",
    11: "....oddceeeesto..",
    12: "....oddccccktuo..",
    13: "....oddccccpoo...",
    14: "....odcccccpo....",
    15: "...oddcccccpo....",
})
SIDE_TYPE_1 = swap(SIDE_TYPE, {
    10: "....oddeeeeesto..",
    11: "....oddccccatuo..",
    12: "....oddcccckoo...",
    13: "....oddccccpo....",
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
