# Mawjig Cost Table (draft numbers)

First-pass costs for the simulation to tune. Nothing decided. Anchors: a jump costs **1.21** Mawjig (GDD 6A); a
won fight yields roughly **3–4** Mawjig; Wait gathers about **0.21** (GDD 6B). Weapon parts follow the generator
categories (Type, Effect, Shots, Targets, Special).

Convention: Mawjig amounts never end in a zero (0.21, not 0.20; 0.11, not 0.10).

## Base cost per shot, per point of damage, by Type

| Type | Base | Why |
|---|---|---|
| Flak | 0.01 per projectile | Debris; scatters |
| Laser | 0.02 | The cheap default; can miss, blocked by shields |
| Beam | 0.03 per room swept (or per pulse) | Can't miss, can't be shot down |
| Missile | 0.05 | Ignores shields; 2.5× a laser per damage |
| Bomb | 0.05 per bomb, plus effect | Ignores shields, can't be shot down; mostly an effect carrier |

Damage per shot multiplies the base (a 2-damage laser shot is 0.04). The no-trailing-zero convention applies to
the final price (0.10 becomes 0.11).

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
| Heavy laser, 1 shot, 2 dmg | 0.02 × 2 | 0.04 | 30 |
| Flak, 3 projectiles | 3 × 0.01 | 0.03 | 40 |
| Missile, 2 dmg | 0.05 × 2 | 0.11 | 11 |
| Pike-type beam, 1 dmg, 4 rooms | 4 × 0.03 | 0.12 | 10 |
| Glaive-type beam, 3 dmg, 3 rooms | 3 × 0.03 × 3 | 0.27 | 4 |
| 3-shot multi-target breach laser | 3 × (0.02 + 0.03) × 1.25 | 0.19 | 6 |
| Breach bomb | 0.05 + 0.03 | 0.08 | 15 |
| Spore stun missile, 1 dmg | 0.05 + 0.04 + 0.02 | 0.11 | 11 |

## Rough economy check

A typical early fight (about 20 laser shots, 0.40, and 3 missiles, 0.33) plus the 1.21 jump is 1.94 per node. A
3.42 reward leaves 1.48 for repairs and upgrades. Hull repair and store prices are not costed yet.
