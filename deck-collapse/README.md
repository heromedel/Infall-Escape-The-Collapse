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
and heal, spool the jump drive and **JUMP**. **Continue Run** then takes the same ship, as it was left, to the
store and on to a random enemy.

- Click a card to play it. Aimed cards then need a glowing target. Right-click or Esc cancels.
- Click one of your crew, then a green system, to move them. Each crew member moves once per turn.
- **Space** or **END TURN** ends your turn. **Reroute Power** is available when you've played no cards this turn.
- Hover anything for details. Hover a crew member to see their skills. **How to Play** in the main menu has the full rules.
- Every battle writes a log (two lines per entry: machine, then readable) to
  `%APPDATA%\Godot\app_userdata\Infall- Deck Collapse\logs`. Settings has an **Open Logs Folder** button.

## Ship Designer

Pick systems and levels, the reactor, weapons (kind, Type, name), EVB battlesuit types, hull, missiles and crew
(name, starting station, and six skills). The deck the design builds is shown live, with the ship's worth in Mawjig:
systems, reactor bars, weapons and suits priced from `docs/reference`, plus crew and missiles.

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
| Engine Efficiency | Classic > Extra Burn |
| Auto Burn | On > Off |
| Jump Escape | On > Off |
| Crew Fights | On > Off |
| Sensor Fog | On > Off |
| Enemy Captain | Normal > Easy > Hard |
| First Turn | Coin Flip > You > Enemy |
| Animation Speed | Normal > Fast > Slow |
| Sound | On > Off |
| Designer Budget | Off > 200 Mawjig > 250 Mawjig > 300 Mawjig |

## Rules this prototype fills in

These are gaps in the GDD, filled with the genre in mind. Each one is a setting or an XML value.

- **Engines (heromedel):** in Classic, Engines give 0% evasion until power is burned in them, then the genre's
  evasion for that many levels (5, 10, 15, 20, 25, 28, 31, 35%). Pilot and engineer bonuses (5/7/10% by skill) count
  only while they run. Auto Burn sends unspent power to Engines when you end your turn.
- **Jump (heromedel):** Engines and Piloting each add 1 Spool Jump Drive per level; 6 charges to jump; needs Piloting
  working and manned or at Auto Pilot. Jump Escape: On allows jumping away mid-battle.
- **Aftermath (heromedel):** after the enemy is beaten you keep playing until you jump; everything carries over.
- **Crew skills (genre):** six skills, untrained, Veteran or Master. Manned Shields, weapons and Engines may draw an
  extra card of their own each turn (10/15/20%); crew in damaged or burning systems may draw Repair or Extinguish.
  Manned Sensors and Airlock Control work a level higher.
- **Crew hits:** each point of damage to a system has a 25% chance to wound each crew member inside.
- **Airlock Control (as Doors):** each level slows boarders leaving a system by a turn and slows fire spreading.
- **Fire:** spreads to the neighbouring tile, burns out when its system is broken, may choke out without air.
- **Mawjig (docs/reference):** a wreck pays 2.5% of its value (+30% for killing the crew); a jump costs 1.21; hull
  repair 0.48 a point; missiles 1.45; crew 10.89.
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
| `tools/` | Headless tests: AI vs AI balance (`simulate.tscn`), one logged battle (`one_battle.tscn`), the human click path (`ui_test.tscn`), card gallery screenshot |

## Planned (from discussion)

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

## Export

```bash
godot --headless --path . --export-release "Windows Desktop" build/windows/InfallDeckCollapse.exe
```
