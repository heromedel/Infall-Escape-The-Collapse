"""Builds the Mecha top-down test: the sheet so far and the pictures in review/. Run from this folder."""
import sys
sys.path.insert(0, "tools")
sys.path.insert(0, "../../terran/crew-test-4/tools")
import mech as m
from pix import Image, FRAME, scaled, strip

FLOOR = (0xC4, 0xCA, 0xD2, 255)


def sheet():
    """Eight frames a row and seventeen rows: the genre's layout, with a row of its own for each direction of powering
    a console, which takes eight frames. Rows not drawn yet are left empty, so every frame is where it will stay."""
    empty = []
    rows = [m.walk_down() + m.walk_right(), m.walk_up() + m.walk_left(),
            m.aims_down() + m.aims_right(), m.aims_up() + m.aims_left(),
            empty, empty,                                  # fighting fire
            empty, empty,                                  # punching
            m.power_right(), m.power_left(), m.power_up(), m.power_down(),
            empty, empty,                                  # teleport, death
            m.clone()[:8], m.clone()[8:],                  # the clone bay runs ten frames, over two rows
            [m.portrait(), m.laser_shot(), None] + m.repair()]
    picture = Image.new("RGBA", (8 * FRAME, len(rows) * FRAME), (0, 0, 0, 0))
    for y, frames in enumerate(rows):
        for x, frame in enumerate(frames):
            if frame:
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


def powering(name, times, milliseconds=200):
    # he clamps on once (frames 1 and 2), then the pulse (frames 3 to 8) loops three times
    played = lambda frames: frames[:2] + frames[2:] * 3
    moving(name, [played(m.power_down()), played(m.power_right()), played(m.power_up()), played(m.power_left())],
           times, milliseconds)


if __name__ == "__main__":
    picture = sheet()
    picture.save("mecha-topdown-sheet.png")
    scaled(picture, 4).save("mecha-topdown-sheet-4x.png")
    m.laser_shot().save("mecha-topdown-laser-shot.png")
    walks("review/walks-4x.gif", 4)
    walks("review/walks-8x.gif", 8)
    aims("review/aims-8x.gif", 8)
    powering("review/powering-8x.gif", 8)
    powering("review/powering-slow-8x.gif", 8, 450)
    clone = m.clone()
    moving("review/clone-10x.gif", [clone + clone[-1:] * 5], 10, 150)
    moving("review/clone-slow-10x.gif", [clone + clone[-1:] * 2], 10, 500)
    strip(clone[4:8], 12, 0, FLOOR).save("review/pilot-12x.png")
    moving("review/repair-8x.gif", [m.repair()], 8, 200)
    strip(clone, 8, 0, FLOOR).save("review/clone-8x.png")
    strip(m.power_down(), 8, 0, FLOOR).save("review/powering-down-8x.png")
    strip(m.power_up(), 8, 0, FLOOR).save("review/powering-up-8x.png")
    strip(m.power_right(), 8, 0, FLOOR).save("review/powering-right-8x.png")
    strip(m.aims_down() + m.aims_up(), 8, 0, FLOOR).save("review/aims-down-up-8x.png")
    strip(m.aims_right() + m.aims_left(), 8, 0, FLOOR).save("review/aims-right-left-8x.png")
    views = [m.walk_down()[0], m.walk_right()[0], m.walk_up()[0], m.walk_left()[0]]
    strip(views, 10, 0, FLOOR).save("review/views-10x.png")
    beside_the_drifter("review/beside-the-drifter.png")
