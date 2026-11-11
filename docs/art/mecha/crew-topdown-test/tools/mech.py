"""A HalfMech in its suit seen from almost straight above, at the crew size of the top-down Terran drifter.

The Terran drifter's build (docs/art/terran/crew-test-4) carried over to the Mecha crew sheet's design
(docs/art/mecha/crew): a crest helm in place of the head, two pauldrons with a blade rising from each in place of the
coat shoulders, a claw in place of a fist, a two-line chest with its three lights, feet a line. Every pixel is placed
by hand as text, one character a pixel.
"""
from PIL import Image

FRAME = 35
PALETTE = {                      # the Mecha crew palette, docs/art/palette.md
    "o": "#0A0A0E",              # outline
    "k": "#1C1D24",              # shadow
    "n": "#2E3039",              # armour dark
    "a": "#4A4D5A",              # armour
    "e": "#7A7F8E",              # armour edge
    "v": "#AA28EB",              # power purple
    "q": "#5A128C",              # purple deep
}
DOWN_AT = (5, 9)                 # where a camera-facing or away-facing grid (25 wide) sits in the frame
SIDE_AT = (10, 6)                # where a right-facing grid (15 wide) sits


def rgba(code):
    hexa = PALETTE[code]
    return tuple(int(hexa[i:i + 2], 16) for i in (1, 3, 5)) + (255,)


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


def change(rows, changes, wide):
    rows = list(rows)
    for number, text in changes.items():
        while len(rows) <= number:
            rows.append("." * wide)
        rows[number] = text
    return grid(rows, wide)


# --- Facing the camera ---------------------------------------------------------------------------------------------
# Helm: a kite with its crest ridge down the middle and the visor bar along its front edge. A blade rises up and out
# of each pauldron. Chest lights under the visor. A claw hangs under each pauldron.

STAND_DOWN = grid([
    "...o........o........o...",
    "...oo......oeo......oo...",
    "...oeo....oaeno....oao...",
    "...oeao..oaaenno..onao...",
    "....oaaoooaaennooonno....",
    "...oeaannonaenkonaanko...",
    "...oaannkovvvvvonnnkko...",
    "...oannkkooooooonnkkko...",
    "....oooooonnvnkoooooo....",
    "...onko..onvnvko..onko...",
    "...oko....onnko....oko...",
    "....o....oanonko....o....",
    "..........oo.oo..........",
], 25)
STEP_DOWN = grid([         # the claw on the viewer's left swings forward and hangs lower; the other is out of sight; a foot steps
    "...o........o........o...",
    "...oo......oeo......oo...",
    "...oeo....oaeno....oao...",
    "...oeao..oaaenno..onao...",
    "....oaaoooaaennooonno....",
    "...oeaannonaenkonaanko...",
    "...oaannkovvvvvonnnkko...",
    "...oannkkooooooonnkkko...",
    "....oooooonnvnkoooooo....",
    "...onko..onvnvko.........",
    "...onko...onnko..........",
    "...oko....ooonko.........",
    "....o.......onko.........",
    ".............oo..........",
], 25)
STEP_DOWN_2 = grid([
    "...o........o........o...",
    "...oo......oeo......oo...",
    "...oeo....oaeno....oao...",
    "...oeao..oaaenno..onao...",
    "....oaaoooaaennooonno....",
    "...oeaannonaenkonaanko...",
    "...oaannkovvvvvonnnkko...",
    "...oannkkooooooonnkkko...",
    "....oooooonnvnkoooooo....",
    ".........onvnvko..onko...",
    "..........onnko...onko...",
    ".........oanooo....oko...",
    ".........oano.......o....",
    "..........oo.............",
], 25)

# --- Facing away ---------------------------------------------------------------------------------------------------
# The same build with no visor and no chest lights: the crest ridge runs the whole helm and down the back plate.

