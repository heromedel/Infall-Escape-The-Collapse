# SC-1 Outrider floor layout tests

Mockups of the Outrider's floor plan: rooms, single-tile systems, doors, airlocks and the Terran conduit ring,
drawn over the accepted hull (`../outrider-hull.svg`). Nothing here is decided. Every layout is an
**Ai-Generated-Proposal** until heromedel reviews it.

| Test | Date | What it tried |
|---|---|---|
| [test-1](test-1/) | 2026-10-23 | First mockup: 30 px tiles, 17 rooms, spare rooms marked, a bridge with three systems, conduit style comparison. |
| [test-2](test-2/) | 2026-10-23 | Simpler and closer to real FTL layouts: 35 px tiles, 10 rooms, blank empty rooms, merged rooms, airlock doors. |

## Research: FTL's real player ship layouts (2026-10-23)

Read from the vanilla game data heromedel shared (`ftl.dat`, layout `.txt` files and `blueprints.xml`; the Captain's
Edition copy was not used). The game files are not copied into this repo, only these findings.

- **Room count:** 14–20 rooms per player ship (Kestrel A: 17).
- **Room sizes:** only 2×2, 2×1 and 1×2. One system per room.
- **Grid:** 8–15 tiles long and 6–10 wide; tiles are 35 px. The Kestrel is 15 × 6, widest mid-ship.
- **Empty rooms:** 1–6 per ship (the Kestrel has 6), often small 2×1 rooms along the hull edges and the rooms that
  hold the airlocks. The blueprint also assigns rooms to systems not installed at the start (the Kestrel's drones,
  cloaking and teleporter rooms).
- **Airlocks:** not rooms. They are doors from a room to space, usually in pairs on two or three rooms, often
  mirrored on both sides (the Kestrel: two on its stern room, two on each mid-ship flank room).
- **Doors:** about 1.5 per room (the Kestrel: 20 inside, 6 airlocks).
- **Placement:** piloting in a small room at the nose, engines at the stern, the widest section mid-ship.
- **Floor art:** one flat plate a few pixels larger than the rooms, with notches at the airlocks. The game draws
  the room floors, walls, doors and system icons on top.
- **Weapons:** mounts are spots in the layout file (`x`, `y`, `rotate`, `mirror`, `gib`, `slide`); weapon art is
  separate and drawn under the hull.

## Rules heromedel gave for these tests (2026-10-23)

- More than one system can share a room. Nearby rooms can be merged, or one system moved into the other's room
  with their stations next to each other (e.g. the Kestrel A's engines and shields).
- Rooms can be bigger than 2×2 or as small as 1×1; otherwise layouts are similar to FTL.
- Piloting, Weapons and Shields are the likely systems on the bridge. Engines don't go on the bridge, and the power
  core is likely central.
- Terran conduits run across the floor to the systems and can be switched on and off or rerouted, drawn as a dark
  or glowing wire, like a train track.
- Don't mark areas for extra systems; leave blank rooms where it makes sense. No storage rooms.
- Every ship has airlocks: doors going outside the ship.
- Don't block doors with systems, unless it is a small room with a passable system, such as a backup battery, and
  not a controlled system.

## Tools

`tools/floor.py` builds test 1, and `tools/floor2.py` builds test 2. Both take the hull SVG and an output path:

    python3 tools/floor2.py ../outrider-hull.svg test-2/floor-layout-test-2.svg

`floor2.py` stops with an error if a console sits on a door tile.
