# FTL Baseline Numbers

Reference only, nothing decided. Since Infall's mechanics default to FTL's (GDD 1C), these are the starting point
for the paper/economy simulation planned once Infall's races exist.

Tables below are extracted from vanilla FTL's game data (`blueprints.xml`, `dlcBlueprints.xml`,
`autoBlueprints.xml`) with `tools/extract_ftl_baseline.py`. The data files themselves are not in this repo.

## Not in the data files (approximate, from memory of the game)

These values are hard-coded in FTL, so they could not be extracted. Treat them as rough.

| Value | Approximately |
|---|---|
| Beacons per sector | about 20–25; a typical run visits about 10–12 per sector, about 80–100 jumps in total |
| Evasion from engines | about 5% per engine power level early, tapering off near the top levels (around 35% at level 8) |
| Evasion bonuses | a crew member manning the pilot station and the engines each add a few percent, more with skill |
| Shields | one shield layer per 2 power; each layer recharges in about 2 seconds |
| Store prices | fuel about 3 scrap, missiles about 6, drone parts about 8 |
| Hull repair | about 2 scrap per hull point early, more in later sectors |
| Reactor | Kestrel starts at 8 power; maximum 25; each extra bar costs more than the last |
| Enemy scaling | enemy ships get more hull, power and better equipment in later sectors; the formula is hard-coded |
| Scrap rewards | a won fight gives roughly 10–30 scrap early, rising in later sectors |

## Weapons

Cooldown is in seconds (per charge for charge weapons). Missiles = missiles used per volley. SP = shield piercing. Beam length is in pixels. Fire and breach chances are per room hit.

