"""The Terran drifter seen from almost straight above, at twice the genre's crew size: a 70 by 70 frame.

Not the small one enlarged. Every frame is drawn again by hand as text, one character a pixel (the colours are in
pix.py), so that the outline can be one thin line, parts of the same cloth meet in a dark brown seam and not in
black, and there is room for shading and for the coat.
"""
import sys
sys.path.insert(0, "tools")
from pix import *


def grid(rows, wide):
    for row in rows:
        assert len(row) == wide, (row, len(row))
    return rows


def put(rows, at):
    image = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
    for y, row in enumerate(rows):
        for x, code in enumerate(row):
            if code != ".":
                image.putpixel((at[0] + x, at[1] + y), rgba(code))
    return image


DOWN_AT = (17, 18)
SIDE_AT = (22, 14)

STAND_DOWN = grid([
    "..............ooooooo...............",
    "............ooijjiihhoo.............",
    "...........ohijjjiihhhho............",
    "...........ohiijjiihhhhho...........",
    "....oooooooohiiijihhhhhhoooooooo....",
    "...offffewwohhiiihhhhhhhoWwecccdo...",
    "..offfeeewwohhhiihhhhhhhoWWeecccdo..",
    "..offeeeeecohhhhhhhhhhhhoeeeccccdo..",
    "..ofeeeeeccohtssssssstuhoeecccdddo..",
    "..oeeeeccccottsssttssstuoeccccdddo..",
    "..oeeecccccdotssssssttuodccccddddo..",
    "..oecccccccddotssssstuoddcccdddddo..",
    "...oooecdoeccanbBBBBbnaccdocddooo...",
    ".....oecdoeccaanbBBbnaaxcdocddo.....",
    ".....osstoecckkkkyykkkkccdottuo.....",
    ".....osttoecdppppmmppppcddotuuo.....",
    ".....ottuoooooooooooooooooottuo.....",
    "......ooooecoZZzzmmzzzZocdoooo......",
    ".........oooozzzzmmzzzzoooo.........",
    "............oooooooooooo............",
], 36)
STAND_UP = grid([
    "..............ooooooo...............",
    "............oohiijihhoo.............",
    "...........ohhiijjihhhho............",
    "...........ohhiiijiihhhho...........",
    "....oooooooohhiiiiihhhhhoooooooo....",
    "...offffeeeohhhiihhhhhhhoeeecccdo...",
    "..offfeeeeeohhhhhhhhhhhhoeeeccccdo..",
    "..offeeeeecohhhhhhhhhhhhoeeccccddo..",
    "..ofeeeeeccohhhhhhhhhhhhoecccccddo..",
    "..oeeeeccccohhhhhhhhhhhhoeccccdddo..",
    "..oeeecccccdohhhhhhhhhhodccccddddo..",
    "..oecccccccddohhhhhhhhoddcccdddddo..",
    "...oooecdoeeccccccccccccddocddooo...",
    ".....oecdoeecccccbbcccccddocddo.....",
    ".....oecdoeeccccbbbbccccddocddo.....",
    ".....oecdoeecccbbccbbcccddocddo.....",
    ".....osstoeeccccccccccccddottuo.....",
    ".....osttoeccccccccccccdddotuuo.....",
    ".....ottuoecccccccccccddddottuo.....",
    "......ooo.oeccccccccccdddo.ooo......",
    "...........oooooooooooooo...........",
], 36)
STAND_RIGHT = grid([
    ".........oooooo.......",
    ".......ooffeeeeo......",
    "......offfeeeecco.....",
    ".....offfeeeecccdo....",
    ".....offeeeecccddo....",
    ".....ooooooooooowwo...",
    "....oohhiiijjihhoo....",
    "...ohhhiijjjiiihhho...",
    "...ohhhiiijjiiihhhho..",
    "...ohhhhiiiiiihhhhho..",
    "...ohhhhhhiihhhhhsso..",
    "...ohhhhhhhhhhhtssso..",
    "...ohhhhhhhhhhttsssso.",
    "...ohhhhhhhhhtssssto..",
    "...ohhhhhhhhuttsssuo..",
    "....ohhhhhhuutttuuo...",
    ".....oohhhhuuuuooo....",
    "......oooowwWnbbBo....",
    ".....offffeeeecbBao...",
    "....oeecffeedccccdao..",
    "....oeecffeedccccdAo..",
    "....oeecffeedccccdao..",
    "....oeecffeedccccdko..",
    "....oeecfeeedccccdpo..",
    "....oeeceeeedcccddpo..",
    "....oeccfeeedcccddpo..",
    "....oeccfeecdccdddmo..",
    "....oecceeecdccdddmo..",
    ".....oeceeecdcdddoo...",
    "......ooeecdoooo......",
    ".......ossto..........",
    ".......ostto..........",
    ".......ottuo..........",
    "........ooo...........",
], 22)


def change(rows, changes, wide):
    rows = list(rows)
    for number, text in changes.items():
        while len(rows) <= number:
            rows.append("." * wide)
        rows[number] = text
    return grid(rows, wide)


# --- Walking: only the arms and feet move, as on the small sheet ------------------------------------------------------

STEP_DOWN = change(STAND_DOWN, {      # the arm on the viewer's left comes forward, the other boot with it
    12: "...oooecdoeccanbBBBBbnaccdooooooo...",
    13: ".....oecdoeccaanbBBbnaaxcdo.........",
    14: ".....oecdoecckkkkyykkkkccdo.........",
    15: ".....oecdoecdppppmmppppcddo.........",
    16: ".....osstoooooooooooooooooo.........",
    17: ".....osttoeco....oZZzzzocdo.........",
    18: ".....ottuooo.....oZzzzzooo..........",
    19: "......ooo........ozzzzzo............",
    20: ".................ozzzzzo............",
    21: "..................ooooo.............",
}, 36)
STEP_DOWN_2 = grid(STAND_DOWN[:12] + [row[::-1] for row in STEP_DOWN[12:]], 36)
STEP_UP = change(STAND_UP, {          # the arm on the viewer's left swings up past its shoulder; a boot shows under the hem
    0: "....ooooo.....ooooooo...............",
    1: "....ossto...oohiijihhoo.............",
    2: "....ostto..ohhiijjihhhho............",
    3: "....ottuo..ohhiiijiihhhho...........",
    4: "....oeecoooohhiiiiihhhhhoooooooo....",
    12: "...oooooooeeccccccccccccddocddooo...",
    13: ".........oeecccccbbcccccddocddo.....",
    14: ".........oeeccccbbbbccccddocddo.....",
    15: ".........oeecccbbccbbcccddocddo.....",
    16: ".........oeeccccccccccccddocddo.....",
    17: ".........oeccccccccccccdddocddo.....",
    18: ".........oecccccccccccddddoooo......",
    19: "..........oeccccccccccdddo..........",
    20: "...........oozzzzoooooooo...........",
    21: "............ozzzzo..................",
    22: "............ozZzzo..................",
    23: ".............oooo...................",
}, 36)
STEP_UP_2 = grid([row[::-1] for row in STEP_UP], 36)


def stand():
    return [put(STAND_DOWN, DOWN_AT), put(STAND_RIGHT, SIDE_AT), put(STAND_UP, DOWN_AT)]


def walk_down():
    return [put(g, DOWN_AT) for g in (STAND_DOWN, STEP_DOWN, STAND_DOWN, STEP_DOWN_2)]


def walk_up():
    return [put(g, DOWN_AT) for g in (STAND_UP, STEP_UP, STAND_UP, STEP_UP_2)]
