"""The 2x drifter from behind and from the side, at the same camera angle as the front (about 45 degrees above), so
the crew sheet can have every facing. Built from heromedel's rig renders (`reference/heromedel-rig-front-right-back.png`
and the male standing / idle / step sheet): the back is the front's silhouette seen from behind; the side is drawn as
its own shapes, facing right (facing left is the mirror image, as crew sheets do it).

Usage: python3 views.py OUT_DIR      (front, back and both sides side by side, and an SVG of each)"""
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image, ImageDraw
import crews as C
import coat3
import hires2
from hires import ramp7, rgbhex

HEAD = ("hair", "face", "eye", "brow", "mouth")
DUSTER7 = [rgbhex(t) for t in ramp7(C.DUSTER)]


def hair_tone(u, t, hair=None):
    """Hair lit from the upper left: u runs 0-1 across the head, t 0-1 down it."""
    H = hair or [rgbhex(c) for c in ramp7(C.HAIR1)]
    v = 5.2 - 2.6 * u - 1.6 * t
    return H[max(1, min(len(H) - 1, round(v)))]


def back(stand, sparts, sleeve=None):
    """From behind: the head all hair down to a strip of nape between the collar's sides, an ear's edge either side;
    the coat's back (`coat3.redraw` with `back`): the collar standing up round the neck, the belt all the way round, a
    vent up the skirt; the boots' heels. The hanging hands are in front of the coat, so from behind they are hidden
    (heromedel). `sleeve` is the near sleeve's outline for another pose."""
    out, parts = coat3.redraw(stand, sparts, DUSTER7, sleeve, back=True)
    S = [c.lower() for c in C.S1]
    head = [p for p, v in parts.items() if v in HEAD]
    xs = [x for x, _ in head]; ys = [y for _, y in head]
    x0, x1, y0, y1 = min(xs), max(xs), min(ys), max(ys)
    rows = {}
    for x, y in head:
        rows.setdefault(y, []).append(x)
    for (x, y) in head:
        r = rows[y]
        u = (x - min(r)) / max(1, max(r) - min(r)); t = (y - y0) / (y1 - y0)
        edge = x in (min(r), max(r)) or y == y0
        if y >= y1 - 2 and min(r) + 2 < x < max(r) - 2:
            out[(x, y)] = S[1] if y < y1 else S[0]; parts[(x, y)] = "neck"        # the nape, in the hair's shadow
        elif 24 <= y <= 27 and x in (min(r), max(r)):
            out[(x, y)] = S[0] if x == max(r) else S[1]; parts[(x, y)] = "face"   # an ear's edge
        else:
            out[(x, y)] = C.HAIR1[0] if edge else hair_tone(u, t); parts[(x, y)] = "hair"
    # two long locks falling from the crown, as darker lines, so the back of the head isn't a flat cap
    for x_top, drift in ((x0 + 6, -.15), (x1 - 6, .15)):
        for y in range(y0 + 3, y1 - 4):
            q = (round(x_top + drift * (y - y0)), y)
            if parts.get(q) == "hair":
                out[q] = C.HAIR1[1]
    # the collar standing up behind the neck: the coat's lit tone, a dark top edge
    for (x, y), v in list(parts.items()):
        if v == "neck" and y > y1:
            out[(x, y)] = coat3.COAT[6] if y > y1 + 1 else coat3.COAT[1]; parts[(x, y)] = "collar-near"
    B = [c.lower() for c in C.BOOTS]
    for p, v in parts.items():                              # the heels: no lit toe from behind
        if v in ("boot-near", "boot-far") and out[p] == B[3]:
            out[p] = B[2]
    return out, parts


# the side view, facing right, in 2x pixels; the outlines run clockwise
SIDE_HEAD = [(66, 12), (73, 12), (77, 15), (78.5, 19), (78.5, 23), (80, 26.5), (78.5, 28), (78.8, 30.5), (77.5, 32.5),
             (73, 33.5), (70, 32), (64, 32), (61.5, 29), (60.5, 24), (61, 17), (63, 13.5)]
SIDE_BODY = [(65, 30.5), (69, 29.5), (76, 33), (79, 37), (80.5, 44), (80, 52), (78.5, 57), (79, 62), (81, 75),
             (82.5, 88), (84, 100), (75, 101.5), (66, 101.5), (57, 100.5), (58.5, 88), (60, 75), (61.5, 63), (61, 57),
             (60.5, 48), (61.5, 40), (63.5, 34)]
SIDE_SLEEVE = [(66.5, 34), (70, 33), (73.5, 34.5), (75, 38), (75, 48), (75.5, 58), (76, 66.9), (68.5, 66.9), (68, 58),
               (67, 48), (65.5, 40), (65.5, 36.5)]
SIDE_LEG = [(66, 98), (73.4, 98), (73.4, 114), (66, 114)]      # the near leg, as wide as a boot's shaft; the far one
                                                               # sits 3 pixels behind it
