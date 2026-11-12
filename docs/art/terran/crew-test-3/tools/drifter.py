"""The Terran drifter, drawn a pixel at a time: a 35 by 35 crew sprite seen from about 45 degrees above.

Each part is rows of text, one character a pixel (the colours are in pix.py), on a grid 17 wide and 23 tall whose
corner sits at (9, 9) in the frame, so the boots stand on the same line as the Mecha's. A frame is parts laid over
each other; a walking frame moves the upper body a pixel down when a foot lands.
"""
import sys
sys.path.insert(0, "tools")
from pix import *

LEFT, TOP, WIDE = 9, 9, 17


def part(first_row, rows, wide=WIDE):
    """Rows are 17 wide; a few (a spray, the fallen body, the portrait) are wider and say so."""
    for row in rows:
        assert len(row) in (WIDE, wide), (row, len(row))
    return (first_row, rows)


def compose(*layers):
    """Layers are (part, down) or (part, down, across) and are drawn in order."""
    image = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
    for layer in layers:
        (first_row, rows), down = layer[0], layer[1]
        across = layer[2] if len(layer) > 2 else 0
        for index, row in enumerate(rows):
            for x, code in enumerate(row):
                if code != ".":
                    image.putpixel((LEFT + x + across, TOP + first_row + index + down), rgba(code))
    return image


