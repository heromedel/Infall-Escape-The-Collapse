"""Pixel frames written as text, one character a pixel, and the pictures made from them."""
from PIL import Image

FRAME = 35

PALETTE = {
    ".": None,
    "o": "#15111a",  # outline
    # hair
    "h": "#2a2233", "i": "#4d4160", "j": "#7a6a90",
    # skin
    "s": "#d39a6a", "t": "#b0744a", "u": "#7c4c36", "v": "#3a2220",
    # coat
    "c": "#6f4424", "d": "#4f3020", "e": "#96602f", "f": "#b47a44",
    # bandana
    "b": "#2f72d6", "B": "#69a8f5", "n": "#1d478f",
    # shirt
    "r": "#a89c88", "R": "#cfc4ae", "q": "#7a705f",
    # collar fleece
    "w": "#e2d6bc", "W": "#b3a58a",
    # shirt, second and third choices
    "a": "#6d7148", "A": "#8a8f5c", "x": "#4b4e33",
    "1": "#7d3838", "2": "#a04a48", "3": "#552626",
    # belt and buckle
    "k": "#2a2530", "y": "#e0b850",
    # trousers
    "p": "#4a5670", "P": "#64729a", "m": "#2f3748",
    # boots
    "z": "#3a3038", "Z": "#5c5060",
    # console glow on the hands
    "g": "#66ff66",
    # fire extinguisher, its spray, a tool or a pistol's metal, a muzzle flash
    "4": "#d8382c", "5": "#8e1e1b", "6": "#f2f5f8", "G": "#7b8592", "D": "#4b525c", "F": "#fff0a0",
    # teleport light
    "L": "#d4ecff", "M": "#7fb4f0",
    # the clone bay's plate
    "X": "#dfe6ee", "Y": "#f6f9fc", "V": "#a9b6c6",
}


def rgba(code):
    hexa = PALETTE[code]
    if hexa is None:
        return (0, 0, 0, 0)
    return tuple(int(hexa[i:i + 2], 16) for i in (1, 3, 5)) + (255,)


def frame(rows, left=10, top=7):
    """A 35 by 35 frame from rows of text placed with their corner at (left, top)."""
    image = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
    for y, row in enumerate(rows):
        for x, code in enumerate(row):
            if code != "." and code != " ":
                image.putpixel((left + x, top + y), rgba(code))
    return image


def mirror(image):
    return image.transpose(Image.FLIP_LEFT_RIGHT)


def scaled(image, times):
    return image.resize((image.width * times, image.height * times), Image.NEAREST)


def strip(frames, times=1, gap=0, background=(0, 0, 0, 0)):
    width = sum(f.width for f in frames) * times + gap * (len(frames) - 1)
    out = Image.new("RGBA", (width, frames[0].height * times), background)
    x = 0
    for f in frames:
        out.alpha_composite(scaled(f, times), (x, 0))
        x += f.width * times + gap
    return out
