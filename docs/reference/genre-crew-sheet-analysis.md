# The genre's human crew sheet, measured

**Date:** 2026-11-10
What FTL's human crew sheet actually contains, frame by frame, so nobody has to explain an animation to an art
session again. Everything here was measured from the sheet (`people/human_base.png`) and from the game's own
animation definitions (`animations.xml`), not judged by eye: frame counts and times come from the definitions, and
"what moves" is a pixel-by-pixel comparison of one frame with the next. heromedel's labelled breakdown of the first
row (a Procreate file, 2026-11-10) supplied the names of the parts and several corrections; those are marked
**(heromedel)**. This document holds words and numbers only. None of the genre's pixels are in the repo.

Rows are counted from the top of the sheet, frames from the left, pixels from the top left of a 35 × 35 frame.

## 1. How the figure is built

The human is seen from almost straight above. He is a stack of five parts, top to bottom **(heromedel)**:

| Part | Facing the camera | What it is |
|---|---|---|
| Head | 7 × 7 with its outline, 45 pixels | Hair on top. The lower rows are face: one skin pixel of forehead, a row of five, a chin of three. **No eyes**: the dark pixels around it are outline **(heromedel)**. |
| Shoulder blades | two pads, each 4 wide and 3 tall inside its outline; 42 pixels the pair | They sit **on top of the torso**, one each side of the head, and are the widest thing on him. |
| Torso | 9 × 4 with outline: two lines of 7, a dark one over a lighter one | Mostly hidden under head and pads. |
| Arms | a sleeve running down from each pad, then a fist | The fist is **one skin pixel in a square of outline**. |
| Feet | one line of 5 pixels under the torso | Legs do not show when he stands. |

Measured sizes of the whole figure:

| View | Size | Pixels | Of which outline |
|---|---|---|---|
| Facing the camera | 17 wide × 12 tall | 144 | 43% |
| Facing away | 17 wide × 12 tall | 142 | 49% |
| Facing right | 9 wide × 18 tall | 118 | 47% |

- **Nearly half of every figure is outline.** The outline is one colour (`#191a16`), and it is what separates the
  parts: head from pads, pads from torso, fist from sleeve.
- **Ten colours draw him:** the outline, two whites (coat), three hair browns, two torso tones, two skins. A pistol
  adds two greys; an extinguisher adds two reds and a dark brown. Nothing else appears on the action rows.
- **Facing away** he is the same build with the head all hair and only the two fist pixels of skin.
- **Facing right** the stack runs down the screen: the far shoulder pad at the top, the head below it with its face
  on the right, then the near pad and sleeve, ending in the near hand at the bottom. The torso shows as three pixels
  at the edge. No legs or feet show at all when he stands.
- **Where he sits in the frame:** facing the camera his box is x 8–24, y 9–20, so his centre is about (16, 14), a
  little up and left of the frame's centre (17, 17). The space below and around him is what the action rows reach
  into.

## 2. The rows, their frames and their timing

From the definitions. "Drawings" is how many different pictures the frames really are.

| Row | Frames | Animation | Time | A frame | Drawings |
|---|---|---|---|---|---|
| 1 | 1–4 | Walk down | 1.0 s | 250 ms | 3 (frame 3 is frame 1 again) |
| 1 | 5–8 | Walk right | 1.0 s | 250 ms | 3 (frame 7 is frame 5 again) |
| 2 | 1–4 | Walk up | 1.0 s | 250 ms | 3 |
| 2 | 5–8 | Walk left | 1.0 s | 250 ms | walk right mirrored (0–4 pixels differ) |
| 3 | 1–3 | Aim down | 1.0 s | 333 ms | 3 |
| 3 | 4–6 | Aim right | 1.0 s | 333 ms | 3 |
| 3 | 7–9 | Aim up | 1.0 s | 333 ms | 3 |
| 4 | 1–4 | Fire down | 1.0 s | 250 ms | 3 (frame 4 is frame 2 again) |
| 4 | 5–8 | Fire right | 1.0 s | 250 ms | 3 |
| 5 | 1–4 | Fire up | 1.0 s | 250 ms | 3 |
| 5 | 5–8 | Fire left | 1.0 s | 250 ms | 3 |
| 6 | 1–9 | Repair | 1.0 s | 111 ms | 3, played 1 2 3 3 2 2 1 1 1 |
| 7 | 1–6 | Punch down | 1.0 s | 167 ms | 6 |
| 8 | 1–4 | Type right | 0.75 s | 188 ms | 4 |
| 8 | 5–8 | Type left | 0.75 s | 188 ms | 4 |
| 9 | 1–4 | Type up | 0.75 s | 188 ms | 4 |
| 9 | 5–8 | Type down | 0.75 s | 188 ms | 4 |
| 10 | 1–9 | Teleport | 0.5 s | 56 ms | 4, played 1 2 3 2 3 4 5 5 5 |
| 11 | 1–6 | Clone | 0.75 s | 125 ms | 6 |
| 12 | 1–3 | Aim left | 1.0 s | 333 ms | 3 |
| 12 | 4–9 | Punch up | 1.0 s | 167 ms | 5 |
| 13 | 1 | Portrait | | | the standing frame, pixel for pixel |
| 13 | 2 | Crew laser shot | 0.5 s | | a plain white bar, 3 × 11 |
| 13 | 4–8 | Death | 0.75 s | 150 ms | 5 |

