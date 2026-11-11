# Mecha crew, top-down test

**Date:** 2026-11-11
**Status:** a test, third version, shown to heromedel and not yet judged. It answers one question: can the nearly
top-down view that worked for the Terran drifter (`docs/art/terran/crew-test-4`) be drawn for a race that has no
human sheet to follow?

![The four views beside the drifter](review/beside-the-drifter.png)

A HalfMech in its suit, standing and walking in the four directions, at the drifter's frame size (35 by 35).

- `mecha-topdown-walk-sheet.png` (and `-4x`): row 1 walk down then walk right, row 2 walk up then walk left, four
  frames each.
- `review/walks-8x.gif` and `-4x.gif`: the four walks moving. `review/views-10x.png`: the four standing views.
  `review/beside-the-drifter.png`: both figures at game size, twice and four times.
  `review/beside-heromedels-drawing.png`: the front view beside the drawing it follows.
- `reference/heromedel-mecha-topdown.png` (and `-8x`): heromedel's own drawing of the suit from above, standing and
  facing the camera, 86 by 48 pixels, about four times game size. It was offered as one more inspiration, not as
  law.

## The design

After heromedel's drawing, brought down to game size by hand (nothing is scaled or traced), in the colours of the
Mecha crew palette (`docs/art/palette.md`):

- A boxy helm with a pale ridge down the middle and a short purple visor bar on its front edge.
- A shoulder plate each side, with a thick spike sweeping up and out of its outer corner. They are shoulders:
  HalfMech suits do not have wings (heromedel, 2026-11-11).
- An arm straight down from under each plate to a grey powered clamp claw with a purple band. heromedel likes the
  clamp claws, and asked for them straight, not bent, and for the thicker spikes of the first version (2026-11-11).
- Two chest lights under the visor, on a torso four rows deep, and two pointed feet. The torso was two rows;
  heromedel had it extended down two pixels with the lights left where they were (2026-11-11). The back view has
  the same torso.
- The feet are two pixels long and stand apart from the torso and from each other, each with its own outline
  (heromedel, 2026-11-11). A stepping foot reaches a pixel further and the other draws in a pixel.
- **Spikes and arms at different angles (heromedel, 2026-11-11):** the spike leans out from the plate's outer
  corner and the claw hangs straight from under its middle. The first version of this test hung each claw straight
  under a blade that stood straight above it, and on a still frame the two read as one stacked piece.

How the other views follow from it:

- From behind there is no visor and no chest light: the ridge runs the whole helm and down the back plate. The claws
  keep their bands.
- Facing right is the front view turned a quarter: one shoulder plate above the helm and one below, the spikes
  sweeping back and out, the claws pointing straight ahead, the visor on the helm's front edge.
- Standing side on, both feet show ahead of the helm, so he is not so thin (heromedel, 2026-11-11).
- The walk moves only the claws and the feet, as the drifter's moves only fists and feet.

## What I think of it

- The front and back views read as heromedel's suit at game size.
- The side view is still the weakest. It is correct as a turn of the front view, but with the shoulder plates as long as
  they are it reads as a bracket more than as a figure.

## Tools

`python3 tools/build.py`, run from this folder, rebuilds the sheet and the pictures. `tools/mech.py` holds the frames
as text, one character a pixel. The build borrows the picture helpers of `docs/art/terran/crew-test-4/tools/pix.py`.
