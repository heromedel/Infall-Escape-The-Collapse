"""Builds the Mecha top-down test: the sheet so far and the pictures in review/. Run from this folder."""
import sys
sys.path.insert(0, "tools")
sys.path.insert(0, "../../terran/crew-test-4/tools")
import mech as m
from pix import Image, FRAME, scaled, strip

FLOOR = (0xC4, 0xCA, 0xD2, 255)


def sheet():
    """The genre's layout, eight frames a row: walks on rows 1 and 2, aims on rows 3 and 4. The rest are to come."""
    rows = [m.walk_down() + m.walk_right(), m.walk_up() + m.walk_left(),
            m.aims_down() + m.aims_right(), m.aims_up() + m.aims_left()]
    picture = Image.new("RGBA", (8 * FRAME, len(rows) * FRAME), (0, 0, 0, 0))
    for y, frames in enumerate(rows):
        for x, frame in enumerate(frames):
            picture.alpha_composite(frame, (x * FRAME, y * FRAME))
    return picture


def moving(name, sets, times, milliseconds=150):
    """A looping picture of several animations side by side, each a list of frames repeated to the same length."""
    steps = max(len(frames) for frames in sets)
    pictures = [strip([frames[step % len(frames)] for frames in sets], times, 0, FLOOR).convert("RGB")
                for step in range(steps)]
    pictures[0].save(name, save_all=True, append_images=pictures[1:], duration=milliseconds, loop=0)


def walks(name, times):
    moving(name, [m.walk_down(), m.walk_right(), m.walk_up(), m.walk_left()], times)


def aims(name, times):
    # each aim held a while: straight, to his right, straight, to his left
    held = lambda frames: [frames[i] for i in (0, 0, 1, 1, 0, 0, 2, 2)]
    moving(name, [held(m.aims_down()), held(m.aims_right()), held(m.aims_up()), held(m.aims_left())], times, 300)


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
    picture.save("mecha-topdown-sheet.png")
    scaled(picture, 4).save("mecha-topdown-sheet-4x.png")
    m.laser_shot().save("mecha-topdown-laser-shot.png")
    walks("review/walks-4x.gif", 4)
    walks("review/walks-8x.gif", 8)
    aims("review/aims-8x.gif", 8)
    strip(m.aims_down() + m.aims_up(), 8, 0, FLOOR).save("review/aims-down-up-8x.png")
    strip(m.aims_right() + m.aims_left(), 8, 0, FLOOR).save("review/aims-right-left-8x.png")
    views = [m.walk_down()[0], m.walk_right()[0], m.walk_up()[0], m.walk_left()[0]]
    strip(views, 10, 0, FLOOR).save("review/views-10x.png")
    beside_the_drifter("review/beside-the-drifter.png")
