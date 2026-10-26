/**
 * The window: draws what the host sends and sends back what the player did. It holds no game state of its own
 * (standards, principle 11: the host owns it).
 */

import type { ShipPicture } from '../shared/ShipPicture';
import { ShipDrawing } from './ShipDrawing.js';
import { Camera } from './Camera.js';

/** The functions the host bridge (src/host/preload.ts) gives the window. */
declare const host: {
  shipNames(): Promise<string[]>;
  shipPicture(name: string, side: 'player' | 'enemy'): Promise<ShipPicture>;
  debug(line: string): Promise<string>;
};

const viewport = document.getElementById('viewport') as unknown as SVGSVGElement;
const drawing = new ShipDrawing();
viewport.appendChild(drawing.root);
const camera = new Camera(viewport, drawing.root);

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
  const name = (document.getElementById('ship-picker') as HTMLSelectElement).value;
  const side = (document.getElementById('side-picker') as HTMLSelectElement).value as 'player' | 'enemy';
  if (!name) return;
  const picture = await host.shipPicture(name, side);
  drawing.draw(picture);
  const size = ShipDrawing.sizeOf(picture);
  camera.centreOn(size.width, size.height);
  document.getElementById('ship-caption')!.textContent =
    `${picture.name} (${picture.race}): ${picture.columns} by ${picture.rows} tiles, ${picture.rooms.length} rooms, `
    + `${picture.systems.length} systems, ${picture.doors.length} doors, hull art ${picture.hullArt ? picture.hullArt.kind : 'none'}.`;
}

/** The debug console: Enter runs the line; up and down walk back through the commands typed this session. */
function wireDebugConsole(): void {
  const line = document.getElementById('debug-line') as HTMLInputElement;
  const output = document.getElementById('debug-output') as HTMLPreElement;
  const history: string[] = [];
  let historyIndex = 0;   // history.length means "the line being typed"
  let unsentLine = '';
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

fillShipPicker();
wireDebugConsole();
