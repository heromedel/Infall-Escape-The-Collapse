/**
 * What a player, or the enemy AI, may ask of the simulation. Orders are the only way state changes from outside:
 * the host's own window and a LAN client send the same orders (GDD 4B: the host owns everything). Types only,
 * shared by the simulation and the window.
 */

export type Order =
  | { kind: 'SetPower'; shipId: number; systemKey: string; bars: number }
  | { kind: 'TargetWeapon'; shipId: number; mount: number; targetShipId: number; targetRoomId: number }
  | { kind: 'ClearTarget'; shipId: number; mount: number }
  | { kind: 'MoveCrew'; shipId: number; crewId: number; tile: { x: number; y: number } }
  | { kind: 'ToggleDoor'; shipId: number; doorId: number };
