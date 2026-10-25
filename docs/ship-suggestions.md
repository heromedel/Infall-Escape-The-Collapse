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

## SC-1 "Outrider": Terran starting scout (2026-10-22)

**Name — Decided (2026-10-23):** Outrider, a scout that rides out ahead of a convoy, as this ship does for the
colony ship. **Designation — Decided (2026-10-23):** SC-1 (scout cruiser, model 1), in the Gatos
style of designation plus name.

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
   player ship. **Rooms — Likely (2026-10-23):** 10 bigger rooms rather than
   the Kestrel's many small ones, from Arty's floor layout test 3: the bridge holds Piloting, Weapons and Shields;
   one room holds Sensors and Doors; the engine room holds Engines and Life Support; Medbay and the AZC core room
   have their own; 5 rooms are empty, for systems bought later. The ship's floor area is about the Kestrel's
   (GDD 3D).

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

   **Conduits: a wheel — Ai-Generated-Proposal (2026-10-23).** The AZC room sits in the middle of the ship,
   armoured. A rim loop runs through every system room, so every system has two paths to power. Four spokes run
   from the AZC (forward, port, starboard, aft) and join the rim at spread-out points. No single cut unpowers
   anything; two cuts only cut off the systems between them; losing everything takes four cuts. That is the "easy
   to reroute" starting ship, a ring around the core at full ship size (heromedel's wording). Higher-tier Terran
   ships can use a plain ring, a figure-eight or branching conduits, where cuts matter more.
   - Earlier version: one loop leaving the AZC by only two exits. Two cuts at those exits killed every system;
     heromedel spotted it in Arty's floor layout test 2.

   Passes made:
   - Pass 1: a Kestrel copy at AZC level 3 (6 systems). Too strong: everything runs at once, so no power choices.
   - Pass 2: AZC level 2, restoring FTL's power tension; one system off at a time.
   - Pass 3: gave the scout Sensors 2 for longer map range (GDD 2E), paid for with a weaker missile than the
     Kestrel's (1 damage instead of 2).
   - Pass 4: conduit ring so a single cut never isolates a system; checked every system room has two paths
     (later found to miss the core's two exits; replaced by the wheel).
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
- The wheel conduit layout as what "easy to reroute" means.
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

   **Conduits:** a ring like the Outrider's, plus one spur out to the bolted-on launcher. Cut the spur and
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

### Pirate Hijacker loadouts (2026-10-23)

**Ai-Generated-Proposal (2026-10-23)**, except where tagged. Asked by heromedel through Infall: Production (handoff
2026-10-23 20:52): one hull with a loadout per band range (**Proposed**, `ship-design-process.md`). The new bands
1–3 loadout is nicknamed **"Cutpurse"**: a small-time thief, in the Gatos style of a nickname on the ship.

| | Cutpurse (new) | Hijacker (existing, unchanged) |
|---|---|---|
| Bands | 1–3 | 4–6 |
| Hull | 9 | 14 |
| AZC level | 2 (4 systems at once) | 3 (6 systems at once) |
| Piloting | 1 | 2 |
| Sensors | — | 1 |
| Doors | — | 2 |
| Shields | 1 layer (shield test level 1) | 2 layers |
| Engines | 1 | 3 |
| Life Support | 1 | 1 |
| Weapons | 1 | 3 |
| Medbay | — | 2 |
| Crew Teleporter | 1 | 2 |
| Weapons carried | Sporewing | Sporewing, Gat 2.1 "Twinshot" |
| Crew | 3 Terrans | 5 Terrans |
| Price | **130.46** | 267.61 |

Same hull and silhouette: the classic Terran cruiser with rust, mismatched panels, darker paint (falling Gatos,
Decided) and the bolted-on Azurethea launcher.

**Cutpurse price:** Shields 54.46 · Weapon Control level 1 4.84 · Crew Teleporter level 1 21.78 · AZC level 2 42.36 ·
Sporewing 7.02 · Piloting, Engines and Life Support installed = **130.46**, under band 1's squad value budget (137).
Crew are extra: 3 Terrans at 10.89, 32.67.

**Ideas considered:** keep the teleporter and drop the guns (picked); keep the Twinshot and drop the teleporter, so
the "hijack" becomes a shakedown by Hail; keep both and drop the shields; a two-ship pirate pair, one disabler and one
boarder; a smaller hull. Picked because it keeps what makes it a hijacker, a disabler and boarders, at the lowest
price. Passes: (1) scaled-down copy, 174 (over budget); (2) dropped the Medbay, so boarders don't heal; (3) dropped
the Twinshot, since it can't hurt a shielded ship much and a hijacker doesn't want hull damage; (4) dropped Doors,
since the Outrider can't board back; (5) simulated, found the stun-lock below and set the squad's targeting rule;
(6) checked the result against the hijacker identity and the Outrider.

#### How it hijacks with less

- **What it lacks:** no gun that hurts the hull, no Medbay (hurt boarders stay hurt), no Doors or Sensors, a
  level 1 teleporter (slow to recharge), and only 4 of its 5 power-drawing systems at once: it usually runs Life
  Support off during a fight and turns it back on after.
- **Its big weakness:** with no Doors system it can't vent a fire, and with no Medbay its burnt crew stay hurt. A
  fire, or fire weapons, can wreck it (heromedel: fine as is).
- **What it goes for first:** the Sporewing hits the Outrider's **Weapons**, so the Outrider can't gut it while
  the boarders work. Then the 2 boarders go in, and one Terran stays to pilot.
- **When the Outrider's shield holds:** it doesn't matter. The Sporewing is a missile and teleporting ignores a
  normal shield, so its plan never needs the shield down.
- **Shield check:** it can't hurt a shielded ship's hull at all; it beats a ship by boarding, which a shield doesn't
  stop.

#### Economy checks against the Outrider

Simulated, 2,000 fights each; same assumptions as the Mecha pair, plus a Sporewing hit disabling the Outrider's
Weapons for about 8 s of repair. Boarding isn't simulated: it costs crew health, not Mawjig.

| | Fight | Outrider shots | Pays (destroyed / crew killed) | Left after jump and shots |
|---|---|---|---|---|
| Band 1, one Cutpurse | about 72 s | 0.39 | 3.26 / 4.24 | 1.66 (no hull damage) |
| Band 3, two Cutpurses | about 150 s | 0.77 | 7.82 / 10.18 | 5.84 (no hull damage) |

**Stun-lock found:** two Cutpurses both aiming at the Outrider's Weapons keep them disabled almost the whole time
(about 680 s; a Sporewing every 6.9 s against an 8 s repair). The squad rule below fixes it: only one aims at
Weapons, the other at Piloting.

#### Squad: Terran Pirates (rough squad format)

**Shows up in:** doomed Terran clusters, and borders (including Mecha borders, where criminals hide).

| Tier | Ships |
|---|---|
| Low (bands 1–3) | Bands 1–2: 1 × Cutpurse. Band 3: 1–2 × Cutpurse (2 = 260.92, under 414) |
| Mid (bands 4–6) | 1–2 × Hijacker |
| High (bands 7–8) | [heavy pirate ship] · [Hijacker high-band loadout] (placeholders) |

Conduct, only where it differs from the Hijacker:
- **Targeting:** with two or more Cutpurses, only one aims its Sporewing at Weapons; the others aim at Piloting, to
  stop the target escaping.
- **When losing:** a Cutpurse has no stolen tech to spare beyond its one launcher, so it offers Mawjig to be let go
  rather than technology.

#### Judgment calls and decisions needed

- The Cutpurse nickname; hull 9; AZC level 2 with Life Support off in a fight.
- Dropping the Twinshot, Medbay, Doors and Sensors.
- The fight assumptions: 8 s to clear a spore-disabled system; 15% Outrider evasion, 5% pirate evasion.
- **Can a bands 1–3 pirate afford a crew teleporter?** Yes, at level 1 (21.78), by dropping the gun, Medbay, Doors
  and Sensors.
- The stun-lock targeting rule is needed for any squad with more than one Sporewing.

## Mecha Light Attack Frame, two loadouts (2026-10-23)

Default tag: **Ai-Generated-Proposal (2026-10-23)**; points taken from the race profile are tagged as they are
there. Asked by heromedel through Infall: Production (handoff 2026-10-23 14:17).

1. **Race:** the Mecha (HalfMechs).
2. **Band:** 1–3 (low tier).
3. **State:** a doing-fine Mecha region, met at its Border clusters. The profile says Mecha borders are in
   constant battle with their neighbours and with criminals (Proposed), which is where a light attack pair patrols.
4. **Race info used (Proposed unless noted):** aggressive, organized and tactical; guts ships; wide, aggressive
   battleships; gunmetal and black with hazard markings (Ai-Generated-Proposal); weapons high damage and hull
   destructive; EVB Dock with battlesuits, crew flying out in them; no reactor, each system self-powered, and a
   Mecha crew member integrating with a system adds one bar; a single weapon system is hard for them to power;
   Mecha breathe (Likely); low tier (Ai-Generated-Proposal): one EVB Dock with laser suits plus one or two
   self-powered weapon systems with a hull-damage laser, thin shields.
5. **Function:** a light attack squad of two. Ideas considered: two hulls (a gunship and a dock carrier); one hull
   in two loadouts; two identical gunships; a pair of suit carriers; a spotter with a gunship. **Picked: one hull
   in two loadouts.** An organized, tactical race fields a standard frame, the pair reads as one unit in a
   screenshot (concern 2), and each loadout still has a clear job. Note for Production: this is one hull, not two,
   towards Goal A's hull count.
6. **Kinds of systems and crew:** one standard frame, thin shields, little evasion. The **Hull Laser** loadout
   guts hulls; the **Suit Dock** loadout launches a laser battlesuit that strips shields. 2 crew each.
7. **Variation:** standard for the race at low tier.
8. **Layout and systems:** the **Light Attack Frame**: wide and squat, with the weapon pod or dock on the flank,
   in gunmetal and black with hazard markings. Hull 7 (the low end of the band 1–3 stand-ins, since these are light
   ships). No reactor: every system carries its own power, and an integrated crew member adds one bar.

   | System | Hull Laser loadout | Suit Dock loadout | Own power (bars) |
   |---|---|---|---|
   | Piloting | 1 | 1 | — |
   | Doors | 1 | 1 | — |
   | Shields (shield test level 1, one layer) | 1 | 1 | 2 |
   | Engines | 1 | 1 | 1 |
   | Life Support | 1 | 1 | 1 |
   | Cybernetic Servicing Core (the Mecha Medbay) | 1 | 1 | 1 |
   | Weapon pod | 2 | — | 1, +1 from an integrated crew member |
   | EVB Dock | — | 2 | 2 |
   | **Own power in all** | | | **6 / 7** |

   - **Hull Laser:** the pod is level 2, since a system never holds more power than its level (GDD 1C), but it
     has only one bar of its own, so one crew member integrates with it to power its 2-power laser.
     That is the profile's "a single weapon system is hard to power" in play: stun, kill or pull that crew member
     away and the laser goes quiet.
   - **Suit Dock:** one crew member flies the laser battlesuit; the other pilots. The suit carries its own air for a
     sortie.
   - **Weak points:** Life Support (Mecha breathe, Likely: one of them has to stop and repair it) and the crew
     member in the weapon pod.

   Passes made:
   - Pass 1: two full ships, each with a dock and two pods. Too strong for bands 1–3 against a lone starting ship.
   - Pass 2: split the jobs, one loadout each, on one frame.
   - Pass 3: the Hull Laser's pod needs an integrated crew member, making the crew a target.
   - Pass 4: hull 7 rather than 10, as light ships. Simulated at hull 10, the fight runs about 86 s and leaves
     1.82 instead of 2.69: workable, but heavier than a light pair should be.
   - Pass 5: the suit can't get through a shield layer alone (its shots come about 3 s apart and the layer comes back
     in 2 s), so its job is popping the layer for the Hull Laser.
   - Pass 6: checked against the Outrider in a simulation (see 9).
