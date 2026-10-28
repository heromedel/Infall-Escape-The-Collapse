/**
 * What the host sends out every tick: the live state of a battle, as a picture, with nothing the window shouldn't
 * know. The window draws it and nothing else; a LAN client gets the same (GDD 4B). Types only.
 */

export interface Snapshot {
  tick: number;
  seconds: number;
  /** The off-screen distance between the squads (GDD 3Q). */
  distanceGm: number;
  squads: SnapshotSquad[];
  shots: SnapshotShot[];
  /** Set once the battle is decided. */
  result?: { winner: 'player' | 'enemy' | 'draw'; reason: string };
}

export interface SnapshotSquad {
  side: 'player' | 'enemy';
  name: string;
  mawjig: number;
  ships: SnapshotShip[];
}

export interface SnapshotShip {
  id: number;
  name: string;
  race: string;
  side: 'player' | 'enemy';
  hullPoints: number;
  hullMax: number;
  shieldLayers: number;
  shieldLayersMax: number;
  evasionPercent: number;
  powerKind: string;
  barsTotal: number;
  barsInUse: number;
  isGone: boolean;
  rooms: { id: number; oxygen: number }[];
  systems: SnapshotSystem[];
  doors: { id: number; open: boolean }[];
  crew: SnapshotCrew[];
  weapons: SnapshotWeapon[];
}

export interface SnapshotSystem {
  key: string;
  name: string;
  level: number;
  damage: number;
  bars: number;
  maxBars: number;
  isWorking: boolean;
  spored: boolean;
  mannedBy?: number;
}

export interface SnapshotCrew {
  id: number;
  name: string;
  race: string;
  health: number;
  /** Signed ship tile coordinates (GDD 5G). */
  x: number;
  y: number;
  walking: boolean;
  stunned: boolean;
}

export interface SnapshotWeapon {
  name: string;
  mount: number;
  /** Charge from 0 to 1. */
  charge: number;
  /** Live: the player powered it and its weapon system still has the bars for it. */
  powered: boolean;
  /** Bars it needs from its weapon system. */
  cost: number;
  /** The tile aimed at, in the target ship's signed coordinates (GDD 5G). */
  target?: { shipId: number; tile: { x: number; y: number } };
  /** The target stays after a volley (autofire) or is let go after one. */
  autofire: boolean;
}

export interface SnapshotShot {
  id: number;
  weaponName: string;
  type: string;
  fromShipId: number;
  toShipId: number;
  toTile: { x: number; y: number };
  /** Flight progress from 0 to 1. */
  progress: number;
}
