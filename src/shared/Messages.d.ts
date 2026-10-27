/**
 * What travels between the host and a client (GDD 4B: the host owns everything; clients send orders and get the
 * picture back). The window and, later, a LAN client use exactly these. Types only.
 */

import type { ShipPicture } from './ShipPicture';
import type { Snapshot } from './Snapshot';
import type { Order } from './Order';

export type ClientToHost =
  | { kind: 'Order'; order: Order }
  | { kind: 'Pause' }
  | { kind: 'Unpause' };

/** How the window lays the battle out: settings that change nothing in the simulation. */
export interface Look {
  /** Battle GUI: 'floating' (the genre's placement over the battle) or 'card' (one panel bottom-left). */
  battleGui: 'floating' | 'card';
  /** The fire mode weapons get without Ctrl. */
  autofire: boolean;
  /** Draw a line from the ship to each target room as well as the room mark. */
  targetLines: boolean;
}

export type HostToClient =
  /** Sent once when a battle starts: everything the window needs to draw each ship (the static parts). */
  | { kind: 'BattleStarted'; pictures: Record<number, ShipPicture>; playerShipIds: number[]; formation: { depth: number; inverted: boolean }; look: Look }
  /** A look setting changed mid-battle (the debug console for now, the settings screen later). */
  | { kind: 'Look'; look: Look }
  /** Sent every tick while a battle runs, and once more when it ends. */
  | { kind: 'Snapshot'; snapshot: Snapshot }
  | { kind: 'Paused'; paused: boolean; by: string }
  | { kind: 'BattleEnded'; winner: string; reason: string };
