# Infall: Deck Collapse

A card battle prototype for Infall. Ship battles are played with cards. Every system and crew member adds cards to
your deck, and you fight an AI captain. Built with **Godot 4.3** (GDScript). Ships, systems, weapons and battlesuits
are XML files you can edit.

The rules follow the Deck Collapse GDD (https://claude.ai/artifact/TYK6VhpJkfsJu3gJmStWEy), with the genre as
the default where the GDD is silent.

## Play

- **Windows:** run `InfallDeckCollapse.exe`. It needs no install.
- **From source:** open this folder in Godot 4.3 and press Play (F5).

The flow is **Battle**: pick your ship and an enemy, then **FIGHT**. When the enemy is beaten, keep playing to repair
and heal, then **JUMP**. **Continue Run** then takes the same ship, as it was left, to a stop between
battles (sometimes a station with a store) and on to a random enemy.

- Click a card to play it. Aimed cards then need a glowing target. Right-click or Esc cancels.
- Click one of your crew, then a green system, to move them. Each crew member moves once per turn.
- **Space** or **END TURN** ends your turn. **Reroute Power** is available when you've played no cards this turn.
- Hover anything for details. Hover a crew member to see their skills. A crew member with a wrench badge repaired this
  turn and stays where they are. **How to Play** in the main menu has the full rules.
- Every battle writes a log (two lines per entry: machine, then readable) to
  `%APPDATA%\Godot\app_userdata\Infall- Deck Collapse\logs`. Settings has an **Open Logs Folder** button.

## Ship Designer

Pick systems and levels, the reactor, weapons, EVB battlesuit types, hull, missiles and crew (name, starting
station, and six skills). A weapon system holds up to 4 weapons: pick premade ones or **Design a weapon…** from its
parts (kind, power, shots, damage, speed, specials), seeing its price and cards as you go. The deck the design builds is shown live, with the ship's worth in Mawjig:
systems, reactor bars, weapons and suits priced from `docs/reference`, plus crew and missiles.

- Parts of a ship file the game doesn't support yet (unknown systems, floor plans and so on) are listed in the
  designer and the battle log with the notes and GDD references left on them. They're kept when the file is saved and
  ignored in battle.
- **Save to My Ships** writes the design to your ships folder, and it appears in the ship lists.
- **Export XML…** and **Import XML…** read and write ship files anywhere. **Copy XML** puts the file on the clipboard.
- The ships folder on Windows is `%APPDATA%\Godot\app_userdata\Infall- Deck Collapse\ships`.
  The designer shows the exact path and has an **Open My Ships Folder** button.

## Settings (default first)

| Setting | Choices |
|---|---|
| Cards Drawn Per Turn | 1 > 2 |
| Opening Hand Power | Random > 2 Guaranteed |
| Hull Scale | Ship Value > 75% > 50% > 150% |
| Ammo | All Use Mawjig > Classic > Limited Missiles Only > Missiles Use Mawjig |
| Engine Efficiency | Classic > Extra Burn |
| Auto Burn | On > Off |
| Jump Escape | On > Off |
| Multi Target Lasers | On > Off |
| EVB Refund | No > Yes |
| Crew Toughness | Default 10 > Tough 12 > Weak 8 |
| Crew Fights | On > Off |
| Sensor Fog | On > Off |
| Enemy Captain | Normal > Easy > Hard |
| First Turn | Coin Flip > You > Enemy |
| Crew Portraits | Cat Faces > Plain Tokens |
| Animation Speed | Normal > Fast > Slow |
| Sound | On > Off |
| Station Frequency | 1 in 5-10 > Every Stop |
| Upgrade at Stations Only | On > Off |
| Store System Repair | Off > On |
| Designer Budget | Off > 200 Mawjig > 250 Mawjig > 300 Mawjig |

## Rules this prototype fills in

These are gaps in the GDD, filled with the genre in mind. Each one is a setting or an XML value.

- **Engines (heromedel):** in Classic, Engines give 0% evasion until power is burned in them, then the genre's
  evasion for that many levels (5, 10, 15, 20, 25, 28, 31, 35%). Pilot and engineer bonuses (5/7/10% by skill) count
  only while they run. Auto Burn sends unspent power to Engines when you end your turn.
- **Jump (heromedel):** at the end of each turn you burn at least 1 power in Engines, the Jig Drive gains a charge per
  working Engines level, if Engines and Piloting work. 24 charges to jump. Jumping needs Piloting working and manned
  or at Auto Pilot. Jump Escape: On allows jumping away mid-battle.
- **Aftermath (heromedel):** after the enemy is beaten you keep playing until you jump; everything carries over.
  With no enemy left the Jig Drive charges at once if Engines and Piloting work, as in the genre.
- **Ammo (heromedel):** by default every volley and battlesuit launch costs Mawjig (`mawjig-cost-table.md`), for
  enemies too. A run starts with 12.11 (GDD 8K, Proposed). An enemy carries its own wreck reward (2.5% of its value)
  to pay for its shots; unspent Mawjig isn't added to salvage (economy-findings F11). Classic ammo uses missile and battlesuit-part stocks instead.
- **Crew XP (GDD 7H):** 100 XP to Veteran, 150 more to Master; 6.7 per dodge, 1.8 per shield layer popped, 1.5 per
  volley, 5.6 per point repaired, 12.5 per crew fight. XP carries through a run.
- **Crew skills (genre):** six skills, untrained, Veteran or Master. 10/15/20% (by skill) is the standard crew chance
  to draw an extra card: manned Shields and weapons draw one of their own, and crew in a damaged, breached or burning
  system may draw a Repair. Crew evasion is 5/7/10%. Manned Sensors and Airlock Control work a level higher.
- **Shields (heromedel):** may draw an extra Raise Shield each turn even unmanned, 10% per working level, plus the crew
  chance when manned.
- **Weapons (Infall docs, heromedel):** each weapon is its own entry (`data/weapons.xml`): kind (laser, flak, ion,
  missile, beam), power, shots, damage, speed, rooms swept for beams, and specials (multi-target, fire, breach,
  pierce, chain, defensive, spores, stun, mind control). A weapon adds **speed** cards to the deck (36 ÷ its
  weapon-budget-table cooldown by default; fixed once made). Price comes from `weapon-budget-table.md`, Mawjig per
  card from `mawjig-cost-table.md`. A weapon system holds up to 4 weapons; its level is the power they can use a
  turn. Genre-style ships carry genre-style weapons (single-target lasers, sweeping beams); Infall weapons come from
  Ship Design's ships, plus a few new ones marked in the file.
- **Repair (heromedel):** one Repair card fixes one thing, in order: fire, breach, spores, then 1 damage. Repair skill
  only makes Repair cards come more often. The repairer stays in that system for the rest of the turn. No repairs
  in a system with enemies in it. Other crew can still move once after acting, and man the system they move to.
- **Air (heromedel):** each system holds up to Life Support's level in air pips (bubbles down its tile's left edge).
  Working Life Support adds a pip to every unbreached system as your turn starts; while it is down, every system
  loses one as your turn ends. Breached and vented systems have none. Crew in a system with no air take a wound as
  the turn ends. Restore Environment adds a pip to every unbreached system, only while Life Support works. A ship
  crewed only by races that don't breathe (Senti) needs no Life Support.
