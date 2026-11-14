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
- **D — Built (2026-11-13), GDD 2R (Decided):** a cluster that turns Abandoned has no store; what it holds
  becomes something drifting to salvage. The rest of GDD 2R (each state changing who is met and what a store has)
  is not built.

- **E — Built (2026-11-14), GDD 2R; heromedel: "you can work on cluster simulation and how it affects available
  events":** the galaxy changes a little after every jump.
  - **Refugees move.** A cluster about to be swallowed sends its people out once; each group moves one cluster
    outward per jump while the place it is in is Doomed, Struggling or Swallowed, rests where things are fine, and
    settles when it reaches safe space of its own race. A cluster holding a group is Refugee.
  - **At War.** A cluster beside one held by another race is At War when either race pushes into its neighbours;
    it is a Border while that lasts. The war is over when the enemy's cluster is abandoned or swallowed.
  - **Hemmed in.** A cluster at war with more enemy neighbours than friends is Struggling, however far the
    collapse is.
  - **Fronts move.** An inner cluster becomes a Border once a neighbour of its own race is swallowed, abandoned
    or occupied.
  - **In play.** At a cluster at war, two quiet arrivals in five become a fight, and the other side's ships are
    met there too. The Refugee state already changes stores and events.
  - **Ai-Generated-Proposal:** the Terrans, Azurethea, Tentauri and Senti flee; the Mecha, Lykario and Malphen
    push into their neighbours; two Doomed clusters in three send a group.

