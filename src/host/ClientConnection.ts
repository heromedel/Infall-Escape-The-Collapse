/**
 * One connected client: the host sends it messages and hears its messages. The window's connection runs over
 * Electron's bridge; a LAN connection comes later on the same shape, so the host never knows which it has.
 */

import type { ClientToHost, HostToClient } from '../shared/Messages';

export interface ClientConnection {
  /** Who this is, for the log and for pause control (GDD 4H). */
  readonly name: string;
  send(message: HostToClient): void;
  /** The host registers one listener for everything the client says. */
  onMessage(listener: (message: ClientToHost) => void): void;
}
