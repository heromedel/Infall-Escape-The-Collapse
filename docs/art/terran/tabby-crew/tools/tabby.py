"""The Tabby crew sheet, Facing style: the mercenary cat of docs/art/terran/cat-concept-for-gatos, animated.

Every frame is drawn by hand as text, one character a pixel (the colours are in pix.py). A frame is a few hand-drawn
parts laid back to front; each pose of a limb is its own drawing.
"""
from PIL import Image

from pix import FRAME, LEFT, frame, mirrored, tail, rgba, turned, sealed

# --- Facing down (toward the viewer) ---------------------------------------------------------------------------

HEAD = [                      # rows 0-9 of the standing figure; the collar starts under it
    ".....#......##.....",
    "....#Y#....#oO#....",
    "...#YKO#####OKO#...",
    "...#YOOoOoOoOOo#...",
    "...#YOOOOOOOOOo#...",
    "...#YO##OOO##Oo#...",
    "...#YSH#WWWH#Oo#...",
    "...#YSOWWNWWOOo#...",
    "...#YOOWWWWWOOo#...",
    "....#oOOWWWOOo#....",
]
STAND = [                     # rows 10-22: collar, jacket, paws, pants, boots
    "...#CCC#####CCC#...",
    "..#CCcCJJZJJCcCC#..",
    "..#QJJcJjZjTcJJj#..",
    "..#QeJ#JjZTJ#JJj#..",
    "..#QJJ#JjGjJ#JJj#..",
    "..#jjj#RTRRR#jjj#..",
    "..#WWw#PPPpP#wWW#..",
    "...#qPXPPpPPPPp#...",
    "..#qPTTPp#pPPPPp#..",
    "..#qPPPp#.#pPPPp#..",
    "...#ppp#...#ppp#...",
    "..#bBBB#...#bBBB#..",
    "..######...######..",
]
# A step with the leg on our left coming toward us. The body sinks a pixel onto it (rows 11-22) and that knee
# bends, so its boot stays on the deck's line and shows more of its top; the other leg is behind, its boot lifted
# and smaller. The arms swing against the legs: the arm on our left goes back (a row shorter, its paw tucked at
# the hem in shade), the arm on our right comes forward with the whole paw showing.
STEP_LEFT = [
    "...#CCC#####CCC#...",
    "..#CCcCJJZJJCcCC#..",
    "..#QJJcJjZjTcJJj#..",
    "..#QeJ#JjZTJ#JJj#..",
    "..#jjj#JjGjJ#JJj#..",
    "..#ww##RTRRR#jjj#..",
    "...##qPPPPpP#WWW#..",
    "...#qPXPPpPPPPp#...",
    "..#qPTTPp#pPPp#....",
    "..#bbBB#..#BBB#....",
    "..#bBBBB#..###.....",
    "..#######..........",
]
# The other step: the leg on our right comes toward us, the arm on our left comes forward.
STEP_RIGHT = [
    "...#CCC#####CCC#...",
    "..#CCcCJJZJJCcCC#..",
    "..#QJJcJjZjTcJJj#..",
    "..#QeJ#JjZTJ#JJj#..",
    "..#QJJ#JjGjJ#jjj#..",
    "..#jjj#RTRRR##ww#..",
    "..#WWW#PPPpPPp##...",
    "...#qPXPPpPPPPp#...",
    "...#pTTp##pPPPPp#..",
    "....#BBB#..#bbBB#..",
    ".....###..#bBBBB#..",
    "..........#######..",
]
# The tail hangs behind his hip on our right and sways as he walks, a beat behind the hips. Columns 16-21.
TAIL_REST = [
    ".#....",
    ".O#...",
    "#o##..",
    ".O#Y#.",
    ".oO##.",
    ".###..",
]
TAIL_OUT = [                  # swung out from his leg, the tip flicked up
    ".#....",
    "#O#...",
    "#o##..",
    ".#O#Y#",
    "..#O#.",
    "...#..",
]
TAIL_IN = [                   # swung in close, the curl small
    ".#....",
    "#O#...",
    "#o#...",
    "#O##..",
    "#oY#..",
    ".##...",
]


def walk_down():
    stand = frame((TAIL_REST, 16, 15), (HEAD, 0, 0), (STAND, 0, 10))
    return [stand,
            frame((TAIL_OUT, 16, 16), (HEAD, 0, 1), (STEP_LEFT, 0, 11)),
            stand,
            frame((TAIL_IN, 16, 16), (HEAD, 0, 1), (STEP_RIGHT, 0, 11))]


# Aiming toward us: he has drawn the pistol (the holster hangs empty) and holds it low in his right paw, the arm
# out from his side so the pistol hangs over the deck, clear of his leg. Three aims, as on the other sheets:
# straight, a little to his right, a little to his left. The forearm, paw and pistol move as one piece from the
# elbow; the pistol itself never changes shape. The body is rows 10-22, starting a column left of the figure.
FOREARM_PISTOL = [            # rows 14-20: forearm, cuff, paw, pistol
    "#QJJ#",
    "#jjj#",
    "#WWw#",
    "#gg#.",
    "#gX#.",
    "#gX#.",
    ".##..",
]


