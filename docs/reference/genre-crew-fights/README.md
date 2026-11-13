# Genre crew fights: two recordings (2026-11-12)

Reference only, nothing decided. heromedel asked how fights between several crew go in the genre's game before
Infall's crew fights are changed (GV 7F, particles and shots). None of the earlier reference frames
(`../genre-battle-screen/`) shows crew fighting crew, so the game was run under Wine and two boarding fights were
recorded at 20 frames a second. The frames are kept here to copy behaviour from, never art (hard rule: nothing
from them goes into the code or content).

Both fights are the same ship: the Kestrel on Easy against a Pirate Fighter at the first beacon, with two human
crew sent across by a crew teleporter. The pirate's crew were a Rock and a human. Times are seconds on each
recording's own clock.

## What the frames show

| Frame sheet | What it is |
|---|---|
| `01-fight-one-overview-1fps.jpg` | Fight one, one frame a second for 30 s. The two boarders land in the pirate's four-tile shield room, where the Rock is at the console. |
| `02-fight-one-arrival-10fps.jpg` | Fight one, 1.8 s to 3.5 s. The pirate's human comes in through the top door and ends on the top-left tile with a boarder. |
| `03-fight-one-shot-in-flight-20fps.jpg` | Fight one, every frame from 4.60 s to 5.45 s: a boarder's shot leaving, crossing a tile and landing. |
| `04-fight-one-shared-tile-10fps.jpg` | Fight one, 11.8 s to 13.5 s: the two on the shared tile trading blows while the others shoot. |
| `05-fight-two-overview.jpg` | Fight two, one frame every 1.25 s. The boarders land in a two-tile room with nobody in it; both pirates walk in. |

## Read off the frames

1. **Two on a tile fight hand to hand.** A tile holds one fighter from each side. The two are drawn apart on it,
   the pirate in the upper half and the boarder in the lower, facing each other, and they punch.
2. **A fighter with nobody on his tile shoots.** He stays on his own tile, turns to face his target and fires. In
   fight one a boarder on the top-right tile and the Rock on the bottom-right tile shot at each other for 28 s and
   neither ever stepped onto the other's tile, even after the other two were dead.
3. **Whoever walks into the room pairs up.** In both fights every pirate who walked in went onto a tile that had a
   boarder on it. In fight two the Rock was on a boarder's tile within 2 s of the boarders landing and the human
   was on the other boarder's tile by 2.75 s; from then on there were two pairs and no shot was fired for the
   whole fight. In fight one the human walked past the nearer boarder and paired with the further one.
4. **Whoever is already standing in the room does not move.** The Rock at his console and the boarders who beamed
   in stayed where they were. So who punches and who shoots comes from who walked in, not from fighters closing
   on each other.
5. **A shooter changes targets, in runs.** The unpaired boarder shot at the Rock, then at the pirate's human on the
   shared tile (11.9 s, 13.2 s), then at the Rock again. The Rock's shots also went to both boarders in turn.
   Every one of that boarder's shots in fight one, traced by which way the bolt flew (2026-11-13, R the Rock, H
   the pirate's human, who reached his tile at about 3.5 s and was dead by about 20 s):
   R at 2.55 s, then R R R R R, H, R, H H H, R R R, H H (the last at 20.2 s), then R for every shot to the end.
   So with two foes to shoot at he changed target five times in fourteen shots, going back to the Rock while
   the human was still alive. One recording cannot tell a coin toss for each shot from a rule that keeps a
   target for a while.
6. **A shot is a small bolt that flies.** The human's is a short green streak, about 6 to 8 pixels long. It crossed
   one tile in about 5 frames (0.25 s), so about 140 pixels a second at this size. The Rock's shot is a small grey
   lump, so each race has its own.
7. **Shots come about every 1.1 to 1.2 s** (bolts first seen at 2.55, 3.7, 4.8, 6.1, 7.35, 8.55 s). Blows on a
   paired fighter also land about once a second (12.25, 13.25, 14.25 s).
8. **Every hit is marked the same way, punch or shot:** one frame of a white disc with a red cross on the one hit,
   then a red splat that fades over about 0.4 s.
9. **Health bars** sit over every fighter in the room: green for the player's crew, red for the other side.
10. **How the fights ended.** Fight one: the paired boarder and the pirate's human were both dead by 20 s; the
    shooting boarder died at 30 s; the Rock lost little. Fight two: both boarders were dead between 20 s and 24 s.

