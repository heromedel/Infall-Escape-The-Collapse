/**
 * Finds every entity folder under content/ and holds what it loaded, by name (coding rules 4 and 5). This is the
 * only place that reads content from disk; the simulation's readers take text.
 *
 * Ships: content/ships/<folder>/ship.xml is the base ship; loadout.<anything>.xml beside it are its loadouts,
 * each registered under the loadout's own name (GDD 5J). Art named in the XML is looked for in the same folder.
 *
 * Systems: content/systems/<folder>/system.xml names the system; symbol.svg beside it is its standard symbol,
 * lifted from the accepted floor plans. A system with no folder still works; it draws as a lettered square.
 */

import * as fs from 'node:fs';
import * as path from 'node:path';
import { ShipDefinition } from '../simulation/content/ShipDefinition';
import { ShipFileReader, ShipFileError } from '../simulation/content/ShipFileReader';
import { checkShip } from '../simulation/content/ShipChecks';
import { Log } from './Log';

/** A system's content: its name and, when it has one, its symbol's SVG text. */
export interface SystemEntry {
  name: string;
  folder: string;
  symbolSvg?: string;
}

/** A loaded ship together with the folder its art lives in. */
export interface ShipEntry {
  definition: ShipDefinition;
  folder: string;
}

export class ContentLibrary {
  private readonly ships = new Map<string, ShipEntry>();
  private readonly systems = new Map<string, SystemEntry>();

  private constructor(private readonly log: Log) {}

  static load(contentFolder: string, log: Log): ContentLibrary {
    const library = new ContentLibrary(log);
    if (!fs.existsSync(contentFolder)) {
      log.event('content.folder_missing', { folder: contentFolder });
      return library;
    }
    library.loadSystems(path.join(contentFolder, 'systems'));
    library.loadShips(path.join(contentFolder, 'ships'));
    library.noteSystemsWithoutSymbols();
    log.event('content.loaded', { ships: library.ships.size, systems: library.systems.size });
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

  /** The system's content, or nothing when no folder names it. */
  system(name: string): SystemEntry | undefined {
    return this.systems.get(name);
  }

  private loadSystems(systemsFolder: string): void {
    if (!fs.existsSync(systemsFolder)) return;
    for (const folderName of fs.readdirSync(systemsFolder).sort()) {
      const folder = path.join(systemsFolder, folderName);
      const systemFile = path.join(folder, 'system.xml');
      if (!fs.existsSync(systemFile)) continue;
      const name = /<system\s[^>]*name="([^"]+)"/.exec(fs.readFileSync(systemFile, 'utf8'))?.[1];
      if (!name) {
        this.log.event('content.system_refused', { file: systemFile, reason: 'the <system> element has no name="..."' });
        continue;
      }
      const symbolFile = path.join(folder, 'symbol.svg');
      const symbolSvg = fs.existsSync(symbolFile) ? fs.readFileSync(symbolFile, 'utf8') : undefined;
      this.systems.set(name, { name, folder, symbolSvg });
      this.log.event('content.system_loaded', { system: name, symbol: symbolSvg !== undefined });
    }
  }

  /** A system a ship uses that has no symbol draws as a lettered square; say so once per name. */
  private noteSystemsWithoutSymbols(): void {
    const seen = new Set<string>();
    for (const entry of this.ships.values()) {
      for (const system of entry.definition.systems) {
        if (seen.has(system.name) || this.systems.get(system.name)?.symbolSvg) continue;
        seen.add(system.name);
        this.log.event('content.symbol_missing', { system: system.name });
      }
    }
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
