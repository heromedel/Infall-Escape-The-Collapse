# Tabby crew sheet (Facing style)

**Date:** 2026-11-11
**Status:** a test, waiting for heromedel's verdict. The mercenary cat of
[`../cat-concept-for-gatos`](../cat-concept-for-gatos) animated, so the GATOS as Tabbys have a Facing sheet like the
Terran drifter's. The standing views are that concept's, unchanged; every animation frame is an
**Ai-Generated-Proposal (2026-11-11)**. Not in the game yet.

![The sheet at 4x](tabby-crew-sheet-4x.png)

![Walking](review/walk-4x.gif)

280 × 490 pixels: 35 × 35 frames, 8 per row, in the order of the other Facing sheets (the `eight-wide` layout in
`infall-godot/content/crew-layouts.xml`), with the boots on the same line.

| Row | Frames |
|---|---|
| 1 | Walk down, then walk right |
| 2 | Walk up, then walk left |
| 3 | Aim down, then aim right (three aims each: straight, a little one way, a little the other) |
| 4 | Aim up, then aim left |
| 5 | Fight fire down, then right (a red extinguisher in the same paw, sweeping; no spray drawn) |
| 6 | Fight fire up, then left |
| 7 | Punch up |
| 8 | Punch down |
| 9 | Type right, then type left |
| 10 | Type up, then type down |
| 11 | Teleport |
| 12 | Death |
| 13 | Clone |
| 14 | Portrait, crew laser shot, a gap, then repair (4 frames) |

## How each animation is staged

- **Walk:** the first frame of each direction is him standing. On a step the body sinks a pixel onto the leading
  leg, whose knee bends so its boot stays on the deck's line. Toward us the leading boot shows more of its top and
  the trailing boot is lifted and smaller; the arms swing against the legs by a pixel. Away from us his arms stay
  ahead of him, out of sight, as when he stands. From the side the near and far legs stride in turn with the deck
  showing between them, and the near arm swings back to the holster and forward across his chest. The tail follows
  a beat behind: it sways beside his hip, flicks across his calf, or leans and straightens behind him.
- **Aim:** he draws the pistol, so the holster hangs empty. One arm acts, as on the other sheets. Toward us the arm
  is out from his side so the pistol hangs over the deck, clear of his leg; away from us it rises beside his head,
  leaning out so deck shows between it and his ear; from the side the paw sits under the pistol's slide. Between
  the three aims the whole arm swings and the pistol never changes shape (heromedel, 2026-11-12: the first version
  bent the gun and left the arm still).
- **Fight fire:** the aiming arm with a red extinguisher, sweeping straight, one way, straight, the other way. No
  spray is drawn: the game adds it (heromedel, 2026-11-12). The nozzle is the dark tip beyond the red; in the
  frame's own pixels it is at about (10, 31) toward us, (25, 22) to the right and (25, 14) away from us.
- **Punch:** one arm, with his weight behind it (heromedel, 2026-11-12: the first version moved only the arm). He
  shifts away as the fist draws back, then steps in with the other leg and sinks a pixel as the arm goes out, and
  his head dips as it lands. Away from us the elbow pokes out first, and the arm goes out ahead of him, which from
  behind is up beside his head.
- **Type:** from the side the forearms are out and the paws tap in turn; toward us the paws meet at his belt; away
  from us his elbows work in turn. The tail tip flicks once a loop. The pistol is back in the holster.
- **Repair:** on one knee, a hammer up, forward, down on the work, forward.
- **Teleport, clone, laser shot:** made the same way as the Terran drifter's (`../crew-test-3`): his own columns
  dragged upward, the cool white plate lowering, the power-green shot.
- **Death:** staged as a knockdown is, after looking up how they are built: a hit (eyes shut, arms jolted out, a
  pixel off the deck), two frames going over with his feet leaving the deck, flat in the air, the landing, a small
  rebound, then one lying pose in which his top arm flops across his belly. Every frame is one whole figure, so his
  head never leaves his shoulders (heromedel, 2026-11-12: the first version slid the head sideways and he looked
  decapitated for a frame).
- **Portrait:** his head and shoulders drawn larger by hand: the heavy lids, the scar, the notched ear.

## How it is made

Every frame is drawn by hand as text, one character a pixel, in `tools/tabby.py`; the colours are in
`tools/pix.py`. A frame is a few hand-drawn parts laid back to front, and each pose of a limb is its own drawing.
Left-facing frames are the right-facing ones mirrored. Some frames are worked out from drawn ones: the teleport,
the clone bay's plate and the laser shot (as on the drifter's sheet), and in the death the lying figure, which is a
drawn pose turned a quarter turn (every pixel moves, none changes), and the two going-over frames, which are the
hit pose turned part of the way and then checked by eye (`turned` in `tools/pix.py`). `python3 tools/build.py`, run from this
folder, rebuilds the sheet and the pictures in `review/`.

## Review pictures

- `review/walk-4x.gif`, `walk-1x.gif`: walking down, right, up and left.
- `review/work-4x.gif`: typing down, right and up, repairing, and fighting fire down, right and up.
- From 2026-11-12 every row is shown to a blind checker (a reader told nothing about what each strip is meant to
  be) before it goes to heromedel. Two passes so far. What it still reads loosely, and why it was left: seen from
  behind, the raised arm with a pistol or a fist is not clearly aiming or punching (it is the same staging as the
  other sheets); the lying figure is recognisably the standing one turned; the kneel is compact; and in the back
  view the tail starts where the strap ends, as in the concept's standing drawing.
- `review/fight-4x.gif`: the three aims down, right and up, then punching down and up.
- `review/death-4x.gif`, `review/teleport-clone-4x.gif`.