## 3. Each animation, and what actually moves

### Walk (4 frames)

- Frames are **stand, step, stand, step**. Frames 1 and 3 are the same picture. The second step is the first one
  mirrored (18 pixels differ facing the camera, 6 facing away, from shading) **(heromedel: "mirrored from first two
  frames")**.
- **Only fists and feet move.** Facing the camera, 43 of his 144 pixels ever change, and all of them lie in the
  lower rows (y 14–21). The head, the pads and the torso do not change by a pixel: **no bob** **(heromedel)**.
- On a step one foot comes forward: the feet line becomes a foot three rows tall on one side, and the figure grows
  one row taller. The other foot swings back and is hidden **(heromedel)**.
- The arms answer the feet: one fist shows forward, the other swings back out of sight. Facing away, the forward
  fist appears as a single skin pixel up at the top corner of its pad.
- Facing right there is more to redraw (70 of 118 pixels change): the near arm and hand swing, and on the second
  step a leg reaches back and a foot forward, the only frames where a leg shows from the side.

### Aim (3 frames, 4 directions)

- **The three frames are three aims: straight, a little to his right, a little to his left** **(heromedel)**. The
  body is the same in all three; only the gun arm is redrawn (40–71 pixels).
- **There is no flash, blast or particle.** The only colours these frames add to the standing figure are the
  pistol's two greys. The shot is a separate sprite, the white bar on row 13, drawn by the game.
- The definitions give the three frames one second like any animation, so in play they would follow one another:
  his aim sways centre, right, left. (Inference from the definition; not watched in the game.)
- The gun is **long and thin and held at the end of a straight arm**: three to six grey pixels in a dark outline,
  reaching 4–5 pixels past where his hand hangs. It is always in **his right hand**: on the viewer's left when he
  faces the camera, on the viewer's right from behind, on the near (lower) side facing right, on the far (upper)
  side facing left. That is why aim left is a new drawing and not aim right mirrored (51–74 pixels differ).
- Facing the camera the gun points down the screen; angled, it swings out past his side by two pixels or in under
  his body. Facing away it points up past his shoulder by three pixels. Facing right it lies level, then tips down,
  then tips up.

### Fire (4 frames, 4 directions)

- The extinguisher is a **red block two pixels by three (5–6 red pixels) in a dark outline, at the end of the same
  straight arm**, the right one.
- **There is no spray.** The four frames **sweep it from side to side**: facing the camera it sits at x 8, then 11,
  then 13, then back to 11. Facing right it sweeps down and up the same way.
- 23–69 pixels change a frame; the body stays as it is.

### Repair (9 frames, one direction)

- He is **bent over or kneeling, seen from above**: a different, wider figure (20 × 15) leaning to the right.
- There are only **three drawings**, held for uneven times (1 2 3 3 2 2 1 1 1) to make the tool rise and fall.
- Only the tool arm moves: about 24 pixels, all at the right edge. The tool is drawn in the outline colour alone, a
  forked shape, with **no spark**.

### Punch (6 frames, facing the camera and facing away)

- This is the one row where **the whole body is redrawn every frame** (100–150 pixels change each time).
- Facing the camera: a foot steps forward under him, then the arm goes out down the screen with a fist at its end,
  reaching five rows below where he stands, and comes back. His body drops three rows with the lunge.
- Facing away: the same lunge up the screen. The arm reaches seven or eight rows above his head with the fist at
  the top, held for two frames.
- One arm punches. The other stays at his side.

### Type (4 frames, 4 directions)

- **Both hands are out in front of him and visible**, each a couple of skin pixels, and they take turns moving a
  pixel or two. All four frames are different drawings, but only 15–42 pixels change.
- Facing right the hands are in front of his face, one above the other on the screen. Facing away they show as skin
  pixels along his top edge; facing the camera, along his bottom edge.
- No console is drawn.

### Teleport (9 frames in half a second)

- Frame 1 is the standing figure **moved eight rows down the frame** (one pixel differs), to leave room above.
- Then **columns of his own pixels are drawn out upward**: white from the pads, brown from the hair, skin from the
  face. No colour is added: every streak is one of his ten colours **(heromedel: real pixels dragged up, no light)**.
- **His body stays the same size and in the same place throughout**: 17 wide, feet on the same row in every frame.
  What changes is how far the streaks reach above his head: 2 rows, then 5, then **2 again, then 5 again** (frames 4
  and 5 are frames 2 and 3 repeated), then 8, then 13, and the last drawing is held for three frames.
- **He comes apart as it happens.** Of his 144 standing pixels, 118 are still in place in the small frame, 102 in
  the larger, 65 in the next and 39 at the end: the lower body breaks into separate columns with gaps between.

### Clone (6 frames)

- It is **not the clothed man**. A grey lump (34 pixels) grows into a grey figure, the colour comes in from the
  bottom, and it ends as a bare flesh-coloured figure slightly smaller than he is (15 wide). The game then shows him
  normally.

### Death (5 frames)

- It starts from a **side-view** standing frame, not the camera-facing one.
- Frame 2: he staggers, arms out and body twisting (17 × 16). Frame 3: he is going over backwards, arms up
  (19 × 16). Frame 4: he is down, lying along the frame (24 × 11). Frame 5: he settles, three rows lower and three
  pixels shorter (21 × 11).
- Every frame is a full new drawing (180–230 pixels change). He ends face up with his head to the right.

### Portrait and laser shot

- The portrait **is** the camera-facing standing frame: not one pixel differs. There is no separate head-and-shoulders
  drawing.
- The laser shot is pure white, so the game can tint it.

## 4. Rules that hold across the sheet

1. **The body is left alone.** Outside punching and dying, an action redraws one arm and what it holds. The head,
   pads and torso are the same pixels as in the standing frame.
2. **Nothing is an effect.** No flash, spray, spark or light is drawn on the human's sheet anywhere.
3. **Things are held at arm's length**, on a straight arm that leaves his outline, in his right hand.
4. **Small numbers.** A fist is one pixel. A gun is five. An extinguisher is six. A step is one foot three rows
   tall. Typing is a pixel or two.
5. **Frames are reused.** Walk, fire, repair and teleport each have three or four real drawings behind more frames.
6. **Left is only a mirror when his hands are empty.** Walk left mirrors walk right; aim, fire and type left are
   drawn again because he is right-handed.

## 5. The other races

- Every race's sheet is drawn from nearly above, like the human's (checked: Lanius, Mantis, Rock, Engi, Slug).
- **Frame counts are not fixed.** Each race has its own definitions: the Mantis walks in 5 frames and punches in 10;
  the Rock and the Crystal fight fire in 10; deaths run from 5 frames (human) to 10 (Zoltan); the Lanius repairs in
  4. Typing takes 0.75 s for humans and slugs and 1.0 s for most others. So a sheet's layout belongs to its race,
  and the game reads it from the race's definitions.

## 6. Weaknesses in the genre's sheet

- One of the side-view walk frames "doesn't make sense", and a foot sits in the wrong place **(heromedel)**.
- The definitions point "death left" at the clone row, so the human has only one real death, falling one way.
- Repair is three drawings stretched over nine frames, and its tool is a black fork that could be anything.
- The fist is a single pixel and the feet a single line, so hands and feet carry no shape at all.
- The face is skin with no features; from the side, the head and the far shoulder read as one white-capped lump.
- Legs never show from the side when he stands, so the side figure is a head between two blobs.
- There is no room for clothing: his coat is the two pads and two sleeves, and nothing below the torso is his.
- Nothing separates one human from another but colour.

## 7. What earlier art sessions got wrong, against these facts

| What was drawn (crew test 3, first rounds) | What the sheet does |
|---|---|
| Shooting as aim, fire with a flash, lower | Three aims, no flash |
| Teleport as turning to light | His own columns drawn upward, flickering, while he comes apart |
| A walk that bobs the whole body and swings both arms | Only fists and feet move |
| An extinguisher held to the body with a spray | A red block at arm's length, swept side to side, no spray |
| Punching with both fists raised first | One arm, with a step and a lunge |
| Death as kneel, then suddenly flat | Stagger, going over, down, settling: five full drawings from the side |
| A separate portrait | The standing frame |
| Typing with hands at the waist | Both hands out in front, a pixel or two each |
| Seen from the front | Seen from almost straight above |

## 8. For a top-down drifter (Ai-Generated-Proposal, 2026-11-10)

How the Terran drifter of crew test 3 could be carried into this build. Nothing here is agreed.

- The pads and sleeves are his **brown duster**; the pads become its shoulders.
- His **quiff** is the head: dark hair with its highlight pushed to one side, and less face showing than the genre's
  human.
- The **blue bandana** is one or two blue pixels where the head meets the torso.
- The **coat's tail is hinted, not drawn**: two brown pixels under the torso that kick back when he steps
  (heromedel's suggestion, 2026-11-10).
- Facing away, the **chevron** is two or three blue pixels on the torso line between the pads.
- Everything in sections 3 and 4 is followed frame for frame; the pixels are our own.
