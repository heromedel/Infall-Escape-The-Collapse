# Infall: Production Goals

What content and systems each goal needs, counted per band, cluster state and race, so sessions can be given work
and the gaps can be seen. Kept by the Production session (`Cloud-C-Production-Flow`). Every count here is an
**Ai-Generated-Proposal (2026-10-23)** unless tagged otherwise: FTL is the measuring stick (heromedel, 2026-10-23),
and the numbers come from FTL's own data files, scaled to Infall's 8 bands, cluster states (GDD 2R) and races.
Nothing here is a design decision; the design lives in `gdd.html` and the race profiles. GUI and assets are in
`production-gui-goals.md`.

Points this plan stands on, by tag: Decided 1A, 1C, 1D, 1F, 1H, 2A, 2F, 2J, 2K, 2R, 3C, 3E, 3F, 4B–4N, 5D, 6C, 6D,
7B, 8C, 8D, 10A; Likely 2C, 2G, 2H, 2L–2Q, 3A, 3D, 3H, 3K, 3L, 3M, 3O, 4A, 4O, 7C–7E, 7G, 8A, 8I; Proposed 2B, 2E, 2I,
3B, 3G, 5A–5C, 6A, 6E, 8B, 8E, 8F, 8H, 11A, 11B, 12A; Ai-Generated-Proposal 1I, 7G (mercenaries), 8G. Heromedel's
answers of 2026-10-23: LAN preparation is step 0 of any code; Goal A's enemies are the GATOS and the Mecha (or a
biomechanical race if system integration is avoided); the Tech victory is the first victory path, but until at
least 3 races and their parts exist, reaching an outer rim cluster and a final battle is enough; all core races by
alpha, probably; FTL is the measuring stick.

## 1. The measuring stick: what FTL ships with

Counted from vanilla `ftl.dat` (Advanced Edition), so Infall's numbers below can be compared like for like.

| FTL content | Count | Notes |
|---|---|---|
| Sector types | 14 in play (plus the Last Stand and the hidden Crystal sector) | A sector type is a race × (controlled or home), or a nebula or civilian space |
| Beacons per sector | 16–24, about 20 | 6×4 grid, 80% of cells get a beacon |
| Event lines per sector description | 7–12 lines, 14–35 events drawn in total | Each line draws min–max events from one list: store, items, nothing, distress, hostile, boarders, quests, nebula, neutral |
| Named top-level events | 647 | Across all files; plus 301 event lists and 125 text lists |
| Events a race's own sector draws from | about 45 own (hostile 5–10, neutral 6–16, distress 6–12, items 5–9, quests 1–5, boarders 1–5, store and nothing texts) plus shared pools (neutral 19, items 13, distress 14, hostile1 10, nebula 15, quests 6) | Engi, Zoltan, Mantis, Rock, Slug, Lanius, Pirate, Rebel each have their own lists |
| Events with a fight | 337 ship placements; 137 `<ship>` behaviour entries (surrender, escape, destroyed, dead crew rewards) | A behaviour entry is what Infall would call a squad's conduct |
| Enemy ship templates | 25 base layouts, 38 with pirate and AE variants | About 3 per race (scout, fighter, bomber); the same template scales by sector (hull, system caps, crew) |
| Weapons | 68 blueprints, 48 buyable | 33 buyable in the base game |
| Drones | 21 | |
| Augments | 43 | |
| Systems | 12 main + 4 subsystems | |
| Crew races | 8 | 1 per race plus humans |
| Hazards | 6 environment types | nebula, storm, asteroids, sun, pulsar, anti-ship battery |
| Blue options | 219 | Choices needing a system, crew race, weapon, drone or augment |
| Event text | 3,298 strings, about 66,000 words | Text lists give 3–5 variants of store and nothing texts |
| Player ships | 10 cruisers × 2–3 layouts | |

How FTL spreads content over a run: a sector draws about 20 of its type's events; a run visits about 10–12 beacons a
sector, so the player sees roughly half a sector's events each sector and roughly 90 events a run, about 1 in 7 of
the game's events. That ratio (about 7 events authored for every event seen) is the density to match.

