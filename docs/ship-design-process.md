# Ship Design Process

How a ship design is put together. Weapons (and other parts) are designed from the ships that need them, not from
lists. Finished designs go in `ship-suggestions.md`.

| Step | Do | Sources |
|---|---|---|
| 1 | Pick a race. | `race-profiles.md` |
| 2 | Pick a difficulty band (1–8, about 10 clusters each). Bands map approximately to a race's ship tiers: 1–3 low, 4–6 mid, 7–8 high (the same grouping as hull repair and fight rewards). | GDD 2G, 2H, 2O; `mawjig-cost-table.md` |
| 3 | Pick the race's state: doing fine, struggling or doomed. A struggling or doomed state doesn't make a ship poor or damaged; it changes the tactics, diplomacy and alliances the race resorts to. | Race profile points 2–4 |
| 4 | Read the race's info: tone, ship style and silhouette, tech, power model, crew traits, ship tiers. | Race profile; `ftl-weapon-system-organization.md` |
| 5 | Pick a ship function. Anything goes, not just the obvious (scout, explorer, defender, a barely-holding-together refugee ship, a boarding party with stolen tech). | Race profile |
| 6 | Decide what kinds of systems and weapons it has at this band and state, and how many crew. | Race profile point 10; GDD 2N |
| 7 | Decide whether it is a variation for this band/state or standard for the race. | Race profile points 1–4 |
| 8 | Decide the layout, rooms, systems and their power levels, hull and reactor, so the weapons fit. | GDD 5A–5D, 8A; `ftl-baseline.md` (FTL ship and enemy template numbers) |
| 9 | Weapons: first check the race's existing weapons for one that fits the role and tier. Only if none fits, design one from parts (type, effect, shots, targets, special), price it, and check the ship has a chance to beat a ship with level 1 shields. | GDD 8E; `weapon-budget-table.md`; `mawjig-cost-table.md`; `drone-prices.md` |
| 10 | Price the ship from the reference tables and save it to `ship-suggestions.md`. | `system-prices.md`; the tables above |
| 11 | Record any new rule the design created (a new special's price, a new system's stats) in the matching reference table, so later designs reuse it instead of reinventing it. | `docs/reference/` |

Finish each design without stopping; list every judgment call at the end for review.

At the creative steps (5, 8, 9), come up with several ideas and pick the best. Then go over the design at least
3–6 times, improving or changing it, and finish with a check that the result makes sense against the data and as
gameplay.

Art is not part of this process.
