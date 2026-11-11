"""Colour variants of the Tentauri crew sheet, so crew can be told apart.

The sheet beside this folder is heromedel's and is the reference: a teal bell, a pink rim, lavender tentacles.
Each variant swaps the bell's colours for another set, tone for tone, and keeps everything else: the outline, the
eyes, the pink rim (the Tentauri's power colour), the crew laser shot and, in all but one, the lavender tentacles.

Run from docs/art/tentauri/crew:   python3 tools/variants.py
It writes variants/tentauri-crew-sheet-<name>.png and review/variants.png.
"""
import os
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CREW = os.path.join(HERE, "..")
SHEET = os.path.join(CREW, "tentauri-crew-sheet.png")
FRAME = 35

# The reference sheet's colours, lightest first.
BELL = ("#e2fffa", "#92e4e0", "#50bac4", "#2e7a96")
TENTACLES = ("#c8aaff", "#886ad6", "#765ac4", "#543c94")

# name: (bell, tentacles); None keeps the reference's colours.
VARIANTS = {
    "gold":   (("#fff8d6", "#ffe08a", "#f0b340", "#b06c34"), None),
    "pearl":  (("#ffffff", "#f3eef8", "#cfc6e2", "#8f86b6"), None),
    "blue":   (("#e0eeff", "#9cc0ff", "#5584e6", "#3350a8"), None),
    "coral":  (("#ffeede", "#ffbc9c", "#f0845c", "#aa4a4c"), None),
    # The reference turned around: a violet bell would be lost against lavender tentacles, so they take the teal.
    "violet": (("#f2e4ff", "#d2a6ff", "#a26ae6", "#6238a8"), ("#92e4e0", "#50bac4", "#3c9aae", "#2e7a96")),
}


def rgb(colour):
    return tuple(int(colour[at:at + 2], 16) for at in (1, 3, 5))


def recoloured(sheet, bell, tentacles):
    swap = {rgb(old): rgb(new) for old, new in zip(BELL, bell)}
    if tentacles:
        swap.update({rgb(old): rgb(new) for old, new in zip(TENTACLES, tentacles)})
    out = sheet.copy()
    pixels = out.load()
    for y in range(out.height):
        for x in range(out.width):
            red, green, blue, alpha = pixels[x, y]
            if (red, green, blue) in swap:
                pixels[x, y] = swap[(red, green, blue)] + (alpha,)
    return out


def review(sheets):
    """Each colour standing on a deck tile at 4x, and at the game's size."""
    floor = (0xb9, 0xbd, 0xc4, 255)
    picture = Image.new("RGBA", (len(sheets) * 150 + 10, 205), (0x30, 0x36, 0x40, 255))
    draw = ImageDraw.Draw(picture)
    for number, (name, sheet) in enumerate(sheets.items()):
        tile = Image.new("RGBA", (FRAME, FRAME), floor)
        tile.alpha_composite(sheet.crop((0, 0, FRAME, FRAME)))
        left = 10 + number * 150
        picture.alpha_composite(tile.resize((FRAME * 4, FRAME * 4), Image.NEAREST), (left, 10))
        picture.alpha_composite(tile, (left, 160))
        draw.text((left + 45, 172), name, fill=(0xe6, 0xea, 0xf0, 255))
    picture.save(os.path.join(CREW, "review", "variants.png"))


if __name__ == "__main__":
    reference = Image.open(SHEET).convert("RGBA")
    sheets = {"teal (the reference)": reference}
    for name, (bell, tentacles) in VARIANTS.items():
        sheets[name] = recoloured(reference, bell, tentacles)
        sheets[name].save(os.path.join(CREW, "variants", "tentauri-crew-sheet-%s.png" % name))
    review(sheets)
    print("wrote %d variants" % len(VARIANTS))
