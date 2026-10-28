"""GATOS crew, vector test: the long-coat drifter on heromedel's rig (front, the 1/2 view), in a 70 x 70 viewBox.
Rounded shapes with soft, low-contrast gradients (light from the upper left), anatomy from the rig's joints."""
import sys

J = {"head_top": (35, 9.5), "neck_base": (35, 15.6), "shoulder_r": (26.5, 18.7), "shoulder_l": (43.5, 18.7),
     "elbow_r": (23.6, 24.1), "elbow_l": (46.6, 24.1), "waist": (35, 26.2), "pelvis": (35, 30.9),
     "hip_r": (30.8, 30.7), "hip_l": (39.4, 30.7), "wrist_r": (21.6, 32.5), "wrist_l": (48.5, 32.5),
     "knee_r": (30.5, 45.5), "knee_l": (39.6, 45.5), "ankle_r": (30.4, 56.3), "ankle_l": (39.8, 56.3)}

SKIN, SKIN_SH, SKIN_HI = "#d39a7e", "#a8705a", "#edc2a6"
HAIR, HAIR_SH, HAIR_HI = "#4b3122", "#2c1b12", "#6e4c36"
COAT, COAT_SH, COAT_HI = "#7d4c2e", "#55311d", "#a0683f"
SHIRT, SHIRT_SH = "#3f7470", "#2b5250"
PANTS, PANTS_SH = "#363f50", "#232a37"
BOOT, BOOT_SH, BOOT_HI = "#33292a", "#1d1718", "#544443"
LINE = "#1a1210"


def grad(gid, light, dark, x1=0, y1=0, x2=1, y2=1):
    return (f'<linearGradient id="{gid}" x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}">'
            f'<stop offset="0" stop-color="{light}"/><stop offset="1" stop-color="{dark}"/></linearGradient>')


def path(d, fill, stroke=LINE, sw=.35, extra=""):
    return f'<path d="{d}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}" stroke-linejoin="round" {extra}/>'


DEFS = "".join([
    grad("skin", SKIN_HI, SKIN_SH), grad("coat", COAT_HI, COAT_SH), grad("coatd", COAT, COAT_SH, 0, 0, 1, 0),
    grad("shirt", SHIRT, SHIRT_SH), grad("pants", PANTS, PANTS_SH, 0, 0, 1, 0), grad("boot", BOOT_HI, BOOT_SH),
    grad("hair", HAIR_HI, HAIR_SH, 0, 0, .6, 1),
    '<radialGradient id="face" cx=".38" cy=".42" r=".7"><stop offset="0" stop-color="%s"/><stop offset=".55" stop-color="%s"/>'
    '<stop offset="1" stop-color="%s"/></radialGradient>' % (SKIN_HI, SKIN, SKIN_SH),
    '<radialGradient id="ao"><stop offset="0" stop-color="#000" stop-opacity=".35"/><stop offset="1" stop-color="#000" stop-opacity="0"/></radialGradient>',
])


