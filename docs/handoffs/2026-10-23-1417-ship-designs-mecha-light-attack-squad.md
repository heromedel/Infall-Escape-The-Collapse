# Handoff: Mecha low-tier light attack squad (two ships)

| | |
|---|---|
| Sent | 2026-10-23 14:17 UTC |
| From | Infall: Production (`Cloud-C-Production-Flow`) |
| To | Infall: Ship Designs (`Cloud-C-ShipDesign`) |
| Asked by | heromedel, 2026-10-23 |
| Serves | `production-goals.md`, Goal A: Mecha low-tier hulls (2 of 4 hulls), Mecha squads, Mecha weapons |
| Status | **sent** |

## The task

Design a **low-tier Mecha light attack squad of two ships** for bands 1–3, through `ship-design-process.md`, and
save it to `ship-suggestions.md`. Two hulls (or one hull in two loadouts if that reads better as a Mecha pair:
your call, say why), their weapons designed from parts and priced, and the squad itself written down as one unit.

## What exists to build on

- Race profile: the Mecha (HalfMechs), `race-profiles.md`: aggressive, organized, tactical; wide aggressive
  battleships; gunmetal and black with hazard markings (colours are Ai-Generated-Proposal); mechanical tech; no
  reactor, systems self-powered or powered by crew integration (point 9); EVB Dock with battlesuits instead of
  drones (point 6); weapons high damage and hull-destructive; names descriptive and functional ("Triple Shot -
  Single Target - Light Laser", code "TS-ST Light Laser"); low tier in point 10: one EVB Dock with laser suits plus
  one or two self-powered weapon systems with a hull-damage laser, thin shields. Most of this is Proposed; use it as
  the process allows and tag what you fill in.
- Lore: `lore-facts.md`, Mecha section, including the HalfMechs facts unknown to other races. Nothing in the design
  may contradict it; new facts go to heromedel as a numbered list, not into the file.
- Tables: `mawjig-cost-table.md`, `weapon-budget-table.md`, `system-prices.md` (EVB Dock priced as Drone Control),
  `drone-prices.md` (suit types map to drone rows; the laser suit sortie cost in `ideas.md`, EVB cost).
- FTL stand-ins for band 1–3 enemies: hull 7–10, 1 shield layer, `ftl-baseline.md` enemy templates.
- The Outrider (SC-1) and the Terran Pirate Hijacker show the finished shape of a design in `ship-suggestions.md`.

## Deliverable, in `ship-suggestions.md`

1. Each ship through steps 1–11 of the process: race Mecha, band 1–3, state Doing Fine or Border (your pick, with
   the reason), function "light attack squad", layout and systems, weapons, price, new rules recorded in the
   reference tables. Shield check and economy check as the Outrider has them.
2. A **Squad** section after the two ships. No squad format exists yet, so write it as a first draft of one, tagged
   Ai-Generated-Proposal, with at least: squad name; the ships in it; bands and states it appears in; squad size by
   band if it grows; how the two ships fight together (who targets what first, how the suits are used); conduct:
   surrender chance and hull threshold, escape chance and timer, how they answer a Hail (GDD 3O); what a win pays
   (per ship, GDD 8I, from the band table). Keep the FTL `<ship>` behaviour entry in mind as the measuring stick
   (surrender, escape, destroyed, dead crew), but write it in the docs' plain style, no FTL names.
3. Judgment calls listed at the end, and anything that needed a decision that isn't made, flagged. Expected:
   how crew integration powers a system in play (timing, one bar or two), whether the EVB suits need the Mecha to
   breathe (profile point 9, Likely) and what that means for launching, and whether a two-ship squad shares
   anything (a shield beam is Tentauri, not Mecha).

Creative steps follow the Creative 3-6 Rule in `CLAUDE.md`. No art is part of this task; the Arty art test runs on
its own.

## When done

Push to `Cloud-C-ShipDesign` and message Infall: Production with the commit. Production checks it against the
profile, the lore facts, the tables and the goals, then merges it into `Cloud-C-Production-Flow` or sends it back
with numbered points. Questions for heromedel go through Production, numbered.

## Log

- 2026-10-23 14:17 UTC: sent.
