# Build report, 2026-11-14

For heromedel, from **Infall: Godot Version**. He asked for the game to be finished as a clean, classic design
from the docs, without conduits on by default, tested by playtesters and blind testers, with Infall: Lori and
Infall: Eco helping. This is what was built that day, what the tests show, and what is left.

The Windows build is `infall-godot/build/windows/Infall.zip`, made from the last commit of the day. Infall: Eco read
the playtest numbers overnight and changed no price: its one piece of advice, ships in more stores from band 4 on,
is in.

## What the playtests show

Three bots play whole runs through the game's own code (`tools/playtest`). A win is a whole game: all eight bands,
then the Last Fleet at the rim. In a fight each ship is flown by the same captain code the enemy uses.

| Playtester | How it plays | Games won, of 70 |
|---|---|---|
| Careless | Fires each weapon as it charges at any room, picks event choices at random, flies straight out, repairs only when badly hurt | 0 |
| Watcher | Goes by what is on the screen: focuses fire, shoots weapons then shields, takes blue choices and offered ships, explores, heads for stores, upgrades to a plan | 15 (7 of 40, then 8 of 30) |
| Expert | Knows what every event choice is worth, picks targets by threat, leaves a losing fight, spends everything, thinks five times a second | 27 (15 of 40, then 12 of 30) |

