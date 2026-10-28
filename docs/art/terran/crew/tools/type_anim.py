"""The 2x drifter typing at a console in front of him, at the sprite's own angle (facing the viewer, seen from about
45 degrees above): four frames, as the Mecha crew's "type down" row does them: both hands on the keys, the near hand
lifted, both on the keys again, the far hand lifted.

The pose comes from the finished standing sprite (`hires2.build`): the coat and sleeves are redrawn by `coat3` with
the sleeves bent, the upper arms hanging to the elbows and the forearms coming forward and in toward the console (from
above, a forearm pointing at the viewer looks short and slanted), then the hands are drawn on the keys, seen from
above as the backs of the hands with the fingertips down.

Usage: python3 type_anim.py OUT_DIR    (frame SVGs, a strip and an animated preview, and the same over a labelled
                                        console mockup for review)"""
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import crews as C
import coat3
import hires2
import qa
from hires import ramp7, rgbhex

# the near sleeve bent for typing, clockwise from the shoulder; the far sleeve is its mirror image
TYPE_SLEEVE = [(53.5, 33.8), (51, 35), (49.5, 38.5), (48.4, 45), (47.6, 50), (49, 54), (54, 59.5), (57, 61.6),
               (63.6, 61.6), (64, 57.5), (59, 53.5), (55.6, 48), (55, 43), (54.8, 37), (54.6, 34.5)]
# the back of the near hand on the keys, from above: "w" the wrist in the cuff's shadow, "f" the fingers, the thumb on
# the body side (right); the far hand is its mirror image, still lit from the left
HAND_DOWN = ["kwwwwwk.",
             "kLsssssk",
             "kLssssSk",
             "kLsfsfSk",
             ".kfkfkk."]
# lifted off the keys: three pixels higher (less doesn't read as a keystroke), the fingers curled up under the hand so it looks shorter
HAND_UP = ["kwwwwwk.",
           "kLsssssk",
           "kLssssSk",
           ".kSSSSk."]
HAND_X, HAND_Y = 57, 62                  # the near hand's top-left corner, just under the cuff: forward of the body,
                                         # which from above is lower on the screen than the belt;
                                         # the hands close together near the middle, as at a keyboard
FRAMES = [("down", "down"), ("up", "down"), ("down", "down"), ("down", "up")]    # (near hand, far hand)
PROTECTED = ["buckle", "lapel-near", "lapel-far", "emblem", "eye", "mouth", "button"]


def hands(out, parts, near, far):
    S = [c.lower() for c in C.S1]
    key = {"k": S[0], "S": S[1], "s": S[2], "L": S[3], "f": S[1], "w": S[1]}
    for name, state in (("hand-near", near), ("hand-far", far)):
        grid = HAND_DOWN if state == "down" else HAND_UP
        y0 = HAND_Y if state == "down" else HAND_Y - 3
        if name == "hand-far":                   # mirrored; swapping the lit and shaded edges keeps the light on the left
            grid = [r[::-1].translate(str.maketrans("LS", "SL")) for r in grid]
            x0 = coat3.CENTRE - (HAND_X + len(grid[0]) - 1)
        else:
            x0 = HAND_X
        for j, row in enumerate(grid):
            for i, ch in enumerate(row):
                if ch in key:
                    out[(x0 + i, y0 + j)] = key[ch]; parts[(x0 + i, y0 + j)] = name
    return out, parts


def forearm_over_coat(out, parts):
    """The forearms lie in front of the coat: a dark line along each forearm's underside where it crosses the coat,
    and the coat just below it in the forearm's shadow, so the sleeve doesn't melt into the coat behind it."""
    out = dict(out)
    shadow = {c: coat3.COAT[max(1, i - 1)] for i, c in enumerate(coat3.COAT)}
    for (x, y), v in parts.items():
        if v in ("arm-near", "arm-far") and y > 50 and parts.get((x, y + 1), "").startswith("coat"):
            out[(x, y)] = coat3.COAT[0]
            for d in (1, 2):
                q = (x, y + d)
                if parts.get(q, "").startswith("coat") and out[q] in shadow:
                    out[q] = shadow[out[q]]
    return out


HEAD = ("hair", "face", "eye", "brow", "mouth")