| Weapon | ID | Type | Damage | Shots | SP | Ion | Fire % | Breach % | Cooldown | Power | Missiles | Cost |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Artillery Beam | ARTILLERY_FED | BEAM | 1 | beam 500 | 5 | 0 | 10 | 0 | 40 | 1 | 0 | 0 |
| Mini Beam | BEAM_1 | BEAM | 1 | beam 45 | 0 | 0 | 10 | 0 | 12 | 1 | 0 | 20 |
| Fire Beam | BEAM_FIRE | BEAM | 0 | beam 140 | 0 | 0 | 80 | 0 | 20 | 2 | 0 | 50 |
| Anti-Bio Beam | BEAM_BIO | BEAM | 0 | beam 140 | 0 | 0 | 0 | 0 | 16 | 2 | 0 | 50 |
| Pike Beam | BEAM_LONG | BEAM | 1 | beam 170 | 0 | 0 | 0 | 0 | 16 | 2 | 0 | 55 |
| Halberd Beam | BEAM_2 | BEAM | 2 | beam 80 | 0 | 0 | 0 | 0 | 17 | 3 | 0 | 65 |
| Boss Beam | ARTILLERY_BOSS_3 | BEAM | 2 | beam 100 | 0 | 0 | 0 | 0 | 26 | 1 | 0 | 70 |
| Hull Beam | BEAM_HULL | BEAM | 1 | beam 100 | 0 | 0 | 0 | 0 | 14 | 2 | 0 | 70 |
| Glaive Beam | BEAM_3 | BEAM | 3 | beam 80 | 0 | 0 | 0 | 0 | 25 | 4 | 0 | 95 |
| Healing Burst | BOMB_HEAL | BOMB | 0 | 1 | 0 | 0 | 0 | 0 | 18 | 1 | 1 | 40 |
| Repair Burst | BOMB_HEAL_SYSTEM | BOMB | 0 | 1 | 0 | 0 | 0 | 0 | 14 | 1 | 1 | 40 |
| Small Bomb | BOMB_1 | BOMB | 0 | 1 | 0 | 0 | 10 | 0 | 13 | 1 | 1 | 45 |
| Crystal Lockdown Bomb | BOMB_LOCK | BOMB | 0 | 1 | 0 | 0 | 0 | 0 | 15 | 1 | 1 | 45 |
| Stun Bomb | BOMB_STUN | BOMB | 0 | 1 | 0 | 1 | 0 | 0 | 17 | 1 | 1 | 45 |
| Breach Bomb Mark I | BOMB_BREACH_1 | BOMB | 0 | 1 | 0 | 0 | 0 | 100 | 9 | 1 | 1 | 50 |
| Fire Bomb | BOMB_FIRE | BOMB | 0 | 1 | 0 | 0 | 100 | 0 | 15 | 2 | 1 | 50 |
| Ion Bomb | BOMB_ION | BOMB | 0 | 1 | 0 | 4 | 0 | 0 | 22 | 1 | 1 | 55 |
| Breach Bomb Mark II | BOMB_BREACH_2 | BOMB | 0 | 1 | 0 | 0 | 0 | 100 | 17 | 2 | 1 | 60 |
| Adv. Flak Gun | SHOTGUN_PLAYER | BURST | 1 | 3 | 0 | 0 | 0 | 0 | 8 | 1 | 0 | 60 |
| Flak Gun Mark I | SHOTGUN | BURST | 1 | 3 | 0 | 0 | 0 | 0 | 10 | 2 | 0 | 65 |
| Swarm Missiles | MISSILE_CHARGEGUN | BURST | 1 | 1 per charge, up to 3 charges | 5 | 0 | 10 | 10 | 7 | 2 | 1 | 65 |
| Flak Artillery | ARTILLERY_FED_C | BURST | 1 | 7 | 0 | 0 | 0 | 0 | 40 | 3 | 0 | 75 |
| Flak Gun Mark II | SHOTGUN_2 | BURST | 1 | 7 | 0 | 0 | 0 | 0 | 21 | 3 | 0 | 80 |
| Defense Laser Mark I | LASER_BURST_1 | LASER | 1 | 1 | 0 | 0 | 10 | 0 | 10 | 1 | 0 | 20 |
| Dual Shot Laser | LASER_BURST_2 | LASER | 1 | 2 | 0 | 0 | 10 | 0 | 10 | 1 | 0 | 25 |
| Ion Blast | ION_1 | LASER | 0 | 1 | 0 | 1 | 0 | 0 | 8 | 1 | 0 | 30 |
| Laser Charger | LASER_CHARGEGUN_PLAYER | LASER | 1 | 1 per charge, up to 2 charges | 0 | 0 | 0 | 0 | 5.5 | 1 | 0 | 30 |
| Ion Stunner | ION_STUN | LASER | 0 | 1 | 0 | 1 | 0 | 0 | 10 | 1 | 0 | 35 |
| Boss Ion | ARTILLERY_BOSS_4 | LASER | 0 | 3 | 0 | 1 | 0 | 0 | 28 | 1 | 0 | 40 |
| Heavy Ion | ION_2 | LASER | 0 | 1 | 0 | 2 | 0 | 0 | 13 | 2 | 0 | 45 |
| Burst Laser Mark I | LASER_BURST_2_A | LASER | 1 | 2 | 0 | 0 | 10 | 0 | 11 | 2 | 0 | 50 |
| Heavy Laser Mark I | LASER_HEAVY_1 | LASER | 2 | 1 | 0 | 0 | 30 | 30 | 9 | 1 | 0 | 50 |
| Ion Charger | ION_CHARGEGUN | LASER | 0 | 1 per charge, up to 3 charges | 0 | 1 | 0 | 0 | 6 | 2 | 0 | 50 |
| Boss Laser | ARTILLERY_BOSS_1 | LASER | 1 | 3 | 0 | 0 | 10 | 10 | 20 | 1 | 0 | 55 |
| Heavy Pierce Laser Mark I | LASER_HEAVY_1_SP | LASER | 2 | 1 | 1 | 0 | 30 | 30 | 10 | 2 | 0 | 55 |
| Hull Smasher Laser | LASER_HULL_1 | LASER | 1 | 2 | 0 | 0 | 0 | 20 | 14 | 2 | 0 | 55 |
| Chain Ion | ION_CHAINGUN | LASER | 0 | 1 | 0 | 1 | 0 | 0 | 14 | 3 | 0 | 55 |
| Laser Charger | LASER_CHARGEGUN | LASER | 1 | 1 per charge, up to 2 charges | 0 | 0 | 0 | 0 | 6 | 2 | 0 | 55 |
| PDS SHOT | PDS_SHOT | LASER | 3 | 1 | 5 | 0 | 0 | 100 | 9 | 1 | 0 | 55 |
| Heavy Laser Mark II | LASER_HEAVY_2 | LASER | 2 | 2 | 0 | 0 | 30 | 30 | 13 | 3 | 0 | 65 |
| Chain Burst Laser | LASER_CHAINGUN | LASER | 1 | 2 | 0 | 0 | 10 | 0 | 16 | 2 | 0 | 65 |
| Ion Blast Mark II | ION_4 | LASER | 0 | 1 | 0 | 1 | 0 | 0 | 4 | 3 | 0 | 70 |
| Laser Charger Mark II | LASER_CHARGEGUN_2 | LASER | 1 | 1 per charge, up to 4 charges | 0 | 0 | 10 | 0 | 5 | 3 | 0 | 70 |
| Hull Smasher Laser Mark II | LASER_HULL_2 | LASER | 1 | 3 | 0 | 0 | 10 | 30 | 15 | 3 | 0 | 75 |
| Burst Laser Mark II | LASER_BURST_3 | LASER | 1 | 3 | 0 | 0 | 10 | 0 | 12 | 2 | 0 | 80 |
| Burst Laser Mark III | LASER_BURST_5 | LASER | 1 | 5 | 0 | 0 | 0 | 0 | 19 | 4 | 0 | 95 |
| Chain Vulcan | LASER_CHAINGUN_2 | LASER | 1 | 1 | 0 | 0 | 10 | 0 | 11.1 | 4 | 0 | 95 |
| Crystal Shard | CRYSTAL_1 | MISSILES | 1 | 1 | 5 | 0 | 0 | 10 | 9 | 1 | 0 | 20 |
| Leto Missiles | MISSILES_1 | MISSILES | 1 | 1 | 5 | 0 | 10 | 10 | 9 | 1 | 1 | 20 |
| Crystal Burst Mark I | CRYSTAL_BURST_1 | MISSILES | 1 | 2 | 1 | 0 | 0 | 10 | 15 | 2 | 0 | 20 |
| Crystal Burst Mark II | CRYSTAL_BURST_2 | MISSILES | 1 | 3 | 1 | 0 | 0 | 10 | 17 | 3 | 0 | 20 |
| Heavy Crystal Mark I | CRYSTAL_HEAVY_1 | MISSILES | 2 | 1 | 1 | 0 | 0 | 10 | 13 | 1 | 0 | 20 |
| Heavy Crystal Mark II | CRYSTAL_HEAVY_2 | MISSILES | 4 | 1 | 1 | 0 | 0 | 100 | 19 | 3 | 0 | 20 |
| Artemis Missiles | MISSILES_2_PLAYER | MISSILES | 2 | 1 | 5 | 0 | 10 | 10 | 11 | 1 | 1 | 38 |
| Artemis Missiles | MISSILES_2 | MISSILES | 2 | 1 | 5 | 0 | 10 | 10 | 10 | 2 | 1 | 38 |
| Hermes Missile | MISSILES_3 | MISSILES | 3 | 1 | 5 | 0 | 30 | 20 | 14 | 3 | 1 | 45 |
| Pegasus Missile | MISSILES_BURST | MISSILES | 2 | 2 | 5 | 0 | 30 | 20 | 20 | 3 | 1 | 60 |
| Breach Missiles | MISSILES_BREACH | MISSILES | 4 | 1 | 5 | 0 | 30 | 80 | 22 | 3 | 1 | 65 |
| Hull Missile | MISSILES_HULL | MISSILES | 2 | 1 | 5 | 0 | 10 | 30 | 17 | 2 | 1 | 65 |
| Boss Missile | ARTILLERY_BOSS_2 | MISSILES | 1 | 3 | 5 | 0 | 30 | 20 | 23 | 1 | 0 | 80 |

