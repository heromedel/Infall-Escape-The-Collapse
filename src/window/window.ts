/**
 * The window: draws what the host sends and sends back what the player did. It holds no game state of its own
 * (standards, principle 11: the host owns it).
 */

interface ShipSummary {
  name: string;
  race: string;
  rooms: number;
  systems: number;
  hull: number;
}

/** The functions the host bridge (src/host/preload.ts) gives the window. */
declare const host: {
  ships(): Promise<ShipSummary[]>;
  debug(line: string): Promise<string>;
};

async function showLoadedShips(): Promise<void> {
  const table = document.getElementById('ships') as HTMLTableElement;
  const ships = await host.ships();
  table.innerHTML = '<tr><th>Ship</th><th>Race</th><th>Rooms</th><th>Systems</th><th>Hull</th></tr>';
  for (const ship of ships) {
    const row = table.insertRow();
    for (const value of [ship.name, ship.race, ship.rooms, ship.systems, ship.hull]) {
      row.insertCell().textContent = String(value);
    }
  }
}

function wireDebugConsole(): void {
  const line = document.getElementById('debug-line') as HTMLInputElement;
  const output = document.getElementById('debug-output') as HTMLPreElement;
  line.addEventListener('keydown', async (event) => {
    if (event.key !== 'Enter' || line.value.trim() === '') return;
    output.textContent = await host.debug(line.value);
    line.value = '';
  });
}

showLoadedShips();
wireDebugConsole();
