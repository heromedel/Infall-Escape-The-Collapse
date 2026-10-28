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
import { Battle } from './host/Battle';
import { Host } from './host/Host';
import { WindowConnection } from './host/WindowConnection';
import { parsePowerColour, POWER_COLOUR_BY_NAME, POWER_COLOUR_BY_WORD } from './simulation/content/Palette';

const projectFolder = path.join(__dirname, '..');
const contentFolder = path.join(projectFolder, 'content');
const logsFolder = path.join(projectFolder, 'logs');

app.whenReady().then(() => {
  const log = Log.open(logsFolder);
  const content = ContentLibrary.load(contentFolder, log);
  const settings = new Settings();
  const host = new Host(log, settings);
  const debug = new DebugConsole(log);
  registerDebugCommands(debug, content, settings, log, host);

  const window = openWindow();
  host.connect(new WindowConnection(window));      // the host's own window is a client like any LAN client
  answerWindowRequests(window, content, settings, debug, log);
});

app.on('window-all-closed', () => app.quit());

function openWindow(): BrowserWindow {
  const window = new BrowserWindow({
    width: 1280,
    height: 720,
    title: 'Infall: Escape The Collapse',
    autoHideMenuBar: true,   // the battle wants the whole window; Alt shows the menu
    webPreferences: { preload: path.join(__dirname, 'host', 'preload.js') },
  });
  window.loadFile(path.join(__dirname, 'window', 'index.html'));
  return window;
}

/** What the window may ask the host for outside a battle: the ship viewer and the debug console. */
function answerWindowRequests(window: BrowserWindow, content: ContentLibrary, settings: Settings, debug: DebugConsole, log: Log): void {
  ipcMain.handle('ship-names', () => content.shipNames());
  ipcMain.handle('ship-picture', (_event, name: string, side: Side) => shipPictureOf(content.ship(name), side, content, settings));
  ipcMain.handle('debug', (_event, line: string) => debug.run(line));
  ipcMain.handle('settings', () => ({ ...settings }));
  ipcMain.on('exit', () => { log.event('program.exit', { by: 'the title screen' }); app.quit(); });
}

