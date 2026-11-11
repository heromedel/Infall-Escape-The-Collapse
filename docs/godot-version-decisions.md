# Godot Version: Working Decisions and Changes

An extension of the GDD (`docs/gdd.html`) for the Godot version of the game (`infall-godot/`, branch
`Cloud-C-Godot-Version`). It holds decisions and changes made while building this version that the GDD doesn't
have yet. Where a point here and the GDD disagree, this doc is the newer word for the Godot version, until the
point is moved into the GDD.

Sections are numbered as in the GDD and points lettered within each section. Cite a point as **GV** plus its number
and letter, e.g. GV 3A. Points are tagged as in `docs/tag-styles.md`, with heromedel's words setting the tag and
anything Claude added tagged Ai-Generated-Proposal.

## 2. The Collapse and Campaign Structure

- **A — Proposed (heromedel, 2026-10-31):** the map is the whole galaxy, open in every direction but through the
  core. The squad may head inward at first but can't get close enough in the opening jumps to be caught when the
  collapse appears. For now, reaching the rim anywhere brings the final battle and the win.
  - **Ai-Generated-Proposal (2026-10-31):** the galaxy is a disc of four spiral arms. The start is far enough from
    the core that four inward jumps can't reach the first horizon. The rim is the outermost ring, 260 map pixels
    deep. The map screen shows an overview of the whole galaxy.
- **B — Likely (heromedel, 2026-10-31):** on the map, Swallowed clusters are black, the legend's icons look like
  clusters, and each race region is one faint wash of colour rather than many circles, so the clusters stand out.
- **C — Decided (heromedel, 2026-10-31):** events don't speak of the collapse before it appears (GDD 2P).

## 3. Squad Combat

- **A — Decided (heromedel, 2026-10-31):** a hit lands on one tile: the system on that tile and the crew standing
  on it are hit, not the whole room; a beam hits only the tiles it passes through. Fires and breaches already
  harm the rest of the room. Moved into GDD 3L.
- **B — Decided (heromedel, 2026-10-31):** crew are ordered to a tile, not only to a room.
- **C — Likely (heromedel, 2026-10-31):** each ship sits centred in a square zone as big as the largest hull plus
  8 tiles. That is 30 tiles today: the largest genre hulls (the Lanius at 600 × 606 px, the Crystal Cruiser at
  721 px long) and our Pirate Hijacker (22 tiles long) all fit. A small ship sits far from its neighbours and
  from the barrier.
- **D — Likely (heromedel, 2026-10-31):** the barrier between the squads (GDD 3R) is at least 12 tiles deep.
- **E — Decided (heromedel, 2026-10-31):** the setting is called `Shots Crossing Barrier: Shown > Hidden`.
- **F — Proposed (heromedel, 2026-10-31):** space should feel vast; panning and zooming deal with the distance.
  - **Ai-Generated-Proposal (2026-10-31):** the camera frames the fight at the start and then moves only when the
    player moves it. Double-click a ship or press F to fly to it; Home frames everything. Ships out of view get an
    arrow at the screen's edge.
- **G — Likely (heromedel, 2026-10-31):** background planets are larger, look more distant and stay nearly still
  as the camera moves.
- **H — Ai-Generated-Proposal (2026-10-31):** as in the genre, power that damage or ion took from a system or a
  weapon comes back by itself once the bars work again. If the player has put that power elsewhere meanwhile, it
  stays where they put it. (Before this, weapons knocked off by a hit stayed off after the repair.)

