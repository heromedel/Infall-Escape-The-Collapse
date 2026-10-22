# Ship Suggestions

Ship designs made with `ship-design-process.md`. Nothing here is decided. Prices use the reference tables in
`docs/reference/` and leave out crew.

## Tentauri Tough Little Scout (2026-10-22)

1. **Race:** Tentauri.
2. **Band:** 1 (easy, near the start of a run).
3. **State:** doing fine.
4. **Race info used:** small ships of about two crew, possibly mates; few rooms with many systems (GDD 5B); go
   where they want, even unwelcome, without looking to destroy; shields and defence specialists; Zoltan-like
   Supershield; biomechanical tech with FTL's default power pool (as the Azurethea); standard weapons; crew run up
   to four systems at once. Silhouette: compact, like tiny shuttles.
5. **Function:** tough little scout. Gets in, survives, gets out.
6. **Kinds of systems and crew:** good shields, minimal weapons, 2 crew.
7. **Variation:** standard for the race; no band or state variation.
8. **Layout and systems:** small scout shuttle shape, wide like a slug's ship, two rooms. Hull 8, one more than
   FTL's enemy scout templates (7), since it is the tough one. Reactor 10 bars, as FTL's Federation and Mantis
   scout templates. Piloting, sensors and doors take no reactor power, as in FTL.

   | Room | System | Bars | Reactor |
   |---|---|---|---|
   | Forward (controlled) | Piloting | 1 | — |
   | | Weapons A | 1 | 1 |
   | | Weapons B | 1 | 1 |
   | | Engines | 2 | 2 |
   | | Shields | 2 (1 layer) | 2 |
   | | Sensors | 1 | — |
   | | Doors | 1 | — |
   | Rear (uncontrolled) | Airlock (GDD 5D) | — | — |
   | | Life Support | 1 | 1 |
   | | Medbay | 1 | 1 |
   | | Supershield Generator | 2 | 2 |
   | | **Total** | | **10** |

   - Two weapon systems, one per laser, so each crew member mans a laser. Their skill, stuns and charge times are
     separate, and it gives each crew member a reason to run several systems.
   - The forward room has 7 controlled systems. Two crew running up to 4 each can man 8, so there is room for one
     more controlled system later.
   - **Supershield Generator:** FTL's Zoltan Shield as a ship system. It recharges periodically, like having FTL's
     Shield Overcharger without a drone system. Power is the Overcharger's player version (2 bars). Capacity: 5,
     as FTL's Zoltan Shield (from memory of FTL, not in the reference data). Recharge rate is left for the
     simulation.
   - Weakness: every controlled system is in the forward room, so one fire, breach or boarder there hits them
     all.
9. **Weapons:** the Tentauri have no weapons yet, so one is designed.

   **Tentauri Defense Laser** (×2): Laser, Damage, Biomechanical, Tentauri · Shots 1 · Damage 1 · Power 1 ·
   Special: Defensive.
   - **Defensive:** when charged but not aimed (or set to defensive mode), it shoots down incoming shots tagged as
     missiles, like FTL's Defense Drone Mark I (missiles, asteroids and flak debris).
   - **Charge:** 9.0 s (7.0 base + 2.0 damage), about 10.8 s on a non-biomechanical system (+20%).
   - **Cost per shot:** 0.02 Mawjig, attacking or defending.
   - **Price:** 12.11. A plain 1-shot laser is 6.79 (1.41 base + 4.09 for one bar + 1.16 × 10 ÷ 9). The
     Defensive special adds 5.32: the Defense Drone Mark I (12.11) less the 1-damage laser it carries. So the
     Defense Laser costs the same as the drone it replaces.
   - **Shield check:** both lasers fired together beat a level 1 shield (one layer): the first shot takes the
     layer and the second lands, so 1 damage per volley against the most basic ship.
   - **Offense or defence:** both lasers are needed to get through one layer, so the ship can't attack and defend
     at once. It fights with both while the Supershield is up, then switches them to defence once the Supershield
     is down, or while the jump drive charges.
