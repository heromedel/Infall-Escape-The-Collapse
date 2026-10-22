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
