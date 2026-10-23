# Handoff: Infall Economy

For the **Infall: Eco** session, from **Infall: Ship Designs** (2026-10-23).

Your job: check, test, calculate or simulate the game's economy and suggest balance changes. Never change a doc
without asking heromedel first. Ship Designs keeps checking prices as it designs ships too, so tell heromedel
when you find something, rather than fixing it quietly.

## Rules to follow

1. `CLAUDE.md`, `docs/game-project-standards.md` (workflow: discuss, plan, ask before writing, check, push) and
   `docs/tag-styles.md` (how firmly each point is agreed; suggestions you write are Ai-Generated-Proposal).
2. Mechanics default to FTL's (GDD 1C), so FTL's numbers are the baseline for everything.
3. Number discussion points so heromedel can answer by number.

## The economy in one paragraph

There is one resource, **Mawjig** (GDD 8C): fuel, ammunition and currency at once, shared by the whole squad
(GDD 4E). A jump costs **1.21** (GDD 6A); waiting at a cluster gathers about **0.21** while the collapse advances
(GDD 6B). Every shot costs Mawjig, lasers cheapest. Fights pay Mawjig from wreckage. The run is about 8 difficulty
bands of about 10 clusters (GDD 2O); bands 1–3, 4–6 and 7–8 roughly map to low, mid and high tiers. A run starts
with one ship and wins with about 3–4 very strong or 6 good ones (GDD 3K).

## Where the numbers live

| File | What it holds |
|---|---|
| `docs/gdd.html` | 6A/6B jump and Wait, 8C Mawjig, 8E weapon parts, 8H shield test, 2O run length, 3K squad size, 7G mercenaries |
| `docs/reference/mawjig-cost-table.md` | per-shot cost by weapon type and effect; hull repair per band; fight rewards per band; a rough economy check |
| `docs/reference/weapon-budget-table.md` | charge time and purchase price built from a weapon's parts; worked examples; the off-price (enhanced model) rule |
| `docs/reference/system-prices.md` | system buy and upgrade prices, reactor bars, the Terran AZC, new Infall systems, crew prices, the shield test levels |
| `docs/reference/drone-prices.md` | drone ability buy prices and per-use costs |
| `docs/reference/ftl-baseline.md` | FTL's own numbers extracted from its data: weapons, drones, systems, crew, augments, player ships, enemy templates |
| `docs/reference/ftl-weapon-system-organization.md` | which FTL weapons and systems suit which race |
| `docs/ship-suggestions.md` | three fully priced ship designs, each with a shield check and (for the Terran scout) an economy check |
| `docs/ship-design-process.md` | the steps a ship design follows; step 10 prices it, step 11 records new pricing rules |

## How the numbers are made

1. **Scrap to Mawjig:** FTL price × **0.242** (1 scrap = 0.242 Mawjig), anchored so a basic weapon (FTL's Leto, 20
   scrap) costs about 4 jumps. Used for systems, upgrades, crew, drones and augments.
2. **No trailing zero:** a Mawjig amount never ends in 0; an x.x0 result adds or subtracts 0.01.
3. **Weapon charge time and price** (`weapon-budget-table.md`): a least-squares fit over FTL's 48 buyable weapons.
   Charge = 7.0 s base + parts (e.g. +2.0 s per damage point per volley). Price = 1.41 + 4.09 per power bar + rates
   per 10 s of charge (damage, ion, breach/fire, etc.). There is no ammo discount: missiles are priced like lasers,
   because in Infall every shot costs Mawjig.
4. **Per-shot cost** (`mawjig-cost-table.md`): laser 0.02, beam 0.03 per room, missile 0.05, flak 0.01 per
   projectile, bomb 0.05; each damage point above 1 adds half the base; effects add per shot, scaled by chance.
5. **System price** = buy price (level 1) + every upgrade step up to its level. This matches Federation Home Planet's
   `Pricing.system` (repo `heromedel/federation-home-planet`, `src/main/java/homeplanet/parser/Pricing.java`) and
   FTL's blueprint data, whose upgrade lists are labelled level 2, level 3, ….
