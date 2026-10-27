# GATOS (Terran) crew

**Date:** 2026-10-27
**Status:** round 5 (experiment, not pushed), three options for heromedel. **Ai-Generated-Proposal** in every detail, built on heromedel's
direction (2026-10-27): pants, dark boots, a mid-tone shirt and a jacket, a rough look; a subtle mix of a space
alliance, a Mexican gang and a 1980s punk gang (no mohawks), as if the GATOS were an alliance of legal and sometimes
benevolent Terran gangs; leaning leather jackets and long-coated mercs, with Firefly as one style inspiration; no
spacemen, nothing cute or cheesy, no stereotypes. Facing forward, seen from about 45° above (heromedel's "1/2"
angle), upright enough to sit with the Mecha and Tentauri crew. Each person has their own emblem, not one alliance mark.

**Round 5 as SVG (2026-10-27):** `svg/gatos-drifter.svg`, `gatos-leather-jacket.svg`, `gatos-vest-merc.svg`: the
round 5 pixel art exported pixel for pixel, nothing changed (one path per colour; the viewBox is the 70 × 70 frame, so
they scale to any size with crisp pixels; checked: every pixel matches). Built by `tools/export_svg.py OUT_DIR`.

**Drifter at 2x resolution (experiment, 2026-10-27):** `svg/gatos-drifter-2x.svg` (140 × 140), built by
`tools/hires.py drifter OUT.svg` from the round 5 pixels: each pixel becomes a 2 × 2 block, then the outline thins to
one sub-pixel, one-pixel stair-steps on the silhouette lose their outer corner, and the shading gains in-between
tones (each 4-tone ramp becomes 7, each sub-pixel a soft average of its neighbours snapped to that ramp); the face keeps
its hand-placed pixels. `review/gatos-drifter-2x-compare.png`: round 5 (left) beside it (right).

**Vector test (experiment, 2026-10-27):** heromedel: the pixel versions look flat, with beady eyes and shading so
contrasty it reads as embossed panels; try higher resolution or vectors, from scratch, with rounder, subtler and more
anatomical shading. The drifter redrawn as a vector (`review/gatos-drifter-vector.svg`, built by
`tools/vector_drifter.py`) over the rig's joints: rounded shapes with soft, low-contrast gradients, a head at the 45°
view (the crown and parted, tousled hair above, the face lower and shorter), almond eyes with whites under a brow
shadow, a nose and jaw shown by shadow, sleeves that read apart from the coat, hands with thumbs, the coat's lapels,
belt and folds drawn as soft shapes. Shown large, at 2x and at true size (`review/gatos-crew-vector-test.png`).

![Vector test](review/gatos-crew-vector-test.png)

![Round 5](review/gatos-crew-round5.png)

**Round 5:** the same three outfits fitted to heromedel's rigged model (`reference/heromedel-rig-front-right-back.png`;
its front view, the 1/2 view, cut to `reference/rig-front-45.png`). The joint and clothing-edge marks are cleaned off
the picture; each pixel goes to its nearest bone (torso, upper and lower arms, thighs, shins, feet), hands start at the
wrists, the shirt ends at the model's hem line, and the clothing is placed by the joints (the duster reaches between
the knees and ankles). Built by `tools/show2.py OUT.svg` (`tools/rig.py`, `tools/paint2.py`, `tools/crews2.py`).
**Round 5, pass 2:** the duster shaded as a trench coat, from cloth-shading advice (folds start where the cloth
hangs from, shadow only along the fold lines, slightly bent lines, one light direction): lit shoulder tops, lapels
folded back with a shadow under their edge, a belt at the waist, one soft fold per panel hanging from the belt and
drifting outward as the coat flares, a lining line on the open front edge, the hem in shade. The boots are now one
matched pair, the same shape on both feet. Round 4 is kept below for comparison.

![Round 4](review/gatos-crew-round4.png)

| Option | Look | Emblem |
|---|---|---|
| 1. Long-coat drifter | brown leather duster to the shins, teal shirt, dark trousers and boots | a faded gold diamond on the near shoulder |
| 2. Leather jacket | cropped black leather jacket over a long faded red shirt, rolled jeans, heavy boots, a bandana on the arm, cropped hair, a brow scar | a painted rust-red broken circle on the chest |
| 3. Vest merc | canvas utility vest over a dusty shirt with rolled sleeves, forearm wraps, cargo pants, a long braid | a stitched teal fish hook on the vest |

Drawn at 2x (a 70 × 70 frame, the figure 56 px tall), with a true-size copy under each. **Traced over heromedel's
45° render** (`reference/`: his camera-angle sheet and the 45° standing frame cut from it), so the angle and
proportions come from the model, not guesswork: the render is scaled to the frame and mirrored so the light comes
from the upper left; its outline gives the silhouette, and its smoothed lightness gives each region's shading (three
tones per material, warmer in the light, cooler in the shade). Coats, vests and the shirt tail are painted over it as
cloth panels; the heads are drawn by hand, a little larger than the model's (sprites exaggerate the head).
`review/gatos-crew-round4-stages.png` shows the stages: silhouette, flat colours, shading, highlights and outline,
details.

**Round 4 (heromedel: round 2's faces, with cleaner lines and better shading):** round 2's heads back; stray
single pixels in the shading cleaned up; arms and legs shaded as cylinders (base, with the far third in shade), so
the render's texture no longer shows as blotches; a lit left edge on each body part; a darker line where an arm meets
the body or one leg meets the other.

**Round 3, rejected (heromedel: worse; the square faces were worse)** (less derpy, a clean style with strong features, e.g. Batman: The Animated Series):** square,
angular heads with heavy flat shadow shapes, separate dark brows over the eyes instead of dot eyes, no drawn mouth
beyond a shadow, square jaws; the body shading flattened to one shadow shape and the base, with highlights only on lit
edges. Round 2 (the round, blobby faces and noisy shading) is in git history.

Round 1 (turned figures, which distorted the heads and feet) and the earlier spacemen concepts are in git history.

Built by `tools/show.py OUT.svg` and `tools/stages.py OUT.svg` (the outfits are in `tools/crews.py`).