9. **Weapons:** no Mecha weapons exist yet.

   **Double Shot - Single Target - Hull Laser** (DS-ST Hull Laser): Laser, Damage + Hull bonus, Mechanical, Mecha
   · Shots 2 · Damage 1 · Power 2 · Breach 20% · double damage to a room without a system.
   - Charge: 12.8 s (7.0 + 4.0 damage + 0.4 breach + 1.4 hull bonus).
   - Cost per volley: 0.07 Mawjig (2 × (0.02 + 0.01 hull bonus + 0.006 breach)).
   - Price: 13.12 (1.41 + 8.18 power + 1.81 damage rate + 0.36 breach rate + 1.36 hull bonus).

   **Laser battlesuit** (suit type for the EVB Dock): one Mecha in a battle suit with a 1-damage laser, priced as
   the laser combat drone, 12.11. Each sortie costs 0.21 Mawjig (about 10 shots), the EVB cost idea in `ideas.md`.

   **Shield check:** the Hull Laser's two shots beat one layer (the first takes it, the second lands, double in an
   empty room). With the suit popping the layer, both land.

   **Economy check:** a simulation of 2,000 fights of the Outrider against this pair. The Outrider fires at the
   Hull Laser first. Assumptions: 15% Outrider evasion, 5% Mecha evasion, the suit firing every 3 s, out 30 s and
   back 15 s, half the Outrider's rooms empty. Result: the fight lasts about 62 s, and the Outrider loses about 5
   hull (4.9) and spends 0.59 Mawjig on shots. Under GDD 8I a wreck pays 2.5% of the ship's value × the band adjustment, so in band 1 the pair would
   pay 6.74 (3.29 + 3.45); after the 1.21 jump, the shots and repairing 4.9 hull at 0.48, about 2.59 is left. Band
   1's squad value budget (137) fits only one frame, though, so the pair belongs in band 3 (see the squad). Each loadout alone pays 0.80 (Hull Laser) or
   1.92 (Suit Dock, which can't hurt a shielded ship by itself).
10. **Price:**

    | Part | Hull Laser | Suit Dock |
    |---|---|---|
    | Shields (shield test level 1) | 54.46 | 54.46 |
    | Piloting, Engines, Life Support | installed | installed |
    | Doors | 14.52 | 14.52 |
    | Cybernetic Servicing Core (priced as a Medbay for now) | 12.11 | 12.11 |
    | Weapon pod (Weapon Control level 2: 4.84 + 9.68) | 14.52 | — |
    | EVB Dock level 2 | — | 16.94 |
    | Own power (6 / 7 bars, priced as reactor bars) | 22.99 | 27.83 |
    | DS-ST Hull Laser / laser battlesuit | 13.12 | 12.11 |
    | **Total** | **131.72** | **137.97** |

    Crew are extra: 2 Mecha each at 14.52, 29.04.
11. **New rules recorded:** the Hull bonus effect's charge time and price in `weapon-budget-table.md`; Mecha
    self-powered bars priced as reactor bars in `system-prices.md`.

### Squad: Light Attack Pair (LAP)

**Ai-Generated-Proposal (2026-10-23)**, a first draft of a squad format, as Production asked. heromedel's view is
that a squad is mainly a list of ships with counts per tier (`rough-example-squad-layout.md`); the conduct lines
below are the extra this brief asked for.

- **Ships:** 1 × Light Attack Frame, Hull Laser loadout; 1 × Light Attack Frame, Suit Dock loadout.
- **Shows up in:** Border clusters of a doing-fine Mecha region, band 3 (bands 1–2 field a single frame).
- **Size by band:** set by the squad value budgets in `mawjig-cost-table.md`. Bands 1–2 (budgets 137 and 173): one
  frame, either loadout, alone, or a pair of weaker ships or loadouts that fits the budget (not designed yet).
  Band 3 (414): the pair (269.69), or 2 Hull Laser + 1 Suit Dock (401.41).
- **How the two fight together:** the Suit Dock launches its suit at once, at the target's shield room, to keep the
  layer down. The Hull Laser fires at rooms without systems, for double damage, to gut the hull. Both pick the
  weakest ship in the player's squad.
- **Hail:**
  - When they have the advantage: they demand Mawjig to let the player pass, or attack.
  - When outmatched: they order the player out of their territory; jumping away ends it without a fight.
- **Surrender:** they offer one only if they profit and are hurt: 25% chance once a ship is down to 2–3 hull. They
  pay about half a ship's reward and let the player pass.
- **Escape:** a ship down to 2–3 hull tries to jump away 50% of the time, charging for about 20 s. The Suit Dock
  recalls its suit first.
- **A win pays (per ship, GDD 8I):** 2.5% of the ship's value × the band adjustment; crew killed pays about 30%
  more. Hull Laser (131.72): 3.29 / 3.62 / 3.95 in bands 1 / 2 / 3, crew killed 4.28 / 4.71 / 5.14. Suit Dock
  (137.97): 3.45 / 3.79 / 4.14, crew killed 4.48 / 4.93 / 5.38. The crew are tough and dangerous in melee, so
  killing them is the harder road.

### Judgment calls and open decisions

- One hull in two loadouts rather than two hulls.
- Border clusters of a doing-fine region as the state.
- Hull 7 and the fight assumptions in the economy check.
- Hull bonus priced from FTL's two Hull Smasher lasers: +0.7 s per shot and 0.75 of the damage rate.
- A suit's sortie: 10 shots, out 30 s, back 15 s.
- Surrender 25% and escape 50% at 2–3 hull, and a 20 s escape charge.
- **Open:** how crew integration works in play: how long engaging and disengaging takes, and whether it is always
  one bar. Assumed here: one bar, a few seconds each way, and never above the system's level (so the Hull Laser's
  pod is level 2). Integration never raises a system past its level (Decided; race profile, Mecha 9).
- **Answered (race profile, Mecha 6):** a suit has its own oxygen, draining from launch until it is back aboard;
  running out means slow asphyxiation.
- **Answered (race profile, Mecha 6):** the first hit leaves a suit damaged, unable to fire and briefly stunned,
  and it can return to a squad ship; a second hit destroys the suit and its occupant.
- **Shared between the two ships:** nothing at system level. The pair shares only tactics: the suit pops the shield
  for the Hull Laser.
