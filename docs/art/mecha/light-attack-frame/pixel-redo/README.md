# Mecha Light Attack Frame, pixel redo (work in progress)

**Date:** 2026-10-25
**Status:** work in progress, saved at heromedel's request. heromedel picked **B** (2026-10-25); A is kept for the
record. Not yet sent to Ship Designs. The accepted vector frame in `../` stays the current design until this replaces it.

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
| `mecha-px-hull-laser.*` | B, Hull Laser loadout: a raised octagonal hardpoint at mount 2 (the laser itself is separate art) |
| `mecha-px-suit-dock.*` | B, Suit Dock loadout: the recessed launch bay with purple guide lights and a launch rail |
| `review/mount-plan.png` | Both versions with the planned mounts marked |
| `review/first-plates.png`, `review/blades.png` | Earlier rounds: curved plates (read as tentacles), then faceted blades |
| `tools/hull_px.py` | Builds A and B: `python3 hull_px.py OUT_DIR` (writes s1 = A, s2 = B, with mount-plan and room overlays, and B's two loadouts) |
| `tools/pixel_kit.py`, `tools/cleavers.py` | The shared pixel shading and earlier versions, kept for the record |

## Battle cross (2026-10-25, awaiting heromedel's review)

heromedel re-planned the rooms first: the **battle cross** (5 rooms, 20 tiles: a command deck with Piloting, Shields
and Doors at the bow; the Servicing Core at the heart; a weapon bay on each flank, the port one spare for a second
weapon or dock; Engines and Life Support sharing the stern room). `battle-cross/` is the B style rebuilt around it at
340 × 300, one hull for both loadouts. The six mounts are hidden data, with no hardpoint drawn on any of them (the
weapon art marks its own mount); mount 4 sits over the starboard weapon bay and takes the Hull Laser. No launch
opening is drawn for the Suit Dock. Built by `tools/hull_l1.py OUT_DIR`. `review-sheet.png` shows the rooms and the
planned mounts.

## Next

Refine B's plates if heromedel wants (sharper tips, light slits instead of dots), then redo the interior with the
tower console, and the weapons in the pixel style.
