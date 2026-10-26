/**
 * Builds the picture the window draws a ship from (src/shared/ShipPicture.d.ts) out of a loaded ship. Signed
 * tile coordinates become a plain grid, rooms become floor tiles and wall segments, doors become rectangles,
 * and the hull art is read from the ship's folder and sent whole, so the window needs no file access.
 *
 * With no art, the picture still has everything GDD 5K asks for: walls, floor tiles, system symbols, doors.
 */

import * as fs from 'node:fs';
import * as path from 'node:path';
import type { PictureArt, PictureCrew, PictureDoor, PictureSegment, PictureTile, ShipPicture } from '../shared/ShipPicture';
import { ShipDefinition, systemKey } from '../simulation/content/ShipDefinition';
import { DIRECTIONS, Direction, gridIndex, neighbourTile, Tile, tileKey, tilesBetween } from '../simulation/content/Tile';
import { placeholderShapeOf, enemyPowerColourOf } from '../simulation/content/Palette';
import { ContentLibrary, ShipEntry } from './ContentLibrary';
import { Settings } from './Settings';

/** The genre's room scale: 35 pixels a tile, the same the art tools use (GDD 3D). */
export const TILE_SIZE = 35;

const DOOR_LENGTH = 20;
const DOOR_THICKNESS = 6;

export type Side = 'player' | 'enemy';

export function shipPictureOf(entry: ShipEntry, side: Side, content: ContentLibrary, settings: Settings): ShipPicture {
  const ship = entry.definition;
  const powerColour = side === 'player' ? settings.playerPowerColour : enemyPowerColourOf(ship.race, ship.powerColour);
  const grid = new Grid(ship);
  const roomOfTile = grid.roomOfTile();

  return {
    name: ship.name,
    race: ship.race,
    tileSize: TILE_SIZE,
    columns: grid.columns,
    rows: grid.rows,
    powerColour,
    floorTiles: grid.allRoomTiles().map((tile) => grid.at(tile)),
    rooms: ship.rooms.map((room) => {
      const topLeft = grid.at({ x: Math.min(room.from.x, room.to.x), y: Math.min(room.from.y, room.to.y) });
      const bottomRight = grid.at({ x: Math.max(room.from.x, room.to.x), y: Math.max(room.from.y, room.to.y) });
      return { id: room.id, column: topLeft.column, row: topLeft.row, width: bottomRight.column - topLeft.column + 1, height: bottomRight.row - topLeft.row + 1 };
    }),
    walls: wallSegments(grid, roomOfTile),
    doors: ship.doors.map((door): PictureDoor => {
      const { column, row } = grid.at(door.tile);
      const airlock = !roomOfTile.has(tileKey(neighbourTile(door.tile, door.facing, ship.centering)));
      return { id: door.id, ...doorRectangle(column, row, door.facing), airlock };
    }),
    systems: ship.systems.map((system) => ({
      key: systemKey(system), name: system.name, level: system.level, ...grid.at(system.tile), wall: system.wall,
      symbolSvg: content.system(system.name)?.symbolSvg,
    })),
    conduits: ship.conduits.map((conduit) => ({ ...grid.at(conduit.tile), runs: conduit.runs })),
    crew: placeholderCrew(ship, grid, powerColour),
    hullArt: readHullArt(ship, entry.folder),
  };
}

/** Signed ship tiles laid onto a plain grid counted from the ship's top-left tile. */
class Grid {
  readonly lowestX: number;
  readonly lowestY: number;
  readonly columns: number;
  readonly rows: number;

  constructor(private readonly ship: ShipDefinition) {
    const tiles = this.allRoomTiles();
    this.lowestX = Math.min(...tiles.map((tile) => tile.x));
    this.lowestY = Math.min(...tiles.map((tile) => tile.y));
    const highestX = Math.max(...tiles.map((tile) => tile.x));
    const highestY = Math.max(...tiles.map((tile) => tile.y));
    this.columns = gridIndex(highestX, this.lowestX, ship.centering.x) + 1;
    this.rows = gridIndex(highestY, this.lowestY, ship.centering.y) + 1;
  }

  at(tile: Tile): PictureTile {
    return {
      column: gridIndex(tile.x, this.lowestX, this.ship.centering.x),
      row: gridIndex(tile.y, this.lowestY, this.ship.centering.y),
    };
  }

  allRoomTiles(): Tile[] {
    return this.ship.rooms.flatMap((room) => tilesBetween(room.from, room.to, this.ship.centering));
  }

  roomOfTile(): Map<string, number> {
    const map = new Map<string, number>();
    for (const room of this.ship.rooms) {
      for (const tile of tilesBetween(room.from, room.to, this.ship.centering)) map.set(tileKey(tile), room.id);
    }
    return map;
  }

  neighbour(tile: Tile, direction: Direction): Tile {
    return neighbourTile(tile, direction, this.ship.centering);
  }
}

