/**
 * The window: draws what the host sends and sends back what the player did. It holds no game state of its own
 * (standards, principle 11: the host owns it). It opens on the title screen (Test Battle, Ship Viewer, Settings,
 * Exit); the ship viewer shows one ship; when the host starts a battle the battle fills the window with the
 * floating GUI over it; Escape goes back. The debug console drops down on the backtick key.
 */

import type { ShipPicture } from '../shared/ShipPicture';
import type { ClientToHost, HostToClient } from '../shared/Messages';
import { ShipDrawing } from './ShipDrawing.js';
import { Camera } from './Camera.js';
import { BattleView } from './BattleView.js';
import { BattleControls } from './BattleControls.js';
import { GUI_BANDS } from './BattleHud.js';

/** The functions the host bridge (src/host/preload.ts) gives the window. */
declare const host: {
  shipNames(): Promise<string[]>;
  shipPicture(name: string, side: 'player' | 'enemy'): Promise<ShipPicture>;
  debug(line: string): Promise<string>;
  settings(): Promise<Record<string, unknown>>;
  exit(): void;
  onHostMessage(listener: (message: HostToClient) => void): void;
  sendToHost(message: ClientToHost): void;
};

const viewport = document.getElementById('viewport') as unknown as SVGSVGElement;
const dock = document.getElementById('dock') as unknown as SVGSVGElement;
const hud = document.getElementById('hud') as unknown as SVGSVGElement;
const viewerDrawing = new ShipDrawing();
const battleView = new BattleView();
const stage = document.createElementNS('http://www.w3.org/2000/svg', 'g');
viewport.appendChild(stage);
const camera = new Camera(viewport, stage);
camera.onChange = (zoom) => battleView.setZoom(zoom);
const controls = new BattleControls(battleView, viewport, hud, dock,
  (order) => host.sendToHost({ kind: 'Order', order }),
  (paused) => host.sendToHost({ kind: paused ? 'Pause' : 'Unpause' }));
let inBattle = false;
let battleOver = false;

type Screen = 'title' | 'viewer' | 'settings' | 'battle';
/** Which screen the body shows; the CSS does the showing and hiding. */
function showScreen(screen: Screen): void {
  document.body.classList.remove('title', 'viewer', 'settings', 'battle');
  document.body.classList.add(screen);
  if (screen !== 'battle') document.body.classList.remove('console-open', 'gui-card', 'armed', 'crew-selected', 'aim-auto', 'aim-once');
}

// ---- the title screen ------------------------------------------------------------------------------------

function wireTitle(): void {
  document.getElementById('title-battle')!.addEventListener('click', () => { host.debug('battle'); });
  document.getElementById('title-viewer')!.addEventListener('click', () => { showScreen('viewer'); showPickedShip(); });
  document.getElementById('title-settings')!.addEventListener('click', () => { showScreen('settings'); fillSettings(); });
  document.getElementById('title-exit')!.addEventListener('click', () => host.exit());
  document.getElementById('settings-back')!.addEventListener('click', () => showScreen('title'));
}

/** The settings screen: each row is a setting as the debug console sets it, default first as the docs write them. */
const SETTING_ROWS: { label: string; key: string; kind: 'choice' | 'number' | 'text'; choices?: [string, string][]; command: (value: string) => string }[] = [
  { label: 'Battle GUI', key: 'battleGui', kind: 'choice', choices: [['floating', 'Floating'], ['card', 'Card']], command: (value) => `gui ${value}` },
  { label: 'Autofire', key: 'autofire', kind: 'choice', choices: [['false', 'Off'], ['true', 'On']], command: (value) => `autofire ${value === 'true' ? 'on' : 'off'}` },
  { label: 'Target Lines', key: 'targetLines', kind: 'choice', choices: [['false', 'Off'], ['true', 'On']], command: (value) => `targetlines ${value === 'true' ? 'on' : 'off'}` },
  { label: 'Player Formation', key: 'playerFormation', kind: 'text', command: (value) => `formation player ${value}` },
  { label: 'Enemy Formation', key: 'enemyFormation', kind: 'text', command: (value) => `formation enemy ${value}` },
  { label: 'Show Zones (debug)', key: 'showZones', kind: 'choice', choices: [['false', 'Off'], ['true', 'On']], command: (value) => `zones ${value === 'true' ? 'on' : 'off'}` },
  { label: 'Shots Crossing Barrier', key: 'shotsCrossingBarrier', kind: 'choice', choices: [['true', 'Shown'], ['false', 'Hidden']], command: (value) => `crossing ${value === 'true' ? 'shown' : 'hidden'}` },
  { label: 'Auto Pause (Turn Mode)', key: 'autoPause', kind: 'choice', choices: [['false', 'Off'], ['true', 'On']], command: (value) => `autopause ${value === 'true' ? 'on' : 'off'}` },
  { label: 'Player Power Color', key: 'playerPowerColour', kind: 'text', command: (value) => `powercolor ${value}` },
];

