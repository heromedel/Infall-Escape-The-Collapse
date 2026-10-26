# SC-1 "Outrider" hull

**Date:** 2026-10-23
**Status:** accepted by Ship Designs (version 1). Ship design: `docs/ship-suggestions.md`, the Outrider section
(the player's first ship, a doing-well Terran light battle scout).

## What it is

Hull art only: no floor art and no weapons. Top-down with the nose up, light from the upper left, 460 × 740.

- **Weapon mounts** are invisible spots, as in FTL, where weapons are separate art drawn by the game. They sit in the
  SVG as a hidden group, `weapon-mounts`, with one point per mount naming its weapon (if fitted) and slide direction.
  Six planned mounts (2026-10-26, art rules), each on the outer edge with a clear line forward
  (`outrider-hull-mounts-preview.png`); odd port, even starboard:
  - 1–2 on the nose flanks, free.
  - 3: Gat 3.1 "Triblast" on the port shoulder, sliding left.
  - 4: Gat M1 "Pathfinder" on the starboard shoulder, sliding right.
  - 5–6 on the wingtips, free.
- **Parts** are named groups (`hull`, `wing-port`, `azc`, `cockpit`, `sensor-array`, `engine-centre`, …),
  so the game can recolour, hide or animate them.

## Based on

| Source | Point | Tag |
|---|---|---|
| GDD 10A | SVG art format | Decided |
| GDD 5D | Every ship has an airlock | Decided |
| CLAUDE.md | No FTL in code (SVGs and scripts count as code) | Hard Rule |
| Race profiles, Terrans 1 | Clean, soft ships when doing well; classic spaceship shapes | Proposed |
| Race profiles, Terrans 1 | White and pale grey with blue trim | Ai-Generated-Proposal |
| Ship suggestions, Outrider | Shuttle-shaped cruiser, AZC mid-ship, Sensors 2, two weapons | Ai-Generated-Proposal |
| Concerns, 2 | Silhouette must read at squad scale | Ai-Generated-Proposal |
| heromedel, 2026-10-23 | Hull only, top-down facing up, mounts are invisible spots | agreed in chat |

Filled in by me (**Ai-Generated-Proposal**): the armour shoulders on both flanks at the core.

**Wing roundel:** a blue-and-white chevron roundel on each wing. I added it, and heromedel kept it (2026-10-23).

- It is not a standard Gatos emblem. There is none, because the Gatos are an alliance, not a federation (race
  profiles, Terrans 1; Decided).
- **Proposed (2026-10-23):** the roundel is used by some doing-well Gatos vessels: perhaps light vessels, scouts,
  ships not at war, or forward vessels (`docs/ideas.md`).
- **Proposed (2026-10-23):** Gatos regions have slightly different colour schemes and emblems (`docs/ideas.md`).
- As the Gatos fall from struggling toward doomed, their ships use darker or black colours and scarier emblems
  (race profiles, Terrans 1; Decided), so a falling Gatos ship would not carry this roundel.

## How it was made

Concepts considered: a lifting-body shuttle with swept wings (picked), a slim rocket, a body with engine pods on
pylons (too close to well-known designs), a hammerhead sensor nose, and a capsule with an armour collar (its collar
idea became the armour shoulders).

Four versions of the shuttle were drawn (the versions sheet and versions 2–4, unreviewed first
drafts, are in git history). Version 1 was picked for the cleanest silhouette and thumbnail, then reviewed six times (the passes sheet is in git history):

| Pass | Changes |
|---|---|
| 1 | Engines out of hiding on a stern block; longer swept wings; armour shoulders at the core; spine hatches. |
| 2 | Stern tucked under the body; chunkier armour; larger framed cockpit; wingtip trim; two sensor masts. |
| 3 | Trailing-edge flaps and roundels on the wings; aft portholes. |
| 4 | A light sweep across the body so it reads as rounded; bigger engine bells. |
| 5 | Smooth rear edge; portholes moved inside the hull; metal shading in the bells. |
| 6 | Wider wing-edge trim, so the blue still reads at squad zoom. |
| 7 | 2026-10-26, art rules: the side airlock hatch and the dorsal access hatches removed (no marked exterior doors; the airlocks are in the floor plan); six planned mounts on the edge. **Final.** |

Each part is built in five stages (`stages.png`): outline, fill, shade, highlight, details. `squad-test.png` shows six
copies at battle zoom, the flat silhouette, and a half-size copy.

## Room space (note for floor layout)

The raised central plate is only about 3.7 tiles wide at 30 px tiles, too narrow on its own for a Kestrel-sized room
count. Rooms should use the full body width (about 6 tiles mid-ship, 4 at the bridge). A floor mockup at that width
fitted 17 rooms.

## Files

| File | What it is |
|---|---|
| `outrider-hull.svg` | Final hull, with named parts and hidden weapon mounts |
| `outrider-hull.png`, `outrider-hull-2x.png` | PNG exports at 1× and 2×, transparent |
| `outrider-hull-mounts.svg`, `outrider-hull-mounts-preview.png` | Review copy showing the mount spots |
| `stages.png`, `squad-test.png` | Review sheets of the final hull |
| `tools/build.py` | Builds every version and stage: `python3 build.py OUT_DIR [version numbers]` (17 is the final) |
| `tools/check_mounts.py` | Checks every mount sits on the hull's edge with a clear line forward, and that there are at least 4: `python3 check_mounts.py HULL.svg ...` (used for the Outrider and the pirate dagger) |
| `tools/art_kit.py` | Shared hull drawing kit (plates, stages, mounts) |
| `tools/render.js` | SVG to PNG: `node render.js in.svg out.png [scale] [background]` |
| `tools/sheet.js` | Side-by-side review sheets |
