"""Three ways to draw the drifter's side view, side by side, for heromedel to pick from.

A: as he is, with only the coat tail and the lifted-foot pixels trimmed flat.
B: A, with the back of the coat as a line of dark and a line of the middle brown.
C: Claude's changes: the back lit with a shadow line behind the arm, a sloped shoulder, the head a row
   taller with a rounder skull (so the eyes sit on the same row as in the front view), and the far leg showing.
"""
import sys
sys.path.insert(0, "tools")
from pix import *
from PIL import ImageDraw
import drifter as d
from drifter import part, swap, compose

BACKGROUND = (0xc4, 0xca, 0xd2, 255)


def rows_of(a_part):
    return list(a_part[1])


def trimmed(a_part):
    """The coat tail cut flat."""
    rows = rows_of(a_part)
    for number in (15, 16):
        if rows[number][3:6] == "odd":
            rows[number] = "....od" + rows[number][6:]
    if rows[15][3] not in ".o" or rows[15][4] not in ".o":     # a fist hangs back there: outline under it
        rows[16] = rows[16][:3] + "oo" + rows[16][5:]
    rows[17] = "....ooo...ooo...."
    return part(0, rows)


def two_lines(a_part):
    """The back as a line of dark and a line of the middle brown."""
    rows = rows_of(a_part)
    for number in range(9, 15):
        if rows[number].startswith("....odd"):
            rows[number] = "....odc" + rows[number][7:]
    return part(0, rows)


def corners_off(a_part):
    """One pixel off each of the torso's four corners."""
    rows = rows_of(a_part)
    rows[8] = "....." + "o" + rows[8][6:11] + "o" + "....."
    rows[17] = "." + rows[17][:4].replace("o", ".")[1:] + "." + rows[17][5:12] + "." + rows[17][13:]
    return part(0, rows)


def frames(side, back, forward, typing, typing_1, legs, legs_pass):
    stand = compose((legs, 0), (side, 0))
    walk = [compose((d.SIDE_LEGS_NEAR, 1), (back, 1)), compose((legs_pass, 0), (side, 0)),
            compose((d.SIDE_LEGS_FAR, 1), (forward, 1)), compose((legs_pass, 0), (side, 0))]
    return stand, walk, [compose((legs, 0), (typing, 0)), compose((legs, 0), (typing_1, 0))]


uppers = [d.SIDE, d.SIDE_ARM_BACK, d.SIDE_ARM_FORWARD, d.SIDE_TYPE, d.SIDE_TYPE_1]
A = frames(*[trimmed(p) for p in uppers], d.SIDE_LEGS, d.SIDE_LEGS)
B = frames(*[two_lines(trimmed(p)) for p in uppers], d.SIDE_LEGS, d.SIDE_LEGS)
A2 = frames(*[corners_off(trimmed(p)) for p in uppers], d.SIDE_LEGS, d.SIDE_LEGS)

C_SIDE = part(0, [
    "........ooo......",
    "......oooiio.....",
    "......ohijiio....",
    ".....ohhhiho.....",
    ".....ohhhhso.....",
    ".....ohhtvso.....",
    "......outssto....",
    "......outtto.....",
    ".....owwWbBo.....",
    ".....ocfecbao....",
    "....ocdeeccao....",
    "....ocdeeccAo....",
    "....ocdeeccko....",
    "....ocdeeccpo....",
    "....occstccpo....",
    "....occtuccpo....",
    "....occcccepo....",
    "....ooo...ooo....",
])
C_BACK = swap(C_SIDE, {
    11: "....oceedccAo....",
    12: "...oeedccccko....",
    13: "...oeedccccpo....",
    14: "..ostccccccpo....",
    15: "..otuccccccpo....",
    16: "...oocccccepo....",
})
C_FORWARD = swap(C_SIDE, {
    11: "....occdeecAo....",
    12: "....occcdeeko....",
    13: "....occccdeeo....",
    14: "....occcccpsto...",
    15: "....occcccctuo...",
    16: "....occccceooo...",
})
C_TYPE = swap(C_SIDE, {
    11: "....ocdeeeeesto..",
    12: "....occccccktuo..",
    13: "....occccccpoo...",
    14: "....occccccpo....",
    15: "....occccccpo....",
})
C_TYPE_1 = swap(C_TYPE, {
    10: "....ocdeeeeesto..",
    11: "....occccccAtuo..",
    12: "....occcccckoo...",
    13: "....occccccpo....",
})
C_LEGS = part(17, [
    ".....omPpmo......",
    ".....omPpmo......",
    ".....omPpmo......",
    ".....ozZzzo......",
    ".....ozZzzzo.....",
    ".....ooooooo.....",
])
C = frames(C_SIDE, C_BACK, C_FORWARD, C_TYPE, C_TYPE_1, C_LEGS, C_LEGS)