- **F — Built (2026-11-14), heromedel: "the victory path that should come next is the get one tech from every
  race":** the Tech victory and its rival. The rule is `docs/ideas.md`, Tech victory (Proposed, heromedel
  2026-11-14, on Infall: Lori's branch): the pieces are goals, not destinations.
  - **The pieces.** Each is a race's own version of a real system: the GATOS Armoured ZeroPoint Core, Azurethea
    Engines, the Tentauri Supershield Generator, the Senti Armoured Avatar Array, the Lykario Autopilot (their
    Piloting), the Malphen Growth Organ, and the Mecha Hull Reinforcement (a new system: 5 more hull points).
    Every system records the race that built it: its ship's race, or the race whose store sold it.
  - **All on one ship (heromedel, 2026-11-14: "all on one ship, not just in the squad"):** a piece counts when it
    is fitted to the one ship that will make the crossing: the squad's own ship that carries the most of them. A
    piece that is taken, bought or given goes to the hold. A refit yard (GV 5E) fits it to a ship, and moves or
    trades a piece between ships. So a squad that starts in the Outrider has the GATOS core fitted from the first
    jump, and an Azurethea ship's Engines can be traded across to it at a yard.
  - **Which pieces (`docs/ideas.md`, 2026-10-21, "one from each pair"):** a setting, `Tech Victory Pieces: One of
    Each Pair > All Seven`. The pairs are Power (the GATOS core or the Malphen Growth Organ), Flight (Azurethea
    Engines or the Lykario Autopilot), Hull (the Tentauri Supershield or the Mecha Hull Reinforcement) and Record
    (the Senti Armoured Avatar Array or genetic diversity). **Open for heromedel:** which of the two is the rule;
    he said "one tech from every race" and then asked whether the docs' pairs were meant.
  - **The goal starts late.** On the squad's first arrival two bands from the rim, The Colony Ship's message
    (TECH_GOAL_FOUND) begins the search. From then the map lists how many pieces are aboard and, for each one
    missing, which way that race's nearest space lies: a pointer to a region, never a marked place.
  - **Ways to a piece while the search is on.** Any ship of that race: its wreck gives the piece up now and then, a
    ship left whole with its crew dead more often, and from band 6 one that surrenders can be asked for it in
    place of its Mawjig. A store in that race's space sells it. That race's own event comes up in its space.
  - **Exceptions (heromedel):** the Malphen piece is never sold; a losing Malphen ship gives up its organ in place
    of its usual surrender. The Mecha never hand theirs over in a surrender and sell it only for a good deal.
  - **Prices (Infall: Eco, findings F16 and F17):** a piece costs what a core system does, 36.31, times the band
    adjustment; the Mecha's deal 1.5 times that; a favour a quarter; kinship a half. A ship left whole carries its
    piece 1 time in 3 from band 6.
  - **The rival (heromedel, 2026-11-14):** Commodore Marlowe's Long Odds (Lori's names; the ship is Infall: Ship
    Designs' BC-9) meets a squad that is searching and has two or more pieces, once in each of the last two bands.
    It carries a Jig Drive MC-Flywheel (Mawjig-Charged; heromedel's name) and jumps away the moment its hull falls
    below 25% (heromedel). With all seven aboard it ambushes the squad at the rim, the flywheel spent, and its
    first two losses are replaced by ships that jump in where the wrecks were. Winning that fight is the Tech
    victory.
  - **Setting:** `Tech Victory: Optional > Required`. Optional: without all seven the rim is as before, the Last
    Fleet and the plain ending. Required: without all seven there is no way out at the rim yet.
  - **Not built:** a Short run has no Tech victory.
  - **Ai-Generated-Proposal:** genetic diversity stands in as six living crew of the squad's own race aboard the
    one ship (the docs say "maybe 3 males and 3 females of your core race"; the game has no crew sex); fitting a
    piece from the hold costs a quarter of that system's price, and a ship that already has that kind of system has
    it rebuilt as the piece where it stands, keeping its level; a wreck gives up its piece 1 time in 10; the rival wants two pieces aboard before
    it hunts and comes to those meetings at 70% of its hull; the ambush is the Long Odds and a Checkpoint Cutter,
    replaced by a Forlorn Hope and a Sellsword; the setting and its default; the pointers are compass directions
    as the map shows them.

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
- **K — Likely (heromedel, 2026-11-13), built:** closer to the genre, from heromedel's answers, the reference
  frames and what could be read online (no new recordings):
  - Fire spreads between rooms through their doors, never through a wall: freely through an open door or with
    no working Doors system; a closed door slows it 1.75 times and a closed blast door 10 times (the genre's
    wiki). **Ai-Generated-Proposal:** a blast door is Doors at level 2 or more.
  - Crew fight a fire from where they stand (already so).
  - A damaged system is red, on the ship and in the HUD (it was orange until broken).
  - A system's own key gives it power and Shift with the key takes it away, shown in its tooltip (reference
    frame 12).
    - **Decided (heromedel, 2026-11-13):** the keys match the genre's, and anything of Infall's that sat on one of
      them moved. Cloaking is H, the Crew Teleporter G and the Supershield Y, so every system key works both ways.
      Open Doors is Z and Close Doors X, Recall R, Return to Stations Enter, look at the selected ship Q, launch
      a suit B.
  - Open Doors pressed again, with every inner door open, opens the airlocks too.
    - **Decided (heromedel, 2026-11-14), built:** no separate VENT button, and no SPECIALS card: as in the genre,
      a system's own controls are small icon buttons on the system (doors open and close on the Doors subsystem;
      teleporter send and recall; cloaking, hacking, mind control, the battery and the EVB Dock one each).
  - While the mouse player aims, the arrow is hidden: the reticle is the cursor (reference frame 02).
  - An enemy's empty shield pip shows its recharge as a bar (reference frame 17).
  - A weapon file can name its launch sound; without one it gets its kind's (missile, flak, ion, spore, heavy or
    light laser). A miss has a sound. The new sounds have not been listened to.
  - **Decided (heromedel, 2026-11-13):** event choices are numbered and a number key picks one, as the genre's
    event screens show. Built for every window of numbered choices; 1 also presses a window's only button.
  - Not settled: the gap between a volley's shots (0.25 s in the game; no figure found).

- **L — Built (2026-11-14), heromedel:** captains weigh the fight. Each captain compares the damage coming in
  with the damage going out, as measured over the last 20 s and as each side's weapons stand now, against the hull
  each side has left. From that it changes tactics (nothing landing: go for the shields, or turn on the ship with
  the fewest layers; taking a beating: go for the weapons doing it), and an enemy captain that is losing with
  under half a minute left thinks of surrender or escape before its hull says so, while one that is winning
  fights on however low its hull is. This runs beside the ship's own plan and its squad's conduct.
  **Ai-Generated-Proposal:** the 20 s window, "losing" as lasting under 0.6 of the other side's time, and the
  half minute.
- **M — Built (2026-11-14), heromedel by way of Infall: Eco:** against a Shield Projector, or three layers and
  more, a captain sends what ignores shields at the shield room; the Senti plans cut the shield room first. Senti
  picket fights fell from 32 to 54% of hull lost to 0 to 37%, with no stalemates.

