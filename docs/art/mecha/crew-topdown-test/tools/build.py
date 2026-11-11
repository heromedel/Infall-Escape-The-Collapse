"""Builds the Mecha top-down test: the walk sheet and the pictures in review/. Run from this folder."""
import sys
sys.path.insert(0, "tools")
sys.path.insert(0, "../../terran/crew-test-4/tools")
import mech as m
from pix import Image, FRAME, scaled, strip

FLOOR = (0xC4, 0xCA, 0xD2, 255)


def sheet():
    rows = [m.walk_down() + m.walk_right(), m.walk_up() + m.walk_left()]
    picture = Image.new("RGBA", (8 * FRAME, len(rows) * FRAME), (0, 0, 0, 0))
    for y, frames in enumerate(rows):
        for x, frame in enumerate(frames):
            picture.alpha_composite(frame, (x * FRAME, y * FRAME))
    return picture


def walks(name, times, milliseconds=150):
    sets = [m.walk_down(), m.walk_right(), m.walk_up(), m.walk_left()]
    pictures = [strip([frames[step] for frames in sets], times, 0, FLOOR).convert("RGB") for step in range(4)]
    pictures[0].save(name, save_all=True, append_images=pictures[1:], duration=milliseconds, loop=0)


def beside_the_drifter(name):
    """The four standing views beside the top-down Terran drifter's, at game size, twice and four times."""
    import topdown as t
    stills = [m.walk_down()[0], m.walk_right()[0], m.walk_up()[0], m.walk_left()[0],
              t.walk_down()[0], t.walk_right()[0], t.walk_up()[0], t.walk_left()[0]]
    parts = [strip(stills, times, 0, FLOOR) for times in (1, 2, 4)]
    picture = Image.new("RGBA", (parts[-1].width, sum(part.height for part in parts)), FLOOR)
    y = 0
    for part in parts:
        picture.alpha_composite(part, (0, y))
        y += part.height
    picture.save(name)


if __name__ == "__main__":
    picture = sheet()
    picture.save("mecha-topdown-walk-sheet.png")
    scaled(picture, 4).save("mecha-topdown-walk-sheet-4x.png")
    walks("review/walks-4x.gif", 4)
    walks("review/walks-8x.gif", 8)
    views = [m.walk_down()[0], m.walk_right()[0], m.walk_up()[0], m.walk_left()[0]]
    strip(views, 10, 0, FLOOR).save("review/views-10x.png")
    beside_the_drifter("review/beside-the-drifter.png")
