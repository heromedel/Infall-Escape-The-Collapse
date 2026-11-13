# Overnight report (2026-11-13 to 14)

The log of `overnight-plan-2026-11-13.md`, written as the night goes, newest at the bottom. The summary and the
numbered questions for heromedel are added at the end.

## Log

### Helpers asked (Plan D)

- **Infall: Eco** was sent seven questions: its five open items in `items-needing-second-opinion.md`, the number
  for GDD 7H's "slightly faster" repair, and whether the new one-hit-a-second crew fights trouble the economy.
- **Infall: Ship Designs** was sent four: floor plans for the docs' ships that have none (Polyp, Vein Moth, Relay
  Picket, the three Senti crew killers), anything to know about the Pickpocket and Scrap Hound loadouts, whether
  the Medbay rule is the whole placement rule, and which ships need a system the game lacks.

### A1. Baseline

Every test passes before any change tonight:

| Test | Result |
|---|---|
| Compile check | no errors |
| Content check | no problems |
| Galaxy, mercenary, ship value | pass |
| Crew fight rules | all 13 hold |
| Fight test | won 20 of 20, average 42.7 s |
| Input test | 20 of 20 |
| Co-op (split screen) test | 17 of 17 |
| LAN test | host 5 of 5, client 8 of 8, no machine out of step |
| Bot runs (6) | all lost, between jump 6 and jump 19 (bands 2 to 4) |

The bot runs losing early is not from today's crew fight changes: the same six seeds on the code from before them
lost at nearly the same jumps (6, 12, 11, 13, 19, 20 then; 6, 13, 11, 9, 19, 19 now). The bot is a simple captain
(everything at the enemy's weapons, repairs at stores), so this may only show the bot's limits; it is noted for Eco.

### B1. What the genre does (no new recordings)

| Question | Answer | From | Infall |
|---|---|---|---|
| Do crew walk to a fire to fight it? | No; they fight it from where they stand | heromedel | Same already. Nothing to change. |
| How does fire spread between rooms? | Through doors. Open doors let it through easily; a closed door slows it 1.75 times, a closed blast door 10 times | heromedel; the genre's wiki, Door System page | Spreads through any wall at a quarter chance. To change. |
| Open all doors and airlocks | One press opens every inner door; a second press opens the airlocks as well. Closing works the same in reverse | Players' forum posts (the wiki confirms the command and its key only) | Separate OPEN DOORS and VENT buttons. A second press of OPEN DOORS can vent too. |
| The gap between a volley's shots | Not found online; the genre's data has no field for it | Search, and the earlier research | Stays 0.25 s; `explained-not-in-gdd.md` item 10 still calls 0.2 s a guess. Not changed. |
| A damaged system's colour | Red | heromedel; reference frame 18 (one point of damage, icon red) | Orange until broken. To change. |
| System power keys | The key adds power, Shift with it removes: "Add Power: A / Remove Power: Shift + A" on the Shields tooltip | Reference frame 12 | Each system file names a key; nothing reads it. To build. |
| Event choice keys | Not confirmed by any source found | Search; the game's readme lists only 1–4, 5–6 and Escape | Parked: asked in the questions below. |

