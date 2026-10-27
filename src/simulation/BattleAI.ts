/**
 * Orders for a squad nobody is steering: the enemy, and a stand-in player in tests. Once a second it powers
 * shields, engines, weapons and life support in that order, sends crew to man piloting, weapons, shields and
 * engines, sends idle crew to repair, and aims every weapon at the enemy's shields, then weapons, then piloting.
 * Not in the docs yet: enemy conduct per squad (surrender, escape) comes with the squad files.
 */

import { Order } from './Order';
import { Ship } from './Ship';
import { Squad } from './Squad';
import { Simulation } from './Simulation';
import { secondsToTicks } from './Ticks';
import { sameTile } from './content/Tile';
import { POWER_ORDER } from './PowerSupply';

const THINK_EVERY = secondsToTicks(1);
const MANNING_ORDER = ['Piloting', 'Weapons', 'Weapon Pod', 'Shields', 'Engines'];
const TARGET_ORDER = ['Shields', 'Weapons', 'Weapon Pod', 'Piloting', 'Engines'];

export function battleOrders(simulation: Simulation, squad: Squad): Order[] {
  if (simulation.tick % THINK_EVERY !== 1) return [];
  const enemies = simulation.squads.filter((other) => other.side !== squad.side).flatMap((other) => other.livingShips);
  const orders: Order[] = [];
  for (const ship of squad.livingShips) {
    orders.push(...powerOrders(ship));
    orders.push(...crewOrders(ship));
    if (enemies.length > 0) orders.push(...targetOrders(ship, enemies[0]));
  }
  return orders;
}

function powerOrders(ship: Ship): Order[] {
  if (ship.power.kind === 'SelfPowered') return [];
  let barsLeft = ship.power.totalBars;
  const orders: Order[] = [];
  for (const name of POWER_ORDER) {
    for (const system of ship.systems.filter((candidate) => candidate.name === name)) {
      const bars = Math.min(system.maxBars, barsLeft);
      barsLeft -= bars;
      orders.push({ kind: 'SetPower', shipId: ship.id, systemKey: system.key, bars });
    }
  }
  return orders;
}

/**
 * Stations are filled in priority order: a crew member already at a wanted station stays; the rest are sent,
 * nearest first in file order, to the stations still empty, then to damaged systems nobody is repairing.
 */
function crewOrders(ship: Ship): Order[] {
  const orders: Order[] = [];
  const able = ship.crew.filter((member) => member.isAlive && member.stunnedTicks === 0);
  const claimed = new Set<number>();
  const stations = MANNING_ORDER.map((name) => ship.system(name)).filter((system) => system !== undefined);
  const wantedStations = stations.slice(0, able.length);
  for (const station of wantedStations) {
    if (station.mannedBy && able.includes(station.mannedBy)) { claimed.add(station.mannedBy.id); continue; }
    const onTheWay = able.find((member) => !claimed.has(member.id) && member.path.length > 0 && member.path.at(-1) !== undefined && sameTile(member.path.at(-1)!, station.tile));
    if (onTheWay) { claimed.add(onTheWay.id); continue; }
    const member = able.find((candidate) => !claimed.has(candidate.id) && !isManningWanted(ship, candidate, wantedStations));
    if (!member) break;
    claimed.add(member.id);
    orders.push({ kind: 'MoveCrew', shipId: ship.id, crewId: member.id, tile: station.tile });
  }
  for (const system of ship.systems.filter((candidate) => candidate.damage > 0 || candidate.spored)) {
    if (ship.livingCrewInRoom(ship.roomOfTile(system.tile)!).length > 0) continue;
    const member = able.find((candidate) => !claimed.has(candidate.id) && candidate.path.length === 0);
    if (!member) break;
    claimed.add(member.id);
    orders.push({ kind: 'MoveCrew', shipId: ship.id, crewId: member.id, tile: system.tile });
  }
  return orders;
}

function isManningWanted(ship: Ship, member: { id: number }, wanted: { mannedBy?: { id: number } }[]): boolean {
  return wanted.some((station) => station.mannedBy?.id === member.id);
}

function targetOrders(ship: Ship, enemy: Ship): Order[] {
  const wanted = TARGET_ORDER.map((name) => enemy.system(name)).find((system) => system && !system.isBroken)
    ?? enemy.systems[0];
  const room = wanted ? enemy.roomOfTile(wanted.tile) : enemy.rooms[0];
  if (!room) return [];
  return ship.weapons
    .filter((weapon) => !weapon.target || weapon.target.roomId !== room.id || weapon.target.shipId !== enemy.id)
    .map((weapon) => ({ kind: 'TargetWeapon', shipId: ship.id, mount: weapon.mount, targetShipId: enemy.id, targetRoomId: room.id, autofire: true }));
}