def figure():
    out = []
    # legs: tapered trousers with a slight knee, the far leg a touch darker
    out.append(path("M30.8 31 C28.6 36 28.8 41 29.3 45.5 C29.4 50 29.3 53.5 29.1 56.5 L32.1 56.5 C32.4 53 32.6 49 32.4 45.5 C32.8 41 33.6 36 34.6 31 Z", "url(#pants)"))
    out.append(path("M35.6 31 C36.8 36 37.6 41 38 45.5 C37.9 49 38.1 53 38.4 56.5 L41.2 56.5 C41.1 53.5 41 50 41.1 45.5 C41.6 41 41.6 36 39.6 31 Z", "url(#pants)", extra='opacity=".93"'))
    # boots, a matched pair seen from above the toe
    for cx in (30.6, 39.8):
        out.append(path(f"M{cx-2} 55.6 L{cx+1.9} 55.6 L{cx+2.1} 59 C{cx+2.6} 60.5 {cx+2.4} 61.8 {cx+1.2} 62.2 L{cx-1.4} 62.2 C{cx-2.6} 61.8 {cx-2.7} 60.5 {cx-2.2} 59 Z", "url(#boot)"))
        out.append(f'<path d="M{cx-1.6} 60.9 Q{cx} 61.6 {cx+1.6} 60.9" fill="none" stroke="{BOOT_HI}" stroke-width=".3" opacity=".6"/>')
    # shirt, seen between the coat's open fronts
    out.append(path("M32.4 16.4 L37.6 16.4 L37.2 31.5 L32.8 31.5 Z", "url(#shirt)"))
    out.append(f'<path d="M35 18 L35 30" stroke="{SHIRT_SH}" stroke-width=".25"/>')
    for y in (21, 24.5, 28):
        out.append(f'<circle cx="35" cy="{y}" r=".3" fill="{SHIRT_SH}"/>')
    # far sleeve (behind), then the coat body, then the near sleeve
    out.append(path("M41.4 17 C45 17.4 47 19.8 47.5 23.6 C48 27.2 48.8 30.1 49.6 32.6 L46.6 33.3 C45.7 30.6 44.7 27.9 44.1 25 C43.4 22.6 42.6 21.6 41.4 21 Z", "url(#coatd)"))
    near = ("M34 15.8 C31 15.7 28.6 16.4 27.6 18 C27.2 20.5 27.4 24 27.3 27.5 C27 33 26 40 25.2 47.5 "
            "C25 49.6 26 50.8 27.6 50.6 C29.8 50.6 31.9 50.4 33.9 50.6 C34 44 34.1 37 34.2 31 Z")
    far = ("M36 15.8 C39 15.7 41.4 16.4 42.4 18 C42.8 20.5 42.6 24 42.7 27.5 C43 33 44 40 44.8 47.5 "
           "C45 49.6 44 50.8 42.4 50.6 C40.2 50.6 38.1 50.4 36.1 50.6 C36 44 35.9 37 35.8 31 Z")
    out.append(path(far, "url(#coatd)"))
    out.append(path(near, "url(#coat)"))
    # coat folds: soft shadows hanging from the belt, drifting outward, lit on their upper-left side
    for d in ("M29.6 31.5 C29.3 37 28.8 43 28 50", "M41 31.5 C41.4 37 42 43 42.8 50"):
        out.append(f'<path d="{d}" fill="none" stroke="{COAT_SH}" stroke-width=".9" stroke-linecap="round" opacity=".55"/>')
    for d in ("M28.9 34 C28.6 39 28.2 44 27.5 49",):
        out.append(f'<path d="{d}" fill="none" stroke="{COAT_HI}" stroke-width=".5" stroke-linecap="round" opacity=".45"/>')
    # lapels folded back, the near one catching the light, a soft shadow beneath each
    out.append(path("M34 15.9 L31.2 16.6 L32.6 23.5 L34.1 25.5 Z", COAT_HI, sw=.3))
    out.append(path("M36 15.9 L38.8 16.6 L37.4 23.5 L35.9 25.5 Z", COAT, sw=.3))
    out.append(f'<path d="M31.4 17 L32.7 23.7" stroke="{COAT_SH}" stroke-width=".35" opacity=".7"/>')
    # belt with a buckle
    out.append(path("M27.2 29.4 C29.5 29.9 33 30 34.2 30 L34.2 31.2 C33 31.2 29.5 31.1 27.1 30.6 Z", "#2a1c14", sw=.2))
    out.append(path("M35.8 30 C37 30 40.5 29.9 42.8 29.4 L42.9 30.6 C40.5 31.1 37 31.2 35.8 31.2 Z", "#2a1c14", sw=.2))
    out.append('<rect x="32.9" y="29.7" width="1.5" height="1.8" rx=".2" fill="none" stroke="#c8a860" stroke-width=".35"/>')
    # near sleeve over the coat
    out.append(path("M28.6 17 C25 17.4 23 19.8 22.5 23.6 C22 27.2 21.2 30.1 20.4 32.6 L23.4 33.3 C24.3 30.6 25.3 27.9 25.9 25 C26.6 22.6 27.4 21.6 28.6 21 Z", "url(#coat)"))
    out.append(f'<path d="M24.3 18.6 C23.4 20.4 23.2 22.4 23.1 24.4" stroke="{COAT_HI}" stroke-width=".45" fill="none" opacity=".6"/>')
    # hands: palm, a thumb and a hint of fingers
    for (x, y, f) in ((21.9, 33.6, 1), (48.1, 33.6, -1)):
        out.append(path(f"M{x-1*f} {y-.6} C{x-1.3*f} {y+.8} {x-1*f} {y+2.2} {x} {y+2.5} C{x+1*f} {y+2.3} {x+1.2*f} {y+1} {x+1*f} {y-.6} Z", "url(#skin)", sw=.3))
        out.append(path(f"M{x+.9*f} {y} C{x+1.6*f} {y+.4} {x+1.7*f} {y+1.1} {x+1.3*f} {y+1.5} Z", "url(#skin)", sw=.25))    # thumb
        out.append(f'<path d="M{x-.35*f} {y+1.2} L{x-.4*f} {y+2.2} M{x+.25*f} {y+1.2} L{x+.25*f} {y+2.2}" stroke="{SKIN_SH}" stroke-width=".18"/>')
    # personal emblem: a small faded gold diamond, stitched on the near breast
    out.append('<path d="M29.4 19.3 L30.4 20.4 L29.4 21.5 L28.4 20.4 Z" fill="#c8a050" stroke="#7a5a28" stroke-width=".2"/>'
               '<circle cx="29.4" cy="20.4" r=".3" fill="#3a2416"/>')
    out.append(head())
    return "".join(out)


