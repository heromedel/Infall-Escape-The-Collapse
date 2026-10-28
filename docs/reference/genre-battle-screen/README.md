# Genre battle screen: reference frames (2026-10-27)

Screenshots of the genre's battle screen taken in this coding session, one state per frame, to copy placement and
behaviour from, never art (hard rule: nothing from these goes into the code or content). Kept here so the next
session has them. Window 1280 by 720, Kestrel against a Rebel Rigger, paused unless the name says otherwise.

## What the frames show

| Frame | State |
|---|---|
| 01 | A fight, paused. Hull bar top-left with shield bubbles under it, crew list down the left edge, weapons bottom-centre, main systems bottom-left with bars above their icons, subsystems bottom-right a little apart, AUTOFIRE button under the weapons, enemy in a TARGET panel top-right with its hull bar and shield bubbles, room icons below it. |
| 02 | Weapon slot clicked: the slot gets a yellow outline and the cursor becomes a crosshair reticle. Hovering a slot shows its tooltip (type, damage, hotkey). |
| 03 | Aiming with autofire off: the hovered enemy room gets a yellow outline; the slot and the cursor reticle are yellow. |
| 04 | Same with Ctrl held: the slot outline and the cursor reticle turn red. Letting go turns them yellow again. |
| 05 | Target set while Ctrl was held: a red reticle with the weapon's number stays on the room. |
| 06 | Two targets at once: weapon 2 set without Ctrl leaves a yellow reticle with "2"; weapon 1's red one with "1" stays. |
| 07 | Right click while aiming: the aim is cancelled and that weapon's old target is cleared. |
| 08 | Right click on a slot: the weapon is depowered (slot greyed, its bars gone). |
| 09 | AUTOFIRE turned on: the existing yellow mark turns red. So red is autofire (keeps the target), yellow is fire once. |
| 10 | Aiming with autofire on: slot and cursor red by default. |
| 11 | Aiming with autofire on and Ctrl held: slot and cursor yellow. |
| 12 | System tooltip: what it does, level, status (power, manned), the add and remove power keys. |
| 13 | Crew member clicked in the list: the row gets a green outline, the sprite a green marker, and the cursor stays a pointer. |
| 14 | With a crew member selected, hovering a room on the own ship outlines it yellow. |
| 15 | AUTOFIRE tooltip: "Toggle to activate/deactivate weapons automatically firing. Hotkey: V. LEFT CTRL + AIM can force a weapon to do the opposite of current setting". |
| 16 | Running: an enemy laser crossing the gap from the right; the own shield bubble is down and recharging. |
| 17 | Running: the missile's hit flash on the enemy weapons room, a floating "1" on the shields room from the laser, the enemy shield pip empty with a recharge bar under it, hull bar shorter. |
| 18 | Running: the damaged enemy system's icon is red; the floating number fades. |

## Rules read off the frames

- Fire mode is decided at the moment of the room click by whether Ctrl is held; the cursor and the slot preview it.
- Red = autofire (the weapon keeps its target and fires every time it charges). Yellow = fire once. The AUTOFIRE
  button sets the default and recolours existing marks.
- The room hover outline is always yellow, whatever the mode.
- Right click while aiming cancels. Right click on a slot depowers the weapon; left click repowers it.
- Subsystems sit apart from the main systems, with their own bars, and are always lit.
- Damage shows as a floating number on the room and a red system icon; shields show as bubbles with a recharge bar.

## Recording at 20 frames a second (2026-10-28)

A 30 s recording of a fight against a rebel Elite Fighter at a fleet beacon, read frame by frame. The Kestrel's
own weapons were knocked out by the fleet's battery before they fired, so this recording has the enemy's shots
only; a second recording from a clean fight is still needed for a burst's spacing and the player's bolts.

| Frame | What it shows |
|---|---|
| 19 | The enemy's laser bolt arriving at the player's ship, six frames 50 ms apart, enlarged three times: a short bright green streak with a brighter head and a fading tail, about 30 px long at 1280 wide, moving about 12 px a frame. |
| 20 | The same bolt leaving the enemy's ship in the TARGET window: a green streak off the top of its hull. It left at frame 135 and arrived at frame 161, so 1.3 s from leaving to arriving with the off-screen gap in between. The next bolt left 241 frames later: a 12 s charge. |
| 21 | The fleet battery's warning: a small crosshair on the player's hull that becomes a pulsing red ball, then the hit. Not a weapon of the ship. |
| 22 | The battery's hit: a large white-orange fireball crossing from the left edge and bursting on the hull, with fire left in the room. |

Read off the frames: a laser bolt is an elongated streak in the weapon's colour, not a dot; it is drawn on the
firing ship's screen leaving, then on the target's screen arriving, and is not drawn in between.

## From the genre's data files (2026-10-28)

Read from the packed game data in the Wine setup, as a reference only; nothing from it is copied into the repo
(hard rule). Weapon entries have no field for the gap between a burst's shots: that spacing lives in the engine,
not the data, so it can only be measured from a recording. What the data does give:

- **Projectile speed:** a `speed` value on some weapons, absent on the burst lasers (the wiki's 60 is the default),
  75 and 90 on the heavy lasers, 13 on beams. Units unknown; relative only.
- **Laser bolt:** a four-frame strip, each frame 50 by 20 pixels, cycling over 0.5 s. The bolt is a glowing streak
  about 40 px long and 10 px thick with a bright rounded head and a tail that thins out behind it; the frames vary
  the tail so it flickers. Light lasers are a thin orange-red streak, burst and heavy lasers a fatter green, blue,
  purple or orange one. The bolt flies head first along its path.
- **Missile:** one 32 by 80 pixel image of a slim rocket seen from above, pointed nose, small fins, a small exhaust
  flame at the tail; it flies nose first. The bomb projectile is a plain teardrop.
- **Firing animation:** the mounted weapon has a frame strip with a charged frame and a fire frame, a fire point
  where the bolt appears, and a mount point; missiles add a glow image while charged.
- **Sounds per weapon:** launch (two or three variants chosen at random), hit hull, hit shield, miss.

For ours: a laser is a streak with a bright head and a thinning tail in the weapon's colour, flickering a little;
a missile is a slim nose-first rocket with an exhaust flame. Each weapon file names its own projectile art later.
