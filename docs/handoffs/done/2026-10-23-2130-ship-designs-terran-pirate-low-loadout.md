# Handoff: Terran pirate, bands 1–3 loadout of the Pirate Hijacker's hull

| | |
|---|---|
| Prepared | 2026-10-23 20:30 UTC |
| Sent | 2026-10-23 20:52 UTC |
| From | Infall: Production (`Cloud-C-Production-Flow`) |
| To | Infall: Ship Designs (`Cloud-C-ShipDesign`) |
| Asked by | heromedel, 2026-10-23 (loadouts by band range: "a Terran pirate with a loadout for band 1–3, another for 4–6") |
| Serves | `production-goals.md`, Goal A: Terran doomed pirates (enemy race), the second Terran hull, Terran doomed squads |
| Status | **done** |

## The task

Give the Terran Pirate Hijacker's hull (`ship-suggestions.md`, band 5) a **bands 1–3 loadout**, so the same hull
carries two loadouts the way heromedel described: a weaker one for bands 1–3 and the existing one for 4–6. One
loadout, not a new hull. Then one squad in the `rough-example-squad-layout.md` format, filling its Low row.

## What exists to build on

- The Pirate Hijacker: classic Terran cruiser hull, rust and mismatched panels, a bolted-on stolen Azurethea
  launcher; hull 14, AZC level 3, Sporewing + Gat 2.1 "Twinshot", crew teleporter, 5 Terran crew; hijacks rather
  than destroys. Keep the hull, the silhouette and the identity (hijacker); scale everything else down to bands 1–3.
- Doomed Terrans (race profile, Terrans 4, 7; Proposed): aggressive, xenophobic, theft, hijacking, piracy; doomed
  hubs become checkpoints with tolls and shakedowns; Terran pirates work the colony arms. Darker colours and scarier
  emblems as they fall (Decided). All-Terran crew (the Hijacker's call).
- Budget: a band 1 fight is worth a squad value of about 137, band 2 about 173, band 3 about 414 for two ships
  (`economy-findings.md`, F6). A wreck pays 2.5% of ship value × the band adjustment (GDD 8I, Proposed). So the
  loadout should price near 137–175 for band 1–2, and the Low squad row near the band it is met in.
- Band 1–3 stand-ins: hull 7–10, one shield layer. The Outrider is the player ship it must be beatable by and
  must threaten: it has Shields level 1, Gat 3.1 and Gat M1, 3 crew.
- Tables: `mawjig-cost-table.md`, `weapon-budget-table.md`, `system-prices.md` (AZC levels), volley rounding rule
  (F5, 4). Weapons: use the Gat 2.1 "Twinshot" and Gat M1 "Pathfinder" if they fit; design a new Terran weapon
  only if none fits (process step 9).
- Lore: `lore-facts.md`, Terrans. Nothing may contradict it; new facts go to heromedel as a numbered list.

## Deliverable, in `ship-suggestions.md`

1. A **Loadouts** subsection on the Pirate Hijacker: a table with both loadouts side by side (bands, hull points,
   AZC level, systems and levels, weapons, crew, price), the existing one unchanged, the new one priced through the
   tables with a shield check and an economy check against the Outrider at band 1 and band 3 (the simulation you
   used for the Mecha pair is fine).
2. How the bands 1–3 loadout hijacks with less: which systems it lacks, what it goes for first, what it does when
   the Outrider's shield holds.
3. A squad in `rough-example-squad-layout.md`'s format, Low row filled with this loadout (its name) and counts, the
   Mid row with the existing loadout, High left as placeholders. Conduct lines (Hail, surrender, escape) only
   where they differ from the Hijacker's.
4. Judgment calls listed, decisions needed flagged. Expected: what a hijacker does to a lone Outrider in band 1
   if it wins (the run is lost at 1F only when all scouts are gone, so a boarded and taken ship is a loss), and
   whether a bands 1–3 pirate can afford a crew teleporter at all.

Creative 3-6 Rule applies. No art.

## When done

Push to `Cloud-C-ShipDesign` and message Infall: Production with the commit. Production checks and merges or sends
back numbered points. Questions for heromedel go through Production, numbered.

## Log

- 2026-10-23 20:30 UTC: prepared.
- 2026-10-23 20:52 UTC: sent.
- 2026-10-23 20:56 UTC: received, commit 1f5979f on `Cloud-C-ShipDesign`: Cutpurse loadout (130.46), loadouts table, Terran Pirates squad, stun-lock targeting rule.
- 2026-10-23 21:10 UTC: checked (prices recompute: 130.46, rewards 3.26 / 4.24 and 7.82; profile and lore; squad format) and merged. Decision on a winning hijacker in band 1 passed to heromedel. Done.
