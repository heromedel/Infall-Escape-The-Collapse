# Overnight plan for the Godot version (2026-11-13)

For **Infall: Godot Version**, asked for by heromedel: a large plan to work through while he sleeps, covering
co-op testing, matching the genre's feel, and design points the game lacks. Started the same evening on his
answers, which are worked in below and marked (heromedel, 2026-11-13). Progress is logged in
`overnight-report-2026-11-13.md`.

Every item below was checked by this session in the docs or the code (helpers' reports were used only as leads;
one of their claims was wrong and is not here). Where an item still rests on something unchecked, it says so.

## Rules for the night

1. **Build only what is settled:** a point tagged Hard Rule, Decided or Likely in the docs, a point on the Next
   build list, or the genre's behaviour (GDD 1C) once it has been seen in the genre's own game or its data.
2. **No new design decisions.** Where a settled point leaves a number or a detail open, either park the item or
   pick the smallest sensible value, tag it Ai-Generated-Proposal in the docs and list it in the morning report.
   (heromedel chooses which, Q3.)
3. **Check the genre before copying it,** without new recordings (heromedel, 2026-11-13): the reference notes,
   the screenshots already taken, earlier research in the docs, and what can be read online. Most of it is
   obvious to him; his own answers are under Plan B.
4. **One step, one commit, pushed** to `Cloud-C-Godot-Version`. A step that changes the simulation also runs the
   fight test, the crew fight test and the LAN test before its commit. A step that only changes drawing gets a
   compile check and a screenshot.
5. **The helper sessions** (Infall: Eco, Infall: Ship Designs, Infall: Lori) generally know what they are talking
   about (heromedel, 2026-11-13): go with what they say, then report what it was and what was done with it. To
   find out what a session does, ask Infall: Manager. Where a settled point gives no number, look it up first or
   ask the right session (his answer to Q3).
6. **Stop and park** anything that turns out bigger or less settled than it looked, with a note of why.
7. The hard rule on the genre's name, code, art and text holds as always.

## Plan A: co-op, tested and fixed

1. **Baseline.** Run every existing test once and record the results: compile check, lint, content check, galaxy,
   mercenary, ship value, fight, crew fight, input, co-op (split screen), LAN, flow, three bot runs, chaos seeds 1–5.
2. **Five and six players on one screen.** The split layout puts views 5 and 6 in a third row off the screen
   (`main.gd`, the view layout); GDD 4A (Likely) allows six players. Lay five and six out in a grid of three by two.
3. **A stronger out-of-step check.** The number the LAN machines compare covers hull, shields, crew tile and
   health, weapon charge and shot count (`battle_screen.gd`, `checksum`). Add fires, breaches, air, system damage
   and power, conduits and the battle's random-number state, so a disagreement is caught where it starts.
4. **A wider LAN test.** Today's joins mid-fight and sends one door order. Add: a jump, an event choice, a store
   purchase, a hail, a rule change, leaving and rejoining, and joining during a jump (a helper suspects orders
   queued behind a jump are played twice by a machine that joins then; unconfirmed, so test it). Fix what fails.
5. **A wider split-screen test.** Add: Local Co-op View: Shared, five and six players, the local Admiral leaving
   (GV 4E says the game pauses and saves when the Admiral drops out; that is only wired to a LAN disconnect),
   Battlefield: Horizontal with a split screen, and a controller opening the store, ship screen and map.
6. **Chaos with two players.** The chaos tester drives one player only. Give it a second, controller player.
7. **Remember assignments** (GDD 4F, Decided): when a player leaves, keep what they commanded so the Admiral can
   restore it when they return. Today the handover forgets it.
8. **Stale notes:** the README says assigning ships isn't built, and a comment in `session.gd` says every player
   commands every ship; both are out of date (GV 4I).

