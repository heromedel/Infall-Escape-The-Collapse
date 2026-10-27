# Infall: Concerns

Design concerns saved for later with heromedel's agreement, each with the ideas offered for it. A concern is
closed by a decision in `gdd.html`, then removed or marked resolved here.

## 1. Grinding when the collapse can't be slowed (2026-10-23)

Run length expects some grinding rather than rushing straight through (GDD 2O), but the collapse expands about one
jump's distance each time the player jumps (GDD 2Q) and, unlike FTL's rebel fleet, nothing slows it down, not even
mercenaries (GDD 7G). How can we allow for more grinding?

Ideas:

- **Proposed (2026-10-23):** Senti-GPH tech might allow a high donation at a Senti cluster, paying a grant for them to
  attempt to stop or slow the collapse, or to research it. It never actually gets stopped this way.
- **Unlikely (2026-10-23):** The collapse grows once every two jumps instead of every jump.

## 2. Squad battles must read well in a screenshot (2026-10-23)

Store capsules, screenshots and trailers are what sell an FTL-like. A battle of up to 6 ships against 6 has to read
at a glance, even as a small thumbnail, or it looks like clutter. This ties into the visual identity (GDD 10B) and
the GUI (GDD 14A), both still Open.

Ideas:

- **Ai-Generated-Proposal (2026-10-23):** test each race's silhouette and colours (race profiles, point 1) at squad
  scale, so races are told apart at a glance in a zoomed-out battle.
- **Ai-Generated-Proposal (2026-10-23):** check the GUI with 12 ships on screen, so panels and indicators don't bury
  the ships in a screenshot.

## 3. Terran conduits: why would you ever reroute power? (2026-10-23)

Terran ships have unlimited power through conduits (race profiles, Terrans 6), and power is rerouted through
undamaged conduits when some are cut. But if every route can stay powered all the time, there is never a reason to
reroute: power just flows wherever a path exists, and rerouting does nothing for the player.

Ideas:

- **Proposed (2026-10-23):** give conduits a limit, or lose power over a split or a distance.
- **Proposed (2026-10-23):** power leaks when sent through broken conduits (it barely changes anything on its own).
- **Proposed (2026-10-23):** broken conduits start fires 75% of the time while powered, so leaving every route
  powered is dangerous.
- **Proposed (2026-10-23):** the captain can draw or place new conduits at any time after selecting the power core.
  Either they work at once but can't pass through a broken conduit or a breach, or the crew quickly builds them:
  routing a drawn conduit is at least twice as fast as repairing a broken one, and can route around rooms that are on
  fire or breached. Breaches and broken systems then become what power has to be routed around.
- **Proposed (2026-10-23):** drop rerouting as a player action. A system has power if an unbroken conduit
  path leads from it to the AZC; the ship finds the path itself. A damaged conduit (and possibly a breached room)
  doesn't carry power, so a system goes dark only when every path to it is cut. The decisions become which conduit
  to repair first, ship layouts with loops (tough) or a single spine (fragile), and enemies targeting conduit hubs.

## 4. Conduit power and systems with several options, such as weapon mounts (heromedel, 2026-10-27)

If Terran ships are powered through conduits and more than one weapon sits on the same weapon system, there has to
be a way to set which of those weapons are powered. So a system with several options, such as weapon mounts, must
still work like vanilla FTL after it receives power from a conduit: the conduit delivers bars to the system, and
inside the system the player assigns those bars to its options (which weapons are on) with the genre's clicks.

Ideas:

- **Proposed (2026-10-27):** two layers. The conduit layer answers "how many bars reach this system". The system
  layer is the genre's: the Weapons system's bars are handed to weapon slots in order, and clicking a slot powers
  or depowers that weapon. Only the first layer is Terran-specific; the second is the same for every race.
