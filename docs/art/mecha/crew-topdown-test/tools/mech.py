"""A HalfMech in its suit seen from almost straight above, at the crew size of the top-down Terran drifter.

The design follows heromedel's own top-down drawing of the suit (reference/), brought down to game size, in the
colours of the Mecha crew palette. Every pixel is placed by hand as text, one character a pixel.
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
DOWN_AT = (4, 10)                # where a camera-facing or away-facing grid (27 wide) sits in the frame
SIDE_AT = (8, 4)                 # where a right-facing grid (19 wide) sits


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
# After heromedel's own top-down drawing (reference/): a boxy helm with a pale ridge and a short visor bar on its front
# edge, a wing pauldron each side, a thin spike sweeping up and out of each wing's outer corner, an arm coming down
# and out from under each wing to a grey clamp claw with a purple band, two chest lights, two pointed feet. Spikes up
# and out, arms down and out: together an X, so a claw never reads as stacked under a spike.

STAND_DOWN = grid([
    "o.........................o",
    ".o.........ooooo.........o.",
    "..o.......oaaeano.......o..",
    "...ooo...onaaeanko...ooo...",
    "...oeeoooonaaeankooooano...",
    "...oeaannonaaeankoaannko...",
    "...oaannnonnaeankonnnkko...",
    "...oannkkonnvvvnkonnkkko...",
    "...onkoooooooooooooookko...",
    "....ooko.onnvnvnko.okoo....",
    "....ovno.onnnnnkko.ovno....",
    "...oeeo..oanooonko..oeeo...",
    "...oeo....oo...oo....oeo...",
    "....o.................o....",
], 27)
STEP_DOWN = grid([         # the claw on the viewer's left swings forward and hangs lower, the other lifts; a foot steps
    "o.........................o",
    ".o.........ooooo.........o.",
    "..o.......oaaeano.......o..",
    "...ooo...onaaeanko...ooo...",
    "...oeeoooonaaeankooooano...",
    "...oeaannonaaeankoaannko...",
    "...oaannnonnaeankonnnkko...",
    "...oannkkonnvvvnkonnkkko...",
    "...onkoooooooooooooookko...",
    "....ooko.onnvnvnko.ovno....",
    ".....oko.onnnnnkko..oeeo...",
    "....ovno.ooooooonko..oeo...",
    "...oeeo.......onko....o....",
    "...oeo.........oo..........",
    "....o......................",
], 27)
STEP_DOWN_2 = grid([
    "o.........................o",
    ".o.........ooooo.........o.",
    "..o.......oaaeano.......o..",
    "...ooo...onaaeanko...ooo...",
    "...oeeoooonaaeankooooano...",
    "...oeaannonaaeankoaannko...",
    "...oaannnonnaeankonnnkko...",
    "...oannkkonnvvvnkonnkkko...",
    "...onkoooooooooooooookko...",
    "....ovno.onnvnvnko.okoo....",
    "...oeeo..onnnnnkko.oko.....",
    "...oeo...oanoooooo.ovno....",
    "....o....oano.......oeeo...",
    "..........oo.........oeo...",
    "......................o....",
], 27)

# --- Facing away ---------------------------------------------------------------------------------------------------
# No visor and no chest lights: the ridge runs the whole helm and down the back plate. The claws keep their bands.

STAND_UP = grid([
    "o.........................o",
    ".o.........ooooo.........o.",
    "..o.......oaaeano.......o..",
    "...ooo...onaaeanko...ooo...",
    "...oeeoooonaaeankooooano...",
    "...oeaannonaaeankoaannko...",
    "...oaannnonnaeankonnnkko...",
    "...oannkkonnnennkonnkkko...",
    "...onkoooooooooooooookko...",
    "....ooko.onnnennko.okoo....",
    "....ovno.onnnenkko.ovno....",
    "...oeeo..oanooonko..oeeo...",
    "...oeo....oo...oo....oeo...",
    "....o.................o....",
], 27)
STEP_UP = grid([
    "o.........................o",
    ".o.........ooooo.........o.",
    "..o.......oaaeano.......o..",
    "...ooo...onaaeanko...ooo...",
    "...oeeoooonaaeankooooano...",
    "...oeaannonaaeankoaannko...",
    "...oaannnonnaeankonnnkko...",
    "...oannkkonnnennkonnkkko...",
    "...onkoooooooooooooookko...",
    "....ovno.onnnennko.okoo....",
    "...oeeo..onnnenkko.oko.....",
    "...oeo...oanoooooo.ovno....",
    "....o....oano.......oeeo...",
    "..........oo.........oeo...",
    "......................o....",
], 27)
STEP_UP_2 = grid([
    "o.........................o",
    ".o.........ooooo.........o.",
    "..o.......oaaeano.......o..",
    "...ooo...onaaeanko...ooo...",
    "...oeeoooonaaeankooooano...",
    "...oeaannonaaeankoaannko...",
    "...oaannnonnaeankonnnkko...",
    "...oannkkonnnennkonnkkko...",
    "...onkoooooooooooooookko...",
    "....ooko.onnnennko.ovno....",
    ".....oko.onnnenkko..oeeo...",
    "....ovno.ooooooonko..oeo...",
    "...oeeo.......onko....o....",
    "...oeo.........oo..........",
    "....o......................",
], 27)

# --- Facing right --------------------------------------------------------------------------------------------------
# The front view turned a quarter: one wing above the helm and one below, the spikes sweeping back and out, the
# claws reaching forward and out, the ridge running front to back and the visor on the helm's front edge.

STAND_RIGHT = grid([
    "...o...............",
    "....o..............",
    ".....o.............",
    "......ooooooo.oo...",
    "......oaannkooeeo..",
    "......oannkkooveo..",
    ".......onnkookno...",
    ".......onkkoooo....",
    ".......onkko.......",
    "......oooooo.......",
    ".....oaaaano.......",
    "....onaaaano.......",
    "....onaaaavo.......",
    "....oeeeeevo.......",
    "....onnnnnvo.......",
    "....onnnnkko.......",
    ".....onkkkko.......",
    "......oooooo.......",
    ".......oaano.......",
    ".......oannoooo....",
    ".......oannookvo...",
    "......oeannkooneo..",
    "......oaannkooeeo..",
    "......ooooooo.oo...",
    ".....o.............",
    "....o..............",
    "...o...............",
], 19)
STEP_RIGHT = grid([         # the near claw reaches forward, the far one draws back; a foot shows ahead of the helm
    "...o...............",
    "....o..............",
    ".....o.............",
    "......ooooooooo....",
    "......oaannkoeeo...",
    "......oannkkoveo...",
    ".......onnkokno....",
    ".......onkkooo.....",
    ".......onkko.......",
    "......oooooo.......",
    ".....oaaaano.......",
    "....onaaaano.......",
    "....onaaaavo.......",
    "....oeeeeevooo.....",
    "....onnnnnvoano....",
    "....onnnnkkooo.....",
    ".....onkkkko.......",
    "......oooooo.......",
    ".......oaano.......",
    ".......oannooooo...",
    ".......oannokkkvo..",
    "......oeannkoooneo.",
    "......oaannko.oeeo.",
    "......ooooooo..oo..",
    ".....o.............",
    "....o..............",
    "...o...............",
], 19)
STEP_RIGHT_2 = grid([
    "...o...............",
    "....o..............",
    ".....o.............",
    "......ooooooo..oo..",
    "......oaannko.oeeo.",
    "......oannkkoooveo.",
    ".......onnkokkkno..",
    ".......onkkooooo...",
    ".......onkko.......",
    "......oooooo.......",
    ".....oaaaano.......",
    "....onaaaanooo.....",
    "....onaaaavoano....",
    "....oeeeeevooo.....",
    "....onnnnnvo.......",
    "....onnnnkko.......",
    ".....onkkkko.......",
    "......oooooo.......",
    ".......oaano.......",
    ".......oannooo.....",
    ".......oannokvo....",
    "......oeannkoneo...",
    "......oaannkoeeo...",
    "......ooooooooo....",
    ".....o.............",
    "....o..............",
    "...o...............",
], 19)



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