- **N — Built (2026-11-14), GDD 6F (Proposed, heromedel):** leaving a fight. Each ship jumps clear on its own
  charged drive, at no cost (JUMP OUT; the HUD shows the selected ship's own drive under the squad's). JUMP in a
  fight: with no ship clear it says there is nowhere to plot a course from, unless every drive is charged, when
  the whole squad jumps clear at once; with some clear and some still fighting it lists the ships that will be
  lost and asks; once the squad is clear the map opens, and the jump from there costs the 1.21. A fight won with
  ships clear brings them back. If every ship still fighting is lost, the run goes on with the ones that got out.

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
- **K — Built (2026-11-13):**
  - GDD 4F (Decided): what a player commanded when they left is remembered, and the Admiral restores it from the
    Players menu when they return. Kept for the run; a save does not keep it.
  - GDD 4A (Likely): five and six players on one screen are laid out three across and two down.
  - GV 4E: the Admiral leaving by choice pauses and saves, as their machine dropping out does.
  - Fixed: a machine joining while the host was mid-jump played orders queued behind the jump twice and fell out
    of step. The host's record is now written as each item is played.
  - The out-of-step check also covers the battle's random numbers, systems, air, fires, breaches, conduits and
    cooldowns.
  - Tests: `tools/lan_run_test.sh` (a longer run over LAN, both machines' state compared), more checks in
    `coop_test`, and `CHAOS_PLAYERS` for the chaos tester.

## 5. Ships

- **A — Decided (heromedel, 2026-10-31):** a powered Medbay heals every crew member of its own side in its room
  every tick, whatever they are doing, while fire or lack of air keeps hurting them. It heals allies from any
  ship of the squad, never enemies. (The room rule is GDD 5B.)
- **B — Built (2026-11-13), GDD 5B (Decided):** buying a system is held to the placement rules Ship Designs gave:
  a tile of its own; a Medbay (or any system that heals) only with systems crew can't man, Doors and Sensors
  counted as manned. The room picker says why a room is refused.
  - **Decided (heromedel, 2026-11-13; GDD 5D):** an EVA or EVB Dock sits at an airlock: on a tile that has one,
    or in a room that has an airlock with no system on its tile. A bought dock is put on the airlock's tile, and a
    room without such an airlock is refused. The content check holds every ship file to it; the four with an EVB
    Dock (the Assault Frame and its Siege loadout, the Light Attack Frame's two suit dock loadouts) have the dock
    on the tile next to a clear airlock, so they pass.
- **C — Built (2026-11-13):** the docs' own ships from `ship-suggestions.md`: the Pirate Pickpocket and the
  Lykario Scrap Hound (loadouts), the Malphen Polyp with its flak loadout, the Azurethea Vein Moth, and the
  weapons Flesh Mortar, Bone Flak and Lantern. The docs' Relay Picket and the Senti crew killers wait for the AAA.
  - **Decided (heromedel, 2026-11-13):** the Malphen Growth's first fight is a squad of two, a Polyp and a flak
    Polyp (three cost the Outrider half its hull in bot fights); band 2 keeps two Polyps and a flak Polyp. The
    Pirate Scrapper keeps a place: its own squad, GATOS Scrappers, in bands 1 and 2. "None of these are made as
    hard rules; ships should go where the fun, balance and challenge are."

- **D — Built (2026-11-14):** the Relay Picket is the docs' one (`ship-suggestions.md`, as updated 2026-11-13: a
  7-bar Senti core, a Shield Projector, the Armoured Avatar Array, a Backup Battery, two beams, two Senti). The
  Archive Cruiser, its mid-tier loadout, is an **Ai-Generated-Proposal**: three Projector layers, three Senti, the
  Intrusion Array, two lasers and a beam. Senti pickets are met from band 3, as the docs have it.

- **E — Built (2026-11-14), GDD 5N (Proposed, heromedel):** refit yards. A store with a yard (one with a ship for
  sale, and half the others) moves a system from one of the squad's ships to another for a quarter of its value at
  its level, into a room the player picks, under the same placement rules as a purchase. A ship can't take a kind
  of system it already has: the two ships trade theirs, each taking the other's tile. A weapons system moves only
  with its weapons off, and a mercenary's ship is not the squad's to refit. A piece of the Tech victory in the
  hold is fitted to a ship here. Moving a power core, Life Support, Piloting or Engines asks first, in Infall: Lori's words.
  The yard also buys a ship (Infall: Eco, finding F17: half of what a store asks for the design, less damage);
  its crew move to the other ships where there is room. Crew already move between ships on the ship screen.
- **F — Built (2026-11-14), GDD 8R (heromedel):** the EVA Dock has a third button: crew of the ship who crossed to
  a squad-mate stay there and join its crew.

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
  - **Particles — Likely (heromedel, 2026-11-12):** all particles are made in the game instead of being drawn on
    the sheets (extinguisher spray, welding sparks and the like), and the ones that were drawn on sheets came off:
    it is more consistent and easier to change. Built 2026-11-12.
    - Repair sparks are the ship's power colour (heromedel's example, built). Extinguisher spray is white and
      pale blue (**Ai-Generated-Proposal**).
    - Taken off the sheets: the Facing drifter's spray and repair sparks; the Tentauri's repair sparks and the
      sparkles at its tentacle tips when it shoots; the Mecha Facing sheet's flash at the claw in one aiming frame
      each way. The top-down drifter and top-down Mecha had none. The shooting flashes are not replaced yet: the
      game does not draw a crew member's shot.
    - How it is built: a sheet's `<crew_art>` in its `race.xml` holds `<particles kind="…" animation="…" …/>` with
      the point in the frame where they start for each way the crew member faces ("any" for all; left is right
      mirrored unless given). The points were read off the art and are good to a pixel or so.
  - **Crew for sale — Decided (heromedel, 2026-11-11):** every crew card in a store shows a picture of the crew
    member, drawn as the Art Style setting draws them aboard: their sprite standing on a deck tile, or their
    token where the style is Tokens or the race has no sheet in it. It is the crew member the buyer gets: their
    name and subtype are settled before the sale, though the card doesn't show the name.
  - **Subtypes — Decided (heromedel, 2026-11-11):** a crew member has a subtype that names the colours they
    wear, one for each part of their race's sheet. A Tentauri's is bell and tentacles, picked separately, e.g.
    `blue/forest`. It is for show only, is saved with the run, and a clone keeps it.
    - A newcomer takes, at random, a planned subtype nobody in the squad wears; once all are worn, a combination
      of the listed colours nobody in the squad wears. No weights, so a bell can turn up with tentacles of its own
      colour. An enemy squad does the same among itself.
    - Past every combination (36 for the Tentauri) the colours are made up at random: one too close to a subtype
      already worn is thrown and tried again, and the third try stands whatever it is (heromedel). What counts as
      too close is an **Ai-Generated-Proposal**: every part within 25 degrees of hue of the other's.
    - A Tentauri for sale at a store shows the subtype they will have.
    - More planned subtypes can be added later; other races have none yet.
    - How it is built: the race's `race.xml` lists each part (`<skin_part>`: the sheet's own colour codes for it
      and the colours it can take) and the planned subtypes (`<subtype wears="…"/>`). The sheet is kept as an SVG,
      and the game changes its colour codes and draws it, once for each subtype worn (`CrewSkins`, `CrewArt`).