## Drones

| Drone | ID | Type | Power | Cost |
|---|---|---|---|---|
| System Repair Drone | REPAIR | REPAIR | 1 | 30 |
| Anti-Personnel Drone | BATTLE | BATTLE | 2 | 35 |
| Anti-Combat Drone | ANTI_DRONE | DEFENSE | 1 | 35 |
| Anti-Ship Ion Drone I | COMBAT_ION | COMBAT | 2 | 50 |
| Anti-Ship Missile Drone I | COMBAT_MISSILE | COMBAT | 2 | 50 |
| Combat Drone Mark I | COMBAT_1 | COMBAT | 2 | 50 |
| Anti-Ship Beam Drone I | COMBAT_BEAM | COMBAT | 2 | 50 |
| Defense Drone Mark I | DEFENSE_1 | DEFENSE | 2 | 50 |
| Anti-Ship Fire Drone | COMBAT_FIRE | COMBAT | 3 | 50 |
| Anti-Ship Beam Drone II | COMBAT_BEAM_2 | COMBAT | 3 | 60 |
| Shield Overcharger | DRONE_SHIELD | SHIELD | 3 | 60 |
| Shield Overcharger | DRONE_SHIELD_PLAYER | SHIELD | 2 | 60 |
| Ion Intruder Drone | BOARDER_ION | BOARDER | 3 | 65 |
| Defense Drone Mark II | DEFENSE_2 | DEFENSE | 3 | 70 |
| Defense Drone Mark II | DEFENSE_2_ENEMY | DEFENSE | 3 | 70 |
| Boarding Drone | BOARDER | BOARDER | 3 | 70 |
| Boarding Drone | BOARDER_BOSS | BOARDER | 2 | 70 |
| Hacking Drone | DRONE_HACKING | HACKING | 1 | 70 |
| Combat Drone Mark II | COMBAT_2 | COMBAT | 4 | 75 |
| Defense Drone Mark II | BOSS_DEFENSE_2 | DEFENSE | 2 | 75 |
| Hull Repair | SHIP_REPAIR | SHIP_REPAIR | 2 | 85 |

