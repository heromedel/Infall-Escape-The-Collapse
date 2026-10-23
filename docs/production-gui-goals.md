# Infall: Production GUI and Asset Goals

The screens, panels and assets a working game needs, listed by the goal that first needs them (`production-goals.md`)
and the session expected to make them. Everything here is **Ai-Generated-Proposal (2026-10-23)** unless tagged
otherwise; the GUI itself is Open in the GDD (14A), so this is a list of what has to be decided and made, not how
it looks. The art session (Infall: Arty) owns art; GUI layout decisions go through heromedel with mockups (12A).

Points this list stands on: Decided 3C, 3E, 4B–4N, 10A, 12B; Likely 2D, 3A, 3H, 3J, 3O, 4A, 4O; Proposed 2E, 3B, 3I,
11A, 11B, 12A; Open 10B, 14A.

## Screens and flows

| Screen or flow | Goal | What it must do | Who |
|---|---|---|---|
| Title screen | A | New run, continue, join game, settings, quit; the game's name and a first visual identity (10B Open) | Arty for art; layout mockup |
| Host and join | A | Host a run (becomes Captain), join by direct IP (4A), lobby showing players and assignments (4C, 4D), start | Production spec; heromedel decides |
| New run | A | Pick starting race and ship (Terran only in A), difficulty later, multiplayer settings (4G: Pause Control, Turn Mode, Event Choices, Captain Transfer) | |
| Galaxy map | A | Cluster nodes drawn as dot groups (2J), links, current squad, collapse ring (2Q), cluster state marks (2R), store and distress marks within sensor range (2E), clamped zoom with a setting (2D), Jump and Wait (6B) buttons, Mawjig and squad summary | Arty: map art |
| Cluster arrival and event window | A | Event text, choices, blue options marked, votes shown per player (4M), auto-pause (4K), results | |
| Battle screen | A | Player squad bottom, enemy squad top (3A), curved formation (3H), pan and zoom camera (3C), 16:9 with GUI bands top and bottom (3J); ships at FTL room scale (3D) | Arty: ship and room art |
| Per-ship panel | A | Selecting a ship shows its systems, power or conduits, hull, crew and weapons beside it (3B); Terran conduit view and reroute; weapon targeting on any enemy ship (3L) | mockups first (12A) |
| Hail window | A | Ask or offer surrender, pay passage, other options per squad conduct (3O) | |
| Pause, vote and lock-in indicator | A | Who paused, who voted, who locked in commands (4L); turn-mode auto pause (4I) | |
| Store | A | FTL-style sections (systems, weapons, crew, repair, Mawjig can't be bought: it is the currency), stock by cluster state, race-themed texts | |
| Ship upgrade and crew screens | A | Upgrade systems and AZC or reactor, move crew, assign ships and crew to players (4C) | |
| Results and run end | A | Run lost (1F) or band 3 reached; later the escape (B) | |
| Settings | A | Multiplayer settings, map zoom, conduits toggle, controls, sound; defaults shown first | |
| Save and load | B | Resume a run; the host saves (4N) | |
| Rim and escape | B | The last clusters, the final battle, the escape sequence | Arty |
| Victory and unlocks | C | Tech victory flow, race and ship unlocks (7C) | |
| Debug and admin | A | Console or panel: give Mawjig, spawn squad, reveal map, jump to band, logs on screen (standards: more logs and admin commands) | |

## Assets

| Asset | Goal | Count | Notes | Who |
|---|---|---|---|---|
| Ship art, SVG with named parts (10A) | A: 4 hulls; B: 18; C: 42 | hull, floor plan, rooms, weapon mounts, damaged and doomed variants as recolours | Art Test 01 is the method | Arty |
| Weapon art | A: 9; B: 30; C: 64 | icon and ship-mounted art per weapon folder (11B) | race-styled, not FTL look-alikes | Arty |
| Crew sprites | A: 2 races; B: 3; C: 7 | walk, repair, fight, death; sex variants where the race has them | | Arty |
| System icons | A | FTL's set under Infall names + AZC, conduits, EVB Dock, Jigawatt Drive; C: EVA, Supershield, AAA, Mutation, growth organ | | Arty |
| Map art | A | cluster dot groups per state, region tints per race, collapse ring, link lines | | Arty |
| Backgrounds | A: 6; B: 16; C: 30 | space backgrounds per region type and hazard (nebula, asteroids, sun), near-collapse distortion (B) | | Arty |
| Event images | B | race and situation images for events, as FTL's planets and ships | | Arty |
| Race portraits and ship silhouettes | A | for the hail window and event text | | Arty |
| GUI skin | A | panels, buttons, bars, chips; readable at squad zoom (concern 2) | | Arty with mockups |
| Fonts | A | one for GUI, one for event text | licensed for games | |
| Sound | D | weapons, systems, alerts, UI; music per race and state | | later session |
| Title and store capsule | D | key art, trailer stills (concern 2) | | Arty |

## GUI decisions needed first

1. Per-ship panel placement at squad scale (3B): beside the ship or docked; what shows when zoomed out.
2. How 12 ships read on screen (concern 2): silhouette, colour and size per race.
3. The galaxy map's look: how a cluster's states, rank and race read at a glance (2R: "the map shows it").
4. The conduit view: how cut conduits and rerouting are shown and controlled (7E).
5. Vote and lock-in display (4L).
6. Visual identity apart from FTL (10B).
