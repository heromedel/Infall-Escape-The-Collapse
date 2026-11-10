"""The Terran drifter seen from almost straight above, at the genre's crew size.

Built as the genre builds its human (docs/reference/genre-crew-sheet-analysis.md): a head on two coat shoulders on a
two-line torso, a fist a pixel, feet a line. Every pixel here is placed by hand as text, one character a pixel; the
colours are in pix.py. A frame is a grid of text set into a 35 by 35 frame at the offset its view uses.
"""
import sys
sys.path.insert(0, "tools")
from pix import *

DOWN_AT = (6, 9)     # where a camera-facing or away-facing grid (21 wide) sits in the frame
SIDE_AT = (8, 7)     # where a side grid (13 wide) sits


def grid(rows, wide):
    for row in rows:
        assert len(row) == wide, (row, len(row))
    return rows


def put(rows, at, across=0, down=0):
    image = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
    for y, row in enumerate(rows):
        for x, code in enumerate(row):
            if code != ".":
                image.putpixel((at[0] + x + across, at[1] + y + down), rgba(code))
    return image


def change(rows, changes, wide):
    rows = list(rows)
    for number, text in changes.items():
        while len(rows) <= number:
            rows.append("." * wide)
        rows[number] = text
    return grid(rows, wide)


# --- Standing and walking, facing the camera ---------------------------------------------------------------------

STAND_DOWN = grid([
    "........oooo.........",
    ".......ojiiho........",
    "....oooohjiihoooo....",
    "...offwohiihhoWcdo...",
    "..offeeohhhhhoecddo..",
    "..ofeecotsssuoccddo..",
    "..oeccecosttocdcddo..",
    "...ooeoeabBbadodoo...",
    "...osooeppyppdooto...",
    "....o.ooooooooo.o....",
    ".....oeoZzmzZodo.....",
    "......o.ooooo.o......",
], 21)
STEP_DOWN = change(STAND_DOWN, {      # the arm on the viewer's left comes forward, the other foot with it
    7: "...ooooeabBbadodoo...",
    8: "...oecoeppyppdoo.....",
    9: "...oeoooooooooo......",
    10: "...osoeo..oZzo.......",
    11: "....o.o...ozo........",
    12: "..........ooo........",
}, 21)
STEP_DOWN_2 = change(STAND_DOWN, {
    7: "...ooeoeabBbadoooo...",
    8: ".....ooeppyppdocdo...",
    9: "......oooooooooodo...",
    10: ".......oZzo..odoto...",
    11: "........ozo...o.o....",
    12: "........ooo..........",
}, 21)

# --- Facing away ---------------------------------------------------------------------------------------------------

STAND_UP = grid([         # from behind the long coat hides his feet: its hem is a third brown line
    ".........oooo........",
    "........ohiiho.......",
    "....oooohhiihoooo....",
    "...offeohiihhoecdo...",
    "..offeeohhihhoecddo..",
    "..ofeecoohhhooccddo..",
    "..oeccecowwWocdcddo..",
    "...ooeoeecbcccodoo...",
    "...osooecbcbccooto...",
    "....o..occccco..o....",
    ".......ooooooo.......",
], 21)
STEP_UP = change(STAND_UP, {          # the arm on the viewer's left swings forward, up past its shoulder; a boot shows
    0: "....o....oooo........",
    1: "...oso..ohiiho.......",
    2: "...oeooohhiihoooo....",
    7: "....oooeecbcccoocdo..",
    8: "......oecbcbccoocdo..",
    9: ".......occccco..oo...",
    10: ".......ozzoooo.......",
    11: ".......ozzo..........",
    12: "........oo...........",
}, 21)
STEP_UP_2 = change(STAND_UP, {
    0: ".........oooo...o....",
    1: "........ohiiho..oto..",
    2: "....oooohhiihooodo...",
    7: "..oecooeecbcccooo....",
    8: "..oecooecbcbcco......",
    9: "...oo..occccco.......",
    10: ".......oooozzo.......",
    11: "..........ozzo.......",
    12: "...........oo........",
}, 21)

# --- Facing right ----------------------------------------------------------------------------------------------------