Left out on purpose: votes, lock-in and player profiles (GV 4G, saved for later), and handing the game to another
machine when the host quits (the road map's "Later").

## Plan B: closer to the genre

1. **Look first,** with heromedel's answers (2026-11-13):
   a. Crew do not walk to a fire to fight it ("they would be in the fire if they did"), and he doesn't think
      they leave it either. Infall already works this way: nothing to change.
   b. Fire spreads to rooms connected by doors. Infall lets it through any wall: to change.
   c. Open-all-doors vents all the air, fairly fast: check online what it does with airlocks.
   d. The gap between a volley's shots: check online or in the earlier research.
   e. A damaged system is red. Infall shows orange until it is broken: to change, after a look at the
      screenshots already taken.
   f. Event and power keys: check online.
2. **System power keys.** Each `system.xml` already names a `hotkey`, and nothing reads it. Make the key add power
   and Shift with it remove power, and show the key in the system's tooltip, as reference frame 12 shows.
3. **Number keys for event choices** (if step 1f confirms them).
4. **The aiming cursor.** While aiming, the genre's cursor is the reticle (reference frame 02); Infall draws a
   reticle and leaves the arrow showing. Hide the arrow while aiming.
5. **Enemy shield pips that show recharge** (reference frame 17): a bar under an empty pip.
6. **Whatever step 1 confirms** of a, b, c, d and e, each as its own step.
7. **Weapon sounds.** The genre gives each weapon its own launch sound and has hit, shield-hit and miss sounds
   (the battle-screen reference). Infall plays one of three shared sounds. Let a weapon file name its sound and add
   miss and shield-hit sounds, made by `tools/make_audio.py`.

## Plan C: design points the game lacks

Quick ones first.

1. **Player Power Color** (GDD 14D, Decided): `Player Power Color: Default (Green) > Racial > Specific Color`. The
   setting is listed and nothing reads it.
2. **Enemy Terran ships show pirate orange** (GDD 14D, Likely, default confirmed 2026-10-31), with the setting
   `Enemy Terran Color: Pirate Power Orange > Power Green`. Today only the pirate faction is orange.
3. ~~Mawjig never ends in a zero in the squad's pool.~~ **Dropped (heromedel, 2026-11-13):** that rule is
   Eco's and is about prices, which never end in a zero; the pool in play may land on one.
4. **The Medbay room rule when buying a system** (GDD 5B, Decided): a Medbay shares a room only with systems crew
   can't man. The shipped ships obey it; the room picker does not check it.
5. **Abandoned clusters have no store** (GDD 2R, Decided): "No store; derelicts and wreckage to salvage." A
   cluster keeps its store today when it turns Abandoned. The rest of 2R (each state changing who you meet) is
   bigger and is listed for the morning, not built.
6. **Repairing a system you have a level in is slightly faster** (GDD 7H, Decided). The docs give no number.
7. **Lykario Animal Senses** (race profiles, Lykario 9, Decided): "They sense Life Signs, without using ship
   sensors and even on other ships and in hazards." Never called psychic and never explained.

Larger ones.

8. **Ship status cards** (GV 14H, Proposed, first on the Next build list): a small card for each ship a player
   commands, with a deck plan showing fire, breaches, damage, air and intruders, a hull bar and shield pips; a click
   jumps to the ship; it folds like the other cards.
9. **The docs' own ships the game lacks** (`items-needing-second-opinion.md`). Their files are in
   `docs/deck-collapse-ships/`, which has no floor layouts. So: the two that are loadouts of ships the game has
   (the Pickpocket on the Hijacker, the Scrap Hound on the Outrider) go in now; the ones that need a hull and floor
   plan (Polyp, Vein Moth, the docs' Relay Picket, the three Senti crew killers) go in only where
   `ship-suggestions.md` gives a layout, and the rest are asked of Ship Designs.
10. **The Tentauri reach** (`docs/art/tentauri/crew/`, the reach prototype): a Tentauri working several consoles
    grows a pair of short tentacles to each, drawn by the game.
11. **If the night allows: several weapon systems on one ship** (GDD 8L, Likely), each its own stacked row. The
    largest item here; it touches the simulation, the HUD and the ship files, so it is last and may be parked.

## Plan D: the helper sessions

Asked at the start, so answers are back when they are needed.

1. **Infall: Eco:** the five open items under its name in `items-needing-second-opinion.md` (shield levels as bars
   or layers, the growth organ's price, 15 crew damage a hull point, mercenary prices, the event set paying less
   than the genre's), and the values of any ship added in C9.
2. **Infall: Ship Designs:** floor plans for the docs' ships that have none (C9), a look at the two loadouts once
   they are in, and whether the Medbay rule check (C4) matches what it expects.
3. **Infall: Lori:** every line of player-facing text written tonight (tooltips, the Abandoned cluster's salvage
   text, new ship and weapon descriptions), and the Animal Senses wording (C7).

## Plan E: wrapping up

1. Run the baseline again and compare it with A1.
2. Update `godot-version-decisions.md` (points, tags, decision log), the game's README and the reference notes.
3. A morning report in this folder: what was built, what was tested and how, what failed, what was parked and
   why, every Ai-Generated-Proposal made, what the helpers said and what was done with it, and numbered questions.
4. A Windows build, if heromedel wants one (Q2).

## Order

A1, D (messages out), A2–A8, C1–C7, B1, B2–B6, C8, C9, C10, B7, C11, E. The list is longer than one night is
likely to hold; it is in order of value, each step stands alone, and the work stops wherever the night ends.

## Questions, as answered (heromedel, 2026-11-13)

- **Q1.** Go ahead, with the changes worked in above.
- **Q2.** A Windows build at the end: not answered, so none is made.
- **Q3.** Where a settled point gives no number: look it up first, or ask the right session.
