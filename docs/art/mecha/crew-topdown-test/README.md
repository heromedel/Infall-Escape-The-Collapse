# Mecha crew, top-down test

**Date:** 2026-11-11
**Status:** a test, third version, shown to heromedel and not yet judged. It answers one question: can the nearly
top-down view that worked for the Terran drifter (`docs/art/terran/crew-test-4`) be drawn for a race that has no
human sheet to follow?

![The four views beside the drifter](review/beside-the-drifter.png)

A HalfMech in its suit at the drifter's frame size (35 by 35). He is larger than the drifter, 27 pixels across with
his spikes against 17, and that is intended: a suit is supposed to be larger than a Terran (heromedel, 2026-11-11).

- `mecha-topdown-sheet.png` (and `-4x`), eight frames a row and seventeen rows: the genre's layout, with a row of
  its own for each direction of powering a console and two for the clone bay. Rows not drawn yet are left empty, so every frame is already where
  it will stay:

  | Row | Frames |
  |---|---|
  | 1 | Walk down (4), walk right (4) |
  | 2 | Walk up (4), walk left (4) |
  | 3 | Aim down (3), aim right (3) |
  | 4 | Aim up (3), aim left (3) |
  | 5, 6 | Fighting fire: to come |
  | 7, 8 | Punching up and down: to come |
  | 9, 10, 11, 12 | Powering a console: right, left, up, down (8 each) |
  | 13, 14 | Teleport and death: to come |
  | 15, 16 | The clone bay (10: eight, then two) |
  | 17 | Portrait, crew laser shot, a gap, repair (4) |

- `mecha-topdown-laser-shot.png`: his crew laser shot, the genre's bar in Mecha purple with a hot core.
- `review/walks-8x.gif` and `-4x.gif`: the four walks moving. `review/aims-8x.gif`: the four aims, each held a
  while. `review/powering-8x.gif` and `-slow-8x.gif`: powering a console in the four directions, the
  clamp-on once and the pulse three times. `review/clone-10x.gif` and `review/clone-slow-10x.gif`: the clone bay at
  game speed and slowed. `review/pilot-12x.png`: the four frames with the pilot. `review/repair-8x.gif`: the repair. `review/aims-down-up-8x.png` and `review/aims-right-left-8x.png`: the aim frames laid out.
  `review/views-10x.png`: the four standing views. `review/beside-the-drifter.png`: both figures at game size, twice
  and four times. `review/beside-heromedels-drawing.png`: the front view beside the drawing it follows.
- `reference/heromedel-mecha-topdown.png` (and `-8x`): heromedel's own drawing of the suit from above, standing and
  facing the camera, 86 by 48 pixels, about four times game size. It was offered as one more inspiration, not as
  law.

## The design

After heromedel's drawing, brought down to game size by hand (nothing is scaled or traced), in the colours of the
Mecha crew palette (`docs/art/palette.md`):

- A boxy helm with a pale ridge down the middle and a short purple visor bar on its front edge. The ridge reaches
  one pixel past the top of the helm, a slight point, with the outline pixel there pushed up one (heromedel,
  2026-11-11). Side on, the same point shows at the back of the helm.
- A shoulder plate each side, with a thick spike sweeping up and out of its outer corner. They are shoulders:
  HalfMech suits do not have wings (heromedel, 2026-11-11).
- An arm straight down from under each plate to a grey powered clamp claw with a purple band. heromedel likes the
  clamp claws, and asked for them straight, not bent, and for the thicker spikes of the first version (2026-11-11).
- Two chest lights under the visor, on a torso four rows deep, and two pointed feet. The torso was two rows;
  heromedel had it extended down two pixels with the lights left where they were (2026-11-11). The back view has
  the same torso. Its two bottom outline corners are trimmed, as on the drifter's coat (heromedel, 2026-11-11).
- **A hint of a face (heromedel, 2026-11-11):** on the front the two chest lights are eyes, and a mouth three pixels
  wide sits under them, one tone darker than the armour. It is meant to be hard to notice.
- **Helm shading:** the tones fall off from the top left to the bottom right. They were in columns either side of
  the ridge, the same fault the feet had. `review/helm-shading-before-after-16x.png` shows front and back, before
  then after. The same regrade was tried on the side view's helm after its ridge moved up a row;
  heromedel found it worse, so the side helm keeps its plain shading, lit above the ridge and dark below
  (2026-11-11).
- The feet are two pixels long and stand apart from the torso and from each other, each with its own outline
  (heromedel, 2026-11-11). A stepping foot reaches a pixel further and the other draws in a pixel. Each
  foot is shaded from the top left (one lit pixel, armour, shadow at the bottom right), not in columns, which read
  as vertical stripes.
- **Spikes and arms at different angles (heromedel, 2026-11-11):** the spike leans out from the plate's outer
  corner and the claw hangs straight from under its middle. The first version of this test hung each claw straight
  under a blade that stood straight above it, and on a still frame the two read as one stacked piece.

How the other views follow from it:

- From behind there is no visor and no chest light. The crest still runs the whole helm, but the back plate is plain
  dark shading with no pale line down it (heromedel, 2026-11-11). The claws keep their bands.
- Facing right is the front view turned a quarter: one shoulder plate above the helm and one below, the spikes
  sweeping back and out, the claws pointing straight ahead, the visor on the helm's front edge.
