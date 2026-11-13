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
| Move selected crew | Right click a tile (left click too with Mouse Control's second choice): the first goes to that tile, the rest to free tiles in its room | A / Cross |
| Step back | Esc, or click on nothing: aiming stops, then the crew are let go, then the ship, then (Esc) the menu. With Mouse Control's second choice, right click | B / Circle |
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
| Map and jump | J or JUMP (the Admiral jumps) | |
| Player setup: players, inputs, who commands what, LAN | P or the players button by the menu | View / Select |
| Join as another player | | Start on a new controller |
| Ship screen (upgrades, weapons, crew) | U or SHIP | |
| Give a system power, or take it away | The system's key (in its tooltip: Shields A, Engines S, Weapons W, Medbay D, Life Support F, Cloaking H, Teleporter G), Shift with it to take away | |
| Open the inner doors, then the airlocks; close every door | Z, Z again; X | |
| Send and recall boarders; cloak; launch a battlesuit | T and R; C; B | |
| Crew back to their stations; look at the ship | Enter; Q | |
| Take an event's choice | Its number | |
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
  floor plan in their race's style (GDD 5K). Crew are drawn as the Art Style setting says (GV 7F): `Art Style: Top Down > Facing > Tokens`, top-down sprites, facing sprites or the round portrait tokens; a race with no sheet in the chosen style shows its token. The GATOS Species setting (Terrans > Tabbys) makes the GATOS humans or cats.
- **Sound:** every effect and the three music tracks are synthesized by `tools/make_audio.py`.

## Added on 2026-11-13 (the overnight plan)

What was built, how it was tested and what is left for heromedel is in `docs/handoffs/overnight-report-2026-11-13.md`;
the points are in `docs/godot-version-decisions.md` (GV 2D, 3K, 4K, 5B, 5C, 7G–7J, 8D, 8E, 14H, 14I). In short:

- Consoles drawn from the art sessions' art, crew fights as the genre has them, deaths played, the Tabby's sheet.
- Ship status cards, Player Power Color, enemy Terrans in pirate orange, damaged systems red, system power keys.
- Fire spreads through doors only; Open Doors pressed twice vents; the reticle replaces the arrow while aiming.
- Lykario Animal Senses; the Tentauri reach; Abandoned clusters without a store; the Medbay rule on purchases.
- New from the docs: the Pirate Pickpocket, Lykario Scrap Hound, Malphen Polyp and Azurethea Vein Moth.
- Co-op: six players on one screen, remembered assignments, a LAN fix for joining mid-jump, and wider tests
  (`tools/lan_run_test.sh`, `CHAOS_PLAYERS=2 tools/chaos.sh`).
- Beams deal damage again (they had not since tile targeting).
- After heromedel's answers the next morning: keys as the genre has them and number keys for event choices; each
  status card folds on its own; Specific Power Color with every species' colour and a picker; `Shield Levels: By
  Bar > By Layer` (By Layer makes a shield level a whole layer, GDD 8H); a two-ship first Malphen squad and the
  GATOS Scrappers; a dock goes at an airlock (GDD 5D).

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
- **Numbers the docs leave open:** layer recharge 2 s, crew 2.2 tiles a second, repair 12.5 s a bar, fire 10.4 s, 15 crew damage a
  point of hull damage, the Supershield regrowing a layer every 20, 15 or 10 s, teleporter cooldowns 20/15/10 s,
  suit sorties of about 30 s.

## Playing together (GV 4)

The game always runs as a server with its players as clients, also alone. Controllers on the same computer join with
Start and get their own view of the screen (left and right for two, quarters for three or four; Local Co-op View:
Split > Shared). Over LAN, the host opens the game in the Players menu and others join with the host's IP address,
at any time. The host is the Admiral and makes the squad's decisions. In Player setup the Admiral gives each ship
and crew member to Any player or to chosen players; any player can change their input or leave. What a player
commanded when they left is remembered, and the Admiral can restore it when they return (GDD 4F). Up to six players
share a screen (three across and two down for five or six). The Admiral leaving pauses the game until they return.

## Not in this build yet

- The vote and lock-in multiplayer settings, and player profiles (GV 4G).
- The Tech victory and other victory paths (ideas); the win is reaching the rim.
- Augments and drones (the design moves drones into EVB suits and race systems).

## Crew art still to fill in (GV 7F)

The Art Style setting shows a token for any race with no sheet in the chosen style.

| Race | Top Down | Facing |
|---|---|---|
| GATOS as Terrans | The drifter | The drifter |
| GATOS as Tabbys | None | The Tabby crew sheet (`docs/art/terran/tabby-crew`), every animation |
| Mecha | The suit | The older crew sheet |
| Tentauri | None | The crew sheet, recoloured for each crew member's subtype |
| Azurethea, Malphen, Lykario, Senti-GPH | None | None |

- Every Terran is the same drifter until there are more designs.
- The Tentauri's token is cut from their Facing sheet, in the colours of the crew member's subtype (GV 7F). The
  other races' tokens are still drawn faces, and no other race has subtypes yet.
- A store's crew cards show the crew member as the Art Style setting draws them: sprite or token.
- Consoles are drawn from art (GV 7G): `content/consoles/<style>/` holds each style's `console.xml` and art (the
  wall desk, the Mecha tower, the Tentauri organs), brought over from `docs/art` by `tools/import_console_art.py`.
  A race names its style in its `race.xml` (`consoles="tower"`); one that names none gets the wall desk. The game
  draws the system's symbol on the console, in the colour of its state.
- A crew member standing at a console is drawn a few pixels back from its wall so the symbol stays in view
  (`stand_back` on a sheet's `<crew_art>`; drawing only). In the Facing style a console on the wall nearest the
  player is drawn over them.
- Crew fights (GV 7G): a tile holds one fighter from each side. Whoever walks into a room with foes goes onto a
  foe's tile and the two punch; a fighter alone on a tile stays put and shoots at one foe until that foe is dead or gone, turning on
  someone else only to fight back. A hit lands once a second. Send a
  crew member onto a foe's tile to punch, or to any other tile to shoot. `tools/crew_fight_test.tscn` checks the
  rules headless. A sheet's `<particles kind="shot" animation="aim" …/>` is the muzzle its shots leave from.
- No ring is drawn under a sprite. A health bar's colour says whose crew it is (green ours, red theirs); it shows
  in a room holding both sides, and on anyone hurt or selected. A selected sprite has a thin outline in the
  player's colour. Tokens are about 19 pixels across and keep their rim.
- The top-down drifter's death is a bad placeholder (heromedel, 2026-11-11), to be made again from scratch.
- A crew member who dies plays their sheet's death frames once where they stood, and the last frame fades; a
  token shrinks away. The top-down drifter's death frames are still the placeholder.
- The clone-bay rows are not used: the game has no clone bay. The HalfMech's clamp-on frames are not used either.
- A Tentauri working several systems at once is not drawn yet. The reach prototype
  (`docs/art/tentauri/crew/tentauri-reach-prototype.html`) draws the reaching tentacles live, a pair to each
  console, over a body sheet; the game is meant to draw them itself in the same way, not from sheet rows.
- When a sheet has no frames for what a crew member is doing, or none for the way they face (punching is only
  drawn toward and away from the camera), they stand and the small badge says what they are doing, as with tokens.
  A sheet with no teleport frames gets the tokens' glow and sparks.
- Stunned, healing and out of air have no frames: the small badges and sparks show them, as with tokens.
- Particles are the game's, not the sheets' (GV 7F): no sheet draws sparks, spray or a shooting flash. Each sheet's
  entry in its `race.xml` gives the point where they start (`<particles kind="sparks" animation="repair" …/>`,
  `<particles kind="spray" animation="fire" down="…" right="…" up="…"/>`). Repair sparks take the ship's power
  colour; extinguisher spray is white and pale blue. The game does not draw a crew member's shot yet.

## Tools

- `tools/check_content.tscn` lists the content and any problems in the XML.
- `tools/test_fight.tscn`, `tools/auto_run.tscn` (`RUNS=3`): headless fights and whole bot runs.
- `tools/flow_test.tscn`, `tools/input_test.tscn`, `tools/battle_view_test.tscn`, `tools/ship_gallery.tscn`:
  screenshots and simulated clicks (need a display, e.g. `xvfb-run`).
- `tools/compile_check.sh` rebuilds the script cache and prints script errors.
- `tools/make_audio.py` remakes the sounds and music.
- `tools/import_crew_art.py` copies the crew sprite sheets from `docs/art` into `content/races` and checks each
  against its layout in `content/crew-layouts.xml`. Run it after a sheet changes, then let Godot import the files.
  A sheet the game recolours for subtypes (the Tentauri's) is copied as its SVG and kept from Godot's importer
  (`importer="keep"` in its `.import` file), so the exported game still has its text.
- `tools/battle_view_test.tscn` takes `ART_STYLE` and `SPECIES` to set those two settings, and `ZOOM` (with
  `ZOOM_ENEMY`) for a close-up of a deck.
- The admin console: press the backtick key (`) in game; `help` lists its commands.
- Debug: run with `INFALL_SMOKE=1` to load the content, start a run and quit; `INFALL_SEED=<number>` fixes a new
  run's seed.