- **G — Likely (heromedel, 2026-11-12), built 2026-11-13:** crew fights as the genre has them
  (`docs/reference/genre-crew-fights/`), and how crew and consoles share a tile.
  - **Likely (heromedel, 2026-11-12), built:** a tile holds one fighter from each side. Whoever walks into a
    room with foes in it goes onto a foe's tile and pairs up; the two on a tile punch. A fighter with nobody on
    their tile stays where they are, aims and fires, and a small bolt flies from about the gun to the target.
    Those already standing in the room do not move.
  - **Proposed (heromedel, 2026-11-12), built:** if a player moves a paired crew member to another tile, the
    enemy, if still willing to fight, follows to go on with the melee. The genre had no need of this: it has no
    tile-to-tile orders.
  - How it is built (`CrewBrain`, `ShipView`; `tools/crew_fight_test` checks the rules). Each line here is an
    **Ai-Generated-Proposal** where the recordings or heromedel did not settle it:
    - A punch or a shot lands once a second and does the same damage, 5.6 health at melee 1.0, so a second of
      fighting costs what it did before hits were counted. Whether the genre's shot and punch differ is not
      known.
    - A walker takes the nearest foe's tile that none of their own side holds. A player chooses by the tile
      they order: onto a foe's tile to punch, any other tile to shoot.
    - Crew beamed in land on a tile with no foe on it when there is one, so they start by shooting, as in the
      recordings.
    - **Decided (heromedel, 2026-11-13), built:** a shooter concentrates on one foe until that foe is dead or
      gone, unless they are hit by someone else, when they fight back and turn on the one who hit them. This is
      Infall's own rule: in the recording the genre's shooter changed target five times in fourteen shots, and
      turned on a foe who never touched him.
      - **Ai-Generated-Proposal (agreed by heromedel, 2026-11-13):** they turn on the one who hit them only if
        their own target is not shooting at them too; otherwise two foes shooting at one fighter would have
        them changing target at every hit. A punch needs no rule: a foe who walks onto a shooter's tile is
        paired with them, and they punch back.
      - **Ai-Generated-Proposal (agreed by heromedel, 2026-11-13):** the first target is a foe already shooting
        at them if there is one, otherwise the nearest.
    - The bolt takes a quarter of a second a tile and always lands.
    - Following: only crew no player commands follow, and only inside the room. A player's own crew wait for
      orders.
    - Drawing: the two on a tile are drawn apart, the other side's above and facing the camera, the player's
      below with their back to it. The punch is timed to land with the hit. The bolt is a ship laser's made
      small, in the shooter's side's colour, leaving from the muzzle point each sheet gives
      (`<particles kind="shot" animation="aim" …/>`). A hit shows a white flash with a red cross, then red
      flecks that fade. Crew are drawn from the back of the screen forward, and health bars over everything.
  - **Decided (heromedel, 2026-11-12):** no extra outlines round a crew member. The second ring drawn when
    someone mans a system goes: the console's art and its powered symbol are enough, and a crew member standing
    there is plainly manning it.
  - **Likely (heromedel, 2026-11-12):** crew are the genre's size in a tile.
  - **Decided (heromedel, 2026-11-13), built:** crew and system share a tile the way the art sessions settled
    it: the console at the wall with the symbol in it, the crew member in front, and no symbol disc at the
    tile's middle.
    - The console art is in the game's content (`infall-godot/content/consoles/`, brought over by
      `tools/import_console_art.py`): the Outrider's wall desk, the Mecha tower, and the Tentauri organs, one for
      each system. A race names its style in its `race.xml` (`consoles="organs"`).
    - **Ai-Generated-Proposal:** a race with no consoles of its own (Azurethea, Lykario, Malphen, Senti) gets
      the wall desk until theirs is drawn.
    - The art carries no symbol. The game draws it on the screen or bulb, so its colour still shows powered,
      unpowered, damaged and broken.
    - The desk and the tower turn to face their wall. The Tentauri organs stay upright on the screen however
      the ship and the view are turned, at half size, slid against their wall (style guides, Tentauri ships).
    - A crew member standing still on a console's tile is drawn back from its wall: 6 pixels for a sprite, 4 for
      the top-down HalfMech (its arms were drawn to grip the tower), 8 for a token. Only the drawing shifts;
      where they stand in the battle does not. **Ai-Generated-Proposal** for the distances
      (mockup: `docs/art/mockups/crew-at-console/`).
    - In the Facing style a console on the wall nearest the player is drawn over the crew member, who stands
      behind it.
    - A system with no wall (the Mecha Servicing Core) still shows its symbol on a dark plate.
    - Shields, Engines and Life Support are now drawn as the agreed shapes (`content/systems/<id>/symbol.svg`
      at the repo root).
  - **Decided (heromedel, 2026-11-13), built:** no ring under a crew sprite. Sides are told apart as in the
    genre, by the health bar's colour: green for the player's crew, red for the other side. The bar shows on
    every crew member in a room that holds both sides, and on one who is hurt or selected, as before; its
    length still shows health. It sits just under the figure's feet. A token keeps its rim, which is part of
    the token.
  - **Decided (heromedel, 2026-11-13), built:** a selected crew sprite has a thin outline that hugs it, one
    pixel wide, in the selecting player's colour, as the genre marks its own. A selected token keeps a ring.
  - **Likely (heromedel, 2026-11-13), built:** tokens are smaller, about 19 pixels across with the rim (they were
    about 27), so a console's symbol shows beside one. The size is an **Ai-Generated-Proposal**.
  - What was found about consoles, symbols and size (2026-11-12), before the points above were answered.
    heromedel's first leaning was a small symbol beside or above a crew member while manning:
    - The art sessions settled where the symbol goes: in the console. The Outrider's floor layout test 4 has
      "a pale desk that blends into the floor, with a small symbol on its screen"; the pirate ships have wall
      desks with the symbol; the Tentauri have an organic base for each system with the symbol lit in a dark
      bulb (Decided, `docs/art/style-guides.md`); the Mecha console is a pixel tower with the symbol on its
      screen (Decided). The art rule (`docs/art/README.md`, 2026-10-25): a console sits against its wall, at
      most about half the tile deep, and crew stand and work on the console's own tile.
    - The Godot version uses none of that console art. It draws a plain desk with a blank screen and puts the
      symbol on a dark disc in the middle of the tile, which is GDD 14C's stand-in "until console art exists".
      A crew member stands on the tile's middle, on top of it.
    - Symbols: 14 agreed symbol files are at the repo root (`content/systems/<id>/symbol.svg`, from the first
      coding version). The Godot version redraws its symbols in code. Weapons, Medbay, Piloting, Sensors and
      Doors match; Shields, Engines and Life Support are drawn differently.
    - Size: the top-down drifter is already exactly the genre human's size in the frame (17 by 12 pixels facing
      down, 9 by 18 facing sideways). What makes crew look bigger is the ring round each one, about 29 pixels
      across. The Facing sprites are taller by design (22 to 31 pixels), and a token with its rim is about 30
      across.