def arm_down(forearm, swing=-1):
    """Facing us with his right arm out from his side, holding something. swing is how far the forearm stands out:
    -1 straight, -2 further out, 0 in beside his leg. The upper arm follows it, and his side fills in behind."""
    out = -swing
    upper = "." * (2 - out // 2) + "#%s#" + "J" * (out // 2) + "%s#.."
    body = ["....#CCC#####CCC#...",
            "...#CCcCJJZJJCcCC#..",
            upper % ("QJJ", "cJjZjTcJJj"),
            upper % ("QeJ", "JJjZTJ#JJj")]
    for fill, rest in (("J", "JJJjGjJ#JJj#.."), ("R", "RRRTRRR#jjj#.."), ("q", "qPPPPpP#wWW#..")):
        body.append("." * 5 + "#" + rest if out == 0 else "." * (6 - out) + fill * out + rest)
    body += ["....#qPTPPpPPPPp#...",
             "...#qPTTPp#pPPPPp#..",
             "...#qPPPp#.#pPPPp#..",
             "....#ppp#...#ppp#...",
             "...#bBBB#...#bBBB#..",
             "...######...######.."]
    return frame((TAIL_REST, 16, 15), (HEAD, 0, 0), (body, -1, 10), (forearm, swing, 14))


def aim_down():
    return [arm_down(FOREARM_PISTOL, swing) for swing in (-1, -2, 0)]


# --- Facing up (away from the viewer) --------------------------------------------------------------------------

BACK_HEAD = [
    ".....##......#.....",
    "....#Yo#....#O#....",
    "...#YOO#####OOo#...",
    "...#YOOoOoOoOOo#...",
    "...#YOOoOOOoOOo#...",
    "...#YOOoOOOoOOo#...",
    "...#YOOOOOOOOOo#...",
    "...#YOOOOOOOOOo#...",
    "...#YOOOOOOOOOo#...",
    "....#oOOOOOOOo#....",
]
BACK_STAND = [
    "...#CCCCCcCCCcc#...",
    "..#CCcCCCCCCCcCC#..",
    "..#QJJjTJJJJjJJj#..",
    "..#QJJjJTJJJjJJj#..",
    "..#QJJjJJTJJjJJj#..",
    "..#RRRRRRRRRRRRR#..",
    "...#qPPPPpPPPPp#...",
    "...#qPPPPpPPPPp#...",
    "..#qPPPPp#pPPPPp#..",
    "..#qPPPp#.#pPPPp#..",
    "...#ppp#...#ppp#...",
    "..#BBBB#...#BBBB#..",
    "..######...######..",
]
# Walking away, the leg on our left trails toward us (low and big, its heel to us) and the other steps away (short,
# its boot lifted). His arms stay ahead of him, out of sight, as when he stands. The body sinks a pixel: rows 11-22.
BACK_STEP_LEFT = [
    "...#CCCCCcCCCcc#...",
    "..#CCcCCCCCCCcCC#..",
    "..#QJJjTJJJJjJJj#..",
    "..#QJJjJTJJJjJJj#..",
    "..#QJJjJJTJJjJJj#..",
    "..#RRRRRRRRRRRRR#..",
    "...#qPPPPpPPPPp#...",
    "...#qPPPPpPPPPp#...",
    "..#qPPPPp#pPPp#....",
    "..#BBBB#..#DDD#....",
    "..#BBBBB#..###.....",
    "..#######..........",
]
BACK_STEP_RIGHT = [
    "...#CCCCCcCCCcc#...",
    "..#CCcCCCCCCCcCC#..",
    "..#QJJjTJJJJjJJj#..",
    "..#QJJjJTJJJjJJj#..",
    "..#QJJjJJTJJjJJj#..",
    "..#RRRRRRRRRRRRR#..",
    "...#qPPPPpPPPPp#...",
    "...#qPPPPpPPPPp#...",
    "....#pPPp#pPPPPp#..",
    "....#DDD#..#BBBB#..",
    ".....###..#BBBBB#..",
    "..........#######..",
]
# The tail comes from under the jacket and sweeps across his right calf (our right), nearest to us, so it is drawn
# over him. Its tip flicks up on one step and sags on the other.
BACK_TAIL_REST = [(9, 16), (10, 17), (11, 18), (12, 19), (13, 19), (14, 18)]
BACK_TAIL_UP = [(9, 17), (10, 18), (11, 19), (12, 19), (13, 18), (14, 17)]
BACK_TAIL_DOWN = [(9, 17), (10, 18), (11, 19), (12, 20), (13, 20), (14, 20)]


def walk_up():
    stand = frame((BACK_HEAD, 0, 0), (BACK_STAND, 0, 10), tail(BACK_TAIL_REST))
    return [stand,
            frame((BACK_HEAD, 0, 1), (BACK_STEP_LEFT, 0, 11), tail(BACK_TAIL_UP)),
            stand,
            frame((BACK_HEAD, 0, 1), (BACK_STEP_RIGHT, 0, 11), tail(BACK_TAIL_DOWN))]


# Aiming away from us: his right arm (on our right from behind) reaches out ahead of him, which from here is up
# beside his head, leaning out a little so deck shows between it and his ear. The forearm, paw and pistol move as
# one piece; the sleeve from the shoulder leans to meet them. The pistol is a slide with its sight on top.
SLEEVES_UP = {                # columns 15 on, rows 10-12, by the column the forearm stands at
    16: ["#Jj#", "CJj#", "j##."],
    17: [".#Jj#", "CJJj#", "jjj#.", ".##.."],        # where it runs sideways it is two pixels deep, like the rest of
    18: ["..#Jj#", "CJJJj#", "jjjj#.", ".###.."],    # the arm
}
FOREARM_UP_PISTOL = [         # rows 4-9: pistol, paw, cuff
    ".#..",
    "#X#.",
    "#gX#",
    "#gX#",
    "#Oo#",
    "#jj#",
]
FOREARM_UP_PAW = [            # a fist, for the punch
    ".##.",
    "#Oo#",
    "#Oo#",
    "#jj#",
]


def arm_up(forearm, at=17, top=4):
    """From behind with his right forearm raised; `at` is its column: 16 against his head, 18 furthest out."""
    return frame((BACK_HEAD, 0, 0), (BACK_STAND, 0, 10), tail(BACK_TAIL_REST), (SLEEVES_UP[at], 15, 10), (forearm, at, top))


def aim_up():
    return [arm_up(FOREARM_UP_PISTOL, at) for at in (17, 16, 18)]


# --- Facing right (left is the same, mirrored) -----------------------------------------------------------------

SIDE_HEAD = [
    "......#...#........",
    ".....#o#.#Y#.......",
    ".....#oO#YKO#......",
    "....#OOoOoOOO#.....",
    "....#YOOOOOOOO#....",
    "....#YOOOO##OO#....",
    "....#YOoOOH#OON#...",
    "....#YOOOOOOWWW#...",
    "....#oOOOOOOWW#....",
    ".....#oOOOOOw#.....",
]
SIDE_STAND = [
    "....#CCCCCCCCC#....",
    "...#CCQJJCCCCC#....",
    "...#QJQJJdJJJZ#....",
    "...#QJQeJdJJTj#....",
    "...#QJQJJdJTJj#....",
    "...#jRjjjdRRRj#....",
    "...#q#Oo#PPPPp#....",
    "...#qX##PPPPPp#....",
    "...#qTPPPPPPPp#....",
    "...#ppp#qPPPPp#....",
    "...#ppp#qPPPp#.....",
    "...#DDD#BBBBBBb#...",
    "...#############...",
]
# A stride with the near leg forward: its boot lands heel first ahead of him, the far leg trails on its toe, and the
# floor shows between them. The near arm swings back, its paw by the holster. The body sinks a pixel: rows 11-22.
SIDE_STRIDE_NEAR = [
    "....#CCCCCCCCC#....",
    "...#CCQJJCCCCC#....",
    "...#QJQJJdJJJZ#....",
    "...#QJQeJdJJTj#....",
    "...#QQJJdJJTJj#....",
    "...#jjjdRRRRRj#....",
    "...#Oo#qPPPPPp#....",
    "...#qXPPPPPPPp#....",
    "..#ppT###qPPPPp#...",
    "..#ppp#..#qPPPp#...",
    ".#DDD#....#BBBBBb#.",
    ".#####....########.",
]
# The other stride: the far leg forward (darker, thinner), the near leg trailing. The near arm swings forward, bent,
# the forearm across his chest and the paw at its front edge, well above his belt.
SIDE_STRIDE_FAR = [
    "....#CCCCCCCCC#....",
    "...#CCQJJCCCCC#....",
    "...#QJQeJdJJTj#....",
    "...#QJJQQQQjOo#....",
    "...#QJJdjjjjdj#....",
    "...#jRRRRRRRRj#....",
    "...#qPPPPPPPPp#....",
    "...#qXPPPPPPPp#....",
    "..#qPTPP##pppp#....",
    ".#qPPPp#..#ppp#....",
    ".#BBBBBb#.#DDDD#...",
    ".########.######...",
]
# The tail stands up behind him, curling at the tip; it leans back on one stride and stands straighter on the other.
SIDE_TAIL_REST = [(3, 17), (2, 17), (2, 16), (2, 15), (1, 14), (1, 13), (2, 12)]
SIDE_TAIL_BACK = [(3, 18), (2, 18), (1, 17), (1, 16), (0, 15), (0, 14), (1, 13)]
SIDE_TAIL_UPRIGHT = [(3, 18), (2, 18), (2, 17), (2, 16), (2, 15), (2, 14), (3, 13)]


def walk_right():
    stand = frame(tail(SIDE_TAIL_REST), (SIDE_HEAD, 0, 0), (SIDE_STAND, 0, 10))
    return [stand,
            frame(tail(SIDE_TAIL_BACK), (SIDE_HEAD, 0, 1), (SIDE_STRIDE_NEAR, 0, 11)),
            stand,
            frame(tail(SIDE_TAIL_UPRIGHT), (SIDE_HEAD, 0, 1), (SIDE_STRIDE_FAR, 0, 11))]


def walk_left():
    return [mirrored(picture) for picture in walk_right()]


# Aiming to the side: the near arm is straight out ahead of him under his chin, the pistol's slide running on from
# the top of the paw. Level, a little high, a little low. The holster on his hip is empty. Rows 10-17.
SIDE_AIM = [                  # two columns wider than the figure, for the pistol
    "....#CCCCCCCCC#......",
    "...#CCQJJCCCCC######.",
    "...#QJQeQQQQQjgggX#..",
    "...#QJJJJJJJJjOoX##..",
    "...#QJdddddddj####...",
    "...#jRRRRRRRRj#......",
    "...#qPPPPPPPPp#......",
    "...#qTPPPPPPPp#......",
]
SIDE_AIM_HIGH = [
    "....#CCCCCCCCC######.",
    "...#CCQJJCQQQjgggX#..",
    "...#QJQeQQJJJjOoX##..",
    "...#QJJJJJdddj####...",
    "...#QJddddJTJj#......",
    "...#jRRRRRRRRj#......",
    "...#qPPPPPPPPp#......",
    "...#qTPPPPPPPp#......",
]
SIDE_AIM_LOW = [
    "....#CCCCCCCCC#......",
    "...#CCQJJCCCCC#......",
    "...#QJQeQQJJJZ######.",
    "...#QJJJJJQQQjgggX#..",
    "...#QJddddJJJjOoX##..",
    "...#jRRRRRdddj####...",
    "...#qPPPPPPPPp#......",
    "...#qTPPPPPPPp#......",
]
SIDE_LEGS = SIDE_STAND[8:]        # rows 18-22: standing legs and boots


def aim_right():
    return [frame(tail(SIDE_TAIL_REST), (SIDE_HEAD, 0, 0), (arm, 0, 10), (SIDE_LEGS, 0, 18))
            for arm in (SIDE_AIM, SIDE_AIM_HIGH, SIDE_AIM_LOW)]


def aim_left():
    return [mirrored(picture) for picture in aim_right()]


# --- Fighting a fire: the aiming arm with a red extinguisher, sweeping across the fire --------------------------
# No spray is drawn: the game adds it (heromedel, 2026-11-12). The nozzle is the dark tip beyond the red.

FOREARM_EXTINGUISHER = [      # rows 14-21: forearm, cuff, paw, the canister, its nozzle
    "#QJJ#",
    "#jjj#",
    "#WWw#",
    "#rM#.",
    "#rM#.",
    "#rM#.",
    ".#X#.",
    "..#..",
]
FOREARM_UP_EXTINGUISHER = [   # rows 4-9
    ".#..",
    "#X#.",
    "#rM#",
    "#rM#",
    "#Oo#",
    "#jj#",
]
def with_extinguisher(aim):
    """A side aim with the red canister in place of the pistol; its dark nozzle is the tip."""
    return [row.replace("gggX#..", "OOrrX#.").replace("OoX##..", "OoMM##.") for row in aim]


def fire_down():
    return [arm_down(FOREARM_EXTINGUISHER, swing) for swing in (-1, -2, -1, 0)]


def fire_up():
    return [arm_up(FOREARM_UP_EXTINGUISHER, at) for at in (17, 16, 17, 18)]


def fire_right():
    return [frame(tail(SIDE_TAIL_REST), (SIDE_HEAD, 0, 0), (arm, 0, 10), (SIDE_LEGS, 0, 18))
            for arm in map(with_extinguisher, (SIDE_AIM, SIDE_AIM_HIGH, SIDE_AIM, SIDE_AIM_LOW))]


def fire_left():
    return [mirrored(picture) for picture in fire_right()]


# --- Punching: one arm, as on the other sheets, and his weight behind it -----------------------------------------

LEGS = STAND[7:]              # rows 17-22 of the front view: hips, legs, boots
# Toward us, with his right arm (on our left). He shifts his weight away as the fist draws back (the arm shortens,
# the paw up at the hem), then steps in with the other leg and sinks onto it as the arm comes at us, the paw big
# and low; his head dips as the blow lands.
PUNCH_DOWN_BACK = [           # rows 10-16
    "...#CCC#####CCC#...",
    "..#CCcCJJZJJCcCC#..",
    "..#QJJcJjZjTcJJj#..",
    "..#QeJ#JjZTJ#JJj#..",
    "..#jjj#JjGjJ#JJj#..",
    "..#WWw#RTRRR#jjj#..",
    "...####PPPpP#wWW#..",
]
PUNCH_DOWN_STRIKE = [         # rows 11-22: the whole body below the head, stepped in and sunk a pixel
    "...#CCC#####CCC#...",
    "..#CCcCJJZJJCcCC#..",
    "..#QJJcJjZjTcJJj#..",
    "..#QeJ#JjZTJ#JJj#..",
    "..#QJJ#JjGjJ#jjj#..",
    "..#QJJ#RTRRR##ww#..",
    "..#jjj#PPPpPPp##...",
    ".#WWWw#PPpPPPPp#...",
    ".#WWww#p##pPPPPp#..",
    "..####B#...#bbBB#..",
    ".....##...#bBBBB#..",
    "..........#######..",
]
PUNCH_DOWN_HOME = [           # rows 10-17: the arm coming back, a row longer than at rest
    "...#CCC#####CCC#...",
    "..#CCcCJJZJJCcCC#..",
    "..#QJJcJjZjTcJJj#..",
    "..#QeJ#JjZTJ#JJj#..",
    "..#QJJ#JjGjJ#JJj#..",
    "..#QJJ#RTRRR#jjj#..",
    "..#jjj#PPPpP#wWW#..",
    "..#WWw#............",
]


def punch_down():
    stand = frame((TAIL_REST, 16, 15), (HEAD, 0, 0), (STAND, 0, 10))
    return [stand,
            frame((TAIL_IN, 16, 15), (LEGS, 0, 17), (PUNCH_DOWN_BACK, 1, 10), (HEAD, 1, 0)),
            frame((TAIL_REST, 15, 16), (PUNCH_DOWN_STRIKE, -1, 11), (HEAD, -1, 1)),
            frame((TAIL_REST, 15, 16), (PUNCH_DOWN_STRIKE, -1, 11), (HEAD, -1, 2)),
            frame((TAIL_REST, 16, 15), (HEAD, 0, 0), (LEGS, 0, 17), (PUNCH_DOWN_HOME, 0, 10)),
            stand]


# Away from us, with the same arm (on our right from behind). Drawing back, his shoulders shift away and the elbow
# pokes out at his side; then he steps in and sinks as the arm goes out ahead of him, up beside his head.
BACK_TORSO, BACK_LEGS = BACK_STAND[:6], BACK_STAND[6:]        # rows 10-15 and 16-22
ARM_DRAWN_BACK = [            # columns 15-18, rows 11-16: the arm back at his side toward us, the paw at his hip
    "CJ#.",
    "jJj#",
    "jJj#",
    "jjj#",
    "ROo#",
    "###.",
]


def punch_up():
    stand = frame((BACK_HEAD, 0, 0), (BACK_STAND, 0, 10), tail(BACK_TAIL_REST))

    def strike(top):
        """Stepped in and sunk a pixel, the fist out ahead of him; the sleeve grows a row for the further reach."""
        sleeve = SLEEVES_UP[17]
        return frame((BACK_HEAD, 1, 1), (BACK_STEP_RIGHT, 1, 11), tail([(x + 1, y + 1) for x, y in BACK_TAIL_REST]),
                     ([sleeve[0]] * (8 - top) + sleeve, 16, top + 3), (FOREARM_UP_PAW, 18, top))
    return [stand,
            frame((BACK_LEGS, 0, 16), (BACK_TORSO, -1, 10), (BACK_HEAD, -1, 0), tail(BACK_TAIL_REST), (ARM_DRAWN_BACK, 14, 11)),
            strike(8),
            strike(7),
            frame((BACK_HEAD, 0, 0), (BACK_STAND, 0, 10), tail(BACK_TAIL_REST), (ARM_DRAWN_BACK, 15, 11)),
            stand]


# --- Working a console: the pistol is back in its holster -------------------------------------------------------

# From the side: the forearms are out ahead of him at chest height and the paws tap in turn, the far paw showing
# just beyond the near one; a shadow under the arm sets it off from the jacket. Rows 10-17.
SIDE_TYPE_NEAR_UP = [
    "....#CCCCCCCCC#....",
    "...#CCQJJCCCCC#....",
    "...#QJQJJdJJJZ###..",
    "...#QJQeQQQQQjOo#..",
    "...#QJJJJJJJJj#oo#.",
    "...#jRdddddddj####.",
    "...#qPPPPPPPPp#....",
    "...#qXPPPPPPPp#....",
]
SIDE_TYPE_NEAR_DOWN = [
    "....#CCCCCCCCC#....",
    "...#CCQJJCCCCC#....",
    "...#QJQJJdJJJZ####.",
    "...#QJQeQQQQQj#oo#.",
    "...#QJJJJJJJJjOo##.",
    "...#jRdddddddj###..",
    "...#qPPPPPPPPp#....",
    "...#qXPPPPPPPp#....",
]
SIDE_TAIL_FLICK = [(3, 17), (2, 17), (2, 16), (2, 15), (1, 14), (1, 13), (1, 12)]      # only the tip straightens


def type_right():
    def pose(arms, the_tail):
        return frame(tail(the_tail), (SIDE_HEAD, 0, 0), (arms, 0, 10), (SIDE_LEGS, 0, 18))
    return [pose(SIDE_TYPE_NEAR_UP, SIDE_TAIL_REST), pose(SIDE_TYPE_NEAR_DOWN, SIDE_TAIL_REST),
            pose(SIDE_TYPE_NEAR_UP, SIDE_TAIL_FLICK), pose(SIDE_TYPE_NEAR_DOWN, SIDE_TAIL_REST)]


def type_left():
    return [mirrored(picture) for picture in type_right()]


# Toward us: the elbows bend and the forearms come at us, a paw held up either side of his zip and tapping in turn,
# clear above his belt. Rows 10-16.
TYPE_DOWN_LEFT = [            # the paw on our left is down, the other up
    "...#CCC#####CCC#...",
    "..#CCcCJJZJJCcCC#..",
    "..#QJJcJjZjTcJJj#..",
    "..#QeJjjjZjwW#Jj#..",
    "..#QJ#WwjGj##Jjj#..",
    "..#jj###RRRRRjj##..",
    "...##qPPPPpPPp##...",
]
TYPE_DOWN_RIGHT = [
    "...#CCC#####CCC#...",
    "..#CCcCJJZJJCcCC#..",
    "..#QJJcJjZjTcJJj#..",
    "..#Qe#WwjZjjjJJj#..",
    "..#QJJ##jGjwW#Jj#..",
    "..##jjRRRRR###jj#..",
    "...##qPPPPpPPp##...",
]


def type_down():
    def pose(arms, the_tail):
        return frame((the_tail, 16, 15), (HEAD, 0, 0), (LEGS, 0, 17), (arms, 0, 10))
    return [pose(TYPE_DOWN_LEFT, TAIL_REST), pose(TYPE_DOWN_RIGHT, TAIL_REST),
            pose(TYPE_DOWN_LEFT, TAIL_IN), pose(TYPE_DOWN_RIGHT, TAIL_REST)]


# Away from us his paws are out of sight at the console; his elbows work in turn and his tail tip flicks.
BACK_ELBOW_LEFT = ["#.", "#Q", "#Q", ".#"]      # columns 1-2, rows 12-15: the elbow on our left, out a pixel
BACK_ELBOW_RIGHT = ["#.", "j#", "j#", "#."]     # columns 16-17, rows 12-15


def type_up():
    def pose(the_tail, *elbow):
        return frame((BACK_HEAD, 0, 0), (BACK_STAND, 0, 10), tail(the_tail), *elbow)
    return [pose(BACK_TAIL_REST, (BACK_ELBOW_LEFT, 1, 12)), pose(BACK_TAIL_REST, (BACK_ELBOW_RIGHT, 16, 12)),
            pose(BACK_TAIL_UP_STANDING, (BACK_ELBOW_LEFT, 1, 12)), pose(BACK_TAIL_REST, (BACK_ELBOW_RIGHT, 16, 12))]


BACK_TAIL_UP_STANDING = [(9, 16), (10, 17), (11, 18), (12, 18), (13, 17), (14, 16)]


# --- Repairing: down on one knee, hammering at something low ahead of him ---------------------------------------

# From the side, two rows lower than standing (rows 12-22): the near leg's thigh level with the knee up and its
# boot planted ahead; the far leg kneeling, its knee on the deck and its boot behind him; deck shows under the
# raised thigh. The near arm is drawn by the poses below.
KNEEL = [
    "....#CCCCCCCCC#....",
    "...#CCQJJCCCCC#....",
    "...#QJJJJJJJJZ#....",
    "...#QJJJJJJJTj#....",
    "...#QJJJJJJTJj#....",
    "...#jRRRRRRRRj#....",
    "...#qPPPPPPPPp#....",
    "...#qXPPPPPPPPPp#..",
    ".###pppp####qPPp#..",
    "#DDDpppp#..#BBBBBb#",
    "#########..########",
]
KNEEL_ARM_LEVEL = [           # rows 13-16: straight out from the shoulder, a shadow under it
    "...#CCQJJCCCCC###..",
    "...#QJQeQQQQQjOo#..",
    "...#QJJJJJJJJjOo#..",
    "...#QJdddddddj###..",
]
KNEEL_ARM_LOW = [             # rows 14-17: the forearm dropped
    "...#QJQeQQJJJZ###..",
    "...#QJJJJJQQQjOo#..",
    "...#QJddddJJJjOo#..",
    "...#jRRRRRdddj###..",
]
HAMMER_UP = [                 # columns 16-21, rows 7-13: the handle slants up and forward, the head high, clear of
    "..###.",                 # his nose
    ".#ggX#",
    ".#gXX#",
    ".#T###",
    ".#T#..",
    "#T#...",
    "T#....",
]
HAMMER_FORWARD = [            # columns 16-21: the handle level, the head on end
    "...##.",
    "###gX#",
    "TTTgX#",
    "###gX#",
    "...##.",
]
HAMMER_DOWN = [               # columns 15-20: the handle slants down, the head on the work, above the deck
    ".#....",
    ".T#...",
    ".#T##.",
    "##ggX#",
    ".#gXX#",
    "..###.",
]


def repair():
    def pose(arm, arm_row, hammer, hammer_column, hammer_row):
        return frame(tail([(x, y + 2) for x, y in SIDE_TAIL_REST]), (SIDE_HEAD, 0, 2), (KNEEL, 0, 12), (arm, 0, arm_row),
                     (hammer, hammer_column, hammer_row))
    up = pose(KNEEL_ARM_LEVEL, 13, HAMMER_UP, 16, 7)
    forward = pose(KNEEL_ARM_LEVEL, 13, HAMMER_FORWARD, 16, 12)
    down = pose(KNEEL_ARM_LOW, 14, HAMMER_DOWN, 15, 15)
    return [up, forward, down, forward]


# --- Teleport, clone bay and laser shot: made as on the Terran drifter's sheet, from his own standing frame ------

def standing():
    return frame((TAIL_REST, 16, 15), (HEAD, 0, 0), (STAND, 0, 10))


# How far each column of him is pulled, as a share of the frame's pull; the pattern repeats across him.
PULLS = (0.5, 0.1, 1.0, 0.3, 0.0, 0.7, 0.2, 0.9, 0.0, 0.4, 1.0, 0.2, 0.6, 0.0, 0.8, 0.3, 1.0)


def teleport():
    """Eight frames: each column of his own pixels is dragged upward from the feet, a little at first, then a long
    way, stretched most at the top. No light and no effect, as on the other sheets (heromedel, 2026-11-10)."""
    stand = standing()
    frames = []
    for pull in (0, 1, 2, 3, 5, 8, 12, 16):
        picture = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
        for x in range(FRAME):
            column = [stand.getpixel((x, y)) for y in range(FRAME) if stand.getpixel((x, y))[3]]
            if not column:
                continue
            bottom = max(y for y in range(FRAME) if stand.getpixel((x, y))[3])
            high = len(column)
            tall = high + round(pull * PULLS[(x - LEFT) % len(PULLS)])
            bend = (tall - 1) / max(1, high - 1)
            for step in range(tall):
                y = bottom - (tall - 1) + step
                if y >= 0:
                    picture.putpixel((x, y), column[round((high - 1) * (step / max(1, tall - 1)) ** bend)])
        frames.append(picture)
    return frames


def clone():
    """Six frames: the clone bay's cool white plate lowers and he stands there."""
    stand = standing()
    frames = []
    for top in (7, 12, 17, 22, 26, 29):
        picture = stand.copy()
        for y in range(top, 33):
            for x in range(5, 31):
                if x in (5, 30) or y in (top, 32):
                    code = "#15111a"
                elif y == top + 1 or x == 6:
                    code = "#f6f9fc"
                elif x == 29 or y == 31:
                    code = "#a9b6c6"
                else:
                    code = "#dfe6ee"
                picture.putpixel((x, y), rgba(code))
        frames.append(picture)
    return frames


def laser_shot():
    """The crew's pistol shot: a white core in power green, the same as the Terran drifter's."""
    picture = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
    green = (0x66, 0xff, 0x66)
    for y in range(8, 27):
        for x in range(14, 25):
            across, along = abs(x - 19), max(0, abs(y - 17) - 6)
            reach = across + along
            if across <= 1 and abs(y - 17) <= 7:
                picture.putpixel((x, y), (0xf2, 0xff, 0xf2, 255))
            elif reach <= 2:
                picture.putpixel((x, y), green + (255,))
            elif reach <= 3:
                picture.putpixel((x, y), green + (150,))
            elif reach <= 4:
                picture.putpixel((x, y), green + (70,))
    return picture


# --- Death: he is hit, knocked off his feet, lands flat on his side, bounces once and lies still ----------------
# Staged as a knockdown is: a hit, the body in the air between standing and lying, the landing, a small rebound,
# one lying pose. Every frame is one whole figure, so his head never leaves his shoulders.

HEAD_SHUT = HEAD[:5] + [      # his eyes squeezed shut
    "...#YOOOOOOOOOo#...",
    "...#YS##WWW##Oo#...",
] + HEAD[7:]
FLUNG = [                     # rows 10-22, a column wider each side: hit, his arms jolt out from his sides
    "....#CCC#####CCC#....",
    "...#CCcCJJZJJCcCC#...",
    "..#QJJ#cJjZjTc#JJj#..",
    "..#QeJ#JJjZTJJ#JJj#..",
    ".#QJJ#JJJjGjJJJ#JJj#.",
    ".#jjj#RRRTRRRRR#jjj#.",
    ".#WWw#qPPPPpPPp#wWW#.",
    "..###qPXPPpPPPPp###..",
    "...#qPTTPp#pPPPPp#...",
    "...#qPPPp#.#pPPPp#...",
    "....#ppp#...#ppp#....",
    "...#bBBB#...#bBBB#...",
    "...######...######...",
]
# Lying still on his left side, facing us: the arm that ends up on top has flopped across his belly.
LAID_OUT = HEAD_SHUT + [
    "...#CCC#####CCC#...",
    "..#CCcCJJZJJCcCC#..",
    "..#QJJcJjZjTcJJj#..",
    "..#QeJJ#jZTJ#JJj#..",
    "...#QJJJ#GjJ#JJj#..",
    "....#jjj#RRR#jjj#..",
    "....#WWw#PpP#wWW#..",
    "...#q###PpPPPPp#...",
    "..#qPTTPp#pPPPPp#..",
    "..#qPPPp#.#pPPPp#..",
    "...#ppp#...#ppp#...",
    "..#bBBB#...#bBBB#..",
    "..######...######..",
]
TAIL_LIMP = [(17, 15), (18, 16), (18, 17), (19, 18), (19, 19)]                # slack, curving away from his hip


def death():
    hit = frame(tail(TAIL_LIMP), (FLUNG[:8], -1, 10), (LAID_OUT[18:], 0, 18), (HEAD_SHUT, 0, 0))   # the same legs as lying
    hit = hit.crop(hit.getbbox())
    limp = frame(tail(TAIL_LIMP), (LAID_OUT, 0, 0))
    limp = limp.crop(limp.getbbox())

    def placed(figure, middle, lift):
        """The figure with its middle at a column and its lowest pixel `lift` above the deck's line."""
        picture = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
        picture.alpha_composite(figure, (middle - figure.width // 2, 33 - lift - figure.height))
        return sealed(picture)

    flat, still = hit.transpose(Image.ROTATE_270), limp.transpose(Image.ROTATE_270)
    return [placed(hit, 17, 1),                    # hit: jolted a pixel off the deck
            placed(turned(hit, 25), 17, 0),        # going over, his feet still down
            placed(turned(hit, 58), 18, 2),        # off his feet
            placed(flat, 19, 3),                   # flat in the air
            placed(flat, 19, 0),                   # he lands
            placed(flat, 19, 1),                   # a small rebound
            placed(still, 19, 0),                  # and lies still, the arm flopping down
            placed(still, 19, 0)]


# --- The portrait: his head and shoulders, drawn larger by hand -------------------------------------------------

PORTRAIT = [
    "......##.............#.#......",
    ".....#YY#............#o#O#....",
    "....#YKKO#..........#OKKo#....",
    "...#YYKKKO#........#OKKKOo#...",
    "...#YYKKKOO########OOKKKOo#...",
    "..#YOOKOOOOoOOoOOoOOOOKOOOo#..",
    "..#YOOOOOOOoOOoOOoOOOOOOOoo#..",
    "..#YOOOOOOOOOOoOOOOOOOOOOOo#..",
    "..#YOOOOOOOOOOOOOOOOOOOOOoo#..",
    "..#YOO#####OOOOOOOO#####Ooo#..",
    "..#YSOHH###OOOOOOOOHH###Ooo#..",
    "..#YSOO###OOOWWWWOOO###OOoo#..",
    "..#YOSOOOOOWWWNNWWWOOOOOOoo#..",
    "..#YOOSOOOWWWWNNWWWWOOOOOoo#..",
    ".#YYYOOOOWWWWWwwWWWWWOOOOooo#.",
    "..#YOOOOOWWWWWWWWWWWWOOOOoo#..",
    "...#oOOOOWWWWWWWWWWWWOOOoo#...",
    "....#ooOOOOWWWWWWWWOOOOoo#....",
    "..#CCCCCCC##########CCCCCCC#..",
    ".#CCCCcCCCCJJJJZZJJJJCCCCcCC#.",
    "#CCCCccCCCJJJjjZZjjTTJCCccCCC#",
    "#QQJJJJccJJJJjjZZjjTTJJccJJJj#",
    "#QQJJJJ#JJJJJjjZZjTTjJJ#JJJJj#",
    "##############################",
]


def portrait():
    assert len({len(line) for line in PORTRAIT}) == 1
    picture = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
    from pix import KEY
    for j, line in enumerate(PORTRAIT):
        for i, character in enumerate(line):
            if character != ".":
                picture.putpixel((2 + i, 6 + j), rgba(KEY[character]))
    return picture


def portrait_and_shot():
    return [portrait(), laser_shot()]
