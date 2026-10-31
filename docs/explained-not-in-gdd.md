# Explained, not in the GDD

> Full name: *Explanation - fixes and features - heromedel explained to Infall: Init Coding that it did not add or
> correct into the GDD.* Written 2026-10-31 by the Infall: Init Coding session from its own chat log
> (2026-10-26 to 2026-10-28). Nothing here is a new idea: every line is something heromedel said directly. Each
> item says where it stands now (built, in another doc, or nowhere) so it can be moved into `docs/gdd.html` with
> a tag. Nothing has been added to the GDD by this document.

## 0. First finding: the editable GDD copy is three days behind

The shared editable copy (https://claude.ai/artifact/DNRJEFZkzS4zBL1nPHoLmX) has **no entry dated after
2026-10-23**. Every point this session wrote into `docs/gdd.html` on 2026-10-26, 27 and 28 is missing from it,
including tile targeting (3L), the barrier (3R), the formation grid (3S), GATO Meters (3Q), saves (11C), the
weapon rows (8K), slots and mounts (8L) and the Enemy Terran Color setting (14D). CLAUDE.md says the copy is only
updated on request, and it never was. That is why tile targeting looked missing: it is in the git GDD
(3L, Decided, 2026-10-28) but not in the copy. Items 1 to 4 below list what the git GDD holds; the rest is what
it does not.

## 1. In the git GDD, missing only from the editable copy

| Told on | What heromedel said | Git GDD |
| --- | --- | --- |
| 10-28 | "unlike ftl in ours you should be able to target a tile/system not a whole room" | 3L Decided |
| 10-26 | The barrier: shot hits the line, vanishes, reappears on the other side; distance in GATO Meters; events could claim further distances | 3Q Likely / Proposed |
| 10-28 | Two lines with star particles between, the full word Gatometers, a tiny faint dash while crossing, no straightening of the shot, diagonal, "not proposed but decided" | 3R Decided |
| 10-28 | Invisible grid, six zones a side never overlapping each other or the barrier, formations saved as files, curve first, player and enemy formations differ and are chosen in settings, min move is one room | 3S Proposed |
| 10-27 | Weapon systems as stacked rows, collapsible, only filled slots in battle, one small Autofire button on the bottom row | 8K Likely |
| 10-27 | Slots from level up to six, maxSlots, mounts are coordinates and a shared pool unless flagged to a system, bought and moved mounts later, per-system level prices, surcharge is Eco's | 8L Proposed |
| 10-27 | Conduits go to systems, not mounts | 5H changed |
| 10-26 | Saves instant, no interval setting, folder per squad, unique squad and ship IDs, no continue file | 11C Proposed |
| 10-26 | Enemy Terran ships show pirate orange, with a setting | 14D Proposed |
| 10-26 | Loadout patches keep the values they leave out | 5J Likely |

## 2. Told directly, built in code, never written into the GDD

These are the gaps the question was about. Section 14 (User Interface) still says the GUI is "Open".

| # | Told on | What heromedel said | Built? | Where it should go |
| --- | --- | --- | --- | --- |
| 1 | 10-26, 10-27 | The battle GUI is like the genre's: floating elements over the battle, not a side panel or a big blocking card; at least semi-transparent if a card is used; our own icons, the genre's placement | Yes, floating HUD; `Battle GUI: Floating > Card` setting | 14 (new point), 3B |
| 2 | 10-27 | Subsystems (Piloting, Sensors, Doors) sit bottom-right, always powered on their own, never shown as bars that can't fill; systems and the reactor stack sit bottom-left | Yes | 14 |
| 3 | 10-26 | GUI anchored around the selected ship's hull, "or maybe a setting to try either one" | No, screen-anchored only | 14, as a setting |
| 4 | 10-27 | A highlight under or around the selected ship | Yes, a ring under the hull | 14 |
| 5 | 10-27 | Fire modes: autofire toggle button; Ctrl held at the click flips the mode for that one target; a red reticle is the kept target (autofire), yellow is fire once (confirmed from the genre's frames); the cursor becomes a reticle after picking a weapon and clears once the target is set | Yes; `Autofire: Off > On` setting, V key | 14 and 8K (8K only has the Ctrl sentence) |
| 6 | 10-27 | Target lines are a separate option from the target marks | Yes, `Target Lines: Off > On` | 14 |
| 7 | 10-27 | Per-weapon power as in the genre: weapons powered left to right at start; system damage takes weapons offline from the right; right-click depowers a weapon and frees its bar; a different weapon can be powered if the bars allow; drag a weapon to reorder; a weapon that loses power loses charge and resumes from where it dropped to (examples 1 and 2 in the chat) | Yes | 8 (new point); concern 4 covers only the conduit side |
| 8 | 10-26 | Orders can be given while paused, as in the genre ("couldn't give orders to a paused game") | Yes, orders take effect at once while paused | 3 or 4I |
| 9 | 10-28 | Title screen: "Infall: Escape The Collapse" with Test Battle, Ship Viewer, Settings and Exit | Yes | 14 |
| 10 | 10-28 | Lasers are streaks, not dots; the weapon graphics should show; the pace should be human-readable and like the genre's; the delay between bolts should come from the genre's data | Bolt and missile SVGs per weapon file; 240 px/s measured; the burst spacing is still a 0.2 s guess | 3 or 8, and 11 (projectile art named in the weapon file) |
| 11 | 10-28 | Formations backed up 2 to 4 more tiles; the barrier stretches across the whole battlefield and further, "so it looks more like a battle field" | Yes, zones start six rows back and a twelve-column margin each side | 3R and 3S still describe the older "largest hull plus a slight margin" rule |
| 12 | 10-28 | Zones are squares, big ones, one column apart, and a zone stays the same size whatever sits in it ("space ships don't hug") | Yes, 24-cell squares | 3S says "a rectangle of grid cells" and nothing about size being fixed or one column apart |
| 13 | 10-28 | The barrier and spacing and delay are what make it feel like a battle; sound is missing and it feels weird without it | No sound at all | No point on sound anywhere in the GDD |
| 14 | 10-26 | Console Blue `#1C242C` disc behind a system symbol so power green reads over a bright floor | Yes | In `docs/art/palette.md` as Decided, not in 10 Art Direction |
| 15 | 10-26 | The ship file's `powerColour` stays as an optional override | Yes | 5 (ship file format) does not list it |
| 16 | 10-26 | An admin command to set the player power colour to any power colour | Yes, `powercolor` | Dev tool; 14D covers the setting itself |
| 17 | 10-27 | The Autofire button could shrink, move or become a keybind only | Button and V key | 8K mentions the button only |
| 18 | 10-28 | Free positioning of ships could still be allowed beside the zones ("idk if that's better or worse") | No | 3S, as an open note |

## 3. Written down, but in a different place than the GDD

| Told on | What | Where it is |
| --- | --- | --- |
| 10-27 | Conduit power versus systems with several options such as weapon mounts | `docs/concerns.md` concern 4 |
| 10-26 | Reserve the room the largest ship needs in front of the barrier | `docs/ideas.md` "Step saved", now superseded by 3R and item 11 above |
| 10-28 | Formations chosen before a battle (attack, spear, block, wing, curve); surprise battles flip them | `docs/ideas.md` |
| 10-28 | A larger battle area for flank and pincer attacks | `docs/ideas.md` |
| 10-28 | The hard rule is against copy and paste, not likeness: the look may be very similar and the design the same | `CLAUDE.md` only; 1C still just says FTL is the genre |
| 10-26 | WF A: a names page before each coding step; trivial choices are Claude's and reported; comments cite the design | `docs/coding-rules.md` 14 to 16 |
| 10-26 | Principle 8 reworded (prepping for the future must not over-complicate now, failing to prep is wrong too) | `docs/game-project-standards.md` and its artifact |

## 4. Wording in the GDD that does not match what was said

| GDD | What it says | What heromedel said |
| --- | --- | --- |
| 8K | "holding Ctrl at the room click" | Targets are tiles (3L); should read "tile click" |
| 3R | "Settings: Squad Offset: 0.35 > 0 to 1" | 3S moved the offset into the formation file as `shift`; the setting no longer exists |
| 3R | "Shots Crossing Barrier: Shown > Hidden" | heromedel's wording was "Shots Passing Barrier: Shown > Hidden" |
| 14D | "Enemy Terran Color: Pirate Power Orange > Power Green" | First written by heromedel as "Power Green > Pirate Power Orange", then "any terran ship that is set as enemy may as well switch to pirate". The built behaviour is pirate orange; the default order should be confirmed |
| 3Q | "beams ... would care much less, if at all" | "beams could care a little, maybe just much less" |

## 5. Not GDD material, listed so nothing is lost

- Up and down arrows walk the debug console's history (10-26). Built.
- The hint text over the weapon row was in the way; removed (10-28). Built.
- Zones drawn semi-transparent so the spacing can be checked (10-28). Built as `zones on|off`.
- Don't touch the camera zoom for now (10-28). Untouched.
- Screenshot every GUI state of the genre once and keep the frames in a reference folder, never in code folders
  (10-27). Done: `docs/reference/genre-battle-screen/`.
