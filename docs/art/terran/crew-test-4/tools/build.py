"""Builds the top-down drifter's sheet and review pictures. Run from this folder: python3 tools/build.py"""
import sys
sys.path.insert(0, "tools")
from pix import *
import topdown as t

FLOOR = (0xc4, 0xca, 0xd2, 255)


def rows():
    """The genre's human layout, row for row: 13 rows of up to 9 frames."""
    return [
        t.walk_down() + t.walk_right(),
        t.walk_up() + t.walk_left(),
        t.aim_down() + t.aim_right() + t.aim_up(),
        t.fire_down() + t.fire_right(),
        t.fire_up() + t.fire_left(),
        t.repair(),
        t.punch_down(),
        t.type_right() + t.type_left(),
        t.type_up() + t.type_down(),
        t.teleport_light(),
        t.clone(),
        t.aim_left() + t.punch_up(),
        [t.portrait(), t.laser_shot(), None] + t.death(),
    ]


def sheet():
    out = Image.new("RGBA", (9 * FRAME, 13 * FRAME), (0, 0, 0, 0))
    for y, frames in enumerate(rows()):
        for x, f in enumerate(frames):
            if f is not None:
                out.alpha_composite(f, (x * FRAME, y * FRAME))
    return out


def animations(name, times=4, milliseconds=150):
    walk_left = t.walk_left()
    death = t.death()
    sets = [t.walk_down(), t.walk_right(), t.walk_up(), walk_left, t.punch_down(), t.punch_up(),
            t.aim_down(), t.aim_right(), t.aim_up(), t.aim_left(), t.repair(), t.teleport_light(),
            t.fire_down(), t.fire_right(), t.fire_up(), t.fire_left(), t.clone(), death + death[-1:] * 4,
            t.type_down(), t.type_right(), t.type_up(), t.type_left()]
    pictures = []
    for index in range(36):
        picture = Image.new("RGBA", (6 * FRAME * times, 4 * FRAME * times), FLOOR)
        for number, frames in enumerate(sets):
            f = frames[index % len(frames)]
            picture.alpha_composite(scaled(f, times), ((number % 6) * FRAME * times, (number // 6) * FRAME * times))
        pictures.append(picture.convert("RGB"))
    pictures[0].save(name, save_all=True, append_images=pictures[1:], duration=milliseconds, loop=0)


if __name__ == "__main__":
    ours = sheet()
    ours.save("terran-drifter-topdown-sheet.png")
    scaled(ours, 4).save("terran-drifter-topdown-sheet-4x.png")
    pulled = strip(t.teleport())                      # the genre's kind of teleport, kept beside the sheet
    pulled.save("terran-drifter-topdown-teleport-pulled.png")
    scaled(pulled, 4).save("terran-drifter-topdown-teleport-pulled-4x.png")
    animations("review/animations-4x.gif")
    animations("review/animations-2x.gif", 2)
    # beside the face-forward drifter of crew test 3, at game size, twice and four times
    front = Image.open("../crew-test-3/terran-drifter-sheet.png").convert("RGBA")
    stills = [front.crop((0, 0, 35, 35)), t.walk_down()[0], t.walk_right()[0], t.walk_up()[0], t.walk_left()[0]]
    parts = [strip(stills, times, 0, FLOOR) for times in (1, 2, 4)]
    out = Image.new("RGBA", (max(p.width for p in parts), sum(p.height for p in parts)), FLOOR)
    y = 0
    for p in parts:
        out.alpha_composite(p, (0, y))
        y += p.height
    out.save("review/game-size.png")