STAND_RIGHT = grid([
    ".....ooo.....",
    "....ofeeo....",
    "...offeco....",
    "...ooooowo...",
    "..ohhiihoo...",
    "..ohijihho...",
    "..ohiihtsoo..",
    "..ohhhtssoo..",
    "..ohhhutoo...",
    "...ooooobo...",
    "...offecao...",
    "...ofeecoo...",
    "...ofeecdoo..",
    "...oeeccooo..",
    "...odeccooo..",
    "....oocdso...",
    "......osto...",
    ".......oo....",
], 13)
STEP_RIGHT = change(STAND_RIGHT, {    # the near arm swings forward; a boot shows under him
    9: "...ooooobоo..".replace("о", "o"),
    10: "...offecaoeo.",
    11: "...ofeecooeo.",
    12: "...ofeecooeco",
    13: "...oeeccoooco",
    14: "...odeccooso.",
    15: "....oocdZzto.",
    16: "......ooooo..",
    17: ".............",
}, 13)
STEP_RIGHT_2 = change(STAND_RIGHT, {  # the far arm comes forward past his head, the near one back, a leg out in front
    3: "...ooooowoo..",
    4: "..ohhiihooeo.",
    5: "..ohijihhoeso",
    6: "..ohiihtsoooo",
    11: "...ofeeco....",
    12: "..oofeecdoo..",
    13: "..oeeccdopoo.",
    14: "..oeecooopPpo",
    15: "..oecoo..oZzo",
    16: "...oosoo..ooo",
    17: "....oooo.....",
}, 13)


def walk_down():
    return [put(g, DOWN_AT) for g in (STAND_DOWN, STEP_DOWN, STAND_DOWN, STEP_DOWN_2)]


def walk_up():
    return [put(g, DOWN_AT, down=1) for g in (STAND_UP, STEP_UP, STAND_UP, STEP_UP_2)]


def walk_right():
    return [put(g, SIDE_AT) for g in (STAND_RIGHT, STEP_RIGHT, STAND_RIGHT, STEP_RIGHT_2)]


def over(rows, patches, wide, top=0):
    """A copy of a grid, widened to `wide`, with `top` empty rows added above, and with pieces of rows replaced:
    {row: (column, text)} or {row: [(column, text), ...]}. Rows are numbered as in the grid it started from, so
    the added rows above are -1, -2 and so on."""
    out = ["." * wide for _ in range(top)] + [row + "." * (wide - len(row)) for row in rows]
    for number, pieces in patches.items():
        index = number + top
        while len(out) <= index:
            out.append("." * wide)
        for column, text in ([pieces] if isinstance(pieces, tuple) else pieces):
            out[index] = out[index][:column] + text + out[index][column + len(text):]
    return grid(out, wide)


LEFT_AT = (2, 7)     # a left-facing grid is 21 wide, his mirrored figure in columns 10 to 18
STAND_LEFT = grid(["." * 8 + row[::-1] for row in STAND_RIGHT], 21)

# --- Aiming: three aims, straight, a little to his right, a little to his left; no flash ----------------------------
# The pistol is in his right hand, at the end of a straight arm. His head turns a little with the aim.

