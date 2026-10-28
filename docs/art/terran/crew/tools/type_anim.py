"""The 2x drifter typing, at the sprite's own angle (facing the viewer, seen from about 45 degrees above): four
frames, as the crew sheets' "type down" rows do them: both hands down, the near hand lifted, both down, the far hand
lifted. There is no console in the sprite: the console belongs to the room art, and the crew stands on its tile.

Typing facing down is drawn as in the crew sheets: the elbows go out to the sides, and the hands come down at hip
level outside the body, palms down, pressing alternately. The pose comes from the finished standing sprite
(`hires2.build`): the coat and sleeves are redrawn by `coat3` with the sleeves bent out, then the hands are drawn,
seen from above as the backs of the hands with the fingertips down.

Usage: python3 type_anim.py OUT_DIR    (frame SVGs, a strip and an animated preview)"""
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import crews as C
import coat3
import hires2
import qa
import views
from hires import ramp7, rgbhex

# the near sleeve bent for typing, clockwise from the shoulder: the elbow out to the side, the forearm coming down
# to the hip; the far sleeve is its mirror image
TYPE_SLEEVE = [(53.5, 33.8), (50, 35), (46.5, 38), (43.5, 42), (41, 47), (41.5, 53), (43, 60.6), (49.5, 60.6),
               (48.8, 55), (48.2, 50), (50, 45.5), (52.5, 42), (54, 38), (54.6, 34.5)]
# the back of the near hand on the keys, from above: "w" the wrist in the cuff's shadow, "f" the fingers, the thumb on
# the body side (right); the far hand is its mirror image, still lit from the left
HAND_DOWN = ["kwwwwwk.",
             "kLsssssk",
             "kLssssSk",
             "kLsfsfSk",
             ".kfkfkk."]
# lifted by LIFT pixels (at game size a smaller lift vanishes: 3 pixels here came out as none), the fingers curled
# under so the hand looks shorter
HAND_UP = ["kwwwwwk.",
           "kLsssssk",
           "kLssssSk",
           ".kSSSSk."]
HAND_X, HAND_Y = 42, 61                  # the near hand's top-left corner, just under the cuff, at the hip
LIFT = 5
FRAMES = [("down", "down"), ("up", "down"), ("down", "down"), ("down", "up")]    # (near hand, far hand)
PROTECTED = ["buckle", "lapel-near", "lapel-far", "emblem", "eye", "mouth", "button"]


def hands(out, parts, near, far):
    S = [c.lower() for c in C.S1]
    key = {"k": S[0], "S": S[1], "s": S[2], "L": S[3], "f": S[1], "w": S[1]}
    for name, state in (("hand-near", near), ("hand-far", far)):
        grid = HAND_DOWN if state == "down" else HAND_UP
        y0 = HAND_Y if state == "down" else HAND_Y - LIFT
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


# --- facing away (typing up): the elbows out and the hands raised beside the shoulders, palms forward, so from behind
# we see the backs of the hands, fingers up; hands held in front of him would be hidden by his body
TYPE_UP_SLEEVE = [(53.5, 33.8), (50, 35), (48.6, 36.8), (47.6, 38.6), (41.8, 38.6), (41, 42), (40.8, 46), (42, 49.8),
                  (45.5, 50), (49, 47), (52, 43.5), (54, 40), (54.6, 34.5)]
RAISED = [".kfkfkk.",
          "kLsfsfSk",
          "kLssssSk",
          "kLsssssk",
          "kwwwwwwk"]
RAISED_UP = [".kSSSSk.",                  # lifted: the fingers bent, the wrist showing below down to the cuff
             "kLssssSk",
             "kLsssssk"] + [".kwwwwk."] * (LIFT + 1) + [".kwwwwwk"]
RAISED_X, RAISED_Y = 41, 34

# --- facing right (typing right): both forearms reach forward to the console at chest height, the backs of the
# hands up and toward us, fingertips down on the keys; the far arm is behind him, seen only where it reaches past his
# chest, and darker
TYPE_SIDE_SLEEVE = [(66.5, 34), (70, 33), (73.5, 34.5), (76, 39), (79, 44.6), (85.4, 44.4), (85.6, 50.4), (79, 51),
                    (74.5, 50), (70.5, 45), (67.5, 40), (65.5, 36.5)]
SIDE_TYPE = ["kwwwk..",
             "kLsssk.",
             "kLssssk",
             "kLsSsSk",
             ".kSkSkk"]
SIDE_TYPE_UP = ["kwwwk..",
                "kLsssk.",
                "kLsssk.",
                "kkSSk..",
                "kwk....",
                "kwk...."]                  # the wrist bent up from the cuff
SIDE_X, SIDE_Y = 86, 45
FAR_SHIFT = (-2, -1)


