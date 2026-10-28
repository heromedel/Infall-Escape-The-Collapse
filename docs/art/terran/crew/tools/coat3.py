"""Round 3 at 2x: the drifter's coat and arms redrawn by shape (docs/art/sprite-process.md), one goal.

heromedel (round 3): the coat was rigidly square, the arms stuck out, and shading by regions made visible squares
instead of a realistic look. So the coat's outline is drawn as a shape (sloped round shoulders, a slight waist at the
belt, a skirt that flares to a curved hem), the sleeves hang close to the body, and the shading follows the form, as
drawing tutorials teach rather than by region:
- one light, from the upper left; the cloth turns away from it across the body and down the skirt, as smooth
  gradients whose seams curve with the form, so there are no straight bands;
- shadows shift cooler and highlights warmer, instead of only darker and lighter;
- drop folds hang from the belt at different lengths and slight angles (never parallel stripes): a dark crease, lit on
  its upper-left ridge;
- cast shadows where one thing covers another: under the belt, beside the sleeves.
"""
from PIL import Image, ImageDraw

CENTRE = 139                    # x + mirrored x: the figure's centre line is at 69.5

# the coat's own ramp, darkest to lightest: shadows lean cool (toward violet-brown), lights lean warm (toward amber)
COAT = ["#120a0c", "#22130f", "#311d18", "#43291d", "#563622", "#6a4529", "#7f5732", "#94693c"]
BELT = ("#2a1a12", "#160e0a")   # the strap's lit top edge, the strap
CUFF_Y = 66

# the near half of the outline (the far half is its mirror image), in 2x pixels
BODY = [(62, 30), (58, 31), (55, 32.5), (53, 35), (52, 38.5), (52.5, 43), (53.5, 52), (54, 57), (53.5, 63),
        (51.5, 72), (49.5, 82), (48, 92), (47.5, 99), (52, 100.5), (60, 101.5), (69.5, 102.5)]
# the sleeve hangs relaxed: the upper arm drops from the shoulder to a slightly bent elbow, and the forearm angles in
# so the hand rests in front of the coat's side, not held straight down like a soldier's
SLEEVE = [(53.5, 33.8), (51, 35), (49.5, 38.5), (48.6, 45), (48.3, 51), (49.2, 58), (50.4, CUFF_Y + .9),
          (56.8, CUFF_Y + .9), (56, 58), (55.2, 51), (55, 43), (54.8, 37), (54.6, 34.5)]
# drop folds from the belt, (top x, top y, length, drift per row): different lengths, slightly different angles
FOLDS_NEAR = [(58, 63, 22, -.16), (63, 66, 14, .06), (55, 80, 16, -.2)]
FOLDS_FAR = [(77, 63, 26, .14), (83, 70, 15, .2), (79, 88, 12, .1)]


def mask(poly_near):
    """The pixels inside a shape whose near half is given, mirrored for the far half."""
    im = Image.new("L", (140, 140))
    pts = poly_near + [(CENTRE - x, y) for x, y in reversed(poly_near)]
    ImageDraw.Draw(im).polygon([(x + .5, y + .5) for x, y in pts], fill=1)
    return {(x, y) for x in range(140) for y in range(140) if im.getpixel((x, y))}


def sleeve_mask(far, shape=None):
    im = Image.new("L", (140, 140))
    pts = [(CENTRE - x if far else x, y) for x, y in (shape or SLEEVE)]
    ImageDraw.Draw(im).polygon([(x + .5, y + .5) for x, y in pts], fill=1)
    return {(x, y) for x in range(140) for y in range(140) if im.getpixel((x, y))}


def tone(value):
    """A smooth value (0-7) to the nearest ramp colour. No dither: tried in round 3 and it read as checkerboard
    noise over the whole coat; the gradient's seams curve with the form instead."""
    return COAT[max(0, min(len(COAT) - 1, round(value)))]


def fold_pixels(folds):
    """Each fold's crease line, from its top down, drifting sideways as it falls."""
    crease = {}
    for x0, y0, length, drift in folds:
        for j in range(length):
            depth = 1.4 * min(1, j / 4) * min(1, (length - j) / 6)   # soft at both ends, deepest in the middle
            crease[(round(x0 + drift * j), y0 + j)] = depth
    return crease


