# Genre Timings (measured)

Reference only, nothing decided. Numbers read from the genre's own save files (heromedel's Save Logger logs,
2026-09-30 and 2026-10-06, Easy, sectors 4 to 7) and from one fight of the real game run under Wine by the coding
session (2026-10-26, Kestrel on Easy, sector 1). They complement `ftl-baseline.md`, which holds the data-file
numbers; these are the live ones the data files don't give.

## Clocks inside the saves

| Timer | Stored as | Read as |
|---|---|---|
| Weapon cooldown goal | blueprint seconds × 800 (a 16 s chain laser is 12800; the 11.1 s Vulcan is 8880) | a weapon charges 800 units a second |
| Cloak goal | 10000, 15000 | cloak levels of 10 s and 15 s, so most other timers run 1000 units a second |
| Jump drive fully charged | 85000 | charge accumulates at a rate the engines set; not a plain 85 s |
| Ion deionization | up to 24375 | the ion clearing clock, about 24 s at the top value seen |
| Drone cooldown (defence and shield drones) | 6000 | 6 s |
| Drone buildup before firing | 500 | 0.5 s |

The saves also carry crew `Stun Ticks`, `Dying Ticks`, `Stationary Ticks`, `Overload Ticks`, `Shield Recharge Ticks`
and `Energy Shield` animation ticks, so any of those can be read the same way once a save catches them mid-count.

## Crew skill steps

Mastery intervals in the saves (Advanced Edition; the original game's in brackets): pilot 15 (13), engines 15 (13),
shields 55 (50), weapons 65 (58), repair 18 (16), combat 8 (7). These are the per-event steps behind GDD 7H's
"about FTL's pace"; one level is one interval.

## One real fight, measured from screenshots

Kestrel (Burst Laser II, 12 s, 3 shots; Artemis, 11 s, 2 damage) against a Zoltan Energy Fighter (about 7 hull,
one shield layer plus its energy shield), sector 1, Easy.

| | Measured |
|---|---|
| First volley lands | about 10 s after the fight starts |
| Fight length | 21 s |
| Player hull lost | 1 |
| Reward | 25 scrap, 3 fuel, 2 missiles |

For comparison, Infall's simulation (2026-10-26) has the Outrider (Gat 3.1, 13.1 s, 3 shots; Gat M1, 9.1 s,
1 damage) kill the 7-hull Light Attack Frame in 27 s on average over 200 fights, first volley at 13 s, 0.1 hull
lost. The gap is the weapons' charge times and damage, not the combat rules.

## Fight economy from a real run (Easy, sectors 4 to 5, a strong Zoltan cruiser)

Rewards per won fight seen in the saves: 27, 47, 49, 45, 31, 26 and 52 scrap, with fuel and missiles alongside;
no hull lost in any of them; one store visit of about 120 scrap. At the cost table's 0.242 Mawjig a scrap that is
6 to 13 Mawjig a fight, against `mawjig-cost-table.md`'s 3.42 for a band 1 wreck. Bands 4 to 5 pay more by design
and this was Easy, so it is a note for the economy session, not a correction.
