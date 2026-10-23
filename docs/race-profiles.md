# Infall: Race Profiles

Each race is defined with the profile below. Other race ideas are in `ideas.md`.

How races treat each other: see Relations between races at the end.

## Profile template

1. **Racial tone and description:** who they are and how they feel to meet, including their ship style
   (hull shapes, colours) so their ships are recognisable at a glance.
2. **Base characteristics when doing fine.**
3. **Characteristics that emerge when struggling.**
4. **Characteristics when near the collapse and/or doomed.**
5. **How they interact with each other race.** This also drives how clusters change state (GDD 2L), e.g.
   whether they take in refugees or invade weakened neighbours.
6. **How their technology works or differs.**
7. **What it's like near and inside their territory.**
8. **Where and how they live:** whether they sprawl or hold a small, tight territory.
9. **Crew traits:** what one crew member of this race does on your ship, FTL-style (e.g. fights well,
   repairs fast). Ideally connected to the race's character.
10. **Ship designs across tiers:** basic to advanced, since a race can be placed anywhere from the core to the
    rim and its strength comes from its placement (GDD 2N).

## Terrans: The Galactic Alliance of Terran Occupied Systems ("the Gatos") (draft, 2026-10-21)

The starting race (GDD 7C). The name and its pun (*gatos*, "cats") are deliberate, to avoid a plain Federation
clone.

1. **Tone and ship style:** when doing well, clean, soft Federation-like ships. When desperate, a grim,
   survivalist look built from seemingly borrowed or stolen technology.
   Silhouette (Proposed): classic spaceship shapes, from large shuttles to cruisers and rockets.
   Colours (Ai Generated): white and pale grey with blue trim; desperate ships add rust and mismatched panels from other
   races.
2. **Doing fine:** accepted by others, interested in trade and other cultures. Technology is clean, easy to use
   and humane.
3. **Struggling:** hopeful, somewhat optimistic, with the occasional pessimistic individual. They believe in
   coming together.
4. **Doomed:** aggressive and xenophobic; they blame their problems on others and resort to nearly any crime:
   theft, hijacking, using other races' technology, even piracy. Willing to do anything to survive.
5. **Relations:**
    - Doing well: likely to take in refugees of any race; helpful and diplomatic.
    - Struggling: less tolerant of aggressive races, less likely to take them in; more likely to resort to combat.
    - Doomed: refugees are among the things blamed; very unlikely to willingly take more in.
6. **Technology:** much like FTL's Federation, with **power conduits** and a heavily armoured power core (the
   **AZC**, Armoured ZeroPoint Core). The core has no power limit: if a system is connected, it has power, period;
   no power balancing and no maximum power. Instead, rooms can have these issues: atmosphere, fire, deck breaches,
   wall breaches and damaged conduits. Power must be rerouted through undamaged conduits or rooms, and cut
   conduits repaired. Ion weapons can still disrupt Terran systems, and systems can be switched off on purpose.
   Introduced slowly: the initial scout ship is easy to reroute, with routing mattering more on larger,
   higher-tier ships; it can be changed later if it becomes a problem.
   Balance idea, starting from FTL's default weapon numbers: a weapon with a high hull-breach chance gets a lower
   chance of conduit damage; one with a low or no breach chance gets a conduit-damage chance, or a higher one.
   Synergy: a power-giving crew race would be very strong on Terran ships, powering a room whose conduit was
   severed elsewhere in the ship.
   Setting (default first): `Terran Ship Conduits: On > Off`. Off is FTL-like: Terran ships manage power like the
   biomechanical ships, with a limited pool of bars. Conversion (Ai Generated): each AZC level becomes 5 bars, the
   same equivalence `system-prices.md` already prices the AZC by; conduit damage then does nothing.
   Weapon names: an official designation plus a fun nickname, like real weapons (AK-47, "Ma Deuce"); e.g.
   Gat 3.1 "Triblast" (3 shots, 1 target), ".22" as a nickname for a light weapon. In Gatos codes M means
   missile (Gat M1), so enhanced models can use another marker, such as Gat 3.1 Mod2, V2, Model S, or EGat 3.1
   (energy efficient); these are examples, not a fixed list.
7. **Near and inside their territory (Ai Generated):** core worlds are busy trade hubs: stores are common and well stocked,
   patrols keep pirates down, and doing-fine Terran clusters are the likeliest to become Refugee clusters (GDD 2R),
   since they take anyone in. Along the colony arms stores thin out and patrols are rare. When doomed, the same
   hubs become checkpoints with scans, tolls and shakedowns, and Terran pirates work the arms.