def draw(out, parts, grid, x0, y0, name, dim=0, mirror=False, behind=()):
    """A hand grid at (x0, y0). `mirror` flips it (keeping the light on its left), `dim` darkens it a step, and it
    never covers pixels of the parts in `behind`."""
    S = [c.lower() for c in C.S1]
    tone = {"k": 0, "S": 1, "s": 2, "L": 3, "f": 1, "w": 1}
    if mirror:
        grid = [r[::-1].translate(str.maketrans("LS", "SL")) for r in grid]
    for j, row in enumerate(grid):
        for i, ch in enumerate(row):
            q = (x0 + i, y0 + j)
            if ch in tone and parts.get(q) not in behind:
                out[q] = S[max(0, tone[ch] - dim) if ch != "k" else 0]; parts[q] = name
    return out, parts


def frames_up(stand, sparts):
    pose, pparts = views.back(stand, sparts, TYPE_UP_SLEEVE)
    result = []
    for near, far in FRAMES:
        out, parts = dict(pose), dict(pparts)
        for name, state, mirror in (("hand-near", near, False), ("hand-far", far, True)):
            grid = RAISED if state == "down" else RAISED_UP
            y0 = RAISED_Y if state == "down" else RAISED_Y - LIFT
            x0 = RAISED_X if not mirror else coat3.CENTRE - (RAISED_X + len(grid[0]) - 1)
            draw(out, parts, grid, x0, y0, name, mirror=mirror)
        result.append((out, parts))
    return result


def frames_right(stand, sparts):
    base, bparts = views.side(stand, sparts, arms=False)
    body = ("coat-near", "belt", "buckle", "hair", "face", "eye", "brow", "mouth")
    result = []
    for near, far in FRAMES:
        out, parts = dict(base), dict(bparts)
        # the far arm first, behind him: only what reaches out past his chest shows
        far_px, far_parts = views.side_arm({}, {}, TYPE_SIDE_SLEEVE, "arm-far", dim=1.2, shift=FAR_SHIFT)
        for q, c in far_px.items():
            if parts.get(q) not in body:
                out[q] = c; parts[q] = "arm-far"
        dy = 0 if far == "down" else -LIFT
        draw(out, parts, SIDE_TYPE if far == "down" else SIDE_TYPE_UP, SIDE_X + FAR_SHIFT[0],
             SIDE_Y + FAR_SHIFT[1] + dy, "hand-far", dim=1, behind=body)
        out, parts = views.side_arm(out, parts, TYPE_SIDE_SLEEVE)
        dy = 0 if near == "down" else -LIFT
        draw(out, parts, SIDE_TYPE if near == "down" else SIDE_TYPE_UP, SIDE_X, SIDE_Y + dy, "hand-near")
        for q in [q for q, v in parts.items() if v in ("arm-far", "hand-far")]:      # the far arm's lone corners
            if sum((q[0] + dx, q[1] + dy) in out for dx, dy in qa.NB4) <= 1:
                del out[q]; del parts[q]
        for q in qa.holes(out):                  # a pinhole left between the far arm and the near one: shadow
            out[q] = coat3.COAT[0]; parts[q] = "arm-far"
        result.append((out, parts))
    return result


def mirrored(frames):
    """Facing left: the facing-right frames flipped."""
    return [({(coat3.CENTRE - x, y): c for (x, y), c in px.items()}, {(coat3.CENTRE - x, y): v for (x, y), v in pa.items()})
            for px, pa in frames]


if __name__ == "__main__":
    sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "mecha", "light-attack-frame", "pixel-redo", "tools"))
    from pixel_svg import paths
    from PIL import Image
    out_dir = sys.argv[1]; os.makedirs(out_dir, exist_ok=True)
    stand, down = frames()
    stand2, sparts2, _ = hires2.build()
    right = frames_right(stand2, sparts2)
    directions = [("down", down), ("right", right), ("up", frames_up(stand2, sparts2)), ("left", mirrored(right))]
    rows = []
    for direction, result in directions:
        images = []
        for n, (px, parts) in enumerate(result):
            st, ho = qa.stray_pixels(px), qa.holes(px)
            print(f"type {direction} {n}", "PASS" if not (st or ho) else f"FAIL stray {st[:4]} holes {ho[:4]}")
            open(os.path.join(out_dir, f"drifter-2x-type-{direction}-{n}.svg"), "w").write(
                f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 140 140" width="560" height="560" '
                f'shape-rendering="crispEdges">{paths(px)}</svg>\n')
            im = Image.new("RGB", (140, 140), (157, 162, 170))
            for p, c in px.items():
                im.putpixel(p, tuple(int(c[i:i + 2], 16) for i in (1, 3, 5)))
            images.append(im.crop((32, 8, 108, 130)).resize((76 * 3, 122 * 3), Image.NEAREST))
        images[0].save(os.path.join(out_dir, f"drifter-2x-type-{direction}.gif"), save_all=True,
                       append_images=images[1:], duration=180, loop=0)
        rows.append(images)
    w, h = rows[0][0].size
    sheet = Image.new("RGB", (4 * (w + 8), len(rows) * (h + 8)), (157, 162, 170))
    for r, images in enumerate(rows):
        for n, im in enumerate(images):
            sheet.paste(im, (n * (w + 8), r * (h + 8)))
    sheet.save(os.path.join(out_dir, "drifter-2x-type-sheet.png"))
