"""Round 3 at 2x: the drifter's legs redrawn by shape with the coat off, before the coat goes back on over them.

heromedel (round 3): pencil legs with a crotch bulge. The legs were the rig's thin columns, and only a stub of trouser
showed in the coat's opening. Drawn as a body first, like a figure drawing: thighs from the hips meeting at the crotch
in a soft V, tapering to the knees, the calves swelling a little below them and narrowing to the ankles, where they
go into the boots. Shaded as cylinders lit from the upper left, the inner thighs in shadow.
"""
from PIL import Image, ImageDraw

from hires import ramp7, rgbhex
import crews as C

CENTRE = 139                    # x + mirrored x: the figure's centre line is at 69.5
CROTCH = 74

# the near leg's outline in 2x pixels, clockwise from the hip; the far leg is its mirror image
LEG = [(54.5, 62), (69.4, 62), (69.4, CROTCH), (68.3, 79), (66.6, 86), (65.6, 91), (66, 96), (65.2, 103),
       (64, 109), (63.4, 114), (56, 114), (55.2, 109), (54.4, 103), (54.4, 97), (55.4, 91), (55.2, 84),
       (54.8, 74), (54.4, 68)]


def leg_mask(far):
    im = Image.new("L", (140, 140))
    pts = [(CENTRE - x if far else x, y) for x, y in LEG]
    ImageDraw.Draw(im).polygon([(x + .5, y + .5) for x, y in pts], fill=1)
    return {(x, y) for x in range(140) for y in range(140) if im.getpixel((x, y))}


def redraw(big, bp):
    """Goal: legs with thighs, a groin, knees and calves. Only the legs change; the boots stay on top of them."""
    ramp = [rgbhex(t) for t in ramp7(C.PANTS1)]
    out, parts = dict(big), dict(bp)
    for p, v in bp.items():
        if v in ("leg-near", "leg-far"):
            del out[p]; del parts[p]
    for name, far, dim in (("leg-near", False, 0), ("leg-far", True, -.5)):
        cells = {p for p in leg_mask(far) if not parts.get(p, "").startswith("boot")}
        rows = {}
        for x, y in cells:
            rows.setdefault(y, []).append(x)
        for (x, y) in cells:
            xs = rows[y]
            u = (x - min(xs)) / max(1, max(xs) - min(xs))
            v = 4.6 - 2.4 * u + dim                       # a cylinder lit from the left
            inner = u > .6 if not far else u < .4
            if y < CROTCH + 10 and inner:
                v -= 1.0                                  # the inner thigh, in the other leg's shadow
            if 87 <= y <= 90 and .2 < u < .5:
                v += .6                                   # the knee catching the light
            edge = any((x + dx, y + dy) not in cells and not parts.get((x + dx, y + dy), "").startswith("boot")
                       for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
            if edge:
                v = 1 if (x < 69.5 and (x - 1, y) not in cells and not far) else 0
            out[(x, y)] = ramp[max(0, min(len(ramp) - 1, round(v)))]; parts[(x, y)] = name
    return out, parts