STAND_UP = grid([
    "...o........o........o...",
    "...oo......oeo......oo...",
    "...oeo....oaeno....oao...",
    "...oeao..oaaenno..onao...",
    "....oaaoooaaennooonno....",
    "...oeaannonaenkonaanko...",
    "...oaannkonnenkonnnkko...",
    "...oannkkooooooonnkkko...",
    "....oooooonnenkoooooo....",
    "...onko..oknenko..onko...",
    "...oko....onnko....oko...",
    "....o....oanonko....o....",
    "..........oo.oo..........",
], 25)
STEP_UP = grid([
    "...o........o........o...",
    "...oo......oeo......oo...",
    "...oeo....oaeno....oao...",
    "...oeao..oaaenno..onao...",
    "....oaaoooaaennooonno....",
    "...oeaannonaenkonaanko...",
    "...oaannkonnenkonnnkko...",
    "...oannkkooooooonnkkko...",
    "....oooooonnenkoooooo....",
    ".........oknenko..onko...",
    "..........onnko...onko...",
    ".........oanooo....oko...",
    ".........oano.......o....",
    "..........oo.............",
], 25)
STEP_UP_2 = grid([
    "...o........o........o...",
    "...oo......oeo......oo...",
    "...oeo....oaeno....oao...",
    "...oeao..oaaenno..onao...",
    "....oaaoooaaennooonno....",
    "...oeaannonaenkonaanko...",
    "...oaannkonnenkonnnkko...",
    "...oannkkooooooonnkkko...",
    "....oooooonnenkoooooo....",
    "...onko..oknenko.........",
    "...onko...onnko..........",
    "...oko....ooonko.........",
    "....o.......onko.........",
    ".............oo..........",
], 25)

# --- Facing right --------------------------------------------------------------------------------------------------
# From above, a figure facing right has one shoulder above its head and one below. Far pauldron and its blade on top,
# the helm with its ridge running back to a point and the visor on its front edge, the near pauldron, blade and claw
# below.

STAND_RIGHT = grid([
    "....o..........",
    "....oo.........",
    "....ono........",
    "...oonoo.......",
    "..onnnnko......",
    "..onnkkko......",
    "..oooooooo.....",
    ".oaaaaannvo....",
    "oeeeeeeeavo....",
    ".onnnnnkkvo....",
    "..oooooooo.....",
    "..oeaaanoo.....",
    "..oaannkono....",
    "..oannkkoko....",
    "...ookooo......",
    "....oko........",
    "....oo.........",
    "....o..........",
], 15)
STEP_RIGHT = grid([         # the near claw reaches forward, a foot trails behind
    "....o..........",
    "....oo.........",
    "....ono........",
    "...oonoo.......",
    "..onnnnko......",
    "..onnkkko......",
    "..oooooooo.....",
    ".oaaaaannvo....",
    "oeeeeeeeavo....",
    ".onnnnnkkvo....",
    "..oooooooo.....",
    "ooooeaaanooo...",
    "oanoaannkonno..",
    ".oooannkkooko..",
    "...ookoo..oo...",
    "....oko........",
    "....oo.........",
    "....o..........",
], 15)
STEP_RIGHT_2 = grid([         # the far claw reaches forward, a foot steps ahead
    "....o..........",
    "....oo.........",
    "....ono........",
    "...oonoooo.....",
    "..onnnnkonno...",
    "..onnkkkooko...",
    "..ooooooooo....",
    ".oaaaaannvo....",
    "oeeeeeeeavo....",
    ".onnnnnkkvo....",
    "..ooooooooo....",
    "..oeaaanoano...",
    "..oaannkoooo...",
    "..oannkko......",
    "...ookoo.......",
    "....oko........",
    "....oo.........",
    "....o..........",
], 15)



def facing_left(frames):
    return [frame.transpose(Image.FLIP_LEFT_RIGHT) for frame in frames]


def walk_down():
    return [put(g, DOWN_AT) for g in (STAND_DOWN, STEP_DOWN, STAND_DOWN, STEP_DOWN_2)]


def walk_up():
    return [put(g, DOWN_AT) for g in (STAND_UP, STEP_UP, STAND_UP, STEP_UP_2)]


def walk_right():
    return [put(g, SIDE_AT) for g in (STAND_RIGHT, STEP_RIGHT, STAND_RIGHT, STEP_RIGHT_2)]


def walk_left():
    return facing_left(walk_right())
