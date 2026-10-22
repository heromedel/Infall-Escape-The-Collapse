# System and Upgrade Prices (draft)

Same conversion as weapons and hull repair: FTL's store prices × 0.242 (1 scrap = 0.242 Mawjig), with the
no-trailing-zero rule. Nothing decided; the simulation tunes these.

## Systems

"Buy" is the price to install the system at level 1. "Upgrades" lists each level's step price in order (level 2,
level 3…), as FTL's blueprint data labels them. A system at a level costs its buy price plus every step up to that
level (e.g. Shields at 2 bars: 30.25 + 24.21 = 54.46), the same way Federation Home Planet prices systems
(`Pricing.system`).

FTL lists Piloting and Engines at 1 scrap because every ship starts with them; Life Support starts installed too.

| System | FTL buy (scrap) | Buy (Mawjig) | Upgrades, per level (Mawjig) | All upgrades (Mawjig) |
|---|---|---|---|---|
| Life Support (FTL Oxygen) | 0 | starts installed | 6.05, 12.11 | 18.16 |
| Piloting | 1 | starts installed | 4.84, 12.11 | 16.95 |
| Engines | 1 | starts installed | 2.42, 3.63, 7.26, 9.68, 14.52, 19.36, 29.04 | 85.91 |
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

## New Infall systems (suggested, from FTL analogs)

Each is priced from the closest FTL system. A weaker analog ("sucks more") takes × 0.75 of its price, a first
guess.

| System | Analog | Buy (Mawjig) | Upgrades, per level (Mawjig) | All upgrades (Mawjig) |
|---|---|---|---|---|
| EVB Dock | Drone Control | 14.52 | 2.42, 4.84, 7.26, 10.89, 14.52, 19.36, 24.21 | 83.51 |
| Mutation system | Drone Control × 0.75 | 10.89 | 1.82, 3.63, 5.45, 8.17, 10.89, 14.52, 18.15 | 62.63 |
| EVA Dock | Teleporter × 0.75 | 16.34 | 5.45, 10.89 | 16.34 |
| AAA | Clone Bay + Backup DNA Bank augment (40 scrap) | 21.78 | 8.47, 10.89 | 19.36 |
| Supershield Generator | Zoltan Shield augment (80 scrap) | 19.36 | none yet | — |

The number of levels follows the analog until each system's levels are designed.

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