## Systems

Cost = price to buy the system at a store. Upgrade costs are scrap per level, from level 2 upward.

| System | Start power | Max power | Cost | Upgrade costs |
|---|---|---|---|---|
| Oxygen | 1 | 3 | 0 | 25, 50 |
| Crew Teleporter | 1 | 3 | 90 | 30, 60 |
| Cloaking | 1 | 3 | 150 | 30, 50 |
| Piloting | 1 | 3 | 1 | 20, 50 |
| Medbay | 1 | 3 | 50 | 35, 45 |
| Shields | 2 | 8 | 125 | 100, 20, 30, 40, 60, 80, 100 |
| Artillery Beam | 2 | 4 | 150 | 30, 50, 80 |
| Engines | 2 | 8 | 1 | 10, 15, 30, 40, 60, 80, 120 |
| Weapon Control | 4 | 8 | 20 | 40, 25, 35, 50, 75, 90, 100 |
| Drone Control | 2 | 8 | 60 | 10, 20, 30, 45, 60, 80, 100 |
| Sensors | 1 | 3 | 40 | 25, 40 |
| Door System | 1 | 3 | 60 | 35, 50 |
| Clone Bay | 1 | 3 | 50 | 35, 45 |
| Hacking | 1 | 3 | 80 | 35, 60 |
| Backup Battery | 1 | 2 | 35 | 50 |
| Mind Control | 1 | 3 | 75 | 30, 60 |

## Crew

| Race | ID | Cost |
|---|---|---|
| Human | human | 45 |
| Engi | engi | 50 |
| Mantis | mantis | 55 |
| Slug | slug | 45 |
| Rockman | rock | 55 |
| Crystal | crystal | 60 |
| Zoltan | energy | 60 |
| Battle | battle | 50 |
| Repair | repair | 50 |
| Lanius | anaerobic | 50 |

## Augments

