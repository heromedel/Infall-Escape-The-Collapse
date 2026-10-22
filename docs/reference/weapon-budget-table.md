# Weapon Budget Table (draft)

Cooldown and purchase price built from a weapon's parts, so every weapon is priced by adding up what it does.
Per-shot Mawjig costs are in `mawjig-cost-table.md`; this table covers **charge time** and **price**.

Calibration: a least-squares fit over FTL's 48 buyable weapons (crystal, boss and artillery excluded). Cooldowns
are fairly formulaic in FTL (fit explains about 60% of the variation); prices are mostly power bars plus damage
rate, with designer judgment on top (about 78%). Scrap converts at 1 scrap = 0.242 Mawjig, so a Leto-class
weapon (20 scrap) is 4.84, about 4 jumps. Values marked (judgment) had no usable FTL signal.

There is no ammo discount. FTL discounts missiles because lasers there are infinite and missiles are scarce
(you fire missiles, not scrap). In Infall every shot costs Mawjig, so both are finite and lasers are the base;
missiles land undiscounted. A weapon that is better and costs more to fire also costs more to buy. One caveat: the fit's
constants come from FTL's lasers, whose prices include a premium for being free to fire, so Infall laser prices may
end up lower than FTL's; the simulation should tell.

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
| Base | 1.41 | |
| Power | +4.09 per bar | the largest term in FTL's prices |
| Damage rate | +1.16 per (damage per volley × 10 ÷ cooldown) | |
| Ion rate | +0.54 per (ion per volley × 10 ÷ cooldown) | |
| Breach or fire rate | +1.15 per (full-chance shots × 10 ÷ cooldown) | fire by judgment; FTL prices it at zero |
| Pierce | +0.75 per shield layer | |
| Bomb | +5.54 | |
| Flak | +1.38 | |
| Beam | +0.24 | |
| Multi-target | × 1.25 | judgment |
| Phase | × 1.5 | judgment |

Final prices follow the no-trailing-zero rule (x.x0 adds or subtracts 0.01).

## Worked examples

| Weapon | Cooldown | Price | FTL comparison (× 0.242) |
|---|---|---|---|
| Stinger: 1 dmg missile, no effects, 1 power | 9.0 s | 6.79 | Leto 4.84 |
| 2-shot laser, 1 power | 11.0 s | 7.61 | Dual Shot 6.05 |
| 3-shot laser, 2 power | 13.0 s | 12.27 | Burst II 19.36 (FTL prices it above its stats) |
| Heavy laser: 2 dmg, 30% fire, 30% breach, 1 power | 12.2 s | 7.97 | Heavy I 12.10 |
| Pike-type beam: 1 dmg x 4 rooms, 2 power | 20.0 s | 12.15 | Pike 13.31 |
| Glaive-type beam: 3 dmg x 2 rooms, 4 power | 24.0 s | 20.91 | Glaive 22.99 |
| Flak, 3 projectiles, 2 power | 10.0 s | 14.45 | Flak I 15.73 |
| Ion blast, 1 ion, 1 power | 9.5 s | 6.06 | Ion Blast 7.26 |
| Breach bomb, 1 power | 13.0 s | 11.92 | Breach Bomb I 12.10 |
| 3-shot multi-target breach laser, 2 power | 17.0 s | 17.08 | new |
| 1-room phase beam, 2 dmg, 2 power | 19.0 s | 16.58 | new |

The Stinger lands above the Leto because FTL's missile prices carry the scarcity discount that Infall drops: a
shield-ignoring missile costs more to buy and more to fire than a laser.
