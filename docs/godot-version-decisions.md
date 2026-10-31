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

## 8. Weapons and Systems

- **A — Likely (Infall: Eco, 2026-10-31):** event rewards follow the genre's curve by band; the battlesuit gives
  0.02 Mawjig back when it comes home (economy-findings F5).
- **B — Decided (heromedel, 2026-10-31):** a ship's value is worked out from its parts when the game loads, by
  `system-prices.md`'s rules (Infall: Eco; hull, systems, rooms, doors, mounts, reactor and weapons), not typed into
  each ship file. Built (`scripts/core/ship_value.gd`).
  - **Likely (Infall: Eco, 2026-10-31):** a room holding several systems counts its dearest; the AZC counts as a
    room's system at its level-1 price, 18.15; a shields room at one layer's price, 54.46. The Supershield costs
    38.72, with upgrades of 7.26 and 12.11.

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
11. **The chaos tester's last open finding** (an event window open about 20 s): checked, not reproduced.

## Decision log

| Date | Decision |
| --- | --- |
| 2026-10-31 | The doc started; today's decisions recorded (GV 2A–14D). |
| 2026-10-31 | The GATOS are cats: the Galactic Alliance of Tabby Occupied Systems (GV 7A, race profiles). |
| 2026-10-31 | Mercenaries on renewable contracts (GV 7C), for the next build; HalfMechs may be learned through a Mecha crew member (GV 7B). |
| 2026-10-31 | The GATOS Species setting, Terrans > Tabbys, replaces "officially cats" (GV 7A); the portrait options liked (GV 7D). |
| 2026-10-31 | 1.21 Jigawatts is 1.21 Mawjig (GV 6A); "the Power Cores on a ship" covers every ship (GV 6B); kitten-like HalfMechs and holographic cat Senti proposed (GV 7D). |
| 2026-10-31 | The evening build: everything on the Next build list (GV 3H, 7A, 7C, 7E, 8B). |
