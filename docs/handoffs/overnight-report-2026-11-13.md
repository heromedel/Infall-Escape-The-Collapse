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

### What the helpers answered (both within about fifteen minutes)

heromedel's rule for the night: go with what they say, then report it. What was done with each answer is logged
under the step that used it; this is what they said.

**Infall: Ship Designs** (checked by it against `ship-suggestions.md` on its own branch):

1. Floor plans exist in `ship-suggestions.md` for the **Polyp** (line 1058; its flak loadout at 1082 swaps the Flesh
   Mortar for Bone Flak) and the **Vein Moth** (line 938; its weapons are the Stinger and the Lantern, a 1-room,
   1-damage beam, 1 power, 14.0 s, 6.57, which is not the game's Lanternfly). The docs' **Relay Picket** has a
   layout (line 1124) but needs the AAA, and the three **Senti crew killers** have no Infall layouts, are Deck
   Collapse test ships, and need the AAA too: leave all four for heromedel.
2. **Pickpocket:** band 1 only; Terran Pirates band 1 is one Pickpocket, band 3 one or two Cutpurses or
   Pickpockets; three Terrans; the Cutpurse's hull art; 131.11. On the game's single-weapon-system Hijacker it
   comes to "Weapons level 1 with the Twinshot only". **Scrap Hound:** bands 1–2, in the Lykario Pack's band 1
   slot (the Packrunner is over band 1's budget); three Lykario; hull 12; no Sensors, Doors or Medbay; Engines 1; a
   Crew Teleporter at (2,-2) on the east wall; the Twinshot on mount 3; AZC 2; Lykario silver; 135.95; the
   Outrider's art until it has its own.
3. Placement rules for a bought system: one tile a system and no console on a door tile; a Medbay only with
   systems crew can't man, remembering that crew man Doors and Sensors too; an EVA or EVB Dock next to an airlock;
   a weapon system's slot count is a lock on that hull; on conduit ships warn, don't block, when no conduit reaches
   the room.
4. It also noted the game's Hijacker is out of date: the docs' has Weapons A (Twinshot) and Weapons B (Sporewing).
   That is the several-weapon-systems item (GDD 8L, C11).

**Infall: Eco:**

1. Shield level should mean layers (GDD 8H), as its prices and values already do; it would change the ship files
   from bars to layers.
2. The growth organ is priced as a clone bay: buy 12.11, upgrades 8.47 and 10.89.
3. Keep 15 crew damage a point of damage: the wiki's figure, and it fits the genre's data (the anti-crew beam's 4
   units being its known 60), though never timed in game.
4. Keep the mercenary prices, but scale them by band like wreck rewards, times 1.(band − 1). Its opinion only.
5. Event rewards: the genre's sized rewards are 28% low, 45% medium, 27% high. Keep the 4 tiny; re-tag the other
   25 to about 7 low, 11 medium and 7 high (17, 6 and 2 now).
6. "Slightly faster" repair is not an economy number but heromedel's; as a placeholder only, +5%, half of one
   repair level. **To flag for heromedel.**
7. No objection to one hit a second in crew fights.

### A1 (end). Chaos baseline

Five chaos seeds of 60 s each: no failures, no engine errors, no frame spikes.

### A2, A5, A7, A8. Co-op fixes

- **Five and six players on one screen** are laid out three across and two down (they were off the screen).
- **Assignments are remembered** (GDD 4F): when a player leaves, what they commanded is kept, and the Players menu
  shows the Admiral a RESTORE button beside "… commanded … before leaving" once they are back. Kept in memory for
  the run; a save does not keep it.
- **The Admiral leaving by choice pauses the game and saves** (GV 4E), as their machine dropping out already did.
- The co-op test gained five checks (remembering, restoring, six views on screen, the Shared view, the Admiral
  leaving): 22 of 22 pass.
- Stale notes fixed: the README no longer says assigning ships isn't built, and the comment in `session.gd` is
  right.