def swap(a_part, changes, wide=WIDE):
    """A copy of a part with some rows replaced: {row number: text}."""
    first_row, rows = a_part
    rows = list(rows)
    for number, text in changes.items():
        rows[number - first_row] = text
    return part(first_row, rows, wide)


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
    ".....oZzozzo.....",
    ".....ooooooo.....",
])
FRONT_LEGS_A = part(17, [      # the leg on the viewer's left lands; the other trails, lifted and in shade
    ".....oPpopmo.....",
    ".....oPpommo.....",
    ".....oPpozzo.....",
    ".....oZzozzo.....",
    ".....oZzoooo.....",
    ".....oooo........",
])
FRONT_LEGS_C = part(17, [
    ".....oPpopmo.....",
    ".....oppopmo.....",
    ".....oZzopmo.....",
    ".....oZzozzo.....",
    ".....oooozzo.....",
    "........oooo.....",
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
    "....odctuccpo....",
    "....odccccepo....",
    ".....oo...oo.....",
])
SIDE_ARM_BACK = swap(SIDE, {     # the near arm swings back
    10: "....odeedccao....",
    11: "....odeedccao....",
    12: "...oeedcdccko....",
    13: "...oeedcdccpo....",
    14: "..ostdcccccpo....",
    15: "..otudcccccpo....",
    16: "...oodccccepo....",
})
SIDE_ARM_FORWARD = swap(SIDE, {     # the near arm swings forward
    9: "....oddceecAo....",
    10: "....oddceecao....",
    11: "....oddcceeao....",
    12: "....oddcceeeo....",
    13: "....oddccceeo....",
    14: "....odccccpsto...",
    15: "....odccccctuo...",
    16: "....odcccceooo...",
})
SIDE_LEGS = part(17, [
    "......oPpmo......",
    "......oPpmo......",
    "......oPpmo......",
    "......oZzzo......",
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

FRONT_TYPE = swap(FRONT, {       # both hands up in front of the chest, as over a console
    11: ".oeecstaaxtucddo.",
    12: ".oeecttkyktucddo.",
    13: "..oocccpPmdccoo..",
    14: "...occepmpdcco...",
    15: "...occPpmpmdco...",
    16: "...oecPpmpmdco...",
})
FRONT_TYPE_1 = swap(FRONT_TYPE, {     # and they take turns, a pixel up and back
    10: ".oeecstaAadcccdo.",
    11: ".oeecttaaxtucddo.",
    12: ".oeeccckyktucddo.",
})
FRONT_TYPE_2 = swap(FRONT_TYPE, {
    10: ".oeecccaAatuccdo.",
    11: ".oeecstaaxtucddo.",
    12: ".oeecttkykdccddo.",
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
SIDE_TYPE = swap(SIDE, {       # both hands out at chest height: the near one up, the far one showing past it
    9: "....oddeeccAooo..",
    10: "....oddeeeeesto..",
    11: "....oddccccatuto.",
    12: "....oddcccckooo..",
    13: "....oddccccpo....",
    14: "....odcccccpo....",
    15: "....odcccccpo....",
})
SIDE_TYPE_1 = swap(SIDE_TYPE, {    # and they change places
    8: "....odcfecbaooo..",
    9: "....oddeeccAsto..",
    10: "....oddeeeeetuo..",
    11: "....oddccccaooto.",
    12: "....oddccccko.o..",
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
    return [compose((SIDE_LEGS_NEAR, 1), (SIDE_ARM_BACK, 1)), compose((SIDE_LEGS, 0), (SIDE, 0)),
            compose((SIDE_LEGS_FAR, 1), (SIDE_ARM_FORWARD, 1)), compose((SIDE_LEGS, 0), (SIDE, 0))]


def stand():
    return [compose((FRONT_LEGS, 0), (FRONT, 0)), compose((SIDE_LEGS, 0), (SIDE, 0)),
            compose((BACK_LEGS, 0), (BACK, 0)), mirror(compose((SIDE_LEGS, 0), (SIDE, 0)))]


# --- Shooting, fire and fists: one arm acts, the rest of him stands as he stands ------------------------------------
# The arm that acts is his right: on the viewer's left when he faces the camera, on the viewer's right from behind.

FRONT_ARM_OUT = swap(FRONT, {     # facing the camera: that fist raised a little and a pixel out, ready to hold something
    11: "oeeocccaaxdccddo.",
    12: "ostoccckykdccddo.",
    13: "ottocccpPmdccddo.",
    14: ".oooccepmpdcctuo.",
    15: "...occPpmpmdctuo.",
    16: "...oecPpmpmdcooo.",
})
BACK_ARM_UP = swap(BACK, {        # facing away: that fist up beside his head
    5: ".....othhhto.otuo",
    6: "...oooohhhooootuo",
    7: "..offewwwWWccddo.",
    9: ".ofeecccbccccoo..",
    10: ".oeecccbBbccco...",
    11: ".oeeccbcccbcco...",
    12: ".oeeccccccccco...",
    13: ".oeeccccccccco...",
    14: ".ostccccccccco...",
    15: ".ottecccccccdo...",
    16: ".oooecccccccdo...",
})
# What the fist holds is drawn two pixels left of the grid facing the camera, two right of it from behind.
HELD = -2
HELD_UP = 2

# A pistol: aimed straight, a little to his right, a little to his left. As on the genre's sheet, these three
# frames are three aims, not an animation, and there is no flash: the shot itself is the crew laser shot.
PISTOL_DOWN = part(14, ["..oGko...........", "..oGko...........", "..oGko...........", "..oGko...........",
                        "...oo............"])
PISTOL_DOWN_RIGHT = part(14, ["..oGko...........", ".oGko............", ".oGko............", "oGko.............",
                              ".oo.............."])
PISTOL_DOWN_LEFT = part(14, ["..oGko...........", "...oGko..........", "...oGko..........", "....oGko.........",
                             ".....oo.........."])
PISTOL_UP = part(0, ["............oo...", "...........oGko..", "...........oGko..", "...........oGko..",
                     "...........oGko.."])
PISTOL_UP_RIGHT = part(0, ["..............oo.", ".............oGko", "............oGko.", "............oGko.",
                           "...........oGko.."])
PISTOL_UP_LEFT = part(0, ["..........oo.....", ".........oGko....", "..........oGko...", "..........oGko...",
                          "...........oGko.."])
SIDE_AIM = swap(SIDE, {
    7: ".....owwWbBo.ooooo....",
    8: "....odcfecbaoGGGGko...",
    9: "....oddeeeeestkkoo....",
    10: "....oddccccatuoo......",
    11: "....oddccccaoo...",
    12: "....oddccccko....",
    13: "....oddccccpo....",
    14: "....odcccccpo....",
    15: "....odcccccpo....",
}, 22)
SIDE_AIM_LOW = swap(SIDE_AIM, {   # a little toward the camera: the arm a pixel lower
    7: ".....owwWbBo.....",
    8: "....odcfecbaoooooo....",
    9: "....oddeeccAoGGGGko...",
    10: "....oddeeeeestkkoo....",
    11: "....oddccccatuoo......",
    12: "....oddcccckoo...",
}, 22)
SIDE_AIM_HIGH = swap(SIDE_AIM, {  # a little away from it: the arm a pixel higher
    6: "......outtto.ooooo....",
    7: ".....owwWbBooGGGGko...",
    8: "....odcfeeeestkkoo....",
    9: "....oddccccAtuoo......",
    10: "....oddccccaoo...",
    11: "....oddccccao....",
}, 22)


def shoot_down():
    body = ((FRONT_LEGS, 0), (FRONT_ARM_OUT, 0))
    return [compose(*body, (pistol, 0, HELD)) for pistol in (PISTOL_DOWN, PISTOL_DOWN_RIGHT, PISTOL_DOWN_LEFT)]


def shoot_right():
    legs = (SIDE_LEGS, 0)
    return [compose(legs, (SIDE_AIM, 0)), compose(legs, (SIDE_AIM_LOW, 0)), compose(legs, (SIDE_AIM_HIGH, 0))]


def shoot_up():
    body = ((BACK_LEGS, 0), (BACK_ARM_UP, 0))
    return [compose(*body, (pistol, 0, HELD_UP)) for pistol in (PISTOL_UP, PISTOL_UP_RIGHT, PISTOL_UP_LEFT)]


# --- Fighting a fire: a red extinguisher in the same fist, aimed where the pistol was ---------------------------------
# No spray is drawn: the game makes every particle (heromedel, 2026-11-12), so the four frames of a direction are
# one drawing.

CANISTER_DOWN = part(14, ["..o45o...........", "..o45o...........", "..o45o...........", "..o45o...........",
                          "..okko..........."])
CANISTER_UP = part(0, ["...........okko..", "...........o45o..", "...........o45o..", "...........o45o..",
                       "...........o45o.."])
SIDE_EXTINGUISHER = swap(SIDE, {
    9: "....oddeeccAoooooooo......",
    10: "....oddeeeeeest4444ko.....",
    11: "....oddccccaotu5555ko.....",
    12: "....oddcccckoooooooo......",
    13: "....oddccccpo....",
    14: "....odcccccpo....",
    15: "....odcccccpo....",
}, 26)


def fire_down():
    return [compose((FRONT_LEGS, 0), (FRONT_ARM_OUT, 0), (CANISTER_DOWN, 0, HELD))] * 4


def fire_right():
    return [compose((SIDE_LEGS, 0), (SIDE_EXTINGUISHER, 0))] * 4


def fire_up():
    return [compose((BACK_LEGS, 0), (BACK_ARM_UP, 0), (CANISTER_UP, 0, HELD_UP))] * 4



# --- A fist fight: one fist draws back to the shoulder and comes straight out; the other arm hangs ------------------

FRONT_WINDUP = swap(FRONT, {      # the fist on the viewer's left pulls back to the shoulder
    8: ".ostewWbBbWccddo.",
    9: ".ottccenbndccddo.",
    13: "..oocccpPmdccddo.",
    14: "...occepmpdcctuo.",
    15: "...occPpmpmdctuo.",
    16: "...oecPpmpmdcooo.",
})
FRONT_PUNCH = swap(FRONT, {       # and comes straight at the camera, so it shows large and low
    12: ".oeeeeckykdccddo.",
    13: "..oosstpPmdccddo.",
    14: "...osttpmpdcctuo.",
    15: "...ottupmpmdctuo.",
    16: "...oecPpmpmdcooo.",
})
BACK_WINDUP = swap(BACK, {        # facing away, the arm on the viewer's left bends, its elbow out
    13: ".oeecccccccccddo.",
    14: "..ooccccccccctuo.",
    15: "...oecccccccdtuo.",
    16: "...oecccccccdooo.",
})
BACK_PUNCH = swap(BACK, {         # and the fist goes out past his head
    4: "..oo.ohhhhho.....",
    5: ".ostoothhhto.....",
    6: ".ottooohhhoooo...",
    7: ".offfewwwWWccdo..",
    9: "..ooecccbccccddo.",
    10: "...occcbBbcccddo.",
    11: "...occbcccbccddo.",
    12: "...occcccccccddo.",
    13: "...occcccccccddo.",
    14: "...occccccccctuo.",
    15: "...oecccccccdtuo.",
    16: "...oecccccccdooo.",
})


def punch_down():
    legs = (FRONT_LEGS, 0)
    stand, windup = compose(legs, (FRONT, 0)), compose(legs, (FRONT_WINDUP, 0))
    return [stand, windup, compose(legs, (FRONT_PUNCH, 1)), windup, stand, stand]


def punch_up():
    legs = (BACK_LEGS, 0)
    stand, windup = compose(legs, (BACK, 0)), compose(legs, (BACK_WINDUP, 0))
    return [stand, windup, compose(legs, (BACK_PUNCH, 0)), windup, stand, stand]


# --- Repairs: down on one knee, he swings a hammer onto the deck ---------------------------------------------------

SIDE_KNEEL_LEGS = part(19, [    # the front foot under its knee, the back shin along the deck
    "......oPPpo......",
    "......oPpPPPPo...",
    "...oZZppoooZzzo..",
    "...oooooooooooo..",
])
SIDE_HAMMER_UP = swap(SIDE, {   # the hammer raised in front of his face
    1: "......oooiio.ooooo....",
    2: ".....ohhijiiooGGGo....",
    3: ".....ohhhhso.okkko....",
    4: ".....ohhtvso..oGo.....",
    5: ".....ohutsstoosto.....",
    6: "......outtto..otuo....",
    7: ".....owwWbBoeeoo......",
    8: "....odcfecbeeo...",
    9: "....oddccccAo....",
    10: "....oddccccao....",
    11: "....oddccccao....",
    12: "....oddccccko....",
    13: "....oddccccpo....",
    14: "....odcccccpo....",
    15: "....odcccccpo....",
}, 22)
HAMMER_DOWN = part(15, [        # and brought down in front of him
    ".............G.ooo....",
    "..............GGGGo...",
    "..............okkko...",
    "...............ooo....",
], 22)


def repair():
    """No sparks are drawn where the hammer lands: the game makes them (heromedel, 2026-11-12)."""
    legs = (SIDE_KNEEL_LEGS, 0)
    up = compose(legs, (SIDE_HAMMER_UP, 2))
    down = compose(legs, (SIDE_ARM_FORWARD, 2), (HAMMER_DOWN, 2))
    return [up, down, up, down]


# --- Dying: he reels, his knees go, he topples to his left and lands sprawled on his back --------------------------

KNEEL_LEGS = part(20, [
    ".....oPpopmo.....",
    "...ozzPpopmzzo...",
    "...ooooooooooo...",
])
# On the floor, head to the left, seen from above like everything else: one arm thrown up past his head, the other
# down past it, legs apart. Thirteen rows tall, 25 long.
FALLEN = part(11, [
    "....oooo.................",
    "...ostfeo................",
    ".....ooefeoooooooo.......",
    "..oooooofeeeeeeeeo.ooooo.",
    ".ohihtstWecccccccooPPZzo.",
    "oihjhsvsbaakPPPPPPPoooo..",
    "ohihsstBbAayPmmmmmmo.....",
    ".ohhhsvtbaxkpppppppoooo..",
    ".ohhhutuWcccccccdooppzzo.",
    "..oooooocddddddddo.ooooo.",
    ".....oocdcoooooooo.......",
    "...otucdo................",
    "....oooo.................",
], 25)


def leaning(image, top):
    """The frame with each row slid left, the higher the further: `top` pixels at the top of his head, none at his
    feet. Rows move whole, so no pixel is changed."""
    out = Image.new("RGBA", image.size, (0, 0, 0, 0))
    for y in range(FRAME):
        shift = round(top * max(0, 31 - y) / 22)
        for x in range(FRAME):
            if image.getpixel((x, y))[3] and x - shift >= 0:
                out.putpixel((x - shift, y), image.getpixel((x, y)))
    return out


def head_up(image, lifts):
    """The fallen body with its head end still off the floor: columns left of each mark are lifted a pixel more."""
    out = Image.new("RGBA", image.size, (0, 0, 0, 0))
    for x in range(FRAME):
        lift = sum(1 for mark in lifts if x < mark)
        for y in range(FRAME):
            if image.getpixel((x, y))[3] and y - lift >= 0:
                out.putpixel((x, y - lift), image.getpixel((x, y)))
    return out


def death():
    stand = compose((FRONT_LEGS, 0), (FRONT, 0))
    reel = leaning(stand, 2)
    knees = leaning(compose((KNEEL_LEGS, 0), (FRONT, 3)), 5)
    topple = leaning(compose((KNEEL_LEGS, 0), (FRONT, 4)), 9)
    down = compose((FALLEN, 0, -4))
    return [stand, reel, knees, topple, head_up(down, (9, 13, 17, 21)), head_up(down, (11,)), down, down]


# --- Teleporting, as on the other sheets: strings of his own pixels are pulled up into the sky ------------------------

# How far each column is pulled, as a share of the frame's pull, across the figure from its left edge.
PULLS = (0.5, 0.1, 1.0, 0.3, 0.0, 0.7, 0.2, 0.9, 0.0, 0.4, 1.0, 0.2, 0.6, 0.0, 0.8, 0.3, 1.0)


def teleport():
    """Eight frames: each column of him is dragged upward from the feet, a little at first, flickering, then a
    long way. The whole column moves, so his face, bandana and belt slide up by different amounts from one column
    to the next, and the top of the column draws out into a string."""
    stand = compose((FRONT_LEGS, 0), (FRONT, 0))
    frames = []
    for pull in (0, 1, 2, 3, 5, 8, 12, 16):
        image = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
        for x in range(FRAME):
            column = [stand.getpixel((x, y)) for y in range(FRAME) if stand.getpixel((x, y))[3]]
            if not column:
                continue
            bottom = max(y for y in range(FRAME) if stand.getpixel((x, y))[3])
            amount = round(pull * PULLS[(x - LEFT) % len(PULLS)])
            high, tall = len(column), len(column) + amount
            bend = (tall - 1) / max(1, high - 1)          # stretched most at the top, not at all at the feet
            for step in range(tall):
                source = round((high - 1) * (step / max(1, tall - 1)) ** bend)
                y = bottom - (tall - 1) + step
                if y >= 0:
                    image.putpixel((x, y), column[source])
        frames.append(image)
    return frames


# --- The alternative teleport heromedel asked to keep: he turns to light, and the light breaks up and rises --------

def teleport_light():
    """Eight frames made from the standing frame's own shape: lit, then all light, then thinning bands of it."""
    stand = compose((FRONT_LEGS, 0), (FRONT, 0))
    shape = [(x, y) for y in range(FRAME) for x in range(FRAME) if stand.getpixel((x, y))[3]]
    edge = [p for p in shape if stand.getpixel(p) == rgba("o")]
    inside = [p for p in shape if p not in edge]

    def picture(pixels):
        image = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
        for (x, y), code in pixels:
            if 0 <= x < FRAME and 0 <= y < FRAME:
                image.putpixel((x, y), rgba(code))
        return image

    lit = stand.copy()                       # 2: his outline lights up
    for p in edge:
        lit.putpixel(p, rgba("M"))
    glow = picture([(p, "M") for p in edge] + [(p, "L") for p in inside])                  # 3: all light
    bands = picture([(p, "L" if p in inside else "M") for p in shape if p[1] % 2 == 0])    # 4: every other row
    columns = picture([((x, y - 1), "L") for (x, y) in shape if x % 2 == 0 and y % 2 == 0]
                      + [((x, y - 2), "M") for (x, y) in shape if x % 2 == 0 and y % 4 == 0])
    rising = picture([((x, y - 3), "L") for (x, y) in shape if x % 4 == 1 and y % 2 == 0]
                     + [((x, y - 5), "M") for (x, y) in shape if x % 4 == 1 and y % 4 == 0])
    sparks = picture([((x, y - 6), "L") for (x, y) in shape if x % 4 == 1 and y % 6 == 0]
                     + [((x, y - 8), "6") for (x, y) in shape if x % 8 == 1 and y % 6 == 0])
    last = picture([((x, y - 9), "6") for (x, y) in shape if x % 8 == 5 and y % 8 == 0])
    return [stand, lit, glow, bands, columns, rising, sparks, last]


# --- The clone bay: a plate lowers and he stands there -------------------------------------------------------------

def clone():
    stand = compose((FRONT_LEGS, 0), (FRONT, 0))
    frames = []
    for top in (7, 12, 17, 22, 26, 29):
        image = stand.copy()
        for y in range(top, 32):
            for x in range(5, 30):
                if x in (5, 29) or y in (top, 31):
                    code = "o"
                elif y == top + 1 or x == 6:
                    code = "Y"
                elif x == 28 or y == 30:
                    code = "V"
                else:
                    code = "X"
                image.putpixel((x, y), rgba(code))
        frames.append(image)
    return frames


# --- The portrait and the crew laser shot ---------------------------------------------------------------------------

PORTRAIT = part(-1, [
    ".......oooooo..........",
    ".....ooiiijihoo........",
    "....oiijjiiihhho.......",
    "....ohiijiihhhhho......",
    "....ouhhiihhhhhuo......",
    "....outssssssstuo......",
    "....otsvvvssvvvto......",
    "....otssostssotuo......",
    "....otsssstssstuo......",
    "....otssstttsstuo......",
    ".....otssssssstuo......",
    ".....outsuuustuo.......",
    "......outtttttuo.......",
    "...ooowwouttuoWWooo....",
    "..offewwwbbBbbWWWcdo...",
    ".offeecwwnbBbnWWccddo..",
    ".ofeeecccenbndcccdddo..",
    ".oeeeeccceaAadcccdddo..",
    ".oeeeeccceaAadcccdddo..",
    ".oooooooooooooooooooo..",
], 23)


def portrait():
    return compose((PORTRAIT, 0, -3))


def laser_shot():
    """The crew's pistol shot: a white core in power green (GATOS ships use power green: palette.md)."""
    image = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
    green = (0x66, 0xff, 0x66)
    for y in range(8, 27):
        for x in range(14, 25):
            across, along = abs(x - 19), max(0, abs(y - 17) - 6)
            reach = across + along
            if across <= 1 and abs(y - 17) <= 7:
                image.putpixel((x, y), (0xf2, 0xff, 0xf2, 255))
            elif reach <= 2:
                image.putpixel((x, y), green + (255,))
            elif reach <= 3:
                image.putpixel((x, y), green + (150,))
            elif reach <= 4:
                image.putpixel((x, y), green + (70,))
    return image
