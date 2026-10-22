# Mawjig Cost Table (draft numbers)

First-pass costs for the simulation to tune. Nothing decided. Anchors: a jump costs **1.21** Mawjig (GDD 6A); a
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

Rewards rise with progress. No per-sector scrap reward table turned up in the FTL sources checked, so this is a
draft: scaled to match the repair price rise (×1, ×1.5, ×2), starting from the 3.42 example.

| Bands | Reward for a basic won fight | Hull points it repairs |
|---|---|---|
| 1–3 | 3.42 | about 7 |
| 4–6 | 5.13 | about 7 |
| 7–8 | 6.84 | about 7 |

With both scaling together, a reward is worth about 7 hull points of repair in every band. The jump stays 1.21, so
later fights leave more after the jump. Making rewards grow more slowly than repair prices would make late damage
bite harder; this ratio is the knob to tune in the simulation.

## Rough economy check

A typical early fight (about 20 laser shots, 0.40, and 3 two-damage missiles, 0.24) plus the 1.21 jump is 1.85 per
node. A 3.42 reward leaves 1.57, which pays for about 3 hull points of repair at the band 1–3 price. A fight that
costs 5 hull points needs a reward of about 4.25 to break even in bands 1–3.
