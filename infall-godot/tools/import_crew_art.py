"""Copies the crew sprite sheets from docs/art into the game's content and checks them against their layouts.

The sheets are made in docs/art (each folder has its own build script). The game reads copies beside each race's
race.xml. Run from infall-godot/ after a sheet changes:   python3 tools/import_crew_art.py
It fails, naming the sheet and the animation, if a layout points at an empty frame or off the edge of a sheet,
or if a race's subtypes (its skin parts, colours and planned subtypes, GV 7F) don't fit its sheet.

A sheet the game recolours for subtypes is copied as its SVG; its PNG render beside it in docs/art is what gets
checked against the layout.
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
    "content/races/terran/crew-facing-tabby.png": "terran/tabby-crew/tabby-crew-sheet.png",
    "content/races/mecha/crew-top-down.png": "mecha/crew-topdown-test/mecha-topdown-sheet.png",
    "content/races/mecha/crew-facing.png": "mecha/crew/mecha-crew-sheet.png",
    "content/races/tentauri/crew-facing.svg": "tentauri/crew/tentauri-crew-sheet.svg",
}
FACINGS = ("down", "right", "up", "left", "any")
failed = False


def picture_of(race, sheet):
    """The picture to check a race's sheet by: the sheet itself, or for an SVG its PNG render in docs/art."""
    if not sheet.endswith(".svg"):
        return os.path.join(GAME, "content", "races", race, sheet)
    return os.path.join(ART, SOURCES["content/races/%s/%s" % (race, sheet)][:-len(".svg")] + ".png")


def subtype_problems(root, race_folder):
    """A race's skin parts must name colour codes its SVG sheets use, give every colour as many tones as the part
    has, and plan only subtypes made of its colours."""
    problems = []
    parts = root.findall("skin_part")
    sheets = [open(os.path.join(race_folder, art.get("sheet"))).read() for art in root.iter("crew_art") if art.get("sheet").endswith(".svg")]
    if parts and not sheets:
        problems.append("subtypes need a sheet kept as an SVG")
    for part in parts:
        tones = [code.strip() for code in part.get("sheet_tones").split(",")]
        for code in tones:
            if any(code not in sheet for sheet in sheets):
                problems.append("%s: a sheet doesn't use %s" % (part.get("id"), code))
        for colour in part.findall("colour"):
            if len(colour.get("tones").split(",")) != len(tones):
                problems.append("%s %s: needs %d tones" % (part.get("id"), colour.get("id"), len(tones)))
    for subtype in root.findall("subtype"):
        wears = subtype.get("wears").split("/")
        if len(wears) != len(parts) or any(part.find("colour[@id='%s']" % colour) is None for part, colour in zip(parts, wears)):
            problems.append("planned subtype %s isn't made of the parts' colours" % subtype.get("wears"))
    return problems


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


def report(label, what, problems):
    global failed
    print("%-32s %-22s %s" % (label, what, "ok" if not problems else "PROBLEMS"))
    for problem in problems:
        failed = True
        print("    " + problem)


if __name__ == "__main__":
    for target, source in SOURCES.items():
        shutil.copyfile(os.path.join(ART, source), os.path.join(GAME, target))
    frame, known = layouts()
    races = os.path.join(GAME, "content", "races")
    for race in sorted(os.listdir(races)):
        root = ET.parse(os.path.join(races, race, "race.xml")).getroot()
        for art in root.iter("crew_art"):
            picture = picture_of(race, art.get("sheet"))
            if art.get("layout") not in known:
                problems = ["no layout called " + art.get("layout")]
            elif not os.path.exists(picture):
                problems = ["the sheet is missing"]
            else:
                problems = check(picture, known[art.get("layout")], frame)
            for particles in art.iter("particles"):
                if art.get("layout") in known and known[art.get("layout")].find("animation[@id='%s']" % particles.get("animation")) is None:
                    problems.append("particles for %s, which the layout doesn't have" % particles.get("animation"))
                for facing in FACINGS:
                    if particles.get(facing) and not all(0 <= float(value) < frame for value in particles.get(facing).split(",")):
                        problems.append("%s particles start outside the frame facing %s" % (particles.get("animation"), facing))
            label = "%s, %s%s" % (race, art.get("style"), ", " + art.get("species") if art.get("species") else "")
            report(label, art.get("sheet"), problems)
        if root.find("token") is not None and not any(art.get("style") == root.find("token").get("style") for art in root.iter("crew_art")):
            report(race + ", token", "", ["the token is cut from a %s sheet the race doesn't have" % root.find("token").get("style")])
        if root.find("skin_part") is not None:
            report(race + ", subtypes", "%d planned" % len(root.findall("subtype")), subtype_problems(root, os.path.join(races, race)))
    sys.exit(1 if failed else 0)
