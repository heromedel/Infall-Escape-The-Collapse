# Weapon art

Weapons are separate art (GDD 8F, 11B), drawn top-down pointing up, centred on their mount point at (0, 0). The
game places them at a hull's mount; ship previews do the same with `compose.py`.

| Weapon | Race / tech | Folder | Used on |
|---|---|---|---|
| Sporewing | Azurethea, biomechanical (stolen by Terran pirates) | [`sporewing/`](sporewing/) | Terran Pirate Hijacker and Cutpurse |
| Gat 2.1 "Twinshot" | Terran, mechanical | [`twinshot/`](twinshot/) | Terran Pirate Hijacker |

- **Sporewing (2026-10-23):** two folded wing plates close into a launcher housing that opens to fire, in
  iridescent Azurethea blues with small eye-spots. It is seated neatly in a Terran hardpoint base, the refit that
  lets it run on a Terran ship. Three styles were tried (`sporewing/sporewing-options.png`): a chitin pod with vanes, a
  segmented tube, and the folded wings (picked).
- **Twinshot (2026-10-23):** a compact Terran turret block with two parallel laser barrels.

The builder is `docs/art/terran/pirate-hijacker/tools/weapons.py`.
