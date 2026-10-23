# Ship Suggestions

Ship designs made with `ship-design-process.md`. Nothing here is decided. Prices use the reference tables in
`docs/reference/` and leave out crew. Tags are as in `tag-styles.md`: each design states its default tag, and
points that differ are tagged where they appear.

## Tentauri Tough Little Scout (2026-10-22)

Default tag: **Proposed (2026-10-22)**, from heromedel's worked example; Claude's additions are tagged.

1. **Race:** Tentauri.
2. **Band:** 1 (easy, near the start of a run).
3. **State:** doing fine.
4. **Race info used — Ai-Generated-Proposal (2026-10-22):** small ships of about two crew, possibly mates; few rooms with many systems (GDD 5B); go
   where they want, even unwelcome, without looking to destroy; shields and defence specialists; Zoltan-like
   Supershield; biomechanical tech with FTL's default power pool (as the Azurethea); standard weapons; crew run up
   to four systems at once. Silhouette: compact, like tiny shuttles.
5. **Function:** tough little scout. Gets in, survives, gets out.
6. **Kinds of systems and crew:** good shields, minimal weapons, 2 crew.
7. **Variation:** standard for the race; no band or state variation.
8. **Layout and systems:** small scout shuttle shape, wide like a slug's ship, two rooms. **Ai-Generated-Proposal (2026-10-22):** hull 8, one more than
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

   - **Two weapon systems — Likely (2026-10-22):** one per laser, so each crew member mans a laser. Their skill, stuns and charge times are
     separate, and it gives each crew member a reason to run several systems.
   - **Ai-Generated-Proposal (2026-10-22):** the forward room has 7 controlled systems. Two crew running up to 4 each can man 8, so there is room for one
     more controlled system later.
   - **Supershield Generator:** FTL's Zoltan Shield as a ship system. It recharges periodically, like having FTL's
     Shield Overcharger without a drone system. **Ai-Generated-Proposal (2026-10-22):** power is the Overcharger's player version (2 bars). Capacity: 5,
     as FTL's Zoltan Shield (from memory of FTL, not in the reference data). Recharge rate is left for the
     simulation.
   - **Weakness — Ai-Generated-Proposal (2026-10-22):** every controlled system is in the forward room, so one fire, breach or boarder there hits them
     all.
9. **Weapons:** the Tentauri have no weapons yet, so one is designed.

   **Tentauri Defense Laser** (×2): Laser, Damage, Biomechanical, Tentauri · Shots 1 · Damage 1 · Power 1 ·
   Special: Defensive.
   - **Defensive — Likely (2026-10-22):** when charged but not aimed (or set to defensive mode), it shoots down incoming shots tagged as
     missiles, like FTL's Defense Drone Mark I (missiles, asteroids and flak debris).
   - **Charge — Ai-Generated-Proposal (2026-10-22):** 9.0 s (7.0 base + 2.0 damage), about 10.8 s on a non-biomechanical system (+20%).
   - **Cost per shot — Ai-Generated-Proposal (2026-10-22):** 0.02 Mawjig, attacking or defending.
   - **Price — priced from the Defense Drone Mark I (Proposed (2026-10-22)); numbers Ai-Generated-Proposal (2026-10-22):** 12.11. A plain 1-shot laser is 6.79 (1.41 base + 4.09 for one bar + 1.16 × 10 ÷ 9). The
     Defensive special adds 5.32: the Defense Drone Mark I (12.11) less the 1-damage laser it carries. So the
     Defense Laser costs the same as the drone it replaces.
   - **Shield check — Ai-Generated-Proposal (2026-10-22):** both lasers fired together beat a level 1 shield (one layer): the first shot takes the
     layer and the second lands, so 1 damage per volley against the most basic ship.
   - **Offense or defence:** both lasers are needed to get through one layer, so the ship can't attack and defend
     at once. It fights with both while the Supershield is up, then switches them to defence once the Supershield
     is down, or while the jump drive charges.
