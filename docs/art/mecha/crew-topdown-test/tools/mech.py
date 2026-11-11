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
    "w": "#F5EBFF",              # purple white, the hot core of his laser shot
    # the pilot, from heromedel's HalfMech pilot art (docs/art/mecha/pilot)
    "H": "#4A2C5E", "I": "#7A4A9A",      # hair, hair light
    "S": "#F0CDB8", "T": "#C99A8C",      # skin, skin shade
    "L": "#C77DFF",                      # implant light; also the bright purple of a power pulse
    "P": "#9370BF", "Q": "#7DB792",      # a pulse turning from purple to power green (docs/art/palette.md)
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


def joined(parts):
    """One part made of several, each (rows, (x, y)); later ones over earlier ones."""
    wide = max(x + len(row) for rows, (x, y) in parts for row in rows)
    high = max(y + len(rows) for rows, (x, y) in parts)
    grid = [["."] * wide for _ in range(high)]
    for rows, (x, y) in parts:
        for j, row in enumerate(rows):
            for i, code in enumerate(row):
                if code != ".":
                    grid[y + j][x + i] = code
    return ["".join(row) for row in grid]


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


# --- Aiming: three aims, straight, a little to his right, a little to his left; no flash -------------------------
# He has no pistol: he aims a claw, his right one, with the clamp open on the emitter between its prongs. The shoulder
# of that arm swings forward a row and the arm reaches three rows; aimed aside, the arm steps two pixels over on the
# way. Nothing else moves. Staging after the genre's sheets: three still aims a direction, the shot a sprite of its
# own.

def reaching(lean=0, length=3):
    """An arm reaching down the screen to an open claw; `lean` -1 or 1 steps it two pixels left or right."""
    steps = [0, 1, 1, 2][:length] + [2]
    places = [step * lean for step in steps]
    low = min(places)
    parts = [([ARM], (place - low, row)) for row, place in enumerate(places[:-1])]
    return joined(parts + [(CLAW_OPEN, (places[-1] - low, length))]), low


def aim_down(lean=0):
    arm, across = reaching(lean)                      # his right arm is on the viewer's left
    return figure(left_plate=1, left_arm=([], 0, 0), over=[(arm, moved(ARM_LEFT_AT, across, 1))])


def aim_up(lean=0):
    arm, across = reaching(-lean)                     # from behind, his right arm is on the viewer's right
    arm = upside_down(arm)                            # it reaches up the screen, out from under the plate's far edge
    # a pixel in from where it hangs, so it rises between the helm and the spike; its last row hides under the plate
    return figure(True, right_plate=-1, right_arm=(arm, across - 1, -len(arm) - 6))


def side_reaching(near, lean=0, length=3):
    """An arm reaching right to an open claw; `lean` -1 or 1 steps it two pixels up or down the screen."""
    steps = [0, 1, 1, 2][:length] + [2]
    places = [step * lean for step in steps]
    low = min(places)
    parts = [(["o", "k", "o"], (column, 1 + place - low)) for column, place in enumerate(places[:-1])]
    return joined(parts + [(side_claw(near, 0, True), (length, places[-1] - low))]), low


def aim_right(lean=0, far=False):
    """Facing right he aims his near arm, which is his right. `far` aims the other one: mirrored, that is his right
    arm when he faces left."""
    arm, down = side_reaching(not far, -lean if far else lean)
    if far:
        return side(far_plate=1, far_claw=(arm, 0, down))
    return side(near_plate=1, near_claw=(arm, 0, down))


def aims_down():
    return [aim_down(0), aim_down(-1), aim_down(1)]   # straight, to his right, to his left


def aims_up():
    return [aim_up(0), aim_up(-1), aim_up(1)]


def aims_right():
    return [aim_right(0), aim_right(1), aim_right(-1)]


def aims_left():
    return facing_left([aim_right(0, True), aim_right(1, True), aim_right(-1, True)])