AIM_DOWN = over(STAND_DOWN, {
    7: (3, "oeco"), 8: (3, "oefcoppyppd"), 9: (4, "ofcoooooooo"), 10: (4, "oeoooomzZodo"),
    11: (5, "ooGooooo.o"), 12: (5, "ooDo"), 13: (5, "ooDo"), 14: (6, "oGo"), 15: (6, "oGo"), 16: (7, "o"),
}, 21)
AIM_DOWN_RIGHT = over(STAND_DOWN, {
    3: (8, "tiihh"), 4: (8, "sthhh"), 5: (8, "sssuh"), 6: (9, "sth"),
    7: (2, "ofcoo"), 8: (2, "ofooceppyppd"), 9: (1, "oeco.ooooooooo"), 10: (1, "ooooo"),
    11: (1, "oGo"), 12: (1, "oDo"), 13: (0, "oGoo"), 14: (0, "oGo"), 15: (0, "oo"),
}, 21)
AIM_DOWN_LEFT = over(STAND_DOWN, {
    3: (8, "hiiht"), 4: (8, "hhhss"), 5: (8, "htsss"), 6: (9, "sst"),
    7: (3, "oeco"), 8: (3, "oefooppyppd"), 9: (4, "ofcoooooooo"), 10: (4, "ofecoomzZodo"),
    11: (5, "oecooooo.o"), 12: (6, "oosoGo"), 13: (8, "ooDo"), 14: (9, "ooGo"), 15: (10, "oGo"), 16: (11, "oo"),
}, 21)
AIM_UP = over(STAND_UP, {
    -3: (14, "oo"), -2: (14, "oGo"), -1: (14, "oGo"), 0: (14, "oDo"), 1: (13, "oooo"), 2: (13, "ooceo"),
    7: (14, "ooo."), 8: (14, "oo.."), 9: (14, "..."),
}, 21, 4)
AIM_UP_RIGHT = over(STAND_UP, {
    -4: (19, "o"), -3: (18, "oGo"), -2: (17, "oDDo"), -1: (17, "oGo"), 0: (16, "oDoo"), 1: (15, "oooo"),
    2: (13, "oooceo"), 3: (8, "hhiih"), 3.5: (0, ""), 7: (14, "ooo."), 8: (14, "oo.."), 9: (14, "..."),
} if False else {
    -4: (19, "o"), -3: (18, "oGo"), -2: (17, "oDDo"), -1: (17, "oGo"), 0: (16, "oDoo"), 1: (15, "oooo"),
    2: (13, "oooceo"), 3: [(8, "hhiih"), (17, "oo")], 7: (14, "ooo."), 8: (14, "oo.."), 9: (14, "..."),
}, 21, 4)
AIM_UP_LEFT = over(STAND_UP, {
    -4: (10, "o"), -3: (9, "oDoo"), -2: (10, "oGDo"), -1: (11, "oGGo"), 0: (9, "oooooo"), 1: (13, "ooo"),
    2: (13, "oocoo"), 3: [(8, "iihhh"), (14, "ecddo")], 7: (14, "ooo."), 8: (14, "oo.."), 9: (14, "..."),
}, 21, 4)
AIM_RIGHT = over(STAND_RIGHT, {
    11: (3, "ofeecoooooooo"), 12: (3, "ofeecdooDDGGo"), 13: (3, "oeeccecosooo"), 14: (3, "odeccooooo"),
    15: (4, "oooooo..."), 16: (6, "...."), 17: (7, ".."),
}, 21)
AIM_RIGHT_LOW = over(STAND_RIGHT, {       # a little to his right is toward the camera: the pistol tips down the screen
    8: (2, "ohhsssoo"), 9: (3, "oostobo"),
    13: (3, "oeeccecо".replace("о", "o")), 14: (3, "odeccooooo"), 15: (4, "ooooooDGDo"), 16: (6, "..oostDGo"),
    17: (7, "...ooooGo"), 18: (14, "oo"),
}, 21)
AIM_RIGHT_HIGH = over(STAND_RIGHT, {      # a little to his left is away from it: the pistol tips up
    5: (2, "ohijitso"), 7: (14, "oo"), 8: (13, "oGGo"), 9: (12, "oDDo"), 10: (10, "ooDoo"), 11: (3, "ofeecoooooo"),
    12: (3, "ofeecdoooso"), 13: (3, "oeeccecooo"), 14: (3, "odeccooo"), 15: (4, "oooooo..."), 16: (6, "...."),
    17: (7, ".."),
}, 21)
AIM_LEFT = over(STAND_LEFT, {             # facing left his right hand is on the far side, so the pistol is up the screen
    3: (5, "ooooo"), 4: (5, "oGGDDoo"), 5: (6, "oostco"), 6: (8, "oooo"),
}, 21)
AIM_LEFT_LOW = over(STAND_LEFT, {
    5: (8, "ooc"), 6: (7, "oDDoo"), 7: (6, "oGDsto"), 8: (5, "oGDoooo"), 9: (4, "oGDo"), 10: (5, "oo"),
}, 21)
AIM_LEFT_HIGH = over(STAND_LEFT, {
    0: (5, "oo"), 1: (4, "oGDoo"), 2: (5, "ooDGoooo"), 3: (7, "ooGo"), 4: (8, "oDoo"), 5: (8, "oso"), 6: (9, "oo"),
}, 21)


def aim_down():
    return [put(g, DOWN_AT) for g in (AIM_DOWN, AIM_DOWN_RIGHT, AIM_DOWN_LEFT)]


def aim_up():
    return [put(g, DOWN_AT, down=1 - 4) for g in (AIM_UP, AIM_UP_RIGHT, AIM_UP_LEFT)]


def aim_right():
    return [put(g, SIDE_AT) for g in (AIM_RIGHT, AIM_RIGHT_LOW, AIM_RIGHT_HIGH)]


def aim_left():
    return [put(g, LEFT_AT) for g in (AIM_LEFT, AIM_LEFT_LOW, AIM_LEFT_HIGH)]


