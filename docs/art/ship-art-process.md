# Ship art process

**Date:** 2026-11-13
How the art session makes a ship's art (hull, weapons, floor plan, conduits), written from what worked on the ships
Ship Designs accepted (the Outrider, the Pirate Hijacker, the Tentauri scout and the Mecha battle cross) and from
heromedel's corrections along the way. The rules themselves live in `README.md` (art rules), `style-guides.md` and
`palette.md`; this page is the order of work. Tags follow `docs/tag-styles.md`; the steps are an
**Ai-Generated-Proposal** unless a point says otherwise.

## Who asks and where it goes

- **Decided (2026-10-23, heromedel):** Production decides which pieces are needed, Ship Designs finalizes the ship and
  asks for its art, and the art session sends one or more pieces back without asking heromedel first, then reports
  to him. Art for another session is committed only once it is accepted.
- **Decided (2026-10-23):** commit locally and push only when heromedel says so.

## 1. Read before drawing

1. The ship's design in `docs/ship-suggestions.md`: race, band, state (doing fine, struggling, doomed), function,
   systems and levels, crew, loadouts, weapons, mount count.
2. The race's profile (`docs/race-profiles.md`, point 1: tone, silhouette, colours) and its section of
   `style-guides.md`. The race's power colour from `palette.md`.
3. The art rules in `README.md`, the art review checks (`docs/art-review-checks.md`) and the GDD's layout rules
   (5A–5L).
4. The race's accepted ships and crew, to match them, and FTL's ships of the same kind as a reference for scale and
   tone only (nothing copied; FTL is never named in code or SVGs).
5. Anything unclear about the ship's purpose (player, enemy, either) is asked of Ship Designs or Production, not
   heromedel.

## 2. Rooms first, then the hull

- **Decided (2026-10-25, heromedel):** count the rooms the loadouts need (systems may share a room; one hull can
  serve several loadouts), add a few spare (none for the Tentauri), lay them out on the tile grid, then shape the hull
  around them with a margin. A hull drawn first and filled later came out too narrow (the Outrider's plate fit 3.7
  tiles).
- Lay out the rooms like the reference ships: compact, no storage rooms, no marked spare areas, airlocks, one tile
  per system, no console on a door tile, EVA and EVB Docks beside an airlock.
- Plan the weapon mounts with the rooms: at least 4–6, on the outer edge, on the front profile or an outer flank with
  a clear line forward, each with its slide direction.

## 3. Concepts, versions, passes (the 3-6 rule)

- **Concepts:** list 3–6 silhouettes for the ship's function and race, and say in one line why each is kept or
  dropped (the Outrider: lifting-body shuttle picked; slim rocket, pods on pylons, hammerhead and capsule dropped;
  the pirate: chined dagger picked; twin-boom busy, hammerhead alien, pincer cheesy, box freighter no threat).
- **Versions:** draw 3–6 versions of the best concept and pick by the silhouette and the thumbnail at squad zoom.
- **Passes:** improve the pick 3–6 times, logging each pass in the README (what changed). Then the detail passes
  (art rules): check every light, vent, highlight and mount against what is around it, with 1–2 px of plain surface
  around lights and vents.
- Then compare the result with the ship's design, the race and the lore: does it fit? If not, go back.

## 4. Building the hull

- **Vector races** (GATOS, Tentauri): `docs/art/tools/art_kit.py`. A hull is a list of named plates drawn back to
  front, each built in the five stages (outline, fill, shade, highlight, details), lit from the upper left, nose up.
  Plates and parts are named groups so the game can recolour, hide or animate them. Mounts are hidden points
  (`Hull.mount`) in the `weapon-mounts` group.
- **The Mecha:** pixel art, drawn pixel by pixel in the Mecha palette, written as compact SVG
  (`pixel_svg.py`); the battle cross is the reference.
- One build script per ship (`tools/` beside the art), which writes the final SVG, a mounts review copy, the five
  stage SVGs and PNG exports, so every version can be rebuilt and every stage shown.

## 5. Weapons, previews and checks

- Weapons are separate art (`docs/art/weapons/`). Previews place the weapon files at the mounts, slid out in their
  slide direction and drawn under the hull, so only what passes the edge shows. A stolen or foreign weapon is refitted
  properly, never clamped on. Loadouts of one hull must look visibly different.
- `python3 docs/art/tools/check_mounts.py HULL.svg`: every mount on the edge with a clear line ahead, at least 4.
- Review sheets (`sheet.js`): the stages; the hull alone and with its floor plan, side by side; several copies at
  battle zoom, the flat silhouette and a half-size copy (squad test); beside the race's other ships for scale.

## 6. Floor plan and conduits

- A floor layer on its own, the plan on the hull, and (for conduit races) the conduits on their own layer, exported
  as a separate file. The build checks what it can: one tile per system, no console on a door tile, docks beside an
  airlock, every system and hardpoint traced back to the power core, single points of failure listed in the README.
- Consoles sit against their wall, at most half a tile deep, so crew type on their tile; big non-controlled machines
  may look blocking but are walkable. Symbols: power green on player ships, the race's power colour when fighting the
  player, never red.
- Finished plans show the ship intact and powered. Damage and other demonstrations go in a labelled mockup.

## 7. Sending and recording

- Send Ship Designs the hull, the mounts review copy, the armed previews and the floor plans; save to the repo only
  once it accepts. The piece's README records: what it is, what it is based on (the sources and their tags, and what
  was filled in), the concepts, versions and passes, the files, and each acceptance.
- When heromedel asks for a change, make exactly that change and nothing else, then show it. Unasked changes between
  rounds lost good work on the Mecha suits and hulls more than once.

## Mistakes that made these rules

- The first pirate hull: cluttered, rust that dripped, a cat-skull emblem, a fanged maw, a stolen weapon clamped on,
  and two loadouts that looked the same ("hideous... cheesy compared to FTL").
- Mounts placed deep on the hull, though FTL weapons slide out past the edge.
- Bright airlock hatches and docking frames on hulls; systems on two tiles; consoles blocking tiles.
- A Mecha deck drawn as a boxy "steam deck" with caution stripes; Mecha suits redrawn from scratch as cute robots
  instead of changing the reference step by step.
- Hulls drawn before their rooms were known.