- **Teleport (heromedel):** one card: click your Teleport Bay, then any system on either ship, and everyone of yours
  in the bay goes there; or click another system, and your crew there come back to the bay.
- **EVB Dock (heromedel):** holds up to 4 suit types, like a weapon system holds weapons; each adds Launch cards by
  its speed. Its level is the power it can spend on launches each turn, and a suit's turns of air: level + 1.
  A crew member in the dock flies out in the suit, which drifts beside a random enemy system each turn and acts
  there (guardian and repair suits stay home). When its air is gone, its pilot takes a wound each turn until you
  recall it (click it, then RECALL; it docks as the turn ends). The first hit damages a suit and wounds its pilot:
  it can't act and heads home; a second hit destroys it and its pilot (race-profiles.md, Mecha, Likely). Bolts
  fired from the weapon a suit is beside, and your own misses at the system it's beside, may hit it (15%);
  guardian suits shoot enemy suits (50%). A launch pays Mawjig for every shot over its turns. EVB Refund: Yes pays
  back unused turns. A pilot out in a suit is in no room, so breaches, low air and fire can't reach them while the
  suit has air.
- **Bombs (genre; mawjig-cost-table.md):** teleported into a system: they ignore shields and evasion, can't be shot
  down, and damage the system but not the hull. A missile each with Classic ammo; 0.05 Mawjig each plus effects.
