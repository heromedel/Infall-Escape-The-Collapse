# Terran crew test 3: the drifter in a duster

**Date:** 2026-11-09
**Status:** a test, waiting for heromedel's verdict. Made in one sitting without questions, to see whether a Terran
can be drawn to sit beside the Mecha and Tentauri crew sheets. Everything about the look is an
**Ai-Generated-Proposal (2026-11-09)**.

![The sheet at 4x](terran-drifter-sheet-4x.png)

![Walking beside the Mecha and the Tentauri](review/walk-4x.gif)

A Terran seen from about 45 degrees above (the 1/2 view): a dark quiff, a brown duster with a fleece collar, a
GATOS-blue bandana at the neck, an olive shirt, dark trousers and boots, and a blue scout chevron on the coat's back.
The bandana and the chevron are the one accent, as purple is for the Mecha.

- **Decided (heromedel, 2026-11-10):** this drifter keeps the chevron, but it is his own emblem: there is no
  universal Terran or Tabby emblem, and other Terrans will wear other emblems.
- **Proposed (heromedel, 2026-11-10):** the hands are fists of four pixels (they were flat, two pixels wide and one
  tall).
- **Proposed (heromedel, 2026-11-10):** he stands 23 pixels tall, two shorter than the Mecha in its suit (he was 26,
  a pixel taller than it). A row came out of the chest, one out of the coat's skirt and one out of the legs.

280 × 490 pixels: 35 × 35 frames, 8 per row, with the boots on the same line as the Mecha's feet. The rows are in
the order of the Mecha and Tentauri sheets, so the game can read all three the same way:

| Row | Frames |
|---|---|
| 1 | Walk down, then walk right |
| 2 | Walk up, then walk left |
| 3 | Shoot down, then shoot right (a pistol aimed straight, a little to his right, a little to his left) |
| 4 | Shoot up, then shoot left |
| 5 | Fight fire down, then right (a red extinguisher in the same fist; no spray drawn, the game adds it) |
| 6 | Fight fire up, then left |
| 7 | Punch up (one fist draws back and goes out; the other arm hangs) |
| 8 | Punch down |
| 9 | Type right, then type left |
| 10 | Type up, then type down |
| 11 | Teleport (each column of his own pixels is dragged upward, further every frame) |
| 12 | Death (he reels, his knees go, he topples to his left and lands sprawled on his back) |
| 13 | Clone (a plate lowers and he stands there) |
| 14 | Portrait, crew laser shot, a gap, then repair (on one knee, a hammer up and down, 4 frames) |

No particles are drawn on the sheet (heromedel, 2026-11-12): the extinguisher's spray and the sparks where the
hammer lands came off, and the game makes them (GV 7F).

- **Decided (heromedel, 2026-11-10):** the three shooting frames are three aims, as on the genre's sheet, not an
  animation, and they have no flash or particle.
- **Decided (heromedel, 2026-11-10):** the teleport works as on the other sheets: his real pixels, the inner ones
  too, are pulled upward by different amounts, with no light or effect. The first version, where he turns to light,
  is kept as an alternative: `terran-drifter-teleport-light.png` (8 frames in a row).
- **Decided (heromedel, 2026-11-10):** a punch is one arm; both fists coming up looked odd.
- **Ai-Generated-Proposal (2026-11-10):** the crew laser shot is power green, since GATOS ships use power green
  (`palette.md`); the clone bay's plate is a cool white. The Mecha sheet's rows 15 and 16 are its own and have no
  match here.
- **Decided (heromedel, 2026-11-10):** the side view keeps its first drawing, with the coat tail and the lifted-foot
  pixels trimmed flat and one pixel off each corner at the hem; the shoulders stay square.
- **Proposed (heromedel, 2026-11-10):** the back of the coat has no centre line, and the front-view boots have no
  toes, matching the back view.

## What went wrong on the way (2026-11-10)

The action rows took four rounds. What to do differently for the next Terran or the next race:

- Look at the genre's sheet and the Mecha and Tentauri sheets row by row before drawing a row, and copy how each
  action is staged. The first round was drawn from imagination, which is how shooting became an animation with a
  flash and the teleport became a light effect.
- Keep an action small. One arm acts; the rest of him stands as he stands. Rounds two and three, driven by a blind
  checker's notes, pushed arms far outside his outline, added impact stars and leaned the body, and looked worse.
- A blind checker is good at catching an unintended reading (a canister that looks like a ball at the crotch, a tool
  that looks like something else). It is not a judge of what looks good; heromedel is.
- A thing held in the fist must sit away from the coat with an outline between them, and its metal must be darker
  than a light deck, or it reads as a hole.

## How it is made

Every pixel of the figure is placed by hand as text, one character a pixel, in `tools/drifter.py`; the colours are in
`tools/pix.py`. A frame is a few parts laid over each other (legs, then the upper body), and a walking frame drops the
upper body a pixel when a foot lands. No filter, blur, outline pass or scaling touches the picture. Left-facing frames
are the right-facing ones mirrored. Four things are worked out from drawn frames instead of drawn: the teleport (his own columns
pulled up) and its light alternative, the lean of the fall (rows slid sideways whole), the clone bay's plate, and
the laser shot. `python3 tools/build.py`,
run from this folder, rebuilds the sheet and the pictures in `review/`.

## Review pictures

- `review/game-size.png`: the three races standing, at game size, 2x and 4x.
- `review/walk-1x.gif`, `walk-2x.gif`, `walk-4x.gif`: all three walking in the four directions.
- `review/console-1x.gif`, `console-2x.gif`, `console-4x.gif`: all three at a console.
- `review/actions-2x.gif`, `actions-4x.gif`: his other animations looping. Top row: aiming down, right, up and
  left, punching down and up, repairing. Bottom row: fighting fire down, right, up and left, teleporting, dying, the
  clone bay, and the light teleport kept as an alternative.
