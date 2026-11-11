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
    "L": "#C77DFF",                      # implant light
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


# --- Powering a console: both claws clamped on, and staying clamped, pulsing (heromedel, 2026-11-11) --------------
# Four frames that loop while he holds on: the clamps at rest, the wrist bands flashing pale and spreading, the light
# running down the claws, and the light landing at the tips in power green, so it works on any race's console.

def claw(right, pulse=0):
    body = "oeaao" if right else "oeeao"
    return [["onvno", body, ".oeo.", "..o.."],
            ["ovjvo", body, ".oeo.", "..o.."],
            ["onvno", "ovvvo", ".ovo.", "..o.."],
            ["onvno", body, ".ogo.", "..g.."]][pulse]


def side_claw_pulsing(near, pulse, reach):
    tones = ("e", "e", "a") if near else ("e", "a", "a")
    rows = [[".oo..", "on" + tones[0] + "o.", "kve" + tones[1] + "o", "on" + tones[2] + "o.", ".oo.."],
            [".oo..", "ov" + tones[0] + "o.", "kje" + tones[1] + "o", "ov" + tones[2] + "o.", ".oo.."],
            [".oo..", "onvo.", "kvvvo", "onvo.", ".oo.."],
            [".oo..", "on" + tones[0] + "o.", "kvegg", "on" + tones[2] + "o.", ".oo.."]][pulse]
    return [arm * reach + row for arm, row in zip(".oko.", rows)]


def power_down():
    # both shoulders forward, both arms a row longer and a pixel in, onto the console in front of him
    return [figure(left_plate=1, right_plate=1, left_arm=([ARM, ARM] + claw(False, pulse), 1, 1),
                   right_arm=([ARM, ARM] + claw(True, pulse), -1, 1)) for pulse in range(4)]


def power_up():
    # from behind, both claws rise from under the far edges of the plates, between the helm and the spikes
    frames = []
    for pulse in range(4):
        left = upside_down([ARM, ARM, ARM] + claw(False, pulse))
        right = upside_down([ARM, ARM, ARM] + claw(True, pulse))
        frames.append(figure(True, left_plate=-1, right_plate=-1, left_arm=(left, 1, -len(left) - 6),
                             right_arm=(right, -1, -len(right) - 6)))
    return frames


def power_right():
    return [side(1, 1, (side_claw_pulsing(False, pulse, 2), 0, 0), (side_claw_pulsing(True, pulse, 2), 0, 0))
            for pulse in range(4)]


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
# The one glimpse of a HalfMech out of the suit. The suit goes together empty, in his race's power colour toned down
# with a bright edge that fades (the drifter's clone, in Mecha purple): feet and torso, then plates and claws, then
# the helm. Then it stands in its own colours, unlit, and the pilot shows above the back of it for one frame, mid
# jump: purple hair, pale skin, dark clothes, one implant light, drawn in the top-down build at about half a Terran's
# size. Then she is in, the lights flash on, and he stands.

PILOT = [".o.......o.",
         "oSo.ooo.oSo",
         "okooHIHooko",
         "okkoHHHokko",
         ".oooSSTooo.",
         "...oknLo...",
         "....ooo...."]
PILOT_AT = (8, -1)                       # behind the helm, her head and raised fists clear of its top
CLONE_TONES = ("#24143A", "#37205A", "#4E2E80", "#6A42A6")       # power purple, muted, dark to light
CLONE_EDGES = ("#AA28EB", "#7C24B4", "#3A1560")                  # the edge on the first three frames, fading


def _colour(code):
    return tuple(int(code[i:i + 2], 16) for i in (1, 3, 5)) + (255,)


def toned(image, edge):
    """A frame in the muted clone tones, its outline in the edge colour."""
    out = Image.new("RGBA", image.size, (0, 0, 0, 0))
    line = rgba("o")
    for y in range(image.height):
        for x in range(image.width):
            pixel = image.getpixel((x, y))
            if not pixel[3]:
                continue
            light = (pixel[0] * 3 + pixel[1] * 4 + pixel[2]) // 8
            out.putpixel((x, y), _colour(edge) if pixel == line else _colour(CLONE_TONES[min(3, light // 30)]))
    return out


def recoloured(image, change):
    """A frame with some palette colours swapped, e.g. the lights put out or flashing."""
    swap = {rgba(old): rgba(new) for old, new in change.items()}
    out = image.copy()
    for y in range(image.height):
        for x in range(image.width):
            pixel = image.getpixel((x, y))
            if pixel in swap:
                out.putpixel((x, y), swap[pixel])
    return out


def clone():
    arms = [([ARM] + CLAW_LEFT, ARM_LEFT_AT), ([ARM] + CLAW_RIGHT, ARM_RIGHT_AT)]
    feet = [(FOOT_LEFT, FOOT_LEFT_AT), (FOOT_RIGHT, FOOT_RIGHT_AT)]
    plates = [(PLATE_LEFT, PLATE_LEFT_AT), (PLATE_RIGHT, PLATE_RIGHT_AT)]
    torso, helm = [(TORSO, TORSO_AT)], [(HELM, HELM_AT)]
    suit = arms + feet + plates + torso + helm
    unlit = {"v": "k", "q": "k"}
    pilot = frame([(PILOT, PILOT_AT)], AT)
    pilot.alpha_composite(recoloured(frame(suit, AT), unlit))
    return [toned(frame(feet + torso, AT), CLONE_EDGES[0]),
            toned(frame(arms + feet + plates + torso, AT), CLONE_EDGES[1]),
            toned(frame(suit, AT), CLONE_EDGES[2]),
            pilot,
            recoloured(frame(suit, AT), {"v": "j"}),
            figure()]


def portrait():
    return figure()