- **H — Built (2026-11-13):** the Tentauri reach, as the reach prototype has it (`docs/art/tentauri/crew/`): a
  Tentauri grows a pair of short tentacles to each console it mans from across the room, drawn by the game in its
  own tentacle colours; they pull back in when it stops. The prototype's body sheet is not used yet.
- **I — Built (2026-11-13), race profiles Lykario 9 (Decided):** Animal Senses. With a living Lykario in the
  squad, the crew aboard an enemy ship are seen without sensors and in a nebula. Only the crew show.
- **J — Built (2026-11-13), GDD 7H (Decided):** repairing a system the crew member has a skill level in is 5%
  faster. **Placeholder (heromedel, 2026-11-13):** 5% for now, Infall: Eco's figure (half of one repair level);
  it has not been tested.

- **K — Decided (heromedel, 2026-11-14), built:** `Terran Ship Conduits: Off > On`. Conduits stay in the game as a
  setting, off by default, since a player's grasp of them can't be tested by bots. With it off every ship's power
  is a pool of bars, the player's and the enemy's alike (an AZC level is five bars).
- **L — Built (2026-11-14), race profiles Senti 6 and 9:** the Armoured Avatar Array. One Senti per bar of its
  power (heromedel, 2026-11-13). Damage or ion holds the Senti over the limit in the array until it works again;
  they don't die from it. A Senti struck down in a fight is broadcast again from the array after 12, 9 or 7 s
  (the genre's clone bay times). A Senti needs room in an array to join a ship; Senti stores sell the array.
  **Ai-Generated-Proposal:** the array mends its Senti aboard their own ship, a third as fast as a medbay.

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
- **D — Likely (Infall: Eco, 2026-11-13), built:** the growth organ is priced as a clone bay (12.11, then 8.47 and
  10.89); mercenary prices rise with the band like wreck rewards, times 1.(band − 1); the sized event rewards are
  7 low, 11 medium and 7 high, the genre's split (which reward moved is an **Ai-Generated-Proposal**); 15 crew
  damage a point of damage stays.
  - **Built (2026-11-14), heromedel's go:** shields are the genre's classic ones (GDD 8Q). Shield power moves in
    pairs, and a layer that loses a bar to damage or ion gives up the other bar too. The `Shield Levels` setting
    of 2026-11-13 is gone. A shields room is valued at 10% of Shields' level-1 price, 3.03 (Eco); every ship's
    value matches `economy-findings.md` F13.
- **E — Fixed (2026-11-13):** no beam weapon had dealt damage since tile targeting was built (a beam was never
  given its list of tiles cut). They work again.

- **F — Built (2026-11-14), GDD 8A:** Hacking and Mind Control, with the genre's timings (a pulse of 4, 7 or 10 s;
  control for 14, 20 or 28 s; 20 s to ready again). The probe latches onto one enemy system for the fight and a
  pulse shuts it down; mind control puts one enemy crew member on your side. A use costs 0.04 and 0.08 Mawjig
  (Infall: Eco, **Ai-Generated-Proposal**). The Senti's make is the Intrusion Array and the Azurethea's the
  Pheromone Gland (heromedel, Likely, 2026-11-14; names by Infall: Lori). Not built: seeing into a hacked room,
  and mind control's bonus at higher levels.
