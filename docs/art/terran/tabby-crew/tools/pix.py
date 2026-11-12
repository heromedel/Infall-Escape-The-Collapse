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
}


def rgba(code):
    return tuple(int(code[at:at + 2], 16) for at in (1, 3, 5)) + (255,)


CONCEPT_GAP = (24, 30)        # one deck pixel between his boot and tail in the concept's standing view: left as drawn


def sealed(picture):
    """The picture with any speck of deck shut in by the figure (one or two pixels no path reaches from the frame's
    edge) filled with outline, so no frame has a hole in it."""
    pixels = picture.load()
    reached, waiting = set(), [(x, y) for x in range(FRAME) for y in (0, FRAME - 1)] + [(x, y) for y in range(FRAME) for x in (0, FRAME - 1)]
    while waiting:
        x, y = waiting.pop()
        if (x, y) in reached or not (0 <= x < FRAME and 0 <= y < FRAME) or pixels[x, y][3]:
            continue
        reached.add((x, y))
        waiting += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    shut_in = [(x, y) for y in range(FRAME) for x in range(FRAME) if not pixels[x, y][3] and (x, y) not in reached]
    if len(shut_in) <= 3:
        for place in shut_in:
            if place != CONCEPT_GAP:
                picture.putpixel(place, rgba(KEY["#"]))
    return picture


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
    return sealed(picture)


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



OUTLINE = rgba(KEY["#"])


def turned(picture, degrees):
    """A drawn figure turned clockwise by an angle that is not a quarter turn, for a figure in mid-fall. Each pixel is
    made eight times larger, the picture is turned, and each pixel of the result takes the colour most of its
    eight-by-eight block has; then any gap the turn opened in the outline is closed. The result is checked by eye."""
    size = picture.width * 3
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.alpha_composite(picture, (picture.width, picture.height))
    big = canvas.resize((size * 8, size * 8), Image.NEAREST).rotate(-degrees, resample=Image.NEAREST)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    source = big.load()
    for y in range(size):
        for x in range(size):
            counts = {}
            for dy in range(8):
                for dx in range(8):
                    colour = source[x * 8 + dx, y * 8 + dy]
                    counts[colour] = counts.get(colour, 0) + 1
            colour = max(counts, key=counts.get)
            if colour[3]:
                out.putpixel((x, y), colour)
    pixels = out.load()
    gaps = [(x, y) for y in range(1, size - 1) for x in range(1, size - 1) if not pixels[x, y][3]
            and any(pixels[x + dx, y + dy][3] and pixels[x + dx, y + dy] != OUTLINE for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))]
    for place in gaps:
        out.putpixel(place, OUTLINE)
    return out.crop(out.getbbox())
