# Infall: Ideas

Ideas that are not yet in the game design document. Nothing here is decided. An idea moves into `gdd.html`
once it has been discussed.

## Victory paths (2026-10-21)

Multiple ways to escape, like the win conditions in Sid Meier's Civilization. Not every path needs the whole colony
ship (GDD 1D) to escape.

| Path | Idea |
|---|---|
| Tech | Requires multiple best-possible systems from multiple races to shield, reinforce, power and then drive the ship so it can make the jump. Victory as long as one ship makes the jump carrying at least one male and one female crew member of your core race, or some kind of Mass Genetic Storage bank. This is what sets it apart from Collection. Components, one from each core race: Gatos power core, Azurethea engine (most agile), Mecha ship reinforcements, Tentauri shield, Senti-GPH information archive, Lykario autopilot, Malphen clone bay. Requirement idea: one from each pair: power core or clone bay (without the power, you store your genetic data in the clone bay for the periods when the ship loses power); engine or autopilot; shield or reinforcements; archive or genetic diversity (maybe 3 males and 3 females of your core race). Each component must be that race's own version (e.g. the clone bay must be a Malphen clone bay; the power core must be a Terran AZC); any single one of that version counts. Near-Terran races, such as the Senti-GPH, may have slightly worse cores. |
| Alliance | Get enough races to cooperate to build a colony ark that multiple colony ships can migrate their people onto, for the multi-generational voyage to another galaxy through hyperspace. |
| Exploration | Assemble the mysterious pieces of an ancient artifact known as the Orb of Chullack, which opens a giant space gate sending the ship to another dimension where the collapse never happened. |
| Collection | Amass enough wealth and upgrades to prepare the colony ship to slingshot around the collapse, which distorts space and time and flings it to another galaxy. |
| ??? (secret) | Fly into the collapse. Ships take significant damage or are destroyed. Once 3 beacons deep, escape becomes impossible, but they can meet a mysterious hostile alien race that seems to live in the collapse. About 8 or more jumps deep, they may find out this race is the cause of the collapse and destroy its command ship. Where the race comes from is probably never explained. The colony ship is not taken into the collapse. |

### ??? victory, alternate version (2026-10-21)

Getting powerful enough to survive inside the collapse requires getting nearly to the rim, then becoming powerful
enough to enter the collapse and travel back to the core.

Problem: what are you jumping between if all the star systems have collapsed? Options (can be combined, e.g.
remnants near the edge, alien structures deeper in):

1. **Frozen remnants:** near a black hole time slows dramatically, so things falling in appear frozen at the
   moment they fell. Swallowed star systems remain as distorted, frozen echoes: wrecks, stalled fleets,
   half-crushed planets.
2. **The aliens' own structures:** the hostile race lives in the collapse, so its stations, gates and waypoints
   are the nodes. Following its infrastructure leads to its command ship.
3. **Pockets of stable space:** bubbles or eddies where space hasn't fully collapsed yet.

Run length: rim and back would be very long. If space inside the collapse is compressed, each jump covers a huge
distance, so the way back is short, but every jump does damage (attrition).

### Default final enemy (2026-10-21)

The stage 7 rival who wants your escape route could by default be a band of doomed, criminal Terrans (Gatos).

## Resources

### Material and Energy (2026-10-21) — superseded by Mawjig (GDD 8C)

Instead of FTL's scrap, missiles and drone parts, two resources: **Material** and **Energy**. Basic systems
consume little to no energy beyond whatever energy they gain; powerful energy weapons consume energy; missiles
consume material. (Keeping scrap is also acceptable.)

## Races

When races are discussed, separate two layers:

- **Crew traits:** what one crew member can do, as in FTL (Mantis fight well, Engi repair fast).
- **Faction behaviour:** how that race's ships and factions act in events and encounters.

### Crew sex (2026-10-21)

The Tech victory (one male and one female crew member of your core race) would make crew sex a real gameplay
attribute, which FTL mostly lacks.

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

### Crew skills (2026-10-21)

Better normalize skill gain requirements and increments than FTL does (in FTL, the experience needed and the
bonus per level vary between skills).

### HalfMechs description setting (2026-10-23)

**Unlikely (2026-10-23):** a setting for how the Mecha (HalfMechs) are described outside their suits:
`HalfMechs: Enhanced Underdeveloped but Attractive Adult Bodies > Disgusting little Snot Nosed Twerps`.

## Ships

### Ship interior art (2026-10-23)

- **Proposed (2026-10-23):** Terran power conduits, when not broken, either vanish when the ship isn't selected, or
  are drawn as metal conduits that blend into the floor unless broken. Mocked up in the Outrider's floor layout
  test 4 (`docs/art/terran/outrider/floor-layout-tests/test-4/`): glowing when selected, metal when not.
- **Proposed (2026-10-23):** the system symbols are fine for now, but final art may make systems look more like
  computers, terminals or small machines (like the power core). A system is two things: a nice blended graphic,
  and a small symbol on that graphic in one of the ship's colours. Tried in floor layout test 4 as a pale wall desk
  with the symbol on its screen in the ship's blue.

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
- Variant: the **EVB Dock** (Extra Vehicular Battle Dock, from the Mecha): battle EVA suits that need a
  battlesuit type, like a drone bay needs a drone type, and likely cost material to launch. Any race can use one
  if acquired.
  - **EVB cost (2026-10-22):** a suit has an oxygen timer. The timer and the suit's weapon type set the maximum
    shots per sortie (travel there, shots, travel back), and the Mawjig cost per suit follows from that, e.g. a
    laser suit with 10 shots ≈ 10 × 0.02 = 0.21. Farther targets leave fewer shots; a higher dock level means more
    oxygen, so more shots and a pricier launch. Possibly paid up front per launch, like loading a magazine.

## Weapons

### Multi-room targeting lasers (2026-10-21)

Multi-shot lasers (like FTL's dual laser) that can aim each shot at a different room, unlike FTL, where every
shot from one weapon goes to the same target room.

- Possibly targeting rooms on different ships in the enemy squad too, to decide.
- Could be an optional setting: `Multi Target Lasers: On > Off` (default first), so players can keep FTL's behaviour.

### Point-defense laser (2026-10-21)

**Unlikely (2026-10-23):** an actual defence laser system that shoots down incoming missiles, like a defence drone
but without needing to be a drone. The Tentauri Defense Laser (`ship-suggestions.md`) does this as a weapon
instead.

### Weapon direction (2026-10-22)

FTL's weapons have no real problems; the plan is to scrap drones, customize per race, theme weapons around each
race, and expand rather than replace. Crystal weapons need to change. Weapon costs use Mawjig (GDD 8C), which
replaced Material and Energy. Don't keep FTL's names; some weapons could have biological names.

New weapon ideas:

- **Multi-target lasers** (above).
- **Rapid single-room beam:** hits a single room multiple times with a slight delay; similar to a laser but
  without pausing between hits.
- **Ship-to-ship sweeping beam:** sweeps from one enemy ship to another.
- **Frequency-shifting lasers:** alternate their frequency for a percentage chance to bypass a shield, at the cost
  of charging slower or taking more power.