SIDE_BOOT = ["kkkkkkkk......",
             "kddddddk......",
             "kLbbbbdk......",
             "kLbbbbdk......",
             "kLbbbbbdkk....",
             "kLbbbbbbbdkk..",
             "kLbbbbbLLbbdk.",
             "kLbbbbbbbbbbdk",
             "kddddddddddddk",
             "ksssssssssssk.",
             ".kkkkkkkkkkk.."]


def poly(points):
    im = Image.new("L", (140, 140))
    ImageDraw.Draw(im).polygon([(x + .5, y + .5) for x, y in points], fill=1)
    return {(x, y) for x in range(140) for y in range(140) if im.getpixel((x, y))}


def across(cells):
    """For each pixel, how far across its row of the shape it is: 0 at the left, 1 at the right."""
    rows = {}
    for x, y in cells:
        rows.setdefault(y, []).append(x)
    return {(x, y): (x - min(rows[y])) / max(1, max(rows[y]) - min(rows[y])) for x, y in cells}


def outline(out, cells, dark):
    for (x, y) in cells:
        if any((x + dx, y + dy) not in out for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
            out[(x, y)] = dark


def side(stand, sparts, arms=True):
    """Facing right, the light from the upper left falling on his back: the head in profile (hair over the top and
    back, the ear, one eye, the nose and chin on the right); the coat from the side, its front edge with the lapel
    catching the light, the belt across with the buckle at the front, the skirt flaring to the hem; the near arm
    hanging at his side over the coat; the legs one just behind the other; boots in profile, toes forward."""
    S = [c.lower() for c in C.S1]; H = C.HAIR1
    P = [rgbhex(t) for t in ramp7(C.PANTS1)]
    B = [c.lower() for c in C.BOOTS]
    out, parts = {}, {}
    # legs and boots first, the far one (behind) darker
    bottom = max(y for (x, y), v in sparts.items() if v.startswith("boot"))
    for name, dx, dim in (("leg-far", -3, 1), ("leg-near", 0, 0)):
        leg = {(x + dx, y) for x, y in poly(SIDE_LEG)}
        u = across(leg)
        for p in leg:
            out[p] = P[max(0, min(6, round(4 - 2 * u[p] - dim)))]; parts[p] = name
        outline(out, leg, P[0])
        key = {"k": B[0], "d": B[1], "b": B[2], "L": B[3], "s": "#0a0809"}
        x0, y0 = min(x for x, _ in leg), bottom + 1 - len(SIDE_BOOT)     # the shaft right over its leg
        for j, row in enumerate(SIDE_BOOT):
            for i, ch in enumerate(row):
                if ch in key:
                    c = key[ch] if not dim or ch in "ks" else B[max(0, "kdbL".index(ch) - 1)]
                    out[(x0 + i, y0 + j)] = c; parts[(x0 + i, y0 + j)] = "boot-" + name[4:]
    # the coat
    body = poly(SIDE_BODY)
    u = across(body)
    belt_rows = sorted({y for (x, y), v in sparts.items() if v == "belt"})
    hem = max(y for _, y in body)
    folds = {(round(64 + .1 * j), 64 + j) for j in range(26)} | {(round(73 + .14 * j), 66 + j) for j in range(22)}
    for (x, y) in body:
        v = 5.4 - 2.6 * u[(x, y)]
        if y > belt_rows[-1]:
            v -= (y - belt_rows[-1]) / (hem - belt_rows[-1]) * 1.0
        if y < 38:
            v += .6
        if y == belt_rows[-1] + 1:
            v -= 1.0
        if (x, y) in folds:
            v -= 1.3
        if (x + 1, y) in folds:
            v += .6
        if y in belt_rows:
            out[(x, y)] = coat3.BELT[0] if y == belt_rows[0] else coat3.BELT[1]; parts[(x, y)] = "belt"
        else:
            out[(x, y)] = coat3.tone(v); parts[(x, y)] = "coat-near"
    for (x, y) in body:                                       # the lapel's edge down the front of the chest
        if 34 <= y <= 47 and u[(x, y)] > .8 and parts[(x, y)] == "coat-near":
            out[(x, y)] = coat3.COAT[7] if u[(x, y)] < .93 else coat3.COAT[4]
    for y in belt_rows[:2]:                                   # the buckle, at the front
        for x in (77, 78):
            out[(x, y)] = "#e0c070" if (x + y) % 2 == 0 else "#a8884a"; parts[(x, y)] = "buckle"
    outline(out, body, coat3.COAT[0])
    # the head over the collar
    head = poly(SIDE_HEAD)
    hu = across(head)
    for (x, y) in head:
        hairline = 70 - max(0, y - 24) * .4
        hair = y < 18 or (x < hairline and y < 31) or (x < 73 and y < 21)
        if hair:
            out[(x, y)] = hair_tone(hu[(x, y)] * .6, (y - 12) / 20); parts[(x, y)] = "hair"
        else:
            out[(x, y)] = S[2] if x < 77 else S[3] if y < 26 else S[2]; parts[(x, y)] = "face"
    for (x, y) in head:                                       # the cheek and jaw turning under, in shade
        if parts[(x, y)] == "face" and (y >= 31 or x <= 72):
            out[(x, y)] = S[1]
    for x, y in ((69, 24), (70, 24), (69, 25), (70, 25), (69, 26), (70, 26), (70, 27)):
        out[(x, y)] = S[2] if x == 69 else S[1]; parts[(x, y)] = "face"      # the ear
    out[(69, 23)] = H[1]
    for x in (75, 76, 77):
        out[(x, 22)] = H[1]; parts[(x, 22)] = "brow"
    out[(76, 24)] = "#e6dacb"; out[(77, 24)] = "#2a1810"; parts[(76, 24)] = parts[(77, 24)] = "eye"
    out[(77, 25)] = S[1]
    out[(78, 30)] = "#7a4a3c"; parts[(78, 30)] = "mouth"
    outline(out, head, S[0])
    for (x, y) in head:
        if parts[(x, y)] == "hair" and out[(x, y)] == S[0]:
            out[(x, y)] = H[0]
    if not arms:
        return out, parts
    out, parts = side_arm(out, parts, SIDE_SLEEVE)
    return hang_hand(out, parts)


def side_arm(out, parts, points, name="arm-near", dim=0.0, shift=(0, 0)):
    """A sleeve in profile, in front of whatever is already drawn: lit on its left (his back), the cuff turning under,
    a dark line where its front edge crosses the coat. `dim` darkens it (the far arm, behind him), `shift` moves it."""
    sleeve = {(x + shift[0], y + shift[1]) for x, y in poly(points)}
    su = across(sleeve)
    for (x, y) in sleeve:
        v = 5.6 - 2.6 * su[(x, y)] - dim
        if (x, y + 3) not in sleeve and (x + 3, y) not in sleeve:
            v -= .9
        out[(x, y)] = coat3.tone(v); parts[(x, y)] = name
    outline(out, sleeve, coat3.COAT[0])
    for (x, y) in sleeve:
        if parts.get((x + 1, y), "").startswith("coat") and y > 40:
            out[(x, y)] = coat3.COAT[1]
    return out, parts


# the back of the near hand, hanging, seen from outside: knuckles across, the fingers curled a little under, only
# the thumb's tip showing at the front (heromedel: from the side we see the back of the hand)
SIDE_HAND = ["kwwwwk.",
             "kLsssSk",
             "kLsssss",
             "kLssssk",
             "kLsSsSk",
             "kLssssk",
             ".kSsSk.",
             "..kkk.."]


def hang_hand(out, parts):
    """The near hand hanging below its cuff, its back to us."""
    S = [c.lower() for c in C.S1]
    key = {"k": S[0], "S": S[1], "s": S[2], "L": S[3], "f": S[1], "w": S[1]}
    sleeve = [p for p, v in parts.items() if v == "arm-near"]
    cuff_y = max(y for _, y in sleeve)
    cuff = [x for x, y in sleeve if y == cuff_y]
    x0 = round((min(cuff) + max(cuff) + 1) / 2 - len(SIDE_HAND[0]) / 2)
    for j, row in enumerate(SIDE_HAND):
        for i, ch in enumerate(row):
            if ch in key:
                out[(x0 + i, cuff_y + 1 + j)] = key[ch]; parts[(x0 + i, cuff_y + 1 + j)] = "hand-near"
    return out, parts


def image(px, size=140, bg=(157, 162, 170)):
    im = Image.new("RGB", (size, size), bg)
    for p, c in px.items():
        im.putpixel(p, tuple(int(c[i:i + 2], 16) for i in (1, 3, 5)))
    return im


if __name__ == "__main__":
    out_dir = sys.argv[1]; os.makedirs(out_dir, exist_ok=True)
    stand, sparts, _ = hires2.build()
    right = side(stand, sparts)[0]
    left = {(139 - x, y): c for (x, y), c in right.items()}
    views = [("front", stand), ("right", right), ("back", back(stand, sparts)[0]), ("left", left)]
    tiles = [image(px).crop((36, 8, 104, 130)).resize((68 * 4, 122 * 4), Image.NEAREST) for _, px in views]
    sheet = Image.new("RGB", (len(tiles) * (tiles[0].width + 10), tiles[0].height + 24), (157, 162, 170))
    d = ImageDraw.Draw(sheet)
    for n, (t, (name, _)) in enumerate(zip(tiles, views)):
        sheet.paste(t, (n * (t.width + 10), 0)); d.text((n * (t.width + 10) + 8, t.height + 4), name, fill=(40, 40, 40))
    sheet.save(os.path.join(out_dir, "views.png"))
