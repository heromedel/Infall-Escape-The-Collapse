"""A mercenary cat crew sprite (a new race, working name only): pixel art on the crew grid, a 35 x 35 frame, facing
down, about human height (22 pixels, shorter than the Mecha crew's 25). Cute but tough: a big head with big glinting
eyes, a pink nose and cheek fluff, but stern brows (high at the outside, low toward the nose; the other way round read as sad), a smirk, a notched ear and a scar down the cheek; a bandolier strap
across a bomber jacket and a pistol holstered on his hip; the jacket has a shearling
collar, a unit patch on the sleeve and a ribbed hem; loose pants gathered over heavy boots; a striped tail with a curl.

Usage: python3 cat.py OUT_DIR      (writes cat-merc.svg and a sheet beside the Mecha and Tentauri crews)"""
import os
import sys
from PIL import Image

FIGURE = [
    ".....#......##.....",
    "....#Y#....#oO#....",
    "...#YKO#####OKO#...",
    "...#YOOoOoOoOOo#...",
    "...#YO#OOOOO#Oo#...",
    "...#YO##OOO##Oo#...",
    "...#YSH#WWWH#Oo#...",
    "...#YSOWWNWmOOo#...",
    "...#YOOWWmmWOOo#...",
    "....#oOOWWWOOo#....",
    "...#CCC#####CCC#...",
    "..#CCcCJJZJJCcCC#..",
    "..#QJJcJjZjTcJJj#..",
    "..#QeJ#JjZTJ#JJj#..",
    "..#QJJ#JjGjJ#JJj#..",
    "..#jjj#RTRRR#jjj#..",
    "..#WWw#PPPpP#wWW#..",
    "...#qPXPPpPPPPp#...",
    "..#qPTTPp#pPPPPp#..",
    "..#qPPPp#.#pPPPp#..",
    "...#ppp#...#ppp#...",
    "..#bBBB#...#bBBB#..",
    "..######...######..",
]
KEY = {
    "#": "#1a1220",                                    # the outline
    "Y": "#f0a850", "O": "#d9822b", "o": "#a85a1e",    # orange fur: lit, base, shade and tabby stripes
    "K": "#e89aa8",                                    # inside the ears
    "W": "#f3dcb8", "w": "#d6b48c",                    # the cream muzzle and paws
    "H": "#ffffff",                                    # the glint in each eye
    "N": "#e07a8a", "m": "#a8705a",                    # nose, mouth: a smirk, up at one side (soft: dark read as a gasp)
    "C": "#e8d8b8", "c": "#bfa98a",                    # the shearling collar
    "Q": "#7d8a4c", "J": "#5f6b3a", "j": "#434c28",    # the olive bomber jacket
    "Z": "#c8a860",                                    # its zip
    "e": "#b8442e",                                    # a unit patch on the sleeve, merc red
    "S": "#f6c7a0",                                    # an old scar down the cheek
    "R": "#3a4222",                                    # its ribbed hem
    "P": "#4a5466", "p": "#343b4a", "q": "#5f6a80",    # loose grey-blue pants
    "B": "#3a2a22", "b": "#5c4434",                    # leather boots, lit toe (brown, so they part from the pants)
    "T": "#4a3020",                                    # a strap across the chest, and a holster on the hip
    "X": "#22222a",                                    # the pistol's grip in the holster
    "G": "#b8b8c0",                                    # the strap's buckle
}
# the tail, hanging from behind his hip on his left (our right), curling up at the tip: (column, row) in the grid
TAIL = [((17, 15), "#"), ((17, 16), "O"), ((18, 16), "#"), ((17, 17), "o"), ((18, 17), "#"), ((16, 17), "#"),
        ((17, 18), "O"), ((18, 18), "#"), ((17, 19), "o"), ((18, 19), "O"), ((19, 19), "#"), ((17, 20), "#"),
        ((18, 20), "#"), ((19, 18), "O"), ((20, 18), "#"), ((19, 17), "#"), ((20, 19), "#"), ((19, 20), "#")]
FRAME, FLOOR = 35, 32


def pixels():
    top = FLOOR + 1 - len(FIGURE)
    left = (FRAME - len(FIGURE[0])) // 2
    out = {}
    for (i, j), ch in TAIL:                             # behind the figure
        out[(left + i, top + j)] = KEY[ch]
    for j, row in enumerate(FIGURE):
        for i, ch in enumerate(row):
            if ch != ".":
                out[(left + i, top + j)] = KEY[ch]
    return out


def svg(px, scale=4):
    rects = "".join(f'<rect x="{x}" y="{y}" width="1" height="1" fill="{c}"/>' for (x, y), c in sorted(px.items()))
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {FRAME} {FRAME}" width="{FRAME * scale}" '
            f'height="{FRAME * scale}" shape-rendering="crispEdges">{rects}</svg>\n')


def image(px, bg=(110, 114, 122, 255)):
    im = Image.new("RGBA", (FRAME, FRAME), bg)
    for p, c in px.items():
        im.putpixel(p, tuple(int(c[i:i + 2], 16) for i in (1, 3, 5)) + (255,))
    return im


if __name__ == "__main__":
    out_dir = sys.argv[1]; os.makedirs(out_dir, exist_ok=True)
    assert len({len(r) for r in FIGURE}) == 1, "rows of different widths"
    px = pixels()
    open(os.path.join(out_dir, "cat-merc.svg"), "w").write(svg(px))
    here = os.path.dirname(os.path.abspath(__file__))
    art = os.path.join(here, "..", "..", "..")
    refs = [Image.open(os.path.join(art, p)).convert("RGBA").crop((0, 0, 35, 35))
            for p in ("mecha/crew/mecha-crew-sheet.png", "tentauri/crew/tentauri-crew-sheet.png")]
    tiles = []
    for t in refs[:1] + [image(px)] + refs[1:]:
        bg = Image.new("RGBA", (35, 35), (110, 114, 122, 255)); bg.alpha_composite(t); tiles.append(bg)
    sheet = Image.new("RGBA", (3 * 35 * 6 + 40 + 3 * 45, 35 * 6 + 20), (110, 114, 122, 255))
    for n, t in enumerate(tiles):
        sheet.alpha_composite(t.resize((210, 210), Image.NEAREST), (10 + n * 220, 10))
        sheet.alpha_composite(t, (3 * 220 + 20 + n * 45, 180))
    sheet.save(os.path.join(out_dir, "cat-merc-sheet.png"))
