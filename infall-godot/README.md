# Infall: Escape The Collapse — Godot version

A playable build of Infall made in **Godot 4.3** (GDScript), from the design docs in `docs/`. Mechanics follow the
genre unless the GDD says otherwise (GDD 1C). Ships, weapons, systems, races, squads and events are XML files in
`content/` that can be opened and changed (coding rule 4).

## Play

- **Windows:** run `Infall.exe` (one file, nothing to install).
- **From source:** open this folder in Godot 4.3 and press Play (F5). Or from a terminal: `godot --path .`

A run: lead the GATOS scout squad outward from the collapsing Galactic Core to the rim. Each cluster plays an
event; fights happen on the ship view; the map (Jump) picks the next cluster. Win by reaching **The Rim** and beating
the Last Fleet. Lose when every scout ship is gone (GDD 1F).

## Controls

| Action | Mouse and keys | Controller (Xbox / PlayStation) |
|---|---|---|
| Pause / unpause | Space | Click either stick (L3 / R3) |
| Select crew | Left click a crew token, or drag a box | X / Square |
| Move selected crew | Right click (or left click) a tile: the first goes to that tile, the rest to free tiles in its room | A / Cross |
| Deselect, cancel aiming | Right click, Esc | B / Circle |
| Aim a weapon | Click its slot (or 1–6), then click a tile of an enemy ship: the shot hits that tile and the system there, not the whole room | X on the slot, then on the tile |
| Aim a beam | Click its slot, then press on an enemy tile and drag: every tile it crosses is hit | |
| Fire once / autofire | Aim normally fires once (yellow mark); hold Ctrl to switch. V or AUTOFIRE flips the default (red mark) | |
| Power a system | Click its bars to add power, right click to remove. On the AZC (Terran conduit ships), click to switch a system on or off | |
| Power a weapon | Right click its slot | |
| Doors | Click a door; OPEN DOORS / CLOSE DOORS / VENT buttons | |
| Board, recall, launch suit, cloak | T (BOARD), RECALL, E (LAUNCH SUIT), C (CLOAK) | |
| Crew back to stations | Z | |
| Zoom | Mouse wheel | RT / R2 in, LT / L2 out |
| Pan | Middle drag, arrow keys | Right stick |
| Frame the whole fight | Home | |
| Move a HUD card | Drag its grab bar (the small tab on its top edge); drop it against another card's side to dock it. Right click the bar puts it back; the button beside it folds the card. Settings: HUD Layout, HUD Card Opacity, Reset HUD layout | |
| Fly to a ship | Double-click it, F for the selected ship, or click its status card | |
| Next squad ship | Tab | |
| Map and jump | J or JUMP | View / Select |
| Ship screen (upgrades, weapons, crew) | U or SHIP | |
| Menu | Esc | Menu / Start |

## What is in this build

- **Combat on fixed ticks** (20 a second, GDD 3E): power, shields (one layer per two bars), evasion, weapons that
  charge and fire volleys, lasers, missiles, flak, bombs, beams, ion, spores and stun, fire, breaches and air, hull
  bonus, pierce, infection (GDD 8G), crew that walk, man consoles, repair, fight, suffocate, heal and gain skills on
  GDD 7H's curve with each race's XP rate.
- **Three power models on one code path:** the reactor pool (Azurethea, Tentauri, Malphen, Lykario), the **Terran AZC
  with conduits** (any system joined to the AZC by unbroken conduits has power; the AZC's level sets how many
  power-hungry systems run at once; conduit hits cut runs and crew repair them; the Outrider's conduit wheel from
  `ship-suggestions.md`), and **Mecha self-powered systems** where an integrated HalfMech adds one bar.
- **Race systems and crews:** the Tentauri Supershield and Defense Lasers (shooting down missiles and suits), the
  Mecha EVB Dock with laser battlesuits, the Crew Teleporter, Cloaking, the Cybernetic Servicing Core. Crew traits by
  race: GATOS learn faster; Azurethea breathe out air and repair biomechanical tech fast; Mecha are tough and
  integrate; Tentauri run up to four systems in their room; Senti don't breathe or burn; Lykario are fast; Malphen
  mend.
- **Squads** (GDD 3): up to six ships a side in the curved formation of GDD 3H, player squad below the divider and
  enemy squad above it (3A), set to opposite sides of the wide screen so the gap reads as distance. Pan and zoom
  camera (3C). Each ship's hull and shields float beside it (3B).
- **The galaxy** (GDD 2): an open map of star clusters drawn as dot groups, in race regions with core, inner and
  border clusters; cluster states (Doing Fine, Struggling, Doomed, Border, Refugee, Occupied, Abandoned, Swallowed)
  recomputed every jump; the five-jump collapse opening (2P); the collapse growing a fixed distance per jump or wait
  (2S); sensors read clusters within range (2E); no dead ends (2F); 8 hidden difficulty bands.
