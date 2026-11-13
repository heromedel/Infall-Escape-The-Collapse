# System and Upgrade Prices (draft)

Same conversion as weapons and hull repair: FTL's store prices × 0.242 (1 scrap = 0.242 Mawjig), with the
no-trailing-zero rule. Nothing decided; the simulation tunes these.

## Systems

"Buy" is the price to install the system at level 1. "Upgrades" lists each level's step price in order (level 2,
level 3…), as FTL's blueprint data labels them. A system at a level costs its buy price plus every step up to that
level (e.g. Shields at 2 bars: 30.25 + 24.21 = 54.46), the same way Federation Home Planet prices systems
(`Pricing.system`).

FTL lists Piloting and Engines at 1 scrap because every ship starts with them; Life Support starts installed too.
**Likely (heromedel, 2026-10-31):** in a ship's value they cost **36.31** each at level 1 (150 scrap, heromedel's
price in Federation Home Planet's `Pricing.CORE_SYSTEM`), upgrades on top. Every ship still starts with them.

| System | FTL buy (scrap) | Buy (Mawjig) | Upgrades, per level (Mawjig) | All upgrades (Mawjig) |
|---|---|---|---|---|
| Life Support (FTL Oxygen) | 0 (150 in a ship's value) | 36.31 | 6.05, 12.11 | 18.16 |
| Piloting | 1 (150 in a ship's value) | 36.31 | 4.84, 12.11 | 16.95 |
| Engines | 1 (150 in a ship's value) | 36.31 | 2.42, 3.63, 7.26, 9.68, 14.52, 19.36, 29.04 | 85.91 |
| Shields | 125 | 30.25 | 24.21, 4.84, 7.26, 9.68, 14.52, 19.36, 24.21 | 104.08 |
| Weapon Control | 20 | 4.84 | 9.68, 6.05, 8.47, 12.11, 18.15, 21.78, 24.21 | 100.45 |
| Medbay | 50 | 12.11 | 8.47, 10.89 | 19.36 |
| Clone Bay | 50 | 12.11 | 8.47, 10.89 | 19.36 |
| Sensors | 40 | 9.68 | 6.05, 9.68 | 15.73 |
| Doors | 60 | 14.52 | 8.47, 12.11 | 20.58 |
| Teleporter | 90 | 21.78 | 7.26, 14.52 | 21.78 |
| Cloaking | 150 | 36.31 | 7.26, 12.11 | 19.37 |
| Hacking | 80 | 19.36 | 8.47, 14.52 | 22.99 |
| Mind Control | 75 | 18.15 | 7.26, 14.52 | 21.78 |
| Backup Battery | 35 | 8.47 | 12.11 | 12.11 |
| Drone Control | 60 | 14.52 | 2.42, 4.84, 7.26, 10.89, 14.52, 19.36, 24.21 | 83.51 |
| Artillery | 150 | 36.31 | 7.26, 12.11, 19.36 | 38.73 |

Drone Control and Artillery are listed for reference; both are unplaced (see `ftl-weapon-system-organization.md`).

## Ship value: hull, rooms, doors and mounts

**Likely (heromedel, 2026-10-31):** a ship's value counts its structure as Federation Home Planet does
(`Pricing.java`: `HULL_POINT`, `SYSTEM_ROOM_PERCENT`, `EMPTY_ROOM`, `DOOR`), converted at 0.242. A ship's value is
then its structure, reactor, systems at their levels and weapons; crew are counted separately.

| Part | FHP (scrap) | Mawjig |
|---|:-:|:-:|
| Each hull point | 10 | 2.42 |
| Each room holding a system | 10% of that system's level-1 price | 10% of its level-1 price (Mawjig) |
| Each room without a system | 2 | 0.48 |
| Each door | 2 | 0.48 |
| Each weapon mount | — | **6.05** |

- **Rooms — Ai-Generated-Proposal (2026-10-31), shared with Godot Version:** a room holding several systems counts
  10% of its dearest system's level-1 price; the AZC counts as a room system at 18.15 (its level 1); a shields room
  counts the shield test's level 1, one layer (54.46, so 5.45). Reference values per ship: `economy-findings.md`, F13.
- **Weapon mounts — Proposed (heromedel, 2026-10-31):** a mount costs 25 scrap (**6.05**) to add at a store, and each
  mount a ship has counts at that price in its value. FHP counts mounts but doesn't price them. Replaces the first
  guess of 4.84 (`economy-findings.md`, F10).
- **Likely (heromedel, 2026-10-31):** the wreck rate stays 2.5% of value (GDD 8I), so rewards rise with the new
  values; buying ships rises the same way, which offsets it.

## Shields under the shield test (GDD 8H)

One level per layer; each level takes 2 power and 2 damage to lose, and is priced as FTL's two bars together.

| Level | Layers | FTL bars it replaces | Scrap | Mawjig |
|---|---|---|---|---|
| 1 | 1 | buy + level 2 | 225 | 54.46 |
| 2 | 2 | levels 3–4 | 50 | 12.11 |
| 3 | 3 | levels 5–6 | 100 | 24.21 |
| 4 | 4 | levels 7–8 | 180 | 43.56 |

## Senti Shield Projector — Proposed (2026-11-13, heromedel)

Senti only, instead of the shield system above (the Mawjig Shield Generator). One power and one damage per layer;
layers recover twice as slowly; maximum level double the Generator's (8 layers).

**Likely (2026-11-13, heromedel):** each layer is priced as a Generator layer of the same number, so a Projector
layer costs no less than a Generator layer and budgets limit how many a ship carries.

| Level | Layers | Mawjig |
|---|---|---|
| 1 | 1 | 54.46 |
| 2 | 2 | 12.11 |
| 3 | 3 | 24.21 |
| 4 | 4 | 43.56 |
| 5–8 | 5–8 | **Open:** "crazy expensive" (heromedel); no genre price exists above 4 layers, so Eco sets these |

## New Infall systems (suggested, from FTL analogs)

Each is priced from the closest FTL system. A weaker analog ("sucks more") takes × 0.75 of its price, a first
guess.

| System | Analog | Buy (Mawjig) | Upgrades, per level (Mawjig) | All upgrades (Mawjig) |
|---|---|---|---|---|
| EVB Dock | Drone Control | 14.52 | 2.42, 4.84, 7.26, 10.89, 14.52, 19.36, 24.21 | 83.51 |
| Mutation system | Drone Control × 0.75 | 10.89 | 1.82, 3.63, 5.45, 8.17, 10.89, 14.52, 18.15 | 62.63 |
| EVA Dock | Teleporter × 0.75 | 16.34 | 5.45, 10.89 | 16.34 |
| AAA | Clone Bay + Backup DNA Bank augment (40 scrap) | 21.78 | 8.47, 10.89 | 19.36 |
| Supershield Generator | Zoltan Shield augment (80) + Shield Overcharger drone (60) + a third of Drone Control (20), 160 scrap | 38.72 | 7.26, 12.11 | 19.37 |
| System battery (Senti) | Backup Battery × 0.75 (powers one system only) | 6.35 | 9.08 | 9.08 |

The number of levels follows the analog until each system's levels are designed.

**Supershield Generator — Proposed (heromedel, 2026-10-23; `economy-findings.md` F5, item 10):** 38.72. It starts
each fight full like the Zoltan Shield and regrows layers in battle like the Shield Overcharger, so it is priced as
both, plus a third of Drone Control (it can't launch other drones). **Upgrades — Ai-Generated-Proposal (2026-10-31):**
7.26 and 12.11 for levels 2 and 3 (30 and 50 scrap, Cloaking's steps; FTL's three-level systems step about 30 then
50). Each level regrows a layer faster; FTL's Overcharger regrows one every 15 s (`DRONE_SHIELD` data).

Supershield Generator (Tentauri): FTL's Zoltan Shield as a ship system that recharges periodically, like the Shield
Overcharger without a drone system. 2 bars (the Overcharger's player power). Capacity 5, as FTL's Zoltan Shield
(from memory of FTL, not in the extracted data); recharge rate left for the simulation.

## Crew (Ai Generated)

FTL's crew price × 0.242 (`ftl-baseline.md`), each race priced from its closest FTL crew by what it does.

| Race | FTL analog (scrap) | Why | Mawjig |
|---|---|---|---|
| Terrans | Human (45) | "as FTL's humans" | 10.89 |
| Azurethea | Lanius (50) | the oxygen mirror: they make air where Lanius drain it | 12.11 |
| Mecha | Zoltan (60) | power a system by integrating | 14.52 |
| Tentauri | Zoltan (60) | running up to four systems is a top-tier ability | 14.52 |
| Senti-GPH | Crystal (60) + 5 | the profile says they cost more to recruit | 15.73 |
| Lykario | Mantis (55) | quick attackers | 13.31 |
| Malphen | Rockman (55) | high HP | 13.31 |
| Whispwraith | Lanius (50) | atmosphere-changing crew | 12.11 |

## Mecha self-powered systems

**Proposed (2026-10-26):** Mecha ships have no reactor; each system carries its own power. Each self-powered bar
adds **8.47 Mawjig** to the system's price, the same as the dearest reactor bar: a self-powered system is always on and
never competes for power, which is worth more than a shared reactor bar, though the bar can't be moved to another
system. This applies only on Mecha ships (GDD 8D: a system takes the power behaviour of the ship it is on). Bars
added by integrated Mecha crew are priced separately, as their mech upgrades (`economy-findings.md`, F5).

Replaces the earlier rule (Ai-Generated-Proposal, 2026-10-23) that priced these bars as ordinary reactor bars
(3.63 each for bars 1–5, 4.84 for 6–10, …).

Senti core (Ai-Generated-Proposal, 2026-11-13): it works by bars (race profiles, Senti-GPH 6), so it is priced
per bar as the standard reactor below.

## Standard reactor (per bar)

FTL's reactor price rises every 5 bars. The FTL wiki table is garbled, so these use the designer's recollection:
15, 20, 25, 30, 35 scrap.

| Bars | Scrap per bar | Mawjig per bar | Mawjig for the 5 bars |
|---|---|---|---|
| 1–5 | 15 | 3.63 | 18.15 |
| 6–10 | 20 | 4.84 | 24.21 |
| 11–15 | 25 | 6.05 | 30.25 |
| 16–20 | 30 | 7.26 | 36.31 |
| 21–25 | 35 | 8.47 | 42.35 |

## Terran reactor (AZC) — Proposed

Levels instead of bars. Each level powers 2 more systems to their maximum bars. The step price is 5 × the standard
band price, so the AZC costs the same as buying the standard reactor in bands of 5.

| Level | Systems at max bars | Step (scrap) | Total (scrap) | Step (Mawjig) | Total (Mawjig) |
|---|---|---|---|---|---|
| 1 | 2 | 75 | 75 | 18.15 | 18.15 |
| 2 | 4 | 100 | 175 | 24.21 | 42.36 |
| 3 | 6 | 125 | 300 | 30.25 | 72.61 |
| 4 | 8 | 150 | 450 | 36.31 | 108.92 |
| 5 | 10 | 175 | 625 | 42.35 | 151.27 |

Level 5 can only be installed by a Terran station event or on a genuine Terran ship (not a stolen or copied AZC).

Sources: FTL Wiki, "Ship" and "Stores and resources"; system prices from FTL's data files (`ftl-baseline.md`).
