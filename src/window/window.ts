/**
 * The window: draws what the host sends and sends back what the player did. It holds no game state of its own
 * (standards, principle 11: the host owns it). Outside a battle it is the ship viewer; when the host starts a
 * battle it becomes the battle screen: the battle fills the window, the top band carries the squad and the
 * status line (GDD 3J), and the debug console drops down on the backtick key.
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
  await showPickedShip();
}

async function showPickedShip(): Promise<void> {
  if (inBattle) return;
  const name = (document.getElementById('ship-picker') as HTMLSelectElement).value;
  const side = (document.getElementById('side-picker') as HTMLSelectElement).value as 'player' | 'enemy';
  if (!name) return;
  const picture = await host.shipPicture(name, side);
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
        document.body.classList.add('battle');
        document.body.classList.remove('console-open');
        battleView.start(message.pictures, message.playerShipIds, message.formation);
        controls.start(message.pictures, message.playerShipIds, message.look.battleGui === 'floating');
        stage.replaceChildren(battleView.root);
        fitBattle();
        break;
      }
      case 'Look':
        controls.setFloating(message.look.battleGui === 'floating');
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
  document.body.classList.remove('battle', 'console-open', 'gui-card', 'armed', 'crew-selected');
  showPickedShip();
}

/** The debug console: Enter runs the line; up and down walk back through the commands typed this session. */
function wireDebugConsole(): void {
  const line = document.getElementById('debug-line') as HTMLInputElement;
  const output = document.getElementById('debug-output') as HTMLPreElement;
  const history: string[] = [];
  let historyIndex = 0;   // history.length means "the line being typed"
  let unsentLine = '';
  window.addEventListener('keydown', (event) => {
    if (event.key === '`' && inBattle) {
      event.preventDefault();
      const open = document.body.classList.toggle('console-open');
      if (open) line.focus(); else line.blur();
      return;
    }
    if (event.key === 'Escape' && event.target === line) { line.blur(); document.body.classList.remove('console-open'); return; }
    if (event.key === 'Escape' && inBattle && battleOver && !document.body.classList.contains('armed') && !document.body.classList.contains('crew-selected')) leaveBattle();
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
    await showPickedShip();   // a command may have changed what the picture looks like
  });
}

function caption(text: string): void {
  document.getElementById('ship-caption')!.textContent = text;
}

listenToHost();
fillShipPicker();
wireDebugConsole();
