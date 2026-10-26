"""GATOS (Terran) crew concepts: one standing frame each, facing down, on the 35 x 35 crew tile.

Usage: python3 crew_concepts.py OUT_DIR
Each concept is drawn as its left half and mirrored; the right half is then shaded one step darker (light from the
upper left), and a few single pixels (glints) are added. Writes concept-*.svg and a sheet SVG.
"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "light-attack-frame"))

COLOURS = {
    "o": "#1a1e26",   # outline
    "w": "#eef2f6", "g": "#c3c9d1", "G": "#8d95a1",            # suit white, pale grey, grey
    "b": "#3f7fe0", "B": "#23498f",                            # GATOS blue trim
    "s": "#e8b896", "S": "#c48a6a",                            # skin
    "h": "#5a3e2c", "H": "#7a573e",                            # hair
    "v": "#1b2a44", "V": "#8fb8ff",                            # visor, glint
    "e": "#26303c",                                            # eyes
    "k": "#4a5260", "K": "#2e343e",                            # dark gear (belt, boots)
}
SHADE = {"w": "g", "g": "G", "b": "B", "s": "S", "h": "h", "H": "h", "k": "K"}


def sprite(half, extras=()):
    """half: rows of the left half, the last column on the centre line. Mirrored, right half shaded."""
    px = {}
    n = len(half[0])
    ox, oy = 17 - (n - 1), 35 - len(half) - 2
    for y, row in enumerate(half):
        for x, ch in enumerate(row):
            if ch == ".":
                continue
            px[(ox + x, oy + y)] = ch
            mx = ox + 2 * (n - 1) - x
            if mx != ox + x:
                px[(mx, oy + y)] = SHADE.get(ch, ch)
    for (x, y), ch in extras:
        px[(ox + x, oy + y)] = ch
    return {p: COLOURS[c] for p, c in px.items()}


# A. vac suit: a round helmet with a dark visor, blue shoulder trim, grey gloves and boots
A = sprite(["......ooo",
            "....oowww",
            "...owwwww",
            "...owvvvv",
            "...owvvvv",
            "...owwvvv",
            "....owwww",
            "..oooowgg",
            ".obbbwwww",
            "obbwwwwww",
            "obwowwwww",
            "obwowkkkk",
            "oGwowwwww",
            ".oooowwww",
            "....owwwg",
            "....owwgo",
            "....okkko",
            "....oooo."], [((5, 3), "V")])
# B. uniform jacket, bare head: hair, face, blue collar and a blue stripe down the front
B = sprite(["......ooo",
            "....oohhh",
            "...ohhhhh",
            "...ohhHhh",
            "...ohhsss",
            "...ohssss",
            "....osses",
            "....ossss",
            ".....oSSS",
            "..ooowwbb",
            ".owwwwwwb",
            "owwwwwwwb",
            "owwowwwwb",
            "owwowkkkk",
            "osgowwwww",
            ".oooogggg",
            "....oGGGo",
            "....okkko",
            "....oooo."])
# C. coverall with armoured shoulder pads and a blue harness: wider at the shoulders
C = sprite(["......ooo",
            "....oohhh",
            "...ohhhhh",
            "...ohhsss",
            "...ohssss",
            "....osses",
            "....ossss",
            "..oooosss",
            "oooggowww",
            "ogwwgowbw",
            "oggggowwb",
            ".oowowwwb",
            "..owowkkk",
            "..osowwww",
            "...oowwwg",
            "....owwgo",
            "....okkko",
            "....oooo."])
# D. vac suit, helmet off: a thick neck ring, a blue chevron on the chest (the Outrider's roundel mark)
D = sprite(["......ooo",
            "....oohhh",
            "...ohhhhh",
            "...ohhHhh",
            "...ohhsss",
            "...ohssss",
            "....osses",
            "....ossss",
            "...ooGGGG",
            "..oGgggoo",
            ".owwwwbww",
            "owwwwwwbw",
            "owwowwwwb",
            "owwowkkkk",
            "oGgowwwww",
            ".oooowwww",
            "....owwgo",
            "....okkko",
            "....oooo."])

CONCEPTS = [("A. Vac suit, helmet on", A), ("B. Uniform jacket", B), ("C. Coverall, shoulder pads", C),
            ("D. Vac suit, helmet off", D)]


def to_svg(px):
    return '<g shape-rendering="crispEdges">' + "".join(
        f'<rect x="{x}" y="{y}" width="1" height="1" fill="{c}"/>' for (x, y), c in px.items()) + "</g>"


if __name__ == "__main__":
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    S = 8
    tile = '<rect width="35" height="35" fill="#9da2aa"/>'
    cells = []
    for i, (name, px) in enumerate(CONCEPTS):
        x0 = 20 + i * (35 * S + 24)
        open(os.path.join(out, f"concept-{'abcd'[i]}.svg"), "w").write(
            f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 35 35" width="35" height="35">{to_svg(px)}</svg>\n')
        cells.append(f'<text x="{x0 + 35 * S / 2}" y="24" font-size="15" fill="#e6ebf2" text-anchor="middle" '
                     f'font-family="sans-serif">{name}</text>'
                     f'<g transform="translate({x0},36) scale({S})">{tile}{to_svg(px)}</g>'
                     f'<g transform="translate({x0 + 35 * S / 2 - 35},{48 + 35 * S}) scale(2)">{tile}{to_svg(px)}</g>'
                     f'<g transform="translate({x0 + 35 * S / 2 + 45},{48 + 35 * S + 17})">{tile}{to_svg(px)}</g>')
    W = 20 + 4 * (35 * S + 24)
    open(os.path.join(out, "concepts.svg"), "w").write(
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{48 + 35 * S + 90}">'
        f'<rect width="100%" height="100%" fill="#141920"/>{"".join(cells)}</svg>')
