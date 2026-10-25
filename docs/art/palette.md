# Infall palette

Shared colours for all art. The values live in `palette.py`, which the art tools import, so a shared colour changes in
one place.

| Name | Hex | Used for | Status |
|---|---|---|---|
| Power green | `#66FF66` | Powered systems, powered power bars, and the symbol on an intact player system | **Decided (2026-10-25)** |
| Mecha power purple | `#AA28EB` | The Mecha's accent: visor, chest lights, and the start of the power pulse when they power a system | **Decided (2026-10-25)** |

- **Ai-Generated-Proposal (2026-10-25):** the Terran powered conduit glow (`#5DFFA8` in the Outrider and Pirate plans)
  could become power green too, since a powered conduit means the same thing.
- The enemy (orange) and damaged (red) symbol colours are still Proposed: see `docs/ideas.md`, Ship interior art,
  and the mockup in `mockups/system-symbol-colours/`.
- **Proposed (2026-10-25):** enemy Mecha system symbols could use Mecha power purple, the way pirate (enemy)
  systems use orange.

## Mecha crew palette

From heromedel's Mecha crew sheet (`mecha/crew/`): near-black armour with one accent, the purple.

| Name | Hex | Used for |
|---|---|---|
| Outline | `#0A0A0E` | Outlines and the darkest gaps |
| Shadow | `#1C1D24` | Deep shadow |
| Armour dark | `#2E3039` | Most of the armour |
| Armour | `#4A4D5A` | Lit armour |
| Armour edge | `#7A7F8E` | The few brightest edges |
| Power purple | `#AA28EB` | Visor bar, chest lights, power |
| Purple deep | `#5A128C` | Dark purple, round shots and the pulse |
| Purple pale | `#EBE1FA` | Pale purple, shot glare |
| Purple white | `#F5EBFF` | The hot core of the crew laser shot |

The sheet also uses power green (`#66FF66`) where the pulse reaches a console, two in-between pulse shades
(`#9370BF`, `#7DB792`), a red pair for the fire extinguisher (`#D62218`, `#780E0A`) and three greys for the clone vat
(`#C6C5C4`, `#969698`, `#F3F2F0`).
