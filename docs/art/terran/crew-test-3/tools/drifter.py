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
    15: "....odcccccpo....",
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
    return [compose((SIDE_LEGS_NEAR, 1), (SIDE_ARM_BACK, 1)), compose((SIDE_LEGS, 0), (SIDE, 0)),
            compose((SIDE_LEGS_FAR, 1), (SIDE_ARM_FORWARD, 1)), compose((SIDE_LEGS, 0), (SIDE, 0))]


def stand():
    return [compose((FRONT_LEGS, 0), (FRONT, 0)), compose((SIDE_LEGS, 0), (SIDE, 0)),
            compose((BACK_LEGS, 0), (BACK, 0)), mirror(compose((SIDE_LEGS, 0), (SIDE, 0)))]


# --- Shooting: a pistol comes up, fires, and comes down ----------------------------------------------------------

SIDE_AIM = swap(SIDE, {
    8: "....odcfecbaoo...",
    9: "....oddeeeeestoo.",
    10: "....oddccccatuo..",
    11: "....oddccccaoo...",
    12: "....oddccccko....",
    13: "....oddccccpo....",
    14: "....odcccccpo....",
    15: "....odcccccpo....",
})
SIDE_FIRE = swap(SIDE_AIM, {
    8: "....odcfecbaoo.F.",
    9: "....oddeeeeestooF",
    10: "....oddccccatuoF.",
})
SIDE_LOWER = swap(SIDE_ARM_FORWARD, {
    15: "....odccccctuoo..",
})
FRONT_AIM = swap(FRONT, {
    14: "..oeeeestddddo...",
    15: "...occPtupmdco...",
    16: "...oecPoopmdco...",
})
FRONT_FIRE = swap(FRONT_AIM, {
    17: "...ooo.FF..ooo...",
})
BACK_AIM = swap(BACK, {      # the pistol goes up beside the head, pointing away
    3: ".....ohiihho.o...",
    4: ".....ohhhhho.oo..",
    5: ".....othhhtootuo.",
    6: "...oooohhhoootuo.",
    7: "..offewwwWWccddo.",
    9: ".ofeecccbccccoo..",
    10: ".oeecccbBbccco...",
    11: ".oeeccbcccbcco...",
    12: ".oeeccccccccco...",
    13: "..ooccccccccco...",
    14: "...oecccccccdo...",
    15: "...oecccccccdo...",
    16: "...oecccccccdo...",
})
BACK_FIRE = swap(BACK_AIM, {
    1: ".......oiiho.F...",
    2: ".....ooijiho.F...",
})


def shoot_down():
    legs = (FRONT_LEGS, 0)
    return [compose(legs, (FRONT_AIM, 0)), compose(legs, (FRONT_FIRE, 0)), compose(legs, (FRONT_TYPE, 0))]


def shoot_right():
    legs = (SIDE_LEGS, 0)
    return [compose(legs, (SIDE_AIM, 0)), compose(legs, (SIDE_FIRE, 0)), compose(legs, (SIDE_LOWER, 0))]


def shoot_up():
    legs = (BACK_LEGS, 0)
    return [compose(legs, (BACK_AIM, 0)), compose(legs, (BACK_FIRE, 0)), compose(legs, (BACK_TYPE, 0))]


# --- Fighting a fire: an extinguisher, and its spray ---------------------------------------------------------------

SIDE_SPRAY = swap(SIDE, {
    8: "....odcfecbaooo..",
    9: "....oddeeccAo45o.6....",
    10: "....oddeeeest45o6.6...",
    11: "....oddcccctu45o.",
    12: "....oddcccckooo..",
    13: "....oddccccpo....",
    14: "....odcccccpo....",
    15: "....odcccccpo....",
}, 22)
SIDE_SPRAY_1 = swap(SIDE_SPRAY, {
    9: "....oddeeccAo45o6.6...",
    10: "....oddeeeest45o.6.6..",
}, 22)
FRONT_SPRAY = swap(FRONT, {
    14: "..oeece445dcddo..",
    15: "...ocst445tuco...",
    16: "...oett455tudo...",
    17: "...ooo.666.ooo...",
})
FRONT_SPRAY_1 = swap(FRONT_SPRAY, {
    17: "...ooo6.6.6ooo...",
})
BACK_SPRAY = swap(BACK_TYPE, {     # from behind only the canister shows, held at the hip
    13: "..ooccccccccc45o.",
    14: "...oecccccccd45o.",
    15: "...oecccccccdooo.",
})
BACK_SPRAY_1 = swap(BACK_SPRAY, {
    13: ".oeeccccccccc45o.",
    14: "..ooecccccccd45o.",
})


def fire_down():
    legs = (FRONT_LEGS, 0)
    return [compose(legs, (FRONT_SPRAY, 0)), compose(legs, (FRONT_SPRAY_1, 0))] * 2


def fire_right():
    legs = (SIDE_LEGS, 0)
    return [compose(legs, (SIDE_SPRAY, 0)), compose(legs, (SIDE_SPRAY_1, 0))] * 2


def fire_up():
    legs = (BACK_LEGS, 0)
    return [compose(legs, (BACK_SPRAY, 0)), compose(legs, (BACK_SPRAY_1, 0))] * 2


