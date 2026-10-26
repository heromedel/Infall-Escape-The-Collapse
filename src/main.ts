/**
 * Infall: Escape The Collapse. The flow of the whole program, top to bottom (standards, principle 3).
 *
 * Where things live: the simulation (src/simulation/) is the game and imports nothing from Electron or the window.
 * The host (src/host/) owns the game, the files, the logs and, later, the LAN. The window (src/window/) only draws
 * what the host sends it and sends back what the player did; it is a client of the host like any LAN client.
 */

import { app, BrowserWindow, ipcMain } from 'electron';
import * as path from 'node:path';
import { Log } from './host/Log';
import { ContentLibrary } from './host/ContentLibrary';
import { DebugConsole } from './host/DebugConsole';
import { shipPictureOf, Side } from './host/ShipPicture';
import { Settings } from './host/Settings';
import { parsePowerColour, POWER_COLOUR_BY_NAME } from './simulation/content/Palette';

const projectFolder = path.join(__dirname, '..');
const contentFolder = path.join(projectFolder, 'content');
const logsFolder = path.join(projectFolder, 'logs');

app.whenReady().then(() => {
  const log = Log.open(logsFolder);
  const content = ContentLibrary.load(contentFolder, log);
  const settings = new Settings();
  const debug = new DebugConsole(log);
  registerDebugCommands(debug, content, settings);

  const window = openWindow();
  answerWindowRequests(window, content, settings, debug);
});

app.on('window-all-closed', () => app.quit());

function openWindow(): BrowserWindow {
  const window = new BrowserWindow({
    width: 1280,
    height: 720,
    title: 'Infall: Escape The Collapse',
    webPreferences: { preload: path.join(__dirname, 'host', 'preload.js') },
  });
  window.loadFile(path.join(__dirname, 'window', 'index.html'));
  return window;
}

/** What the window may ask the host for. Later this becomes the client connection the LAN also uses. */
function answerWindowRequests(window: BrowserWindow, content: ContentLibrary, settings: Settings, debug: DebugConsole): void {
  ipcMain.handle('ship-names', () => content.shipNames());
  ipcMain.handle('ship-picture', (_event, name: string, side: Side) => shipPictureOf(content.ship(name), side, content, settings));
  ipcMain.handle('debug', (_event, line: string) => debug.run(line));
}

function registerDebugCommands(debug: DebugConsole, content: ContentLibrary, settings: Settings): void {
  debug.register({
    name: 'ships',
    description: 'List the loaded ships.',
    run: () => content.shipNames().join('\n'),
  });
  debug.register({
    name: 'powercolor',
    description: `Set the player power colour (GDD 14D): a race or colour name (${Object.keys(POWER_COLOUR_BY_NAME).join(', ')}) or a hex value.`,
    run: ([text]) => {
      const colour = text ? parsePowerColour(text) : undefined;
      if (!colour) return `powercolor needs a name (${Object.keys(POWER_COLOUR_BY_NAME).join(', ')}) or a hex value like #66FF66.`;
      settings.playerPowerColour = colour;
      return `Player power colour is now ${colour}.`;
    },
  });
}