| Augment | ID | Cost |
|---|---|---|
| Long-Ranged Scanners | ADV_SCANNERS | 30 |
| FTL Jammer | FTL_JAMMER | 30 |
| Damaged Stasis Pod | STASIS_POD | 30 |
| Automated Re-loader | AUTO_COOLDOWN | 40 |
| Battery Charger | BATTERY_BOOSTER | 40 |
| Backup DNA Bank | BACKUP_DNA | 40 |
| Lifeform Scanner | LIFE_SCANNER | 40 |
| Reverse Ion Field | ION_ARMOR | 45 |
| Shield Charge Booster | SHIELD_RECHARGE | 45 |
| Mantis Pheromones | CREW_STIMS | 50 |
| Drone Reactor Booster | DRONE_SPEED | 50 |
| Stealth Weapons | CLOAK_FIRE | 50 |
| Repair Arm | REPAIR_ARM | 50 |
| Scrap Recovery Arm | SCRAP_COLLECTOR | 50 |
| FTL Recharge Booster | FTL_BOOSTER | 50 |
| Adv. FTL Navigation | FTL_JUMPER | 50 |
| Drone Recovery Arm | DRONE_RECOVERY | 50 |
| Emergency Respirators | O2_MASKS | 50 |
| Distraction Buoys | FLEET_DISTRACTION | 55 |
| Zoltan Shield Bypass | ZOLTAN_BYPASS | 55 |
| Engi Med-bot Dispersal | NANO_MEDBAY | 60 |
| Slug Repair Gel | SLUG_GEL | 60 |
| Explosive Replicator | EXPLOSIVE_REPLICATOR | 60 |
| Hacking Stun | HACKING_STUN | 60 |
| Fire Suppression | FIRE_EXTINGUISHERS | 65 |
| Reconstructive Teleport | TELEPORT_HEAL | 70 |
| Rock Plating | ROCK_ARMOR | 80 |
| Crystal Vengeance | CRYSTAL_SHARDS | 80 |
| Zoltan Shield | ENERGY_SHIELD | 80 |
| Titanium System Casing | SYSTEM_CASING | 80 |
| Defense Scrambler | DEFENSE_SCRAMBLER | 80 |
| Weapon Pre-igniter | WEAPON_PREIGNITE | 120 |

## Player ships (type A layouts)

| Ship | ID | Hull | Starting reactor power | Starting weapons |
|---|---|---|---|---|
| Kestrel | PLAYER_SHIP_EASY | 30 | 8 | MISSILES_2_PLAYER, LASER_BURST_3 |
| Kestrel Cruiser | PLAYER_SHIP_HARD | 30 | 8 | MISSILES_2_PLAYER, LASER_BURST_3 |
| Mantis Cruiser | PLAYER_SHIP_MANTIS | 30 | 7 | BOMB_1, LASER_BURST_1 |
| Stealth Cruiser | PLAYER_SHIP_STEALTH | 30 | 8 | BEAM_1, LASER_BURST_2 |
| Engi Cruiser | PLAYER_SHIP_CIRCLE | 30 | 10 | ION_4 |
| Federation Cruiser | PLAYER_SHIP_FED | 30 | 8 | LASER_BURST_3 |
| Slug Cruiser | PLAYER_SHIP_JELLY | 30 | 8 | BEAM_BIO, BOMB_BREACH_1, LASER_BURST_2 |
| Rock Cruiser | PLAYER_SHIP_ROCK | 30 | 8 | MISSILES_2_PLAYER, MISSILES_HULL |
| Zoltan Cruiser | PLAYER_SHIP_ENERGY | 30 | 5 | BEAM_2, MISSILES_1 |
| Crystal Cruiser | PLAYER_SHIP_CRYSTAL | 30 | 8 | CRYSTAL_BURST_1, CRYSTAL_HEAVY_1 |
| Kestrel | PLAYER_SHIP_TUTORIAL | 30 | 9 | LASER_BURST_2 |
| Engi Cruiser | PLAYER_SHIP_CIRCLE_HP | 30 | 10 | ION_4 |
| Engi Cruiser | PLAYER_SHIP_CIRCLE_2_HP | 30 | 9 | ION_2, LASER_HEAVY_1 |
| Crystal Cruiser | PLAYER_SHIP_CRYSTAL_HP | 30 | 8 | CRYSTAL_BURST_1, CRYSTAL_HEAVY_1 |
| Crystal Cruiser | PLAYER_SHIP_CRYSTAL_2_HP | 30 | 8 |  |
| Kestrel | PLAYER_SHIP_EASY_HP | 30 | 8 | MISSILES_2_PLAYER, LASER_BURST_3 |
| Zoltan Cruiser | PLAYER_SHIP_ENERGY_HP | 30 | 5 | BEAM_2, MISSILES_1 |
| Zoltan Cruiser | PLAYER_SHIP_ENERGY_2_HP | 30 | 5 | ION_1, ION_1, BEAM_LONG |
| Federation Cruiser | PLAYER_SHIP_FED_HP | 30 | 8 | LASER_BURST_3 |
| Federation Cruiser | PLAYER_SHIP_FED_2_HP | 30 | 9 | LASER_BURST_2, MISSILES_1 |
| Kestrel Cruiser | PLAYER_SHIP_HARD_HP | 30 | 8 | MISSILES_2_PLAYER, LASER_BURST_3 |
| Kestrel Cruiser | PLAYER_SHIP_HARD_2_HP | 30 | 8 | LASER_BURST_1, LASER_BURST_1, LASER_BURST_1, LASER_BURST_1 |
| Slug Cruiser | PLAYER_SHIP_JELLY_HP | 30 | 8 | BEAM_BIO, BOMB_BREACH_1, LASER_BURST_2 |
| Slug Cruiser | PLAYER_SHIP_JELLY_2_HP | 30 | 7 | BOMB_HEAL, MISSILES_2_PLAYER |
| Mantis Cruiser | PLAYER_SHIP_MANTIS_HP | 30 | 7 | BOMB_1, LASER_BURST_1 |
| Mantis Cruiser | PLAYER_SHIP_MANTIS_2_HP | 30 | 11 |  |
| Rock Cruiser | PLAYER_SHIP_ROCK_HP | 30 | 8 | MISSILES_2_PLAYER, MISSILES_HULL |
| Rock Cruiser | PLAYER_SHIP_ROCK_2_HP | 30 | 8 | LASER_HEAVY_1_SP, BOMB_FIRE, BOMB_1 |
| Stealth Cruiser | PLAYER_SHIP_STEALTH_HP | 30 | 8 | BEAM_1, LASER_BURST_2 |
| Stealth Cruiser | PLAYER_SHIP_STEALTH_2_HP | 30 | 7 | BEAM_3 |
| Engi Cruiser | PLAYER_SHIP_CIRCLE_R1_HP | 30 | 10 | ION_4 |
| Kestrel Cruiser | PLAYER_SHIP_HARD_R1_HP | 30 | 8 | MISSILES_2_PLAYER, LASER_BURST_3 |
| Lineman Type I | PLAYER_SHIP_DESIGN_1_HP | 30 | 6 | ION_1, BEAM_1, MISSILES_2 |
| Lanius Cruiser | PLAYER_SHIP_ANAEROBIC | 30 | 8 | LASER_CHAINGUN, ION_STUN |
| Lanius Cruiser | PLAYER_SHIP_ANAEROBIC_HP | 30 | 8 | LASER_CHAINGUN, ION_STUN |
| Lanius Cruiser | PLAYER_SHIP_ANAEROBIC_2_HP | 30 | 8 | SHOTGUN_PLAYER |
| Shrike Cruiser | PLAYER_SHIP_ANAEROBIC_3_HP | 30 | 8 | LASER_BURST_3 |