8. **Where and how they live:** both: tight-knit core areas plus arms/branches of colonies. Probably the most
   common race in the galaxy.
9. **Crew traits:** as FTL's humans: they gain skills faster.
10. **Ship tiers:** as FTL.

## Azurethea (draft, 2026-10-21)

1. **Tone and ship style:** a butterfly-like race of peaceful creatures using a mix of biomechanical technology.
   Ships shaped much like moths or butterflies, partly organic. Silhouette (Proposed): winged.
   Colours (Ai Generated): iridescent blues and royal blues with wing-like patterns.
2. **Doing fine:** nearly pacifist and docile; highly likely to accept or offer surrender; primarily interested
   in exploration. Slightly isolationist about sharing technology or letting others on their ships.
3. **Struggling:** more willing to cooperate and more interested in trade.
4. **Doomed:** optimistic but aggressively defensive; cooperate with peaceful races, become vengeful against
   violent enemies.
5. **Relations:** will willingly become refugees when needed, but less inclined to accept refugees, especially
   violent ones. Try to avoid war, but are decisive once in one.
6. **Technology:** part-organic ships. They produce their own Terran-friendly atmosphere in whatever room they
   stand in. Weapons often disable systems with spores, or fire damaging shots at single rooms. Power works
   as FTL's default (a limited pool of power that can be moved to any system), flavoured as biological energy
   flowing through the whole ship rather than a power core or conduits.
   Weapon names (Ai Generated): biological, after creatures and natural things, like the Stinger.
7. **Near and inside their territory (Ai Generated):** quiet, lightly patrolled lanes along their veins, with exploration
   outposts at the tips. Their ships rarely start fights and readily accept surrender. Stores follow their mood:
   doing fine, they sell little of their own technology and few crew (isolationist); struggling, they open up and
   sell biomechanical systems and weapons (more interested in trade).
8. **Where and how they live:** sprawl in thin, almost veiny regions, reaching out for exploration or needed
   resources, and willingly leave unclaimed or neutral clusters near them.
9. **Crew traits:** half HP; produce breathable atmosphere; survive briefly outside a ship without an EVA suit,
   but cannot use EVA suits; repair biomechanical technology faster (most races struggle to repair it).
10. **Ship tiers:**
    - Low tech: single-system targeting shots (stinger missiles or single-shot energy beams).
    - Mid tech: spore systems or weapons that disable systems (cleared like a repair) and stun crew, with no breach
      or fire.
      Idea: their spores also mind control someone in the room, pacifying the enemy and making them fight each
      other. This would give mind control to the Azurethea. Possibly boarding crews, especially when they outnumber the other ship's crew. Higher evasion.
    - High tech: many weapon systems, missiles, a high-hull carapace, spore systems and weapons, good sensors,
      high evasion, medium shields at most.

## The Mecha (draft, 2026-10-21)

"The Mecha" is a working name that may become final.

1. **Tone:** an aggressive destruction race that guts ships; highly organized and tactical.
   Silhouette (Proposed): wide, aggressive battleships.
   Colours (Ai Generated): gunmetal and black with yellow and orange hazard markings.
2. **Doing fine:** territorial and aggressive. If outmatched, they may insist the interloper leave their
   territory. If they have the advantage they are likely to attack, only accepting surrender if they profit
   from it and are injured themselves.
3. **Struggling:** more likely to agree to trades or surrenders they can profit from or gain a power advantage
   from.
4. **Doomed:** still expect at least the appearance of an advantage or benefit for themselves; still not generous
   or charitable, but more inclined to teamwork when their survival depends on it.
5. **Relations:** not likely to become refugees unless absolutely desperate, and even then more likely to
   become raiders or pirates.
6. **Technology:** weapons tend to be high damage and destructive to hulls, lacking the finesse other races
   might prefer. Instead of an EVA Dock they have an **EVB Dock** (Extra Vehicular Battle Dock): a variant of
   the EVA Dock, basically battle EVA suits. It needs a battlesuit type, the way a drone bay needs a drone type,
   and likely costs material to launch. Crew fly out to ships themselves to attack (or do other things)
   repeatedly. Other races can use it if they acquire one.
   Tech type (Ai Generated): mechanical, which is why integrating with biomechanical systems takes them longer (point 9).
   Weapon names: descriptive and functional, e.g. Triple Shot - Single Target - Light Laser. On the weapon card a
   short code (Ai Generated), e.g. TS-ST Light Laser, with the full name as the official designation.
