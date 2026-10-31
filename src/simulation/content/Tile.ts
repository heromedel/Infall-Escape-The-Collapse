/**
 * Tiles, directions and the ship's centering, as GDD 5G describes them.
 *
 * Every coordinate in a ship file counts from the ship's centre. Under Tile centering an axis has a tile 0 and
 * counts -1, 0, 1. Under Point centering the centre is a grid point between tiles, so there is no 0 and the axis
 * counts -2, -1, 1, 2. A ship can be centred differently on each axis (GDD 5G, e.g. 4 wide and 13 long).
 */

export interface Tile {
  x: number;
  y: number;
}

export type Direction = 'North' | 'South' | 'East' | 'West';

export const DIRECTIONS: readonly Direction[] = ['North', 'South', 'East', 'West'];

export type CenteringMode = 'Tile' | 'Point';

export interface Centering {
  x: CenteringMode;
  y: CenteringMode;
}

/** A conduit tile and the directions it runs (GDD 5H). `removed` only appears in a loadout patch (GDD 5J). */
export interface ConduitTile {
  tile: Tile;
  runs: Direction[];
  removed?: boolean;
}

const DIRECTION_LETTERS: Record<string, Direction> = { N: 'North', S: 'South', E: 'East', W: 'West' };

/** "x,y" to a tile. */
export function parseTile(text: string, where: string): Tile {
  const parts = text.split(',').map((part) => part.trim());
  const x = Number(parts[0]);
  const y = Number(parts[1]);
  if (parts.length !== 2 || !Number.isInteger(x) || !Number.isInteger(y)) {
    throw new Error(`${where}: "${text}" is not a tile; expected "x,y" with whole numbers`);
  }
  return { x, y };
}

/** A tile as "x,y", used as a map key. */
export function tileKey(tile: Tile): string {
  return `${tile.x},${tile.y}`;
}

export function sameTile(a: Tile, b: Tile): boolean {
  return a.x === b.x && a.y === b.y;
}

export function oppositeDirection(direction: Direction): Direction {
  switch (direction) {
    case 'North': return 'South';
    case 'South': return 'North';
    case 'East': return 'West';
    case 'West': return 'East';
  }
}

/** The next coordinate along one axis, skipping 0 under Point centering (GDD 5G). */
function stepCoordinate(value: number, step: number, mode: CenteringMode): number {
  const next = value + step;
  return mode === 'Point' && next === 0 ? next + step : next;
}

/** The tile next to this one in a direction. North is the bow, so y grows toward the stern. */
export function neighbourTile(tile: Tile, direction: Direction, centering: Centering): Tile {
  switch (direction) {
    case 'North': return { x: tile.x, y: stepCoordinate(tile.y, -1, centering.y) };
    case 'South': return { x: tile.x, y: stepCoordinate(tile.y, 1, centering.y) };
    case 'East': return { x: stepCoordinate(tile.x, 1, centering.x), y: tile.y };
    case 'West': return { x: stepCoordinate(tile.x, -1, centering.x), y: tile.y };
  }
}

/** How many tiles a coordinate is from the lowest coordinate, so signed tiles map onto a plain grid from 0. */
export function gridIndex(value: number, lowest: number, mode: CenteringMode): number {
  const skipsZero = mode === 'Point' && lowest < 0 && value > 0;
  return value - lowest - (skipsZero ? 1 : 0);
}

/** Every tile in the rectangle between two corner tiles, inclusive, honouring the centering. */
export function tilesBetween(from: Tile, to: Tile, centering: Centering): Tile[] {
  const tiles: Tile[] = [];
  for (let y = Math.min(from.y, to.y); y <= Math.max(from.y, to.y); y++) {
    if (centering.y === 'Point' && y === 0) continue;
    for (let x = Math.min(from.x, to.x); x <= Math.max(from.x, to.x); x++) {
      if (centering.x === 'Point' && x === 0) continue;
      tiles.push({ x, y });
    }
  }
  return tiles;
}

/**
 * The conduit list as written in a ship file (GDD 5H): "(x,y,N,S) (x,y) (x,y,Remove)".
 * A tile with no directions is a full intersection. "Remove" is only meaningful in a loadout (GDD 5J).
 */
export function parseConduitList(text: string, where: string): ConduitTile[] {
  const entries = text.match(/\([^)]*\)/g) ?? [];
  const leftovers = text.replace(/\([^)]*\)/g, '').trim();
  if (leftovers.length > 0) {
    throw new Error(`${where}: conduit text "${leftovers}" is outside any (x,y,...) entry`);
  }
  return entries.map((entry) => {
    const parts = entry.slice(1, -1).split(',').map((part) => part.trim());
    const tile = parseTile(`${parts[0]},${parts[1]}`, `${where} conduit ${entry}`);
    const rest = parts.slice(2);
    if (rest.length === 1 && rest[0].toLowerCase() === 'remove') {
      return { tile, runs: [], removed: true };
    }
    const runs = rest.length === 0 ? [...DIRECTIONS] : rest.map((letter) => {
      const direction = DIRECTION_LETTERS[letter.toUpperCase()];
      if (!direction) throw new Error(`${where}: conduit ${entry} has an unknown direction "${letter}"`);
      return direction;
    });
    return { tile, runs };
  });
}

/** Writes a conduit list back out in the ship-file form, for logs and saves. */
export function formatConduitList(conduits: ConduitTile[]): string {
  return conduits
    .map((conduit) => {
      if (conduit.removed) return `(${conduit.tile.x},${conduit.tile.y},Remove)`;
      const letters = conduit.runs.map((direction) => direction[0]).join(',');
      return conduit.runs.length === 4 ? `(${conduit.tile.x},${conduit.tile.y})` : `(${conduit.tile.x},${conduit.tile.y},${letters})`;
    })
    .join(' ');
}
