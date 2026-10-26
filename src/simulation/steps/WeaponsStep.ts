/**
 * Weapons each tick: a weapon system's bars power its weapons in mount order; a powered weapon with a target
 * charges, a manned weapon room charges a little faster; a charged weapon fires its volley, one shot every fifth
 * of a second, paying Mawjig per shot from the squad's pool (GDD 8C). A squad that can't pay doesn't fire.
 */

import { Ship, Weapon } from '../Ship';
import { Squad } from '../Squad';
import { Shot } from '../Shot';
import { secondsToTicks } from '../Ticks';
import { BattleLog } from '../BattleLog';

const MANNED_SPEEDUP = 1.1;
const TICKS_BETWEEN_SHOTS = secondsToTicks(0.2);

/** Which weapons have power: in mount order, each takes its bars from the weapon systems' working bars. */
export function poweredWeapons(ship: Ship): Set<Weapon> {
  const powered = new Set<Weapon>();
  const weaponSystems = ship.systems.filter((system) => system.name === 'Weapons' || system.name === 'Weapon Pod');
  let barsLeft = weaponSystems.reduce((sum, system) => sum + (system.isWorking ? system.workingBars : 0), 0);
  for (const weapon of [...ship.weapons].sort((a, b) => a.mount - b.mount)) {
    if (weapon.definition.power <= barsLeft) {
      barsLeft -= weapon.definition.power;
      powered.add(weapon);
    }
  }
  return powered;
}

export function weaponsStep(ship: Ship, squad: Squad, shots: Shot[], flightTicks: number, nextShotId: () => number, log: BattleLog): void {
  const powered = poweredWeapons(ship);
  const manned = ship.systems.some((system) => (system.name === 'Weapons' || system.name === 'Weapon Pod') && system.mannedBy) ? MANNED_SPEEDUP : 1;
  for (const weapon of ship.weapons) {
    if (!powered.has(weapon)) { weapon.chargeTicks = 0; weapon.volleyShotsLeft = 0; continue; }
    if (weapon.volleyShotsLeft > 0) { continueVolley(ship, weapon, squad, shots, flightTicks, nextShotId, log); continue; }
    if (!weapon.target) continue;
    weapon.chargeTicks = Math.min(weapon.chargeNeeded, weapon.chargeTicks + manned);
    if (weapon.isCharged) {
      weapon.chargeTicks = 0;
      weapon.volleyShotsLeft = weapon.definition.shots;
      weapon.nextShotTicks = 0;
    }
  }
}

function continueVolley(ship: Ship, weapon: Weapon, squad: Squad, shots: Shot[], flightTicks: number, nextShotId: () => number, log: BattleLog): void {
  if (weapon.nextShotTicks > 0) { weapon.nextShotTicks--; return; }
  const cost = weapon.definition.mawjigPerShot;
  if (!squad.pay(cost)) {
    log.event('no_mawjig', { ship: ship.name, weapon: weapon.definition.name, needed: cost, pool: squad.mawjig });
    weapon.volleyShotsLeft = 0;
    return;
  }
  shots.push(new Shot(nextShotId(), weapon.definition, ship.id, weapon.target!.shipId, weapon.target!.roomId, flightTicks));
  log.event('shot_fired', { ship: ship.name, weapon: weapon.definition.name, targetShip: weapon.target!.shipId, room: weapon.target!.roomId, cost });
  weapon.volleyShotsLeft--;
  weapon.nextShotTicks = TICKS_BETWEEN_SHOTS;
}