So the game can be won, a careless player never wins, and a good player wins about one game in five. Careless runs
end in bands 2 to 5, most of them in band 4. In the round of 40 the expert reached the Last Fleet in 31 games and
beat it in 15; it wins with three or four ships, as GDD 3K expects. The second round, of 30 games on other seeds,
was played after the last changes of the day (several weapon systems, the Hijacker's two). These rates move by
several games from round to round, and the bots never tire or misclick, so a person playing the watcher's way
would win less often than it does.

What the runs changed:

1. **The Tentauri Coil laser** fired two shots where `ship-suggestions.md` gives it one. It ended over half of all
   runs in band 1. With the docs' numbers the Outrider wins every band 1 duel with 84 to 98% of its hull.
2. **Malphen Growth** was the biggest killer. Band 2 is now two Polyps, and band 5 a Swollen Spawnling with
   sometimes a Spawnling; the Broodmass starts at band 6.
3. **Senti pickets** start at band 3, as the docs have the Relay Picket.
4. **A store ship costs 75% of its value** on Normal (Infall: Eco; it was 115%, which no run could ever pay).
5. The bots first reached the end with hundreds of Mawjig unspent and unrepaired hulls: they were not going to
   stores. They now head for a store their sensors show, as a player would.

Still rough, from the last round:

1. **The Last Fleet** ends most of the runs that reach it: 14 of the expert's 31 final fights were lost, and 6 of
   the watcher's 16. A squad of one or two ships does not beat it.
2. **Senti pickets** cost the watcher and the expert a third to a half of their hull each time (bands 4 to 6).
   The Shield Projector's three layers stop most early weapons.
3. **Running out of Mawjig.** The watcher had to wait for want of Mawjig 87 times over 40 games and was swallowed
   by the collapse four times. Infall: Eco calls that an economy fault if a real player meets it; the numbers have
   gone to Eco.
4. **The middle bands are mild for the expert:** fights in bands 3 to 7 cost it under 15% of its hull.

## What was built

| Thing | From | Notes |
|---|---|---|
| A classic reactor by default | heromedel | `Terran Ship Conduits: Off > On`; enemy ships follow the setting too |
| Classic shields as the genre has them | heromedel | Power moves in pairs; a layer that loses a bar gives up the other |
| Hacking, Mind Control | GDD 8A, the genre | The Senti's is the Intrusion Array, the Azurethea's the Pheromone Gland (heromedel, Likely). On the Archive Cruiser and the Sporecarrier, and in stores |
| Backup Battery | The genre; Senti profile 6 | On the Relay Picket; in stores |
| Senti Shield Projector | GDD 8Q | One bar a layer, up to eight, back half as fast |
| Armoured Avatar Array | Senti profile 6 and 9 | One Senti per bar of power; held, not killed, when it loses power; struck-down Senti are broadcast again |
| The docs' Relay Picket | `ship-suggestions.md` | Replaces this session's stand-in. The Archive Cruiser is its mid-tier loadout |
| End of a run | Infall: Lori | Eight events for bands 6 to 8, the Last Fleet's hail with four choices, end screens, nine fixes to older events |
| A system's controls on the system | heromedel, the genre | Icon buttons above the bars; no SPECIALS card, no VENT |
| TO STATIONS, SAVE STATIONS | heromedel | |
| How to Play; a hint in early fights | Blind testers | `Hints in Early Fights: On > Off` |
| A hull's stripe in the ship's power colour | heromedel, 2026-11-13 | The Patrol Cutter |
| `Beams vs Shields: Penetrate (Classic) > Hit (Damages Shields First)` | GDD 8Q | Off by default. With Hit, the Senti beam ships win their duels about a quarter sooner |
| Two door buttons that flip between open and close | heromedel (his option B and icons) | Doors and airlocks |
| Several weapon systems on one ship | GDD 8L | A row of slots for each; each draws on its own bars and has its own gunner. The Pirate Hijacker and the Tentauri scout have Weapons A and B, as the docs have them |
| The EVA Dock | GDD 8R; heromedel "all of it" | Crew cross to another ship in a suit. The open details are filled in as Ai-Generated-Proposals (GV 8K) |
| The three Senti crew killers | `docs/deck-collapse-ships` | With fire beams, a breach laser, an anti-crew beam and a bio bomb. Mild in fights so far |
| Twelve events for bands 3 to 6 | Infall: Lori | Ships and mercenaries on offer, hostile events with a choice before the fight, Senti events that pay without a fight. 107 events in all |
| Short names under the system icons; a different sign on each system's button | Second blind test | SHLD, ENG, WPN A… |
| The dock rule, the Hijacker's door, the Patrol Cutter's hull, the shields room value | Earlier the same day | |

## Blind testers

Three testers who knew nothing about the game looked at screenshots of the title, map, store, ship screen and
fights and said what they saw.

Fixed from their reports: the title's tagline over the QUIT button; an enemy ship under the top bar; untitled
power cards; "1 / 10 REACTOR" (now "1 of 10 POWER FREE"); bare prices on buttons (now BUY and UPGRADE); SOLD on a
system the ship already has (now INSTALLED); the low Mawjig warning not naming the purchase; windows too
see-through; the map's jump button with no hint; and, from all three, nothing saying how to attack.

Not fixed:

1. **Ships look small at the start of a fight.** The view shows both squads and the real distance between them
   (GV 3I), so each ship is small until the player zooms. All three testers said so.
2. **"5,000K Gatometers"** read as a typo to two of them.
3. **Senti weapon names** ("2L 02 V1") read as meaningless codes. They are the race's naming rule.
4. Crew pictures in the store are small and dark in the Top Down art style.

## Numbers and wording filled in (each an Ai-Generated-Proposal)

- Hacking costs 0.04 Mawjig a pulse and Mind Control 0.08 a use (Infall: Eco).
- Shield Projector layers 5 to 8 cost 62.92, 82.28, 101.64 and 121.01 (Infall: Eco).
- The Armoured Avatar Array mends its Senti aboard their own ship, a third as fast as a medbay.
- The Archive Cruiser's loadout, and the Pheromone Gland on the Sporecarrier.
- Which Malphen ships meet the player in which band.
- The How to Play page and the hint line (sent to Infall: Lori for a read).

## Not built

- From GDD 8M: weapon slots set by a system's level, `maxSlots`, and mounts kept for one weapon system.
- The Senti system battery; seeing into a hacked room; mind control's bonus at higher levels.

## Tests at the end of the day

Compile, content, galaxy, mercenary, ship value (all 15 ships match Infall: Eco's table), crew fight (13 rules)
and fight (20 of 20) tests pass. Input 27 of 27, co-op 22 of 22. The LAN test and the LAN run test pass (the LAN run
test failed once while the machine was busy with playtests, and passed when run on its own). Chaos: four seeds
clean, one with a display and one with two players. The exported game starts without errors.

## Questions (answered 2026-11-14: Q1 the difficulty looks right as it is; Q2 the overview; Q3 all of it)

- **Q1.** The watcher, a good player, wins about one game in five and the careless player none. Nine losses in
  ten is said to be the genre's own target (heromedel, 2026-11-14: it is not his; Infall has no set win rate). Do
  you want Normal made a little harder, and if so in the middle bands (where the expert loses little hull) or at
  the Last Fleet?
- **Q2.** Should a fight open zoomed on your own ship, with the enemy off screen until you zoom out, or stay as the
  overview it is now?
- **Q3.** What next: the EVA Dock, the three Senti crew killers and their weapons, or more ships and events for the
  middle bands?

# Later the same day

Everything below was built after the report above, from heromedel's messages through the day and by way of Infall:
Lori, Eco and Ship Designs. The Windows build `infall-godot/build/windows/Infall.zip` is from the last commit.

## What was built

| Thing | From | Notes |
|---|---|---|
| Captains weigh the fight | heromedel | Damage in against damage out and both hulls; a change of tactics needs 5 s to settle and is kept 15 s (GV 3L) |
| The galaxy changes after every jump | heromedel | Refugees move, borders are at war, fronts shift (GV 2E) |
| Seven enemy ships | Infall: Ship Designs | Quiet Ledger, Final Archive, Howler, Hawkmoth, Breacher, Sellsword, Spear Grass |
| The Tech victory | heromedel; `docs/ideas.md` | The pieces are races' own systems, fitted to one ship. The search starts two bands from the rim; the map points to regions (GV 2F) |
| The rival | heromedel | Commodore Marlowe's Long Odds: two hunts, jumping away below 25% hull by its Jig Drive MC-Flywheel, then the ambush at the rim with one replacement |
| Leaving a fight | heromedel (GDD 6F) | Each ship jumps clear on its own charged drive at no cost; the squad's jump costs the 1.21. SHIP OUT under JUMP |
| Refit yards | heromedel (GDD 5N) | Move or trade a system between ships for a quarter of its value, fit a piece from the hold, sell a ship. Four warnings |
| EVA crew can stay | heromedel (GDD 8R) | A third button on the EVA Dock |
| The Alliance victory | heromedel; plan in `docs/ideas.md`, checked by Infall: Lori | Pledges won in talks, by the cluster's state and by who is aboard; four of seven; allies at the rim (GV 2G) |
| Fifteen weapons, five new rules | heromedel; Infall: Ship Designs | Charge and chain weapons; healing, repair and lockdown bombs; fire and ion bombs; GATOS beams; eight loadouts carrying them (GV 8M) |
| Twelve more events | heromedel; Infall: Lori | Clusters at war, refugees on the move, yards, the last two bands. 145 events in all; they went in after the playtest round |
| Settings | | `Tech Victory: Optional > Required`; `Tech Victory Pieces: One of Each Pair > All Seven` |

## What the playtests show now

One round on the last code, seeds 2000 on. A win is a whole game.

| Playtester | Games | Won | Of those |
|---|---|---|---|
| Watcher, no goal | 30 | 5 | 3 by the Alliance victory, 2 by the plain ending |
| Expert, no goal | 30 | 9 | 5 by the Alliance victory, 4 by the plain ending |
| Expert going for the Tech victory | 20 | 3 | 2 Tech victories, 1 plain |
| Expert going for the Alliance victory | 20 | 5 | 4 Alliance victories, 1 plain |

1. **The game is harder than this morning.** The expert won about half its games then and 9 of 30 now, the third
   heromedel called right. What changed in between: stronger enemy loadouts in bands 2 to 8, captains that change tactics, the
   rival's hunts, and the expert spending on new systems (Hacking, Mind Control, a Teleporter, a Battery, Cloaking)
   where it used to buy only upgrades.
2. **The Tech victory can be won, and is the hardest.** Of 20 games going for it, six had all four needs fitted
   to one ship, and two won the ambush. Before the pieces had to be on one ship and before pairs, with all seven,
   it was two of 20 that even held the pieces.
3. **The Alliance victory is the easiest,** and it happens to players who are not trying: three of the watcher's
   five wins were Alliance, because talks come up on arrival and the allied ships help at the rim.
4. **The rival's hunts** cost about a sixth of the squad's hull. Over all four sets they destroyed three squads.
5. **The watcher ran out of Mawjig more than before** (184 waits over 30 games). Found: the playtester was
   paying for convoy pledges (about 12 Mawjig a game, a cost that is new) even when that left it unable to jump,
   where a player gets the low Mawjig warning. With the playtester keeping its jumps in reserve, the waits fall to
   89 over 30 games, about 3 a game, against 2 a game before the victories went in. Where a watcher's Mawjig goes
   in a game: the store about 114, jumps about 92 (76 jumps), pledges about 10, shots about 10, other events
   about 7. The playtest now prints this.
6. **Crew killers, judged by crew** (heromedel by way of Eco). Crew lost per fight: the Last Fleet 5.5, Senti
   pickets 0.8, Azurethea wardens 0.7, GATOS pirates 0.4, and the Senti Census 0 in its three fights. They do not
   kill crew.

## Checks

Compile, content (57 weapons, 25 systems, 145 events), galaxy, mercenary, ship value, crew fight and fight tests
pass. Input 27 of 27, co-op 22 of 22, the LAN run test passes. Chaos: seeds 11, 12 and 13 clean (a stale probe in
the chaos test was fixed). A blind tester looked at the new screens; fixed from it: a panel behind the map's text
and shorter lines, SHIP OUT as a button under JUMP, clearer yard buttons with the reason a move isn't possible.

Not fixed from it: weapon panels over the squad's ships in a fight, the hint banner over the enemy ship, Senti
weapon code names, two crew for sale with the same picture.

## Not built

- Enemy captains do not use the yard, the EVA Dock, or hold a charge weapon to fire several volleys at once.
- A Short run has no Tech victory.
- The Collection (colony ship), Exploration and secret victories.

## Questions

- **Q1 (answered 2026-11-14: one of each pair).** The Tech victory's pieces: one of each pair, as `docs/ideas.md`
  had it in October, or all seven, as you said this morning? Both are built; the default is the pairs. Genetic diversity stands in as six of your own
  people aboard the one ship.
- **Q2.** The Alliance plan in `docs/ideas.md` (eight points, with Lori's check) is built as written. Which points
  are wrong? Two in particular: is four of seven the right number, and should pledging the Malphen cost goodwill
  with the Azurethea or the Tentauri?
- **Q3.** The Alliance victory comes to players who are not trying for it. Leave it, or should the squad have to
  choose to pursue it?

# The evening

Built after heromedel's "I think you are ready to work", in the order agreed: the decisions into the docs, the
small items, the Malphen systems, the Alliance changes, the Vector Drive victory with a setting for every victory,
then events from the situation with populations. Infall: Lori, Eco and Ship Designs supplied texts, prices and ships
through the evening. The Windows build `infall-godot/build/windows/Infall.zip` is from the last commit.

## What was built

| Thing | From | Notes |
|---|---|---|
| A system can move within its own ship at a yard | heromedel (GDD 5N) | |
| Mecha Hull Polarizer | heromedel (GDD 8T) | The Hull Reinforcement renamed; one to a ship |
| Further weapon systems at stores | heromedel; Infall: Eco F10 | Every level full price; each further one costs 1.21 more to install |
| Growth Organ as the Malphen clone bay | heromedel (GDD 8S) | Regrows the dead as growths |
| Lymph Gland | heromedel (GDD 8S) | Hacks an enemy system; tends one of its own rooms (repairs faster, heals to 75%); with a Growth Organ heals a little on a jump, to 100% |
| The Alliance victory as all seven | heromedel; Infall: Lori's rewrite | Each people gives the convoy one thing. The Mecha only when Struggling or Doomed, for a profit; doomed Senti past a fight and with an Armoured Avatar Array; the Malphen only through a gland. The last fight is the Metastasis (GV 2G) |
| The Vector Drive victory | heromedel; Lori's events; Ship Designs' Vector Frame; Eco F19 | In place of the Last Fleet. The drive is lost if the ship dies with it damaged; the ship folds away when beaten down unless the drive is damaged, jammed or spent (GV 2H) |
| A setting for every victory | heromedel | `Rim Victory: Vector Drive > Last Fleet`, `Tech Victory: On > Off`, `Alliance Victory: On > Off` |
| An event's choice changes the fight | heromedel (GDD 9E); Lori's hooks | First strike, escorts or allies held back, a jammed drive, an event that plays once the fight is won |
| Events come from the situation | heromedel (GDD 9D) | No cluster is flagged hostile in advance; the weights are in `content/situations/situations.xml` (GV 2I) |
| Populations | heromedel (`docs/ideas.md`, 2026-10-27) | Gatillions; people leave ahead of the collapse and move on; sensors show them (GV 2J) |

## What the playtests show now

One round on the last code, seeds 2000 on, the same seeds as the table above. A win is a whole game.

| Playtester | Games | Won | Of those |
|---|---|---|---|
| Watcher, no goal | 30 | 4 | 4 by the Vector Drive, fitted to one ship |
| Expert, no goal | 30 | 6 | 6 by the Vector Drive, fitted to one ship |
| Expert going for the Tech victory | 20 | 1 | 1 Tech victory |
| Expert going for the Alliance victory | 20 | 0 | |

1. **The expert wins a fifth of its games,** against the 9 of 30 before the evening. 18 of its 30 games reached
   the Vector Frame and 6 won there, about the same odds as the Last Fleet gave. The difference is the Alliance
   victory: with four races and allies it was five of those nine wins, and with all seven it is none.
2. **The Vector Frame's choices come out even.** The expert won 4 of 15 opening fire and 4 of 15 taking the
   contest. Before the contest's escorts came in at half hull, the contest won the fight four times in five.
3. **Nobody lost the drive, and nobody saved everyone.** The captains spare the drive's room once the ship is half
   beaten, so in 27 wins the drive came out scarred 20 times and whole 7. No playtester ended with the 242.01 Mawjig
   for The Colony Ship: the expert ends a game with about 150.
4. **The Alliance victory was not won in 20 games going for it.** Seven of the 20 got six of the seven peoples.
   Nine of the 20 were swallowed by the collapse while still looking.
5. **The Tech victory:** three of 20 games had all four needs fitted to one ship; one won the ambush.
6. **Fights a jump** are about as many as before over a whole game (watcher 0.25, expert 0.31), and now depend on
   where the squad is. A GATOS squad's chance of a hostile arrival in band 6 where things are fine: its own space
   25%, Tentauri 27%, Azurethea 31%, Senti 33%, Lykario 54%, Mecha 59%, Malphen 77%. The first weights gave too few
   fights and the watcher starved; the base weight of hostile events was doubled.
7. **Malphen space kills.** Malphen growths were 167 fights and 7 lost games; GATOS pirates 345 fights and 9 lost
   games. The playtesters now take another way outward where the map shows plainly dangerous space, when there is
   one.
8. **Mawjig:** the watcher waited for want of it about 3 times a game, as before the evening.

## Checks

Compile, content (356 event choices now checked for requirements, effects and references), galaxy (with
populations and situations), mercenary, ship value, crew fight, fight and the new Vector Drive test pass. Input 27
of 27, co-op 22 of 22, the LAN run test passes, chaos seeds 11, 12 and 13 are clean. An exported build starts.

A blind tester looked at eleven new screens. Fixed from it: the Vector Frame's drive state overlapped its name;
fitting the drive now says it ends the run, won; end screens say VICTORY; How to Play scrolls and names SHIP OUT;
the text after a fight no longer speaks of wrecks when the crews were killed.

Not fixed from it: the hint banner over an enemy ship's tag, ship names cut short in tags, the store's faint
scrollbar, and a talk that shows only "Leave it." when the squad lacks what a blue choice needs (as in the genre,
choices the squad can't take are not shown; the map says what the Malphen need).

## Filled in to build it (each an Ai-Generated-Proposal)

They are listed where they live: GV 2H (the Vector Drive victory: where the Vector Frame waits, how it folds away,
the escorts, fitting, the drive lost), GV 2I (every weight in `content/situations/situations.xml`) and GV 2J
(population sizes and distances the note doesn't give). Three worth knowing without opening them:

1. The Vector Frame folds away over 12 seconds, and a hit on its drive stops the fold. That same hit is what loses
   the drive if the ship then dies, so stopping it is a risk the player chooses.
2. One of the squad's own ships can be fitted with the drive right after the fight or at any store; only The
   Colony Ship needs a refit yard.
3. If the drive is destroyed and neither the Tech nor the Alliance victory is allowed, the run is lost there.

## Not built

- A doomed Senti store behind a fight. Fights deep in doomed Senti space come from the situation: about four
  arrivals in five there are hostile.
- The Collection victory by refitting The Colony Ship (`docs/ideas.md`), and the Exploration and secret victories.
- Enemy captains still do not use the yard, the EVA Dock, or hold a charge weapon.
- Senti crew killers still kill almost no crew (0.83 a fight for the pickets, 0 for the Census in two fights).

## Questions

- **Q1.** The expert now wins a fifth of its games, where you called a third right. Leave it, or ease the Vector
  Frame? If ease, the simplest lever is when its escorts join a contest (now at half its hull).
- **Q2.** The Alliance victory with all seven was not won in 20 games by a playtester going for it. Is that how
  hard the peaceful victory should be?
- **Q3.** Nobody could pay the 242.01 Mawjig to fit the drive to The Colony Ship, so every Vector Drive win was one
  ship leaving alone. Is the ending where everyone leaves meant to be that rare?
