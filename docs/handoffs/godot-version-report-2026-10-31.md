# Godot version: work report, 2026-10-31

What the Infall: Godot Version session did on 2026-10-31, on branch `Cloud-C-Godot-Version`. Everything here is
in the Windows build sent at the end of the day.

## 1. From heromedel's testing

1. **Aiming and orders by tile:** a shot hits one tile and the system whose console is there, and crew on that
   tile; a beam hits each tile it crosses (GDD 3L, updated). Crew go to the tile clicked.
2. **Medbay:** it heals its own side's crew in its room every tick, at any task, stunned included, never
   enemies. Healing shows as rising green crosses, a glowing room and a pulsing health bar.
3. **Crew panel:** two lines, the task over the station or room ("manning / Piloting").
4. **Fire:** layered flames, embers and smoke; burned-out tiles leave scorch marks.
5. **Shields:** the bubble is fitted to each hull's art, mounts and floor.
6. **Galaxy:** the whole galaxy, a disc of spiral arms around the core with an overview in the map's corner.
   The squad can head inward early without reaching the first horizon; any rim cluster brings the final battle.
   Swallowed clusters are black; race regions are a soft wash with a legend.
7. **Tooltips** show again (they never did: the timer restarted every frame); hovering a console shows only its
   system; messages sit on a dark plate.
8. **Store:** buying no longer makes the window jump or grow; a long store scrolls.
9. **Ion storm:** the power it takes comes back when the squad leaves, as the ships had it.
10. **The pause before fights:** ships without hull art built outlines of thousands of points and froze for
    about 9 s each time. Fixed (now about 60 ms). Each fight also logs how long it took to appear.

## 2. The battlefield (heromedel, 2026-10-31; GDD 3Q to 3S)

1. Each ship sits centred in a square zone: the largest hull in the game plus 8 tiles (30 tiles now). The
   largest genre hulls were read from the game data: the Lanius 600 × 606 px, the Crystal Cruiser 721 px long.
2. A 12-tile barrier crosses the whole battlefield: two lines, drifting stars, "400 Gatometers" and "1.0 s"
   pinned to the middle of the screen. Shots and battlesuits take that long to cross; a faint dash shows them
   (setting `Shots Crossing Barrier: Shown > Hidden`).
3. The camera stays where the player puts it. Double-click a ship or press F to fly to it; Home frames all.
   Ships out of view get an arrow at the screen's edge.
4. Background planets are large, hazy and nearly still.
5. The Formation and Screen Shake settings now apply.

## 3. The HUD

1. **Movable cards:** drag a card by its grab bar; cards snap to edges and to each other, and dock to another
   card's side. Right click the bar puts a card back. Subsystems are their own card.
2. **Folding:** a folded card opens when something goes wrong on it and folds again after 5 quiet seconds.
3. **Settings:** `HUD Layout: Movable > Locked`, `HUD Card Opacity: 85% > 100% > 70%`,
   `Collapsed Cards Reopen on Change: On > Off`, `Reopened Cards Fold Back: On > Off`, and Reset HUD layout.
4. **Low Mawjig warning (GDD 14L):** a purchase or event choice that would leave less than 10 asks first with the
   exact amount; the counter is yellow below 10 and red below two jumps.

## 4. From the card game version

1. **Captain plans:** `<ai>` blocks in ship files, in the card game's format, steer what enemy captains shoot,
   where they board and where they send suits. The Hijacker, Light Attack Frame (and Suit Dock), Burr and
   Pappus carry the card game's plans.
2. **Crew tokens:** the GATOS use the approved pixel-art cat head (face C).

## 5. Reviews

1. **Ship Designs, Lori and Eco** reviewed the content written to fill gaps. What changed and what is still
   open is in `docs/items-needing-second-opinion.md`. Authorship comments were removed from the content files.
2. **A code review** of the day's work found eight problems (battlesuits turning back before attacking, a HUD
   docking loop that could freeze the HUD, sticky dragging and others), all fixed.
3. **A chaos tester** (`infall-godot/tools/chaos_test.gd`, `tools/chaos.sh`) plays runs like a careless player
   and checks the game's invariants. It found 15 problems, fixed: the fight-start freeze, HUD clicks through
   windows, the window count drifting after Continue, Z not working, stranded boarders, a lost reward when
   jumping right after a win, saving mid-fight skipping the fight, losing a ship by moving its last crew,
   buttons stealing Space, Esc not closing the map, the console's backtick, and the camera after interrupted
   drags.

## 6. Questions for heromedel

- Q1. Should a Mecha crew member's blue choice be how the player first learns the name HalfMechs?
- Q2. Hired mercenary ships: permanent, or a contract for a few jumps?
- Q3. STRANDED's "1.21 Jigawatts": keep the manual's joke, or say Mawjig?
- Q4. DISTRESS_GATOS_FAMILY's kittens: keep them, since the GATOS are drawn as cats here?
- Q5. Rooms and doors in a ship's value: Eco suggests hull points × 0.48; or a rate per room and door?
- Q6. Record today's decisions in the GDD? The zone size (largest hull + 8 tiles), the 12-tile barrier, the
  Medbay healing at any task, the movable HUD cards and their settings, and the area-weapon idea for
  `ideas.md` (2×2 "Blast").

## 7. How to check it

From `infall-godot/`: `tools/compile_check.sh` (script errors), `tools/input_test.tscn` (clicks, 14 checks),
`tools/test_fight.tscn` (20 fights), `tools/galaxy_test.tscn`, `tools/flow_test.tscn` (screenshots of a run),
`tools/chaos.sh` (the chaos tester). Run the scenes with `godot --path . <scene>`; the ones that draw need a
display (`xvfb-run`).
