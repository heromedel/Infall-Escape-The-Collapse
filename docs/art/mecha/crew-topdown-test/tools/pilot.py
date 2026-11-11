"""The HalfMech pilot, out of her suit, seen from almost straight above: a sprite of her own.

She is seen only in the clone bay, where she runs from the bay to her suit, jumps above its back and drops in
(heromedel, 2026-11-11). The game moves her, so she has a run in the four directions and a jump. She is drawn like the
top-down Terran drifter at about half his size, in the colours of heromedel's HalfMech pilot art
(docs/art/mecha/pilot). A ponytail from a bright tie is what says "girl" at this size.
"""
import mech
from mech import frame, facing_left

AT = (12, 11)                    # where her own corner sits in the frame

# --- Facing the camera -------------------------------------------------------------------------------------------
HEAD = [".......oo..",
        "......oIHo.",            # her ponytail, swinging out to one side
        ".....oIHo..",
        "...oooLoo..",            # a bright tie where it leaves her head
        "..oHHIHHo..",
        "..oHIHHHo..",
        ".ooTSSSToo."]
BODY = [".oSknnLkSo.",            # narrow shoulders, a hand at each side, her implant light
        "..oknnnko.."]
LEGS = ["...oSoSo...",            # bare legs
        "...okoko...",            # and her feet
        "....o.o...."]
# Running: one hand swings back out of sight and the leg under it reaches a row further; the other leg draws up.
BODY_RUN = [".ooknnLkSo.", "..oknnnko.."]
BODY_RUN_OTHER = [".oSknnLkoo.", "..oknnnko.."]       # the other hand back; her implant light stays where it is
LEGS_RUN = ["...oSoko...", "...oSooo...", "...oko.....", "....o......"]
LEGS_TUCKED = ["...okoko...", "....o.o...."]            # in the air, her legs drawn up

# --- Facing away -------------------------------------------------------------------------------------------------
# From behind there is no face: her hair, the tie at her nape and the ponytail down her back.
BACK_HEAD = ["...ooooo...", "..oHHIHHo..", "..oHIHHHo..", ".ooooLoooo."]
BACK_BODY = [".oSknIHkSo.", "..oknHnko.."]
BACK_BODY_RUN = [".ooknIHkSo.", "..oknHnko.."]
BACK_BODY_RUN_OTHER = [".oSknIHkoo.", "..oknHnko.."]

# --- Facing right ------------------------------------------------------------------------------------------------
# One shoulder above her head and one below; the ponytail trails behind her; a foot shows ahead when she runs.
SIDE = ["....ooo....",
        "...oknko...",            # far shoulder
        "...oooooo..",
        ".oooHIHTo..",            # her head is four rows across: a row of hair wider toward the far side
        "oIHLHHHSo..",            # ponytail, tie, hair, face
        ".oooHHHTo..",
        "...oHIHSo..",
        "...oooooo..",
        "...oknnko..",            # near shoulder
        "...oknLSo..",            # implant light, hand
        "....oooo..."]
SIDE_RUN_NEAR_FOOT = [(9, 7, "oo"), (9, 8, "Sko"), (9, 9, "oo")]      # the near foot reaches ahead of her
SIDE_RUN_FAR_FOOT = [(9, 5, "oo"), (9, 6, "Sko"), (9, 7, "oo")]       # then the far one
# Her arms swing against her legs: the arm on the other side from the leading foot comes forward, a hand showing
# ahead of its shoulder, and the arm on the same side goes back, its hand showing behind.
SIDE_FAR_ARM_FORWARD = [(4, 0, "ooooo"), (3, 1, "oknkSo")]
SIDE_FAR_ARM_BACK = [(3, 0, "oooo"), (2, 1, "oSknko")]
SIDE_NEAR_ARM_FORWARD = [(3, 9, "oknLkSo"), (4, 10, "oooooo")]
SIDE_NEAR_ARM_BACK = [(2, 9, "oSknLko"), (3, 10, "ooooo")]


def mirrored(rows):
    return [row[::-1] for row in rows]


def stacked(*parts):
    return [row for part in parts for row in part]


def patched(rows, patches):
    rows = [row.ljust(13, ".") for row in rows]
    for x, y, text in patches:
        rows[y] = rows[y][:x] + text + rows[y][x + len(text):]
    return rows


def facing_down(body=BODY, legs=LEGS):
    return frame([(stacked(HEAD, body, legs), (0, 0))], AT)


def facing_up(body=BACK_BODY, legs=LEGS):
    return frame([(stacked(BACK_HEAD, body, legs), (0, 3))], AT)


def facing_right(patches=()):
    return frame([(patched(SIDE, patches), (0, 0))], AT)


def run_down():
    # on the second step only her legs are mirrored: her head, ponytail and implant light never change sides
    return [facing_down(), facing_down(BODY_RUN, LEGS_RUN), facing_down(),
            facing_down(BODY_RUN_OTHER, mirrored(LEGS_RUN))]


def run_up():
    return [facing_up(), facing_up(BACK_BODY_RUN, LEGS_RUN), facing_up(),
            facing_up(BACK_BODY_RUN_OTHER, mirrored(LEGS_RUN))]


def run_right():
    return [facing_right(),
            facing_right(SIDE_RUN_NEAR_FOOT + SIDE_FAR_ARM_FORWARD + SIDE_NEAR_ARM_BACK),
            facing_right(),
            facing_right(SIDE_RUN_FAR_FOOT + SIDE_NEAR_ARM_FORWARD + SIDE_FAR_ARM_BACK)]


def run_left():
    return facing_left(run_right())


def jump():
    """In the air, facing the camera, legs drawn up: the game holds this while she rises above the suit's back and
    drops in behind it."""
    return facing_down(BODY, LEGS_TUCKED)