def laser_shot():
    """His crew laser shot: the genre's bar, in Mecha purple with a hot core."""
    return frame([(["qvq"] + ["vwv"] * 9 + ["qvq"], (0, 0))], (16, 12))


# --- Powering a console: both claws clamp on and stay clamped, pulsing (heromedel, 2026-11-11) -------------------
# Eight frames. Two to clamp on: he reaches with the clamps open, then sets them on the console. Six that loop while
# he holds: the clamps closed; the wrist bands flare bright purple; the light runs down into the claws; at the tips
# it begins to turn; it lands, green, on the console; the green lingers there. So it works on any race's console.

POWER_FRAMES = 8


def power_claw(right, stage):
    body = "oeaao" if right else "oeeao"
    return [CLAW_OPEN,
            CLAW_OPEN,
            ["onvno", body, ".oeo.", "..o.."],
            ["ovLvo", body, ".oeo.", "..o.."],
            ["onvno", "ovLvo", ".ovo.", "..o.."],
            ["onvno", body, ".oPo.", "..o.."],
            ["onvno", body, ".oQo.", "..g.."],
            ["onvno", body, ".oeo.", "..g.."]][stage]


def side_power_claw(near, stage, reach):
    if stage < 2:
        return side_claw(near, reach, True)
    a, b, c = ("e", "e", "a") if near else ("e", "a", "a")
    rows = {2: [".oo..", "on" + a + "o.", "kve" + b + "o", "on" + c + "o.", ".oo.."],
            3: [".oo..", "ov" + a + "o.", "kLe" + b + "o", "ov" + c + "o.", ".oo.."],
            4: [".oo..", "onvo.", "kvLvo", "onvo.", ".oo.."],
            5: [".oo..", "on" + a + "o.", "kvePo", "on" + c + "o.", ".oo.."],
            6: [".oo..", "on" + a + "o.", "kveQg", "on" + c + "o.", ".oo.."],
            7: [".oo..", "on" + a + "o.", "kve" + b + "g", "on" + c + "o.", ".oo.."]}[stage]
    return [arm * reach + row for arm, row in zip(".oko.", rows)]


def power_down():
    frames = []
    for stage in range(POWER_FRAMES):
        reach, across = ([ARM], 0) if stage == 0 else ([ARM, ARM], 1)      # then a row longer and a pixel in
        frames.append(figure(left_plate=1, right_plate=1, left_arm=(reach + power_claw(False, stage), across, 1),
                             right_arm=(reach + power_claw(True, stage), -across, 1)))
    return frames


def power_up():
    # from behind, both claws rise from under the far edges of the plates, between the helm and the spikes
    frames = []
    for stage in range(POWER_FRAMES):
        reach, across = ([ARM, ARM], 0) if stage == 0 else ([ARM, ARM, ARM], 1)
        left = upside_down(reach + power_claw(False, stage))
        right = upside_down(reach + power_claw(True, stage))
        frames.append(figure(True, left_plate=-1, right_plate=-1, left_arm=(left, across, -len(left) - 6),
                             right_arm=(right, -across, -len(right) - 6)))
    return frames


def power_right():
    return [side(1, 1, (side_power_claw(False, stage, 1 if stage == 0 else 2), 0, 0),
                 (side_power_claw(True, stage, 1 if stage == 0 else 2), 0, 0)) for stage in range(POWER_FRAMES)]


def power_left():
    return facing_left(power_right())


# --- Repairing: the clamp claw and no wrench (heromedel, 2026-11-11) -----------------------------------------------
# Side on, four frames: the near claw opens on the work, closes, turns it a pixel while the far claw steadies, and
# comes back.

def repair():
    reach = lambda rows: [arm * 2 + row for arm, row in zip(".oko.", rows)]
    opened, closed = side_claw(True, 2, True), side_claw(True, 2)
    return [side(0, 1, None, (opened, 0, 0)),
            side(0, 1, None, (closed, 0, 0)),
            side(1, 1, (side_claw(False, 1), 0, 0), (closed, 0, 1)),
            side(0, 1, None, (closed, 0, 0))]


