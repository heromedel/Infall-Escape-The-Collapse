# Weapon art

Weapons are separate art (GDD 8F, 11B), drawn top-down pointing up, centred on their mount point at (0, 0). The
game places them at a hull's mount; ship previews do the same with `compose.py`.

| Weapon | Race / tech | Folder | Used on |
|---|---|---|---|
| Sporewing | Azurethea, biomechanical (stolen by Terran pirates) | [`sporewing/`](sporewing/) | Terran Pirate Hijacker and Cutpurse |
| Gat 2.1 "Twinshot" | Terran, mechanical | [`twinshot/`](twinshot/) | Terran Pirate Hijacker |
| Defense Laser | Tentauri, biomechanical | [`defense-laser/`](defense-laser/) | Tentauri scout (×2) |
| DS-ST Hull Laser | Mecha, mechanical | [`ds-st-hull-laser/`](ds-st-hull-laser/) | Mecha Light Attack Frame, Hull Laser loadout |
| Laser battlesuit (EVB suit) | Mecha, mechanical | [`battlesuit-laser/`](battlesuit-laser/) | Mecha Light Attack Frame, Suit Dock loadout |

- **Sporewing (2026-10-23):** two folded wing plates close into a launcher housing that opens to fire, in
  iridescent Azurethea blues with small eye-spots. It is seated neatly in a Terran hardpoint base, the refit that
  lets it run on a Terran ship. Three styles were tried (`sporewing/sporewing-options.png`): a chitin pod with vanes, a
  segmented tube, and the folded wings (picked).
- **Twinshot (2026-10-23):** a compact Terran turret block with two parallel laser barrels.
- **Defense Laser (2026-10-23):** a siphon emitter, a tapered nacre tube with a glowing lens. Built by
  `docs/art/tentauri/scout/tools/tentauri_weapons.py`.
- **DS-ST Hull Laser and laser battlesuit (2026-10-23):** a twin-barrel turret, and a squat armoured suit with a
  laser arm and jump pack. Built by `docs/art/mecha/light-attack-frame/tools/mecha_weapons.py`.

The Sporewing and Twinshot builder is `docs/art/terran/pirate-hijacker/tools/weapons.py`.
