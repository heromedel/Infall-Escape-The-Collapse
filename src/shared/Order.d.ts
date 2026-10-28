/**
 * What a player, or the enemy AI, may ask of the simulation. Orders are the only way state changes from outside:
 * the host's own window and a LAN client send the same orders (GDD 4B: the host owns everything). Types only,
 * shared by the simulation and the window.
 */

export type Order =
  | { kind: 'SetPower'; shipId: number; systemKey: string; bars: number }
  /**
   * Aim at one tile of an enemy ship (GDD 3L: a tile, not a whole room, since our rooms hold several systems).
   * Autofire keeps the target and fires every time the weapon charges; otherwise it fires one volley and lets go.
   */
  | { kind: 'TargetWeapon'; shipId: number; mount: number; targetShipId: number; targetTile: { x: number; y: number }; autofire: boolean }
  | { kind: 'ClearTarget'; shipId: number; mount: number }
  /** Power a weapon: its cost in bars moves from the reactor into its weapon system (the genre's slot click). */
  | { kind: 'PowerWeapon'; shipId: number; mount: number }
  /** Depower a weapon: its bars go back to the reactor. */
  | { kind: 'DepowerWeapon'; shipId: number; mount: number }
  /** Move a weapon to another slot; slot order decides which weapon goes offline first when the system is damaged. */
  | { kind: 'ReorderWeapons'; shipId: number; mount: number; slot: number }
  | { kind: 'MoveCrew'; shipId: number; crewId: number; tile: { x: number; y: number } }
  | { kind: 'ToggleDoor'; shipId: number; doorId: number };
