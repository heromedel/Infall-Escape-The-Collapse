# Infall: Sample Events

Test mock-ups showing how an event is written down, made with `event-design-process.md`. Everything here is
**Ai-Generated-Proposal (2026-10-23)**: none of it is part of the design until heromedel reviews it. Facts used are
checked against `lore-facts.md`.

## How an event is written

1. **Name:** an ID in capitals (`REFUGEE_FAILING_AIR`) and a working title.
2. **Design:** a table answering steps 1–8 of the event design process.
3. **Text:** step 9, laid out the way the game shows it, in a plain block:
   - `OPENING` is the first box. Choices are numbered, ordinary ones first.
   - `[BLUE]` marks a blue choice, with its requirement in brackets first, as in FTL: `(Azurethea Crew)`. A blue
     choice the player can't take isn't shown.
   - Each outcome is a new box, named by its choice (`1`) or variant (`1a`, `1b` when one choice can roll
     different outcomes).
   - `BOX:` is the summary box under an outcome: what was gained or lost. Amounts never go in the prose.
     Rewards are written by size (low, medium, high), scaled by band (step 6), until the economy sets numbers.
     A fixed cost is written as an amount (`Mawjig -1.21`).
   - `THEN:` says what happens after the box, when it isn't simply the next jump (a fight, another event).
4. **Placeholders:** `{crew}` for a crew member's name, `{race}` for a race. Variant openings for other cluster
   states are written as their own `OPENING (state)` block.
5. **Checks:** the lore facts used, and anything the event needs that isn't decided yet.

## REFUGEE_FAILING_AIR: "Failing Air"

| Step | Answer |
|---|---|
| 1. Band, cluster, type | Bands 1–4. Any region's inner or border clusters. A distress call. |
| 2. Cluster states | Refugee. Also Struggling. |
| 3. Options | Repair (can go wrong), ferry refugees (a crew member joins), give Mawjig (a cost), leave. Blue: Azurethea crew. |
| 4. Involves | A crowded Terran refugee transport whose life support is failing. |
| 5. Meant to | Make the collapse personal early in a run, put a choice on a tight Mawjig budget, and show that crew traits matter. |
| 6. Band scaling | The Mawjig reward scales by band. The crew member joins at any band. |
| 7. Specific clusters | Refugee clusters first. The refugees can be another race's in other variants (`{race}`). |
| 8. Voice | The narrator, plain and informative. The transport's captain: a struggling Terran, tired and polite, still hopeful. |

```
OPENING
A crowded refugee transport drifts at the edge of the cluster, its running lights dimmed to save power. Its captain
hails you.

"Our life support is failing. We have twice the people aboard it was built for. We fled the collapse with
whatever would fly. Please, if you can spare anything, help us."

1. Send your crew over to repair their life support.
2. Ferry as many of them as you can to the nearest station.
3. Give them enough Mawjig to jump to the next cluster.
4. Wish them luck and leave.
5. [BLUE] (Azurethea Crew) Send {crew} to keep their air breathable.
```

```
1a
Your crew spend hours crawling through the transport's ducts and finally get its air scrubbers running again. The
captain sends over what little Mawjig they can spare and thanks you on behalf of everyone aboard.

BOX: Mawjig +(low)
```

```
1b
The transport's life support was pieced together from three different ships, and none of the parts want to work
together. Your crew get it running at half strength before a coolant line bursts and scalds {crew}. Half strength
will last the refugees as far as the next cluster. The captain thanks you anyway.

BOX: {crew} injured
```

```
2
You make trip after trip between the transport and a station that still has room. When the last refugees are
across, one of them, a former ship's engineer, asks to stay aboard and serve with your crew.

BOX: +1 crew (Terran)
```

```
3
You transfer enough Mawjig for a single jump. The captain thanks you. As you leave, the transport's drive begins to
charge.

BOX: Mawjig -1.21
```

```
4
You can't spare the time or the Mawjig. The transport's lights grow fainter behind you as you prepare to jump.
```

```
5
{crew} moves from cabin to cabin. Each room fills with fresh air the moment they stand in it. With the worst of
the danger past, your crew repair the scrubbers without hurrying. The captain sends over a share of their Mawjig.
One of the refugees also asks to join your crew.

BOX: Mawjig +(low)   +1 crew (Terran)
```

