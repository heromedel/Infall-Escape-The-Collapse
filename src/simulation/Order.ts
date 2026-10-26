/**
 * What a player, or the enemy AI, may ask of the simulation. Orders are the only way state changes from outside:
 * the host's own window and a LAN client send the same orders (GDD 4B: the host owns everything).
 */

import { Tile } from './content/Tile';

export type Order =
  | { kind: 'SetPower'; shipId: number; systemKey: string; bars: number }
  | { kind: 'TargetWeapon'; shipId: number; mount: number; targetShipId: number; targetRoomId: number }
  | { kind: 'ClearTarget'; shipId: number; mount: number }
  | { kind: 'MoveCrew'; shipId: number; crewId: number; tile: Tile }
  | { kind: 'ToggleDoor'; shipId: number; doorId: number };
