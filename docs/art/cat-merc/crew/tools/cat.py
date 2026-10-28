"""A mercenary cat crew sprite (a new race, working name only): pixel art on the crew grid, a 35 x 35 frame, facing
down, about human height (22 pixels, shorter than the Mecha crew's 25). Cute but tough: a big head with big glinting
eyes, a pink nose and cheek fluff, but level, half-lowered lids (a calm, unimpressed look), no mouth line, a notched ear and a scar down the cheek; a bandolier strap
across a bomber jacket and a pistol holstered on his hip; the jacket has a shearling
collar, a unit patch on the sleeve and a ribbed hem; loose pants gathered over heavy boots; a striped tail with a curl.

Usage: python3 cat.py OUT_DIR      (writes cat-merc.svg, the other facings, a sheet beside the Mecha and Tentauri
                                   crews, and the four facings side by side)"""
import os
import sys
from PIL import Image

FIGURE = [
    ".....#......##.....",
    "....#Y#....#oO#....",
    "...#YKO#####OKO#...",
    "...#YOOoOoOoOOo#...",
    "...#YOOOOOOOOOo#...",
    "...#YO##OOO##Oo#...",
    "...#YSH#WWWH#Oo#...",
    "...#YSOWWNWWOOo#...",
    "...#YOOWWWWWOOo#...",
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
    "N": "#e07a8a",                                    # the nose (no mouth line: it read as a mustache)
    "C": "#e8d8b8", "c": "#bfa98a",                    # the shearling collar
    "Q": "#7d8a4c", "J": "#5f6b3a", "j": "#434c28",    # the olive bomber jacket
    "Z": "#c8a860",                                    # its zip
    "e": "#b8442e",                                    # a unit patch on the sleeve, merc red
    "S": "#f6c7a0",                                    # an old scar down the cheek
    "R": "#3a4222",                                    # its ribbed hem
    "d": "#2c331a",                                    # the seam where the sleeve's front edge meets the jacket
    "P": "#4a5466", "p": "#343b4a", "q": "#5f6a80",    # loose grey-blue pants
    "B": "#3a2a22", "b": "#5c4434",                    # leather boots, lit toe (brown, so they part from the pants)
    "D": "#2a1e18",                                    # the far boot in the side view, a step darker
    "T": "#4a3020",                                    # a strap across the chest, and a holster on the hip
    "X": "#22222a",                                    # the pistol's grip in the holster
    "G": "#b8b8c0",                                    # the strap's buckle
}
# the tail, hanging from behind his hip on his left (our right), curling up at the tip: (column, row) in the grid
TAIL = [((17, 15), "#"), ((17, 16), "O"), ((18, 16), "#"), ((17, 17), "o"), ((18, 17), "#"), ((16, 17), "#"),
        ((17, 18), "O"), ((18, 18), "#"), ((17, 19), "o"), ((18, 19), "O"), ((19, 19), "#"), ((17, 20), "#"),
        ((18, 20), "#"), ((19, 18), "Y"), ((20, 18), "#"), ((19, 17), "#"), ((20, 19), "#"), ((19, 20), "#")]
