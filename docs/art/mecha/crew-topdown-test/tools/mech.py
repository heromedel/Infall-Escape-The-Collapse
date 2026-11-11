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
DOWN_AT = (4, 9)                 # where a camera-facing or away-facing grid (27 wide) sits in the frame
SIDE_AT = (7, 4)                 # where a right-facing grid (21 wide) sits


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

# How he walks (heromedel, 2026-11-11: the limbs must swing, not piston). Every part keeps its shape and moves as a
# piece. A shoulder plate swings a row forward and takes its spike and claw with it; the claw hangs a row lower on a
# longer arm and a pixel in. The other plate swings a row back, and its claw tucks up under it, a pixel out. The foot
# opposite the forward arm swings forward a row on a dark pixel of leg; the other draws back under the torso.

STAND_DOWN = grid([         # the top row is spare: a shoulder that swings back lifts its spike into it
    "...........................",
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
    ".....o....ooooooo....o.....",
    ".........oano.onno.........",
    ".........onko.onko.........",
    "..........oo...oo..........",
], 27)
STEP_DOWN = grid([         # the shoulder on the viewer's left swings forward, the other back; the opposite foot swings forward
    ".........................oo",
    "........................ono",
    "oo.........ooooo.......ono.",
    "oeo.......oaaeano....oono..",
    ".oeo.....onaaeankooooano...",
    "..oeoo...onaaeankoaannko...",
    "...oeaoooonaaeankonnnkko...",
    "...oeaannonnaeankonnkkko...",
    "...oaannnonnvvvnkooooooo...",
    "...oannkkooooooooo..onvno..",
    "...ooooooonnvnvnko..oeaao..",
    ".....oko.onnnnnkko...oeo...",
    ".....oko.onnnnnkko....o....",
    "....onvnoonnnnkkko.........",
    "....oeeao.ooooooo..........",
    ".....oeo.onkookko..........",
    "......o...oo.onno..........",
    ".............onko..........",
    "..............oo...........",
], 27)
STEP_DOWN_2 = grid([
    "oo.........................",
    "oeo........................",
    ".oeo.......ooooo.........oo",
    "..oeoo....oaaeano.......ono",
    "...oeaoooonaaeanko.....ono.",
    "...oeaannonaaeanko...oono..",
    "...oaannnonaaeankooooano...",
    "...oannkkonnaeankoaannko...",
    "...ooooooonnvvvnkonnnkko...",
    "..onvno..ooooooooonnkkko...",
    "..oeeao..onnvnvnkooooooo...",
    "...oeo...onnnnnkko.oko.....",
    "....o....onnnnnkko.oko.....",
    ".........onnnnkkkoonvno....",
    "..........ooooooo.oeaao....",
    "..........okkoonko.oeo.....",
    "..........oano.oo...o......",
    "..........onko.............",
    "...........oo..............",
], 27)

# --- Facing away ---------------------------------------------------------------------------------------------------
# No visor and no chest lights: the ridge runs the whole helm and down the back plate. The claws keep their bands.

STAND_UP = grid([
    "...........................",
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
    ".....o....ooooooo....o.....",
    ".........oano.onno.........",
    ".........onko.onko.........",
    "..........oo...oo..........",
], 27)
STEP_UP = grid([
    "oo.........................",
    "oeo........................",
    ".oeo.......ooooo.........oo",
    "..oeoo....oaaeano.......ono",
    "...oeaoooonaaeanko.....ono.",
    "...oeaannonaaeanko...oono..",
    "...oaannnonaaeankooooano...",
    "...oannkkonnaeankoaannko...",
    "...ooooooonnnennkonnnkko...",
    "..onvno..ooooooooonnkkko...",
    "..oeeao..onnnennkooooooo...",
    "...oeo...onnnenkko.oko.....",
    "....o....onnnenkko.oko.....",
    ".........onnnekkkoonvno....",
    "..........ooooooo.oeaao....",
    "..........okkoonko.oeo.....",
    "..........oano.oo...o......",
    "..........onko.............",
    "...........oo..............",
], 27)
STEP_UP_2 = grid([
    ".........................oo",
    "........................ono",
    "oo.........ooooo.......ono.",
    "oeo.......oaaeano....oono..",
    ".oeo.....onaaeankooooano...",
    "..oeoo...onaaeankoaannko...",
    "...oeaoooonaaeankonnnkko...",
    "...oeaannonnaeankonnkkko...",
    "...oaannnonnnennkooooooo...",
    "...oannkkooooooooo..onvno..",
    "...ooooooonnnennko..oeaao..",
    ".....oko.onnnenkko...oeo...",
    ".....oko.onnnenkko....o....",
    "....onvnoonnnekkko.........",
    "....oeeao.ooooooo..........",
    ".....oeo.onkookko..........",
    "......o...oo.onno..........",
    ".............onko..........",
    "..............oo...........",
], 27)

