# Mawjig Cost Table (draft numbers)

First-pass costs for the simulation to tune. Nothing decided. Anchors: a jump costs **1.21** Mawjig (GDD 6A); a
won fight yields roughly **3–4** Mawjig; Wait gathers about **0.21** (GDD 6B). Weapon parts follow the generator
categories (Type, Effect, Shots, Targets, Special).

Convention: Mawjig amounts never end in a zero (0.21, not 0.20; 0.11, not 0.10).

## Base cost per shot, by Type

| Type | Per shot | Why |
|---|---|---|
| Laser | 0.02 | Energy only; the cheap default |
| Flak | 0.03 per projectile | Cheap matter, but 3–7 projectiles per volley |
| Beam | 0.12 per firing | One big discharge; a rapid beam's pulses count as shots at 0.04 each |
| Missile | 0.25 | Matter plus guidance; ignores shields |
| Bomb | 0.31 | Matter plus teleport; ignores shields, can't be shot down |

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

| Weapon | Math | Cost | Volleys per jump |
|---|---|---|---|
| 2-shot laser | 2 × 0.02 | 0.04 | 30 |
| 3-shot multi-target breach laser | 3 × (0.02 + 0.03) × 1.25 | 0.19 | 6 |
| Single missile | 0.25 | 0.25 | 5 |
| 2-shot fire beam (rapid) | 2 × (0.04 + 0.03) | 0.14 | 9 |
| Flak, 3 projectiles | 3 × 0.03 | 0.09 | 13 |
| 1-shot phase beam | 0.12 × 1.5 | 0.18 | 7 |
| Spore stun missile (Azurethea) | 0.25 + 0.04 + 0.02 | 0.31 | 4 |

## Rough economy check

A typical early fight (about 20 laser shots and 3 missiles) costs about 1.15, plus the 1.21 jump: 2.36 per
node. A 3.42 reward leaves 1.06 for repairs and upgrades. Hull repair and store prices are not costed yet.