/** One wall segment on each side of a room tile that doesn't face the same room, drawn once per side. */
function wallSegments(grid: Grid, roomOfTile: Map<string, number>): PictureSegment[] {
  const segments: PictureSegment[] = [];
  for (const tile of grid.allRoomTiles()) {
    const room = roomOfTile.get(tileKey(tile));
    const { column, row } = grid.at(tile);
    const left = column * TILE_SIZE;
    const top = row * TILE_SIZE;
    const right = left + TILE_SIZE;
    const bottom = top + TILE_SIZE;
    for (const direction of DIRECTIONS) {
      const across = roomOfTile.get(tileKey(grid.neighbour(tile, direction)));
      if (across === room) continue;
      // A wall between two rooms is drawn by both; drawing it once from the lower room id keeps it single.
      if (across !== undefined && across < room!) continue;
      switch (direction) {
        case 'North': segments.push({ x1: left, y1: top, x2: right, y2: top }); break;
        case 'South': segments.push({ x1: left, y1: bottom, x2: right, y2: bottom }); break;
        case 'West': segments.push({ x1: left, y1: top, x2: left, y2: bottom }); break;
        case 'East': segments.push({ x1: right, y1: top, x2: right, y2: bottom }); break;
      }
    }
  }
  return segments;
}

function doorRectangle(column: number, row: number, facing: Direction): { x: number; y: number; width: number; height: number } {
  const centreX = column * TILE_SIZE + TILE_SIZE / 2;
  const centreY = row * TILE_SIZE + TILE_SIZE / 2;
  const half = TILE_SIZE / 2;
  switch (facing) {
    case 'North': return { x: centreX - DOOR_LENGTH / 2, y: centreY - half - DOOR_THICKNESS / 2, width: DOOR_LENGTH, height: DOOR_THICKNESS };
    case 'South': return { x: centreX - DOOR_LENGTH / 2, y: centreY + half - DOOR_THICKNESS / 2, width: DOOR_LENGTH, height: DOOR_THICKNESS };
    case 'West': return { x: centreX - half - DOOR_THICKNESS / 2, y: centreY - DOOR_LENGTH / 2, width: DOOR_THICKNESS, height: DOOR_LENGTH };
    case 'East': return { x: centreX + half - DOOR_THICKNESS / 2, y: centreY - DOOR_LENGTH / 2, width: DOOR_THICKNESS, height: DOOR_LENGTH };
  }
}

/**
 * Starting crew stand on their systems' tiles, one each, in file order, then on any free room tile. Where crew
 * really start is the simulation's business (step 4); this only gives the picture someone to draw.
 */
function placeholderCrew(ship: ShipDefinition, grid: Grid, colour: string): PictureCrew[] {
  const standingSpots = [...ship.systems.map((system) => system.tile), ...grid.allRoomTiles()];
  const taken = new Set<string>();
  const crew: PictureCrew[] = [];
  for (const group of ship.crew) {
    for (let count = 0; count < group.count; count++) {
      const spot = standingSpots.find((tile) => !taken.has(tileKey(tile)));
      if (!spot) break;
      taken.add(tileKey(spot));
      crew.push({ race: group.race, shape: placeholderShapeOf(group.race), colour, ...grid.at(spot) });
    }
  }
  return crew;
}

/** The hull art from the ship's folder, or nothing when the file isn't there (GDD 5K). */
function readHullArt(ship: ShipDefinition, folder: string): PictureArt | undefined {
  if (!ship.art.hull) return undefined;
  const file = path.join(folder, ship.art.hull);
  if (!fs.existsSync(file)) return undefined;
  const gridX = ship.art.offset.x;
  const gridY = ship.art.offset.y;
  if (file.toLowerCase().endsWith('.svg')) {
    const text = fs.readFileSync(file, 'utf8');
    const size = svgSize(text);
    return { kind: 'svg', content: text, width: size.width, height: size.height, gridX, gridY };
  }
  const bytes = fs.readFileSync(file);
  const size = pngSize(bytes);
  return { kind: 'png', content: `data:image/png;base64,${bytes.toString('base64')}`, width: size.width, height: size.height, gridX, gridY };
}

function svgSize(text: string): { width: number; height: number } {
  const viewBox = /viewBox="\s*[-\d.]+\s+[-\d.]+\s+([\d.]+)\s+([\d.]+)\s*"/.exec(text);
  if (viewBox) return { width: Number(viewBox[1]), height: Number(viewBox[2]) };
  const width = /\swidth="([\d.]+)/.exec(text);
  const height = /\sheight="([\d.]+)/.exec(text);
  return { width: Number(width?.[1] ?? 0), height: Number(height?.[1] ?? 0) };
}

/** A PNG's size sits in its header: width at byte 16, height at byte 20, both big-endian. */
function pngSize(bytes: Buffer): { width: number; height: number } {
  return { width: bytes.readUInt32BE(16), height: bytes.readUInt32BE(20) };
}
