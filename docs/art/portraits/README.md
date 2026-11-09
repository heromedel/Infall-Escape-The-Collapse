# Crew portrait options (2026-10-31)

**Ai-Generated-Proposal (2026-10-31):** options for heromedel to pick from, made for the Godot version's crew tokens
after GV 7D (kitten-like HalfMechs; mercenary-looking Terran humans that are cool or cute, not derpy).

- `halfmech-kittens.png`: K1 to K5. Dark kittens in the HalfMech pilot art's tones, with Mecha power purple
  implants (visor, cyber eye, antenna ear, jaw plate, purple tuft) and green, blue or purple eyes.
- `mercenary-humans.png`: M1 to M5. Mercenary Terrans: a buzz-cut veteran, an undercut with a comm earpiece,
  goggles up, an eyepatch, a grey-bearded veteran.

Each row shows the portrait at 10×, then the token at the game's sizes (25 px on the ship, 32 px on the crew card)
at real size and at 4×.

Made with `tools/portraits.py` (the pixel grids and palettes live there): `python3 tools/portraits.py .`

QA done before review: the kittens' fur was lightened and given a rim light so they read on the dark token, the
right inner ear matched to the left, the eye glints moved to the top, and the visor thinned; the humans were redrawn
on one face template (rounded head, tapered jaw, ears on both sides, single dark eyes under brows instead of
side-glancing whites, a nose shadow, a small mouth), the shaved side and the darkest face made readable.