def head():
    """A head seen from about 45 degrees above: the crown and hair take the top, the face sits lower and is a little
    foreshortened; almond eyes with whites under a brow shadow, a nose by its shadow, a quiet mouth, ears."""
    h = []
    h.append(path("M33.4 14.2 L36.6 14.2 L36.8 16.6 L33.2 16.6 Z", SKIN_SH, sw=.25))                     # neck
    h.append(path("M30.9 10.6 C30.3 11.7 30.7 12.6 31.4 12.5 Z", SKIN_SH, sw=.25))                       # ears
    h.append(path("M39.1 10.6 C39.7 11.7 39.3 12.6 38.6 12.5 Z", SKIN_SH, sw=.25))
    h.append(path("M31 8.4 C31 5.2 33 3.8 35 3.8 C37 3.8 39 5.2 39 8.4 C39.1 10.8 38.6 12.6 37.3 14 "
                  "C36.3 14.9 33.7 14.9 32.7 14 C31.4 12.6 30.9 10.8 31 8.4 Z", "url(#face)", sw=.35))          # face
    # tousled hair, the crown seen from above: an uneven fringe in tufts, strands catching the light
    h.append(path("M30.7 10.3 C29.8 5.6 32 2.8 35.1 2.8 C38.3 2.8 40.2 5.4 39.4 10 L38.9 8.6 L38.3 9.4 L37.8 8.2 "
                  "L36.9 8.9 L36.4 7.9 L35.5 8.7 L34.9 7.8 L34 8.6 L33.4 7.9 L32.6 8.9 L32 8.2 L31.5 9.5 Z", "url(#hair)", sw=.35))
    for d, c, w in (("M31.9 6.2 C33 4.6 34.8 4 36.6 4.3", HAIR_HI, .45), ("M33 7.6 C33.6 6 34.6 5 35.8 4.6", HAIR_HI, .3),
                    ("M36.4 7.6 C37 6.2 37.8 5.6 38.6 5.6", HAIR_SH, .3), ("M34.6 3.4 C35.6 4.4 36 5.6 36 6.8", HAIR_SH, .25)):
        h.append(f'<path d="{d}" fill="none" stroke="{c}" stroke-width="{w}" stroke-linecap="round" opacity=".75"/>')
    h.append(f'<path d="M32 10.7 C33.2 10.3 36.8 10.3 38 10.7" fill="none" stroke="{SKIN_SH}" stroke-width=".8" opacity=".45"/>')   # brow shadow
    for ex, s in ((33.4, 1), (36.6, -1)):
        h.append(f'<path d="M{ex-.95} 10.25 Q{ex} 9.85 {ex+.95} 10.15" fill="none" stroke="{HAIR_SH}" stroke-width=".42" stroke-linecap="round"/>')
        h.append(f'<path d="M{ex-.75} 11.15 Q{ex} 10.7 {ex+.75} 11.15 Q{ex} 11.5 {ex-.75} 11.15 Z" fill="#efe6dc"/>')
        h.append(f'<circle cx="{ex+.1*s}" cy="11.12" r=".33" fill="#4a3424"/><circle cx="{ex+.1*s}" cy="11.12" r=".15" fill="{LINE}"/>')
        h.append(f'<path d="M{ex-.8} 11.12 Q{ex} 10.65 {ex+.8} 11.12" fill="none" stroke="{LINE}" stroke-width=".25"/>')
    h.append(f'<path d="M35.2 11.3 L35.55 12.5 L34.9 12.7" fill="none" stroke="{SKIN_SH}" stroke-width=".3" stroke-linejoin="round"/>')   # nose
    h.append(f'<path d="M34.2 13.35 Q35 13.6 35.8 13.35" fill="none" stroke="#7a4a3c" stroke-width=".3" stroke-linecap="round"/>')       # mouth
    h.append(f'<path d="M33.1 13.9 C34 14.5 36 14.5 36.9 13.9" fill="none" stroke="{SKIN_SH}" stroke-width=".3" opacity=".4"/>')       # stubble along the jaw
    return "".join(h)


def svg(scale, bg="#9da2aa"):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 70 70" width="{70*scale}" height="{70*scale}">'
            f'<defs>{DEFS}</defs><rect width="70" height="70" fill="{bg}"/>{figure()}</svg>')


if __name__ == "__main__":
    open(sys.argv[1], "w").write(svg(float(sys.argv[2])))
