# Mecha crew, top-down test

**Date:** 2026-11-11
**Status:** a test, shown to heromedel, not yet judged. It answers one question: can the nearly top-down view that
worked for the Terran drifter (`docs/art/terran/crew-test-4`) be drawn for a race that has no human sheet to follow?

![The four views beside the drifter](review/beside-the-drifter.png)

A HalfMech in its suit, standing and walking in the four directions, at the drifter's size (35 by 35 frames).

- `mecha-topdown-walk-sheet.png` (and `-4x`): row 1 walk down then walk right, row 2 walk up then walk left, four
  frames each.
- `review/walks-8x.gif` and `-4x.gif`: the four walks moving. `review/views-10x.png`: the four standing views.
  `review/beside-the-drifter.png`: both figures at game size, twice and four times.

## How it was drawn

Nothing was traced and no other sheet was followed frame for frame. The design is the Mecha crew sheet's
(`docs/art/mecha/crew`, style guide "HalfMechs in their suits"): crest head, blade forearms, short legs, near-black
armour with one accent, the purple visor bar and chest lights. The build is the drifter's, part for part:

| The drifter | The HalfMech |
|---|---|
| Head, hair | A helm shaped like a kite, its crest a light ridge down the middle, the visor bar on its front edge |
| Two coat shoulders | Two pauldrons, a blade rising up and out of each |
| A fist under each cuff | A claw under each pauldron |
| Two-line torso | Two-line chest with the three lights |
| Feet a line | Feet a line |

- The colours are the Mecha crew palette (`docs/art/palette.md`), nothing else.
- The walk moves only the claws and the feet, as the drifter's moves only fists and feet.
- From behind there is no visor and no chest light: the ridge runs the whole helm and down the back plate.
- Facing right, one pauldron sits above the helm and one below, each with its blade pointing away, and the visor is
  on the helm's front edge.

## What I think of it

- The front view reads as the same Mecha as the crew sheet, seen from above.
- The back view is hard to tell from the front at game size; only the purple is missing.
- The side view is the weakest: it reads as a dart with a visor more than as a figure.

## Tools

`python3 tools/build.py`, run from this folder, rebuilds the sheet and the pictures. `tools/mech.py` holds the frames
as text, one character a pixel. The build borrows the picture helpers of `docs/art/terran/crew-test-4/tools/pix.py`.
