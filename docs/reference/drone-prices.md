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
- **Mutation column (suggestion):** the same ability as a mutation takes × 0.75 of the drone price, the same "a
  worse analog" factor used for the mutation system itself. First guess, not design.
- Weapon stats come from FTL's blueprint data. Drone fire and breach chances in that data are small (10%) and are
  left out of the shot costs, except the Fire Drone's 90%.

## Drones and their abilities

| Drone | FTL buy (scrap) | Buy (Mawjig) | As a mutation (suggested) | What it does | Use cost |
|---|---|---|---|---|---|
| System Repair Drone | 30 | 7.26 | 5.45 | Seeks out damaged systems and repairs them automatically. | Repairs systems |
| Anti-Personnel Drone | 35 | 8.47 | 6.35 | Seeks out and attacks intruders on board your ship. | Fights boarders |
| Anti-Combat Drone | 35 | 8.47 | 6.35 | Stuns enemy combat drones attacking your ship. | Counters enemy drones |
| Anti-Ship Ion Drone I | 50 | 12.11 | 9.08 | Combat drone with a 1-ion shot. | Ion shots: 0.04 per shot |
| Anti-Ship Missile Drone I | 50 | 12.11 | 9.08 | Combat drone with a missile (1 damage). | Missile: 0.05 per shot |
| Combat Drone Mark I | 50 | 12.11 | 9.08 | Attacks the enemy ship continually (1-damage laser). | Laser: 0.02 per shot |
| Anti-Ship Beam Drone I | 50 | 12.11 | 9.08 | Attacks with a small beam (1 damage). | Beam: 0.03 per room swept |
| Defense Drone Mark I | 50 | 12.11 | 9.08 | Shoots down incoming missiles, asteroids and flak debris. | Laser: 0.02 per shot |
| Anti-Ship Fire Drone | 50 | 12.11 | 9.08 | Small beam that lights rooms on fire (no hull damage). | Beam 0.03 + fire at 90% 0.03 = 0.06 per room |
| Anti-Ship Beam Drone II | 60 | 14.52 | 10.89 | Combat drone with a larger beam. | Beam: 0.03 per room swept |
| Shield Overcharger | 60 | 14.52 | 10.89 | Creates a single Supershield barrier periodically. | No weapon |
| Ion Intruder Drone | 65 | 15.73 | 11.81 | Breaches the enemy hull and randomly ionizes systems. | No weapon |
| Defense Drone Mark II | 70 | 16.94 | 12.71 | Fires faster than Mark I and also shoots down incoming lasers. | Laser: 0.02 per shot |
| Boarding Drone | 70 | 16.94 | 12.71 | Breaches the enemy hull and wreaks havoc inside. | No weapon |
| Hacking Drone | 70 | 16.94 | 12.71 | Hacking drone; FTL's description text not checked. | No weapon |
| Combat Drone Mark II | 75 | 18.15 | 13.61 | Like Mark I but moves and shoots faster. | Laser: 0.02 per shot |
| Hull Repair | 85 | 20.57 | 15.43 | Repairs 3-5 hull damage per drone part. | No weapon |

## Notes for building EVB suits and mutations

1. **Suit types map to the combat and boarding rows.** A laser suit is the Combat Drone row, a beam suit the Beam
   rows, a boarding suit the Boarding Drone row. The suit's sortie cost is its shots (see EVB cost in `ideas.md`),
   not a drone part.
2. **Support abilities have no shot cost.** System Repair, Hull Repair, Shield Overcharger, Anti-Combat and Hacking
   would need their own per-use rule. This is the open question that stops EVB suits and mutations from being
   fully priced.
3. **Malphen mutations** line up with the Anti-Personnel, System Repair, Fire and Boarding rows, which matches
   the specialties in the race profile.

Sources: drone prices and stats from `ftl-baseline.md` and FTL's blueprint data; descriptions from FTL's game text.
