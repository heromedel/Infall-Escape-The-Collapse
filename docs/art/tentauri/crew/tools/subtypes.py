"""A picture of the Tentauri's planned subtypes: the crew sheet in each planned pair of bell and tentacle colours.

The sheet beside this folder is heromedel's and is the reference: a teal bell, a pink rim, lavender tentacles.
The colours and the planned pairs live in the game's content (infall-godot/content/races/tentauri/race.xml), which
recolours the sheet itself; this only draws them for review.

Run from docs/art/tentauri/crew:   python3 tools/subtypes.py
It writes review/subtypes.png.
"""
import os
import xml.etree.ElementTree as ET
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CREW = os.path.join(HERE, "..")
RACE = os.path.join(CREW, "..", "..", "..", "..", "infall-godot", "content", "races", "tentauri", "race.xml")
FRAME = 35


def rgb(code):
    code = code.strip()
    return tuple(int(code[at:at + 2], 16) for at in (1, 3, 5))


def standing(sheet, parts, subtype):
    """The sheet's first frame with each part's tones swapped for the subtype's colour."""
    swap = {}
    for part, colour in zip(parts, subtype.split("/")):
        tones = part.find("colour[@id='%s']" % colour).get("tones")
        swap.update(zip(map(rgb, part.get("sheet_tones").split(",")), map(rgb, tones.split(","))))
    frame = sheet.crop((0, 0, FRAME, FRAME))
    pixels = frame.load()
    for y in range(FRAME):
        for x in range(FRAME):
            red, green, blue, alpha = pixels[x, y]
            pixels[x, y] = swap.get((red, green, blue), (red, green, blue)) + (alpha,)
    return frame


if __name__ == "__main__":
    race = ET.parse(RACE).getroot()
    parts = race.findall("skin_part")
    planned = [subtype.get("wears") for subtype in race.findall("subtype")]
    sheet = Image.open(os.path.join(CREW, "tentauri-crew-sheet.png")).convert("RGBA")
    picture = Image.new("RGBA", (len(planned) * 150 + 10, 205), (0x30, 0x36, 0x40, 255))
    draw = ImageDraw.Draw(picture)
    for number, subtype in enumerate(planned):
        tile = Image.new("RGBA", (FRAME, FRAME), (0xb9, 0xbd, 0xc4, 255))     # a deck tile
        tile.alpha_composite(standing(sheet, parts, subtype))
        left = 10 + number * 150
        picture.alpha_composite(tile.resize((FRAME * 4, FRAME * 4), Image.NEAREST), (left, 10))
        picture.alpha_composite(tile, (left, 160))
        draw.text((left + 45, 172), subtype, fill=(0xe6, 0xea, 0xf0, 255))
    os.makedirs(os.path.join(CREW, "review"), exist_ok=True)
    picture.save(os.path.join(CREW, "review", "subtypes.png"))
    print("drew %d planned subtypes" % len(planned))