- **G — Built (2026-11-14), GDD 8Q (Proposed):** the Senti Shield Projector. One bar a layer, layers back half as
  fast, up to eight; each layer priced as a Generator layer (5 to 8: 62.92, 82.28, 101.64, 121.01, Infall: Eco,
  **Ai-Generated-Proposal**). A ship has it or the Generator. The setting `Beams vs Shields: Penetrate (Classic) >
  Hit (Damages Shields First)` is built as GDD 8Q describes it: with Hit, each tile a beam crosses takes down one
  layer, and once the layers are gone the tiles after it take the beam's full damage.
- **H — Built (2026-11-14):** the genre's Backup Battery: two extra power a level for 30 s, then 20 s to recharge;
  8.47, level 2 another 12.11.
- **J — Built (2026-11-14), GDD 8L (Likely) and 8M (Proposed):** a ship may carry several weapon systems. Each
  weapon is fitted to one and draws on that system's bars only, so damage or ion to one weapon system leaves the
  other's weapons firing; each has its own gunner. The WEAPONS card has a row for each, the first at the bottom,
  and the number keys run row by row. A ship file labels them (`label="A"`, `label="B"`) and a weapon names its
  system. The Pirate Hijacker (Twinshot on A, Sporewing on B; its loadouts as the docs have them) and the Tentauri
  scout and Pappus (one weapon on each) use it. Not built from 8M: slots set by a system's level, `maxSlots`, and
  mounts kept for one system.