## 2. How Infall's content is counted

FTL's unit is the sector type; Infall's is **race × cluster state × band**, which would multiply out of hand if
every cell were authored. The plan keeps authoring near FTL's size by layering:

1. **Band** is handled by scaling, not authoring: as in FTL, one enemy ship design scales its hull, system levels,
   crew count and loadout with the band (GDD 1C, 2N); rewards and repair prices follow the band tables. Bands only
   add authoring where a tier changes what exists: each race's low, mid and high tier designs (race profile point 10).
   **Update (2026-10-23):** Eco's F6 sets a squad value budget per band (137 in band 1 up to 1,243 in band 8), and a
   wreck pays 2.5% of the ship's value × a band adjustment (GDD 8I, Proposed), so a squad is sized by the value of its
   ships, not their count (heromedel: the count of ships is not the measure).
2. **Race** is the main author axis, as sector type is in FTL: each race gets its own event lists, ships, squads,
   weapons, store texts and stock weights.
3. **Cluster state** layers onto the race: the state adds and removes event lists and changes who is met (GDD 2R). The
   Doing Fine set is the race's base; Struggling, Doomed, Border, Refugee, Occupied and Abandoned are smaller sets of
   extra events, extra squads and store changes. A cluster with several states (GDD 2R) draws from all its lists, as
   FTL's homeworlds draw from the home and the generic lists.
4. **Shared pools** (nothing, hazards, generic distress, generic items, collapse messages, store texts) are written
   once, as FTL's NEUTRAL and ITEMS lists are.

**Ai-Generated-Proposal (2026-10-23), needs a decision:** this layering is the content model the counts assume. Whether
cluster states work as extra lists (this), as whole separate lists per state, or as conditions inside events changes the
counts and how Lori writes events. See the decisions list at the end.

### Per-race content set (the full set, reached at alpha)

