# Weapons for the Godot version

**Ai-Generated-Proposal (2026-11-14)**, asked by heromedel through Infall: Godot Version: the genre's weapons the game
lacked, each in its race's naming style (race profiles) and the game's `weapon.xml` form. Shapes follow the genre
(`docs/reference/ftl-baseline.md`); charge time and price come from `weapon-budget-table.md` and cost per volley from
`mawjig-cost-table.md`, as for the game's other weapons. Bands follow the band rule (`ship-design-process.md`: nothing
new to the genre in band 1, complicated things later).

| Weapon | Race | Genre shape | Power | Charge (s) | Price | Cost | Bands | Carried by (squad) | Sold at |
|---|---|---|---|---|---|---|---|---|---|
| Gat 2.2 "Sledge" | GATOS | heavy laser, 2 × 2 damage | 3 | 17.4 | 17.14 | 0.11 | 4–8 | GATOS Checkpoint (bands 4–8), Last Fleet | GATOS stores |
| Gat B1 "Scythe" | GATOS | mid beam, 1 damage, 4 rooms | 2 | 20.0 | 12.15 | 0.12 | 2–8 | GATOS Checkpoint (bands 2–6) | GATOS stores |
| Gat B2 "Reaper" | GATOS | high beam, 2 damage, 2 rooms | 3 | 20.0 | 16.24 | 0.11 | 4–8 | GATOS Checkpoint (bands 6–8), Last Fleet | GATOS stores |
| Gat I2 "Brownout" | GATOS | heavy ion, 2 ion | 2 | 12.0 | 10.49 | 0.04 | 3–8 | GATOS Pirates (bands 4–8) | GATOS stores |
| Gat IC3 "Capacitor" | GATOS | ion charger, up to 3 charges | 2 | 4.8 per charge | 10.71 | 0.04 | 3–8 | GATOS Pirates (bands 5–8) | GATOS stores |
| Gat X2 "Torch" | GATOS | fire bomb | 2 | 15.0 | 15.91 | 0.08 | 3–8 | GATOS Pirates (bands 5–8) | GATOS and pirate-held stores |
| Gat X3 "Blackout" | GATOS | ion bomb, 4 ion | 1 | 22.0 | 12.02 | 0.07 | 3–8 | GATOS Checkpoint (bands 4–8) | GATOS stores |
| FB-MR Fire Beam | Mecha | fire beam, 3 rooms, no damage | 2 | 19.2 | 11.27 | 0.15 | 4–8 | Mecha Raiders (bands 5–8) | Mecha stores |
| HM-ST Hull Missile | Mecha | hull missile, 2 damage, hull bonus | 2 | 12.3 | 13.26 | 0.11 | 3–8 | Mecha Light Attack and Raiders (bands 3–8) | Mecha stores |
| LB-SR Lockdown Bomb | Mecha | lockdown bomb | 1 | 15.0 | 12.54 | 0.09 | 4–8 | Mecha Light Attack (bands 4–8), with a Suit Dock | Mecha stores |
| Chase | Lykario | chain laser, 2 shots | 2 | 15.6 | 11.22 | 0.04 | 3–8 | Lykario Pack (bands 3–8) | rarely sold (Lykario build few weapons) |
| Pack Call | Lykario | healing bomb | 1 | 18.0 | 12.54 | 0.11 | 3–8 | Lykario Pack (bands 4–8) | rarely sold |
| Grasp | Tentauri | ion stunner (ion + stun) | 1 | 11.5 | 7.02 | 0.06 | 2–8 | Tentauri Passage (bands 2–8) | Tentauri stores |
| Bud | Tentauri | repair bomb | 1 | 14.0 | 12.54 | 0.16 | 3–8 | Tentauri Passage (bands 4–8) | Tentauri stores |
| Brood Swarm | Malphen | swarm missiles, up to 3 charges | 2 | 4.7 per charge | 12.53 | 0.06 | 6–8 | Malphen Growth (bands 6–8) | none (Malphen don't trade) |

The fire beam for a race other than the Senti is the Mecha's: they gut ships. The fire bomb is the GATOS'.

## New rules these need

| Rule | Attribute | What it should do |
|---|---|---|
| Charges | `charges="3"` | The weapon stores up to that many volleys, one per `charge` seconds, and can fire any number it holds at once (the genre's charge weapons). |
| Chain | `chain="yes"` | Each volley fired without a break shortens the next charge (the genre's chain weapons: down to about half, over three volleys); it resets if the weapon goes unpowered or stops firing. |
| Heal | `heal="30"` | A bomb that heals every crew member of its owner's side in the room it lands in, by that much health, on either ship (to heal boarders). |
| Lockdown | `lockdown="10"` | A bomb that seals the doors of the room it lands in for that many seconds: no crew enters or leaves. |
| Repair | `repair="2"` | A bomb aimed at one of its own systems that repairs that much system damage. |

Prices for heal, lockdown and repair add 1.5 by judgment, since the budget table has no row for them (the cost table
has heal 0.05, lockdown 0.04 and repair 0.11 per shot, used here). The genre's charge times for some of these are
shorter (heavy laser II 13 s, Pike 16 s); the budget table's are used so the game's pricing stays consistent.
