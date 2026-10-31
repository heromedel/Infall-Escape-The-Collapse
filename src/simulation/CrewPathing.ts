/**
 * Finds a crew member's walk from one tile to another on their own ship: through room floors and doors, never
 * through a wall. Crew open their own ship's doors as they go, as in the genre, so a closed door is not a wall.
 */

import { DIRECTIONS, Tile, neighbourTile, sameTile, tileKey } from './content/Tile';
import { Ship } from './Ship';

/** The tiles to step through after `from`, ending on `to`; empty when already there or unreachable. */
export function findPath(ship: Ship, from: Tile, to: Tile): Tile[] {
  if (sameTile(from, to)) return [];
  const cameFrom = new Map<string, Tile>();
  const visited = new Set<string>([tileKey(from)]);
  const queue: Tile[] = [from];
  while (queue.length > 0) {
    const tile = queue.shift()!;
    for (const direction of DIRECTIONS) {
      const next = neighbourTile(tile, direction, ship.definition.centering);
      const key = tileKey(next);
      if (visited.has(key) || !canStep(ship, tile, next)) continue;
      visited.add(key);
      cameFrom.set(key, tile);
      if (sameTile(next, to)) return walkBack(cameFrom, from, to);
      queue.push(next);
    }
  }
  return [];
}

/** A step is allowed between two neighbouring floor tiles of one room, or through a door between rooms. */
function canStep(ship: Ship, from: Tile, to: Tile): boolean {
  const fromRoom = ship.roomOfTile(from);
  const toRoom = ship.roomOfTile(to);
  if (!fromRoom || !toRoom) return false;
  return fromRoom === toRoom || ship.doorBetween(from, to) !== undefined;
}

function walkBack(cameFrom: Map<string, Tile>, from: Tile, to: Tile): Tile[] {
  const path: Tile[] = [];
  let tile = to;
  while (!sameTile(tile, from)) {
    path.unshift(tile);
    tile = cameFrom.get(tileKey(tile))!;
  }
  return path;
}
