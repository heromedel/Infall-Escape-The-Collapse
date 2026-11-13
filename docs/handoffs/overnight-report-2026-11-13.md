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

### A3. A stronger out-of-step check

The number the LAN machines compare now also takes in the battle's random-number state and tick, each system's
damage, power and ion, each room's air, infection, fires and breaches, the broken conduits, the Supershield and the
cloak and teleporter cooldowns, and which ship each crew member is on. The LAN test still passes with it, which
also says today's crew fights play the same on both machines.

### A4. A wider LAN test, and a bug it found

`tools/lan_run_test.sh` runs a host and a client through a fight won, a purchase by each machine, the client
leaving and rejoining while the host jumps with orders queued behind the jump, the event at the next cluster, a
rule change (Difficulty: Hard), a wait, and a second fight with orders from the client. Both machines then pause on
the same tick and print their state, and the script compares them.

- **Bug found and fixed: a machine that joined while the host was mid-jump fell out of step.** The host's record of
  the run (sent to a machine that joins) listed orders as soon as they were queued, so an order waiting behind the
  jump was in the record and was then sent again when the host played it; the newcomer played it twice. In three
  runs the client reported "out of step" every time, and once never matched the host again. The record is now
  written as each item is played, and what was played in the current frame is sent out before a newcomer is
  welcomed. After the fix: four runs with the client rejoining 0.05, 0.15, 0.3 and 0.45 s into the jump (the host
  confirmed each arrived while the jump was playing) all end with identical state and no out-of-step note.
- Not covered still: hails and surrender offers over LAN, controllers on a client, two real machines.

### A6. Chaos with more than one player

`CHAOS_PLAYERS=2` (up to 6) gives the chaos tester controller players beside the mouse-and-keys one: they point
somewhere in their own view and press a button or lean on a stick, give orders (a door, crew to a room, stations),
and leave and come back. The tester's own clicks on HUD buttons and on the map are now aimed correctly in a split
view (they were aimed as if the view filled the screen, so two-player runs never jumped).

Three two-player seeds of 90 s and one four-player seed, headless: about 450 actions each, jumps, purchases, new
runs and continues, **no failures and no engine errors**. Three two-player seeds with a display (slower, about 45
actions each) were clean too.

**Plan A is done** except what it left out on purpose. Not tested by anything still: real controllers and their
sticks, two real machines, hails and surrender offers over LAN, controllers on a LAN client.

### C1, C2 and B1e. Colours

- **Player Power Color** (GDD 14D, Decided) now works: `Player Power Color: Default (Green) > Racial > Specific Color`
  colours the player's conduits, console symbols, power bars, system icons, weapon power pips and crew shots.
  Racial is the ship's own race's power colour. For Specific Color there is a second setting, `Specific Power
  Color: Blue > Cyan > Yellow > Orange > Pink > Purple > White`. **Ai-Generated-Proposal:** the GDD says only "the
  player picks one colour"; a list to step through was the smallest way to build it, and it leaves red out because
  red is damage.
- **Any Terran ship met as an enemy shows pirate orange** (GDD 14D, Likely), with `Enemy Terran Color: Pirate Power
  Orange > Power Green`. A GATOS patrol used to show green.
- **A damaged system is red** (heromedel; reference frame 18), on the ship and in the HUD. It was orange until
  broken.

### C4, C5, C6 and Eco's answers 2 and 4

