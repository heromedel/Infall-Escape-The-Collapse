# Infall: Deck Collapse

A card battle prototype for Infall. Ship battles are played with cards. Every system and crew member adds cards to
your deck, and you fight an AI captain. Built with **Godot 4.3** (GDScript). Ships, systems, weapons and battlesuits
are XML files you can edit.

The rules follow the Deck Collapse GDD (https://claude.ai/artifact/TYK6VhpJkfsJu3gJmStWEy), with the genre as
the default where the GDD is silent.

## Play

- **Windows:** run `InfallDeckCollapse.exe`. It needs no install.
- **From source:** open this folder in Godot 4.3 and press Play (F5).

The flow is **Battle**: pick your ship and an enemy, then **FIGHT**.

- Click a card to play it. Aimed cards then need a glowing target. Right-click or Esc cancels.
- Click one of your crew, then a green system, to move them. Each crew member moves once per turn.
- **Space** or **END TURN** ends your turn. **Reroute Power** is available when you've played no cards this turn.
- Hover anything for details. **How to Play** in the main menu has the full rules.

## Ship Designer

Pick systems and levels, the reactor, weapons (kind, Type, name), EVB battlesuit types, hull, missiles and crew
(name, skill, starting station). The deck the design builds is shown live, with design points.

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
| Engine Burn | On > Off |
| Jump Escape | On > Off |
| Crew Fights | On > Off |
| Sensor Fog | On > Off |
| Enemy Captain | Normal > Easy > Hard |
| First Turn | Coin Flip > You > Enemy |
| Animation Speed | Normal > Fast > Slow |
| Sound | On > Off |
| Designer Budget | Off > 60 Points > 80 Points |

## Rules this prototype fills in

These are gaps in the GDD, filled with the genre in mind. Each one is a setting or an XML value.

- **Engine Burn:** spend 1 power on Engines for +5% evasion until your next turn, up to the Engines level (GDD C11, Proposed).
- **Jump Escape:** Spool Jump Drive cards (GDD C12) build charges, and at 3 charges you jump away.
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
| `data/ships/*.xml` | Built-in ships |
| `scripts/main.gd` | The game flow, top to bottom |
| `scripts/core/` | Rules (`battle.gd`), enemy AI (`battle_ai.gd`), cards, ships, settings, XML loading |
| `scripts/ui/` | Screens, cards, system tiles, effects |
| `scripts/audio/sound_bank.gd` | Sound effects, synthesized at start-up |
| `tools/` | Headless tests: AI vs AI balance (`simulate.tscn`), one logged battle (`one_battle.tscn`), the human click path (`ui_test.tscn`), card gallery screenshot |

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
