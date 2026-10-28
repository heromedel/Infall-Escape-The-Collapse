"""The drifter drawn by hand at game size, the Mecha crew's: a 25-pixel figure in a 35-pixel frame, with a one-pixel
black outline round every big shape (head, sleeves, coat, legs, boots), as the Mecha crew has.

Round 3c: shrinking the 2x drifter automatically broke the outline (the face not closed off, one-pixel boots, holes
between the legs), because a 25-pixel figure can't keep a 114-pixel one's structure by averaging. So it is drawn here
pixel by pixel, using the 2x drifter only as the reference for proportions and colours.

Usage: python3 tiny.py OUT_DIR      (writes drifter-tiny.svg and a sheet beside the Mecha crew)"""
import os
import sys

# one row per pixel row, feet on the frame's row 32 as in the Mecha crew frame; "." is empty
FIGURE = [
    "......#####......",
    ".....#hihHH#.....",
    ".....#hSSSH#.....",
    ".....#SeSes#.....",
    ".....#SSmSs#.....",
    "....#llSSsCC#....",
    "...#LLClTlCcc#...",
    "..#LCdClTlcdCc#..",
    "..#LCdelTlcdCc#..",
    "..#LCdClTlcdCc#..",
    "..#LCdCCTCcdCc#..",
    "..#LCdCCTCcdCc#..",
    "..#LCdbbgbbdCc#..",
    "..#ccdCCPCcdcc#..",
    "..#FFdCCPCcdFf#..",
    "..#FfdCCPCcdff#..",
    "..#LCCCCPCCccc#..",
    "..#LCcCCPCCcdc#..",
    ".#CCCcCC#CCcdcc#.",
    ".#uuuuuu#uuuuuu#.",
    "..##PPp#.#PPp##..",
    "...#PPp#.#PPp#...",
    "..#kKKK#.#kKKK#..",
    "..#KKKK#.#KKKK#..",
    "..######.######..",
]
KEY = {
    "#": "#0a0a0e",                                    # the outline, the Mecha crew's black
    "h": "#523826", "H": "#2a1a12",                    # hair, lit and shaded
    "S": "#c08a6c", "s": "#a26a52", "e": "#3a2418", "m": "#9a5a48",   # skin lit, shaded, eyes, mouth (soft,
                                                                       # or it reads as a bruise or a nose)
    "i": "#6a4a30",                                    # a highlight in the hair
    "L": "#7f5732", "C": "#563622", "c": "#311d18",    # coat lit, base, shade
    "d": "#1c100c", "u": "#43291d",                    # (u: the hem, a step up from the shade)
    "b": "#24140e",                                    # the belt: dark leather, not the outline's black                                    # the seams between sleeve and coat: darkest brown, not black,
                                                       # so the body doesn't split into separate black-cased tubes
    "l": "#94693c",                                    # the lapels and collar, catching the light
    "T": "#363a2e",                                    # the henley
    "g": "#c8a860",                                    # the buckle
    "P": "#262c39", "p": "#191d27",                    # trousers
    "F": "#c08a6c", "f": "#86523f",                    # hands
    "K": "#3a3333", "k": "#5a4c46",                    # boots, and their lit toe
}
EMBLEM = "#a89878"                                     # "e" below the face rows: the emblem, a pale slash
FRAME, FLOOR = 35, 32


def pixels():
    top = FLOOR + 1 - len(FIGURE)
    left = (FRAME - len(FIGURE[0])) // 2
    out = {}
    for j, row in enumerate(FIGURE):
        for i, ch in enumerate(row):
            if ch == ".":
                continue
            col = EMBLEM if (ch == "e" and j > 4) else KEY[ch]
            out[(left + i, top + j)] = col
    return out


def svg(px, scale=4):
    rects = "".join(f'<rect x="{x}" y="{y}" width="1" height="1" fill="{c}"/>' for (x, y), c in sorted(px.items()))
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {FRAME} {FRAME}" width="{FRAME * scale}" '
            f'height="{FRAME * scale}" shape-rendering="crispEdges">{rects}</svg>\n')


def sheet(px, path):
    """The drifter beside the Mecha crew's first frame: enlarged 6x on two backgrounds, and at true size."""
    from PIL import Image, ImageDraw
    here = os.path.dirname(os.path.abspath(__file__))
    mech = Image.open(os.path.join(here, "..", "..", "..", "mecha", "crew", "mecha-crew-sheet.png")).convert("RGBA").crop((0, 0, 35, 35))
    me = Image.new("RGBA", (35, 35))
    for p, c in px.items():
        me.putpixel(p, tuple(int(c[i:i + 2], 16) for i in (1, 3, 5)) + (255,))
    out = Image.new("RGBA", (2 * 2 * 210 + 3 * 20 + 2 * 45 + 20, 250))
    d = ImageDraw.Draw(out)
    x = 0
    for bg in ((40, 44, 52, 255), (120, 124, 132, 255)):
        tile = Image.new("RGBA", (2 * 210 + 30, 250), bg)
        tile.alpha_composite(mech.resize((210, 210), Image.NEAREST), (10, 10))
        tile.alpha_composite(me.resize((210, 210), Image.NEAREST), (230, 10))
        out.alpha_composite(tile, (x, 0)); x += tile.width
    tile = Image.new("RGBA", (out.width - x, 250), (40, 44, 52, 255))
    tile.alpha_composite(mech, (10, 180)); tile.alpha_composite(me, (55, 180))
    out.alpha_composite(tile, (x, 0))
    out.resize((out.width * 2 // 2, out.height * 2 // 2)).save(path)


if __name__ == "__main__":
    out_dir = sys.argv[1]; os.makedirs(out_dir, exist_ok=True)
    assert len({len(r) for r in FIGURE}) == 1, "rows of different widths"
    px = pixels()
    open(os.path.join(out_dir, "drifter-tiny.svg"), "w").write(svg(px))
    sheet(px, os.path.join(out_dir, "drifter-tiny-sheet.png"))
    print(len(px), "pixels")