# --- Fighting a fire: a red extinguisher on the same straight arm, swept from side to side; no spray -----------------

FIRE_DOWN = [
    over(STAND_DOWN, {7: (2, "ofcoo"), 8: (2, "ofooceppyppd"), 9: (1, "oeco.ooooooooo"), 10: (1, "ooooo"),
                      11: (1, "o44oo"), 12: (1, "o45o"), 13: (1, "o4oo"), 14: (1, "ooko"), 15: (2, "ooo")}, 21),
    over(STAND_DOWN, {7: (3, "oeco"), 8: (3, "oefooppyppd"), 9: (3, "oefooooooooo"), 10: (3, "ooooo"),
                      11: (4, "o44oooooo"), 12: (4, "o45o"), 13: (4, "o4oo"), 14: (4, "ooko"), 15: (5, "ooo")}, 21),
    over(STAND_DOWN, {7: (3, "oeco"), 8: (3, "oefcoppyppd"), 9: (4, "ofcoooooooo"), 10: (4, "oeoooomzZodo"),
                      11: (5, "oo44oooo.o"), 12: (5, "oo45o"), 13: (6, "o4oo"), 14: (6, "ooko"), 15: (7, "ooo")}, 21),
]
_FIRE_UP_BODY = {7: (14, "ooo."), 8: (14, "oo.."), 9: (14, "...")}
FIRE_UP = [
    over(STAND_UP, {**_FIRE_UP_BODY, **{-3: (13, "oo"), -2: (13, "okoo"), -1: (13, "oo5o"), 0: (13, "o45o"),
                                          1: (13, "oooo"), 2: (13, "ooceo")}}, 21, 4),
    over(STAND_UP, {**_FIRE_UP_BODY, **{-3: (16, "oo"), -2: (16, "oko"), -1: (15, "o4oo"), 0: (15, "o45o"),
                                          1: (15, "oooo"), 2: (13, "ooceo")}}, 21, 4),
    over(STAND_UP, {**_FIRE_UP_BODY, **{-3: (18, "oo"), -2: (18, "oko"), -1: (17, "o4oo"), 0: (17, "o45o"),
                                          1: (16, "ooooo"), 2: (13, "oocecco")}}, 21, 4),
]
FIRE_RIGHT = [
    over(STAND_RIGHT, {10: (9, "oooooo"), 11: (3, "ofeecooo44oko"), 12: (3, "ofeecdoo455o"), 13: (3, "oeeccecosoo"),
                       14: (3, "odeccoooo5o"), 15: (4, "oooooo.ooo"), 16: (6, "...."), 17: (7, "..")}, 21),
    over(STAND_RIGHT, {11: (3, "ofeecoo"), 12: (9, "ooooo"), 13: (3, "oeeccecо44oo".replace("о", "o")),
                       14: (3, "odeccooo455ko"), 15: (4, "ooooooosooo"), 16: (6, "....oo5o"), 17: (7, "....ooo")}, 21),
    over(STAND_RIGHT, {7: (13, "oo"), 8: (11, "oooko"), 9: (10, "o44oo"), 10: (10, "o45o"), 11: (3, "ofeecooosoo"),
                       12: (3, "ofeecdooo5o"), 13: (3, "oeeccecooo"), 14: (3, "odeccoo"), 15: (4, "ooooo...."),
                       16: (6, "...."), 17: (7, "..")}, 21),
]
FIRE_LEFT = [
    over(STAND_LEFT, {2: (5, "ooo"), 3: (4, "oko4o"), 4: (4, "oko4o"), 5: (5, "oo5stco"), 6: (6, "o5oooo"),
                      7: (6, "o55ooo"), 8: (7, "oo")}, 21),
    over(STAND_LEFT, {4: (5, "ooo"), 5: (4, "oko4oec"), 6: (4, "oko4oooo"), 7: (5, "ooosto"), 8: (6, "o5oo"),
                      9: (6, "o55o"), 10: (7, "oo")}, 21),
    over(STAND_LEFT, {1: (4, "oooo"), 2: (4, "oko4o"), 3: (5, "oo4oooo"), 4: (6, "oostoo"), 5: (6, "o5ooco"),
                      6: (6, "o55ooo"), 7: (7, "oo")}, 21),
]


def fire_down():
    return [put(FIRE_DOWN[i], DOWN_AT) for i in (0, 1, 2, 1)]


def fire_up():
    return [put(FIRE_UP[i], DOWN_AT, down=1 - 4) for i in (0, 1, 2, 1)]