# --- The clone bay: the suit is put together, and its pilot jumps in (heromedel, 2026-11-11) ----------------------
# The one glimpse of a HalfMech out of the suit. Ten frames. The suit is built, not grown: it goes together in its
# own colours, unlit, a piece at a time (feet and torso, shoulder plates, arms and claws, helm), and each piece wears
# a bright purple edge only on the frame it arrives. Then the pilot comes up behind it on the ground, the top of her
# head showing over the helm, dips, jumps clear of it with her ponytail flying, and drops in. Then the lights come up, dim purple first, and he stands.
# She is a girl (heromedel): long hair in a ponytail is what says so at this size. Her colours are those of
# heromedel's HalfMech pilot art: purple hair, pale skin, dark clothes, one implant light.

PILOT = [".......oo..",
         "......oIHo.",          # her ponytail, swinging out to one side
         ".....oIHo..",
         "...oooLoo..",          # a bright tie where it leaves her head
         "..oHHIHHo..",
         "..oHIHHHo..",
         ".ooTSSSToo.",
         ".oSknnLkSo.",          # narrow shoulders, a hand at each side, her implant light
         "..ooooooo.."]
PILOT_HEAD = PILOT[:6]                        # all that shows of her over the helm when she is behind the suit
# Where she is, frame by frame, behind the helm: walking up on the ground a little to one side, the top of her head
# over the helm; in place and dipping to jump; in the air, all of her clear of the helm; dropping in, only her
# ponytail left.
PILOT_WALKS_UP, PILOT_DIPS, PILOT_JUMPS, PILOT_DROPS_IN = (6, -1), (8, 0), (8, -4), (8, 2)


def unlit(rows):
    return [row.replace("v", "k").replace("q", "k") for row in rows]


def arriving(rows):
    return [row.replace("o", "v") for row in unlit(rows)]


def recoloured(image, change):
    """A frame with some palette colours swapped, e.g. the lights dim."""
    swap = {rgba(old): rgba(new) for old, new in change.items()}
    out = image.copy()
    for y in range(image.height):
        for x in range(image.width):
            pixel = image.getpixel((x, y))
            if pixel in swap:
                out.putpixel((x, y), swap[pixel])
    return out


def clone():
    pieces = {"arms": [([ARM] + CLAW_LEFT, ARM_LEFT_AT), ([ARM] + CLAW_RIGHT, ARM_RIGHT_AT)],
              "feet": [(FOOT_LEFT, FOOT_LEFT_AT), (FOOT_RIGHT, FOOT_RIGHT_AT)],
              "plates": [(PLATE_LEFT, PLATE_LEFT_AT), (PLATE_RIGHT, PLATE_RIGHT_AT)],
              "torso": [(TORSO, TORSO_AT)],
              "helm": [(HELM, HELM_AT)]}
    order = ("arms", "feet", "plates", "torso", "helm")          # back to front, as in every other frame

    def built(have, new=(), behind=()):
        parts = list(behind)
        for name in order:
            if name in new:
                parts += [(arriving(rows), at) for rows, at in pieces[name]]
            elif name in have:
                parts += [(unlit(rows), at) for rows, at in pieces[name]]
        return frame(parts, AT)

    whole = order
    return [built((), ("feet", "torso")),
            built(("feet", "torso"), ("plates",)),
            built(("feet", "torso", "plates"), ("arms",)),
            built(("feet", "torso", "plates", "arms"), ("helm",)),
            built(whole, behind=[(PILOT_HEAD, PILOT_WALKS_UP)]),
            built(whole, behind=[(PILOT_HEAD, PILOT_DIPS)]),
            built(whole, behind=[(PILOT, PILOT_JUMPS)]),
            built(whole, behind=[(PILOT_HEAD, PILOT_DROPS_IN)]),
            recoloured(figure(), {"v": "q"}),
            figure()]


def portrait():
    return figure()
