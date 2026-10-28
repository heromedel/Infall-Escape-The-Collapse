/**
 * Weapons each tick: a weapon system's bars power its weapons in mount order; a powered weapon with a target
 * charges, a manned weapon room charges a little faster; a charged weapon fires its volley, one shot every fifth
 * of a second, paying Mawjig per shot from the squad's pool (GDD 8C). A squad that can't pay doesn't fire. A
 * weapon without autofire lets its target go once its volley is away (the genre's fire-once).
 */

import { Ship, Weapon } from '../Ship';
import { Squad } from '../Squad';
import { Shot } from '../Shot';
import { secondsToTicks } from '../Ticks';
import { BattleLog } from '../BattleLog';

const MANNED_SPEEDUP = 1.1;
/** Not in the docs yet: the gap between a burst's shots. The genre keeps it in its engine, not its data; unmeasured, so a guess. */
const TICKS_BETWEEN_SHOTS = secondsToTicks(0.2);

/**
 * Which weapons are live: in slot order, each weapon the player powered takes its cost from its weapon system's
 * working bars while they last. Damage shrinks the working bars, so weapons go offline from the last slot
 * leftwards, as in the genre.
 */
export function poweredWeapons(ship: Ship): Set<Weapon> {
  const powered = new Set<Weapon>();
  for (const system of ship.weaponSystems) {
    let barsLeft = system.isWorking ? system.workingBars : 0;
    for (const weapon of ship.weaponsOf(system)) {
      if (!weapon.powered) continue;
      if (weapon.cost <= barsLeft) { barsLeft -= weapon.cost; powered.add(weapon); }
    }
  }
  return powered;
}

/**
 * A powered weapon that no longer fits its system's working bars (damage) loses its power for good: its bars go
 * back to the reactor and the player has to power it again, repair or not (genre, heromedel's example 2).
 */
function dropWeaponsThatNoLongerFit(ship: Ship, live: Set<Weapon>, log: BattleLog): void {
  for (const weapon of ship.weapons) {
    if (!weapon.powered || live.has(weapon)) continue;
    weapon.powered = false;
    const system = ship.weaponSystemOf(weapon);
    if (system && ship.power.kind !== 'SelfPowered') ship.power.setBars(system, Math.max(0, system.bars - weapon.cost));
    log.event('weapon_offline', { ship: ship.name, weapon: weapon.definition.name, system: system?.key ?? '' });
  }
}

export function weaponsStep(ship: Ship, squad: Squad, shots: Shot[], flightTicks: number, nextShotId: () => number, log: BattleLog): void {
  const powered = poweredWeapons(ship);
  dropWeaponsThatNoLongerFit(ship, powered, log);
  const manned = ship.systems.some((system) => (system.name === 'Weapons' || system.name === 'Weapon Pod') && system.mannedBy) ? MANNED_SPEEDUP : 1;
  for (const weapon of ship.weapons) {
    // Not in the docs yet: an unpowered weapon loses charge as fast as it gained it, and keeps what is left for when it is powered again.
    if (!powered.has(weapon)) { weapon.chargeTicks = Math.max(0, weapon.chargeTicks - 1); weapon.volleyShotsLeft = 0; continue; }
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
  if (weapon.volleyShotsLeft === 0 && !weapon.autofire) weapon.target = undefined;
}
