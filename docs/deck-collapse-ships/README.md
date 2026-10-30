# Ships for Infall: Deck Collapse

**Ai-Generated-Proposal (2026-10-29)** unless a ship's source says otherwise. One ship per race, in Deck Collapse's
ship XML (`deck-collapse/data/ships/` on `claude/lucid-maxwell-l3wlt6`), expanded where the game has no rule yet.
Each gap is designed as if it existed, marked in the file with a reference (G1, G2 …) and listed below, so the
coder can add it. No art or floor layouts: Deck Collapse has none yet.

## Ships

| File | Race | Ship | Band | About (Mawjig, no crew) | Source |
|---|---|---|---|---|---|
| `sc-1-outrider.xml` | Terran (GATOS) | SC-1 Outrider | player start | 181 | `ship-suggestions.md` |
| `pirate-hijacker.xml` | Terran (pirates) | Pirate Hijacker | 4–6 | 266 + surcharge | `ship-suggestions.md` |
| `loadout.pirate-hijacker.cutpurse.xml` | Terran (pirates) | Cutpurse | 2–3 | 130 | `ship-suggestions.md` |
| `loadout.pirate-hijacker.pickpocket.xml` | Terran (pirates) | Pickpocket | 1 | 131 | `ship-suggestions.md` |
| `tentauri-burr.xml` | Tentauri | Burr | 3 | 189 | `ship-suggestions.md` |
| `loadout.burr.pappus.xml` | Tentauri | Pappus | 1 | 132 | `ship-suggestions.md` |
| `light-attack-frame.xml` | Mecha | Light Attack Frame (Hull Laser) | 1–3 | 132 | `ship-suggestions.md` |
| `loadout.light-attack-frame.suit-dock.xml` | Mecha | Light Attack Frame (Suit Dock) | 2–3 | 138 | `ship-suggestions.md` |
| `azurethea-vein-moth.xml` | Azurethea | Vein Moth | 1–2 | 130 | `ship-suggestions.md` |
| `senti-relay-picket.xml` | Senti-GPH | Relay Picket | 3 | 182 | `ship-suggestions.md` |
| `loadout.outrider.scrap-hound.xml` | Lykario | Scrap Hound (a stolen Outrider) | 1–2 | 136 | `ship-suggestions.md` |
| `malphen-polyp.xml` | Malphen | Polyp | 1, in threes | 38 | `ship-suggestions.md` |
| `loadout.malphen-polyp.flak.xml` | Malphen | Polyp (Flak) | 1, in threes | 41 | `ship-suggestions.md` |
| `whispwraith-mote.xml` | Whispwraith | Mote | inside the collapse | 65 | Deck Collapse only (not an Infall design yet) |

Values are rough sums from `docs/reference/` (systems, reactor bars, weapons); Deck Collapse works out its own.
Band 1's squad budget is 137, so a band 1 squad is one Pickpocket, Pappus, Vein Moth, Scrap Hound or Light
Attack Frame (Hull Laser), or three Polyps. No non-vanilla weapon types or EVB suits in band 1 (Decided,
`ship-design-process.md`).

The open-stern Light Attack Frame is a floor layout change only, so it waits for floor layouts (G19).

## Gaps for the coder

