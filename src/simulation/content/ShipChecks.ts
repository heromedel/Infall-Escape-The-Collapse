/**
 * The rules a loaded ship must pass before the game will use it. A refusal says why, in a sentence, as GDD 5J
 * asks. Warnings are things the game tolerates but a designer would want to hear about (GDD 5H: a conduit that
 * reaches neither power nor a system).
 */

import { ShipDefinition, systemKey } from './ShipDefinition';
import { ConduitTile, Direction, Tile, neighbourTile, oppositeDirection, tileKey, tilesBetween } from './Tile';

export interface ShipCheckResult {
  /** Reasons the ship can't exist. Empty means the ship is accepted. */
  refusals: string[];
  warnings: string[];
}

/** The name of the system a conduit network starts from (race profiles, Terrans 6). */
const POWER_CORE_SYSTEM = 'AZC';

export function checkShip(ship: ShipDefinition): ShipCheckResult {
  const refusals: string[] = [];
  const warnings: string[] = [];
  const roomOfTile = mapTilesToRooms(ship, refusals);

  checkSystems(ship, roomOfTile, refusals);
  checkDoors(ship, roomOfTile, refusals);
  checkWeapons(ship, refusals);
  checkConduits(ship, roomOfTile, refusals, warnings);

  if (ship.rooms.length === 0) refusals.push('the ship has no rooms');
  if (!ship.doors.some((door) => !roomOfTile.has(tileKey(neighbourTile(door.tile, door.facing, ship.centering))))) {
    refusals.push('the ship has no airlock: every ship has a door facing space (GDD 5D)');
  }
  return { refusals, warnings };
}

/** Every tile to the room it belongs to; two rooms on one tile is a refusal. */
function mapTilesToRooms(ship: ShipDefinition, refusals: string[]): Map<string, number> {
  const roomOfTile = new Map<string, number>();
  const seenIds = new Set<number>();
  for (const room of ship.rooms) {
    if (seenIds.has(room.id)) refusals.push(`room ${room.id} is listed twice`);
    seenIds.add(room.id);
    for (const tile of tilesBetween(room.from, room.to, ship.centering)) {
      const key = tileKey(tile);
      const other = roomOfTile.get(key);
      if (other !== undefined && other !== room.id) refusals.push(`rooms ${other} and ${room.id} overlap at tile ${key}`);
      roomOfTile.set(key, room.id);
    }
  }
  return roomOfTile;
}

/** A system sits on a tile of a room, once, and its wall (if any) is a real wall of that room. */
function checkSystems(ship: ShipDefinition, roomOfTile: Map<string, number>, refusals: string[]): void {
  const seenKeys = new Set<string>();
  const seenTiles = new Map<string, string>();
  for (const system of ship.systems) {
    const key = systemKey(system);
    if (seenKeys.has(key)) refusals.push(`system ${key} is listed twice; give the second one a label (GDD 5J)`);
    seenKeys.add(key);

    const room = roomOfTile.get(tileKey(system.tile));
    if (room === undefined) {
      refusals.push(`system ${key} is on tile ${tileKey(system.tile)}, which is in no room`);
      continue;
    }
    const onSameTile = seenTiles.get(tileKey(system.tile));
    if (onSameTile) refusals.push(`systems ${onSameTile} and ${key} share tile ${tileKey(system.tile)}; one tile per system (art rules 2026-10-26)`);
    seenTiles.set(tileKey(system.tile), key);

    if (system.wall && !isWall(system.tile, system.wall, room, ship, roomOfTile)) {
      refusals.push(`system ${key} sits against the ${system.wall} wall of tile ${tileKey(system.tile)}, but that side is open floor of room ${room}`);
    }
  }
}

/** A door sits on a tile of a room, in a wall of that room. The far side may be another room or space. */
function checkDoors(ship: ShipDefinition, roomOfTile: Map<string, number>, refusals: string[]): void {
  const seenIds = new Set<number>();
  for (const door of ship.doors) {
    if (seenIds.has(door.id)) refusals.push(`door ${door.id} is listed twice`);
    seenIds.add(door.id);
    const room = roomOfTile.get(tileKey(door.tile));
    if (room === undefined) {
      refusals.push(`door ${door.id} is on tile ${tileKey(door.tile)}, which is in no room`);
      continue;
    }
    if (!isWall(door.tile, door.facing, room, ship, roomOfTile)) {
      refusals.push(`door ${door.id} faces ${door.facing} from tile ${tileKey(door.tile)}, but that side is open floor of room ${room}`);
    }
  }
}