def fire_right():
    return [put(FIRE_RIGHT[i], SIDE_AT) for i in (0, 1, 0, 2)]


def fire_left():
    return [put(FIRE_LEFT[i], LEFT_AT) for i in (0, 1, 0, 2)]


# --- At a console: both hands out in front of him, each two pixels by two, taking turns by a pixel -------------------

TYPE_DOWN = [
    over(STAND_DOWN, {8: (3, "oeooeppyppdoodo"), 9: (3, "oecooooooooocdo"), 10: (3, "ostooZzmzZootso"),
                      11: (3, "otto.ooooo.otuo"), 12: (4, "ooo.......ooo")}, 21),
    over(STAND_DOWN, {8: (3, "oeooeppyppdoodo"), 9: (3, ".oecoooooooocdo"), 10: (3, ".ostoZzmzZoocdo"),
                      11: (3, ".ottoooooo.otso"), 12: (4, ".ooo......otuo"), 13: (14, "ooo")}, 21),
    over(STAND_DOWN, {8: (3, "oeooeppyppdoodo"), 9: (3, "oecooooooooocdo"), 10: (3, "oecooZzmzotsoo."),
                      11: (3, "osto.oooootuo.."), 12: (3, "otto.....ooo..."), 13: (4, "ooo")}, 21),
    over(STAND_DOWN, {8: (3, "oeooeppyppdoodo"), 9: (3, "oecooooooooocdo"), 10: (3, ".oecoZzmzZotso."),
                      11: (3, ".ostoooooootuo."), 12: (3, ".otto.....ooo.."), 13: (5, "ooo")}, 21),
]
_TYPE_UP_BODY = {2: (3, "ooooo"), 7: (3, ".oooeecbcccooo."), 8: (3, "..ooecbcbccoo.."), 9: (4, "...occccco...")}
TYPE_UP = [
    over(STAND_UP, {**_TYPE_UP_BODY, **{-1: [(6, "ooo"), (14, "ooo")], 0: [(5, "osto"), (14, "otso")],
                                          1: [(5, "oeo"), (14, "ocdo")], 2: [(3, "ooooo"), (13, "ooooo")]}}, 21, 4),
    over(STAND_UP, {**_TYPE_UP_BODY, **{-1: (4, "ooo"), 0: [(3, "osto"), (15, "ooo")],
                                          1: [(3, "oecoo"), (15, "otso")], 2: [(3, "ooooo"), (13, "oooooo")]}}, 21, 4),
    over(STAND_UP, {**_TYPE_UP_BODY, **{-1: (12, "ooo"), 0: [(5, "ooo"), (13, "tso")],
                                          1: [(4, "osto"), (13, "oco")], 2: [(3, "ooooo"), (13, "ooooo")]}}, 21, 4),
    over(STAND_UP, {**_TYPE_UP_BODY, **{-1: (5, "ooo"), 0: (4, "ostoo"), 1: [(4, "oeco"), (13, "oto")],
                                          2: [(3, "ooooo"), (13, "ooooo")]}}, 21, 4),
]
_NEAR_HAND = {11: (8, "oeooo"), 12: (3, "ofeececsto"), 13: (3, "oeeccectuo"), 14: (3, "odeccecoo"), 15: (8, "oo..."),
              16: (6, "ooo...."), 17: (7, "..")}
TYPE_RIGHT = [
    over(STAND_RIGHT, {**_NEAR_HAND, **{5: (10, "coo"), 6: (9, "ocsto"), 7: (9, "octuo"), 8: (9, "ooooo")}}, 21),
    over(STAND_RIGHT, {3: (10, "ooo"), 4: (8, "oecsto"), 5: (9, "octuo"), 6: (9, "ooooo"),
                       10: (11, "ooo"), 11: (8, "oeosto"), 12: (3, "ofeececctuo"), 13: (3, "oeecceccoo"),
                       14: (3, "odeccecо".replace("о", "o")), 15: (8, "oo..."), 16: (6, "ooo...."), 17: (7, "..")}, 21),
    over(STAND_RIGHT, {4: (8, "oeoo"), 5: (9, "osto"), 6: (9, "otuo"), 7: (9, "oooo"),
                       12: (3, "ofeececooo"), 13: (3, "oeeccecsto"), 14: (3, "odeccectuo"), 15: (4, "oooooooo."),
                       16: (6, "ooo...."), 17: (7, "..")}, 21),
    over(STAND_RIGHT, {**_NEAR_HAND, **{4: (8, "oe"), 5: (9, "oo"), 6: (9, "ocoo"), 7: (9, "ocsto"),
                                          8: (10, "ctuo"), 9: (10, "eooo")}}, 21),
]