7. **Near and inside their territory:** in their core territory they help their own kind build, upgrade and
   repair. In their inner territories they may battle each other if one side appears weak or suspicious. Their
   border territories are typically in constant battle with whoever they border, and with criminals and pirates
   from other regions. Since they don't actively seek out criminals, only attacking when they run into them or
   see an advantage, some races find it worthwhile to hide inside Mecha border clusters.
8. **Where and how they live:** they expand like lakes or rivers, flowing into the regions of least resistance,
   preferring previously populated areas over empty regions where they would have to build infrastructure
   themselves. This gives criminals another place to hide, but to the Mecha, criminals developing empty
   clusters just makes them better to take later.
9. **Crew traits:** integrate with any ship system, powering it by one bar, similar to FTL's Zoltan; Mecha could
   perhaps be upgraded to power two bars. Integrating takes a moment longer to begin using a system and to
   disengage, and even longer with biomechanical systems. Slow movement, high melee damage, physically tough.
   Mecha ships have no reactor; if subsystems need power, the system has its own independent power. A single
   weapon system is hard for them to power, so their ships need multiple weapon systems or, more likely, rely on
   EVB suits. Whether Mecha breathe is undecided; assumed yes for now. Suffocation is their key weakness: take out
   their life support and one of them has to disengage and move to repair it.
10. **Ship tiers (Ai Generated):**
    - Low tech: one EVB Dock with laser battlesuits, plus one or two self-powered weapon systems with a
      hull-damage laser (Hull Smasher-like). Thin shields.
    - Mid tech: boarding battlesuits, breach missiles or bombs, a second EVB Dock or weapon system, more hull.
    - High tech: several or upgraded EVB Docks with beam battlesuits, heavy beams (Halberd or Glaive-like) and the
      most hull of any race; shields stay average. Their strength is gutting ships, not out-shielding them.

## Tentauri (draft, 2026-10-21)

Octopus-like race (earlier working label "Octopods").

1. **Tone and ship style:** octopus-like beings in small groups. Small crews and ships, perhaps two crew
   members on a standard ship, possibly mates. Their ships have few rooms with many systems in them.
   Silhouette (Proposed): compact, like tiny shuttles.
   Colours: prismatic, multicoloured ships, close to a chameleon or mother of pearl; aqua, teal and coral white
   or coral pink among them, in mottled patterns.
2. **Doing fine:** quiet and diplomatic, but if they want to go into a system they are willing to force their way
   in; not looking to destroy others, simply to get where they want to go, for whatever reason.
3. **Struggling:** willing to ally, usually in joint operations more than trade, e.g. having a ship join a fleet
   rather than gifting a ship.
4. **Doomed:** highly cooperative, possibly even allying with aggressive races.
5. **Relations (Ai Generated):** they rarely take refugees aboard, having little room, but readily escort refugee convoys
   through dangerous clusters (the joint operations of point 3). Doing fine, they trespass but avoid wars;
   struggling or doomed, they join other races' fleets, even aggressive ones. See also Relations between races.
6. **Technology:** most likely biomechanical, with the same power system as the Azurethea; they specialise in
   shields and defence. If there is a Zoltan-like shield (an extra energy shield layer), it would
   probably go to the Tentauri. Weapons tend to be standard lasers, beams or missiles as needed; they don't mind adapting.
   Weapon names (Ai Generated): from their own anatomy, as an evolved cephalopod-like invertebrate race would name
   things, not ocean themes: e.g. Coil, Grasp, Siphon, Tendril Beam.
7. **Near and inside their territory (Ai Generated):** few, far-apart regions of a handful of clusters each, heavily shielded
   and calm. Their stores stock shields, defence and Backup Batteries. Outside their regions, lone Tentauri ships
   are a common sight passing through other races' territory.
8. **Where and how they live:** explorers who spread by starting small regions further apart from each other
   than most races.