- **I — Decided (heromedel, 2026-11-05):** the distance between the squads is real, not pretended. The battlefield
  is 16,000 pixels from squad to squad and 9,000 across, built lying down like a TV: the player's squad on the left,
  the enemy's on the right. The standard gap between the squads is about 5,000 pixels; battles further away get a
  wider one, and squads moving could later widen or close it. Shots fly the real distance at today's weapon speeds,
  so the flight time is real and the players can see it. It replaces the barrier strip (GV 3D), the slowing of shots
  inside it, the fixed 400 Gatometers and the `Shots Crossing Barrier` setting (GV 3E).
  - **Decided (heromedel, 2026-11-05):** each player's view shows their squad, the gap and the enemy's squad as one
    view under one camera that pans and zooms over it, as now. The gap is drawn squeezed 1:10 into a bar between the
    squads (the squads sit outside it): a minimap of the space between, with shots, missiles and battlesuits
    crossing it. The bar's size follows the gap's (5,000 pixels: a 500-pixel bar).
  - **Decided (heromedel, 2026-11-05):** Gatometers are the gap's real size, 1:1 with pixels, shown in thousands:
    a 5,000-pixel gap reads "5,000K Gatometers".
  - **Decided (heromedel, 2026-11-05):** the background is the real one: each part of the view shows the space
    behind it, so a planet can look big behind one squad, show in part in the bar and barely poke out behind the
    other. It stays generated (the shader), so its size costs nothing.
  - **Ai-Generated-Proposal (2026-11-05):** each squad's area is about 1,500 pixels deep (its zones and formation),
    with today's margin by the gap; the largest gap that fits is about 13,000 pixels (a 1,300-pixel bar). At
    today's speeds the standard gap takes a laser about 5.6 s, a missile about 8 s and a battlesuit about 14 s each
    way.
- **J — Decided (heromedel, 2026-11-05):** a setting, `Battlefield: Vertical > Horizontal`. The battlefield is built
  horizontal; Vertical, the default, shows it turned so the player's squad is at the bottom, as now. Text, crew
  portraits and symbols stay upright either way.
  - **Ai-Generated-Proposal (2026-11-05):** only the drawing turns, not the battle, so each player chooses their own,
    also over LAN.

## 4. Multiplayer

