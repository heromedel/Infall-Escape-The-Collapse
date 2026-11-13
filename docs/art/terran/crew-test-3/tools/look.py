"""Review pictures: the frames enlarged, and at game size beside the Mecha and Tentauri sheets."""
import sys
sys.path.insert(0, "tools")
from pix import *
import drifter

FLOOR = (0xc9, 0xcf, 0xd6, 255)
DARK = (0x2a, 0x2e, 0x3a, 255)


def others():
    mecha = Image.open("../../mecha/crew/mecha-crew-sheet.png").convert("RGBA")
    tent = Image.open("../../tentauri/crew/tentauri-crew-sheet.png").convert("RGBA")
    return mecha, tent


def cell(sheet, row, column):
    return sheet.crop((column * 35, row * 35, column * 35 + 35, row * 35 + 35))


def board(rows_of_frames, name, times=8):
    strips = [strip(frames, times, 4, (0x9a, 0xa3, 0xad, 255)) for frames in rows_of_frames]
    small = [strip(frames, 2, 2, FLOOR) for frames in rows_of_frames]
    width = max(s.width for s in strips) + 20 + max(s.width for s in small)
    height = sum(s.height + 6 for s in strips)
    out = Image.new("RGBA", (width, height), (30, 30, 36, 255))
    y = 0
    for big, little in zip(strips, small):
        out.alpha_composite(big, (0, y))
        out.alpha_composite(little, (big.width + 20, y))
        y += big.height + 6
    out.save(name)


if __name__ == "__main__":
    mecha, tent = others()
    stands = drifter.stand()
    board([[cell(mecha, 0, 0)] + stands + [cell(tent, 0, 0)]], "review/stand.png")
    board([drifter.walk_down(), drifter.walk_right(), drifter.walk_up()], "review/walk.png", 6)
