# Weapon Budget Table (draft)

Cooldown and purchase price built from a weapon's parts, so every weapon is priced by adding up what it does.
Per-shot Mawjig costs are in `mawjig-cost-table.md`; this table covers **charge time** and **price**.

Calibration: a least-squares fit over FTL's 48 buyable weapons (crystal, boss and artillery excluded). Cooldowns
are fairly formulaic in FTL (fit explains about 60% of the variation); prices are mostly power bars plus damage
rate, with designer judgment on top (about 78%). Scrap converts at 1 scrap = 0.242 Mawjig, so a Leto-class
weapon (20 scrap) is 4.84, about 4 jumps. Values marked (judgment) had no usable FTL signal.

There is no ammo discount: every shot costs Mawjig (see `mawjig-cost-table.md`), so a weapon that is better and
costs more to fire also costs more to buy. FTL's fit carried a discount for ammo weapons (lasers are free to fire
there); removing it, the whole price column is scaled by 0.71 so the Stinger lands near the Leto.

## Cooldown (seconds)

| Part | Seconds | Notes |
|---|---|---|
| Base | 7.0 | |
| Damage per volley | +2.0 per point | damage × shots (beams: damage × rooms swept) |
| Ion | +2.5 per point per shot | |
| Fire | +3.0 per shot at 100% chance | scale by chance |
| Breach | +1.0 per shot at 100% chance | FTL adds ~0; small value by judgment |
| Pierce | +1.4 per shield layer | |
| Beam | +5.0 | |
| Bomb | +5.0 | |
| Flak | −3.0 | |
| Multi-target | +1.0 | judgment |
| Phase | +3.0 average search time | judgment |
| Charge | per-charge cooldown = total ÷ charges | |
| Chain | starts about +4.0, falls each volley | judgment |
| Foreign tech type | slower (first guess +20%) | the Stinger: 9 s native, about 11 s on a tech ship |

## Price (Mawjig)

Rates are per 10 seconds of cooldown, so a faster weapon is worth more. The damage-rate term keeps FTL's linear
fit; the half-step damage rule in the cost table applies to per-shot cost only.

| Part | Mawjig | Notes |
|---|---|---|
| Base | 0.99 | |
| Power | +2.91 per bar | the largest term in FTL's prices |
| Damage rate | +0.82 per (damage per volley × 10 ÷ cooldown) | |
| Ion rate | +0.38 per (ion per volley × 10 ÷ cooldown) | |
| Breach or fire rate | +0.82 per (full-chance shots × 10 ÷ cooldown) | fire by judgment; FTL prices it at zero |
| Pierce | +0.53 per shield layer | |
| Bomb | +3.93 | |
| Flak | +0.98 | |
| Beam | +0.17 | |
| Multi-target | × 1.25 | judgment |
| Phase | × 1.5 | judgment |

Final prices follow the no-trailing-zero rule (x.x0 adds or subtracts 0.01).

## Worked examples

| Weapon | Cooldown | Price | FTL comparison (× 0.242) |
|---|---|---|---|
| Stinger: 1 dmg missile, no effects, 1 power | 9.0 s | 4.82 | Leto 4.84 |
| 2-shot laser, 1 power | 11.0 s | 5.41 | Dual Shot 6.05 |
| 3-shot laser, 2 power | 13.0 s | 8.71 | Burst II 19.36 (FTL prices it above its stats) |
| Heavy laser: 2 dmg, 30% fire, 30% breach, 1 power | 12.2 s | 5.66 | Heavy I 12.10 |
| Pike-type beam: 1 dmg × 4 rooms, 2 power | 20.0 s | 8.63 | Pike 13.31 |
| Glaive-type beam: 3 dmg × 2 rooms, 4 power | 24.0 s | 14.85 | Glaive 22.99 |
| Flak, 3 projectiles, 2 power | 10.0 s | 10.26 | Flak I 15.73 |
| Ion blast, 1 ion, 1 power | 9.5 s | 4.31 | Ion Blast 7.26 |
| Breach bomb, 1 power | 13.0 s | 8.46 | Breach Bomb I 12.10 |
| 3-shot multi-target breach laser, 2 power | 17.0 s | 12.13 | new |
| 1-room phase beam, 2 dmg, 2 power | 19.0 s | 11.77 | new |

Side effect of the rescale: apart from the Stinger, the examples now land about 10–55% below FTL's hand-set prices.
The alternative is to keep the original scale, which puts the Stinger near 6.78 (about 5.6 jumps) and the rest close
to FTL; a shield-ignoring missile priced above the Leto would match "better weapon costs more".