10. **Price — Ai-Generated-Proposal (2026-10-22):**

    | Part | Mawjig |
    |---|---|
    | Shields (buy 30.25 + level 2 24.21) | 54.46 |
    | Piloting, Life Support | starts installed |
    | Engines (installed; level 2 2.42) | 2.42 |
    | Medbay | 12.11 |
    | Sensors | 9.68 |
    | Doors | 14.52 |
    | Weapon systems (2 × 4.84) | 9.68 |
    | Supershield Generator (as FTL's Zoltan Shield, 80 scrap) | 19.36 |
    | Reactor, 10 bars (18.15 + 24.21) | 42.36 |
    | 2 × Tentauri Defense Laser | 24.22 |
    | **Total** | **188.81** |

    Each weapon system is at level 1, so it costs only Weapon Control's buy price.

Flags for review:

- The Defensive special isn't in the cost tables yet; its price here is the rule above.

## Terran Starting Scout (2026-10-22)

Default tag: **Ai-Generated-Proposal (2026-10-22)**. heromedel liked the ship and called the test a success, which agrees to the next
step, not to every line; points he agreed to are tagged.

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
6. **Kinds of systems and crew:** **Proposed (2026-10-22):** fine as a well-equipped light battle scout of a doing-well Gatos,
   even if the 3-shot laser with good sensors is a bit powerful. An FTL Kestrel-level all-rounder with one scouting strength: Sensors 2, since
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
   instead. **Names — Likely (2026-10-22):** they follow the Gatos style (race profile 6).

   **Gat 3.1 "Triblast"** (3-shot laser): Laser, Damage, Mechanical, Terran · Shots 3 · Damage 1 · Power 2 · Breach 0% ·
   Conduit damage 10%.
   - Charge: 13.1 s (7.0 + 6.0 damage + 0.09 conduit).
   - Cost per volley: 0.06 Mawjig (3 × (0.02 + 0.001)).
   - Price: 12.34 (1.41 + 8.18 power + 2.66 damage rate + 0.09 conduit rate).
   - **Description — Proposed (2026-10-22):** conduit damage comes from the weapon's ability to overload power systems.

   **Gat M1 "Pathfinder"** (light missile): Missile, Damage, Mechanical, Terran · Shots 1 · Damage 1 · Power 1 · Breach 10% ·
   Conduit damage 0%.
   - Charge: 9.1 s (7.0 + 2.0 damage + 0.1 breach).
   - Cost per shot: 0.05 Mawjig.
   - Price: 6.91 (6.90 by the table, no trailing zero).

   **Conduit chance — Proposed (2026-10-22):** any chance is fine as long as it is priced, below breach. The laser has no breach
   chance, so it gets a conduit-damage chance; the missile has a breach chance and no
   conduit chance (race profile 6).

   **Shield check:** against one layer, the laser's first shot takes the layer and the other two land: 2 damage
   per volley, plus 1 from the missile, which ignores shields. A band 1 enemy (hull 7–10) falls in about three
   volleys, roughly 40 s. The missile also gives the player a way through the two-layer shields of later bands.

   **Economy check — Ai-Generated-Proposal (2026-10-23):** against one band 1 enemy ship (hull 7–10, about 8.5),
   allowing for misses (of a 3-shot volley, one blocked by the shield, one missed, one hit; the missile hitting
   about 70% of the time), the fight takes about 55 s: 5 laser volleys (0.30) and 7 missiles (0.35), 0.65 in all.
   With the squad's 1.21 jump (GDD 6C) that is 1.86 per node. Rewards are paid per enemy ship (GDD 8I): 3.42 for
   destroying it leaves 1.56, about the cost table's example (1.57); 4.36 for killing its crew leaves 2.50. More
   enemy ships per fight pay more per jump, since the jump is paid once.
10. **Price:**

    | Part | Mawjig |
    |---|---|
    | Shields (buy 30.25 + level 2 24.21) | 54.46 |
    | Piloting, Life Support | starts installed |
    | Engines (installed; level 2 2.42) | 2.42 |
    | Weapon Control (buy 4.84 + levels 2–3: 9.68 + 6.05) | 20.57 |
    | Medbay | 12.11 |
    | Sensors (buy 9.68 + level 2 6.05) | 15.73 |
    | Doors | 14.52 |
    | AZC level 2 | 42.36 |
    | Gat 3.1 "Triblast" | 12.34 |
    | Gat M1 "Pathfinder" | 6.91 |
    | **Total** | **181.42** |

    Crew are extra: 3 Terrans at 10.89 each, 32.67.
11. **New rules recorded:** **Proposed (2026-10-22):** conduit damage at a third of breach (+0.01 per shot at 100% in `mawjig-cost-table.md`;
    +0.3 s cooldown and a +0.38 price rate in `weapon-budget-table.md`), since it only affects conduit ships, drains
    no oxygen and is rarely lethal.

Judgment calls for review:

- Picking the player's starting ship as this scout's function.
- AZC level 2, and Piloting, Sensors and Doors taking no core capacity.
- Sensors 2 as the scout's strength, traded for a 1-damage missile.
- The ring conduit layout as what "easy to reroute" means.
- Conduit damage 10% on the laser (any chance is fine as long as it is priced).

## Terran Pirate Hijacker (2026-10-22)

Default tag: **Ai-Generated-Proposal (2026-10-22)**; not reviewed yet.

1. **Race:** Terrans (the Gatos).
2. **Band:** 5 (mid tier).
3. **State:** doomed. **Proposed (2026-10-22):** that doesn't make the ship poor or damaged: it is well armed. Doomed Terrans are aggressive
   and xenophobic, blame others and resort to nearly any crime: theft, hijacking, other races' technology, piracy.
4. **Race info used:** desperate ships look grim and survivalist, built from borrowed or stolen technology;
   classic spaceship silhouette; AZC with conduits; ion still disrupts Terran systems; crew as FTL's humans. A
   system installed on a Terran ship is powered like a Terran system, and a weapon on another tech type's system
   charges 20% slower (GDD 8D, `weapon-budget-table.md`). Pirates and criminals hide in Mecha border clusters.
5. **Function:** a hijacker: it takes ships instead of destroying them. Pirate here means criminals and
   survivalist mercenaries, not a sea-pirate theme (Proposed (2026-10-22)). Ideas considered: a boarding raider, a hijacker, a toll ship
   at a doomed Terran checkpoint, a wreck scavenger, a hunter of refugee convoys, a mercenary escort. The hijacker
   was picked: hijacking is named in the race profile, and it plays differently from a plain warship. It wants
   your ship intact, so it goes for your engines, piloting and crew, not your hull.
6. **Kinds of systems and crew:** disabling weapons, a crew teleporter, strong doors and a medbay for its
   boarders; light hull damage. 5 crew, all Terran: doomed Terrans are xenophobic, unlike FTL's mixed pirate crews.
7. **Variation:** a variation: the doomed Terran pirate.
8. **Layout and systems:** a classic Terran cruiser hull with rust and mismatched panels, and a visibly bolted-on
   organic Azurethea launcher, so the stolen weapon shows on the ship. Hull 14 (FTL's elite Rebel template; mid
   band). AZC level 3 (6 systems): Shields, Engines, Life Support, Weapons, Medbay and Teleporter all run at once.

   | System | Bars | Draws on the AZC |
   |---|---|---|
   | Piloting | 2 | no |
   | Sensors | 1 | no |
   | Doors | 2 | no |
   | Shields | 4 (2 layers) | yes |
   | Engines | 3 | yes |
   | Life Support | 1 | yes |
   | Weapons | 3 | yes |
   | Medbay | 2 | yes |
   | Crew Teleporter | 2 | yes |

   **Conduits:** a ring like the starting scout's, plus one spur out to the bolted-on launcher. Cut the spur and
   the stolen weapon goes dark: a weak point the player can read from the ship's art and aim for.

   Passes made:
   - Pass 1: an FTL pirate copy: mixed crew, burst lasers, teleporter. Generic.
   - Pass 2: made hijacking the identity: disable and board, little hull damage.
   - Pass 3: a stolen Azurethea spore missile as the disabler, paying the 20% foreign-tech charge penalty, the
     cost of using stolen tech; shown by the bolted-on launcher.
   - Pass 4: conduit spur to the launcher, a readable weak point.
   - Pass 5: all-Terran crew (xenophobic when doomed).
   - Pass 6: checked counters and rewards (see 9).
9. **Weapons:** no Terran or Azurethea weapon fits (the Stinger damages hull), so two are designed.

   **Sporewing** (stolen Azurethea, keeps its maker's name): Missile, Spores + Stun, Biomechanical, Azurethea ·
   Shots 1 · Damage 0 · Power 1.
   - Disables the system in the room hit until cleared like a repair, and stuns crew there; no breach or fire
     (Azurethea mid tech).
   - Charge: 11.5 s native; 13.8 s on this Terran ship (+20%).
   - Cost per shot: 0.11 Mawjig (0.05 missile + 0.04 spores + 0.02 stun).
   - Price: 7.02 (1.41 + 4.09 power + 0.47 spores rate + 1.05 stun rate).

   **Gat 2.1 "Twinshot"** (2-shot laser): Laser, Damage, Mechanical, Terran · Shots 2 · Damage 1 · Power 1 ·
   Conduit damage 10%.
   - Charge: 11.1 s. Cost per volley: 0.04. Price: 7.67.
   - For shooting down drones and keeping pressure on shields, not for killing hulls.

   **How it wins:** missiles ignore shields and teleporting ignores normal shields, so it spores your piloting and
   engines (no evasion, no escape), then sends boarders. Against one shield layer the Twinshot lands 1 damage per
   volley, but hull kills aren't its plan.

   **Counters and rewards:** missiles can be shot down (Tentauri defence lasers), and a Supershield blocks
   teleporting, as FTL's Zoltan Shield does; doors, venting and repel-boarder crew work as in FTL. Beating it can
   drop the stolen Sporewing: alien tech as loot.

   **Behaviour (doomed):** on a Hail they demand Mawjig or a ship; when losing, they offer stolen technology to be
   let go.
10. **Price:**

    | Part | Mawjig |
    |---|---|
    | Shields (buy 30.25 + levels 2–4: 24.21 + 4.84 + 7.26) | 66.56 |
    | Engines (installed; levels 2–3: 2.42 + 3.63) | 6.05 |
    | Piloting level 2 | 4.84 |
    | Life Support | starts installed |
    | Weapon Control (buy 4.84 + levels 2–3: 9.68 + 6.05) | 20.57 |
    | Medbay (buy + level 2) | 20.58 |
    | Doors (buy + level 2) | 22.99 |
    | Sensors (buy) | 9.68 |
    | Crew Teleporter (buy + level 2) | 29.04 |
    | AZC level 3 | 72.61 |
    | Sporewing | 7.02 |
    | Gat 2.1 "Twinshot" | 7.67 |
    | **Total** | **267.61** |

    Crew are extra: 5 Terrans at 10.89 each, 54.45.
11. **New rules recorded:** spores and stun cooldown and price rates in `weapon-budget-table.md`.

Judgment calls for review:

- Doomed state, band 5, and the hijacker function.
- Hull 14 and AZC level 3.
- All-Terran crew.
- The Sporewing: missile type (can be shot down) rather than bomb, 1 power, spores priced as ion, stun from FTL's
  Ion Stunner.
- Hail behaviour and the Sporewing as loot.