# from behind: the backs of the ears (the notched one now on our left), tabby stripes down the back of the head, the
# collar all the way round, the strap coming over his left shoulder, the jacket's back with its ribbed hem all the way
# across (his arms and paws are in front of him, hidden by his body: heromedel), and the tail from under the jacket sweeping down across his right calf with a curl (it's nearest to us,
# so it's drawn over him; heromedel: swung across his seat it looked like he was scratching his butt, and straight down
# between his legs it read as crude). The holster is on his hip at the side, out of sight from here
BACK = [
    ".....##......#.....",
    "....#Yo#....#O#....",
    "...#YOO#####OOo#...",
    "...#YOOoOoOoOOo#...",
    "...#YOOoOOOoOOo#...",
    "...#YOOoOOOoOOo#...",
    "...#YOOOOOOOOOo#...",
    "...#YOOOOOOOOOo#...",
    "...#YOOOOOOOOOo#...",
    "....#oOOOOOOOo#....",
    "...#CCCCCcCCCcc#...",
    "..#CCcCCCCCCCcCC#..",
    "..#QJJJTJJJJJJJj#..",
    "..#QJJJJTJJJJJJj#..",
    "..#QJjJJJTJJJjJj#..",
    "..#RRRRRRRRRRRRR#..",
    "...#qPPPPpPPPPp#...",
    "...#qPPPPpPPPPp#...",
    "..#qPPPPp#pPPPPp#..",
    "..#qPPPp#.#pPPPp#..",
    "...#ppp#...#ppp#...",
    "..#BBBB#...#BBBB#..",
    "..######...######..",
]
# facing right: his right side, so the patch, the strap's end and the holster are on our side; the near ear in front,
# the far (notched) ear just behind it; the muzzle out to the right with the nose at its tip; the near arm hanging at
# his side over the jacket; the legs one just behind the other; the boots' toes to the right; the tail behind him,
# curling up
SIDE = [
    "......#...#........",
    ".....#o#.#Y#.......",
    ".....#oO#YKO#......",
    "....#OOoOoOOO#.....",
    "....#YOOOOOOOO#....",
    "....#YOOOO##OO#....",
    "....#YOoOOH#OOO#...",
    "....#YOOOOOOWWN#...",
    "....#oOOOOOOWW#....",
    ".....#oOOOOOw#.....",
    "....#CCCCCCCCC#....",
    "...#CCQJJCCCCC#....",
    "...#QJQJJdJJJZ#....",
    "...#QJQeJdJJTj#....",
    "...#QJQJJdJTJj#....",
    "...#jRjjjdRRRj#....",
    "...#q#Oo#PPPPp#....",
    "...#qX##PPPPPp#....",
    "...#qTPPPPPPPp#....",
    "...#ppp#qPPPPp#....",
    "...#ppp#qPPPp#.....",
    "...#DDD#BBBBBBb#...",
    "...#############...",
]
# the tails as paths of pixels from the root to the tip, outlined where they're drawn: (column, row) in the grid
SIDE_TAIL = [(3, 17), (2, 17), (2, 16), (2, 15), (1, 14), (1, 13), (2, 12)]          # from the hip, curling up behind
BACK_TAIL = [(9, 16), (10, 17), (11, 18), (12, 19), (13, 19), (14, 18)]   # from the waist across his right calf, curling up
FRAME, FLOOR = 35, 32
VIEWS = {"down": (FIGURE, TAIL, None), "up": (BACK, None, BACK_TAIL), "right": (SIDE, None, SIDE_TAIL)}


def pixels(view="down"):
    """The sprite facing `view` (down, up, right, or left: the right view mirrored)."""
    if view == "left":
        return {(FRAME - 1 - x, y): c for (x, y), c in pixels("right").items()}
    grid, tail, path = VIEWS[view]
    top = FLOOR + 1 - len(grid)
    left = (FRAME - len(grid[0])) // 2
    out = {}
    for (i, j), ch in tail or []:                       # a tail drawn pixel by pixel, behind the figure
        out[(left + i, top + j)] = KEY[ch]
    for j, row in enumerate(grid):
        for i, ch in enumerate(row):
            if ch != ".":
                out[(left + i, top + j)] = KEY[ch]
    if path:                                           # a tail drawn along a path, striped, with its own outline
        cells = [(left + i, top + j) for i, j in path]
        for n, q in enumerate(cells):
            out[q] = KEY["Y" if n == len(cells) - 1 else "o" if n % 3 == 2 else "O"]     # a pale tip
        for (x, y) in cells:
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                q = (x + dx, y + dy)
                if q not in cells and (path is BACK_TAIL or q not in out):
                    out[q] = KEY["#"]
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
    for grid in (FIGURE, BACK, SIDE):
        assert len({len(r) for r in grid}) == 1, "rows of different widths"
    px = pixels()
    open(os.path.join(out_dir, "cat-merc.svg"), "w").write(svg(px))
    views = [(v, pixels(v)) for v in ("down", "right", "up", "left")]
    for v, p in views[1:]:
        open(os.path.join(out_dir, f"cat-merc-{v}.svg"), "w").write(svg(p))
    four = Image.new("RGBA", (4 * 220 + 10 + 4 * 45, 230), (110, 114, 122, 255))
    for n, (v, p) in enumerate(views):
        four.alpha_composite(image(p).resize((210, 210), Image.NEAREST), (10 + n * 220, 10))
        four.alpha_composite(image(p), (4 * 220 + n * 45, 180))
    four.save(os.path.join(out_dir, "cat-merc-views.png"))
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