# --- A fist fight ------------------------------------------------------------------------------------------------

FRONT_GUARD = swap(FRONT, {
    10: ".oeestcaAadtucdo.",
    11: ".oeettcaaxdtuddo.",
    13: "..oocccpPmdccoo..",
    14: "...occepmpdcco...",
    15: "...occPpmpmdco...",
    16: "...oecPpmpmdco...",
})
FRONT_WINDUP = swap(FRONT_GUARD, {    # the fist on the viewer's left pulls back to the shoulder
    8: ".ostewWbBbWccddo.",
    9: ".ottccenbndccddo.",
    10: ".oeecccaAadtucdo.",
    11: ".oeecccaaxdtuddo.",
})
FRONT_PUNCH = swap(FRONT_GUARD, {     # and comes straight at the camera
    10: ".oeecccaAadtucdo.",
    11: ".oeecccaaxdtuddo.",
    12: ".oeeeeckykdccddo.",
    13: "..oosstpPmdccoo..",
    14: "...osttpmpdcco...",
    15: "...ottupmpmdco...",
})
BACK_WINDUP = swap(BACK_TYPE, {       # the arm on the viewer's left draws back, its fist at the hip
    13: ".oeecccccccccoo..",
    14: ".ostecccccccdo...",
    15: ".ottecccccccdo...",
    16: ".oooecccccccdo...",
})
BACK_PUNCH = swap(BACK_TYPE, {        # and is thrown forward: the fist shows above the shoulder
    4: "..oo.ohhhhho.....",
    5: ".ostoothhhto.....",
    6: ".ottooohhhoooo...",
    7: ".offfewwwWWccdo..",
    9: "..ooecccbccccddo.",
    10: "...occcbBbcccddo.",
    11: "...occbcccbccddo.",
    12: "...occcccccccddo.",
    13: "...occcccccccoo..",
})


def punch_down():
    legs = (FRONT_LEGS, 0)
    return [compose(legs, (FRONT_GUARD, 0)), compose(legs, (FRONT_WINDUP, 0)), compose(legs, (FRONT_PUNCH, 1)),
            compose(legs, (FRONT_PUNCH, 1)), compose(legs, (FRONT_GUARD, 0)), compose(legs, (FRONT, 0))]


def punch_up():
    legs = (BACK_LEGS, 0)
    return [compose(legs, (BACK_TYPE, 0)), compose(legs, (BACK_WINDUP, 0)), compose(legs, (BACK_PUNCH, 1)),
            compose(legs, (BACK_PUNCH, 1)), compose(legs, (BACK_TYPE, 0)), compose(legs, (BACK, 0))]


# --- Repairs: a tool in the hand, working up and down --------------------------------------------------------------

SIDE_REPAIR = swap(SIDE_TYPE, {
    10: "....oddeeecao.oo.",
    11: "....oddceeeestGGo",
    12: "....oddccccktuoo.",
})
SIDE_REPAIR_HIGH = swap(SIDE_TYPE_1, {
    9: "....oddeeccAo.oo.",
    10: "....oddeeeeestGGo",
    11: "....oddccccatuoo.",
})
SIDE_REPAIR_LOW = swap(SIDE_TYPE, {
    10: "....oddeeccao....",
    11: "....oddeeecao.oo.",
    12: "....oddceeeestGGo",
    13: "....oddccccptuoo.",
    14: "....odcccccpoo...",
})


def repair():
    legs = (SIDE_LEGS, 0)
    return [compose(legs, (SIDE_REPAIR_HIGH, 0)), compose(legs, (SIDE_REPAIR, 0)),
            compose(legs, (SIDE_REPAIR_LOW, 0)), compose(legs, (SIDE_REPAIR, 0))]


# --- Dying: he staggers, drops to his knees, and falls on his back -------------------------------------------------

KNEEL_LEGS = part(20, [
    ".....oPpopmo.....",
    "...ozzPpopmzzo...",
    "...ooooooooooo...",
])
# On the floor, head to the left, seen from above like everything else: nine rows tall, 25 long.
FALLEN = part(14, [
    "........ooooooooooo......",
    "..ooooooofeeeeeeesto.....",
    ".ohihtstWecccccccooooooo.",
    "oihjhsvsbaaaaakPPPPPPZzo.",
    "ohihsstBbAAAAymmmmmmooo..",
    ".ohhhsvtbaaaaxkppppppzzo.",
    ".ohhhutuWcccccccdooooooo.",
    "..ooooooocdddddddtuo.....",
    "........ooooooooooo......",
], 25)


def death():
    stand = compose((FRONT_LEGS, 0), (FRONT, 0))
    stagger = compose((FRONT_LEGS, 0), (FRONT_ARMS_A, 0, 1))
    kneel = compose((KNEEL_LEGS, 0), (FRONT, 3))
    slump = compose((KNEEL_LEGS, 0), (FRONT_ARMS_C, 4, -1))
    landing = compose((FALLEN, -1, -4))
    down = compose((FALLEN, 0, -4))
    return [stand, stagger, kneel, slump, landing, down, down, down]


# --- Teleporting: he turns to light, and the light breaks up and rises ---------------------------------------------

def teleport():
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