/**
 * Weapons sit on hull mounts. When weapon systems claim mounts (a ship with Weapons A and B), every claimed
 * mount exists, no two systems claim one, and every mounted weapon's mount belongs to some weapon system.
 */
function checkWeapons(ship: ShipDefinition, refusals: string[]): void {
  const systemOfMount = new Map<number, string>();
  for (const system of ship.systems) {
    for (const mount of system.mounts ?? []) {
      if (mount < 1 || mount > ship.mountCount) refusals.push(`system ${systemKey(system)} claims mount ${mount}, but the hull has ${ship.mountCount} mounts`);
      const other = systemOfMount.get(mount);
      if (other) refusals.push(`systems ${other} and ${systemKey(system)} both claim mount ${mount}`);
      systemOfMount.set(mount, systemKey(system));
    }
  }
  for (const weapon of ship.weapons) {
    if (weapon.mount === undefined) continue;
    if (weapon.mount < 1 || weapon.mount > ship.mountCount) {
      refusals.push(`weapon ${weapon.name} is on mount ${weapon.mount}, but the hull has ${ship.mountCount} mounts`);
    } else if (systemOfMount.size > 0 && !systemOfMount.has(weapon.mount)) {
      refusals.push(`weapon ${weapon.name} is on mount ${weapon.mount}, which no weapon system claims`);
    }
  }
}

/**
 * Conduits (GDD 5H): each tile is in a room; two neighbours join only where each runs toward the other. From the
 * power core's tile, every conduit tile the power can reach is live. A conduit tile the power can't reach, and
 * that has no system on it, reaches neither power nor a system: a warning, not a refusal.
 */
function checkConduits(ship: ShipDefinition, roomOfTile: Map<string, number>, refusals: string[], warnings: string[]): void {
  if (ship.conduits.length === 0) return;
  const byTile = new Map<string, ConduitTile>();
  for (const conduit of ship.conduits) {
    const key = tileKey(conduit.tile);
    if (byTile.has(key)) refusals.push(`conduit tile ${key} is listed twice`);
    byTile.set(key, conduit);
    if (!roomOfTile.has(key)) refusals.push(`conduit tile ${key} is in no room`);
  }

  const core = ship.systems.find((system) => system.name === POWER_CORE_SYSTEM);
  if (!core) {
    warnings.push(`the ship has conduits but no ${POWER_CORE_SYSTEM} to feed them`);
    return;
  }
  const live = reachableConduits(core.tile, byTile, ship);
  const systemTiles = new Set(ship.systems.map((system) => tileKey(system.tile)));
  for (const conduit of ship.conduits) {
    const key = tileKey(conduit.tile);
    if (!live.has(key) && !systemTiles.has(key)) {
      warnings.push(`conduit tile ${key} reaches neither a power source nor a system`);
    }
  }
  for (const system of ship.systems) {
    const key = tileKey(system.tile);
    if (system.name !== POWER_CORE_SYSTEM && byTile.has(key) && !live.has(key)) {
      warnings.push(`system ${systemKey(system)} has a conduit on its tile, but power can't reach it`);
    }
  }
}

/** The conduit tiles power reaches from the core's tile, walking only joins where both tiles run toward each other. */
function reachableConduits(start: Tile, byTile: Map<string, ConduitTile>, ship: ShipDefinition): Set<string> {
  const live = new Set<string>();
  const toVisit: Tile[] = [start];
  while (toVisit.length > 0) {
    const tile = toVisit.pop()!;
    const key = tileKey(tile);
    const conduit = byTile.get(key);
    if (!conduit || live.has(key)) continue;
    live.add(key);
    for (const direction of conduit.runs) {
      const next = neighbourTile(tile, direction, ship.centering);
      const nextConduit = byTile.get(tileKey(next));
      if (nextConduit && nextConduit.runs.includes(oppositeDirection(direction))) toVisit.push(next);
    }
  }
  return live;
}

/** True when the side of this tile in that direction is a wall: the tile across it is not in the same room. */
function isWall(tile: Tile, direction: Direction, room: number, ship: ShipDefinition, roomOfTile: Map<string, number>): boolean {
  const across = neighbourTile(tile, direction, ship.centering);
  return roomOfTile.get(tileKey(across)) !== room;
}
