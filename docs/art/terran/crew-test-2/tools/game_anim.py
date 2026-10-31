"""The 2x drifter's typing frames brought down to game size, the Mecha crew's (a 25-pixel figure in a 35-pixel
frame), the way heromedel chose: the black outline is put on the full-size frame first (`small.thick_outline`), then
the frame is scaled down (`small.downsample`, every frame with the standing sprite's scale and placement, so nothing
jitters) and the outline tidied to one pixel (`small.tidy_outline`).

Usage: python3 game_anim.py OUT_DIR    (a 35 x 35 SVG per frame, animated previews and a sheet beside the Mecha crew)"""
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image, ImageDraw
import hires2
import small
import type_anim

OUTLINE = 5             # the full-size outline's width: one pixel at game size
HEIGHT = 25             # the figure's height at game size, outline included, as the Mecha crew's


def shrink(px, parts, box):
    big, big_parts = small.thick_outline(px, parts, OUTLINE)
    out, out_parts = small.downsample(big, big_parts, HEIGHT, box)
    return small.tidy_outline(out, out_parts)[0]


def image(px, bg=(110, 114, 122)):
    im = Image.new("RGBA", (small.FRAME, small.FRAME), bg + (255,))
    for p, c in px.items():
        im.putpixel(p, small.rgb(c) + (255,))
    return im


if __name__ == "__main__":
    out_dir = sys.argv[1]; os.makedirs(out_dir, exist_ok=True)
    stand, sparts, _ = hires2.build()
    big, _ = small.thick_outline(stand, sparts, OUTLINE)
    xs = [x for x, _ in big]; ys = [y for _, y in big]
    box = (min(ys), max(ys) + 1, (min(xs) + max(xs) + 1) / 2)
    down = type_anim.frames()[1]
    right = type_anim.frames_right(stand, sparts)
    directions = [("down", down), ("right", right), ("up", type_anim.frames_up(stand, sparts)),
                  ("left", type_anim.mirrored(right))]
    here = os.path.dirname(os.path.abspath(__file__))
    mech_sheet = Image.open(os.path.join(here, "..", "..", "..", "mecha", "crew", "mecha-crew-sheet.png")).convert("RGBA")
    rows = []
    for direction, frames in directions:
        small_frames = [shrink(px, parts, box) for px, parts in frames]
        for n, f in enumerate(small_frames):
            open(os.path.join(out_dir, f"drifter-game-type-{direction}-{n}.svg"), "w").write(small.svg(f))
        rows.append((direction, [image(f) for f in small_frames]))
    # the sheet: each direction's four frames enlarged 6x, then the loop at true size beside the Mecha crew's
    # first standing frame for scale
    mech = Image.new("RGBA", (35, 35), (110, 114, 122, 255)); mech.alpha_composite(mech_sheet.crop((0, 0, 35, 35)))
    cell = 35 * 6
    sheet = Image.new("RGBA", (5 * (cell + 10) + 10, len(rows) * (cell + 10) + 10), (110, 114, 122, 255))
    d = ImageDraw.Draw(sheet)
    for r, (direction, ims) in enumerate(rows):
        for n, im in enumerate(ims):
            sheet.alpha_composite(im.resize((cell, cell), Image.NEAREST), (10 + n * (cell + 10), 10 + r * (cell + 10)))
        x = 10 + 4 * (cell + 10)
        sheet.alpha_composite(mech, (x + 20, 10 + r * (cell + 10) + 80)); sheet.alpha_composite(ims[0], (x + 70, 10 + r * (cell + 10) + 80))
        d.text((x + 20, 10 + r * (cell + 10) + 125), "true size, beside the Mecha", fill=(30, 30, 30))
        d.text((10, 10 + r * (cell + 10)), direction, fill=(30, 30, 30))
    sheet.save(os.path.join(out_dir, "drifter-game-type-sheet.png"))
    # animated previews: all four directions side by side, at 6x and at true size (2x for the true-size gif so it
    # can be seen at all)
    for scale, name in ((6, "drifter-game-type-6x.gif"), (2, "drifter-game-type-2x.gif")):
        anim = []
        for n in range(4):
            fr = Image.new("RGB", (4 * 35 * scale, 35 * scale), (110, 114, 122))
            for c, (_, ims) in enumerate(rows):
                fr.paste(ims[n].convert("RGB").resize((35 * scale, 35 * scale), Image.NEAREST), (c * 35 * scale, 0))
            anim.append(fr)
        anim[0].save(os.path.join(out_dir, name), save_all=True, append_images=anim[1:], duration=180, loop=0)