def redraw(big, bp, old_ramp, sleeve=None):
    """Goal: the coat's outline and the sleeves redrawn as shapes, shaded by form. Everything that isn't coat, sleeve
    or hand keeps its pixels; the lapels and collar keep their shapes and take the new ramp. `sleeve` is the near
    sleeve's outline for another pose (the far one is its mirror image); by default the sleeves hang."""
    out, parts = dict(big), dict(bp)
    old = {c.lower(): i for i, c in enumerate(old_ramp)}
    remap = {c: COAT[min(7, round(i * 7 / (len(old_ramp) - 1)))] for c, i in old.items()}
    redrawn = ("coat-near", "coat-far", "arm-near", "arm-far", "hand-near", "hand-far")
    for p, v in bp.items():
        if v in redrawn:
            del out[p]; del parts[p]
    body, near_sleeve, far_sleeve = mask(BODY), sleeve_mask(False, sleeve), sleeve_mask(True, sleeve)
    belt_rows = sorted({y for (x, y), v in bp.items() if v == "belt"})
    hem = max(y for _, y in body)
    keep = {p for p, v in parts.items() if v not in ("leg-near", "leg-far")}        # the front: shirt, lapels...
    crease = fold_pixels(FOLDS_NEAR + FOLDS_FAR)
    ridge = {(x - 1, y): d for (x, y), d in crease.items()}
    rows = {}
    for x, y in body:
        rows.setdefault(y, []).append(x)
    # the front opening below the belt, where the trousers show: it widens a little toward the hem
    opening = lambda x, y: y > belt_rows[-1] and abs(x - 69.5) < 2 + (y - belt_rows[-1]) / 40 * 1.5

    for (x, y) in body:
        if (x, y) in keep or opening(x, y):
            continue
        xs = rows[y]
        u = (x - min(xs)) / max(1, max(xs) - min(xs))                 # 0 on the lit left side, 1 on the right
        v = 5.0 - 2.0 * u                                             # the body turning away from the light
        if y > belt_rows[-1]:
            v -= (y - belt_rows[-1]) / (hem - belt_rows[-1]) * 1.1     # the skirt darkening down toward the hem
        if y < 38:
            v += .8 * (38 - y) / 6                                    # shoulder tops facing up into the light
        if y in (belt_rows[-1] + 1, belt_rows[-1] + 2):
            v -= 1.2 if y == belt_rows[-1] + 1 else .6                # the belt's shadow
        if any((x - d, y) in near_sleeve for d in (1, 2, 3)):
            v -= 1.0                                                  # the near sleeve's cast shadow
        if any((x + d, y) in far_sleeve for d in (1, 2)):
            v -= .6                                                   # tucked under the far arm
        v -= crease.get((x, y), 0)
        v += .7 * ridge.get((x, y), 0) / 1.4
        if y in belt_rows:
            c = BELT[0] if y == belt_rows[0] else BELT[1]
            out[(x, y)] = c; parts[(x, y)] = "belt"
            continue
        out[(x, y)] = tone(v); parts[(x, y)] = "coat-near" if x < 69.5 else "coat-far"
    for sleeve, name, lit in ((near_sleeve, "arm-near", 0), (far_sleeve, "arm-far", -.7)):
        xs_by_y = {}
        for x, y in sleeve:
            xs_by_y.setdefault(y, []).append(x)
        for (x, y) in sleeve:
            xs = xs_by_y[y]
            u = (x - min(xs)) / max(1, max(xs) - min(xs))
            v = 5.6 - 2.8 * u + lit                                   # a cylinder lit from the left
            if y < 37:
                v += .6
            if 50 <= y <= 53 and u > .45 and (y - 50) == round((u - .45) * 6):
                v -= 1.3                                              # the elbow's crease, on the inside
            if y > 45 and (x, y + 3) not in sleeve:
                v -= .9                                               # the cuff turning under, at the sleeve's end
            out[(x, y)] = tone(v); parts[(x, y)] = name
    for p, v in parts.items():                                         # lapels and collar take the new ramp
        if v in ("lapel-near", "lapel-far", "collar-near", "collar-far") and out[p] in remap:
            out[p] = remap[out[p]]
    for p in [p for p in out if parts.get(p) in ("belt",) and p not in body]:
        del out[p]; del parts[p]                                       # belt ends left outside the new waist
    # the outline: the silhouette's edge one step from the darkest, the darkest on the shadow side and below
    coat_like = ("coat-near", "coat-far", "arm-near", "arm-far")
    edge = [p for p, v in parts.items() if v in coat_like and
            any((p[0] + dx, p[1] + dy) not in out for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))]
    for (x, y) in edge:
        out[(x, y)] = COAT[1] if (x < 69.5 and (x - 1, y) not in out and y < hem - 1) else COAT[0]
    # where a sleeve meets the coat: a dark line so the arm reads in front of the body
    for (x, y), v in list(parts.items()):
        if y < 42:
            continue                                                   # the shoulder flows into the sleeve
        if v == "arm-near" and parts.get((x + 1, y), "").startswith("coat"):
            out[(x, y)] = COAT[1]
        if v == "arm-far" and parts.get((x - 1, y), "").startswith("coat"):
            out[(x, y)] = COAT[0]
    return out, parts
