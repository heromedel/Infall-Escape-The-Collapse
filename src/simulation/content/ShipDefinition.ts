/**
 * Everything a ship file says, after reading and checking (GDD 5F to 5L). Pure data: nothing here moves or
 * fights. The simulation builds a live ship from one of these; the window draws one from the live ship.
 */

import { Centering, ConduitTile, Direction, Tile } from './Tile';

export interface Room {
  id: number;
  /** Two corner tiles; the room is the rectangle between them (GDD 5G). */
  from: Tile;
  to: Tile;
  note?: string;
}

/** A system placed on a tile, optionally against a wall with console art (GDD 5H). */
export interface SystemPlacement {
  name: string;
  /** Tells two systems of the same name apart, e.g. Weapons A and Weapons B (GDD 5J). */
  label?: string;
  tile: Tile;
  level: number;
  /** Self-powered ships (Mecha): the bars this system brings with it instead of drawing on a reactor. */
  selfPower?: number;
  /** Weapon systems on a ship with more than one: the hull mounts this system fires, e.g. "1,2,3". */
  mounts?: number[];
  /** The wall the console sits against. No wall: the system is drawn as an icon over the tile centre. */
  wall?: Direction;
  rotation?: string;
  mirror?: boolean;
  /** Console art by name, e.g. Tentauri.Pilot.Hood. Missing art falls back to the icon (GDD 5K). */
  art?: string;
}

export interface Door {
  id: number;
  tile: Tile;
  /** The wall the door is in. A door facing space is an airlock (GDD 5D, ship-design-process). */
  facing: Direction;
  note?: string;
}

/**
 * How the ship powers its systems. Reactor: a pool of bars, the genre default. AZC: Terran core with conduits,
 * unlimited while connected (GDD 7E). SelfPowered: no shared power, each system carries its own (Mecha).
 */
export interface PowerSource {
  kind: 'Reactor' | 'AZC' | 'SelfPowered';
  bars?: number;
  level?: number;
}

export interface ShipArt {
  hull?: string;
  floor?: string;
  /** Where the hull art sits relative to the tile grid, in tiles (GDD 5J). */
  offset: Tile;
}

export interface StartingWeapon {
  name: string;
  /** Hull mount number; positions come with the hull art (ship-design-process). */
  mount?: number;
}

/** One line of the starting crew list, e.g. 3 Terrans. */
export interface StartingCrew {
  race: string;
  count: number;
}

export interface ShipDefinition {
  name: string;
  race: string;
  /** The base ship's name when this definition came from a loadout file; otherwise the same as `name`. */
  baseShip: string;
  centering: Centering;
  hullPoints: number;
  power: PowerSource;
  art: ShipArt;
  mountCount: number;
  rooms: Room[];
  systems: SystemPlacement[];
  doors: Door[];
  conduits: ConduitTile[];
  weapons: StartingWeapon[];
  crew: StartingCrew[];
  /** Suit types carried for an EVA or EVB Dock, by name. */
  suits: string[];
}

/** The key a loadout patches a system by: its name plus its label when it has one (GDD 5J). */
export function systemKey(system: { name: string; label?: string }): string {
  return system.label ? `${system.name} ${system.label}` : system.name;
}