# --- Facing right --------------------------------------------------------------------------------------------------
# The front view turned a quarter: one shoulder plate above the helm and one below, the spikes sweeping back and out,
# the claws pointing straight ahead, the ridge running front to back and the visor on the helm's front edge.

STAND_RIGHT = grid([         # both feet show ahead of the helm, so he is not so thin (heromedel, 2026-11-11)
    "....oo...............",
    "....oao..............",
    ".....oao.............",
    "......ooooooo.oo.....",
    ".......oaannooneo....",
    ".......oannkokveao...",
    "........onnkoonao....",
    "........onkko.oo.....",
    "........onkko........",
    ".......oooooo........",
    "......oaaaanoooo.....",
    ".....onaaaanoano.....",
    ".....onaaaavonno.....",
    ".....oeeeeevoooo.....",
    ".....onnnnnvonno.....",
    ".....onnnnkkonko.....",
    "......onkkkkoooo.....",
    ".......oooooo........",
    "........oaano........",
    "........oaano.oo.....",
    "........oannooneo....",
    ".......oeannokveeo...",
    ".......oaankoonao....",
    "......ooooooo.oo.....",
    ".....oao.............",
    "....oao..............",
    "....oo...............",
], 21)
STEP_RIGHT = grid([         # the near shoulder and claw swing forward, the far ones back; the far foot swings forward
    "...oo................",
    "...oao...............",
    "....oao..............",
    ".....oooooooo........",
    "......oaannoeo.......",
    "......oannkoeao......",
    ".......onnkoao.......",
    ".......onkkoo........",
    ".......onkko.........",
    ".......oooooo........",
    "......oaaaanooooo....",
    ".....onaaaanokano....",
    ".....onaaaavoknno....",
    ".....oeeeeevooooo....",
    ".....onnnnnvono......",
    ".....onnnnkkoko......",
    "......onkkkkooo......",
    ".......oooooo........",
    ".........oaano.......",
    ".........oaano..oo...",
    ".........oannoooneo..",
    "........oeannokkveeo.",
    "........oaankooonao..",
    ".......ooooooo..oo...",
    "......oao............",
    ".....oao.............",
    ".....oo..............",
], 21)
STEP_RIGHT_2 = grid([
    ".....oo..............",
    ".....oao.............",
    "......oao............",
    ".......ooooooo..oo...",
    "........oaannoooneo..",
    "........oannkokkveao.",
    ".........onnkooonao..",
    ".........onkko..oo...",
    ".........onkko.......",
    ".......oooooo........",
    "......oaaaanooo......",
    ".....onaaaanoao......",
    ".....onaaaavono......",
    ".....oeeeeevooooo....",
    ".....onnnnnvoknno....",
    ".....onnnnkkoknko....",
    "......onkkkkooooo....",
    ".......oooooo........",
    ".......oaano.........",
    ".......oaanoo........",
    ".......oannoeo.......",
    "......oeannoeeo......",
    "......oaankoao.......",
    ".....oooooooo........",
    "....oao..............",
    "...oao...............",
    "...oo................",
], 21)


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
