"""A HalfMech in its suit seen from almost straight above, at the crew size of the top-down Terran drifter.

The design follows heromedel's own top-down drawing of the suit (reference/), brought down to game size, in the
colours of the Mecha crew palette. He is built from parts: a helm, a torso, two shoulder plates with their spikes,
two arms ending in clamp claws, two feet. Every part is placed by hand as text, one character a pixel, and keeps its
shape; a frame is the same parts set at different places, drawn back to front. So a change to one part carries into
every frame.
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
    "j": "#EBE1FA",              # purple pale
    "g": "#66FF66",              # power green, where his power reaches another race's console
}


def rgba(code):
    hexa = PALETTE[code]
    return tuple(int(hexa[i:i + 2], 16) for i in (1, 3, 5)) + (255,)


def frame(parts, at):
    """A 35 by 35 frame from (rows, (x, y)) parts, later parts over earlier ones, set into the frame at `at`."""
    image = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
    for rows, (x, y) in parts:
        for j, row in enumerate(rows):
            for i, code in enumerate(row):
                if code != ".":
                    image.putpixel((at[0] + x + i, at[1] + y + j), rgba(code))
    return image


def facing_left(frames):
    return [image.transpose(Image.FLIP_LEFT_RIGHT) for image in frames]


# --- Parts, facing the camera or away ----------------------------------------------------------------------------
# A boxy helm with a pale crest that comes to a slight point at the top and a short visor bar on its front edge; a
# shoulder plate each side (shoulders, not wings) with a thick spike sweeping up and out of its outer corner; an arm
# straight down from under each plate to a grey powered clamp claw with a purple band; a torso four rows deep whose
# two lights are the eyes of a face barely hinted (a mouth one tone darker than the armour); two feet.
# The spike leans out and the claw hangs straight, so the two never read as one stacked piece.

AT = (4, 6)                       # where the figure's own corner sits in the frame, for these views

HELM = ["....o....", "..ooeoo..", ".oaaeano.", "oaaaeanko", "onaaeanko", "onaaennko", "onnaenkko", "onnvvvkko",
        "ooooooooo"]
HELM_BACK = HELM[:7] + ["onnnenkko", "ooooooooo"]          # no visor: the crest runs the whole helm
TORSO = ["onnvnvnko", "onnnnnnko", "onnkkknko", "onnnnnkko", ".ooooooo."]
TORSO_BACK = ["onnnnnkko", "onnnnkkko", "onnnkkkko", "onnkkkkko", ".ooooooo."]     # plain dark, no pale line
PLATE_LEFT = ["oo.......", "oeo......", ".oeo.....", "..oeoo...", "...oeaooo", "...oeaann", "...oaannn", "...oannkk",
              "...oooooo"]
PLATE_RIGHT = [".......oo", "......ono", ".....ono.", "...oono..", "oooano...", "aannko...", "nnnkko...", "nnkkko...",
               "oooooo..."]
ARM = ".oko."                                            # one row of arm; more rows make a longer reach
CLAW_LEFT = ["onvno", "oeeao", ".oeo.", "..o.."]         # band, claw, tip: closed
CLAW_RIGHT = ["onvno", "oeaao", ".oeo.", "..o.."]
CLAW_OPEN = ["onvno", "oeqeo", "oe.eo", ".o.o."]         # the clamp open, its emitter between the two prongs
FOOT_LEFT = ["oano", "onko", ".oo."]
FOOT_RIGHT = ["onno", "onko", ".oo."]
LEG = "okko"                                             # a dark row of leg above a foot that swings forward
HELM_AT, TORSO_AT = (9, 4), (9, 13)
PLATE_LEFT_AT, PLATE_RIGHT_AT = (0, 4), (18, 4)
ARM_LEFT_AT, ARM_RIGHT_AT = (3, 13), (19, 13)
FOOT_LEFT_AT, FOOT_RIGHT_AT = (9, 18), (14, 18)


def moved(at, across=0, down=0):
    return (at[0] + across, at[1] + down)


def upside_down(rows):
    return rows[::-1]


def figure(back=False, left_plate=0, right_plate=0, left_arm=None, right_arm=None, left_foot=None, right_foot=None,
           over=()):
    """The front or back view. A plate is given by how many rows it swings forward (down the screen); an arm or a
    foot by (rows, across, down) from where it rests. `over` holds parts drawn last, in front of everything."""
    left_arm = left_arm or ([ARM] + CLAW_LEFT, 0, 0)
    right_arm = right_arm or ([ARM] + CLAW_RIGHT, 0, 0)
    left_foot = left_foot or (FOOT_LEFT, 0, 0)
    right_foot = right_foot or (FOOT_RIGHT, 0, 0)
    parts = [(left_arm[0], moved(ARM_LEFT_AT, left_arm[1], left_arm[2])),
             (right_arm[0], moved(ARM_RIGHT_AT, right_arm[1], right_arm[2])),
             (left_foot[0], moved(FOOT_LEFT_AT, left_foot[1], left_foot[2])),
             (right_foot[0], moved(FOOT_RIGHT_AT, right_foot[1], right_foot[2])),
             (PLATE_LEFT, moved(PLATE_LEFT_AT, 0, left_plate)),
             (PLATE_RIGHT, moved(PLATE_RIGHT_AT, 0, right_plate)),
             (TORSO_BACK if back else TORSO, TORSO_AT),
             (HELM_BACK if back else HELM, HELM_AT)]
    return frame(parts + list(over), AT)


# --- Walking, facing the camera or away ---------------------------------------------------------------------------
# The limbs swing, they do not piston (heromedel, 2026-11-11). A shoulder plate swings a row forward and takes its
# spike and claw with it; the claw hangs a row lower on a longer arm and a pixel in. The other plate swings a row
# back, and its claw tucks up under it, a pixel out. The foot opposite the forward arm swings forward on a dark pixel
# of leg; the other draws back under the torso, its top row hidden.

def step(left_forward, back=False):
    swung_back = lambda foot: (["...."] + foot[1:], 0, -1)
    if left_forward:              # the arm on the viewer's left
        return figure(back, 1, -1, ([ARM, ARM] + CLAW_LEFT, 1, 1), ([ARM] + CLAW_RIGHT, 1, -2),
                      swung_back(FOOT_LEFT), ([LEG] + FOOT_RIGHT, -1, 0))
    return figure(back, -1, 1, ([ARM] + CLAW_LEFT, -1, -2), ([ARM, ARM] + CLAW_RIGHT, -1, 1),
                  ([LEG] + FOOT_LEFT, 1, 0), swung_back(FOOT_RIGHT))


def walk_down():
    return [figure(), step(True), figure(), step(False)]


def walk_up():
    return [figure(True), step(False, True), figure(True), step(True, True)]


# --- Parts, facing right -------------------------------------------------------------------------------------------
# The front view turned a quarter, but not strictly (heromedel, 2026-11-11): his left shoulder, the far one at the
# top, is a row shorter where it meets the helm; his feet show ahead of the helm, toward the near side, so he is not
# so thin; the crest, the visor and the crest's point sit a row above the helm's middle. The spikes sweep back and
# out and the claws point straight ahead.

SIDE_AT = (8, 4)

SIDE_FAR = ["...oo....", "...oao...", "....oao..", ".....ooooooo", "......oaanno", "......oannko", ".......onnko",
            ".......onkko"]
SIDE_HELM = ["...oooooo", "..oaaaano", ".onaaaavo", "oeeeeeevo", ".onnnnnvo", ".onnnnnko", ".onnnnkko", "..onkkkko",
             "...oooooo"]
SIDE_NEAR = [".......oaano", ".......oaano", ".......oanno", "......oeanno", "......oaanko", ".....ooooooo",
             "....oao", "...oao", "...oo"]
SIDE_FAR_AT, SIDE_HELM_AT, SIDE_NEAR_AT = (0, 1), (3, 9), (0, 18)
SIDE_FAR_CLAW_AT, SIDE_NEAR_CLAW_AT = (12, 4), (12, 19)
SIDE_FAR_FOOT_AT, SIDE_NEAR_FOOT_AT = (12, 11), (12, 15)
SIDE_FAR_FEET = {1: ("a", "n"), 2: ("an", "nn"), 3: ("kan", "knn")}      # by how far the foot shows; k is leg
SIDE_NEAR_FEET = {1: ("n", "k"), 2: ("nn", "nk"), 3: ("knn", "knk")}


def side_claw(near, reach=0, clamp_open=False):
    """A claw pointing right: arm, band, claw, tip. `reach` adds pixels of arm."""
    tones = ("e", "e", "a") if near else ("e", "a", "a")
    if clamp_open:
        rows = [".ooo.", "on" + tones[0] * 2 + "o", "kvq..", "on" + tones[2] * 2 + "o", ".ooo."]
    else:
        rows = [".oo..", "on" + tones[0] + "o.", "kve" + tones[1] + "o", "on" + tones[2] + "o.", ".oo.."]
    return [arm * reach + row for arm, row in zip(".oko.", rows)]


def side_foot(tones):
    deep = len(tones[0])
    return ["o" * (deep + 1), tones[0] + "o", tones[1] + "o", "o" * (deep + 1)]


def side(far_plate=0, near_plate=0, far_claw=None, near_claw=None, far_foot=2, near_foot=2):
    """The right-facing view. A plate is given by how many pixels it swings forward (to the right); a claw by
    (rows, across, down) from where it rests; a foot by how far it shows."""
    far_claw = far_claw or (side_claw(False), 0, 0)
    near_claw = near_claw or (side_claw(True), 0, 0)
    parts = [(far_claw[0], moved(SIDE_FAR_CLAW_AT, far_claw[1], far_claw[2])),
             (near_claw[0], moved(SIDE_NEAR_CLAW_AT, near_claw[1], near_claw[2])),
             (side_foot(SIDE_FAR_FEET[far_foot]), SIDE_FAR_FOOT_AT),
             (side_foot(SIDE_NEAR_FEET[near_foot]), SIDE_NEAR_FOOT_AT),
             (SIDE_FAR, moved(SIDE_FAR_AT, far_plate)),
             (SIDE_NEAR, moved(SIDE_NEAR_AT, near_plate)),
             (SIDE_HELM, SIDE_HELM_AT)]
    return frame(parts, SIDE_AT)


def walk_right():
    # the near shoulder and claw swing forward and the far ones back, the back claw tucked under its plate with only
    # its tip showing; the far foot swings forward on its leg and the near foot draws in; then the other way round
    return [side(),
            side(-1, 1, (side_claw(False), -3, 0), (side_claw(True, 1), 1, 0), 3, 1),
            side(),
            side(1, -1, (side_claw(False, 1), 1, 0), (side_claw(True), -3, 0), 1, 3)]


def walk_left():
    return facing_left(walk_right())
