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
# edge, a shoulder plate each side (they are shoulders, not wings), a thick spike sweeping up and out of each plate's
# outer corner, an arm straight down from under each plate to a grey powered clamp claw with a purple band, two chest
# lights on a torso four rows deep, two pointed feet. The spike leans out and the claw hangs straight, so the two never read as one stacked
# piece.

STAND_DOWN = grid([
    "oo.......................oo",
    "oeo........ooooo........ono",
    ".oeo......oaaeano......ono.",
    "..oeoo...onaaeanko...oono..",
    "...oeaoooonaaeankooooano...",
    "...oeaannonaaeankoaannko...",
    "...oaannnonnaeankonnnkko...",
    "...oannkkonnvvvnkonnkkko...",
    "...ooooooooooooooooooooo...",
    "....oko..onnvnvnko..oko....",
    "...onvno.onnnnnkko.onvno...",
    "...oeeao.onnnnnkko.oeaao...",
    "....oeo..onnnnkkko..oeo....",
    ".....o...oanooonko...o.....",
    "..........oo...oo..........",
], 27)
STEP_DOWN = grid([         # the claw on the viewer's left swings forward and hangs lower, the other lifts; a foot steps
    "oo.......................oo",
    "oeo........ooooo........ono",
    ".oeo......oaaeano......ono.",
    "..oeoo...onaaeanko...oono..",
    "...oeaoooonaaeankooooano...",
    "...oeaannonaaeankoaannko...",
    "...oaannnonnaeankonnnkko...",
    "...oannkkonnvvvnkonnkkko...",
    "...ooooooooooooooooooooo...",
    "....oko..onnvnvnko.onvno...",
    "....oko..onnnnnkko.oeaao...",
    "...onvno.onnnnnkko..oeo....",
    "...oeeao.onnnnkkko...o.....",
    "....oeo..ooooooonko........",
    ".....o........onko.........",
    "...............oo..........",
], 27)
STEP_DOWN_2 = grid([
    "oo.......................oo",
    "oeo........ooooo........ono",
    ".oeo......oaaeano......ono.",
    "..oeoo...onaaeanko...oono..",
    "...oeaoooonaaeankooooano...",
    "...oeaannonaaeankoaannko...",
    "...oaannnonnaeankonnnkko...",
    "...oannkkonnvvvnkonnkkko...",
    "...ooooooooooooooooooooo...",
    "...onvno.onnvnvnko..oko....",
    "...oeeao.onnnnnkko..oko....",
    "....oeo..onnnnnkko.onvno...",
    ".....o...onnnnkkko.oeaao...",
    ".........oanoooooo..oeo....",
    ".........oano........o.....",
    "..........oo...............",
], 27)

# --- Facing away ---------------------------------------------------------------------------------------------------
# No visor and no chest lights: the ridge runs the whole helm and down the back plate. The claws keep their bands.

STAND_UP = grid([
    "oo.......................oo",
    "oeo........ooooo........ono",
    ".oeo......oaaeano......ono.",
    "..oeoo...onaaeanko...oono..",
    "...oeaoooonaaeankooooano...",
    "...oeaannonaaeankoaannko...",
    "...oaannnonnaeankonnnkko...",
    "...oannkkonnnennkonnkkko...",
    "...ooooooooooooooooooooo...",
    "....oko..onnnennko..oko....",
    "...onvno.onnnenkko.onvno...",
    "...oeeao.onnnenkko.oeaao...",
    "....oeo..onnnekkko..oeo....",
    ".....o...oanooonko...o.....",
    "..........oo...oo..........",
], 27)
STEP_UP = grid([
    "oo.......................oo",
    "oeo........ooooo........ono",
    ".oeo......oaaeano......ono.",
    "..oeoo...onaaeanko...oono..",
    "...oeaoooonaaeankooooano...",
    "...oeaannonaaeankoaannko...",
    "...oaannnonnaeankonnnkko...",
    "...oannkkonnnennkonnkkko...",
    "...ooooooooooooooooooooo...",
    "...onvno.onnnennko..oko....",
    "...oeeao.onnnenkko..oko....",
    "....oeo..onnnenkko.onvno...",
    ".....o...onnnekkko.oeaao...",
    ".........oanoooooo..oeo....",
    ".........oano........o.....",
    "..........oo...............",
], 27)
STEP_UP_2 = grid([
    "oo.......................oo",
    "oeo........ooooo........ono",
    ".oeo......oaaeano......ono.",
    "..oeoo...onaaeanko...oono..",
    "...oeaoooonaaeankooooano...",
    "...oeaannonaaeankoaannko...",
    "...oaannnonnaeankonnnkko...",
    "...oannkkonnnennkonnkkko...",
    "...ooooooooooooooooooooo...",
    "....oko..onnnennko.onvno...",
    "....oko..onnnenkko.oeaao...",
    "...onvno.onnnenkko..oeo....",
    "...oeeao.onnnekkko...o.....",
    "....oeo..ooooooonko........",
    ".....o........onko.........",
    "...............oo..........",
], 27)