6. **Reactor:** 15, 20, 25, 30, 35 scrap per bar in bands of 5 bars. The **Terran AZC** is priced as 5 bars per
   level.
7. **New Infall parts** are priced from their closest FTL analog, sometimes × 0.75 for a weaker analog.
8. **Rules added while designing ships:**
   - A weapon on a system of another tech type charges 20% slower.
   - Conduit damage costs a third of breach.
   - Spores are priced like ion; stun comes from the gap between FTL's Ion Stunner and Ion Blast.
   - The Defensive special adds 5.32: FTL's Defense Drone Mark I less the laser it carries.
   - The Supershield Generator is priced as FTL's Zoltan Shield.
   - Shield test (GDD 8H): one level per layer, priced as FTL's two bars together.

## FTL data and how to get it

- heromedel's FTL folder on Google Drive: https://drive.google.com/drive/folders/1ErJKGVjsM6dVHPHsuGRjVTBigyjHamSl
  - `ftl.dat`: vanilla FTL's data, the baseline. File id `1nMOmpnVpKntfrD4khDh84ylxpVPYmhPi`.
  - `ftl (1).dat`: FTL **Captain's Edition** (a mod), not vanilla. File id `1iCcfHFQgRlduegJt4r5LjA2Gg_xwLf64`.
    Use it only to see how that mod changed things, never as the baseline.
  - The Drive connector couldn't see the folder, but it is public, so curl downloads it:
    `curl -L "https://drive.usercontent.google.com/download?id=<file id>&export=download&confirm=t" -o ftl.dat`
    (about 280 MB; save it in a new, empty folder).
- `ftl.dat` is FTL 1.6's PKG format: magic `PKG\n`, then big-endian u16 header size, u16 entry size (20), u32 entry
  count, u32 paths-region size. Each entry is u32 path hash, u32 path offset (top byte = flags, bit 1 = deflated),
  u32 data offset, u32 data size, u32 unpacked size. The paths region follows the entries. Extract `data/*.xml` and
  run `tools/extract_ftl_baseline.py` on the `data` folder.
- `autoBlueprints.xml` has the enemy ship templates, with each system's starting and maximum level. It is useful for
  setting hull, reactor and system levels by band.
- FTL is for understanding the genre; Infall doesn't copy it directly.

## Checks Ship Designs already does

1. **Recompute every price and charge time** with a quick Python calculation from the formulas, rather than by
   hand, and recheck ship totals after any change.
2. **Shield check:** a ship's weapons must have a chance to beat a ship with one shield layer.
3. **Economy check for a fight:** Mawjig spent per fight (shots per volley × volleys, with FTL-like misses: of a
   3-shot volley, often one is blocked, one misses, one hits), plus the 1.21 jump, against the band's fight reward.
   The cost table's example leaves 1.57 per node in bands 1–3; the Terran scout leaves about 1.33.
4. **Compare with FTL's equivalent ship** (e.g. the Terran scout against the Kestrel) for overall strength.
5. **No trailing zeros** in final prices.

## Known weak spots worth testing

1. No simulation exists yet; the tables say "for the simulation to tune" in several places.
2. Fight rewards (3.42 / 5.13 / 6.84 by band) are a draft; no FTL per-sector reward data was found.
3. The Terran scout's economy check is rough: it assumes 8 volleys per fight, while its shield check kills a band 1
   enemy in about 3.
4. Rounding of per-volley costs (e.g. 3 × 0.021 = 0.063 shown as 0.06) has no stated rule.
5. The Supershield's capacity of 5 is from memory of FTL, not the data; its recharge rate is unset.
6. FTL's hard-coded values (evasion, shield recharge, store prices of fuel and missiles) are approximate, in
   `ftl-baseline.md`.
7. Crew prices and the drone per-use rule are Ai-Generated-Proposal and unreviewed.
8. Whether the economy is too loose or too tight over a whole run (8 bands, squad growth from 1 to 3–6 ships,
   more ships costing more Mawjig per fight) has never been checked.