9. **Crew traits:** can run multiple systems at the same time, maybe up to four.
10. **Ship tiers (Ai Generated):**
    - Low tech: the Tough Little Scout (`ship-suggestions.md`): 2 crew, two rooms, one shield layer, Supershield,
      two Defense Lasers.
    - Mid tech: 2–3 crew, three rooms; two shield layers and a faster Supershield; defence that also shoots down
      lasers (like FTL's Defense Drone Mark II); a Pike-like beam; Backup Battery.
    - High tech: 4 crew, still few rooms; three shield layers plus Supershield; Halberd-like beam and Artemis-like
      missiles; a way to protect a squad-mate (GDD 3N), either a shield beam projected onto another ship or a
      Supershield missile that gives a squad-mate a Supershield layer.

## Senti-GPH (Sentient Generative Pre-trained Holograms) (draft, 2026-10-21)

1. **Tone and description:** holographic AI avatars, originally made by Terrans, who became their own people.
   They build, grow and multiply like other races; they archive information because they are made of
   information themselves.
   Silhouette (Proposed): Terran-like, but centralized around the AAA.
   Colours (Ai Generated): Terran white with cyan or cyan-green holographic light lines.
2. **Doing fine:** curious and logical; collect and preserve knowledge from every culture they meet.
3. **Struggling:** preserving data comes first; they trade for records, archives and storage, and also for things
   necessary for survival, such as defensive equipment as needed.
4. **Doomed:** no qualms about killing living people, while still willing to store their information and
   biological data.
5. **Relations:** taking in refugees costs them life support they don't otherwise need, so they would rather
   preserve a refugee race's records than house its people.
6. **Technology:** very similar to the Terrans', including the same power conduits, with advanced beam weapons
   and sensors. Besides an armoured core
   (the **AZC**, Armoured ZeroPoint Core, as on Terran ships, though maybe slightly worse), they have an **Armoured Avatar Array** (the
   **AAA** system) that stores and broadcasts their holographic avatars. If it is damaged, fewer avatars can be
   broadcast, so the ship has fewer holographic crew until it is repaired; they don't die from this unless the
   ship is destroyed. They don't usually use ion weapons themselves.
   Weapon names: number codes. Beams give rooms swept, type, damage and version, e.g. 3B 01 V2 (3-room beam,
   1 damage, version 2). Other weapons can start with the shot count instead (e.g. 2L 02 V1, a 2-shot laser with
   2 damage); a guideline, not an absolute rule.
7. **Near and inside their territory:** small, dense clusters built around relay and broadcast stations.
8. **Where and how they live:** see 7; they stay close together, since their avatars depend on arrays.
9. **Crew traits:** half HP individually; don't need oxygen; immune to fire. Bound to their ship's AAA, but a
   highly upgraded AAA can broadcast them directly onto another ship, with a cooldown. Ion disrupts them.
   Idea: their skill training is chosen in advance, when recruited or acquired; they cost more to recruit or
   acquire, especially since a ship needs an AAA of a minimum level to host even one; and they learn very poorly
   on their own (massively reduced skill gain).
10. **Ship tiers:**
    - Low: beams, good sensors, a small AAA.
    - Mid: hacking, a larger AAA.
    - High: more hacking, an upgraded AAA, shield-penetrating technologies or weapons; not likely missiles.

## Lykario (draft, 2026-10-21)

Wolf-like race (earlier working label "wolf race").

1. **Description and ship style:** evolved independently, but similar to Terran canines. Ships are a mix of
   stolen parts, but efficient when doing well.
   Silhouette (Proposed): Terran-like, but more rugged and hostile.
   Colours (Ai Generated): a patchwork of stolen hull colours under their own bone-white claw markings.
2. **Doing fine:** raid and attack others, seemingly for fun; willing to join up with others for a joint hunt.
3. **Struggling:** tend to be in denial, insisting things are fine and just wanting to continue the hunt, but
   even more willing to trade or join up.
4. **Doomed:** oddly vicious but optimistic and highly willing to team up, convinced they will be fine as long
   as they just keep going.
5. **Relations (Ai Generated):** they don't take in refugees as such, but take in anyone who proves useful on a hunt:
   refugees who fight beside them can join the pack, the rest are prey. They rarely become refugees themselves;
   doomed bands follow refugee convoys instead.
6. **Technology:** a mix of non-biomechanical tech stolen from others; basic weapons and technology; crew
   teleporters; cloaking. Their power model is whatever the ship they stole uses. They tend to use an autopilot while
   boarding others.
   Weapon names: most of their weapons are stolen and unmodified, so they keep their maker's name. Only the few
   they edit or build themselves get Lykario names (Ai Generated: hunting words, e.g. "Fang").
7. **Near and inside their territory:** see 8.
8. **Where and how they live:** small, localized, independent clusters that even attack each other.
9. **Crew traits:** quick attacks, reduced HP, Animal Senses.
   Animal Senses (Decided, designer, 2026-10-23): as if they are psychic, but player-facing text never calls it
   psychic. It is always "Animal Senses", and the senses are never explained. They sense Life Signs, without using ship sensors and even on
   other ships and in hazards.
10. **Ship tiers:** even their best ship designs are not that amazing, aside from larger or multiple crew
    teleporter rooms.

## Malphen (formally Malphagius) (idea, 2026-10-21)

Tumor race. "Malphagius" (roughly "the malignant devourer") is the formal or scientific name, used in lore and
events; "Malphen" is the everyday name.

Basically a core race.

- Silhouette (Proposed): bulbous, irregular shapes.
- Biomechanical weapons that infect a ship's systems and spread.
- Either the race is basically mutants, or it is a living ship with no crew.
- Weapons tend to be fired like fleshy missiles or like flak guns, to get through shields.
- Maybe they have the equivalent of the clone bay.
- Should probably have high HP and clone themselves.
- Idea: a mutation system that lets Malphen crew swap their specialty, e.g. anti-personnel, repair, fire.
- Idea: launching is a mutation. A Malphen mutates to survive the launch, then goes to an airlock or a launching
  bay and is fired into another ship. If it is just an airlock, that explains how they get back. Concern: there
  may already be too many ways to board a ship.
- Diplomacy through matter (2026-10-22): if they can't infect a ship and survive, or escape, they launch valuable
  debris into space for the other side to take and try to escape: their version of FTL's surrender offer, with
  no words. Otherwise they likely only pick off vulnerable ships, or use hit-and-run infection tactics.
  - Suggestion (Ai Generated): the debris might carry infection, making it a gamble to take. Only if the risk is
    visible to the player (e.g. sensors show infected debris), so accepting a surrender is never an unseen
    punishment.
- How they behave when doing fine, struggling and doomed: see the profile below.

Profile (Ai Generated):

1. **Tone and ship style:** both options above at once: each ship is a living organism, and its crew are parts it
   grows. So boarding still matters, and killing the crew isn't the end: the ship grows more unless its growth
   organ (the clone bay equivalent) is destroyed. Ships are swollen and lopsided (bulbous, irregular). Colours:
   flesh pinks, bruise purples and bone. They don't speak; events show them through what they do.
2. **Doing fine:** patient and quiet. They grow into empty and Abandoned clusters (GDD 2R), absorb wrecks, and
   rarely attack ships that keep their distance. They can't be talked to, but they can be paid in matter: a Hail
   (GDD 3O) offering Mawjig can buy passage.
3. **Struggling:** hungry. They hunt ships to absorb them, and accept surrender only as matter (Mawjig).
4. **Doomed:** they pick off vulnerable ships and use hit-and-run infection tactics (above), launch crew at
   ships they can take, and absorb their own weaker ships to keep the strongest going. When cornered they
   jettison debris to buy their escape.
5. **Relations:** everyone's rival, and they never become refugees in the usual sense: a doomed Malphen region
   spreads into its neighbours instead. No race takes Malphen in. The biomechanical races (Azurethea, Tentauri)
   fear them most, since infection spreads faster into biomechanical systems (GDD 8G).
6. **Technology:** biomechanical, with FTL's default power pool (as the Azurethea and Tentauri). The growth organ
   is their clone bay. Weapons carry infection (GDD 8G) or fire fleshy missiles and flak (above).
   Weapon names: they don't speak, so their weapons are named by the races who face them, grim and descriptive
   (e.g. Flesh Mortar).
7. **Near and inside their territory:** wreck fields being overgrown, derelict stations covered in growth, very few
   stores. Events are about infected ships and stations, and what can still be saved from them.
8. **Where and how they live:** one connected mass that grows outward from its edges, slowly swallowing
   neighbouring Abandoned clusters, so the player can watch it spread over a run: a small mirror of the collapse.
9. **Crew traits:** high HP (like FTL's Rockmen) and they slowly heal anywhere on a biomechanical ship (it is their
   own tissue); normal speed. Specialties come from the mutation idea above.
10. **Ship tiers:**
    - Low tech: fleshy missiles (Leto-like) and flak; the growth organ.
    - Mid tech: infection weapons; the mutation system.
    - High tech: swarm-like missiles, launch-mutation boarders, regrowth (hull repair, like FTL's Hull Repair
      drone).

## Whispwraith (partial draft, 2026-10-21)

Possibly the mysterious race of the ??? victory (see `ideas.md`); probably not a core race either way. Other
profile points were left until that is decided; they are filled in below as Ai Generated.

- **Description:** beings that seem to be made of a cloud of particles and energy.
- **Ship silhouette (Open):** maybe circular.
- **Technology:** their ships use FTL-style power levels, but instead of a reactor they get 2 bars per
  Whispwraith, allocatable anywhere in the ship. Their weapons tend to be ion weapons.
- **Crew traits:** survive in a different kind of atmosphere; oxygen atmospheres are toxic to them. They drain
  an oxygen environment, converting it into their own, taking damage from the oxygen meanwhile. Once in their
  own environment they heal over time, without needing a medbay. They can charge for a second and then teleport
  themselves to another room or ship, with a cooldown.
- Their atmosphere is harmful to other races.
- Probably recruitable by the player.

Profile (Ai Generated). Written so it still works if they become the ??? victory race; see the note at the end.

1. **Tone and ship style:** silent and alien; they rarely answer a Hail. Ships are smooth and round (silhouette
   above). Colours: translucent pale violet with a soft inner glow.
2. **Doing fine:** deep inside the collapse. Its radiation and distortion suit them, so their state runs the
   other way from every other race's: the deeper into the collapse, the better they do.
3. **Struggling:** near the collapse's edge, where it thins out. Defensive and wary; they drain and convert the
   atmosphere of any ship that attacks them.
4. **Doomed:** at the very edge. They attack any ship that crosses in, trying to take it over by converting its
   whole atmosphere to their own.
5. **Relations:** they neither take nor become refugees. No other race knows they exist; they likely live
   undiscovered inside the collapse (designer, 2026-10-23). The Senti-GPH,
   who don't need oxygen, are the only race that could share space with them.
6. **Technology:** as above: 2 power bars per Whispwraith, ion weapons; plus atmosphere conversion (an effect in
   the cost table). Weapon names: their own style, highly strange and alien (designer, 2026-10-23).
7. **Near and inside their territory:** their territory is the collapse itself (Swallowed clusters, GDD 2R).
8. **Where and how they live:** only inside the collapse; they don't exist outside it. The player meets them only
   on the ??? victory path, or through a secret way to recruit one, if one is added.
9. **Crew traits:** as above.
10. **Ship tiers:**
    - Low tech: ion blasts; one or two Whispwraith crew.
    - Mid tech: ion bombs and chain ion; crew who teleport themselves aboard.
    - High tech: heavy ion and atmosphere-conversion weapons; enough crew for many power bars.

Note: this fits them being the ??? race; only their command ship and the cause of the collapse would need
adding.

## Relations between races

There is no fixed table of rivals and friends: how two races treat each other depends on proximity (bordering or
distant) and on each side's state (doing fine, struggling, doomed). Each profile's point 5 gives the race's
tendencies; combine the two sides for the situation.

| Situation | What happens | Source |
|---|---|---|
| Azurethea ~ doomed distant Lykario | The Azurethea are peaceful toward them; if the Lykario want to team up, the Azurethea have little issue with it. | Designer |
| Azurethea ~ bordering Lykario | The Lykario hunt the Azurethea, as they do anyone bordering them. The Azurethea try diplomacy, but the more they struggle the more vindictive they become; it can easily turn into all-out war. | Designer |
| Tentauri ~ doomed Mecha ship | The Tentauri are defensive; the doomed Mecha may want to trade or join up, for their own advantage. | Designer |
| Doing-fine Malphen ~ doomed distant Mecha | The Malphen would likely attack on sight; knowing this, the Mecha would likely prepare a battle plan to attack first or escape. | Designer |
| Doomed Malphen ~ doing-fine Mecha | If the Malphen can't infect the Mecha ship and survive, or escape, they launch valuable debris for the Mecha to take and try to escape; otherwise they likely only pick off vulnerable ships, or hit and run with infection. | Designer |
| Doing-fine Terrans ~ bordering struggling Azurethea | The Terrans offer trade and take in refugees; the Azurethea, now more interested in trade, accept. One of the friendliest pairings. | Ai Generated |
| Doomed Terrans ~ bordering doing-fine Senti-GPH | The Terrans blame outsiders and steal technology, so they raid the Senti; the Senti, preserving data first, trade for defensive equipment. | Ai Generated |
| Struggling Tentauri ~ bordering doing-fine Mecha | The Tentauri force their way through; the Mecha insist they leave, or attack if they have the advantage. A likely forced-passage fight. | Ai Generated |
