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

Pick systems and levels, the reactor, weapons (kind, Type, name), EVB battlesuit types, hull, missiles and crew
(name, starting station, and six skills). The deck the design builds is shown live, with the ship's worth in Mawjig:
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
- **Repair (heromedel):** one Repair card fixes one thing, in order: fire, breach, then damage (a repair Veteran fixes 2
  damage). The repairer stays in that system for the rest of the turn. No repairs in a system with enemies in it.
  Other crew can still move once after acting, and man the system they move to. Extinguish Fire is gone.
- **Air (heromedel):** each Life Support level holds 1 pip of air. While Life Support is broken or offline, each turn
  uses a pip; once the air is gone, everyone aboard takes a wound each turn. Working Life Support refills a pip each
  turn; Restore Environment refills one, even while Life Support is down.
- **Broken systems (heromedel):** a broken system's cards can't be drawn; they stay in the deck until it is repaired.
- **Crew hits:** each point of damage to a system has a 25% chance to wound each crew member inside.
- **Airlock Control (as Doors):** boarders need 0/0/1/2/3 turns to move from one system to another at Airlock Control
  level 0–4 (level 1 doesn't slow them). Teleporting and venting aren't slowed. Each level slows fire spreading.
  Cycle Airlock needs a working Airlock Control, not crew.
- **Fire:** spreads to the neighbouring tile, burns out when its system is broken, may choke out once the air is gone.
- **Mawjig (docs/reference):** a wreck pays 2.5% of its value (+30% for killing the crew); a jump costs 1.21; hull
  repair 0.48 a point; missiles 1.45; crew 10.89.
- **Stations (heromedel):** the stop between battles has a station 1 in 5–10 stops (`rules.xml` station). A station
  always sells hull repair, missiles and suit parts, plus 2 random sections of 3 from systems, weapons, battlesuits
  and crew (genre). Weapons and battlesuits sell for half (genre). A bought weapon comes with its own weapon system at
  its Type, up to 4; otherwise it goes to the 4-slot cargo hold, which adds no cards and can be swapped at any stop.
  Upgrades raise systems and the reactor by the `systems.xml` step prices, with Undo until you leave. Store crew
  are named from `data/names/` (Federation-Home-Planet's name-list format): cat names with Cat Faces, human names
  with Plain Tokens. The run changes its own copy of the ship, never the saved design.
- **Crew Fights:** boarders and defenders in the same system trade 1 wound each at the end of the turn.
- **Crew act once per turn:** each crew member can do one crew card per turn.
- **Reactor hits:** ion and Hack on a Reactor knock one Power Cell loose (GDD C6) instead of shutting it down.
- **Evasion:** 5% per working Engines level, plus a few percent for a pilot and an engineer by skill. It needs
  Piloting manned, or Auto Pilot at level 2 or 3 (GDD C12).
- **Cloak** adds +40% evasion until your next turn (GDD C14).
- **EVB battlesuits** replace drones (GDD C8, C9). Each dock holds one suit type from `data/suits.xml`: assault,
  ion, cutter, guardian (shoots down torpedoes), repair and boarding.

## Ships

The built-in ships are renamed versions of the genre's starting cruisers (all hull 30) and some of its enemy
templates (hull 9–14), translated into Infall systems:

- Reactor level = starting power.
- A shield level = one layer.
- Each weapon is its own weapon system, and its Type is its power cost.
- Airlock Control replaces doors and the EVB Dock replaces drones.

They're in `data/ships/` and are meant to be edited.

## Files

| Path | What it is |
|---|---|
| `data/systems.xml` | Every system: its card, cards per level, design points, level limits |
| `data/weapons.xml` | Weapon kinds and what each Type does |
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
- EVB battlesuits (and an EVA system) could make crew immune to breaches and low air until the suit's air runs out.
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

## Export

```bash
godot --headless --path . --export-release "Windows Desktop" build/windows/InfallDeckCollapse.exe
```
