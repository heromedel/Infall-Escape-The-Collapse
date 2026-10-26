/**
 * The bridge between the window and the host. The window gets exactly these functions and nothing else of Node
 * or Electron, so it stays a viewer (coding rule 3).
 */

import { contextBridge, ipcRenderer } from 'electron';

contextBridge.exposeInMainWorld('host', {
  shipNames: () => ipcRenderer.invoke('ship-names'),
  shipPicture: (name: string, side: 'player' | 'enemy') => ipcRenderer.invoke('ship-picture', name, side),
  debug: (line: string) => ipcRenderer.invoke('debug', line),
});