function registerDebugCommands(debug: DebugConsole, content: ContentLibrary, settings: Settings, log: Log, host: Host): void {
  debug.register({
    name: 'ships',
    description: 'List the loaded ships.',
    run: () => content.shipNames().join('\n'),
  });
  debug.register({
    name: 'fight',
    description: 'Run a headless battle to its end and report: fight [seed] [player ship] [enemy ship]. Ship names with spaces go in quotes. Default: the Outrider against the Light Attack Frame.',
    run: (words) => {
      const seed = Number(words[0] ?? Date.now() % 100000) || 1;
      const names = words.slice(1).join(' ').match(/"([^"]+)"/g)?.map((quoted) => quoted.slice(1, -1)) ?? [];
      const battle = new Battle(content, log, settings, names[0] ?? 'SC-1 Outrider', names[1] ?? 'Light Attack Frame', seed);
      const result = battle.runToResult();
      const ships = battle.simulation.squads.flatMap((squad) => squad.ships.map((ship) => `${ship.name}: hull ${ship.hullPoints}/${ship.hullMax}, crew alive ${ship.crew.filter((member) => member.isAlive).length}/${ship.crew.length}`));
      const mawjig = battle.simulation.squads.map((squad) => `${squad.name} Mawjig left ${squad.mawjig}`);
      return [`Seed ${seed}: ${result.winner} wins after ${result.seconds} s (${result.reason}).`, ...ships, ...mawjig, 'The tick-by-tick story is in the log file.'].join('\n');
    },
  });
  debug.register({
    name: 'battle',
    description: 'Start a live battle in the window: battle [seed] ["player ships"] ["enemy ships"] [distance GM]. Each quoted list is ship names separated by commas, e.g. battle 7 "SC-1 Outrider,Terran Pirate Cutpurse" "Light Attack Frame,Light Attack Frame". Default: the Outrider against the Light Attack Frame at 400 GM.',
    run: (words) => {
      const seed = Number(words[0] ?? Date.now() % 100000) || 1;
      const rest = words.slice(1).join(' ');
      const lists = rest.match(/"([^"]+)"/g)?.map((quoted) => quoted.slice(1, -1).split(',').map((name) => name.trim()).filter(Boolean)) ?? [];
      const distance = Number(rest.replace(/"[^"]+"/g, '').trim()) || undefined;
      const battle = new Battle(content, log, settings, lists[0] ?? 'SC-1 Outrider', lists[1] ?? 'Light Attack Frame', seed, distance);
      host.startBattle(battle);
      const names = (index: number) => battle.simulation.squads[index].ships.map((ship) => ship.name).join(' + ');
      return `Battle started, seed ${seed}: ${names(0)} against ${names(1)} at ${battle.simulation.distanceGm} GM. Space pauses.`;
    },
  });
  debug.register({
    name: 'formation',
    description: 'Squad formation (GDD 3H, 3I): formation depth 0.7 | inverted on|off. Takes effect at the next battle.',
    run: ([what, value]) => {
      if (what === 'depth' && value !== undefined && !Number.isNaN(Number(value))) settings.formationDepth = Number(value);
      else if (what === 'inverted' && value !== undefined) settings.formationInverted = value === 'on';
      else if (what !== undefined) return 'formation depth <share of the tallest ship> | inverted on|off';
      return `Formation: curve depth ${settings.formationDepth}, ${settings.formationInverted ? 'inverted (centre forward)' : 'centre back'}.`;
    },
  });
  debug.register({
    name: 'gui',
    description: 'Battle GUI setting (GDD 1C, 3J): gui floating | card. The genre\'s floating placement or one card bottom-left; switches at once.',
    run: ([kind]) => {
      if (kind === 'floating' || kind === 'card') { settings.battleGui = kind; host.announceLook(); }
      else if (kind !== undefined) return 'gui floating | card';
      return `Battle GUI: ${settings.battleGui}.`;
    },
  });
  debug.register({
    name: 'autofire',
    description: 'Autofire setting (the genre\'s default fire mode): autofire off | on. Ctrl at the room click gives the opposite; V toggles it in the battle.',
    run: ([state]) => {
      if (state === 'on' || state === 'off') { settings.autofire = state === 'on'; host.announceLook(); }
      else if (state !== undefined) return 'autofire off | on';
      return `Autofire ${settings.autofire ? 'on: weapons keep their target' : 'off: weapons fire one volley and let go'}.`;
    },
  });
  debug.register({
    name: 'targetlines',
    description: 'Target Lines setting: targetlines off | on. A dashed line to each target room as well as the room mark.',
    run: ([state]) => {
      if (state === 'on' || state === 'off') { settings.targetLines = state === 'on'; host.announceLook(); }
      else if (state !== undefined) return 'targetlines off | on';
      return `Target lines ${settings.targetLines ? 'on' : 'off'}.`;
    },
  });
  debug.register({
    name: 'offset',
    description: 'Squad Offset setting (GDD 3R): offset 0.35. The player squad shifted sideways by this share of the wider squad; takes effect at the next battle.',
    run: ([value]) => {
      if (value !== undefined && !Number.isNaN(Number(value))) settings.squadOffset = Math.max(0, Math.min(1, Number(value)));
      else if (value !== undefined) return 'offset <0 to 1>';
      return `Squad offset ${settings.squadOffset}.`;
    },
  });
  debug.register({
    name: 'crossing',
    description: 'Shots Crossing Barrier setting (GDD 3R): crossing shown | hidden. The tiny dash of a shot in the strip; switches at once.',
    run: ([state]) => {
      if (state === 'shown' || state === 'hidden') { settings.shotsCrossingBarrier = state === 'shown'; host.announceLook(); }
      else if (state !== undefined) return 'crossing shown | hidden';
      return `Shots crossing the barrier: ${settings.shotsCrossingBarrier ? 'shown' : 'hidden'}.`;
    },
  });
  debug.register({
    name: 'autopause',
    description: 'Turn Mode auto pause (GDD 4I): autopause off | on [seconds].',
    run: ([state, seconds]) => {
      settings.autoPause = state === 'on';
      if (seconds) settings.autoPauseIntervalTicks = Math.max(1, Math.round(Number(seconds) * 20));
      return `Auto pause ${settings.autoPause ? `on, every ${settings.autoPauseIntervalTicks / 20} s` : 'off'}.`;
    },
  });
  debug.register({
    name: 'powercolor',
    description: `Set the player power colour (GDD 14D): a race (${Object.keys(POWER_COLOUR_BY_NAME).join(', ')}), a colour word (${Object.keys(POWER_COLOUR_BY_WORD).join(', ')}) or a hex value.`,
    run: (words) => {
      const colour = words.length > 0 ? parsePowerColour(words.join(' ')) : undefined;
      if (!colour) return `powercolor needs a race (${Object.keys(POWER_COLOUR_BY_NAME).join(', ')}), a colour word (${Object.keys(POWER_COLOUR_BY_WORD).join(', ')}) or a hex value like 66FF66.`;
      settings.playerPowerColour = colour;
      return `Player power colour is now ${colour}.`;
    },
  });
}
