# Drone Ability Prices (draft)

Priced so drone abilities can be reused as building blocks, for example EVB battlesuits (GDD ideas: a suit needs a
suit type the way a drone bay needs a drone type) and Malphen mutations (race profile: a mutation system lets crew
swap specialty, e.g. anti-personnel, repair, fire). Nothing decided.

## How the numbers were made

- **Buy price:** FTL's drone price × 0.242, the same carry-over used for systems, crew and augments. No price ends
  in zero (x.x0 adds 0.01).
- **Use cost:** FTL charges one drone part per deployment. Infall has one resource, so the cost of using an ability
  is its shots, priced from `mawjig-cost-table.md` (laser 0.02, beam 0.03 per room, missile 0.05, ion +0.02,
  fire +0.03 scaled by chance). Drones with no weapon have no shot cost; how they pay per use is open.
- Weapon stats come from FTL's blueprint data. Drone fire and breach chances in that data are small (10%) and are
  left out of the shot costs, except the Fire Drone's 90%.

## Drones and their abilities

| Drone | FTL buy (scrap) | Buy (Mawjig) | What it does | Use cost |
|---|---|---|---|---|
| System Repair Drone | 30 | 7.26 | Seeks out damaged systems and repairs them automatically. | Repairs systems |
| Anti-Personnel Drone | 35 | 8.47 | Seeks out and attacks intruders on board your ship. | Fights boarders |
| Anti-Combat Drone | 35 | 8.47 | Stuns enemy combat drones attacking your ship. | Counters enemy drones |
| Anti-Ship Ion Drone I | 50 | 12.11 | Combat drone with a 1-ion shot. | Ion shots: 0.04 per shot |
| Anti-Ship Missile Drone I | 50 | 12.11 | Combat drone with a missile (1 damage). | Missile: 0.05 per shot |
| Combat Drone Mark I | 50 | 12.11 | Attacks the enemy ship continually (1-damage laser). | Laser: 0.02 per shot |
| Anti-Ship Beam Drone I | 50 | 12.11 | Attacks with a small beam (1 damage). | Beam: 0.03 per room swept |
| Defense Drone Mark I | 50 | 12.11 | Shoots down incoming missiles, asteroids and flak debris. | Laser: 0.02 per shot |
| Anti-Ship Fire Drone | 50 | 12.11 | Small beam that lights rooms on fire (no hull damage). | Beam 0.03 + fire at 90% 0.03 = 0.06 per room |
| Anti-Ship Beam Drone II | 60 | 14.52 | Combat drone with a larger beam. | Beam: 0.03 per room swept |
| Shield Overcharger | 60 | 14.52 | Creates a single Supershield barrier periodically. | No weapon |
| Ion Intruder Drone | 65 | 15.73 | Breaches the enemy hull and randomly ionizes systems. | No weapon |
| Defense Drone Mark II | 70 | 16.94 | Fires faster than Mark I and also shoots down incoming lasers. | Laser: 0.02 per shot |
| Boarding Drone | 70 | 16.94 | Breaches the enemy hull and wreaks havoc inside. | No weapon |
| Hacking Drone | 70 | 16.94 | Hacking drone; FTL's description text not checked. | No weapon |
| Combat Drone Mark II | 75 | 18.15 | Like Mark I but moves and shoots faster. | Laser: 0.02 per shot |
| Hull Repair | 85 | 20.57 | Repairs 3-5 hull damage per drone part. | No weapon |

## Notes for building EVB suits and mutations

1. **Suit types map to the combat and boarding rows.** A laser suit is the Combat Drone row, a beam suit the Beam
   rows, a boarding suit the Boarding Drone row. The suit's sortie cost is its shots (see EVB cost in `ideas.md`),
   not a drone part.
2. **Support abilities have no shot cost.** System Repair, Hull Repair, Shield Overcharger, Anti-Combat and Hacking
   would need their own per-use rule. This is the open question that stops EVB suits and mutations from being
   fully priced.

   **Per-use rule (Ai Generated):** each use is priced by the effect it delivers, from the Effect table in
   `mawjig-cost-table.md`, without a shot base, since nothing is fired. A use that copies something the store
   sells costs the store price, so the ability is a convenience, never a discount.

   | Ability | One use | Cost per use |
   |---|---|---|
   | System Repair | one system bar repaired | 0.11 (Repair) |
   | Hull Repair | one hull point | the band's store price, 0.48 / 0.73 / 0.97 |
   | Shield Overcharger | one Supershield layer | 0.02 (it stops what one laser shot does) |
   | Anti-Combat | one stun on a drone or suit | 0.02 (Stun) |
   | Hacking | one hack activation | 0.04 (Lockdown) |
   | Anti-Personnel | one deployment | 0.21 (a 10-shot laser sortie, as the EVB laser suit) |
   | Boarding | one launch | 0.08 (missile 0.05 + breach 0.03) |
   | Ion Intruder | one launch | 0.11 (missile 0.05 + breach 0.03 + ion 0.02 = 0.10, no trailing zero) |
3. **Mutations use the same rows, limited to on-ship types.** A mutation has no EVA, so it cannot take an
   external combat type. It takes drone abilities that work aboard the ship, such as Anti-Personnel and System
   Repair, and possibly a boarding type (designer's words: "maybe a boarding mutation"). No separate mutation price
   is needed, because the prices are built from FTL's base costs.

Sources: drone prices and stats from `ftl-baseline.md` and FTL's blueprint data; descriptions from FTL's game text.
