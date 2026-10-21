# Infall: Ideas

Ideas that are not yet in the game design document. Nothing here is decided. An idea moves into `gdd.html`
once it has been discussed.

## Victory paths (2026-10-21)

Multiple ways to escape, like the win conditions in Sid Meier's Civilization. Not every path needs the whole colony
ship (GDD 1D) to escape.

| Path | Idea |
|---|---|
| Tech | Requires multiple best-possible systems from multiple races to shield, reinforce, power and then drive the ship so it can make the jump. Victory as long as one ship makes the jump carrying at least one male and one female crew member of the same race, or some kind of Mass Genetic Storage bank. This is what sets it apart from Collection. |
| Alliance | Get enough races to cooperate to build a colony ark that multiple colony ships can migrate their people onto, for the multi-generational voyage to another galaxy through hyperspace. |
| Exploration | Assemble the mysterious pieces of an ancient artifact known as the Orb of Chullack, which opens a giant space gate sending the ship to another dimension where the collapse never happened. |
| Collection | Amass enough wealth and upgrades to prepare the colony ship to slingshot around the collapse, which distorts space and time and flings it to another galaxy. |
| ??? (secret) | Fly into the collapse. Ships take significant damage or are destroyed. Once 3 beacons deep, escape becomes impossible, but they can meet a mysterious hostile alien race that seems to live in the collapse. About 8 or more jumps deep, they may find out this race is the cause of the collapse and destroy its command ship. Where the race comes from is probably never explained. The colony ship is not taken into the collapse. |

## Races

When races are discussed, separate two layers:

- **Crew traits:** what one crew member can do, as in FTL (Mantis fight well, Engi repair fast).
- **Faction behaviour:** how that race's ships and factions act in events and encounters.

### Crew abilities taken from FTL ship mechanics (2026-10-21)

Abilities that exist in FTL as ship or system mechanics, but that no race has:

| Ability | Notes |
|---|---|
| Self-teleport | Crew could hop between ships in their own squad mid-fight to repair, reinforce or flee. Needs a cooldown and probably a range limit. |
| Fire at a ship without a weapon system | A weak attack that still works when weapons are down. Could require standing in a specific room (airlock, hull-facing room). |
| Leave the ship like a drone | Repair hull or wall breaches from outside, or cross to a squad-mate's ship. Limited by air or time outside; vulnerable to anti-drone fire. |
| Produce oxygen | The mirror of FTL's Lanius, who drain oxygen. Less reliance on the oxygen system; stacks with more crew. |
| Run two systems at once | E.g. an octopus or squid-like race reaching systems in one room (see GDD 5B) or adjacent rooms. Fewer crew doing more; suits a low-population race. |

### Nina's race ideas (from the Google Doc)

Both describe faction behaviour more than crew traits, so they would need adapting to fit an FTL-style game.

1. **Solo race (unnamed):** 1–2 ships, minimal crew. They like to work alone and are hard to trade with or
   talk to. Fast workers. "Fast workers" could become a crew trait (faster repairs or system operation).
2. **Ant-like race:** lots of ships; they coordinate and work well with others; their tech needs multiple
   people. "Tech needs multiple people" could become a crew trait (a bonus when several share a room, or
   systems that need two or more of them to operate).

## Ships

### EVA Dock and EVA suits (2026-10-21)

In real life a spacewalk is an EVA (extravehicular activity). Working names: **EVA Dock** for the system,
**EVA suit** for the suit.

Crew suit up at the EVA Dock and leave the ship: a slower, riskier alternative to the teleporter, for boarding
enemies or reaching squad-mates.

- **System levels:** only add suit time/oxygen. More time means reaching farther ships.
- **Distance matters:** crossing time depends on the gap between ships, so formation depth and spacing
  (GDD 3H) become tactical.
- **Risk in transit:** crew outside can be hit by defence drones or anti-personnel fire.
- **Out of air:** to decide. Leaning toward damage over time until they reach a ship, like FTL suffocation,
  rather than instant death.
- A race that survives outside without a suit would be a stronger version of the same mechanic.

## Weapons

### Multi-room targeting lasers (2026-10-21)

Multi-shot lasers (like FTL's dual laser) that can aim each shot at a different room, unlike FTL, where every
shot from one weapon goes to the same target room.

- Possibly targeting rooms on different ships in the enemy squad too, to decide.
- Could be an optional setting: `Multi Target Lasers: On > Off` (default first), so players can keep FTL's behaviour.