**Checks:**

- Lore used: the Azurethea produce breathable air wherever they stand (Proposed). Struggling Terrans stay hopeful
  (Proposed). Refugee clusters have recruitable crew and events asking for help, fuel or escort (GDD 2R, Decided).
  Mawjig is fuel (GDD 8C, Decided), and a jump costs 1.21 (GDD 6C, Decided).
- **Likely (2026-10-23):** the event doesn't appear before the collapse opening ends (GDD 2P), since the captain
  says they "fled the collapse". The exception is refugees from a war, who could appear earlier with their own
  opening (e.g. in At War clusters).
- Needs: choice 2 assumes a nearby station. If a cluster may have none, choice 2 needs other wording.
- Outcome 5 is fixed, like most FTL blue choices. Choice 1 rolls between 1a and 1b.

## SENTI_ARCHIVE_REQUEST: "The Archive Asks"

| Step | Answer |
|---|---|
| 1. Band, cluster, type | Bands 2–8. A Senti-GPH region's deep or inner clusters, at a relay station. A hail and trade. |
| 2. Cluster states | Doing Fine and Struggling use the first opening. Doomed uses its own (below). |
| 3. Options | Trade the home world's records for Mawjig, refuse. Blue: a Senti crew member gets a better price. Doomed: hand everything over, or fight. |
| 4. Involves | A Senti-GPH relay station. |
| 5. Meant to | Show what the player's people have lost as something others value, give a choice with no wrong answer, and show the Senti voice. Doomed: show how far a doomed Senti will go. |
| 6. Band scaling | The payment scales by band. The doomed station's ship scales as any enemy does. |
| 7. Specific clusters | Senti-GPH clusters only. |
| 8. Voice | The narrator. The station speaks as "We, The Senti-" in negotiation. A Senti crew member speaks as "I". |

```
OPENING (Doing Fine, Struggling)
A Senti relay station hangs above the cluster's largest moon, broadcasting on every channel at once. A hologram
flickers onto your screen.

"We, The Senti-, have learned that your people's world is gone. We would like to preserve its records in our
archive. We will pay for them."

1. Transmit your home world's records.
2. Refuse. Your people's history stays with your people.
3. [BLUE] (Senti-GPH Crew) Let {crew} negotiate.
```

```
1
You transmit everything your ships carry: maps, histories, songs and the names of the dead. The hologram stays
still while the station reads it all.

"We, The Senti-, thank you. Your world will be remembered for as long as we are."

The payment arrives a moment later.

BOX: Mawjig +(medium)
```

```
2
The hologram dips its head.

"We, The Senti-, understand. Records are only worth keeping when they are given freely."

The station goes back to its broadcasts as you prepare to jump.
```

```
3
{crew} steps up to the console. "I know what records like these are worth to them. Let me do the talking."

After a quick exchange of data, {crew} transmits the records. The station's payment arrives a moment later, far
more than it first offered.

BOX: Mawjig +(high)
```

```
OPENING (Doomed)
A Senti relay station turns its weapons toward you as you arrive.

"We, The Senti-, are preserving everything we can before this cluster is lost. We will preserve your records and
your biological data. Lower your shields. This will not take long."

1. Transmit your records and let them scan your crew.
2. Prepare for battle.
```

```
1
The station takes your records, then scans every member of your crew down to the cell. When it is finished, it
powers down its weapons without another word. You leave as quickly as your drives allow.
```

```
2
"We, The Senti-, will preserve what is left of you."

THEN: the station attacks.
```

**Checks:**

- Lore used: the Senti archive information because they are made of it, and collect knowledge from every culture
  (Proposed). They live around relay and broadcast stations (Proposed). "We, The Senti-" in negotiation, and "I"
  for a single Senti (Decided). Doomed Senti kill living people while still storing their information and biological
  data (Proposed). The player's scouts fly ahead of the last survivors of their home planet (GDD 1D, Decided).
- **Open (2026-10-23):** whether a relay station can fight like a ship (`ideas.md`, Stations as enemies). If not,
  the doomed variant's enemy is a Senti ship guarding the station.
- **Unlikely (2026-10-23):** giving away the records mattering later (the Senti Archive, the Tech victory).
