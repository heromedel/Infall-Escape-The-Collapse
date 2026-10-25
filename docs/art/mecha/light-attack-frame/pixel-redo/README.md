# Mecha Light Attack Frame, pixel redo (work in progress)

**Date:** 2026-10-25
**Status:** **accepted by Ship Designs (2026-10-25): the current Mecha Light Attack Frame.** The battle-cross hull,
floor plans, weapons and armed previews in `battle-cross/` and `weapons/` replace the vector frame in `../` and the
vector weapons in `docs/art/weapons/ds-st-hull-laser/` and `battlesuit-laser/` (kept for the record). Versions A and B
and the speckled rounds below are the history.

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

## Battle cross (2026-10-25): the Mecha hull style reference

heromedel re-planned the rooms first: the **battle cross** (5 rooms, 20 tiles: a command deck with Piloting, Shields
and Doors at the bow; the Servicing Core at the heart; a weapon bay on each flank, the port one spare for a second
weapon or dock; Engines and Life Support sharing the stern room). `battle-cross/` is the B style rebuilt around it at
340 × 300, one hull for both loadouts. The six mounts are hidden data, with no hardpoint drawn on any of them (the
weapon art marks its own mount). They follow FTL's mount data (checked in its layout files): each sits on the hull's
outer edge, on the front profile so nothing of the ship is ahead of it, and stores its slide direction (`data-slide`):
1–2 on the horn tips and 3–4 on the big blades' forward edges, sliding up (forward); 5–6 on the blades' outermost
flanks, sliding outward. Odd numbers port, even starboard. Mount 4, level with the starboard weapon bay, takes the
Hull Laser. The build checks the line ahead of each slid-out weapon is clear. No launch
opening is drawn for the Suit Dock.

**Sleek finish (heromedel: saved as the starting point to compare future Mecha hulls against).** The speckled grit,
seams, machinery blocks and conduit glints read as damage, so the surface was redone sleek: near-black metal (the main
tone is the Mecha palette's shadow grey `#1c1d24`) shaded in crisp bands, a bright highlight along each blade's ridge
falling off in steps, a dark crease and a faint reflected band below it, thin rim light on edges facing the upper-left
light, short clean shadows under overlapping plates, and the spine shaded like a polished column. The big blades' light
band is slimmed so their lights sit on dark metal; the rear highlights are thinner than the front ones. Purple stays in
the light rows, the spine slit, the bow slit (one band across the prow's centre line, on purpose) and four rear vents,
staggered along the engine block's dark band. Every light and vent has at least 2 px of one even shade around it
(art rules: detail passes; the build checks it). Built by `tools/hull_bc_sleek.py OUT_DIR`; `tools/hull_l1.py` keeps
the earlier speckled version. `review-sheet.png` shows the rooms and the planned mounts.

Future Mecha hulls are compared against this one, but different ship styles should still look different, as not
every Terran ship is a rocket or a shuttle.

## Floor plans, weapons and loadouts (2026-10-25)

- **Floor plans** (`battle-cross/floor-plans/`, built by `tools/floor_bc.py`): a floor layer and a plan on the hull for
  each loadout, in the Mecha pixel style: a light deck so the dark crew read clearly, dark walls with a lit rim, steel
  door slabs, airlocks only in the floor plan (two, in the spare bay, never marked on the hull). Consoles are the
  Mecha tower (no ports) turned to face their wall, with the system symbol upright in Mecha power purple: Piloting and
  Shields on the command deck's front wall, Doors on its side, the weapon pod (Hull Laser) or EVB Dock console (Suit
  Dock) on the weapon bay's outer wall. The Servicing Core's cradle (two tiles against the core room's south wall) and
  the Suit Dock's launch clamp are big machines crew walk over. No conduits: every system carries its own power. The
  build checks every room sits under the hull, no console stands on a door tile, one console per tile, every door
  joins two rooms and every airlock opens to space.
  - **Two frames (Ship Designs, agreed with heromedel), same hull art, both loadouts** (`frames.png`):
    - **Standard** (`plan-standard-*`): the stern split into two 2 × 1 rooms with a door between, Engines in the
      port room and Life Support in the starboard room. The Core's door opens into the engine room.
    - **Open stern** (`plan-open-stern-*`), the alternate, more vulnerable frame: Engines and Life Support share one
      4 × 1 stern room (4 tiles so its two consoles and its door each get a tile), so a fire or breach there hits both.
  - The hull's shadowed body was widened a few pixels to cover the 4-tile-wide stern.
- **Weapons** (`weapons/`, built by `tools/weapons_px.py`), in the hull's sleek banded metal, purple only at the
  emitters: the **DS-ST Hull Laser** (a squat housing and two heavy barrels, one per shot) and the **laser
  battlesuit** (heromedel's HalfMech crew sprite with a laser on its right arm; its jump pack is on its back, out of
  sight from above). They replace the vector weapons in `docs/art/weapons/` (accepted).
- **Armed previews** (`battle-cross/mecha-bc-armed-*.png`, standard frame; overview in `battle-cross/loadouts.png`): the Hull Laser
  at mount 4, slid out from under the blade's edge (only the part past the edge shows, as when it slides out); the
  Suit Dock shown with its battlesuit just launched, off the starboard bow. The two loadouts look different.

## Next

Done: accepted by Ship Designs on 2026-10-25. Ship-design note from Ship Designs: Life Support shares the stern room
with Engines, so a fire or breach there hits both (a readable weak point).