10. **Price:**

    | Part | Mawjig |
    |---|---|
    | Shields (buy, 2 bars) | 30.25 |
    | Engines, Piloting, Life Support | starts installed |
    | Medbay | 12.11 |
    | Sensors | 9.68 |
    | Doors | 14.52 |
    | Weapon systems (2 × 4.84) | 9.68 |
    | Supershield Generator (as FTL's Zoltan Shield, 80 scrap) | 19.36 |
    | Reactor, 10 bars (18.15 + 24.21) | 42.36 |
    | 2 × Tentauri Defense Laser | 24.22 |
    | **Total** | **162.18** |

    Weapon systems use FTL's Weapon Control buy price each, though FTL's starts at 4 bars and these at 1.

Flags for review:

- The Defensive special isn't in the cost tables yet; its price here is the rule above.

## Terran Starting Scout (2026-10-22)

1. **Race:** Terrans (the Gatos).
2. **Band:** 1 (low tier).
3. **State:** doing fine.
4. **Race info used:** clean, soft Federation-like ships; silhouette of classic spaceship shapes (shuttles,
   cruisers, rockets); AZC power core with conduits instead of power bars; rooms can suffer atmosphere loss, fire,
   deck and wall breaches and damaged conduits, and power is rerouted around cut conduits; "the initial scout ship
   is easy to reroute"; crew as FTL's humans; ship tiers as FTL. The player's first ship is a Terran scout
   (GDD 1D, 3K, 7C).
5. **Function:** the player's starting scout, the first ship of a run. Ideas considered: a Terran patrol scout met
   as an enemy, a survey ship, a courier, the colony ship's pathfinder, the player's starting scout. The starting
   scout was picked: it is the ship every run begins with, so it sets the baseline other ships are balanced
   against (GDD 3G), and the race profile already gives a rule for it (easy to reroute).
6. **Kinds of systems and crew:** an FTL Kestrel-level all-rounder with one scouting strength: Sensors 2, since
   sensor level sets how far beacons are visible (GDD 2E). 3 crew, like the Kestrel.
7. **Variation:** standard for the race (the Terran starting ship).
8. **Layout and systems:** a shuttle-shaped cruiser in white and pale grey with blue trim. Hull 30, as every FTL
   player ship. About as many rooms as the Kestrel (GDD 3D), with spare rooms reserved for systems bought later.

   **AZC level 2:** powers 4 systems at full. The ship has 5 systems that draw power (Shields, Engines, Life
   Support, Weapons, Medbay), so one must be off at any time, usually the Medbay or Life Support. This keeps FTL's
   Kestrel tension: the Kestrel's 8 bars can't run its Medbay with everything else on either. Piloting, Sensors and
   Doors take no core capacity, as FTL's subsystems take no reactor power.

   | System | Bars | Draws on the AZC |
   |---|---|---|
   | Piloting | 1 | no |
   | Sensors | 2 | no |
   | Doors | 1 | no |
   | Shields | 2 (1 layer) | yes |
   | Engines | 2 | yes |
   | Life Support | 1 | yes |
   | Weapons | 3 | yes |
   | Medbay | 1 | yes |

   **Conduits: one ring.** The AZC room sits in the middle of the ship, armoured, with two conduit exits. One
   conduit loop runs from it through every system room and back: AZC → Shields → Weapons → Cockpit (Piloting) →
   Sensors → Doors → Medbay → Life Support → Engines → AZC. Every system has two paths to the core, so a single cut
   conduit never cuts a system off; the player only has to reroute when two cuts land on both sides of a system.
   That is the "easy to reroute" starting ship. Higher-tier Terran ships can use branching conduits, where one cut
   matters more.

   Passes made:
   - Pass 1: a Kestrel copy at AZC level 3 (6 systems). Too strong: everything runs at once, so no power choices.
   - Pass 2: AZC level 2, restoring FTL's power tension; one system off at a time.
   - Pass 3: gave the scout Sensors 2 for longer map range (GDD 2E), paid for with a weaker missile than the
     Kestrel's (1 damage instead of 2).
   - Pass 4: conduit ring so a single cut never isolates a system; checked every system room has two paths.
   - Pass 5: weapons follow the Terran breach/conduit rule (below).
   - Pass 6: checked against band 1 enemies (FTL's scout templates: hull 7–10, 1 shield layer): see 9.
9. **Weapons:** no Terran weapons exist yet. The Stinger fits the missile role but is Azurethea and biomechanical,
   so on a Terran (mechanical) system it would charge 20% slower; a Terran missile is designed with the same parts
   instead. Names follow the Gatos style (race profile 6).

   **Gat 3.1 "Triblast"** (3-shot laser): Laser, Damage, Mechanical, Terran · Shots 3 · Damage 1 · Power 2 · Breach 0% ·
   Conduit damage 10%.
   - Charge: 13.1 s (7.0 + 6.0 damage + 0.09 conduit).
   - Cost per volley: 0.06 Mawjig (3 × (0.02 + 0.001)).
   - Price: 12.34 (1.41 + 8.18 power + 2.66 damage rate + 0.09 conduit rate).
   - Description idea: conduit damage comes from the weapon's ability to overload power systems.

   **Gat M1 "Pathfinder"** (light missile): Missile, Damage, Mechanical, Terran · Shots 1 · Damage 1 · Power 1 · Breach 10% ·
   Conduit damage 0%.
   - Charge: 9.1 s (7.0 + 2.0 damage + 0.1 breach).
   - Cost per shot: 0.05 Mawjig.
   - Price: 6.91 (6.90 by the table, no trailing zero).

   The laser has no breach chance, so it gets a conduit-damage chance; the missile has a breach chance and no
   conduit chance (race profile 6).

   **Shield check:** against one layer, the laser's first shot takes the layer and the other two land: 2 damage
   per volley, plus 1 from the missile, which ignores shields. A band 1 enemy (hull 7–10) falls in about three
   volleys, roughly 40 s. The missile also gives the player a way through the two-layer shields of later bands.

   **Economy check:** a fight of about 8 volleys (allowing for misses: in FTL a 3-shot volley often has one shot
   blocked, one miss and one hit) costs 0.48 in laser shots and 0.40 in missiles, plus the 1.21 jump: about 2.09
   per node against a 3.42 reward, leaving 1.33. A little tighter than the cost table's example fight (1.57 left),
   mostly from firing the missile every volley; holding it back saves Mawjig.
10. **Price:**

    | Part | Mawjig |
    |---|---|
    | Shields (buy, 2 bars) | 30.25 |
    | Engines, Piloting, Life Support | starts installed |
    | Weapon Control (buy) | 4.84 |
    | Medbay | 12.11 |
    | Sensors (buy 9.68 + level 2 6.05) | 15.73 |
    | Doors | 14.52 |
    | AZC level 2 | 42.36 |
    | Gat 3.1 "Triblast" | 12.34 |
    | Gat M1 "Pathfinder" | 6.91 |
    | **Total** | **139.06** |

    Crew are extra: 3 Terrans at 10.89 each, 32.67.
11. **New rules recorded:** conduit damage at a third of breach (+0.01 per shot at 100% in `mawjig-cost-table.md`;
    +0.3 s cooldown and a +0.38 price rate in `weapon-budget-table.md`), since it only affects conduit ships, drains
    no oxygen and is rarely lethal.

Judgment calls for review:

- Picking the player's starting ship as this scout's function.
- AZC level 2, and Piloting, Sensors and Doors taking no core capacity.
- Sensors 2 as the scout's strength, traded for a 1-damage missile.
- The ring conduit layout as what "easy to reroute" means.
- Conduit damage 10% on the laser (any chance is fine as long as it is priced).
- Weapon Control at FTL's buy price, though FTL's starts at 4 bars and this at 3.
