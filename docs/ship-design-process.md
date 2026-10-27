# Ship Design Process

How a ship design is put together. Weapons (and other parts) are designed from the ships that need them, not from
lists. Finished designs go in `ship-suggestions.md`.

| Step | Do | Sources |
|---|---|---|
| 1 | Pick a race. | `race-profiles.md` |
| 2 | Pick a difficulty band (1–8, about 10 clusters each). Bands map approximately to a race's ship tiers: 1–3 low, 4–6 mid, 7–8 high (the same grouping as hull repair and fight rewards). | GDD 2G, 2H, 2O; `mawjig-cost-table.md` |
| 3 | Pick the race's state at the cluster where the ship is met: doing fine, struggling or doomed. State is per cluster (GDD 2R), not race-wide, so one race can be doing fine in one cluster and doomed in another. A struggling or doomed state doesn't make a ship poor or damaged; it changes the tactics, diplomacy and alliances the race resorts to. | Race profile points 2–4; GDD 2R |
| 4 | Read the race's info: tone, ship style and silhouette, tech, power model, crew traits, ship tiers. | Race profile; `ftl-weapon-system-organization.md` |
| 5 | Pick a ship function. Anything goes, not just the obvious (scout, explorer, defender, a barely-holding-together refugee ship, a boarding party with stolen tech). | Race profile |
| 6 | Decide what kinds of systems and weapons it has at this band and state, and how many crew. | Race profile point 10; GDD 2N |
| 7 | Decide whether it is a variation for this band/state or standard for the race. | Race profile points 1–4 |
| 8 | Decide the layout, rooms, systems and their power levels, hull and reactor, so the weapons fit. Write the layout in the ship setup format (below). | GDD 5A–5D, 5F–5L, 8A; `ftl-baseline.md` (FTL ship and enemy template numbers) |
| 9 | Weapons: first check the race's existing weapons for one that fits the role and tier. Only if none fits, design one from parts (type, effect, shots, targets, special), price it, and check the ship has a chance to beat a ship with level 1 shields. | GDD 8E; `weapon-budget-table.md`; `mawjig-cost-table.md`; `drone-prices.md` |
| 10 | Price the ship from the reference tables and save it to `ship-suggestions.md`. | `system-prices.md`; the tables above |
| 11 | Record any new rule the design created (a new special's price, a new system's stats) in the matching reference table, so later designs reuse it instead of reinventing it. | `docs/reference/` |

**Layout format — Proposed (2026-10-26):** step 8 gives the layout as the ship's XML would (GDD 5F–5L), so art
and the game build the same ship:

- **Centering:** `Center: Tile` or `Point` (per axis if needed).
- **Rooms:** numbered, each by its two corner tiles from the centre, e.g. `Room 0: (-1,-1),(0,0)`.
- **Systems:** keyed by name (plus a label if there are two, e.g. `Weapons A`), with tile, wall and level/power.
  One tile per system. Anything not listed doesn't exist, so Life Support is never left out by accident.
- **Doors:** numbered, by tile and facing; airlocks are doors facing space. EVA and EVB Docks sit next to one.
- **Other data:** hull, reactor (or Mecha self-power; Terran conduits tile by tile with directions, GDD 5H),
  starting weapons and crew, and the weapon mounts (coordinates on the ship; the hull art at most hints at them).
  Extra mounts are suggested, not required: a hull planned for 2 to 4 weapons should carry 2 more. A hull with
  two weapon systems may flag mounts to one system (`system="Weapons B"`) and cap a system's slots
  (`maxSlots`), GDD 8L. The Light Attack Frame's Weapon Pod is the first `maxSlots="1"`: one weapon by design,
  a semi-hard lock on the hull.
- **Loadouts:** as patches of the base ship (`Inherit: Patch`): list only what changes, `removed` for what goes;
  weapons and crew lists are given whole. A loadout derives from the base ship only.

Finish each design without stopping; list every judgment call at the end for review.

At the creative steps (5, 8, 9), come up with several ideas and pick the best. Then go over the design at least
3–6 times, improving or changing it, and finish with a check that the result makes sense against the data and as
gameplay.

**Proposed (2026-10-23):** a squad's size isn't fixed by its full ships. For band 1 especially, weaker ships or
loadouts let a squad of two or more fit the band's squad value budget (`mawjig-cost-table.md`). The Malphen in
particular can field many small, weak ships early.

**Proposed (2026-10-23):** a design can have several loadouts on purpose:

- **By band range**, overlaps allowed: e.g. a Terran pirate with one loadout for bands 1–3, another for 4–6 and a
  stronger one for 6–8.
- **Alternate loadouts** for the same ship and band: e.g. a Mecha ship with boarding suits or laser suits; pirates
  with a crew teleporter or anti-crew (bio) lasers.

Art is not part of this process.