- **Mawjig** (GDD 8C, 6B, 6C): one pool for the squad; every volley and every jump spends it; waiting gathers 0.25;
  fights pay 2.5% of each beaten ship's value times the band adjustment, 30% more when its crew were killed (8I).
- **79 events** in the events-sample.md form, with blue choices for crew races and systems; the collapse opening and
  GATOS store texts are Lori's, used as written.
- **Store, ship screen, hail, surrender offers, saves** (hand-readable JSON with the seed, coding rule 11), **run logs**
  (two lines per entry, coding rule 10) in the user data folder, settings with defaults first (GDD 1K), and starting
  ships that unlock as you get farther (GDD 7C).
- **Art:** the hull art from `docs/art/` (Outrider, Pirate Hijacker and Cutpurse, Mecha Light Attack Frame, Tentauri
  scout) and its weapon art, lined up to the ship files' floor plans. Ships without art get a hull drawn from their
  floor plan in their race's style (GDD 5K). Crew are portrait tokens; the GATOS are cats.
- **Sound:** every effect and the three music tracks are synthesized by `tools/make_audio.py`.

## Filled in from the genre or the lore (Ai-Generated-Proposals, 2026-10-31)

Where the design docs are silent, this build fills the gap with the genre's behaviour or extrapolates from the race
profiles, as heromedel asked. None of this is a design decision; each is a starting point to review. What still needs checking by Ship Designs,
Lori or Eco is listed in `docs/items-needing-second-opinion.md`.

- **New ships:** GATOS Patrol Cutter (and a Checkpoint loadout), Pirate Scrapper, Pirate Marauder (Hijacker bands
  7–8), Mecha Assault Frame and Siege Frame, Tentauri Seedpod and Chestnut, the Tentauri Pappus (the Burr's band 1
  loadout, from the docs), Azurethea Moth Skiff and Hawkmoth, Senti Beacon Picket and Archive Cruiser, Lykario
  Packrunner and Huntmaster, Malphen Cyst, Swollen Cyst and Tumour. Layouts, systems and crews are in their
  `ship.xml` files.
- **New weapons**, priced with `weapon-budget-table.md` and `mawjig-cost-table.md`: Gat 1.2 "Hammer", Gat M2
  "Longshot", Gat 5.1 "Hailstorm", Gat X1 "Breacher", Gat I1 "Static", Gat F3 "Scattergun", Mandible, Ocellus, Pollen
  Bomb, TS-ST Light Laser, SS-ST Breach Missile, HB-MR Hull Beam, Coil, Tendril Beam, Siphon, 3B 01 V2, 2L 02 V1,
  1L 02 P1, 2B 03 V1, Fang, Snarl, Sinew Flak (was Flesh Mortar), Gristle Missile.
- **Squads** for every race, with conduct (surrender and escape chances, preferred targets, how they answer a Hail).
- **Map generation:** the whole galaxy, a disc of four spiral arms around the core. The squad starts in GATOS space
  close enough to the core to head inward for a few jumps but not to be caught when the collapse appears (GDD 2P),
  and may go any way but through the core; reaching any cluster on the rim brings the final battle (heromedel,
  2026-10-31). Regions are placed at random; cluster contents (store, hostile, distress, neutral, items, hazard,
  nothing) by chance. The map screen has an overview of the whole galaxy.
- **Default conduits:** a core ship whose file lists none gets a branching network out from the AZC along the
  walkways; the conduit rule used is concerns.md item 3's last proposal (no rerouting action: a system has power if an
  unbroken path reaches the AZC).
- **The final battle:** the Last Fleet, a band of doomed GATOS at the rim (ideas: default final enemy).
- **Numbers the docs leave open:** layer recharge 2 s, crew 2.2 tiles a second, repair 5.5 s a bar, 15 crew damage a
  point of hull damage, the Supershield regrowing a layer every 20, 15 or 10 s, teleporter cooldowns 30/20/10 s,
  suit sorties of about 30 s.

## Not in this build yet

- LAN multiplayer and the multiplayer settings (GDD 4). The simulation runs on fixed ticks and takes orders, so it is
  ready for it, but there is no host or join yet.
- The Tech victory and other victory paths (ideas); the win is reaching the rim.
- Augments and drones (the design moves drones into EVB suits and race systems).

## Tools

- `tools/check_content.tscn` lists the content and any problems in the XML.
- `tools/test_fight.tscn`, `tools/auto_run.tscn` (`RUNS=3`): headless fights and whole bot runs.
- `tools/flow_test.tscn`, `tools/input_test.tscn`, `tools/battle_view_test.tscn`, `tools/ship_gallery.tscn`:
  screenshots and simulated clicks (need a display, e.g. `xvfb-run`).
- `tools/compile_check.sh` rebuilds the script cache and prints script errors.
- `tools/make_audio.py` remakes the sounds and music.
- The admin console: press the backtick key (`) in game; `help` lists its commands.
- Debug: run with `INFALL_SMOKE=1` to load the content, start a run and quit; `INFALL_SEED=<number>` fixes a new
  run's seed.
