"""Pixel frames written as text, one character a pixel, and the pictures made from them."""
from PIL import Image

FRAME = 35

PALETTE = {
    ".": None,
    "o": "#15111a",  # outline
    # hair
    "h": "#241d2b", "i": "#463a52", "j": "#6a5a78",
    # skin
    "s": "#d39a6a", "t": "#b0744a", "u": "#7c4c36", "v": "#3a2220",
    # coat
    "c": "#55341f", "d": "#341f17", "e": "#7a4c2a", "f": "#a06a3a",
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
    "k": "#1b171d", "y": "#e0b850",
    # trousers
    "p": "#343c4e", "P": "#4a556c", "m": "#222836",
    # boots
    "z": "#231d24", "Z": "#4a3f48",
    # console glow on the hands
    "g": "#66ff66",
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
