"""Builds the review pictures of the 2x top-down drifter. Run from this folder: python3 tools/build.py"""
import sys
sys.path.insert(0, "tools")
from pix import *
import big

FLOOR = (0xc4, 0xca, 0xd2, 255)

if __name__ == "__main__":
    rows = [big.stand(), big.walk_down(), big.walk_up()]
    for times in (1, 4):
        strips = [strip(r, times, 0, FLOOR) for r in rows]
        out = Image.new("RGBA", (max(s.width for s in strips), sum(s.height for s in strips)), FLOOR)
        y = 0
        for s in strips:
            out.alpha_composite(s, (0, y))
            y += s.height
        out.save("review/so-far-%dx.png" % times)
    # beside the small one of crew test 4, shown at the same size on screen
    small = Image.open("../crew-test-4/terran-drifter-topdown-sheet.png").convert("RGBA")
    def cell(row, col):
        return small.crop((col * 35, row * 35, col * 35 + 35, row * 35 + 35)).resize((70, 70), Image.NEAREST)
    pairs = [strip(big.walk_down(), 4, 0, FLOOR), strip([cell(0, c) for c in range(4)], 4, 0, FLOOR),
             strip(big.walk_up(), 4, 0, FLOOR), strip([cell(1, c) for c in range(4)], 4, 0, FLOOR)]
    out = Image.new("RGBA", (pairs[0].width, sum(p.height for p in pairs)), FLOOR)
    y = 0
    for p in pairs:
        out.alpha_composite(p, (0, y))
        y += p.height
    out.save("review/beside-the-small-one.png")
    frames = [strip([a, b], 4, 0, FLOOR).convert("RGB") for a, b in zip(big.walk_down(), big.walk_up())]
    frames[0].save("review/walk-4x.gif", save_all=True, append_images=frames[1:], duration=250, loop=0)
