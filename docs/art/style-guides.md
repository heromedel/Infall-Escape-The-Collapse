# Infall art style guides

**Date:** 2026-10-25
How each race and its ships look, drawn from the art heromedel has approved. Where this guide and an older
suggestion disagree (race profiles, ship suggestions, earlier art notes), **this guide wins**: the older Mecha
suggestions in particular (gunmetal with yellow and orange hazard markings, stencils, bolts, industrial plating) are
replaced. Tags follow `docs/tag-styles.md`. The general art rules stay in `README.md`; the colours in `palette.md`.

## Mecha ships

Reference: the sleek battle-cross frame, `mecha/light-attack-frame/pixel-redo/battle-cross/` (built by
`tools/hull_bc_sleek.py`).

- **Not wanted — Decided (2026-10-25, heromedel):** no hazard or caution stripes, no yellow or orange markings, no
  stencilled codes, stickers or emblems, no bolts, rivets or panel seams, no industrial plating and no square, boxy
  panelled "steam deck" look. Wear and grit that read as damage are not wanted either.
- **No marked exterior doors — Decided (2026-10-25, heromedel):** no airlock hatches, docking frames or launch bays
  drawn brightly on the hull. The hull may imply an opening by its shapes, but never marks exactly where a door is.
  (Airlocks still exist in the floor plan, art rules.)
- **Finish — Likely (2026-10-25):** dark, sleek, metallic and threatening. Near-black metal shaded in crisp bands: a
  bright highlight along each plate's ridge falling off in steps, a dark crease below it and a faint reflected band,
  a thin rim of light on edges facing the light (light comes from the upper left), short clean shadows under
  overlapping plates. The main tone is the Mecha palette's shadow grey (`#1C1D24`); the hull ramp is in `palette.md`.
  Front highlights may be fuller; rear highlights are thinner.
- **Lights — Likely (2026-10-25):** Mecha power purple (`#AA28EB`, pale core `#EBE1FA`, deep glow `#5A128C`) is the
  only colour on the hull: rows of short light slits along the plates, a slit on the spine, a bow band and rear vents.
  Every light sits on one even tone with at least 2 px of plain metal around it (art rules: detail passes).
- **Shape language — Likely (2026-10-25):** inspired by the design language of FTL's Lanius ships (nothing copied):
  big overlapping blade plates with straight edges and sharp, angled points, each split by a ridge into a lit and a
  dark facet; stepped notches cut into the plates, like the Mecha console's cheeks; a narrow spine drawn like the
  console's tower; an engine block at the stern. Curved bands read as tentacles and are avoided. No rocket shapes.
- **Variety — Likely (2026-10-25):** future Mecha hulls are compared against the reference, but different ship
  styles should look different, as not every Terran ship is a rocket or a shuttle. The reference reads a little like
  a stealth jet; heavier, more armoured mech-warship shapes are a valid direction for other hulls.
- **Built for the job — Decided (2026-10-25, heromedel):** rooms first, sized for what the loadouts need (systems may
  share rooms); then the hull around them (art rules).
- **Mounts — Likely (2026-10-25):** at least 4–6 planned per hull, on the outer edge with a clear line forward, each
  with its slide direction (art rules).
- **Symbols on an enemy Mecha ship — Decided (2026-10-25):** Mecha power purple (`palette.md`).

## Mecha consoles and interiors

- **Console — Decided (2026-10-25, heromedel's pick):** the pixel tower with stepped cheeks, without arm ports
  (`mecha/console/`). Turned to face its wall; crew stand and type on its own tile (art rules).
- **Big machines — Decided (2026-10-25):** the Cybernetic Servicing Core may look big and blocking, but crew walk
  over its tile.
- **Servicing Core — Decided (2026-10-26, heromedel's pick):** a stepped wall panel with a console-style screen
  holding the medbay symbol, two tapered servicing arms hanging either side, and a tall stand table with four small
  flared shoulders, each with a purple light; a purple light inside each arm near its foot (`mecha/servicing-core/`).
  Unlike other systems it always faces up and is never turned.
- **One tile per system — Decided (2026-10-26, heromedel):** no system takes more than one tile.
- **EVB Dock — Decided (2026-10-26, heromedel):** any EVA or EVB Dock must be next to an airlock door.
- **Floors and walls — Open:** the pixel-style floor is not drawn yet (a light deck read best in a first test, so the
  dark crew stand out).

## HalfMechs in their suits (crew)

Reference: heromedel's sheet, `mecha/crew/`.

- **Look — Decided (2026-10-25, heromedel's sheet):** low-res pixel art at true crew size, a Gundam-like mech
  silhouette (crest head, blade forearms, short legs), near-black armour from the Mecha palette with one accent, the
  purple (visor bar, chest lights). At sprite size the texture is gritty and broken up, and detail is hinted by a pixel
  or two. Menace comes from the silhouette and the dark palette, not from faces, eyes, grilles or bolts.
- **Powering a system — Decided (2026-10-25):** the power-pulse typing rows: a pulse runs from the HalfMech into the
  console, purple turning power green as it arrives.

## HalfMech people (out of their suits)

Reference: heromedel's art, `mecha/pilot/`. There are no current plans to show HalfMechs out of their suits.

- **Look — Proposed (2026-10-25, heromedel's art):** a petite pilot, about half an FTL human's size (9 px wide, 13 px
  tall), pale skin, dark purple hair, purple eyes, and purple implant lights on the left shoulder and the back of the
  head. Black clothing, bare limbs, single-pixel hands and feet. Female and male base designs.

## Tentauri ships

Reference: the Tentauri scout, `tentauri/scout/`.

- **Finish — Proposed (2026-10-25):** soft, comfy and pillowy: rounded, inflated forms in pastel mother-of-pearl
  (pale aqua, teal, coral white and pink), a gentle glow, clean vector art. Compact, like a tiny shuttle (race
  profiles).
- **Consoles — Decided (2026-10-25):** organic bases, one per system, shaped by what it does, with the standard system
  symbol lit in a dark bulb. Half size, upright, slid against their wall so crew use them from the same tile, never
  turned or mirrored for the wall.
- **Weapons — Likely (2026-10-25):** the Defense Laser's segmented style (accepted by Ship Designs), mounted on the
  hull's edge.
- **Power colour — Open:** a Tentauri power pink (`#FF5ECA`, "bubblegum matched") was liked but is not yet saved.

## Tentauri crew

Reference: heromedel's sheet, `tentauri/crew/`.

- **Look — Decided (2026-10-25, heromedel's sheet):** a soft jellyfish from above: a rounded teal bell with a light
  highlight and a dark outline, two dot eyes, a pink rim at the base, and lavender tentacles. The tentacles are thin,
  wavy lines (one pixel, plus a shade pixel), never wedges or triangles. Two long tentacles always hang; the eight
  short ones type, shoot, punch and reach out to other systems in the room (the reach prototype).
- **Using a Tentauri system — Proposed (2026-10-25):** a grasping animation instead of typing (`docs/ideas.md`).
