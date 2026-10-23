# Mawjig Cost Table (draft numbers)

First-pass costs for the simulation to tune. Anchors: a jump costs a fixed **1.21** Mawjig for the whole squad
(GDD 6C, Decided); a
won fight yields roughly **3–4** Mawjig; Wait gathers about **0.21** (GDD 6B). Weapon parts follow the generator
categories (Type, Effect, Shots, Targets, Special).

Convention: Mawjig amounts never end in a zero (0.21, not 0.20; 0.11, not 0.10). If the weapon generator ever
lands on an x.x0 value, it must add or subtract 0.01.

## Base cost per shot, by Type (1 damage)

| Type | Base | Why |
|---|---|---|
| Flak | 0.01 per projectile | Debris; scatters |
| Laser | 0.02 | The cheap default; can miss, blocked by shields |
| Beam | 0.03 per room swept (or per pulse) | Can't miss, can't be shot down |
| Missile | 0.05 | Ignores shields; 2.5× a laser |
| Bomb | 0.05 per bomb, plus effect | Ignores shields, can't be shot down; mostly an effect carrier |

Shots multiply the base in full (2 laser shots are 0.04). Damage adds less than shots do: each damage point above 1
adds half the base, so a laser shot is 0.02, 0.03 and 0.04 at 1, 2 and 3 damage, and a 2-damage missile is about
0.08. Half is a first guess for the simulation to tune. The no-trailing-zero convention applies to the final
price: an x.x0 result must add or subtract 0.01 (0.10 becomes 0.11 or 0.09).

## Effect, added per shot

At 100% chance; scale by chance (a 30% breach chance adds 0.01).

| Effect | Added | Effect | Added |
|---|---|---|---|
| Damage | none | Stun | +0.02 |
| Hull bonus | +0.01 | Kill (bio) | +0.05 |
| Breach / wall breach | +0.03 | Mind control | +0.08 |
| Fire | +0.03 | Toxin | +0.04 |
| Infection | +0.05 | Lockdown | +0.04 |
| Ion | +0.02 | Atmosphere conversion | +0.04 |
| Spores | +0.04 | Pierce | +0.04 |
| Heal | +0.05 | Repair | +0.11 |
| Conduit damage | +0.01 | | |

## Shots, Targets, Specials

| Part | Cost rule |
|---|---|
| Shots | Per-shot cost × number of shots |
| Multi-target | × 1.25 on the volley |
| Charge | Same per shot; paid when it fires |
| Chain | Same per shot; drains faster because it fires faster |
| Phase | × 1.5 per shot (it passes shields) |

## Worked examples (per volley)

| Weapon | Math | Cost | Per jump |
|---|---|---|---|
| 2-shot laser, 1 dmg | 2 × 0.02 | 0.04 | 30 |
| Heavy laser, 1 shot, 2 dmg | 0.02 × 1.5 | 0.03 | 40 |
| Flak, 3 projectiles | 3 × 0.01 | 0.03 | 40 |
| Missile, 2 dmg | 0.05 × 1.5 | 0.08 | 15 |
| Pike-type beam, 1 dmg, 4 rooms | 4 × 0.03 | 0.12 | 10 |
| Glaive-type beam, 3 dmg, 3 rooms | 3 × 0.03 × 2 | 0.18 | 6 |
| 3-shot multi-target breach laser | 3 × (0.02 + 0.03) × 1.25 | 0.19 | 6 |
| Breach bomb | 0.05 + 0.03 | 0.08 | 15 |
| Spore stun missile, 1 dmg | 0.05 + 0.04 + 0.02 | 0.11 | 11 |

## Hull repair

FTL's store charges per hull point by sector: 2 scrap in sectors 1–3, 3 in sectors 4–6, 4 in sectors 7–8 (FTL wiki,
"Stores and resources"), an average of about 2.9. Infall maps its 8 difficulty bands onto the same steps. At
1 scrap = 0.242 Mawjig:

| Bands | Scrap per point | Mawjig per hull point |
|---|---|---|
| 1–3 | 2 | 0.48 |
| 4–6 | 3 | 0.73 |
| 7–8 | 4 | 0.97 |

Weapon purchase prices from `weapon-budget-table.md` are the store prices;
systems, crew and augments carry over from FTL's prices at the same 0.242 conversion.

## Fight rewards

- **Proposed (2026-10-23):** Rewards follow FTL's per-sector curve, one step per band, starting from the 3.42 of
  GDD 8C. FTL's scrap per reward level and sector (Normal difficulty, from Hexagon's disassembly of the game, tabled
  at [MikeHopley/ftl-scrap](https://github.com/MikeHopley/ftl-scrap)) is weighted by how often FTL's fights pay
  each level, counted from vanilla `ftl.dat`. Details in `docs/economy-findings.md` (F1).
- **Decided (2026-10-23):** Killing the crew pays more than destroying the ship, about 30% more, as in FTL. An intact
  ship leaves more matter to convert into Mawjig.
- **Likely (2026-10-23):** Band 1 starts near FTL, but later bands may need rewards to rise faster than FTL's to pay
  for a bigger squad's costs, unless the run allows, or ends up with, more time for grinding.
- **Likely (2026-10-23):** Rewards are paid per enemy ship destroyed or left without crew, not once per fight. The
  size of enemy squads compared with the player's is then the economy's main dial: smaller enemy squads mean a
  poorer run (GDD 8I; `docs/economy-findings.md`, F4).

These are averages. Each fight pays a varying amount around them, as in FTL, where a reward level's range runs
about a quarter either side of its middle and the level itself varies (Low, Medium, High).

| Band | Per ship destroyed | Per ship left without crew | Hull points a destroyed-ship reward repairs |
|:-:|:-:|:-:|:-:|
| 1 | 3.42 | 4.36 | about 7 |
| 2 | 4.77 | 6.09 | about 10 |
| 3 | 6.21 | 7.88 | about 13 |
| 4 | 7.57 | 9.62 | about 10 |
| 5 | 9.01 | 11.41 | about 12 |
| 6 | 10.42 | 13.21 | about 14 |
| 7 | 11.78 | 14.99 | about 12 |
| 8 | 13.21 | 16.79 | about 14 |

Rewards rise every band while repair prices rise in three steps, so a reward buys about 7 hull points in band 1 and
about 12–14 late, as in FTL. The jump stays 1.21, so later fights leave more after the jump.

## Rough economy check

A typical early fight (about 20 laser shots, 0.40, and 3 two-damage missiles, 0.24) plus the 1.21 jump is 1.85 per
node. A 3.42 reward leaves 1.57, which pays for about 3 hull points of repair at the band 1–3 price. A fight that
costs 5 hull points needs a reward of about 4.25 to break even in bands 1–3.
