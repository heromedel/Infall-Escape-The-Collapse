/**
 * The bridge between the window and the host. The window gets exactly these functions and nothing else of Node
 * or Electron, so it stays a viewer (coding rule 3).
 */

import { contextBridge, ipcRenderer } from 'electron';

contextBridge.exposeInMainWorld('host', {
  shipNames: () => ipcRenderer.invoke('ship-names'),
  shipPicture: (name: string, side: 'player' | 'enemy') => ipcRenderer.invoke('ship-picture', name, side),
  debug: (line: string) => ipcRenderer.invoke('debug', line),
  /** The settings in play, for the settings screen; changes go through debug commands. */
  settings: () => ipcRenderer.invoke('settings'),
  exit: () => ipcRenderer.send('exit'),
  /** The client side of the host connection: messages from the host, and messages to it. */
  onHostMessage: (listener: (message: unknown) => void) => { ipcRenderer.on('host-message', (_event, message) => listener(message)); },
  sendToHost: (message: unknown) => ipcRenderer.send('client-message', message),
});