- **K — Built (2026-11-14), GDD 8R (Proposed):** the EVA Dock. A crew member of a ship with one walks to an
  airlock, crosses to another ship in a suit and steps in at one of its airlocks: a squad-mate's, to repair or
  fight boarders there, or an enemy's, to board it; they come home the same way. The crossing takes the real
  distance at a suit's speed and uses the suit's air (25, 40 or 55 s by the dock's level); out of air, they lose
  health until they arrive. Ships don't aim at them. Stores sell the dock (16.34). **Ai-Generated-Proposal:** any
  number may be out, suits are kept, the air refills aboard their own squad's ships, they enter an enemy by any
  airlock, and a Supershield keeps them out as it does boarders. No enemy captain uses it yet.
- **L — Built (2026-11-14):** the three Senti crew killers (`docs/deck-collapse-ships/senti-crew-killers`), as
  loadouts on the Relay Picket's floor plan, in the squad Senti Census, met where Senti are Doomed or Struggling.
  Their weapons: fire beams, a breach laser, an anti-crew beam that passes shields and wounds the crew it sweeps,
  and a bio bomb that wounds everyone in a room. **Ai-Generated-Proposal:** more Projector layers and hull than
  the docs' files, and the weapons' charge times and prices. They are mild in fights so far; Ship Designs has been
  asked for their own floor plans.
- **I — Proposed (Infall: Eco, 2026-11-14; heromedel: "makes sense"), built:** a store asks 75% of a ship's value
  on Normal, 50% on Easy and 100% on Hard (it was 115%).

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
  - Built 2026-11-13 as one HUD card, SHIP STATUS, holding a small card for each ship the player commands (the
    Admiral: every ship). A room is orange with a flame when it burns, has a dark hole when breached, a red edge
    when a system in it is damaged, a red tint as its air thins, and a red dot for each intruder. The plan lies
    the way the ship does on the screen (Battlefield: Vertical or Horizontal). **Ai-Generated-Proposal:** the
    marks' looks are this session's.
  - **Decided (heromedel, 2026-11-13), built:** each ship's card folds on its own, and a folded card opens again
    when its ship is hit, on fire, breached or boarded.
- **I — Built (2026-11-13), GDD 14D:** `Player Power Color: Default (Green) > Racial > Specific Color` colours the
  player's conduits, symbols, power bars and pips, and `Enemy Terran Color: Pirate Power Orange > Power Green`
  decides what a Terran enemy shows.
  - **Decided (heromedel, 2026-11-13), built:** the Specific Color is both a list of every species' power colour
    and a picker: `Specific Power Color: GATOS Green > Pirate Orange > Mecha Purple > Tentauri Pink > Azurethea
    Blue > Senti Yellow-Green > Lykario Silver > Malphen Pink-Orange > Custom`, and Custom opens a colour picker.

- **J — Built (2026-11-14):** How to Play on the title and pause menus, and a hint in a new player's first fights
  (`Hints in Early Fights: On > Off`), after three blind testers looked at screenshots and none could tell how to
  attack. From the same reports: titles on the SYSTEMS and SUBSYSTEMS cards, "1 of 10 POWER FREE", BUY and UPGRADE
  on price buttons, INSTALLED for a system the ship has, the title screen's overlap, the enemy ship clear of the
  top bar. TO STATIONS and SAVE STATIONS are heromedel's wording.

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
   fire, breaches, damage, air and intruders, a hull bar and shield pips; a click jumps to the ship. Built
   2026-11-13.

2. **Art Style** (GV 7F): built 2026-11-11 with the five sheets that exist and the standing Tabby; the Tabby's full Facing sheet went in on 2026-11-13. Still to fill in:
   top-down Tabbys; the Tabby's animations in the Facing style; top-down Tentauri; any sheet at all for the
   Azurethea, Malphen, Lykario and Senti-GPH; the clone-bay animation, which the game does not play (it has
   no clone bay; deaths have played since 2026-11-13). The top-down drifter's repair and death rows were redrawn from his own frames the same day and are in.

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
| 2026-11-11 | Tentauri tokens are cut from the Facing sheet's standing frame (GV 7F). |
| 2026-11-12 | Particles are made in the game, not drawn on the sheets; repair sparks in the ship's power colour (GV 7F). |
| 2026-11-11 | Every crew card in a store shows the crew member's picture, following the Art Style setting (GV 7F). |
| 2026-11-11 | Crew subtypes: a Tentauri's bell and tentacle colours, planned pairs first, then unused combinations, one of each to a squad (GV 7F). |
| 2026-11-13 | Consoles drawn from the art sessions' art with the symbol on them, crew drawn back from the wall, no ring under sprites, health bars coloured by side, a thin outline for a selected sprite, smaller tokens (GV 7G); built the same day. |
| 2026-11-13 | The Tabby's full Facing sheet is in the game, in place of the four standing views. |
| 2026-11-13 | Crew fights as the genre has them: pairing on a tile, punches, shots, hit marks, and the enemy following a moved crew member (GV 7G); built the same day. |
| 2026-11-13 | A crew member who shoots concentrates on one foe, and fights back when hit by another (GV 7G). |
| 2026-11-13 | A dying crew member plays their sheet's death frames, then fades (GV 7F). |
| 2026-11-13 | heromedel's answers to the overnight report: keys match the genre's and event choices take number keys (GV 3K); a two-ship first Malphen squad and the GATOS Scrappers (GV 5C); each status card folds on its own (GV 14H); Specific Power Color lists every species and has a picker (GV 14I); `Shield Levels: By Bar > By Layer` (GV 8D); the 5% repair bonus stays as a placeholder (GV 7J). |
| 2026-11-13 | Two shield systems proposed, the Mawjig Shield Generator and the Senti Shield Projector, and the setting `Beams vs Shields: Penetrate (Classic) > Hit (Damages Shields First)` (GDD 8Q); for Ship Designs to weigh before any is built. |
| 2026-11-14 | Built: classic shields as the genre has them (power in pairs), the `Shield Levels` setting removed, the shields room at 3.03, and the Hijacker's door 4 taken out as Ship Designs did (GV 8D). |
| 2026-11-13 | For the next build, on heromedel's go: the classic shield fixed to the genre's (shield power moves in pairs, a damaged or ionised layer frees its other bar, the `Shield Levels` setting removed), and a hull's power-colour stripe following the ship's power colour. The EVA Dock is written up as GDD 8R (Proposed). |
| 2026-11-13 | An EVA or EVB Dock sits at an airlock: on its tile, or in a room with an airlock that has no system on its tile (GDD 5D, GV 5B). |
| 2026-11-13 | The overnight plan (`docs/handoffs/overnight-plan-2026-11-13.md`, report beside it): co-op fixes and tests (GV 4K), closer to the genre (GV 3K), Player Power Color (GV 14I), the Medbay rule and the docs' ships (GV 5B, 5C), Abandoned clusters (GV 2D), Animal Senses, the reach and the repair bonus (GV 7H–7J), Eco's prices (GV 8D), ship status cards (GV 14H). |