if __name__ == "__main__":
    now = (compose((d.SIDE_LEGS, 0), (d.SIDE, 0)), d.walk_right(), d.type_right()[:2])
    front = d.stand()[0]
    times = 6
    sets = [("now", now), ("A", A), ("B", B), ("C", C)]
    out = Image.new("RGBA", (8 * FRAME * times + 50, len(sets) * (FRAME * times - 30)), BACKGROUND)
    draw = ImageDraw.Draw(out)
    for index, (label, (stand, walk, typing)) in enumerate(sets):
        y = index * (FRAME * times - 30) - 20
        draw.text((8, y + 110), label, fill=(20, 20, 30, 255))
        for column, f in enumerate([front, stand] + walk + typing):
            out.alpha_composite(scaled(f, times), (50 + column * FRAME * times, y))
    out.save("review/side-options.png")
    small = Image.new("RGBA", (8 * FRAME * 2, len(sets) * FRAME * 2), BACKGROUND)
    for index, (label, (stand, walk, typing)) in enumerate(sets):
        for column, f in enumerate([front, stand] + walk + typing):
            small.alpha_composite(scaled(f, 2), (column * FRAME * 2, index * FRAME * 2))
    small.save("review/side-options-2x.png")
    pictures = []
    for index in range(4):
        picture = Image.new("RGBA", (4 * FRAME * 4, FRAME * 4), BACKGROUND)
        for column, (label, (stand, walk, typing)) in enumerate(sets):
            picture.alpha_composite(scaled(walk[index], 4), (column * FRAME * 4, 0))
        pictures.append(picture.convert("RGB"))
    pictures[0].save("review/side-options-walk.gif", save_all=True, append_images=pictures[1:], duration=130, loop=0)
    # A beside A with the torso's corners off
    pair = [("A", A), ("A2", A2)]
    times = 8
    out = Image.new("RGBA", (7 * (FRAME * times - 60) + 60, len(pair) * (FRAME * times - 40)), BACKGROUND)
    draw = ImageDraw.Draw(out)
    for index, (label, (stand, walk, typing)) in enumerate(pair):
        y = index * (FRAME * times - 40) - 30
        draw.text((8, y + 150), label, fill=(20, 20, 30, 255))
        for column, f in enumerate([stand] + walk + typing):
            out.alpha_composite(scaled(f, times), (10 + column * (FRAME * times - 60), y))
    out.save("review/side-corners.png")
    small = Image.new("RGBA", (7 * FRAME * 2, 2 * FRAME * 2), BACKGROUND)
    for index, (label, (stand, walk, typing)) in enumerate(pair):
        for column, f in enumerate([stand] + walk + typing):
            small.alpha_composite(scaled(f, 2), (column * FRAME * 2, index * FRAME * 2))
    small.save("review/side-corners-2x.png")
    pictures = []
    for index in range(4):
        picture = Image.new("RGBA", (2 * FRAME * 5, FRAME * 5), BACKGROUND)
        for column, (label, (stand, walk, typing)) in enumerate(pair):
            picture.alpha_composite(scaled(walk[index], 5), (column * FRAME * 5, 0))
        pictures.append(picture.convert("RGB"))
    pictures[0].save("review/side-corners-walk.gif", save_all=True, append_images=pictures[1:], duration=130, loop=0)
