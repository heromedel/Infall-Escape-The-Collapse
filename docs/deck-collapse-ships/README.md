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
| `tentauri-scout.xml` | Tentauri | Tough Little Scout | 3 | 189 | `ship-suggestions.md` |
| `loadout.tentauri-scout.little-scout.xml` | Tentauri | Little Scout | 1 | 132 | `ship-suggestions.md` |
| `light-attack-frame.xml` | Mecha | Light Attack Frame (Hull Laser) | 1–3 | 132 | `ship-suggestions.md` |
| `loadout.light-attack-frame.suit-dock.xml` | Mecha | Light Attack Frame (Suit Dock) | 2–3 | 138 | `ship-suggestions.md` |
| `azurethea-vein-moth.xml` | Azurethea | Vein Moth | 1–2 | 130 | new |
| `senti-relay-picket.xml` | Senti-GPH | Relay Picket | 3 | 202 | new |
| `lykario-scrap-hound.xml` | Lykario | Scrap Hound | 1–2 | 136 | new |
| `malphen-polyp.xml` | Malphen | Polyp | 1, in threes | 38 | new |
| `loadout.malphen-polyp.flak.xml` | Malphen | Polyp (Flak) | 1, in threes | 41 | new |
| `whispwraith-mote.xml` | Whispwraith | Mote | inside the collapse | 65 | new |

Values are rough sums from `docs/reference/` (systems, reactor bars, weapons); Deck Collapse works out its own.
Band 1's squad budget is 137, so a band 1 squad is one Pickpocket, Little Scout, Vein Moth, Scrap Hound or Light
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
| G12 | AAA | Senti avatar array: hosts one avatar per level (suggestion); damage drops avatars until repaired | Senti profile 6 |
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
- **Vein Moth:** the profile's two low-tech shots, a Stinger and a single-shot beam ("Firefly", a biological name).
- **Relay Picket:** two beams and Sensors 2; no Life Support, since Senti don't breathe. It costs more than a band 1
  budget allows, so band 3.
- **Scrap Hound:** no Sensors (Animal Senses), Auto Pilot so the pilot can board, a stolen Twinshot.
- **Polyp:** a swarm ship of about 38, so three fit band 1; a flak loadout mixes shield-poppers into the swarm.
- **Mote:** 4 bars from 2 crew: Shields (2), Engines (1) and one ion blast (1). "Hush" as a strange, alien name.
