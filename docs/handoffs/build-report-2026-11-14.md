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

## Questions

- **Q1.** The watcher, a good player, wins about one game in five and the careless player none. You said nine
  losses in ten is normal. Do you want Normal made a little harder, and if so in the middle bands (where the
  expert loses little hull) or at the Last Fleet?
- **Q2.** Should a fight open zoomed on your own ship, with the enemy off screen until you zoom out, or stay as the
  overview it is now?
- **Q3.** What next: the EVA Dock, the three Senti crew killers and their weapons, or more ships and events for the
  middle bands?
