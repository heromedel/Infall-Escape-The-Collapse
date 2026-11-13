# GATOS Patrol Cutter hull

**Date:** 2026-11-13
**Status:** draft for heromedel's review, not yet sent to Ship Designs. The ship comes from the Godot version
(`infall-godot/content/ships/patrol-cutter/ship.xml` on `Cloud-C-Godot-Version`), which has no hull art for it; the
Checkpoint loadout (`loadout.patrol-cutter.checkpoint.xml`) uses the same hull.

![At the Outrider's scale, at battle zoom, as a silhouette and at half size](review/scale-and-squad.png)

## What it is

A tidy doing-fine GATOS patrol cutter: white and pale grey with blue trim, the armoured housing over the AZC
(race profiles, Terrans 1). Hull only, top-down, nose up, light from the upper left, 300 × 480 at 1x (35 px tiles, the
centre of tile (0, 0) at 150, 240). A classic spaceship, not a rocket: a chined bow, swept side sponsons, engines set
flush into a squared stern, no nose cone, fins or engine bells.

- **Rooms first:** the 9 rooms of the ship file are laid out on the tile grid (`tools/layout.py`) and the hull is drawn
  round them; `tools/check_rooms.py` checks every room has at least 4 px of hull round it
  (`review/rooms-and-mounts.png`).
- **Six mounts** in the hidden `weapon-mounts` group, each on the outer edge with a clear line forward
  (`check_mounts.py`), odd port, even starboard: 1–2 on the bow chines (up), 3–4 on the sponsons' swept leading edges
  (left, right: the Gat 2.1 at 3, the Gat M1 at 4; the Checkpoint fits the Gat 3.1 and the Gat M2 there), 5–6 on
  the sponsons' outer flanks (left, right).
- **Parts:** `hull`, `sponson-port`, `sponson-starboard`, `spine`, `cockpit`, `azc`, `engines`.

For the Godot ship file (art pixels on the 1x hull):

```xml
<art hull="patrol-cutter-hull-2x.png" scale="0.5" center="150,240"/>
<mount id="1" x="122" y="36" slide="up"/>
<mount id="2" x="178" y="36" slide="up"/>
<mount id="3" x="63" y="136" slide="left"/>
<mount id="4" x="237" y="136" slide="right"/>
<mount id="5" x="45" y="250" slide="left"/>
<mount id="6" x="255" y="250" slide="right"/>
```

## How it was made (`docs/art/ship-art-process.md`)

Concepts (`review/concepts.png`), all drawn round the rooms: A, a chined wedge; B, sponsons on struts; C, a rounded
cutter; D, a sensor-bar bow; E, a swept cutter. A, C and D read as a blocky plus sign; E was picked, its sponsons swept
back, its corners softened.

| Pass | Changes |
|---|---|
| 1 | The sponsons as raised plates of their own; a narrower spine; an engine block; mounts 3–4 onto the true edge. |
| 2 | The sponsons out to the hull's edge (they floated inside a white rim). |
| 3 | The GATOS blue double stripe across the spine under the canopy, as on the Outrider. |
| 4 | Up to the Outrider's polish: a bigger armoured AZC housing with an inner ring and bolts, spine seams, larger nozzles. |
| 5 | Blind check, 6/10, "a utility shuttle, not a fast cutter": a longer chined bow; the engines set into the stern (the block read as bolted on); the dial sensor dropped (read as a clock). |
| 6 | Blind check, 6/10: a narrower bow tip; no dome, pod slots or portholes (read as a button, handles and stitching); bigger nozzles. Sponsons tapered into swept tips were tried and dropped: they read as rocket boosters. |

Each part is built in the five stages (`review/stages.png`). Still flagged by the blind checks: the AZC housing sits
alone mid-spine, and the hull is plainer than the Outrider. The Gat M1 has no weapon art yet, so there is no armed
preview.

## Files

| File | What it is |
|---|---|
| `patrol-cutter-hull.svg` | The hull, with named parts and hidden mounts |
| `patrol-cutter-hull.png`, `-2x.png` | PNG exports at 1x and 2x, transparent |
| `patrol-cutter-hull-mounts.svg` | Review copy showing the mount spots |
| `tools/build.py` | Builds the hull and its stages: `python3 build.py OUT_DIR` |
| `tools/layout.py`, `tools/check_rooms.py` | The rooms on the pixel grid, and the room-margin check |
| `tools/concepts.py` | The concept silhouettes |
