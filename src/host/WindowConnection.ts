/**
 * The host's own window as a client, over Electron's bridge (src/host/preload.ts). Messages go out on the
 * "host-message" channel and come back on "client-message"; nothing else crosses.
 */

import { BrowserWindow, ipcMain } from 'electron';
import type { ClientToHost, HostToClient } from '../shared/Messages';
import { ClientConnection } from './ClientConnection';

export class WindowConnection implements ClientConnection {
  readonly name = 'the host\'s window';

  constructor(private readonly window: BrowserWindow) {}

  send(message: HostToClient): void {
    if (!this.window.isDestroyed()) this.window.webContents.send('host-message', message);
  }

  onMessage(listener: (message: ClientToHost) => void): void {
    ipcMain.on('client-message', (_event, message: ClientToHost) => listener(message));
  }
}