- **The Medbay room rule when buying a system** (GDD 5B, Decided). The room picker greys out a room that may not
  take the system and says why, and the purchase itself is refused if the room is wrong. Following Ship Designs:
  crew man Doors and Sensors too, so a Medbay can't share with those either, and an EVB Dock needs a room with an
  airlock. On the Outrider a Medbay is now refused in the bridge, the Sensors and Doors room and the engine room.
  Its conduit advice (warn, don't block) needed nothing: a bought system is joined to the conduits automatically.
- **Abandoned clusters have no store** (GDD 2R, Decided). When a cluster turns Abandoned its store is gone, and
  what it holds becomes "something drifting" (a salvage event), as the GDD's row says.
- **Repairing a system you have a skill level in is 5% faster** (GDD 7H, Decided; the number is Eco's placeholder).
  **For heromedel to settle:** Eco says this number is yours, not the economy's.
- **The growth organ costs 12.11** (Eco: priced as a clone bay), up from the 6.05 placeholder. The Cyst's value
  rises by 6.06 with it; the ship value test's reference numbers predate this, so it now skips ships with a growth
  organ, as it already did ships with a Supershield.
- **Mercenary prices rise with the band** (Eco), times 1.(band − 1) like wreck rewards: the hire price, the price
  shown on the choice and the pay a renewal builds on. The mercenary test still passes (17 of 17).

Fight test 20 of 20, crew fight rules all hold, content check clean after these.

### Eco's answer 5: the event reward mix

The 25 sized event rewards went from 17 low, 6 medium and 2 high to **7 low, 11 medium and 7 high**, the genre's
split as Eco counted it; the 4 tiny ones stay. **Ai-Generated-Proposal:** Eco gave the counts, and which reward
moved is this session's pick, by what the choice risks or needs:

- Now high: talking the freighter through venting, the wreckage's good roll, searching the nebula, cracking the
  weapon cache (it can cost hull), and sending a crew member with the right trait to the failing refugee ship.
- Now medium: the three choices a crew member of the right race opens (Azurethea warning, Senti archive, Tentauri
  passage), towing the GATOS family, patching the Lykario's engine, repairing the refugees' life support, mining
  the asteroids, and the wreckage's poorer roll.
- Still low: the freighter's poorer roll, the Tentauri search, the spore cloud, the stardust, the two chart-sharing
  choices and the Tentauri escort.

Eco also reminded that events need the genre's full reward curve by band; that is already in (GV 8A).

**Not done from Eco's answers:** shield levels as layers in the ship files (answer 1). It changes what every
ship file's shield number means and how upgrades step, so it is left for heromedel to say go on.

### B2, B4, B5 and B6. Closer to the genre

- **System power keys.** A system's own key gives it power and Shift with the key takes power away, as the genre's
  tooltip says. The keys were already in each system's file (Shields A, Engines S, Weapons W, Medbay D and so on)
  and nothing read them. The system's tooltip now shows them. Where a key already does something else in Infall
  (C cloaks, T teleports, E launches a suit, F looks at the ship, Z sends crew to stations), that use stays and
  only Shift with the key works, to take power away. The input test checks Shift + A and A on Shields.
- **The aiming cursor.** While the mouse player aims, the arrow is hidden and the reticle is the cursor; it comes
  back when the aim ends or a window opens. Not seen in a screenshot (a screenshot does not show the system
  cursor), so this one wants a look in play.
- **Enemy shield pips show recharge:** a small bar under the empty pip that is coming back.
- **Fire spreads between rooms through doors only** (heromedel), not through walls: freely through an open door,
  or when the ship has no working Doors system; a closed door slows it 1.75 times and a closed blast door (Doors
  at level 2 or more) 10 times, the genre's wiki figures. "Blast door at Doors level 2" is this session's reading.
- **Open Doors pressed again, with every inner door already open, opens the airlocks too,** as players describe
  the genre's button. The separate Vent button stays.
- Not changed: crew fight fires from where they stand (already so), and the gap between a volley's shots (no
  figure found).
- The wider LAN test now also closes a window of the Admiral's own (a store an event opens), which had made it
  fail now and then by holding the game. Fight test 20 of 20; crew fight rules hold; LAN run passes three times
  running; input test 22 of 22; one chaos seed clean.

### C7. Lykario Animal Senses

With a living Lykario in the squad, the crew aboard an enemy ship are seen even when its inside is not: with no
sensors, or in a nebula (race profiles, Lykario 9, Decided). Only the crew show, not the rooms' state. The race's
card says "Animal Senses: they sense Life Signs aboard other ships, with or without sensors." Checked in a nebula
with a Lykario squad (crew seen) and a GATOS squad (not seen). The profile also says "in hazards"; the nebula is the
one hazard that blinds sensors, so that is where it shows.

**Infall: Lori** was sent the night's new player-facing lines to check (this trait line, the tooltip lines, the
room picker's refusals, the Players menu line, the two setting names).

### C8. Ship status cards (GV 14H)

A new HUD card, SHIP STATUS (top right by default; it drags, docks and folds like the others), holds a small card
of a fixed size for each ship the player commands, and for the Admiral every ship of the squad. Each has the
ship's name, hull bar, shield pips and a deck plan: a room is orange with a flame when it burns, shows a dark hole
when breached, has a red edge when a system in it is damaged, takes a red tint as its air thins, and carries a red
dot for each intruder. A click selects the ship and jumps to it. A folded card reopens when things get worse aboard
any of its ships.

- The plan lies the way the ship does on the screen: upright beside the bars with Battlefield: Vertical, on its
  side under them with Horizontal.
- **Ai-Generated-Proposal:** GV 14H says each card folds; these fold together as one HUD card. The marks' looks
  are this session's.
- Checked by screenshot with two ships, two fires and boarders aboard, in both battlefield orientations; input
  test 22 of 22, co-op test 22 of 22, a two-player chaos seed clean.

### C9. The docs' own ships, and a beam bug found on the way

Added from `ship-suggestions.md`, with Ship Designs' pointers:

| Ship | What it is | Where it is met |
|---|---|---|
| Pirate Pickpocket | Hijacker loadout: Weapons 1 with the Twinshot, a teleporter, three Terrans, no Doors or Medbay, the Cutpurse's hull art | GATOS Pirates band 1 (replacing the Pirate Scrapper there); band 3 may add one beside the Cutpurse |
| Lykario Scrap Hound | Outrider loadout: hull 12, Piloting 2, a stolen Twinshot, a teleporter in the starboard forward room, three Lykario, no Sensors, Doors or Medbay | Lykario Pack band 1 (the pack had no band 1) |
| Malphen Polyp, and its flak loadout | The docs' layout: hull 5, no shields, one weapon, one crew member. New weapons Flesh Mortar (missile) and Bone Flak | Malphen Growth bands 1–2, two Polyps and a flak Polyp (the Malphen had no band 1 or 2) |
| Azurethea Vein Moth | The docs' layout: hull 10, one shield layer, the Stinger and the new Lantern (a one-room beam) | Azurethea Wardens bands 1–2 (the Moth Skiff keeps band 3) |

Left for heromedel, as Ship Designs said: the docs' Relay Picket and the three Senti crew killers need the AAA,
which the game does not have.

Ten bot fights of the Outrider against each (a captain who only aims at weapons and never orders crew):

| Enemy | Won | Hull left of 30 | Crew left of 3 |
|---|---|---|---|
| Two Polyps and a flak Polyp | 9 of 10 | 14.7 | 2.8 |
| Vein Moth | 10 | 27.2 | 3.0 |
| Pickpocket | 10 | 28.7 | 1.4 |
| Scrap Hound | 10 | 28.4 | 2.0 |
| Pirate Scrapper (band 1 before tonight) | 10 | 29.1 | 3.0 |

- **For heromedel: the Polyp swarm is a hard first fight.** Three missiles every nine seconds pass the Outrider's
  one shield layer, and it costs half the hull. The docs flag this themselves ("whether a squad of three is too
  much for a first fight"). It is in as the docs have it.
- **The boarders now kill crew** when nobody answers them (the Pickpocket's three and the Scrap Hound's three):
  that is the bot never sending anyone to fight, but it shows boarding is a real threat in band 1 now.
- By the game's value-from-parts rule the Scrap Hound comes to 332.90 and the Pickpocket to 326.83, about the
  Packrunner's 330.81, because the rule counts the hull's rooms and doors and the Outrider is a big hull. Ship
  Designs' 135.95 and 131.11 count systems and weapons only. So fight rewards for them are like a Packrunner's.
- The Polyp's growth organ only heals. In the docs it grows a new crew member when the one aboard dies, so there
  a Polyp does not end with its crew; here it does (GDD 1F).
- One-line descriptions for the four ships and three weapons are this session's, written from the docs, and go
  to Lori.

**Bug found and fixed: no beam weapon has dealt damage since tile targeting was built.** The beam code kept a list
of the tiles a beam had cut, but a beam was never given that list, so the code failed at the first unshielded tile
it reached and the beam did nothing, the player's and the enemy's alike (five beam weapons). The Vein Moth's
Lantern showed it in the test fights. One missing field; beams work again.

