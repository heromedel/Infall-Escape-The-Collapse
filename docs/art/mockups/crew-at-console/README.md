# Crew at a console: does the console art fit in one tile with the crew member? (2026-11-13)

**Ai-Generated-Proposal**, a mockup for GV 7G. Not built in the game.

heromedel agreed (2026-11-13, "if you can make it work") that crew and system should share a tile the way the art
sessions settled it: the console at the wall with the symbol in it, the crew member in front. This puts the real
console art (the Outrider's wall desk, the Mecha tower, a Tentauri organ) and the real typing frames of each crew
sheet into one 35-pixel tile, on each wall, at 6 times size.

| Picture | What it shows |
|---|---|
| `crew-at-tile-middle.png` | The crew member at the tile's middle, where the game draws them now. They cover the symbol on almost every wall. |
| `crew-stepped-back.png` | The crew member drawn 6 pixels back from the console's wall, and a console on the south wall drawn over a Facing sprite. The symbol shows on every wall. |

## Read off the mockup

- **Stepping back works** for every sheet. The top-down drifter's hands land on the desk on all four walls.
- **Facing sprites on a south wall** stand behind the console, so only the head and shoulders show.
- **Tall Facing sprites reach past the tile** by 3 to 6 pixels when stepped back (clipped in these pictures; in the
  game they would overlap the next tile a little, as tall sprites already do).
- **A token at today's size (29 across) still covers the console.** At about 21 across it fits.
- **The ring under each crew member (29 across) is left out.** It would cross the console.
- The top-down HalfMech's typing frames were drawn to grip the tower from the tile's middle, so it may want a
  smaller step back than the others.