- **A — Decided (heromedel, 2026-11-01):** there is no separate single player: the game always runs a server that
  the player's client connects to, which readies it for LAN and keeps input and the simulation under one control.
  Playing alone is hosting with nobody joined. Built (`scripts/net/session.gd`).
  - **Ai-Generated-Proposal (2026-11-01):** every machine plays the same stream of orders and ticks from the host
    (lockstep), rather than the host sending the whole battle each tick. A machine joining is sent where the run
    began (the seed and ship, or the host's save) and everything since, and catches up; the host checks every 5 s
    that the machines agree and sends a machine that doesn't back through the catch-up. Only the host keeps the save.
    Squad decisions are the Admiral's: event, victory, hail and surrender choices, jumps and waiting, pausing,
    hailing. Refits and purchases are open to everyone, as commanding ships is (GV 4D). The settings that change a
    run (rules: conduits, run length, difficulty, formation, GATOS Species, auto pause) are the host's.
- **B — Likely (heromedel, 2026-11-01):** players are titled Commodores and the host is the Admiral, so no player
  is outranked by a crew member (crew ranks reach Captain, GV 15A). It replaces the titles in GDD 4B–4D (the
  Captain is the host, joining players are Commanders) and GDD 15B; the roles stay the same.
- **C — Decided (heromedel, 2026-11-01):** the multiplayer groundwork, all in one build: the server and its clients,
  every player action sent to the server as an order, LAN hosting and joining by direct IP, and each controller as a
  player of its own with its own cursor (GDD 14E's buttons). Players drop in and out at any time (GDD 4F): a new pad
  joins by pressing Start, a LAN player joins a running game, mid-fight included, and a player coming back gets
  their name, colour and place again. A Players menu lists everyone; the host starts as the Admiral and can hand the
  role on.
- **D — Decided (heromedel, 2026-11-01):** until the Admiral can assign ships (later), every player may command every
  ship and its crew.
- **E — Decided (heromedel, 2026-11-01):** the multiplayer settings (GDD 4H–4N) are built at their defaults for now:
  only the Admiral pauses, the Admiral makes event choices while the others see them, an indicator shows who paused,
  and if the Admiral drops out the game pauses and saves until they return.
- **F — Decided (heromedel, 2026-11-01):** players sharing a screen get split screen, each with their own camera,
  cards and selection: left and right for two, quarters for three or four. A setting,
  `Local Co-op View: Split > Shared`. Shared things (events, the pause and who paused) show once across the screen;
  a player's own windows open in their view. Over LAN each player has their own screen.
- **G — Saved for later (heromedel, 2026-11-01):** the vote and lock-in options of the multiplayer settings, and
  player profiles. (Assigning ships and crew moved to GV 4I.)
- **H — Decided (heromedel, 2026-11-05):** one player setup menu, on the title and during a run: every player, their
  name and colour, which input they use (keyboard and mouse, or a controller), and what they command. Any player can
  leave and everyone else stays in.
- **I — Decided (heromedel, 2026-11-05):** ships and crew are assigned to Any player or to specific players
  (GDD 4C–4D). A ship assigned to a player takes its crew with it, and a crew member can also be assigned on their
  own. Orders from players who aren't assigned are refused, and they are told why.
- **J — Likely (heromedel, 2026-11-05):** a player who leaves hands their ships and crew to the Admiral; a setting
  may choose otherwise later.

## 5. Ships

- **A — Decided (heromedel, 2026-10-31):** a powered Medbay heals every crew member of its own side in its room
  every tick, whatever they are doing, while fire or lack of air keeps hurting them. It heals allies from any
  ship of the squad, never enemies. (The room rule is GDD 5B.)

## 6. Jump Travel

- **A — Decided (heromedel, 2026-10-31):** the manual's "needs at least 1.21 Jigawatts" (GDD 9B) stays: a Jigawatt
  and a Materials Worth of Jigawatts (a Mawjig) are exactly the same thing, so 1.21 Jigawatts is a jump's 1.21
  Mawjig. The STRANDED text now says "if you wait long enough", not "we".
- **B — Decided (heromedel, 2026-10-31):** "the Power Cores on a ship" is deliberately vague: every ship has some
  kind of power generation, whatever its race, so the line fits every squad.

## 7. Races and Crew

- **A — Decided (heromedel, 2026-10-31):** a setting, `GATOS Species: Terrans > Tabbys`. With Terrans, the default,
  the GATOS are humans, the Galactic Alliance of Terran Occupied Systems; with Tabbys they are cats, the Galactic
  Alliance of Tabby Occupied Systems (race profiles, Terrans). It replaces "the GATOS are officially cats", earlier
  the same day. The setting also chooses the GATOS crew portraits (the mercenary humans or the cat heads), the
  HalfMechs' look and words (childlike or kitten-like) and the Senti's portraits (GV 7D), and words in events that
  depend on the species (e.g. DISTRESS_GATOS_FAMILY's kittens). Built: text says both ways as
  `{gatos:Terran words|Tabby words}`, filled in when shown, and the GATOS have shared names plus names for each
  species.
  - **Ai-Generated-Proposal (2026-10-31):** the fifteen human names for Terrans (Dana Reyes, Mack Holloway and
    the rest, in `content/races/terran/race.xml`); the cat-only names (Mittens, Captain Fluff and the rest) are used
    with Tabbys. With Tabbys the Senti are drawn as the GATOS cat head in their yellow-green, see-through with a
    glowing outline and eyes, scan lines and one slipped row.
- **B — Decided (heromedel, 2026-10-31):** a Mecha crew member's blue choice may be how the player first learns
  the name HalfMechs (the MECHA_TERRITORY event).
- **C — Proposed (heromedel, 2026-10-31):** hired mercenaries work on a contract, which can be renewed for a price
  that rises each time. If any of the mercenary crew die, the mercenaries are likely to leave after the battle. Built.
  - **Ai-Generated-Proposal (2026-10-31):** a contract runs for a number of jumps the hiring event sets (Lykario 3,
    "they don't stay long"; Tentauri 5; others 4), and waiting counts as a jump. When it is up, the captain asks for
    a renewal costing a quarter more than the last term; the player renews or lets them go. After a battle in which
    any of their own crew died, they leave three times in four, unless the player pays them that price to stay,
    which works two times in three. When they leave, their crew go with them wherever they are, and the squad's
    own crew aboard come back. Mercenaries don't keep a run alive (GDD 7G).
  - **Ai-Generated-Proposal (2026-10-31):** four new hiring events after GDD 7G's race table: Mecha (a fee, cheaper
    if a Mecha crew member haggles), Tentauri in struggling or doomed space (flying the same way, sharing the
    drive's Mawjig), struggling Senti (paid in Mawjig or in your sensor logs) and doomed Terran survivalists (who
    are now and then still pirates). Their words are for Lori to check; their prices for Eco.
- **D — Proposed (heromedel, 2026-10-31):** with Tabbys (GV 7A), the HalfMechs are kitten-like rather than
  childlike, and the Senti are holographic cats. Crew portraits follow: cats in the HalfMech colour palette for the
  Mecha, and semi-transparent yellow-green cats with holographic distortion or scan lines for the Senti. With
  Terrans, the GATOS crew use human portraits.
  - **Liked (heromedel, 2026-10-31):** the portrait options in `docs/art/portraits/`: HalfMech kittens K1 to K5 and
    mercenary Terrans M1 to M5 all look fine as tokens.
  - **Idea (heromedel, 2026-10-31):** the HalfMech kittens follow the HalfMech pilot art's dark look: black
    kittens in dark tones, with blue, green or purple eyes and Mecha power purple implants.

- **E — Likely (heromedel, 2026-10-31):** the genre's community-wiki timings that Infall: Eco passed on (not timed
  in game): repair 12.5 s a system bar for an untrained crew member, fire-fighting 10.4 s, teleporter cooldowns
  20, 15 and 10 s by level (were 5.5 s, about 6 s and 30/20/10 s). The teleporter's cooldown resets outside
  fights. Built.
- **F — Proposed (heromedel, 2026-11-11):** a setting, `Art Style: Top Down > Facing > Tokens`, so both sprite
  styles can be playtested without asking for a build of each. It can be taken out before a release if needed.
  - **Top Down — Decided as the default (heromedel, 2026-11-11):** crew drawn from almost straight above, as the
    genre draws them (`docs/art/terran/crew-test-4`, `docs/art/mecha/crew-topdown-test`).
  - **Facing:** crew drawn standing, facing the viewer (`docs/art/terran/crew-test-3`, `docs/art/mecha/crew`,
    `docs/art/tentauri/crew`, the Tabby of `docs/art/terran/cat-concept-for-gatos`).
  - **Tokens:** the round portrait tokens the game has drawn until now.
  - A race with no sheet in the chosen style is drawn as its token, so the game plays the same in every style and
    a new sheet shows up by itself. As sheets are added to the game, gaps, missing frames and fixes get filled in
    (heromedel, 2026-11-11); what is missing is listed in `infall-godot/README.md`.
  - How it is built: a race names its sheets in its `race.xml` (`<crew_art style="…" sheet="…" layout="…"/>`), and
    `content/crew-layouts.xml` says where each animation's frames sit on a sheet. Frames are 35 pixels, the size of
    a deck tile, so a sprite fills its tile one pixel for one.
  - **Tokens from sprites — Decided for the Tentauri (heromedel, 2026-11-11):** a race's token can be a circle cut
    from one frame of its sheet (`<token style="…" frame="row,column" centre="x,y" radius="…"/>` in `race.xml`),
    in place of a drawn face. The Tentauri's is the bell of the Facing sheet's standing frame.
  - **Colour variants — Proposed (heromedel, 2026-11-11):** a sheet can list the same sheet in other colours
    (`variants="…"` on `<crew_art>`). A crew member's name picks one, for the sprite and the token alike; the
    race's own names take them in turn. The Tentauri have six (`docs/art/style-guides.md`).

## 8. Weapons and Systems

- **A — Likely (Infall: Eco, 2026-10-31):** event rewards follow the genre's curve by band; the battlesuit gives
  0.02 Mawjig back when it comes home (economy-findings F5).
- **B — Decided (heromedel, 2026-10-31):** a ship's value is worked out from its parts when the game loads, by
  `system-prices.md`'s rules (Infall: Eco; hull, systems, rooms, doors, mounts, reactor and weapons), not typed into
  each ship file. Built (`scripts/core/ship_value.gd`).
  - **Likely (Infall: Eco, 2026-10-31):** a room holding several systems counts its dearest; the AZC counts as a
    room's system at its level-1 price, 18.15; a shields room at one layer's price, 54.46. The Supershield costs
    38.72, with upgrades of 7.26 and 12.11.

- **C — Likely (heromedel, 2026-11-05):** with the real distance (GV 3I), a battlesuit carries 10 to 20 times more
  air, so it can cross the gap, fight and come home.
  - **Ai-Generated-Proposal (2026-11-05):** 15 times to start.

## 14. User Interface

- **A — Proposed (heromedel, 2026-10-31):** the HUD's sections are cards the player can drag by a small bar at
  the top, to customise the layout. The layout is shared by every ship.
- **B — Proposed (heromedel, 2026-10-31):** the subsystems are a card of their own, which can lock onto the
  systems card or detach from it.
- **C — Proposed (heromedel, 2026-10-31):** cards can be folded. A folded card opens by itself when something
  changes on it (a crew member is hurt, say), so its animation shows, and folds again after 5 quiet seconds.
  Settings: `Collapsed Cards Reopen on Change: On > Off`, `Reopened Cards Fold Back: On > Off`.
  - **Ai-Generated-Proposal (2026-10-31):** cards snap to the screen's edges and to each other; right clicking a
    card's bar puts it back. Settings: `HUD Layout: Movable > Locked`, `HUD Card Opacity: 85% > 100% > 70%`, and a
    Reset HUD layout button.
- **D — Ai-Generated-Proposal (2026-10-31):** messages sit on a dark plate so they read over any ship; hovering a
  system's console shows only that system.

- **E — Likely (heromedel, 2026-11-01):** built. A setting, `Mouse Control: Left Selects, Right Orders > Left Selects and
  Orders, Right Deselects`. The default is the genre's: left click selects, arms and targets; right click orders
  crew and cancels. In both, right click on a system or weapon on the HUD powers it down, as usual.
- **F — Likely (heromedel, 2026-11-01):** stepping back goes one level at a time: a mode is cancelled (aiming, the
  teleporter, a suit launch), then the crew or weapon is deselected, then the ship, and Esc's last step opens the
  menu. Clicking on nothing steps back (right click with the second Mouse Control), and so does Esc. With no ship
  selected, the ship cards (weapons, systems, crew) are hidden, while every ship of the squad stays listed with its
  hull and can be selected.
  - **Ai-Generated-Proposal (2026-11-01):** with no ship selected the weapon hotkeys 1 to 6 do nothing and Tab
    selects the first ship. With the default Mouse Control, a left click on the selected ship's own floor also
    steps back, as a click on nothing does. Built.

- **G — Proposed (heromedel, 2026-11-05):** the settings menu gets tabs, as the settings grow.
- **H — Proposed (heromedel, 2026-11-09):** ship status cards. Every ship a player commands has a small status
  card of a fixed size; the Admiral has one for every ship of the squad. The battle view then never has to keep two
  ships in sight: a player can select one of their ships, zoom to an enemy ship, and still see on the card when
  their own ship is hit.
  - A card shows a small deck plan. A room shows fire, a breach and damage with a tint and/or one icon (not every
    tile of the room), its air with a tint, and intruders with icons. The card also has a hull bar and shield pips.
  - Clicking a card jumps the camera to that ship.
  - A card folds like the other HUD cards: it reopens when something changes on its ship and folds back.

## 15. Ranks and Titles

- **A — Decided (heromedel, 2026-11-01):** crew ranks are cosmetic only, and kept apart from the name: the rank is
  shown in front of it (e.g. "Lt. Omar Haddad"), so renaming never loses it.
  - **Proposed (heromedel, 2026-11-01):** ranks and the Promote button as in Federation Home Planet: one rank for
    each skill fully mastered (both levels), Sgt., Lt., Maj., Col., Cmd., Cpt.; when a rank is due, the player
    presses Promote. A skill lost never takes a rank away. One ladder for every race until racial ranks are made.
    It replaces GDD 15C (ranks shown from total skill, with no button). Built: a gold mark on the crew card when a
    promotion is due, and Promote on the ship screen.

## Next build

The list for the 2026-10-31 evening build. All built; what is left is noted.

1. **Mercenaries** on renewable contracts, with more mercenary events (GV 7C). Built. Escorting The Colony Ship stays
   an idea (`ideas.md`).
2. **The genre's wiki timings** for repair, fire-fighting and the teleporter (GV 7E). Built.
3. **The GATOS Species setting** (GV 7A) with the human faces, the HalfMech kittens, holographic cat Senti and
   species words in events. Built.
4. **Ship values worked out from their parts** by Eco's rules (GV 8B). Built.
5. **Windows that rebuild break.** Fixed once in the shared window base: windows empty at once, shrink to fit and
   scroll when tall.
6. **Upgrade prices read as "+6.05".** Now the plain price, with the low Mawjig warning.
7. **Regions are too large.** Every race's regions have the same weight and size (weights kept as data); the first
   region is the player's race. GATOS space is now about 12–14% of clusters.
8. **More room between the ships and the barrier.** A fixed 6-tile gap between every zone and the barrier; the
   barrier is 16 tiles.
9. **Show what is under the cursor while aiming.** Done.
10. **Survivors.** Only from surrendered ships and from enemy boarders who surrender when their ship is destroyed,
    and always the player's choice. Special events that save someone are not written yet.
11. **The chaos tester's last open finding** (an event window open about 20 s): not a stuck window. The tester
    counted a chain of windows (a contract, the opening message, the cluster's event) as one, and a big window
    whose way out its random clicks kept missing. It now times each window and presses a window's way out before
    calling it stuck; no window was stuck in eight seeds since.

## Next build (after 2026-10-31)

All built in the build of 2026-11-01.

1. **The multiplayer groundwork** (GV 4A, 4C–4F): built. The server and its clients, orders, LAN by direct IP,
   controllers as players with their own cursors, drop in and out, the Players menu (P, or a controller's View) and
   the Admiral role, split screen, everyone commanding every ship, the multiplayer settings at their defaults.
2. **More varied cat heads:** built. Coats (plain, tabby stripes, tuxedo, calico), ear tufts on one in four, and the
   faces other than face C now 60% of heads (were 50%). The coats are Ai-Generated-Proposal.
3. **Mouse Control and stepping back** (GV 14E, 14F): built.
4. **Crew ranks and Promote** (GV 15A): built.
5. **Player titles** (GV 4B): built; players are named "Admiral Name" and "Commodore Name".

## Next build (after 2026-11-02)

All built in the build of 2026-11-05.

1. **Co-op fixes** (heromedel, 2026-11-05: with player 1 on the keyboard and player 2 on a controller, the controller
   began moving player 1's camera, and crew obeyed only player 1). Suspected: the controller's stick also drives the
   keyboard player's camera through the default arrow actions, and after a window shown to everyone the controller
   moves the real mouse, so its clicks land in player 1's view. Both were so, and are fixed: the arrow-key camera
   answers only the keyboard, and over the windows every player sees each controller has a cursor of its own.
   A now selects and presses as well, and orders selected crew when it points at a room.
2. **The real battlefield** (GV 3I, 3J): 16,000 by 9,000, horizontal, the gap squeezed 1:10 into a bar, real
   flight times, real Gatometers, the real background, and the `Battlefield: Vertical > Horizontal` setting. Built.
3. **Battlesuit air** for the longer crossings (GV 8C): 15 times. Built.
4. **The player setup menu** (GV 4H) with inputs, assigning ships and crew (GV 4I), and leaving (GV 4J). Built;
   the keyboard player drops back in with any key, as a controller does with Start.
5. **Settings tabs** (GV 14G): Game, Battle, Controls, HUD, Players, Display and Sound. Built.

## Next build (after 2026-11-05)

1. **Ship status cards** (GV 14H): a small card for every ship a player commands, with a deck plan that shows
   fire, breaches, damage, air and intruders, a hull bar and shield pips; a click jumps to the ship.

2. **Art Style** (GV 7F): built 2026-11-11 with the five sheets that exist and the standing Tabby. Still to fill in:
   top-down Tabbys; the Tabby's animations in the Facing style; top-down Tentauri; any sheet at all for the
   Azurethea, Malphen, Lykario and Senti-GPH; death and clone-bay animations, which the game does not play
   yet. The top-down drifter's repair and death rows were redrawn from his own frames the same day and are in.

## Later (the road map)

- When the host quits a LAN game, hand the game to another player's machine instead of ending it (GDD 4N, Admiral
  transfer).

## Decision log

| Date | Decision |
| --- | --- |
| 2026-10-31 | The doc started; today's decisions recorded (GV 2A–14D). |
| 2026-10-31 | The GATOS are cats: the Galactic Alliance of Tabby Occupied Systems (GV 7A, race profiles). |
| 2026-10-31 | Mercenaries on renewable contracts (GV 7C), for the next build; HalfMechs may be learned through a Mecha crew member (GV 7B). |
| 2026-10-31 | The GATOS Species setting, Terrans > Tabbys, replaces "officially cats" (GV 7A); the portrait options liked (GV 7D). |
| 2026-10-31 | 1.21 Jigawatts is 1.21 Mawjig (GV 6A); "the Power Cores on a ship" covers every ship (GV 6B); kitten-like HalfMechs and holographic cat Senti proposed (GV 7D). |
| 2026-10-31 | The evening build: everything on the Next build list (GV 3H, 7A, 7C, 7E, 8B). |
| 2026-11-01 | Mouse Control setting and stepping back (GV 14E, 14F); cosmetic crew ranks with Promote (GV 15A); Commodores and the Admiral (GV 4B); always a server (GV 4A). |
| 2026-11-01 | Always a server is Decided (GV 4A); the multiplayer groundwork goes first on the Next build list. |
| 2026-11-01 | The multiplayer groundwork planned (GV 4C–4G): server and clients, orders, LAN, controllers, drop in and out, split screen, defaults only. |
| 2026-11-01 | The 2026-11-01 build: the multiplayer groundwork and the rest of the Next build list. |
| 2026-11-05 | The real battlefield (GV 3I, 3J), the player setup menu and assignments (GV 4H–4J), more battlesuit air (GV 8C), settings tabs (GV 14G); handing the game over on the road map. |
| 2026-11-05 | The 2026-11-05 build: co-op fixes, the real battlefield, battlesuit air, the player setup menu with assignments, settings tabs. |
| 2026-11-09 | Ship status cards (GV 14H) proposed and put on the Next build list. |
| 2026-11-11 | The Art Style setting, Top Down > Facing > Tokens, with Top Down the default (GV 7F); built the same day. |
| 2026-11-11 | Tentauri tokens are cut from the Facing sheet's standing frame, and the sheet has colour variants (GV 7F). |