- Standing side on, both feet show ahead of the helm, so he is not so thin (heromedel, 2026-11-11).
- Side on is not a strict quarter turn (heromedel, 2026-11-11): his left shoulder, the far one at the top when he
  faces right, is a row shorter where it meets the helm, and his feet sit toward the near side, the left foot a
  row down and the right foot two. The ridge, the visor and the crest's point sit one row above the helm's
  middle, toward the far side; the helm's own shape is unchanged.
- **The walk swings (heromedel, 2026-11-11).** The first walks lengthened and shortened the arms and legs, which
  read as pistons. Now every part keeps its shape and moves as a piece: a shoulder plate swings a row forward with
  its spike and claw, the other swings a row back and its claw tucks up under it, and the foot opposite the forward
  arm swings forward on a pixel of leg while the other draws back under the torso. The genre's rock crew, the
  nearest build to this one, walks the same way: its whole shoulder line tilts with each step.

## Aiming

Staging after the genre's sheets (its lanius sheet for the row layout): three still aims a direction, straight, a
little to his right and a little to his left, with no flash, and the shot a sprite of its own. No pixels are taken.

- **Ai-Generated-Proposal (2026-11-11):** he has no pistol. He aims his right claw with the clamp open on a
  deep-purple emitter between its two prongs, and the shot leaves from there. The old Mecha crew sheet also fires
  from the arm.
- The shoulder of the aiming arm swings forward a row and the arm reaches three rows. Aimed aside, the arm steps two
  pixels over on the way. Nothing else moves.
- Facing away, the claw rises from under the far edge of his shoulder plate, between the helm and the spike.
- Facing left is the mirror of facing right with the other arm aiming, so it is still his right arm.

## Powering a console

The style guide's power-pulse rows were made for an earlier figure with a longer bar down the arm (heromedel,
2026-11-11). For this one, **Proposed (heromedel, 2026-11-11):** he clamps on with both claws and stays clamped,
pulsing. Eight frames:

- Frames 1 and 2, played once: he reaches with both clamps open, then sets them on the console.
- Frames 3 to 8, looped while he holds on: the clamps closed; the wrist bands flare bright purple; the light runs
  down into the claws; at the tips it begins to turn; it lands on the console in power green; the green lingers.
- The flare is bright purple, not white, and the light passes through the palette's two in-between pulse shades on
  its way to green (heromedel, 2026-11-11, after a first version of four frames with a pale flash and no clamp-on).
- Purple turning power green where it reaches the console is kept from the Decided entry, so it works on any race's
  console.
- The game would need to play the first two frames once and loop the other six; the genre's typing rows loop whole.

## Repairing

**Proposed (heromedel, 2026-11-11):** he repairs with the clamp claw and no wrench. Side on, four frames: the near
claw opens on the work, closes, turns it a pixel while the far claw steadies, and comes back.

## The clone bay

**Proposed (heromedel, 2026-11-11):** the clone animation shows a suit being put together, and a brief glimpse of a
small HalfMech jumping into the back of it. She is drawn like the top-down Terran, in HalfMech colours, and is a
girl. Ten frames:

- Frames 1 to 4: the suit is built, not grown. It goes together in its own colours, unlit, a piece at a time: feet
  and torso, shoulder plates, arms and claws, helm. Each piece wears a bright purple edge only on the frame it
  arrives. heromedel was in two minds about a purple outline on a suit that is being constructed, not cloned
  (2026-11-11); the first version tinted the whole suit purple, and this keeps the colour to the arriving piece.
- Frames 5 and 6: the pilot is on the ground behind the suit before she jumps (heromedel, 2026-11-11). She walks up
  a little to one side, the top of her head and her ponytail showing over the helm, then stands in place and dips
  to jump. From almost straight above, the back of the suit is its top edge on the screen.
- Frame 7: she is in the air, all of her clear of the helm.
- Frame 8: she drops in; only her ponytail still shows.
- Frame 9: the lights come up dim, in deep purple. Frame 10: he stands. The first version flashed the lights pale for
  a frame, which read as the suit staying white before powering (heromedel, 2026-11-11).
- **The pilot:** purple hair in a ponytail that swings out to one side from a bright tie, pale skin, dark clothes,
  narrow shoulders with a hand at each side, one implant light; the colours of heromedel's HalfMech pilot art
  (`docs/art/mecha/pilot`). The ponytail is what says "girl" at this size. The first pilot had her fists raised
  above her head, which read as a boy making a rude gesture with both hands (heromedel, 2026-11-11); a second try
  with a ponytail straight up read as a pointed hat.
- This is the one place a HalfMech is seen out of the suit. The style guide and the pilot's README said there were
  no plans to show one; both now note this glimpse.

## What I think of it

- The front and back views read as heromedel's suit at game size.
- The side view is still the weakest. It is correct as a turn of the front view, but with the shoulder plates as long as
  they are it reads as a bracket more than as a figure.

## Tools

`python3 tools/build.py`, run from this folder, rebuilds the sheet and the pictures. `tools/mech.py` holds his parts
as text, one character a pixel (helm, torso, each shoulder plate, each claw, each foot), and builds every frame by
setting the same parts at different places, so a change to one part carries into every frame. The build borrows the picture helpers of `docs/art/terran/crew-test-4/tools/pix.py`.
