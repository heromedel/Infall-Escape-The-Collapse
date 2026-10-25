# Mecha console

**Date:** 2026-10-25
**Status:** picked by heromedel (the tower with ports, stepped cheeks). Not yet used in a floor plan: the Mecha Light
Attack Frame's plans will take it when the frame is redone in the Mecha pixel style.

![The console at 8x](mecha-console-tower-8x.png)

A Mecha system console for one 35 × 35 tile, drawn in the Mecha style (`docs/art/README.md`, race rendering styles):
pixel art on the grid, near-black armour from the Mecha palette with a gritty, uneven texture, and purple hinted in a
pixel or two (the port rims and a slit at the base). A narrow armoured tower with the screen and the system's symbol
(in power green on the screen), between two heavy stepped cheeks.

- **Ports:** two sockets where the HalfMech's hands land when it types at the console (tile pixels x 9 and 26,
  y 3–4, for a console on the north wall). In the power-pulse typing frame (`docs/art/mecha/crew/`, rows 15–16) the
  pulse turns power green right in the ports.
- **Side walls:** the side typing frames put the hands at (25, 16) and (23, 21–22) for an east wall (mirrored for
  west), not where a turned console's ports would be, so a side-wall console needs its own port layout.
- **How it was picked:** three console shapes (slab, tower, low bar), each with and without ports, shown with the
  typing frame over them (`console-options.png`); heromedel picked the tower with ports, made more pixelated and
  menacing. Three cheek shapes in pixel art (`tower-options.png`): blade, stepped (picked) and claw.

## Tools

| File | What it does |
|---|---|
| `tools/consoles.py` | The first console shapes, with and without ports: `python3 consoles.py ../../crew/mecha-crew-sheet.svg OUT.svg` |
| `tools/tower_px.py` | The pixel tower in three cheek shapes, with the typing frame over each: `python3 tower_px.py ../../crew/mecha-crew-sheet.svg OUT.svg` (writes `tower-*.svg` beside it) |