| Ref | Gap | What the files ask for | Source |
|---|---|---|---|
| G1 | Races | `race` on ships and crew, and each race's crew traits (Tentauri run up to four systems in a room; Mecha integrate for one bar; Azurethea half HP and make air; Senti half HP, no oxygen, fire immune, ion disrupts; Lykario quick attacks and Animal Senses; Malphen high HP and slow healing aboard; Whispwraith heal in their own air) | race profiles, point 9 |
| G2 | Power models | `<power kind="pool" level>` (the genre's reactor); `kind="AZC" level` (each level powers 2 drawing systems at full; `draws="false"` systems take none); `kind="self"` with `ownPower` per system (Mecha); `kind="crew" barsPerCrew="2"` (Whispwraith) | race profiles 6; `system-prices.md` |
| G3 | Weapon systems with slots | a weapon system holds several `<weapon>`s; its level sets its slots and bars; `maxSlots` caps it | GDD 8L |
| G4 | Per-weapon stats | `power`, `shots`, `damage` and effects on each weapon, instead of a fixed row per Type | `weapon-budget-table.md` |
| G5 | Spores and stun | `spores="true"`: the hit system is disabled until cleared like a repair; `stun="true"` stuns crew there; no breach or fire | `ship-suggestions.md` (Sporewing) |
| G6 | Flak | `kind="flak"`: several projectiles, each can pop a shield layer | Malphen profile |
| G7 | Defensive | `defensive="true"`: shoots down an incoming torpedo when not aimed | Tentauri Defense Laser |
| G8 | Hull bonus | `hullBonus="true"`: double damage to a room without a system (needs rooms, G19) | DS-ST Hull Laser |
| G9 | Conduit damage | `conduitDamage` percent; matters once conduits and floor layouts exist (G19) | GDD 5H; Terran weapons |
| G10 | Foreign tech | `tech` on a weapon; on another tech type's system it charges 20% slower | GDD 8D |
| G11 | Supershield Generator | an extra energy layer that recharges over time, capacity 5, blocks teleporting | `system-prices.md` |
| G12 | AAA | Senti avatar array; built in Deck Collapse (2026-10-30, heromedel's design): replaces the Med Bay on Senti ships, hosts 3 Senti per working level, brings dead Senti back. The three crew killers carry one (Census Picket level 1, Quiet Ledger and Final Archive level 2), and every plan line aimed at a Med Bay has an AAA twin for Senti targets | Senti profile 6 |
| G13 | Growth organ | Malphen clone bay: grows a dead crew member back unless the organ is destroyed | Malphen profile 1, 6 |
| G14 | Cybernetic Servicing Core | the Mecha Medbay (heals any race); where Mecha upgrade their mechs | Mecha profile 9 |
| G15 | Atmosphere | Life Support can make a race's own air (`atmosphere`); Senti ships may skip Life Support | Whispwraith and Senti profiles |
| G16 | Beam rooms | `rooms` swept by a beam | `weapon-budget-table.md` |
| G17 | Laser battlesuit | suit type `laser`: one Mecha in a suit with a 1-damage laser | `ship-suggestions.md` (Light Attack Frame) |
| G18 | Loadout files | `loadout.ship.name.xml` patches its ship (`inherit="Patch"`, `removed="true"`, crew given whole) | GDD 5J |
| G19 | Floor layouts | rooms, tiles, doors and conduits; the four existing designs already have them (`ship-suggestions.md`; `content/ships/` on `Cloud-C-Init-Coding`) | GDD 5F–5L |

## Judgment calls

- One ship per new race, all low tech, the first tier a player meets. Names are working names; Malphen and
  Whispwraith ship names are what others would call them.
- Crew are named by role (Pilot, Gunner …) rather than invented personal names.
- **Vein Moth:** one weapon system at level 2, no Sensors; the profile's two low-tech shots, a Stinger and a single-shot beam ("Lantern", a firefly's light organ; Azurethea weapons are insect parts).
- **Relay Picket:** two beams and Sensors 2; no Life Support, since Senti don't breathe. It costs more than a band 1
  budget allows, so band 3.
- **Scrap Hound:** a stolen, battered Outrider (a loadout of it, G18): no Sensors (Animal Senses), Auto Pilot so the pilot can board, a stolen Twinshot.
- **Polyp:** a swarm ship of about 38, so three fit band 1; a flak loadout mixes shield-poppers into the swarm.
- **Mote:** 4 bars from 2 crew: Shields (2), Engines (1) and one ion blast (1). "Hush" as a strange, alien name.

## Senti crew killers (2026-10-29)

**Ai-Generated-Proposal (2026-10-29)**, asked by heromedel: Senti-GPH ships whose goal is killing the crew, not the
ship, to be tested in Deck Collapse. Doomed Senti have no qualms about killing living people, while still storing
their data (race profile 4). Their own crew are holograms: half health, immune to fire, no air needed, so fire,
breaches and venting are weapons they can use without fear.

| File | Ship | Bands | How it kills crew | Rules used |
|---|---|---|---|---|
| `senti-crew-killers/senti-census-picket.xml` | Census Picket | 3–4 | a fire beam sets each swept system burning; a beam wounds everyone it sweeps; Hacking keeps the Med Bay down | Deck Collapse's current rules |
| `senti-crew-killers/senti-quiet-ledger.xml` | Quiet Ledger | 5–6 | fire in some systems, breaches in others, then holograms teleport into rooms nobody else can live in | Deck Collapse's current rules |
| `senti-crew-killers/senti-final-archive.xml` | Final Archive | 7–8 | an anti-bio beam and bio bombs hurt crew only, so the ship is kept | G20, G21 |

New gaps:

| Ref | Gap | What the file asks for |
|---|---|---|
| G20 | Crew-only damage | `crewDamage`: health pips each crew member in a hit system loses, on top of (or instead of, with `damage="0"`) system damage; the genre's anti-bio beam |
| G21 | Bombs | `kind="bomb"`: teleported straight into a system, so it ignores shields and can't be shot down; uses one missile per shot, as every genre bomb does (`ftl-baseline.md`). Senti use beams and lasers far more, but an occasional bomb is fine (heromedel, 2026-10-30) |

Judgment calls: fire and breaches in separate systems (a breach drains the air a fire needs); teleport standing in
for an upgraded AAA broadcasting avatars aboard; the weapon codes follow the Senti number codes, with F for fire,
B for breach and X for anti-bio as suggestions; band 7–8 for the bio weapons, since a bio bomb is new to the genre.

## Captain plans (2026-10-30)

**Ai-Generated-Proposal (2026-10-30)**, asked by heromedel: an `<ai>` section in every ship (Deck Collapse's format,
commit 49333f3 on its branch). Most ships play `destroy` with a few lines from their design; the boarders and crew
killers play `crew-kill`. The Cutpurse inherits the Hijacker's plan; other loadouts with an `<ai>` replace their
ship's plan.

| Ship | Plan | In short |
|---|---|---|
| SC-1 Outrider | destroy | Triblast on Shields, Pathfinder on the guns |
| Pirate Hijacker (and Cutpurse) | crew-kill | Deck Collapse's example, plus boarders on the guns and the Med Bay; never cuts the air while its boarders are aboard |
| Pickpocket | crew-kill | Twinshot on the guns; boarders on the guns, then the Med Bay |
| Burr, Pappus | destroy | the guns that could stop it, then the engines that could chase it |
| Light Attack Frame | destroy | the Hull Laser on the guns once the shield is down; the Suit Dock's suit pops the shield |
| Vein Moth | destroy | both weapons on one system: the guns, then Piloting |
| Scrap Hound | crew-kill | boarders to the Med Bay; never fires on a system holding its own hunters, nor cuts the air while they're aboard |
| Polyp, Polyp (Flak) | destroy | the missile on the guns; the flak pops shields for the swarm |
| Relay Picket | destroy | the guns, to protect its station |
| Mote | destroy | ion the shields, then the guns |
| Census Picket | crew-kill | while boarded, shoot and hack the enemy teleporter; otherwise burn the Med Bay, then Life Support, and hack whichever still works |
| Quiet Ledger | crew-kill | breach Life Support, burn the Med Bay, hack Airlock Control so they can't vent fires; holograms hold the airless rooms |
| Final Archive | crew-kill | bio bomb the Med Bay where the hurt gather, burn Life Support; the anti-bio beam sweeps the crowded systems |

Features the plans use that Deck Collapse doesn't have yet, written as if they existed:

| Ref | Gap | What the files ask for |
|---|---|---|
| G22 | Suit lines | `<suit system suit when weight/>`: where a battlesuit goes, like a weapon line |
| G23 | Boarding lines | `<board system when weight/>`: which enemy system teleported boarders go to |
| G24 | Hacking lines | `<hack system when weight/>`: hack targets beyond crew-kill's Med Bay first |
| G25 | Conditions on enemy systems | `when="enemyMedBayDown"`, `when="enemyLifeSupportDown"` |
| G26 | Our boarders aboard | `ownBoardersAboard`: any of our crew is aboard the enemy ship |
| G27 | Negative conditions | `unless="…"` skips a line while the condition holds; `ownCrewIn`: our own crew are in the target system (so a ship never shoots its own boarders) |
| G28 | Being boarded | `when="enemyBoardersAboard"`: enemy crew are aboard our ship (the Census Picket turns on the enemy teleporter first) |
