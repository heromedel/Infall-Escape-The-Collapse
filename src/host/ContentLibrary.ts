/**
 * Finds every entity folder under content/ and holds what it loaded, by name (coding rules 4 and 5). This is the
 * only place that reads content from disk; the simulation's readers take text.
 *
 * Ships: content/ships/<folder>/ship.xml is the base ship; loadout.<anything>.xml beside it are its loadouts,
 * each registered under the loadout's own name (GDD 5J). Art named in the XML is looked for in the same folder.
 */

import * as fs from 'node:fs';
import * as path from 'node:path';
import { ShipDefinition } from '../simulation/content/ShipDefinition';
import { ShipFileReader, ShipFileError } from '../simulation/content/ShipFileReader';
import { checkShip } from '../simulation/content/ShipChecks';
import { Log } from './Log';

/** A loaded ship together with the folder its art lives in. */
export interface ShipEntry {
  definition: ShipDefinition;
  folder: string;
}

export class ContentLibrary {
  private readonly ships = new Map<string, ShipEntry>();

  private constructor(private readonly log: Log) {}

  static load(contentFolder: string, log: Log): ContentLibrary {
    const library = new ContentLibrary(log);
    if (!fs.existsSync(contentFolder)) {
      log.event('content.folder_missing', { folder: contentFolder });
      return library;
    }
    library.loadShips(path.join(contentFolder, 'ships'));
    log.event('content.loaded', { ships: library.ships.size });
    return library;
  }

  ship(name: string): ShipEntry {
    const entry = this.ships.get(name);
    if (!entry) throw new Error(`No ship named "${name}" is loaded`);
    return entry;
  }

  shipNames(): string[] {
    return [...this.ships.keys()];
  }

  private loadShips(shipsFolder: string): void {
    if (!fs.existsSync(shipsFolder)) return;
    const reader = new ShipFileReader();
    for (const folderName of fs.readdirSync(shipsFolder).sort()) {
      const folder = path.join(shipsFolder, folderName);
      const shipFile = path.join(folder, 'ship.xml');
      if (!fs.existsSync(shipFile)) continue;
      const shipText = fs.readFileSync(shipFile, 'utf8');
      this.accept(() => reader.readShip(shipText), shipFile, folder);

      const loadoutFiles = fs.readdirSync(folder).filter((file) => /^loadout\..*\.xml$/.test(file)).sort();
      for (const loadoutFile of loadoutFiles) {
        const loadoutText = fs.readFileSync(path.join(folder, loadoutFile), 'utf8');
        this.accept(() => reader.readLoadout(shipText, loadoutText), path.join(folder, loadoutFile), folder);
      }
    }
  }

  /** Reads one ship or loadout, checks it, and keeps it only if nothing refused it. */
  private accept(read: () => ShipDefinition, file: string, folder: string): void {
    let definition: ShipDefinition;
    try {
      definition = read();
    } catch (error) {
      const reason = error instanceof ShipFileError ? error.message : `unexpected error: ${(error as Error).message}`;
      this.log.event('content.ship_refused', { ship: path.basename(file), file, reason });
      return;
    }
    const result = checkShip(definition);
    for (const warning of result.warnings) this.log.event('content.ship_warning', { ship: definition.name, warning });
    if (result.refusals.length > 0) {
      this.log.event('content.ship_refused', { ship: definition.name, file, reason: result.refusals.join('; ') });
      return;
    }
    this.noteMissingArt(definition, folder);
    this.ships.set(definition.name, { definition, folder });
    this.log.event('content.ship_loaded', {
      ship: definition.name, race: definition.race, rooms: definition.rooms.length, systems: definition.systems.length,
      doors: definition.doors.length, conduits: definition.conduits.length, hullArt: definition.art.hull ?? 'none',
    });
  }

  private noteMissingArt(definition: ShipDefinition, folder: string): void {
    for (const kind of ['hull', 'floor'] as const) {
      const art = definition.art[kind];
      if (art && !fs.existsSync(path.join(folder, art))) {
        this.log.event('content.art_missing', { ship: definition.name, kind, art });
      }
    }
  }
}