## Not settled by these two recordings

- **Whether a shot and a punch do the same damage.** The shooters changed targets, so the two cannot be separated
  here.
- **Which enemy a newcomer picks** when more than one has a free tile. In fight one he passed the nearer one; it
  may be that he took the one nobody was attacking yet.
- **What happens with more fighters than tiles,** or when a newcomer finds every enemy already paired.
- **Whether the player's own crew do the same when ordered into a room.** Both times the walkers were the
  pirate's crew, moved by the game. The boarders arrived by teleporter and were never given a move order.

## How Infall differs now

From 2026-11-13 Infall fights this way too (GV 7G lists the rules and which of them are guesses). Before that
everyone in a room with an enemy damaged the nearest enemy every tick from wherever they stood, nobody walked onto
an enemy's tile, every fighter played the aiming pose, and no shot or hit mark was drawn.

## Crew in a tile: the genre beside Infall (2026-11-12)

`06-crew-in-a-tile-compared.jpg`: the genre's crew at engines, weapons and piloting, then Infall's piloting and
engine rooms in each Art Style. heromedel asked for this look before the fights are changed, since how Infall
draws crew and system symbols in a tile had not been compared with the genre.

| | Genre | Infall now |
|---|---|---|
| System symbol | One for the room, large (most of a tile), flat dark grey on the floor at the room's middle. | One for each system on its own tile: a dark disc with the symbol lit in the power colour, at the tile's middle. |
| Console | Drawn at the wall of one tile; the crew member stands on that tile in front of it. | A desk at the wall edge of the system's tile, with a blank dark screen. |
| A crew member at a station | Stands clear of the room's symbol, which stays in view. | Stands at the tile's middle, on top of the symbol, which is hidden. Which system they are on is only said in words in the crew panel. |
| Size in a 35-pixel tile | About 20 wide and 18 tall, floor showing all round. | Top-down sprite about 24 wide; the Facing sprite 23 tall and reaching the tile's lower edge; a token about 30 across with its ring. |
| Marks round the crew member | A thin outline that hugs the sprite. | A soft ring, a second ring when manning, and a conduit line through the tile. |
| Two fighters on a tile | Drawn apart, one in the upper half and one in the lower. | Not done yet. |

No note was found of an agreed symbol beside a crew member to say which system they are on, in this repo's docs or
in the older Deck Collapse version; the Godot version says it in words in the crew panel.

## How the recordings were made

So the next session can repeat or extend them. Nothing below is in the repo; it all lived in the session's scratch
folder.

- **The game:** heromedel's own copy, `FTL Faster Than Light.rar` in his shared Drive folder (the folder named in
  `docs/handoffs/economy.md`), fetched with the same `curl` line as that handoff gives for `ftl.dat` and unpacked
  with `unrar`. It is the Steam build, version 1.6.14, and runs under Wine 9 without Steam.
- **Running it:** `Xvfb :99 -screen 0 1300x760x24`, then `wine FTLGame.exe` from the game's folder. No flags were
  needed; it draws with software OpenGL. It takes about 50 s to reach the language screen. The window sits 4
  pixels right and 30 down on the virtual screen, so clicks and crops are offset by that.
- **Driving it:** `xdotool` (mouse move, a short pause, button down and up; `space` pauses), with a screenshot
  after each step (`import -window root`, cropped to the window) to see where to click next.
- **Getting a crew teleporter:** the Kestrel's entry in the game's data lists every system with `start="true"` or
  `start="false"`. In the scratch copy of `ftl.dat` the live Kestrel entry's teleporter line was changed from
  `start="false" />` to `start="true"  />`, the same length, so the archive needed no repacking. The original was
  kept beside it. No save was edited.
- **Recording:** `ffmpeg -f x11grab -framerate 20 -video_size 1280x720 -i :99.0+4,30 -t 45 -c:v libx264 -preset
  ultrafast -qp 0 out.mkv`, started just before the crew were beamed over; frames were then cut out of it with
  `ffmpeg -vf fps=20,crop=…`. Shot and hit times were found by counting bolt-green and flash-white pixels a frame.
- **Replaying the fight:** the game saves on arriving at a beacon, so after closing it, Continue starts the same
  fight again from the top.
