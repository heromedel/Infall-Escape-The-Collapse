"""Copies the crew sprite sheets from docs/art into the game's content and checks them against their layouts.

The sheets are made in docs/art (each folder has its own build script). The game reads copies beside each race's
race.xml. Run from infall-godot/ after a sheet changes:   python3 tools/import_crew_art.py
It fails, naming the sheet and the animation, if a layout points at an empty frame or off the edge of a sheet.
"""
import os
import shutil
import sys
import xml.etree.ElementTree as ET
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
GAME = os.path.join(HERE, "..")
ART = os.path.join(GAME, "..", "docs", "art")
SOURCES = {        # the game's copy: the sheet it is copied from
    "content/races/terran/crew-top-down.png": "terran/crew-test-4/terran-drifter-topdown-sheet.png",
    "content/races/terran/crew-facing.png": "terran/crew-test-3/terran-drifter-sheet.png",
    "content/races/mecha/crew-top-down.png": "mecha/crew-topdown-test/mecha-topdown-sheet.png",
    "content/races/mecha/crew-facing.png": "mecha/crew/mecha-crew-sheet.png",
    "content/races/tentauri/crew-facing.png": "tentauri/crew/tentauri-crew-sheet.png",
}
FACINGS = ("down", "right", "up", "left", "any")


def tabby_standing(path):
    """The Facing Tabby has no sheet yet, only four standing views: set them in a row, facing down, right, up, left."""
    sys.path.insert(0, os.path.join(ART, "terran", "cat-concept-for-gatos", "tools"))
    import cat
    sheet = Image.new("RGBA", (4 * cat.FRAME, cat.FRAME), (0, 0, 0, 0))
    for number, view in enumerate(("down", "right", "up", "left")):
        sheet.alpha_composite(cat.image(cat.pixels(view), (0, 0, 0, 0)), (number * cat.FRAME, 0))
    sheet.save(path)


def layouts():
    root = ET.parse(os.path.join(GAME, "content", "crew-layouts.xml")).getroot()
    return int(root.get("frame")), {layout.get("id"): layout for layout in root.iter("layout")}


def check(sheet_path, layout, frame):
    """Every frame a layout names must be on the sheet and have something drawn in it."""
    sheet = Image.open(sheet_path).convert("RGBA")
    problems = []
    for animation in layout.iter("animation"):
        for facing in FACINGS:
            if animation.get(facing) is None:
                continue
            row, column, count = (int(value) for value in animation.get(facing).split(","))
            for step in range(count):
                box = ((column - 1 + step) * frame, (row - 1) * frame, (column + step) * frame, row * frame)
                if box[2] > sheet.width or box[3] > sheet.height:
                    problems.append("%s %s: frame %d is off the sheet" % (animation.get("id"), facing, step + 1))
                elif sheet.crop(box).getbbox() is None:
                    problems.append("%s %s: frame %d is empty" % (animation.get("id"), facing, step + 1))
    return problems


if __name__ == "__main__":
    for target, source in SOURCES.items():
        shutil.copyfile(os.path.join(ART, source), os.path.join(GAME, target))
    tabby_standing(os.path.join(GAME, "content/races/terran/crew-facing-tabby.png"))
    frame, known = layouts()
    failed = False
    races = os.path.join(GAME, "content", "races")
    for race in sorted(os.listdir(races)):
        for art in ET.parse(os.path.join(races, race, "race.xml")).getroot().iter("crew_art"):
            sheet_path = os.path.join(races, race, art.get("sheet"))
            if art.get("layout") not in known:
                problems = ["no layout called " + art.get("layout")]
            elif not os.path.exists(sheet_path):
                problems = ["the sheet is missing"]
            else:
                problems = check(sheet_path, known[art.get("layout")], frame)
            label = "%s, %s%s" % (race, art.get("style"), ", " + art.get("species") if art.get("species") else "")
            print("%-32s %-22s %s" % (label, art.get("sheet"), "ok" if not problems else "PROBLEMS"))
            for problem in problems:
                failed = True
                print("    " + problem)
    sys.exit(1 if failed else 0)