# --- Facing right --------------------------------------------------------------------------------------------------
# The front view turned a quarter: one shoulder plate above the helm and one below, the spikes sweeping back and out,
# the claws pointing straight ahead, the ridge running front to back and the visor on the helm's front edge.

STAND_RIGHT = grid([         # both feet show a little ahead of the helm, so he is not so thin (heromedel, 2026-11-11)
    "...oo..............",
    "...oao.............",
    "....oao............",
    ".....ooooooo.oo....",
    "......oaannooneo...",
    "......oannkokveao..",
    ".......onnkoonao...",
    ".......onkko.oo....",
    ".......onkko.......",
    "......oooooo.......",
    ".....oaaaanooo.....",
    "....onaaaanoao.....",
    "....onaaaavono.....",
    "....oeeeeevooo.....",
    "....onnnnnvono.....",
    "....onnnnkkoko.....",
    ".....onkkkkooo.....",
    "......oooooo.......",
    ".......oaano.......",
    ".......oaano.oo....",
    ".......oannooneo...",
    "......oeannokveeo..",
    "......oaankoonao...",
    ".....ooooooo.oo....",
    "....oao............",
    "...oao.............",
    "...oo..............",
], 19)
STEP_RIGHT = grid([         # the near claw reaches forward, the far one draws back; the near foot steps ahead
    "...oo..............",
    "...oao.............",
    "....oao............",
    ".....ooooooooo.....",
    "......oaannoneo....",
    "......oannkkveao...",
    ".......onnkonao....",
    ".......onkkooo.....",
    ".......onkko.......",
    "......oooooo.......",
    ".....oaaaanooo.....",
    "....onaaaanoao.....",
    "....onaaaavono.....",
    "....oeeeeevoooo....",
    "....onnnnnvonno....",
    "....onnnnkkokko....",
    ".....onkkkkoooo....",
    "......oooooo.......",
    ".......oaano.......",
    ".......oaano..oo...",
    ".......oannoooneo..",
    "......oeannokkveeo.",
    "......oaankooonao..",
    ".....ooooooo..oo...",
    "....oao............",
    "...oao.............",
    "...oo..............",
], 19)
STEP_RIGHT_2 = grid([
    "...oo..............",
    "...oao.............",
    "....oao............",
    ".....ooooooo..oo...",
    "......oaannoooneo..",
    "......oannkokkveao.",
    ".......onnkooonao..",
    ".......onkko..oo...",
    ".......onkko.......",
    "......oooooo.......",
    ".....oaaaanoooo....",
    "....onaaaanoaao....",
    "....onaaaavonno....",
    "....oeeeeevoooo....",
    "....onnnnnvono.....",
    "....onnnnkkoko.....",
    ".....onkkkkooo.....",
    "......oooooo.......",
    ".......oaano.......",
    ".......oaanooo.....",
    ".......oannoneo....",
    "......oeannkveeo...",
    "......oaankonao....",
    ".....ooooooooo.....",
    "....oao............",
    "...oao.............",
    "...oo..............",
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
