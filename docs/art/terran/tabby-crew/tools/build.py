"""Builds the Tabby crew sheet and its review pictures.   Run from docs/art/terran/tabby-crew:  python3 tools/build.py

The sheet is 8 frames wide and 14 rows tall, 35 x 35 a frame, in the order of the other Facing sheets (the
"eight-wide" layout in infall-godot/content/crew-layouts.xml).
"""
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pix
import tabby

HERE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
DECK = (0xc9, 0xcf, 0xd8, 255)


def rows():
    return [
        tabby.walk_down() + tabby.walk_right(),
        tabby.walk_up() + tabby.walk_left(),
        tabby.aim_down() + tabby.aim_right(),
        tabby.aim_up() + tabby.aim_left(),
        tabby.fire_down() + tabby.fire_right(),
        tabby.fire_up() + tabby.fire_left(),
        tabby.punch_up(),
        tabby.punch_down(),
        tabby.type_right() + tabby.type_left(),
        tabby.type_up() + tabby.type_down(),
        tabby.teleport(),
        tabby.death(),
        tabby.clone(),
        [tabby.portrait(), tabby.laser_shot(), None] + tabby.repair(),
    ]


def sheet():
    picture = Image.new("RGBA", (8 * pix.FRAME, 14 * pix.FRAME), (0, 0, 0, 0))
    for row, frames in enumerate(rows()):
        for column, frame in enumerate(frames):
            if frame is not None:
                picture.alpha_composite(frame, (column * pix.FRAME, row * pix.FRAME))
    return picture


def loop(name, sets, scale, milliseconds):
    """Several animations side by side in one looping GIF, each on a strip of deck."""
    longest = max(len(frames) for frames in sets)
    tiles = []
    for step in range(longest):
        tile = Image.new("RGBA", (len(sets) * pix.FRAME, pix.FRAME), DECK)
        for number, frames in enumerate(sets):
            tile.alpha_composite(frames[step % len(frames)], (number * pix.FRAME, 0))
        tiles.append(tile.resize((tile.width * scale, tile.height * scale), Image.NEAREST).convert("P", palette=Image.ADAPTIVE))
    tiles[0].save(os.path.join(HERE, "review", name), save_all=True, append_images=tiles[1:], duration=milliseconds, loop=0)


if __name__ == "__main__":
    os.makedirs(os.path.join(HERE, "review"), exist_ok=True)
    picture = sheet()
    picture.save(os.path.join(HERE, "tabby-crew-sheet.png"))
    on_deck = Image.new("RGBA", picture.size, DECK)
    on_deck.alpha_composite(picture)
    on_deck.resize((picture.width * 4, picture.height * 4), Image.NEAREST).save(os.path.join(HERE, "tabby-crew-sheet-4x.png"))
    loop("walk-4x.gif", [tabby.walk_down(), tabby.walk_right(), tabby.walk_up(), tabby.walk_left()], 4, 150)
    loop("walk-1x.gif", [tabby.walk_down(), tabby.walk_right(), tabby.walk_up(), tabby.walk_left()], 1, 150)
    hold = lambda frames, times: [frame for frame in frames for count in range(times)]
    loop("work-4x.gif", [tabby.type_down(), tabby.type_right(), tabby.type_up(), tabby.repair(),
                         tabby.fire_down(), tabby.fire_right(), tabby.fire_up()], 4, 170)
    loop("fight-4x.gif", [hold(tabby.aim_down(), 4), hold(tabby.aim_right(), 4), hold(tabby.aim_up(), 4),
                          tabby.punch_down() + tabby.punch_down(), tabby.punch_up() + tabby.punch_up()], 4, 130)
    death = tabby.death()
    loop("death-4x.gif", [death + [death[-1]] * 6], 4, 130)
    loop("teleport-clone-4x.gif", [tabby.teleport() + [Image.new("RGBA", (35, 35))] * 3, tabby.clone() + [tabby.standing()] * 5], 4, 110)
    print("built the sheet: %d x %d" % picture.size)
