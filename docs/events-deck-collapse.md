# Infall: Placeholder Events for Deck Collapse

Eight short events for the stops between battles that have no store, written for Infall: Deck Collapse (the
card-battle prototype) in the format of `events-sample.md`. Everything here is **Ai-Generated-Proposal
(2026-10-29)** until heromedel reviews it.

All are band 1 and work in any cluster. Outcomes use only what the prototype can do: start a battle, gain or lose
Mawjig, hull or missiles, wound a crew member or have one join, give a free weapon or system repair, or nothing.
`BOX:` amounts are sizes (low, medium) for the prototype to set. `{crew}` is the crew member the blue choice found.

Left out on purpose: Whispwraith and Malphen crew choices (no race knows the Whispwraith exist, and no race takes
the Malphen in), and anything that says people "fled the collapse", since band 1 can come before the collapse
opening ends.

## 1. DERELICT_FREIGHTER: "Sealed Hold"

```
OPENING
A freighter drifts dark and silent at the edge of the cluster. Its cargo hold is still sealed. Your scans show no
life aboard.

1. Cut through the hold doors.
2. Leave it alone.
3. [BLUE] (Mecha Crew) Have {crew} plug into the freighter's door controls.
```

```
1a
Your crew cut their way in and find the hold still half full. They haul across everything worth converting.

BOX: Mawjig +(low)
```

```
1b
The cutting torch sets off a fuel line behind the doors. The blast throws your crew clear, but {crew} is burned
before they can get back aboard.

BOX: {crew} wounded
```

```
2
You leave the freighter to drift. Whatever it carried can stay its own business.
```

```
3
{crew} links into the freighter's systems and takes control of the doors. The hold opens without a spark. Your crew
empty it at their leisure.

BOX: Mawjig +(medium)
```

## 2. ASTEROID_BELT: "Loose Rock"

```
OPENING
The cluster's star is ringed by a slow belt of asteroids. Some of them glitter with ore worth converting into
Mawjig. Mining them means flying close.

1. Move in and mine the nearest asteroids.
2. Keep your distance.
3. [BLUE] (Sensors level 2+) Scan the belt for the richest rock first.
```

```
1a
Your squad breaks up the nearest asteroids and converts the ore.

BOX: Mawjig +(low)
```

```
1b
A spinning fragment clips one of your ships before its pilot can pull away. You gather what ore you can and leave
the belt.

BOX: Hull -(low)   Mawjig +(low)
```

```
2
You stay clear of the belt while your Jigawatt Drives charge.
```

```
3
Your sensors pick out a single asteroid veined with ore, drifting well away from the rest. Your squad mines it
without a scratch.

BOX: Mawjig +(medium)
```

## 3. STRANDED_PILOT: "One Life Sign"

```
OPENING
A damaged shuttle hangs in the cluster, its engines dead. Its pilot hails you, weak but polite.

"Please, I've been out here for days. I can fly anything you give me if you take me with you."

1. Bring the pilot aboard.
2. Leave the shuttle.
3. [BLUE] (Lykario Crew) Ask {crew} what they sense aboard the shuttle.
```

```
1a
The pilot is as harmless as they sounded, and grateful to be somewhere warm. Once they have eaten, they ask to join
your crew.

BOX: +1 crew (Terran)
```

```
1b
As you match course, a pirate ship powers up behind the shuttle. The pilot was only bait.

THEN: battle (random)
```

```
2
You leave the shuttle behind. Its pilot's hails follow you until you jump.
```

```
3
{crew} goes still for a moment. "One life on that shuttle. More on the ship hiding behind it."

Your scanners show nothing, but you trust {crew}.

1. Prepare for battle.
2. Leave before the trap can close.
```

```
3-1
The pirate ship drops its disguise when it sees you coming. Its crew are not ready for a fight.

THEN: battle (random)
```

```
3-2
You jump away before the pirates can spring their trap.
```

## 4. PIRATE_TOLL: "The Toll"

```
OPENING
A pirate ship drops out of hiding as you arrive and trains its weapons on your squad.

"This cluster's ours. Pay the toll and fly on, or we take it from your wreck."

1. Pay the toll.
2. Refuse and prepare for battle.
3. [BLUE] (Cloaking) Cloak and lead your squad out of their sensor range.
```

```
1
The pirates count your payment twice before letting you go.

BOX: Mawjig -(low)
```

```
2
"Your funeral," the pirate captain says.

THEN: battle (random)
```

```
3
You cloak and lead your squad along the edge of the cluster, out of the pirates' sensor range. By the time they
stop searching, you are gone.
```