async function fillSettings(): Promise<void> {
  const current = await host.settings();
  const rows = document.getElementById('settings-rows')!;
  const reply = document.getElementById('settings-reply')!;
  rows.replaceChildren();
  for (const row of SETTING_ROWS) {
    const label = document.createElement('label');
    label.textContent = row.label;
    let input: HTMLSelectElement | HTMLInputElement;
    if (row.kind === 'choice') {
      input = document.createElement('select');
      for (const [value, name] of row.choices!) {
        const option = document.createElement('option');
        option.value = value; option.textContent = name;
        input.appendChild(option);
      }
    } else {
      input = document.createElement('input');
      input.type = row.kind === 'number' ? 'number' : 'text';
      if (row.kind === 'number') (input as HTMLInputElement).step = '0.1';
    }
    input.value = String(current[row.key]);
    input.addEventListener('change', async () => { reply.textContent = await host.debug(row.command(input.value)); });
    label.appendChild(input);
    rows.appendChild(label);
  }
}

// ---- the ship viewer (outside a battle) --------------------------------------------------------------------

async function fillShipPicker(): Promise<void> {
  const picker = document.getElementById('ship-picker') as HTMLSelectElement;
  for (const name of await host.shipNames()) {
    const option = document.createElement('option');
    option.value = name;
    option.textContent = name;
    picker.appendChild(option);
  }
  picker.addEventListener('change', showPickedShip);
  (document.getElementById('side-picker') as HTMLSelectElement).addEventListener('change', showPickedShip);
}

async function showPickedShip(): Promise<void> {
  if (inBattle || !document.body.classList.contains('viewer')) return;
  const name = (document.getElementById('ship-picker') as HTMLSelectElement).value;
  const side = (document.getElementById('side-picker') as HTMLSelectElement).value as 'player' | 'enemy';
  if (!name) return;
  const picture = await host.shipPicture(name, side);
  // a battle may have started while the picture was on its way: never draw over it
  if (inBattle || !document.body.classList.contains('viewer')) return;
  stage.replaceChildren(viewerDrawing.root);
  viewerDrawing.draw(picture);
  const size = ShipDrawing.sizeOf(picture);
  camera.centreOn(size.width, size.height);
  caption(`${picture.name} (${picture.race}): ${picture.columns} by ${picture.rows} tiles, ${picture.rooms.length} rooms, `
    + `${picture.systems.length} systems, ${picture.doors.length} doors, hull art ${picture.hullArt ? picture.hullArt.kind : 'none'}.`);
}

// ---- the battle screen (what the host sends) ----------------------------------------------------------------

function listenToHost(): void {
  host.onHostMessage((message) => {
    switch (message.kind) {
      case 'BattleStarted': {
        inBattle = true;
        battleOver = false;
        showScreen('battle');
        battleView.start(message.pictures, message.playerShipIds, message.formations, message.projectiles);
        controls.start(message.pictures, message.playerShipIds, message.look);
        stage.replaceChildren(battleView.root);
        fitBattle();
        break;
      }
      case 'Look':
        controls.setLook(message.look);
        break;
      case 'Snapshot': {
        battleView.update(message.snapshot);
        controls.update(message.snapshot);
        break;
      }
      case 'Paused':
        controls.setPaused(message.paused);
        break;
      case 'BattleEnded':
        battleOver = true;
        break;
    }
  });
}

/** The camera shows the whole battle; the window's size decides the zoom (GDD 3C: ships keep their size). */
function fitBattle(): void {
  requestAnimationFrame(() => {   // after the header has hidden, so the viewport has its final size
    const size = battleView.size();
    camera.fitTo(size.width, size.height, GUI_BANDS);
  });
}

function leaveBattle(): void {
  inBattle = false;
  showScreen('title');
}

/** The debug console: Enter runs the line; up and down walk back through the commands typed this session. */
function wireDebugConsole(): void {
  const line = document.getElementById('debug-line') as HTMLInputElement;
  const output = document.getElementById('debug-output') as HTMLPreElement;
  const history: string[] = [];
  let historyIndex = 0;   // history.length means "the line being typed"
  let unsentLine = '';
  window.addEventListener('keydown', (event) => {
    if (event.key === '`') {
      event.preventDefault();
      const open = document.body.classList.toggle('console-open');
      if (open) line.focus(); else line.blur();
      return;
    }
    if (event.key === 'Escape' && event.target === line) { line.blur(); document.body.classList.remove('console-open'); return; }
    if (event.key !== 'Escape' || event.target instanceof HTMLInputElement || event.target instanceof HTMLSelectElement) return;
    const screen = document.body.className.match(/\b(title|viewer|settings|battle)\b/)?.[1];
    if (screen === 'viewer' || screen === 'settings') showScreen('title');
    else if (screen === 'battle' && battleOver && !document.body.classList.contains('armed') && !document.body.classList.contains('crew-selected')) leaveBattle();
  });
  line.addEventListener('keydown', async (event) => {
    if (event.key === 'ArrowUp' || event.key === 'ArrowDown') {
      event.preventDefault();
      if (historyIndex === history.length) unsentLine = line.value;
      historyIndex = Math.max(0, Math.min(history.length, historyIndex + (event.key === 'ArrowUp' ? -1 : 1)));
      line.value = historyIndex === history.length ? unsentLine : history[historyIndex];
      line.setSelectionRange(line.value.length, line.value.length);
      return;
    }
    if (event.key !== 'Enter' || line.value.trim() === '') return;
    history.push(line.value);
    historyIndex = history.length;
    unsentLine = '';
    output.textContent = await host.debug(line.value);
    line.value = '';
    await showPickedShip();   // in the viewer, a command may have changed what the picture looks like; never in a battle
  });
}

function caption(text: string): void {
  document.getElementById('ship-caption')!.textContent = text;
}

listenToHost();
wireTitle();
fillShipPicker();
wireDebugConsole();
showScreen('title');