def type_down():
    return [put(g, DOWN_AT) for g in TYPE_DOWN]


def type_up():
    return [put(g, DOWN_AT, down=1 - 4) for g in TYPE_UP]


def type_right():
    return [put(g, SIDE_AT) for g in TYPE_RIGHT]


def facing_left(frames):
    """Right-facing frames mirrored and moved four pixels left, where the genre's left-facing figure stands."""
    return [mirror(f).transform((FRAME, FRAME), Image.AFFINE, (1, 0, 4, 0, 1, 0)) for f in frames]


def walk_left():
    return facing_left(walk_right())


def type_left():
    return facing_left(type_right())


# --- A fist fight: the whole body moves. He twists and steps, lunges with one arm, and comes back --------------------

PUNCH_TWIST = grid([
    "........oooo.........",
    "....oooojiiho........",
    "...offwohjiihoo......",
    "..offeeohiihhoWoo....",
    "..ofeecohhhhhoecdo...",
    "...oeccotsssuoccddo..",
    "..ooooecosttocdcddo..",
    "..ocsooeabBbadoooo...",
    "...ooooeppyppdocdo...",
    "......oooooooootdo...",
    ".......oooomppoooo...",
    "..........opppo......",
    "..........oppo.......",
    "..........oZzo.......",
    "..........oooo.......",
], 21)
PUNCH_READY = grid([
    "........oooo.........",
    ".......ojiiho........",
    "....oooohjiihoooo....",
    "...offwohiihhoWcdo...",
    "..offeeohhhhhoecddo..",
    "..ofeecotsssuoccddo..",
    "..oeccecosttocdoooo..",
    "..oooooeabBbadocdo...",
    "..ocsooeppyppdotdo...",
    "...oo.oooooooooooo...",
    ".......oooomppo......",
    "..........oppo.......",
    "..........oZzo.......",
    "..........ooo........",
], 21)
PUNCH_LUNGE = grid([
    "........oooo.........",
    ".......ojiihoooo.....",
    ".....ooohjiihoecdo...",
    "....ofeohiihhoecddo..",
    "...ofeeohhhhhoccddo..",
    "..ofeecotsssuoocdoo..",
    "..oeccecosttocdooo...",
    "..ofecoeabBbadooto...",
    "...ofcoeppyppdoooo...",
    "....oecoooooooo......",
    "....ofco..oppo.......",
    "....ofeo..oZzo.......",
    ".....oso...oo........",
    ".....osto............",
    ".....ooo.............",
], 21)
UP_TWIST = grid([
    ".........oooo........",
    "...ooo..ohiiho.......",
    "...ocsoohhiihoo......",
    "..offeeohiihhoeoo....",
    "..ofeecohhihhoecdo...",
    "...oeccoohhhooccddo..",
    "...ooeccowwWocdcddoo.",
    "...ooooeecbcccocdoto.",
    ".....ooecbcbccooodo..",
    "......oooooooooocdo..",
    "..........ozzo..ooo..",
    "..........ozzo.......",
    "..........ooo........",
], 21)
UP_LUNGE = grid([
    "..............oo.....",
    ".............osto....",
    "..............oto....",
    "..............oeo....",
    "..............oeco...",
    ".........oooo.oooo...",
    "........ohiihoeecdo..",
    "......oohhiihoeccdo..",
    "....oofohiihhoccddo..",
    "...ofeeohhihhocddo...",
    "..ofeecoohhhooccdo...",
    "..oeccecowwWodcdo....",
    "..oecooeecbcccoo.....",
    "..oecooecbcbccoo.....",
    "...ocooooooooooo.....",
    "....o.....ozzo.......",
    "..........ozzo.......",
    "..........ozzo.......",
    "..........oooo.......",
], 21)


def punch_down():
    poses = ((PUNCH_TWIST, -1), (PUNCH_READY, 0), (PUNCH_LUNGE, 1), (PUNCH_LUNGE, 2), (PUNCH_TWIST, 1), (PUNCH_TWIST, 0))
    return [put(g, DOWN_AT, down=down) for g, down in poses]


