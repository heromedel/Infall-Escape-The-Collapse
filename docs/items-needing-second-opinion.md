# Items needing a second opinion

Content written for the Godot version (`infall-godot/content/`) to fill gaps the docs left. Each owner session
reviewed its part on 2026-10-31; what was changed is under **Checked**, and what is still open is listed here.

## Still open

### For Ship Designs

1. **Two weapon systems per ship:** the Hijacker's Sporewing on its own Weapons B, and the Burr's one weapon system
   per laser (`ship-suggestions.md`). The Godot version runs one weapon system per ship, so both still use one.
2. **The docs' own ships the Godot version lacks:** the Pickpocket (band 1 pirate), the Polyp (band 1 Malphen, with
   the docs' Flesh Mortar missile), the docs' Relay Picket with its AAA, the Vein Moth and the Scrap Hound. There is
   no band 1 Malphen squad until the Polyp is added.
3. **Loadout values** (Chestnut 488.4, Tumour 302.6, Swollen Cyst 181.3, Archive Cruiser 305.2, Checkpoint, Siege,
   Huntmaster, Marauder) have not been re-priced.
4. **Burr's value:** Ship Designs' 188.81 against Eco's rebuild of 193.64.

### For Eco

1. **Shield levels in ship.xml:** stored as bars (level 2 is one layer, as in the genre) while GDD 8H's shield test
   counts a level per layer. Which one the files mean needs settling.
2. **The growth organ** (Malphen) has no price yet.
3. **Repair 5.5 s a bar, 15 crew damage a hull point and teleporter cooldowns 30/20/10 s** are unchecked.
4. **The event set pays less than the genre's:** 17 low, 6 medium, 2 high and 4 tiny, where the genre's events
   lean to medium and high.

## Checked

### Ship Designs (2026-10-31)

- Mecha Raiders band 1 had an EVB suit (no EVB suits in band 1, `ship-design-process.md`): band 1 is now the
  open-stern frame, band 2 the suit dock. The Light Attack Frame Suit Dock appears in bands 2–3 only.
- Malphen's Gristle Missile (infection, mid tech in the race profile) was in bands 1–2: Malphen Growth now starts at
  band 3. Its suggested band 1 swap to the "Flesh Mortar" was not made: that name is the docs' missile (the Polyp's),
  while the Godot weapon of that name was flak with infection, so the Godot one is renamed **Sinew Flak**.
- Tentauri Passage: the **Pappus** loadout (`tentauri-scout.pappus`, 132.17) in bands 1–2, the **Burr** (renamed from
  Tough Little Scout) in band 3. The Pappus carries the card game's Coil plan.
- Assault Frame: Doors moved from the core room (with the Servicing Core) to the command deck (GDD 5B Medbay rule).
- Over budget at band 1: GATOS Checkpoint, Lykario Pack and Senti Pickets start at band 2. Pirates at band 4 field one
  Hijacker.
- Names: Hornet → **Mandible**, Lanternfly → **Ocellus** (the docs' Lantern is a beam), Sporecarrier → **Hawkmoth**,
  Warden → **Seedpod**, Vanguard → **Chestnut**, Spawnling → **Cyst** (Swollen Cyst), Broodmass → **Tumour**, and the
  Godot Relay Picket → **Beacon Picket** (the docs' Relay Picket is a different ship). Ids are unchanged.
- Fine as they are: the Patrol Cutter, every ship's Medbay room, the Assault Frame's EVB Dock and weapon names, the
  Packrunner, the Tentauri Seedpod, and the other squads' budgets.

### Lori (2026-10-31)

- Events that speak of the collapse wait until it appears (GDD 2P): `after_collapse="yes"` on REFUGEE_FAILING_AIR,
  LYKARIO_DENIAL and NEUTRAL_DISBELIEF; `requires="collapse"` on NEUTRAL_TRAVELLER_NEWS's warning choice;
  REVISIT_EARLY and WAITED_EARLY are used before it appears.
- REVISIT and WAITED reworded (no claim that nothing changed; no power cores assumed). HAZARD_ION_STORM made
  race-neutral, HAZARD_SUN_FIGHT a full sentence, ITEMS_DERELICT_SCOUT no longer says its crew are gone,
  ITEMS_WRECKAGE without the repeated "convert".
- The HalfMechs are no longer named to outsiders (STORE_MECHA, DISTRESS_MECHA_POD).
- "The Colony Ship" capitalized (STORE_TERRAN_DOOMED, GATOS_SHAKEDOWN). GATOS_SHAKEDOWN's "We're GATOS too" needs
  GATOS crew. STORE_OCCUPIED is for Mecha occupiers. STORE_AZURETHEA_STRUGGLING's petals are wings.
- PIRATE_TOLL's door choice matches its outcome; DISTRESS_FREIGHTER's venting choice no longer requires your Doors;
  DISTRESS_TENTAURI_PAIR has no third Tentauri; MECHA_OUTMATCHED's line; NEUTRAL_REFUGEE_CONVOY "many races";
  NEUTRAL_COLONY_SHIP_SUPPLY's outcome finishes the story.
- SENTI_DOOMED_ARCHIVE is for doomed Senti only; SENTI_PICKET is for border clusters and speaks plainly.
- Not changed, for heromedel: STRANDED is heromedel's text; DISTRESS_GATOS_FAMILY's kittens (the GATOS are drawn
  as cats in the Godot version, as heromedel asked); MECHA_TERRITORY's "HalfMech" line; NEUTRAL_MERCENARY's permanent
  ship.

### Eco (2026-10-31)

- Volley costs: 2B 03 V1 0.12, HB-MR Hull Beam 0.12, DS-ST Hull Laser 0.08, Fang 0.06 (per-shot cost rounded first,
  F5 item 4). Sinew Flak 10.9 s, 14.48, 0.06 and Gristle Missile 9.9 s, 7.02, 0.07 (infection priced as fire).
- The Laser Battlesuit's launch costs 0.22 and a suit that comes home gives 0.02 back (F5 item 2).
- Ship values rebuilt from `system-prices.md`: Light Attack Frame 159.55, Assault Frame 298.88, Moth Skiff 138.23,
  Packrunner 166.12, Patrol Cutter 170.71, Pirate Scrapper 85.12, Beacon Picket 150.93, Hawkmoth 243.82, Seedpod
  267.51, Cyst 98.98.
- Event rewards follow the genre's curve by band (low/medium/high from 2.06/3.75/5.08 at band 1 to 8.11/14.41/19.61
  at band 8; tiny a third of low, huge one and a half times high).
- Crew walk 2.2 tiles a second (the genre's usual crew, measured), not 2.6.
- Fine as they are: the other 26 weapons, waiting pay 0.25, shield recharge 2 s, the Supershield's 20/15/10 s.