def look_down(out, parts):
    """He looks down at the keys: the head dips a pixel (the neck and collar close over the gap below the chin), and
    each eye moves down another pixel, with skin (the lid) where its top row was."""
    out, parts = dict(out), dict(parts)
    head = {p: (out[p], v) for p, v in parts.items() if v in HEAD}
    for p in head:
        del out[p]; del parts[p]
    for (x, y), (c, v) in head.items():
        out[(x, y + 1)] = c; parts[(x, y + 1)] = v
    eye = {p: out[p] for p, v in parts.items() if v == "eye"}
    top = min(y for _, y in eye)
    for (x, y) in eye:
        if y == top:
            out[(x, y)] = out[(x, y - 1)]; parts[(x, y)] = "face"
    for (x, y), c in eye.items():
        out[(x, y + 1)] = c; parts[(x, y + 1)] = "eye"
    return out, parts


def console_mockup(out):
    """For review only (a mockup, not part of the sprite): a plain console in front of him at hand height, since a
    typing pose can't be judged with nothing to type on."""
    out = dict(out)
    for x in range(50, 90):
        for y in range(64, 84):
            top = y < 68
            out[(x, y)] = "#0a0a0e" if (x in (50, 89) or y in (64, 83)) else ("#5a6270" if top else "#2a2f38")
    return out


def frames():
    stand, sparts, _ = hires2.build()
    ramp = [rgbhex(t) for t in ramp7(C.DUSTER)]
    pose, pparts = coat3.redraw(stand, sparts, ramp, TYPE_SLEEVE)
    pose = forearm_over_coat(pose, pparts)
    pose, pparts = look_down(pose, pparts)
    result = []
    for near, far in FRAMES:
        out, parts = hands(dict(pose), dict(pparts), near, far)
        bad = qa.detail_survival(stand, sparts, out, parts, PROTECTED)
        st, ho = qa.stray_pixels(out), qa.holes(out)
        print(f"frame near {near:<4} far {far:<4}", "PASS" if not (bad or st or ho) else f"FAIL {bad} stray {st[:4]} holes {ho[:4]}")
        result.append((out, parts))
    return stand, result


if __name__ == "__main__":
    sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "mecha", "light-attack-frame", "pixel-redo", "tools"))
    from pixel_svg import paths
    from PIL import Image
    out_dir = sys.argv[1]; os.makedirs(out_dir, exist_ok=True)
    stand, result = frames()
    images, mock = [], []
    for n, (px, parts) in enumerate(result):
        m = console_mockup(px)
        m.update({p: c for p, c in px.items() if parts.get(p) in ("hand-near", "hand-far")})
        im = Image.new("RGB", (140, 140), (157, 162, 170))
        for p, c in m.items():
            im.putpixel(p, tuple(int(c[i:i + 2], 16) for i in (1, 3, 5)))
        mock.append(im.crop((36, 8, 104, 130)).resize((68 * 4, 122 * 4), Image.NEAREST))
        open(os.path.join(out_dir, f"drifter-2x-type-down-{n}.svg"), "w").write(
            f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 140 140" width="560" height="560" '
            f'shape-rendering="crispEdges">{paths(px)}</svg>\n')
        im = Image.new("RGB", (140, 140), (157, 162, 170))
        for p, c in px.items():
            im.putpixel(p, tuple(int(c[i:i + 2], 16) for i in (1, 3, 5)))
        images.append(im.crop((36, 8, 104, 130)).resize((68 * 4, 122 * 4), Image.NEAREST))
    strip = Image.new("RGB", (len(images) * (images[0].width + 10), images[0].height), (157, 162, 170))
    for n, im in enumerate(images):
        strip.paste(im, (n * (im.width + 10), 0))
    strip.save(os.path.join(out_dir, "drifter-2x-type-down-strip.png"))
    strip = Image.new("RGB", (len(mock) * (mock[0].width + 10), mock[0].height), (157, 162, 170))
    for n, im in enumerate(mock):
        strip.paste(im, (n * (im.width + 10), 0))
    strip.save(os.path.join(out_dir, "drifter-2x-type-down-console-mockup.png"))
    mock[0].save(os.path.join(out_dir, "drifter-2x-type-down-console-mockup.gif"), save_all=True,
                 append_images=mock[1:], duration=180, loop=0)
    images[0].save(os.path.join(out_dir, "drifter-2x-type-down.gif"), save_all=True, append_images=images[1:],
                   duration=180, loop=0)