- **Crew damage (Ship Design's G20):** a weapon's `crewDamage` costs every crew member in a hit system that many
  pips on top of its damage; a beam with no damage (the genre's anti-bio beam) is stopped by any shield layer.
- **Beams (Infall docs: rooms swept):** a beam sweeps its rooms in a row, left or right of the aimed system as the
  captain picks. Shield layers cut its damage and stay up, as in the genre.
- **Multi Target Lasers (docs/ideas.md, heromedel):** a special of some lasers; with the setting On (default) each of
  their shots can aim at its own system, Off they fire like ordinary lasers.
- **Broken systems (heromedel):** a broken system's cards can't be drawn; they stay in the deck until it is repaired.
- **Crew health (heromedel):** crew have health pips: Crew Toughness (Default 10, Tough 12, Weak 8) × their race's
  health ÷ 100, rounded down (`data/races.xml`): Terran/GATOS, Tentauri, Whispwraith 10; Azurethea, Lykario 7;
  Senti 5; Mecha 12; Malphen 15. Damage in pips (`rules.xml` crewDamage): every crew member in a hit system loses 1
  per point of damage (as in the genre, no roll); no air 1 a turn; fire 1 per fire pip a turn; crew-fight hits 2 ×
  the race's attack; Treat heals 1 per Med Bay level.
- **Races (race-profiles.md point 9, heromedel):** Mecha have 125% health and attack and move at most 3 systems at
  a time; Lykario strike first in a fight (an enemy they kill deals them no damage); Senti are immune to fire and
  need no air. Pick a crew member's race in the designer.
- **Airlock Control (as Doors):** boarders need 0/0/1/2/3 turns to move from one system to another at Airlock Control
  level 0–4 (level 1 doesn't slow them). Teleporting and venting aren't slowed. Each level slows fire spreading.
  Airlock Control adds 3 Cycle Airlock cards, plus 1 per level above 1. Cycle Airlock costs 1 power and needs a
  working Airlock Control, not crew: the fire goes out, the air is gone, and everyone inside takes a wound.
- **Fire (heromedel):** a fire has 1–4 pips and grows a pip each turn. Each turn it hurts everyone inside 1 pip per
  fire pip, damages its system by 1 and uses half its pips (rounded down) of the system's air; it goes out when the
  air is gone (breaches and venting take it all) or the system is broken. A Repair puts out 2 fire pips. It may
  spread to the system beside it as a 1-pip fire.
- **Mawjig (docs/reference):** a wreck pays 2.5% of its value (+30% for killing the crew) times the band
  adjustment, x1.0 in band 1 rising 0.1 a band to x1.7 in band 8 (mawjig-cost-table.md, Fight rewards; economy-findings
  F1); an enemy's purse rises the same way. A jump costs 1.21; hull repair 0.48 a point; missiles 1.45; crew 10.89.
- **Weapon prices (weapon-budget-table.md):** power, plus damage and effects over the weapon's exact cooldown; a
  weapon given more or fewer cards than its cooldown suggests is priced as that much faster or slower.
- **Weapon rarity (genre):** each weapon has a rarity, 1 common to 5 rare (0: never in stores at random). A store
  picks its weapons weighted 5, 4, 3, 2, 1 by rarity (`rules.xml` rarity; the weights and the weapons' rarities are
  Ai-Generated-Proposal).
- **Beacons and bands (heromedel):** after a battle, and with each JUMP (1.21 Mawjig), you reach a beacon: half the
  time an event (`data/events.xml`, by Infall: Lori), otherwise a hostile ship to fight. Some events lead to a
  fight; the others leave you at a quiet beacon to jump on. The difficulty band rises every 10 jumps (GDD: about 8
  bands, each about 10 clusters deep); enemies come from ships allowed in the band (`bands="1-3"` on a ship),
  stations only stock weapons allowed in it (`bands` on a weapon: new ideas like multi-target lasers start at band
  2), and hull repair costs 0.48, 0.73 or 0.97 a point by band (mawjig-cost-table.md). Ship and weapon band ranges
  are Ai-Generated-Proposal.
- **Stations (heromedel):** a beacon has a station 1 in 5–10 jumps (`rules.xml` station). A station
- **Crew Fights:** boarders and defenders in the same system trade blows at the end of the turn.
- **Mind control (heromedel):** the Mind Control card holds a mind for the system's level + 1 turns; a mind-control
  weapon for its weapon system's level.
- **Crew act once per turn:** each crew member can do one crew card per turn.
- **Med Bay (heromedel):** TREAT on its tile costs 1 power; as the turn ends, everyone in it heals by its level.
- **Reactor hits:** ion and Hack on a Reactor knock one Power Cell loose (GDD C6) instead of shutting it down.
- **Evasion:** 5% per working Engines level, plus a few percent for a pilot and an engineer by skill. It needs
  Piloting manned, or Auto Pilot at level 2 or 3 (GDD C12).
- **Cloak** adds +40% evasion until your next turn (GDD C14).
- **EVB battlesuits** replace drones (GDD C8, C9). Suit types are in `data/suits.xml`: assault, laser, ion, cutter,
  guardian, repair and boarding.

## Ships

The built-in ships are renamed versions of the genre's starting cruisers (all hull 30) and some of its enemy
templates (hull 9–14), translated into Infall systems:

- Reactor level = starting power.
- A shield level = one layer.
- One weapon system holding the ship's weapons, its level the power they had.
- Airlock Control replaces doors and the EVB Dock replaces drones.

The `infall-*.xml` ships are Ship Design's, one per race (`docs/deck-collapse-ships` on Cloud-C-ShipDesign,
Ai-Generated-Proposal). The game reads their weapons as written; their power runs as a plain reactor for now (G2; an AZC is 5 bars per level),
and the parts it doesn't have yet (Supershield, growth organ, servicing core, AAA, floor plans …) are kept and
listed with their gap numbers.

**Captain plans** (heromedel 2026-10-30): an `<ai plan="destroy|crew-kill">` section in a ship file, with lines of
four kinds, each tried in order:

| Line | When it's used | Limited to |
|---|---|---|
| `<target system when unless weapon weight/>` | aiming a weapon | `weapon`: that weapon, by name |
| `<suit system when unless suit weight/>` | launching a battlesuit: it goes there and stays while the system works (G22) | `suit`: that suit type |
| `<board system when unless weight/>` | teleporting boarders (G23) | |
| `<hack system when unless weight/>` | hacking (G24) | |

A line whose `when` holds and whose `unless` doesn't rolls its weight, and on a success the captain uses its system.
Conditions: `always`, `enemyWeaponsDown`, `enemyShieldsDown`, `enemyMedBayDown`, `enemyLifeSupportDown` (G25; a ship
without the system counts it as down), `enemyWounded`, `ownBoardersAboard` (G26), `ownCrewIn` (our crew are in the
line's system, G27). Weight defaults to 0.75 (followed 3 times in 4), can't go above 0.9, and Easy captains halve it
while Hard add 0.1. A failed roll only means the captain chooses as usual. A crew-kill plan also aims at rooms with
crew and hacks the Med Bay first. Every Infall ship has Ship Design's plan (Cloud-C-ShipDesign, 2026-10-30). With a
Teleport card in hand, an AI keeps a boarder in its Teleport Bay until two are across.

**Loadouts** (GDD 5J; Ship Design's G18): a `<loadout ship="…">` file patches a ship already loaded: its attributes
replace the ship's, `<power>` replaces the power, each `<system>` matches by id (else type) and changes it or is
added (`removed="true"` drops it), and `<crew>` with `<member>`s replaces the crew whole. The Pickpocket, Cutpurse,
Light Attack Frame (Suit Dock), Polyp (Flak), Pappus (of the Burr) and Scrap Hound (of the SC-1 Outrider) are loadouts.

They're in `data/ships/` and are meant to be edited.

## Files

| Path | What it is |
|---|---|
| `data/systems.xml` | Every system: its card, cards per level, design points, level limits |
| `data/weapons.xml` | Weapon families and every weapon (power, shots, damage, speed, specials, rarity, bands) |
| `data/races.xml` | Crew races: health, attack and traits |
| `data/events.xml` | Events at beacons |
| `data/suits.xml` | EVB battlesuit types |
| `data/rules.xml` | Jump charges, crew draw and hit chances, fire, airlock and economy numbers |
| `data/ships/*.xml` | Built-in ships |
| `scripts/main.gd` | The game flow, top to bottom |
| `scripts/core/` | Rules (`battle.gd`), enemy AI (`battle_ai.gd`), cards, ships, settings, XML loading |
| `scripts/ui/` | Screens, cards, system tiles, effects |
| `scripts/audio/sound_bank.gd` | Sound effects, synthesized at start-up |
| `data/names/*.xml` | Crew names for hire, by race and style |
| `tools/` | Headless tests: AI vs AI balance (`simulate.tscn`), one logged battle (`one_battle.tscn`), the human click path (`ui_test.tscn`), stations, cargo and upgrades (`station_test.tscn`), card gallery screenshot |

## Planned (from discussion)

- Crew portraits use the GATOS cat concept (face C, Cloud-C-Art), a concept that isn't decided; the art rules still say the
  GATOS are human. The variants beyond face C are Ai-Generated-Proposal. Other races' faces later.
- An EVA system could make crew aboard immune to breaches and low air for a while, as suits already do.
- Augments: none are listed in the Infall docs yet. A Nano Machines style heal would fit the Malphen (suggestion).

- The designer could set the order systems sit in; later, floor plans, with systems laid out by the plan instead
  of in a row (fire spread and adjacency would follow the plan).

## Tests

```bash
godot --headless --path . res://tools/simulate.tscn -- battles=10
```

```bash
godot --headless --path . res://tools/one_battle.tscn -- a=0 b=1 seed=5
```

```bash
godot --path . -- start=battle player=Wayfarer enemy="Heavy Gunship" autoplay
```

```bash
godot --headless --path . res://tools/station_test.tscn
```

```bash
godot --path . -- start=station player=Wayfarer
```

```bash
godot --path . -- start=event event=2 player=Wayfarer
```

## Export

```bash
godot --headless --path . --export-release "Windows Desktop" build/windows/InfallDeckCollapse.exe
```
