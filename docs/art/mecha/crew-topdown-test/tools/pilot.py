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
LEGS_RUN = ["...oSoko...", "...oSooo...", "...oko.....", "....o......"]
LEGS_TUCKED = ["...okoko...", "....o.o...."]            # in the air, her legs drawn up

# --- Facing away -------------------------------------------------------------------------------------------------
# From behind there is no face: her hair, the tie at her nape and the ponytail down her back.
BACK_HEAD = ["...ooooo...", "..oHHIHHo..", "..oHIHHHo..", ".ooooLoooo."]
BACK_BODY = [".oSknIHkSo.", "..oknHnko.."]
BACK_BODY_RUN = [".ooknIHkSo.", "..oknHnko.."]

# --- Facing right ------------------------------------------------------------------------------------------------
# One shoulder above her head and one below; the ponytail trails behind her; a foot shows ahead when she runs.
SIDE = ["....ooo....",
        "...oknko...",            # far shoulder
        ".ooooooo...",
        "oIHLHIHSo..",            # ponytail, tie, hair, face
        ".oooHHHTo..",
        "...oHIHSo..",
        "...oooooo..",
        "...oknLSo..",            # near shoulder, implant light, hand
        "....oooo..."]
SIDE_RUN_NEAR_FOOT = [(9, 4, "oo"), (9, 5, "Sko"), (9, 6, "oo")]      # the near foot reaches ahead of her
SIDE_RUN_FAR_FOOT = [(9, 2, "oo"), (9, 3, "Sko"), (9, 4, "oo")]       # then the far one


def mirrored(rows):
    return [row[::-1] for row in rows]


def stacked(*parts):
    return [row for part in parts for row in part]


def patched(rows, patches):
    rows = [row.ljust(13, ".") for row in rows]
    for x, y, text in patches:
        rows[y] = rows[y][:x] + text + rows[y][x + len(text):]
    return rows


def facing_down(body=BODY, legs=LEGS, flipped=False):
    lower = stacked(body, legs)
    if flipped:                  # the other hand and the other leg; her head and ponytail stay as they are
        lower = mirrored(lower)
    return frame([(stacked(HEAD, lower), (0, 0))], AT)


def facing_up(body=BACK_BODY, legs=LEGS, flipped=False):
    lower = stacked(body, legs)
    if flipped:
        lower = mirrored(lower)
    return frame([(stacked(BACK_HEAD, lower), (0, 3))], AT)


def facing_right(patches=()):
    return frame([(patched(SIDE, patches), (0, 2))], AT)


def run_down():
    return [facing_down(), facing_down(BODY_RUN, LEGS_RUN), facing_down(), facing_down(BODY_RUN, LEGS_RUN, True)]


def run_up():
    return [facing_up(), facing_up(BACK_BODY_RUN, LEGS_RUN), facing_up(), facing_up(BACK_BODY_RUN, LEGS_RUN, True)]


def run_right():
    return [facing_right(), facing_right(SIDE_RUN_NEAR_FOOT), facing_right(), facing_right(SIDE_RUN_FAR_FOOT)]


def run_left():
    return facing_left(run_right())


def jump():
    """In the air, facing the camera, legs drawn up: the game holds this while she rises above the suit's back and
    drops in behind it."""
    return facing_down(BODY, LEGS_TUCKED)