| Content | Per race | FTL equivalent |
|---|---|---|
| Ship designs | **Proposed (heromedel, 2026-10-23):** a ship design carries loadouts by band range, e.g. a Terran pirate with a loadout for bands 1–3, another for 4–6 and a stronger one for 6–8 (the overlap is deliberate), plus alternate loadouts where the race has them (a Mecha ship with boarding suits or laser suits; pirates with a crew teleporter or bio lasers). Weaker ships or loadouts cover the low end of a band. Count (Ai-Generated-Proposal): about 3–4 hulls per race, each with 2–3 band-range loadouts and 0–2 alternates, so about 10–12 loadouts per race; a hull scales its hull points and system levels within its range as FTL's templates do | 3 templates per race, scaled by sector |
| Squad templates | about 15: Doing Fine 3 (patrol, convoy with escort, lone ship), Struggling 2, Doomed 3 (raiders, hijackers, fleeing band), Border 2 (warship group, mixed with the neighbour), Refugee 2 (convoy, convoy under attack), Occupied 2 (occupier's patrol, resistance), Abandoned 1 (scavengers). A squad is a named list of ship designs with counts per tier (`rough-example-squad-layout.md`, Proposed), filled to the band's value budget (economy findings F6) | 137 behaviour entries over 25 templates, about 5 per template |
| Squad conduct | per squad template: surrender chance and hull threshold, escape chance and timer, hail answers, what a win pays (GDD 8I) | surrender/escape/destroyed/deadCrew per `<ship>` |
| Events, Doing Fine | about 45: hostile 8, neutral 12, distress 8, items 6, quests 3, boarders 2, store texts 4, nothing texts 3, plus 3 blue options tied to the race's crew or tech | a race's own sector lists |
| Events, other states | Struggling 10, Doomed 12, Border 6 (per race; a border between two races draws both), Refugee 8, Occupied 8 (as occupier 4, as occupied 4), Abandoned 4 (what this race left behind) = about 48 | none; FTL has no states |
| Weapons | 8: 3 low, 3 mid, 2 high, built from parts and priced (GDD 8E), named in the race's style | about 5–6 weapons appear on a race's ships |
| Systems | 0–2 race systems (AZC and conduits, EVB Dock, Supershield, AAA, Mutation, growth organ, Animal Senses) | 0–1 (Zoltan shield, Lanius-only tech) |
| Crew | 1 crew race with traits, name list, art | 1 |
| Store | store texts 4, a stock weight table per state (what the race sells doing fine, struggling, as occupier, when refugees), prices from the tables | sector rarity tables, 3–5 store texts |
| Lore and text | race facts in `lore-facts.md`, 2–3 ship name lists, voice notes for event writing | names.xml, sector intro texts |

So a race at full size is about 93 events, 6 hulls, 15 squads, 8 weapons. Seven core races: about 650 race events,
which with the shared pools (section 3) lands near FTL's 647, as the measuring stick asks.

## 3. Shared content (written once)

| Content | Count | Notes |
|---|---|---|
| Collapse opening messages | 5 | GDD 2P, one per jump, laid over ordinary events |
| Collapse distance texts | 8 | 2B: near the horizon and far from it, per 2 bands; shock near, disbelief far |
| Generic nothing | 1 event, 6 texts | |
| Generic store | 1 event, 5 texts, stock rules per state (2R) | |
| Hazards | 6 environments as FTL's, 12 hazard events (2 per hazard) | Swallowed cluster edge as a 7th hazard at Goal B |
| Generic distress | 14 | neutral or refugee ships of any race, traps |
| Generic items and trading | 13 | derelicts, wrecks to convert to Mawjig, refuelling stations |
| Generic neutral | 19 | mercenaries (7G), traders, lone travellers, beggars |
| Quests | 6 generic chains | plus the race quests above |
| Neutral and unclaimed clusters | 10 | between regions (2K) |
| Abandoned clusters, generic | 8 | derelicts, scavengers, pirates, Malphen moving in (2R) |
| Exit and rim | 8 | the last clusters before the rim, the escape (Goal B) |
| Final battle | 1 squad and 3 events | the stage 7 rival (2G) |
| Shared pool total | about 120 events | FTL's shared pools are about 80 |

## 4. The goals

Each goal lists what must exist. "Exists" means in the docs, priced and checked, in the form a coder can build from:
ships in `ship-suggestions.md`, weapons in the cost tables, events in Lori's event files, squads in a squad file.

### Goal A: minimum playable prototype

One playable race, a short run, every core loop present once.

| Area | Needed | Status (2026-10-23) |
|---|---|---|
| Network and players | Host and join flow designed before any other code (heromedel: step 0): Captain hosts, Commanders join by LAN direct IP (4A), assignment of ships and crew (4C, 4D), shared pool (4E), drop in and out (4F), Pause Control and Turn Mode settings (4H, 4I), event choice voting (4M), pause and vote indicators (4L) | Decided in the GDD; the host flow and what the network carries each tick are not written |
| Player race | Terrans (7C): the Terran Starting Scout, AZC with conduits (7E), conduit setting | Scout designed; conduit rules and routing need a worked ruleset |
| Enemy races | GATOS (doing fine patrols, doomed pirates) and the Mecha (border, EVB suits, system integration) | Mecha Light Attack Frame (1 hull, 2 loadouts) and the Light Attack Pair squad done and merged 2026-10-23 (`handoffs/done/2026-10-23-1417-ship-designs-mecha-light-attack-squad.md`); 1 more Mecha low hull still needed; Terran Pirate Hijacker exists (mid tier, band 5: needs a low-tier pirate) |
| Bands | 1–3 (low tier); the run ends at the band 3 edge with a results screen | |
| Map | Open cluster map (2C) with Terran and Mecha regions, neutral clusters between, deep/inner/border ranks (2K), no dead ends (2F), the 5-jump opening (2P), the collapse ring (2Q); states in play: Doing Fine, Doomed, Border | Generation rules (region shapes, how many clusters, link rules) are not written |
| Ships | Terran: Outrider + 1 more hull (patrol or pirate) with bands 1–3 loadouts; Mecha: Light Attack Frame loadouts for bands 1–3, including one weak enough for a band 1 budget (F6: 137), + 1 more hull if needed = 3–4 hulls | 3 hulls (Outrider; Pirate Hijacker hull with the Cutpurse bands 1–3 loadout, done 2026-10-23, `handoffs/done/2026-10-23-2130-ship-designs-terran-pirate-low-loadout.md`; Light Attack Frame, whose pair is a band 2–3 squad, band 1 loadout still needed) |
| Squads | Terran doing fine 2, Terran doomed 2, Mecha border 2, Mecha doing fine 1, mixed border 1 = 8 templates, sizes 1–3 | 2 of 8 (Light Attack Pair; Terran Pirates with the Cutpurse in its Low row); squad format: heromedel's `rough-example-squad-layout.md` (Proposed), conduct lines optional |
| Events | shared: collapse opening 5, nothing 1 (3 texts), store 1 (3 texts), hazards 3 of 6 (nebula, asteroids, sun) with 6 events, distress 6, items 6, neutral 8; Terran doing fine 15, Terran doomed 8; Mecha doing fine 10, border 5 = about 70 events | 8 of about 70: collapse opening 5 and Terran store texts 3 done and merged 2026-10-23 (`events-collapse-opening-and-terran-stores.md`; `handoffs/done/2026-10-23-2052-lori-collapse-opening-and-store-texts.md`); two sample events exist (`events-sample.md`) |
| Weapons | Terran 4 (2 exist), Mecha 3, stolen or found 2 = 9 | 5 of 9 (Gat 3.1, Gat M1, Gat 2.1, DS-ST Hull Laser, laser battlesuit; the Sporewing is Azurethea) |
| Systems | FTL's core set renamed as decided (Life Support 8B), conduits and AZC, EVB Dock with 1 suit type, Supershield only if the Tentauri replace the Mecha | Prices exist for all; behaviour of EVB and conduits needs a ruleset |
| Crew | Terran, Mecha traits (integration timing, slow, tough); Terran name list | Traits proposed in profiles; no name lists |
| Economy | Mawjig display, jump 1.21, wait 0.21, rewards bands 1–3, repair prices, store prices | Tables exist |
| Combat | FTL rules on fixed ticks (3E), pan and zoom (3C), formation (3H), Hail with surrender (3O), wall breaches off | |
| Win and loss | Loss: all scouts gone (1F); end: band 3 reached | |

### Goal B: playable through to the end

| Area | Needed on top of A |
|---|---|
| Bands | 1–8, with mid and high tier ships for every race in play, enemy squads up to 6 ships, rewards and prices for all bands, grinding allowed (2O; concern 1) |
| Races | 3: GATOS, Mecha, and one biomechanical race (Tentauri, whose scout exists, or Azurethea, whose Stinger exists), so the Tech victory's parts can later come from 3 races |
| States | all seven in play: Doing Fine, Struggling, Doomed, Border, Refugee, Occupied, Abandoned; Swallowed as the map edge; Core and At War stay Open unless decided |
| Map | full galaxy: random region placement (2M), race strength from placement (2N), 8 hidden bands (2H), the rim; ring expands one jump per jump |
| Ships | 3–4 hulls per race × 3 = about 10, each with its band-range loadouts (about 30–36 loadouts) |
| Squads | 15 per race × 3 = 45 plus 2 neutral convoys and the final rival |
| Events | per race 93 × 3 = about 280, shared pool 120 = about 400 (70 from A) |
| Weapons | 8 per race × 3 = 24 plus 6 neutral or stolen = 30 |
| Systems | all of FTL's (8A) under their Infall names, plus the race systems of the 3 races; Jigawatt Drive (6D) |
| Victory | reach an outer rim cluster and fight the final rival (doomed Terran band); the Tech victory (ideas) waits for its 3 races' parts and goes in at C |
| Mercenaries | FTL's mercenary (7G): fight, or pay to scout a region; they cannot slow the collapse |
| Ship loss and replacement | wrecks of own ships, replacement ships from events and stores (1I; needs review), 3–4 strong or 6 good ships by the end (3K) |
| Save and load | a run can be saved and resumed, including the collapse position |

### Goal C: alpha

| Area | Needed on top of B |
|---|---|
| Races | all 7 core races: GATOS, Azurethea, Mecha, Tentauri, Senti-GPH, Lykario, Malphen; starting race unlocks (7C) for at least 2 more |
| Ships | about 25 hulls, about 80 loadouts; squads about 105; relations between races in border and occupied squads (race profiles, Relations) |
| Events | about 650 race events + 120 shared = FTL's size; blue options for every race's crew and tech (FTL has 219) |
| Weapons | 56 race weapons + 8 neutral; every effect in the cost table used by at least one weapon |
| Systems | EVA Dock, EVB Dock suit types, Supershield, AAA, Mutation, growth organ, Infection effect (8G), tech types fully (8D) |
| Victory | Tech victory in full: one part from each pair, each race's own version, as the ideas table; the final rival keeps its place as stage 7 |
| Multiplayer | every setting in section 4 working, captain transfer (4N, 4O), spectating Commander |
| Economy | Eco's simulation run over whole runs; reward curve retuned if bands 7–8 starve (F4) |
| Modding | folder-per-ship and folder-per-weapon formats final (11A, 11B), so content sessions write directly in them |
| Lore | every event checked against `lore-facts.md`; every race's voice in writing |

### Goal D: beta

| Area | Needed on top of C |
|---|---|
| Races | Whispwraith and the ??? path only if decided; otherwise they stay out |
| Victory | the other victory paths heromedel decides to keep (alliance, exploration, collection), each with its own event chains |
| Balance | full-run simulation per race start; difficulty settings; hidden band tuning (2H) |
| Onboarding | band 1 teaches through play, never a visible tutorial (standards) |
| Settings | the optional toggles named in the GDD (map zoom, conduits, formation, multi-target lasers if kept) |
| Polish | sound, music per race and state, event art, achievements or unlocks, logs and debug commands (standards: more logs) |
| Modding | mod loading from folders tested with a sample mod |

## 5. Decisions the counts depend on (not made yet)

Each is Open or Proposed in the docs. Any session can fill one in as an Ai-Generated-Proposal; heromedel decides.

1. **Content model for cluster states** (section 2): extra lists layered on the race's base, or something else.
2. **Enemy ship scaling by band**: FTL scales one template by sector (hull, system caps, loadout from a weapon list). heromedel (2026-10-23, Proposed): loadouts by band range on one hull (1–3, 4–6, 6–8) and alternate loadouts; weaker loadouts for the low end. The band's squad value budget (F6) bounds what a squad carries. Still open: how a hull's hull points and system levels scale inside a loadout's range.
3. **Squads as data**: heromedel (2026-10-23, Proposed): a squad is a named list of ship designs with counts per tier (`rough-example-squad-layout.md`); conduct lines (surrender, escape, hail, pay) are an optional extra, first drafted in the Light Attack Pair.
4. **Map generation rules**: clusters per band (about 10, 2O), clusters per region, region shapes per race (profiles point 8), link density, where neutral clusters go, how the 5-jump opening is laid out.
5. **Store stock by state**: 2R gives the direction (short stock, barren, either side when occupied); the weights and slot counts are not set. FTL: 2–4 sections of 3 items, systems forced in some cases.
6. **Goal B's end**: what an outer rim cluster is on the map, and what the final battle is (the doomed Terran band is an idea, not a decision).
7. **Which biomechanical race is Goal B's third race**: Tentauri (scout designed, Supershield) or Azurethea (Stinger designed, spores, default FTL power).
8. **Mecha system integration in Goal A**: engage and disengage timing is still open. Settled 2026-10-23: integration never powers a system above its level (Decided); extra bars are mech upgrades at the Cybernetic Servicing Core (Likely); suits carry their own oxygen and every launch uses a new suit (Likely); a hit suit's rules (Proposed). EVB suits are in A through the Light Attack Pair.
9. **Terran conduit rules**: what a cut conduit does per tick, reroute as a player action, repair time; the setting's Off conversion.
10. **Ship loss (1I)**: escape pods, own-wreck salvage, replacements are still Ai-Generated-Proposal.
11. **Network model**: what the host owns, what clients send (orders only), tick rate, and how a drop-out is held (4F); needed before any code (heromedel).
12. **Core and At War states** (2R): in play or not for B.