def punch_up():
    poses = ((UP_TWIST, 4), (UP_TWIST, 3), (UP_LUNGE, -3), (UP_LUNGE, -4), (UP_TWIST, 2), (UP_TWIST, 3))
    return [put(g, DOWN_AT, down=down) for g, down in poses]


# --- Repairs: bent over his work, seen from above; the tool arm rises in three drawings over nine frames -------------
# The pose is the genre's, part for part, in his colours: the far shoulder and the coat's back on the left, the head
# in the middle, the tool arm on the right, the near hand on the deck below.

REPAIR = [grid(rows, 25) for rows in ([
    "..........ooo............",
    ".........oecco...........",
    "........oeeoooo..........",
    ".......oeohhhhho.........",
    ".......oeohhhhho.........",
    "......oceoiihhhoo........",
    "......oceoihhhhodo.......",
    "...ooooceohhhhtoooo......",
    "..oeccoceeoooooooso......",
    "..occdoceeecodoooto......",
    "...ooooocecdodo..oGo.....",
    "....oo.oeeecoo....oGDo...",
    "........oeecoooo...o.....",
    ".........oecodto....o....",
    "..........ooooo..........",
], [
    "..........ooo............",
    ".........oecco...........",
    "........oeeoooo..........",
    ".......oeohhhhho.........",
    ".......oeohhhhhoo........",
    "......oceoiihhhodoo......",
    "......oceoihhhhodtso.....",
    "...ooooceohhhhtoooto.....",
    "..oeccoceeooooo..oGo.....",
    "..occdoceeecodo...oGo....",
    "...ooooocecdodo....oD....",
    "....oo.oeeecoo.....ooo...",
    "........oeecoooo...o.o...",
    ".........oecodto.........",
    "..........ooooo..........",
], [
    "..........ooo............",
    ".........oecco...........",
    "........oeeoooo..........",
    ".......oeohhhhhooo.oo....",
    ".......oeohhhhhoddooo....",
    "......oceoiihhhoddtto....",
    "......oceoihhhhodooso....",
    "...ooooceohhhhtoo..Go....",
    "..oeccoceeooooo....Go....",
    "..occdoceeecodo....Do....",
    "...ooooocecdodo....ooo...",
    "....oo.oeeecoo.....ooo...",
    "........oeecoooo...o.o...",
    ".........oecodto.........",
    "..........ooooo..........",
])]


def repair():
    drawings = [put(g, (5, 11)) for g in REPAIR]
    return [drawings[i] for i in (0, 1, 2, 2, 1, 1, 0, 0, 0)]


# --- Dying, from the side: he staggers, goes over backwards, is down, and settles ------------------------------------
# The four falling poses are the genre's, part for part, in his colours: slate legs, brown coat, dark hair.

FALLING = [grid(rows, 29) for rows in ([
    "..........oooo...............",
    "......ooooeceeo..............",
    "....ooocccocceeo.............",
    "....ottocommpmoooo...........",
    ".....ooooomcohhhhho..........",
    "........oocoshhhhho..........",
    "......ooppbosshthio..........",
    ".....opmpccosssthio..........",
    "....opppmcccossstho..........",
    "...oppmmomccoooooo...........",
    "..ompmmmommpeeeo.............",
    "..oomopmmoomceeo.............",
    "...ooommotmceeeo.............",
    "....opmmotoceeco.............",
    "....opmmooooooo..............",
    "....oooooo...................",
], [
    ".............................",
    "......oooooooooo.............",
    "......ostocceeeeoo...........",
    "......osooccccceeeo..........",
    ".......oo.oooooeeeoo.........",
    "..............oepooooo.......",
    "............ooeeohhhhho......",
    "..........ooeeeeohhhhho......",
    "........oooeccebosshhio......",
    ".....ooomppoppeposshhio......",
    "....ompmmmpoppepostthio......",
    "....oooommpoppcppottto.......",
    ".....ompmmmomcpooooooo.......",
    "....ooppmmmmooooompmmo.......",
    "....opmmmmmoostoppmoo........",
    "....opommoo.ootopoo..........",
    "....ooooo.....ooo............",
], [
    ".............................",
    ".............................",
    ".............................",
    ".............................",
    ".............................",
    ".............................",
    "................ooo..........",
    ".............ooooeeoooo......",
    "............osseeeeeeeeo.....",
    "...........oottccoecccpoooo..",
    "......oooooomooooooppppohhho.",
    "....oopmmmmmmmmooooopoohhhho.",
    "....oopmopmmmmmooemmbosshhio.",
    "....ooppmoooooooppppmosthiho.",
    ".....ooommmmmmoooooopootthho.",
    ".......oooooooo..ottooooooo..",
    "..................ooo........",
], [
    ".............................",
    ".............................",
    ".............................",
    ".............................",
    ".............................",
    ".............................",
    ".............................",
    ".............................",
    ".............................",
    "...................oooo......",
    "...........oooooooooeeeo.....",
    ".........ooommmmmpoeeecoooo..",
    "........omooooooooeeeccohhho.",
    ".......ommoppmmmmoecccohhhho.",
    ".......oooommmmmoecboosshhio.",
    "..........oooomopppomosthiho.",
    "..............oooooomootthho.",
    ".............osstottooooooo..",
    ".............ossooooo........",
    "..............oo.............",
])]


