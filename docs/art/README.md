# Infall art

Art for Infall, made by the art session (Infall: Arty). One folder per piece, by race: `docs/art/<race>/<piece>/`,
each with its SVG, PNG exports, review sheets, build tools and a notes README.

## Art rules from heromedel

| Date | Rule |
|---|---|
| 2026-10-19 | Art is SVG (GDD 10A), built in stages: outline, fill, shade, highlight, details; then reviewed and changed at least 3–6 times, and exported as PNG. |
| 2026-10-23 | Follow the Creative 3-6 Rule (CLAUDE.md): 3–6 ideas, the best made 3–6 ways, then 3–6 rounds of improvement, then checked against the design and lore. |
| 2026-10-23 | SVGs and the scripts that build them are code: FTL is never mentioned in them (CLAUDE.md hard rule). Notes READMEs are docs and may mention FTL. |
| 2026-10-23 | Ship hulls are top-down with the nose facing up. |
| 2026-10-23 | Hull art only, until floor art is asked for. |
| 2026-10-23 | Weapon mounts are invisible spots on the hull, stored as data; weapons are separate art. |
| 2026-10-23 | Art for another session (e.g. Ship Designs) is sent to that session first and committed only once it is accepted. |
| 2026-10-23 | Floor layouts follow FTL's layouts, except that a room can hold more than one system and rooms can be bigger than 2×2 or as small as 1×1. No marked spare areas: leave blank rooms. No storage rooms. Every ship has airlocks (doors to space). |
| 2026-10-23 | No system console on a door tile, unless it is a small room with a passable system (such as a backup battery), not a controlled system. |
| 2026-10-23 | Power conduit paths are kept on their own layer and exported as a separate file from the floor layout. |
| 2026-10-23 | FTL is the bar for tone: clean, restrained and readable, never cheesy or cluttered. Show character through colours and shapes, at the Outrider's level of polish. |
| 2026-10-23 | Nothing drips in space: no rust streaks or drips. Show wear sparingly, as scorching, pitting, faded or patchy paint, and a few replaced plates of a different shade. |
| 2026-10-23 | The Gatos are human; the cat pun is only in their name. No cat motifs on their ships. |
| 2026-10-23 | Stolen or foreign weapons look properly fitted on a real hardpoint, refitted into the hull, not clamped on. |
| 2026-10-23 | Weapons are separate art, but ship previews and squad views show them mounted. Loadouts of one hull must look visibly different. |
| 2026-10-23 | Conduit check, run before sending any conduit ship: every installed system's room is on the network and traces back to the AZC, and every single point of failure is listed in the piece's README (only intended weak points, such as a single spur, may remain). The floor plan tools fail the build otherwise. Every weapon hardpoint has a run back to the AZC too: whether mounts need power is **Open** (race profiles, Terrans 6), but heromedel asked to work as if they do. |
| 2026-10-23 | Actual plans and finished art show the real thing only: intact, powered, as designed. Never demonstrate an idea, a mechanic or damage in them. An experimental idea or a demonstration (a cut conduit, a GDD 14C flash, a damage state, an alternative) goes in a separate mockup file, clearly labelled as a mockup. |
| 2026-10-23 | Console symbols are not red, since red means a cut-off system (GDD 14C). |
| 2026-10-23 | Plan rooms first: count the rooms a ship needs (plus a few spare for most races; the Tentauri need none), lay them out, then size and shape the hull around them with a margin. |
| 2026-10-25 | Shared colours come from the palette (`palette.md`, values in `palette.py` for the tools). Power green `#66FF66` is for every powered system, powered power bar, and the symbol on an intact player system. |
| 2026-10-25 | **Proposed:** each race has its own rendering style, not just its own shapes. **Gatos** (especially doing well): clean vector, crisp edges, polished plates, tidy clean tech. **Tentauri:** soft, comfy and pillowy: rounded inflated forms, pastel mother-of-pearl, organic consoles, a gentle glow. **Mecha:** low-res SNES-style pixel art built pixel by pixel on the grid, near-black with one purple accent, a gritty, uneven pixel texture (not clean), detail only hinted (see `mecha/crew/`). |
| 2026-10-23 | No rocket-like Terran designs for a while: no pointed nose cone, tail fins and engine-bell silhouette. Terran ships look built for deep space, not for launching from a planet (race profiles, Terrans 1, Likely). |

## Pieces

| Piece | Status |
|---|---|
| [`terran/outrider/`](terran/outrider/) | SC-1 Outrider hull: accepted by Ship Designs. Floor layout tests 1–4 in `floor-layout-tests/`. |
| [`terran/pirate-hijacker/`](terran/pirate-hijacker/) | Terran Pirate Hijacker hull, Hijacker and Cutpurse loadouts, squad view and floor plans: accepted by Ship Designs. |
| [`tentauri/scout/`](tentauri/scout/) | Tentauri scout hull, armed preview and floor plan with organic consoles: accepted by Ship Designs. |
| [`mecha/light-attack-frame/`](mecha/light-attack-frame/) | Mecha Light Attack Frame hull, Hull Laser and Suit Dock loadouts, armed preview and floor plans: accepted by Ship Designs. |
| [`mecha/console/`](mecha/console/) | The Mecha system console (pixel tower with ports, stepped cheeks), picked by heromedel. |
| [`mecha/crew/`](mecha/crew/) | heromedel's Mecha crew sprite sheet (16 rows, with power-pulse typing), saved as the crew reference. |
| [`weapons/`](weapons/) | Sporewing, Gat 2.1 "Twinshot", Tentauri Defense Laser, DS-ST Hull Laser and laser battlesuit art. |
| [`mockups/`](mockups/) | Labelled mockups of ideas, not finished art: system symbol colours. |
