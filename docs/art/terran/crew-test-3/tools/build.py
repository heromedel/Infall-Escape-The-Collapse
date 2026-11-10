"""Builds the drifter's sheet and the review pictures. Run from this piece's folder: python3 tools/build.py"""
import sys
sys.path.insert(0, "tools")
from pix import *
import drifter

FLOOR = (0xc4, 0xca, 0xd2, 255)
LINE = (0xae, 0xb5, 0xbe, 255)


def sheet():
    """The rows of the Mecha and Tentauri sheets, in their order."""
    def left(frames):
        return [mirror(f) for f in frames]

    walk, shoot, fire, typing = drifter.walk_right(), drifter.shoot_right(), drifter.fire_right(), drifter.type_right()
    rows = [
        drifter.walk_down() + walk,
        drifter.walk_up() + left(walk),
        drifter.shoot_down() + shoot,
        drifter.shoot_up() + left(shoot),
        drifter.fire_down() + fire,
        drifter.fire_up() + left(fire),
        drifter.punch_up(),
        drifter.punch_down(),
        typing + left(typing),
        drifter.type_up() + drifter.type_down(),
        drifter.teleport(),
        drifter.death(),
        drifter.clone(),
        [drifter.portrait(), drifter.laser_shot(), None] + drifter.repair(),
    ]
    out = Image.new("RGBA", (8 * FRAME, len(rows) * FRAME), (0, 0, 0, 0))
    for y, frames in enumerate(rows):
        for x, f in enumerate(frames):
            if f is not None:
                out.alpha_composite(f, (x * FRAME, y * FRAME))
    return out


def actions(name, times=4, milliseconds=140):
    """Every other animation looping in one picture: shooting, fire, fists, repair, teleport, death, the clone bay."""
    def left(frames):
        return [mirror(f) for f in frames]

    sets = [drifter.shoot_down(), drifter.shoot_right(), drifter.shoot_up(), left(drifter.shoot_right()),
            drifter.punch_down(), drifter.punch_up(), drifter.repair(),
            drifter.fire_down(), drifter.fire_right(), drifter.fire_up(), left(drifter.fire_right()),
            drifter.teleport(), drifter.death(), drifter.clone()]
    pictures = []
    for index in range(24):
        picture = floor(7 * FRAME * times, 2 * FRAME * times, times)
        for number, frames in enumerate(sets):
            f = frames[index % len(frames)]
            picture.alpha_composite(scaled(f, times), ((number % 7) * FRAME * times, (number // 7) * FRAME * times))
        pictures.append(picture.convert("RGB"))
    pictures[0].save(name, save_all=True, append_images=pictures[1:], duration=milliseconds, loop=0)


def cells(image, row, first):
    return [image.crop(((first + i) * FRAME, row * FRAME, (first + i + 1) * FRAME, (row + 1) * FRAME)) for i in range(4)]


def floor(width, height, times):
    """A plain deck: light tiles, 35 pixels a tile like the sprites' frames."""
    image = Image.new("RGBA", (width, height), FLOOR)
    for x in range(0, width, FRAME * times):
        for y in range(height):
            image.putpixel((x, y), LINE)
    for y in range(0, height, FRAME * times):
        for x in range(width):
            image.putpixel((x, y), LINE)
    return image


def animation(name, sets, times, milliseconds=130):
    """sets: one list per race of four directions, each four frames. A grid: a column a race, a row a direction."""
    width, height = len(sets) * FRAME * times, 4 * FRAME * times
    pictures = []
    for index in range(4):
        picture = floor(width, height, times)
        for column, directions in enumerate(sets):
            for row, frames in enumerate(directions):
                picture.alpha_composite(scaled(frames[index], times), (column * FRAME * times, row * FRAME * times))
        pictures.append(picture.convert("RGB"))
    pictures[0].save(name, save_all=True, append_images=pictures[1:], duration=milliseconds, loop=0)


if __name__ == "__main__":
    ours = sheet()
    ours.save("terran-drifter-sheet.png")
    scaled(ours, 4).save("terran-drifter-sheet-4x.png")
    mecha = Image.open("../../mecha/crew/mecha-crew-sheet.png").convert("RGBA")
    tent = Image.open("../../tentauri/crew/tentauri-crew-sheet.png").convert("RGBA")

    def walks(image):
        return [cells(image, 0, 0), cells(image, 0, 4), cells(image, 1, 0), cells(image, 1, 4)]

    def types(image, row):
        return [cells(image, row + 1, 4), cells(image, row, 0), cells(image, row + 1, 0), cells(image, row, 4)]

    for times in (1, 2, 4):
        animation("review/walk-%dx.gif" % times, [walks(mecha), walks(ours), walks(tent)], times)
        animation("review/console-%dx.gif" % times, [types(mecha, 8), types(ours, 8), types(tent, 8)], times, 160)
    actions("review/actions-4x.gif")
    actions("review/actions-2x.gif", 2)
    # one still picture: every race standing, at game size, twice and four times
    stills = [cells(mecha, 0, 0)[1], cells(ours, 0, 0)[1], cells(ours, 0, 4)[1], cells(ours, 1, 0)[1], cells(ours, 1, 4)[1],
              cells(tent, 0, 0)[1]]
    parts = [strip(stills, times) for times in (1, 2, 4)]
    width = max(p.width for p in parts)
    out = floor(width, sum(p.height for p in parts), 1)
    y = 0
    for p in parts:
        out.alpha_composite(p, (0, y))
        y += p.height
    out.save("review/game-size.png")
