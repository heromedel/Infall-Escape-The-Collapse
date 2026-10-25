# Mecha Light Attack Frame, pixel redo (work in progress)

**Date:** 2026-10-25
**Status:** work in progress, saved at heromedel's request. Two versions of the new hull, A and B; not yet picked,
not yet sent to Ship Designs. The accepted vector frame in `../` stays the current design until this replaces it.

![Version A and B](review/mount-plan.png)

## What it is

A new start on the Mecha frame in the Mecha style (`docs/art/README.md`): pixel art drawn pixel by pixel on the hull's
440 × 330 grid, in the Mecha palette (`docs/art/palette.md`), with purple only in the light slits.

- **Inspiration:** the design language of FTL's Lanius ships (big overlapping plates, hooked and pointed tips, dark
  machinery between the plates, rows of glowing slits). Nothing is copied or recoloured from them: the shapes are
  drawn new, around this ship's own rooms.
- **Matched to the Mecha console** (`../../console/`): the spine is drawn like the console's tower (a narrow dark
  column, a recessed screen, purple slits), the plates have stepped notches like its cheeks, and the shading is the
  same per-pixel method (outline, lit upper-left edges, gritty shade variation).
- **No caution stripes and no boxy panelled deck**, as heromedel asked.
- **Shape (heromedel's pick of the blade rounds):** forward horns framing a pointed armoured prow, two big cleaver
  blades each side raked aft, each split by a ridge into a lit and a dark facet, and an engine block at the stern
  with four purple vents. B has a longer prow and horns and blades raked further aft.
- **Rooms:** the same room plan as the accepted frame (`../tools/rooms.py`); the build checks every room sits under
  the hull with a 5 px margin.

## Weapon mounts

Six planned mounts on each version (art rules: plan for at least 4–6), stored as invisible spots in the SVG
(`mount-1` to `mount-6`), plus the Suit Dock's bay mouth (`suit-bay`):

| Mount | Where | Use |
|---|---|---|
| 1, 2 | horn roots, firing forward | 2 (starboard) takes the DS-ST Hull Laser in the Hull Laser loadout |
| 3, 4 | the big blades' leading edges, out wide | free for later loadouts |
| 5, 6 | the aft blades' roots | free for later loadouts |
| suit bay | outboard under the starboard blade, over the weapon bay | the Suit Dock loadout's launch bay |

## Files

| File | What |
|---|---|
| `mecha-px-hull-a.*`, `mecha-px-hull-b.*` | The two versions: SVG (pixels as rects, mounts hidden), PNG at 1x and 2x |
| `review/mount-plan.png` | Both versions with the planned mounts marked |
| `review/first-plates.png`, `review/blades.png` | Earlier rounds: curved plates (read as tentacles), then faceted blades |
| `tools/hull_px.py` | Builds A and B: `python3 hull_px.py OUT_DIR` (writes s1 = A, s2 = B, with mount-plan and room overlays) |
| `tools/pixel_kit.py`, `tools/cleavers.py` | The shared pixel shading and earlier versions, kept for the record |

## Next

Pick A or B, then: draw the hardpoint at mount 2 and the suit bay for the two loadouts, refine the plates (sharper
tips, light slits instead of dots), and redo the interior with the tower console.