## 5. AZURETHEA_EXPLORER: "Torn Wing"

```
OPENING
An Azurethea explorer ship rests near one of the cluster's moons, one of its wings torn. Its crew hail you gently
and say they will manage on their own.

1. Offer to help with their repairs.
2. Wish them well and move on.
3. [BLUE] (Azurethea Crew) Let {crew} speak with them.
```

```
1
Your crew spend hours patching the explorer's torn wing. The Azurethea thank you in their quiet way and send over
what Mawjig they can spare.

BOX: Mawjig +(low)
```

```
2
The explorer dips its wings as you leave.
```

```
3
{crew} talks with them for a long time. Afterwards, the explorers offer to tend your ship as well, and a team of
them works through one of your damaged systems.

BOX: free system repair
```

## 6. TENTAURI_PASSAGE: "Making Room"

```
OPENING
A small Tentauri ship arrives right behind you, its shields bright. Its two crew ask, quietly, that your squad move
aside. They are passing through and would rather not wait.

1. Move aside and let them pass.
2. Hold your position.
3. [BLUE] (Tentauri Crew) Let {crew} talk to them.
```

```
1
The Tentauri slip past without another word.
```

```
2
The Tentauri ship pushes through your formation anyway, its shields grinding against your hull. It never fires,
and it is gone before you can.

BOX: Hull -(low)
```

```
3
{crew} and the strangers trade a few soft words. The Tentauri stay long enough to help repair one of your systems
before they go on their way.

BOX: free system repair
```

## 7. OLD_BATTLEFIELD: "Old Wreckage"

```
OPENING
The wreckage of an old battle drifts through the cluster, cold and scattered. Some of the wrecks still carry
unspent missiles. Some of those are still live.

1. Send your crew to search the wrecks.
2. Leave the dead alone.
3. [BLUE] (Teleport Bay) Teleport the salvage aboard from a safe distance.
```

```
1a
Your crew find a rack of missiles still sealed in its casing and bring it home.

BOX: Missiles +(low)
```

```
1b
A missile wakes up as your crew move it. The blast wounds {crew} before the others can pull them clear.

BOX: {crew} wounded
```

```
2
The wreckage drifts on behind you as you leave.
```

```
3
You lock onto the wrecks from a safe distance and teleport across everything that still looks useful.

BOX: Missiles +(low)   Mawjig +(low)
```

## 8. MECHA_PATROL: "Mecha Ground"

```
OPENING
A Mecha patrol ship blocks your way, wide and heavily armed.

"This cluster belongs to us. Leave it, or pay to stay."

1. Pay what they ask.
2. Refuse and prepare for battle.
3. [BLUE] (Hacking) Hack their sensors to make your squad look stronger.
4. [BLUE] (Mecha Crew) Let {crew} answer them.
```

```
1
The patrol takes your payment and moves aside without a word.

BOX: Mawjig -(low)
```

```
2
The patrol ship opens fire.

THEN: battle (random)
```

```
3
Their sensors suddenly show a squad far stronger than yours. The patrol hesitates, then decides you are not worth
the risk and lets you pass.
```

```
4
{crew} answers them in their own blunt way. Soon the talk turns to business. The patrol decides a trade is worth
more than a fight and sells you missiles from its own stores.

BOX: Mawjig -(low)   Missiles +(low)
```

## Checks

- Lore used:
  - Mawjig is matter converted into stored energy, and wreckage and other matter can be converted into it (GDD
    8C, Decided).
  - The drive is the Jigawatt Drive (GDD 6D, Decided).
  - A Mecha can integrate with a ship system (race profile, Mecha 9; Proposed).
  - The Lykario sense Life Signs without ship sensors, even on other ships (Lykario 9, Decided). Their
    Animal Senses are never explained and never called psychic, so the line only reports what {crew} senses.
  - The Azurethea are peaceful, nearly pacifist explorers (Azurethea 1, 2; Proposed).
  - The Tentauri often travel two to a ship, specialise in shields and force their way where they want to go
    without looking to destroy anyone (Tentauri 1, 2, 6; Proposed).
  - The Mecha are territorial, insist interlopers leave, and accept deals they profit from (Mecha 2, 3; Proposed).
    Their HalfMech secret is not touched.
  - Pirates exist, and borders can be front lines against them (GDD 2R, Decided).
- Event 8 fits best in or near Mecha regions. The others fit any cluster.
- New facts: none. Nothing here adds to `lore-facts.md`.