def death():
    return [put(STAND_RIGHT, (5, 7))] + [put(g, (5, 8)) for g in FALLING]


# --- Teleporting: he drops to the bottom of the frame, his own columns are drawn up, and he comes apart --------------

SHARES = (0.6, 0.0, 1.0, 0.2, 0.7, 0.0, 0.4, 1.0, 0.1, 0.8, 0.3, 0.0, 0.9, 0.5, 0.0, 1.0, 0.3)
ORDER = (5, 11, 1, 14, 8, 3, 16, 6, 12, 0, 9, 4, 15, 2, 10, 7, 13)     # which columns go first


def teleport():
    """Nine frames: the reach of the streaks is 0, 2, 5, 2, 5, 8, 13, 13, 13 rows, as on the genre's sheet, and he
    loses columns as it goes. Every streak is made of the column's own pixels."""
    stand = put(STAND_DOWN, DOWN_AT, down=8)
    frames = []
    for reach, gone in ((0, 0), (2, 3), (5, 5), (2, 3), (5, 5), (8, 9), (13, 12), (13, 12), (13, 12)):
        image = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
        for x in range(FRAME):
            column = [(y, stand.getpixel((x, y))) for y in range(FRAME) if stand.getpixel((x, y))[3]]
            if not column:
                continue
            index = x - DOWN_AT[0] - 2
            lost = 0 <= index < 17 and index in ORDER[:gone]
            amount = round(reach * SHARES[index % 17])
            top = column[0][0]
            for y, colour in column:
                if not (lost and y > top + 2):          # a lost column keeps only its top, which is drawn upward
                    image.putpixel((x, y), colour)
            for step in range(amount):
                image.putpixel((x, top - 1 - step), column[min(len(column) - 1, 1 + step * 2 // max(1, amount))][1])
        frames.append(image)
    return frames


# --- The clone bay: a grey lump, a grey figure, and the colour coming in from the feet -------------------------------

GREYS = ("#4a4650", "#646070", "#7e7a88", "#9a98a4")
LUMP = grid([".ooooo.", "o21120o", "o11211o", "o21121o", ".o112o.", "..ooo.."], 7)


def clone():
    stand = put(STAND_DOWN, DOWN_AT)

    def grey(colour):
        light = (colour[0] * 3 + colour[1] * 4 + colour[2]) // 8
        code = GREYS[min(3, light // 52)]
        return tuple(int(code[i:i + 2], 16) for i in (1, 3, 5)) + (255,)

    def figure(colour_from):
        image = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
        for y in range(FRAME):
            for x in range(FRAME):
                colour = stand.getpixel((x, y))
                if colour[3]:
                    image.putpixel((x, y), colour if y >= colour_from or colour == rgba("o") else grey(colour))
        return image

    lump = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
    for y, row in enumerate(LUMP):
        for x, code in enumerate(row):
            if code != ".":
                lump.putpixel((14 + x, 14 + y), rgba("o") if code == "o" else grey((int(code) * 70,) * 3))
    bare = figure(99)
    for y in range(FRAME):                              # the first grey figure has no fists or feet yet
        for x in range(FRAME):
            if y >= DOWN_AT[1] + 9 and bare.getpixel((x, y))[3]:
                bare.putpixel((x, y), (0, 0, 0, 0))
    return [lump, bare, figure(99), figure(DOWN_AT[1] + 7), figure(DOWN_AT[1] + 3), stand]


def portrait():
    return put(STAND_DOWN, DOWN_AT)


def laser_shot():
    image = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
    for y in range(12, 23):
        for x in range(16, 19):
            image.putpixel((x, y), (255, 255, 255, 255))
    return image
