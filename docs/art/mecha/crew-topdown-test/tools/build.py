"""Builds the Mecha top-down test: the sheet so far and the pictures in review/. Run from this folder."""
import sys
sys.path.insert(0, "tools")
sys.path.insert(0, "../../terran/crew-test-4/tools")
import mech as m
import pilot
from pix import Image, FRAME, scaled, strip

FLOOR = (0xC4, 0xCA, 0xD2, 255)


def sheet():
    """Eight frames a row and sixteen rows: the genre's layout, with a row of its own for each direction of powering
    a console, which takes eight frames."""
    rows = [m.walk_down() + m.walk_right(), m.walk_up() + m.walk_left(),
            m.aims_down() + m.aims_right(), m.aims_up() + m.aims_left(),
            m.fire_down() + m.fire_right(), m.fire_up() + m.fire_left(),
            m.punch_up(), m.punch_down(),
            m.power_right(), m.power_left(), m.power_up(), m.power_down(),
            m.teleport(), m.death(),
            m.clone(),                                     # the suit's own clone frames; its pilot is pilot.py
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


def pilot_sheet():
    """The pilot's own sheet: her run on rows 1 and 2 in the suit's layout, her jump on row 3."""
    rows = [pilot.run_down() + pilot.run_right(), pilot.run_up() + pilot.run_left(), [pilot.jump()]]
    picture = Image.new("RGBA", (8 * FRAME, len(rows) * FRAME), (0, 0, 0, 0))
    for y, frames in enumerate(rows):
        for x, frame in enumerate(frames):
            picture.alpha_composite(frame, (x * FRAME, y * FRAME))
    return picture


def clone_bay(name, times, milliseconds=150):
    """How the game would play it: the suit is built and waits; the pilot runs to it from the side the clone bay is
    on, vaults up, hangs above its back and drops in behind it; the lights come up. A stretch of floor 80 by 40."""
    suit, run, jump = m.clone(), pilot.run_right(), pilot.jump()
    suit_at = (43, 5)
    script = [(0, None), (1, None), (2, None), (3, None)]                    # (suit frame, pilot)
    for step in range(7):                                                    # she runs in along the floor
        script.append((m.CLONE_WAITING, (run[step % 4], (-10 + 4 * step, 10), True)))
    script += [(m.CLONE_WAITING, (jump, (24, 4), True)),                     # vaulting, in front of the suit
               (m.CLONE_WAITING, (jump, (36, -3), True)),
               (m.CLONE_WAITING, (jump, (43, -6), False)),                   # above its back: drawn behind it
               (m.CLONE_WAITING, (jump, (43, -2), False)),                   # dropping in
               (m.CLONE_WAITING, (jump, (43, 2), False)),
               (m.CLONE_WAITING, None), (5, None)] + [(6, None)] * 5
    pictures = []
    for suit_frame, her in script:
        picture = Image.new("RGBA", (80, 40), FLOOR)
        if her and not her[2]:
            picture.alpha_composite(her[0], her[1]) if min(her[1]) >= 0 else paste_clipped(picture, her[0], her[1])
        picture.alpha_composite(suit[suit_frame], suit_at)
        if her and her[2]:
            paste_clipped(picture, her[0], her[1])
        pictures.append(scaled(picture, times).convert("RGB"))
    pictures[0].save(name, save_all=True, append_images=pictures[1:], duration=milliseconds, loop=0)


def paste_clipped(picture, image, at):
    """Set an image on a picture where part of it may fall off the edge."""
    layer = Image.new("RGBA", picture.size, (0, 0, 0, 0))
    layer.paste(image, at)
    picture.alpha_composite(layer)


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
    strip(clone, 8, 0, FLOOR).save("review/clone-suit-8x.png")
    clone_bay("review/clone-bay-8x.gif", 8)
    clone_bay("review/clone-bay-slow-8x.gif", 8, 400)
    her = pilot_sheet()
    her.save("halfmech-pilot-topdown-sheet.png")
    scaled(her, 4).save("halfmech-pilot-topdown-sheet-4x.png")
    moving("review/pilot-run-10x.gif", [pilot.run_down(), pilot.run_right(), pilot.run_up(), pilot.run_left()], 10)
    crop = lambda frames: [f.crop((8, 8, 28, 28)) for f in frames]
    strip(crop(pilot.run_down() + pilot.run_up()), 10, 0, FLOOR).save("review/pilot-run-down-up-10x.png")
    strip(crop(pilot.run_right() + pilot.run_left() + [pilot.jump()]), 10, 0, FLOOR).save(
        "review/pilot-run-right-left-jump-10x.png")
    moving("review/repair-8x.gif", [m.repair()], 8, 200)
    moving("review/fire-8x.gif", [m.fire_down(), m.fire_right(), m.fire_up(), m.fire_left()], 8, 250)
    moving("review/punch-8x.gif", [m.punch_down(), m.punch_up()], 8, 150)
    moving("review/teleport-8x.gif", [m.teleport() + [Image.new("RGBA", (FRAME, FRAME))] * 3], 8, 120)
    moving("review/death-8x.gif", [m.death() + m.death()[-1:] * 5], 8, 150)
    strip(m.fire_down() + m.fire_up(), 8, 0, FLOOR).save("review/fire-down-up-8x.png")
    strip(m.fire_right() + m.fire_left(), 8, 0, FLOOR).save("review/fire-right-left-8x.png")
    strip(m.punch_down(), 8, 0, FLOOR).save("review/punch-down-8x.png")
    strip(m.punch_up(), 8, 0, FLOOR).save("review/punch-up-8x.png")
    strip(m.teleport(), 8, 0, FLOOR).save("review/teleport-8x.png")
    strip(m.death(), 8, 0, FLOOR).save("review/death-8x.png")
    strip(m.power_down(), 8, 0, FLOOR).save("review/powering-down-8x.png")
    strip(m.power_up(), 8, 0, FLOOR).save("review/powering-up-8x.png")
    strip(m.power_right(), 8, 0, FLOOR).save("review/powering-right-8x.png")
    strip(m.aims_down() + m.aims_up(), 8, 0, FLOOR).save("review/aims-down-up-8x.png")
    strip(m.aims_right() + m.aims_left(), 8, 0, FLOOR).save("review/aims-right-left-8x.png")
    views = [m.walk_down()[0], m.walk_right()[0], m.walk_up()[0], m.walk_left()[0]]
    strip(views, 10, 0, FLOOR).save("review/views-10x.png")
    beside_the_drifter("review/beside-the-drifter.png")