## Enemy ship templates (base values before sector scaling)

| Template | Hull | Base reactor power |
|---|---|---|
| REBEL_FAT | 9 | 8 |
| REBEL_SKINNY | 10 | 7 |
| REBEL_SKINNY_ELITE | 14 | 13 |
| REBEL_TRANSPORT | 9 | 8 |
| AUTO_BASIC | 6 | 6 |
| AUTO_ASSAULT | 8 | 7 |
| JELLY_BUTTON | 9 | 7 |
| JELLY_CROISSANT | 10 | 7 |
| JELLY_TRUFFLE | 11 | 10 |
| ROCK_SCOUT | 8 | 10 |
| ROCK_FIGHT | 10 | 7 |
| ROCK_ASSAULT | 12 | 7 |
| ROCK_ASSAULT_ELITE | 12 | 12 |
| MANTIS_SCOUT | 7 | 10 |
| MANTIS_FIGHTER | 9 | 11 |
| MANTIS_BOMBER | 11 | 11 |
| FED_SCOUT | 7 | 10 |
| FED_BOMBER | 9 | 7 |
| CIRCLE_SCOUT | 7 | 8 |
| CIRCLE_BOMBER | 9 | 8 |
| ZOLTAN_FIGHTER | 7 | 7 |
| ZOLTAN_BOMBER | 7 | 9 |
| ZOLTAN_PEACE | 7 | 12 |
| CRYSTAL_SCOUT | 7 | 9 |
| CRYSTAL_BOMBER | 9 | 9 |
