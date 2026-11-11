"""Drawing helpers for the Tabby crew sheet: a frame is 35 x 35 pixels, drawn as text, one character a pixel."""
from PIL import Image

FRAME = 35
FLOOR = 32            # the row the boots' outline sits on, as on the other crew sheets
WIDE, TALL = 19, 23   # the standing figure's grid; a part's place is given in this grid's columns and rows
LEFT, TOP = (FRAME - WIDE) // 2, FLOOR + 1 - TALL

KEY = {
    "#": "#1a1220",                                    # the outline
    "Y": "#f0a850", "O": "#d9822b", "o": "#a85a1e",    # orange fur: lit, base, shade and tabby stripes
    "K": "#e89aa8",                                    # inside the ears
    "W": "#f3dcb8", "w": "#d6b48c",                    # the cream muzzle and paws
    "H": "#ffffff",                                    # the glint in each eye
    "N": "#e07a8a",                                    # the nose
    "C": "#e8d8b8", "c": "#bfa98a",                    # the shearling collar
    "Q": "#7d8a4c", "J": "#5f6b3a", "j": "#434c28",    # the olive bomber jacket
    "Z": "#c8a860",                                    # its zip
    "e": "#b8442e",                                    # a unit patch on the sleeve, merc red
    "S": "#f6c7a0",                                    # an old scar down the cheek
    "R": "#3a4222",                                    # its ribbed hem
    "d": "#2c331a",                                    # the seam where the sleeve's front edge meets the jacket
    "P": "#4a5466", "p": "#343b4a", "q": "#5f6a80",    # loose grey-blue pants
    "B": "#3a2a22", "b": "#5c4434",                    # leather boots, lit toe
    "D": "#2a1e18",                                    # the far boot in the side view, a step darker
    "T": "#4a3020",                                    # a strap across the chest, and a holster on the hip
    "X": "#22222a",                                    # the pistol's grip in the holster
    "G": "#b8b8c0",                                    # the strap's buckle
    "g": "#62626e",                                    # the pistol's lit steel: darker than a light deck
    "r": "#d62218", "M": "#8c1610",                    # the fire extinguisher: lit, shade
    "u": "#f0faff", "v": "#3aa0e8",                    # its spray
}


def rgba(code):
    return tuple(int(code[at:at + 2], 16) for at in (1, 3, 5)) + (255,)


def frame(*parts):
    """A frame from parts drawn back to front. A part is (grid, column, row): where its top left corner goes in the
    standing figure's grid. '.' is see-through."""
    picture = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
    for grid, column, row in parts:
        assert len({len(line) for line in grid}) == 1, "rows of different widths: %r" % (grid,)
        for j, line in enumerate(grid):
            for i, character in enumerate(line):
                if character != ".":
                    picture.putpixel((LEFT + column + i, TOP + row + j), rgba(KEY[character]))
    return picture


def mirrored(picture):
    return picture.transpose(Image.FLIP_LEFT_RIGHT)


def strip(frames, scale=8, background=(0xc9, 0xcf, 0xd8, 255), gap=1):
    """Frames side by side on the deck's colour, for looking at closely."""
    out = Image.new("RGBA", (len(frames) * (FRAME * scale + gap) - gap, FRAME * scale), (0x30, 0x36, 0x40, 255))
    for number, picture in enumerate(frames):
        tile = Image.new("RGBA", (FRAME, FRAME), background)
        tile.alpha_composite(picture)
        out.alpha_composite(tile.resize((FRAME * scale, FRAME * scale), Image.NEAREST), (number * (FRAME * scale + gap), 0))
    return out


def gif(frames, path, milliseconds, scale=4, background=(0xc9, 0xcf, 0xd8, 255)):
    tiles = []
    for picture in frames:
        tile = Image.new("RGBA", (FRAME, FRAME), background)
        tile.alpha_composite(picture)
        tiles.append(tile.resize((FRAME * scale, FRAME * scale), Image.NEAREST).convert("P", palette=Image.ADAPTIVE))
    tiles[0].save(path, save_all=True, append_images=tiles[1:], duration=milliseconds, loop=0)


def close(frames, scale=14, box=(2, 0, 34, 35), background=(0xc9, 0xcf, 0xd8, 255)):
    """The figure's part of each frame, enlarged a lot, for checking pixels."""
    wide, tall = (box[2] - box[0]) * scale, (box[3] - box[1]) * scale
    out = Image.new("RGBA", (len(frames) * (wide + 2) - 2, tall), (0x30, 0x36, 0x40, 255))
    for number, picture in enumerate(frames):
        tile = Image.new("RGBA", (FRAME, FRAME), background)
        tile.alpha_composite(picture)
        out.alpha_composite(tile.crop(box).resize((wide, tall), Image.NEAREST), (number * (wide + 2), 0))
    return out


def tail(path):
    """A tail one pixel thick along a path of (column, row) from root to tip: striped, pale at the tip, with its own
    outline all round. Returns a part for frame()."""
    left = min(x for x, y in path) - 1
    top = min(y for x, y in path) - 1
    wide = max(x for x, y in path) + 2 - left
    tall = max(y for x, y in path) + 2 - top
    grid = [["."] * wide for row in range(tall)]
    for x, y in path:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            grid[y + dy - top][x + dx - left] = "#"
    for number, (x, y) in enumerate(path):
        grid[y - top][x - left] = "Y" if number == len(path) - 1 else "o" if number % 3 == 2 else "O"
    return (["".join(row) for row in grid], left, top)


def dots(points):
    """Loose pixels, such as spray: (column, row, character) in the figure's grid. Returns a part for frame()."""
    left = min(x for x, y, c in points)
    top = min(y for x, y, c in points)
    grid = [["."] * (max(x for x, y, c in points) + 1 - left) for row in range(max(y for x, y, c in points) + 1 - top)]
    for x, y, c in points:
        grid[y - top][x - left] = c
    return (["".join(row) for row in grid], left, top)
