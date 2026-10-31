/**
 * Finds every entity folder under content/ and holds what it loaded, by name (coding rules 4 and 5). This is the
 * only place that reads content from disk; the simulation's readers take text.
 *
 * Ships: content/ships/<folder>/ship.xml is the base ship; loadout.<anything>.xml beside it are its loadouts,
 * each registered under the loadout's own name (GDD 5J). Art named in the XML is looked for in the same folder.
 *
 * Weapons: content/weapons/<folder>/weapon.xml is the weapon's card (GDD 8E, 8F, 11B).
 *
 * Races: content/races/<folder>/race.xml holds a race's crew traits; a race with no file gets the defaults.
 *
 * Systems: content/systems/<folder>/system.xml names the system; symbol.svg beside it is its standard symbol,
 * lifted from the accepted floor plans. A system with no folder still works; it draws as a lettered square.
 */

import * as fs from 'node:fs';
import * as path from 'node:path';
import { ShipDefinition } from '../simulation/content/ShipDefinition';
import { ShipFileReader, ShipFileError } from '../simulation/content/ShipFileReader';
import { checkShip } from '../simulation/content/ShipChecks';
import { WeaponDefinition } from '../simulation/content/WeaponDefinition';
import { WeaponFileReader, WeaponFileError } from '../simulation/content/WeaponFileReader';
import { DEFAULT_RACE, RaceDefinition, readRaceDefinition } from '../simulation/content/RaceDefinition';
import { Log } from './Log';
import type { ProjectileArt } from '../shared/Messages';
import { FormationDefinition, FormationFileError, readFormationDefinition } from '../simulation/content/FormationDefinition';

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
  private readonly weapons = new Map<string, WeaponDefinition>();
  /** Each weapon's projectile picture by weapon name, read from the SVG its file names. */
  private readonly projectiles = new Map<string, ProjectileArt>();
  private readonly races = new Map<string, RaceDefinition>();
  private readonly formations = new Map<string, FormationDefinition>();

  private constructor(private readonly log: Log) {}

  static load(contentFolder: string, log: Log): ContentLibrary {
    const library = new ContentLibrary(log);
    if (!fs.existsSync(contentFolder)) {
      log.event('content.folder_missing', { folder: contentFolder });
      return library;
    }
    library.loadSystems(path.join(contentFolder, 'systems'));
    library.loadRaces(path.join(contentFolder, 'races'));
    library.loadWeapons(path.join(contentFolder, 'weapons'));
    library.loadShips(path.join(contentFolder, 'ships'));
    library.loadFormations(path.join(contentFolder, 'formations'));
    library.noteSystemsWithoutSymbols();
    library.noteWeaponsMissing();
    log.event('content.loaded', { ships: library.ships.size, systems: library.systems.size, weapons: library.weapons.size, races: library.races.size, formations: library.formations.size });
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

  weapon(name: string): WeaponDefinition {
    const weapon = this.weapons.get(name);
    if (!weapon) throw new Error(`No weapon named "${name}" is loaded`);
    return weapon;
  }

  weaponNames(): string[] {
    return [...this.weapons.keys()];
  }

  /** Every loaded weapon's projectile picture, by weapon name; a weapon without one draws the window's placeholder. */
  projectileArt(): Record<string, ProjectileArt> {
    return Object.fromEntries(this.projectiles);
  }

  /** The race's traits, or the plain defaults under its name when it has no file. */
  race(name: string): RaceDefinition {
    return this.races.get(name) ?? { ...DEFAULT_RACE, name };
  }

  /** A formation by name (GDD 3S); the first loaded when the name is unknown, so a battle always has one. */
  formation(name: string): FormationDefinition {
    const formation = this.formations.get(name) ?? [...this.formations.values()][0];
    if (!formation) throw new Error('No formation files are loaded (content/formations)');
    return formation;
  }

  formationNames(): string[] {
    return [...this.formations.keys()];
  }

  private loadFormations(formationsFolder: string): void {
    if (!fs.existsSync(formationsFolder)) return;
    for (const folderName of fs.readdirSync(formationsFolder).sort()) {
      const file = path.join(formationsFolder, folderName, 'formation.xml');
      if (!fs.existsSync(file)) continue;
      try {
        const formation = readFormationDefinition(fs.readFileSync(file, 'utf8'));
        this.formations.set(formation.name, formation);
        this.log.event('content.formation_loaded', { formation: formation.name, zones: formation.zones.length, zoneSize: formation.zoneSize, shift: formation.shift });
      } catch (error) {
        const reason = error instanceof FormationFileError ? error.message : `unexpected error: ${(error as Error).message}`;
        this.log.event('content.formation_refused', { file, reason });
      }
    }
  }

  private loadRaces(racesFolder: string): void {
    if (!fs.existsSync(racesFolder)) return;
    for (const folderName of fs.readdirSync(racesFolder).sort()) {
      const file = path.join(racesFolder, folderName, 'race.xml');
      if (!fs.existsSync(file)) continue;
      try {
        const race = readRaceDefinition(fs.readFileSync(file, 'utf8'));
        this.races.set(race.name, race);
        this.log.event('content.race_loaded', { race: race.name, xpRate: race.xpRate, integrationBars: race.integrationBars });
      } catch (error) {
        this.log.event('content.race_refused', { file, reason: (error as Error).message });
      }
    }
  }

  private loadWeapons(weaponsFolder: string): void {
    if (!fs.existsSync(weaponsFolder)) return;
    const reader = new WeaponFileReader();
    for (const folderName of fs.readdirSync(weaponsFolder).sort()) {
      const file = path.join(weaponsFolder, folderName, 'weapon.xml');
      if (!fs.existsSync(file)) continue;
      try {
        const weapon = reader.readWeapon(fs.readFileSync(file, 'utf8'));
        this.weapons.set(weapon.name, weapon);
        this.loadProjectileArt(weapon, path.join(weaponsFolder, folderName));
        this.log.event('content.weapon_loaded', { weapon: weapon.name, type: weapon.type, shots: weapon.shots, damage: weapon.damage, chargeSeconds: weapon.chargeSeconds });
      } catch (error) {
        const reason = error instanceof WeaponFileError ? error.message : `unexpected error: ${(error as Error).message}`;
        this.log.event('content.weapon_refused', { file, reason });
      }
    }
  }

  /** The projectile's SVG named by the weapon file, when it is there; a missing file is noted, not fatal. */
  private loadProjectileArt(weapon: WeaponDefinition, folder: string): void {
    if (!weapon.projectileArt) return;
    const file = path.join(folder, weapon.projectileArt);
    if (!fs.existsSync(file) || !file.toLowerCase().endsWith('.svg')) {
      this.log.event('content.projectile_art_missing', { weapon: weapon.name, file });
      return;
    }
    const content = fs.readFileSync(file, 'utf8');
    const viewBox = /viewBox="\s*[-\d.]+\s+[-\d.]+\s+([\d.]+)\s+([\d.]+)\s*"/.exec(content);
    const width = Number(viewBox?.[1] ?? /\swidth="([\d.]+)/.exec(content)?.[1] ?? 0);
    const height = Number(viewBox?.[2] ?? /\sheight="([\d.]+)/.exec(content)?.[1] ?? 0);
    this.projectiles.set(weapon.name, { content, width, height });
  }

  /** A ship that names a weapon with no file can't arm it; say so once per name. */
  private noteWeaponsMissing(): void {
    const seen = new Set<string>();
    for (const entry of this.ships.values()) {
      for (const weapon of entry.definition.weapons) {
        if (seen.has(weapon.name) || this.weapons.has(weapon.name)) continue;
        seen.add(weapon.name);
        this.log.event('content.weapon_missing', { weapon: weapon.name, ship: entry.definition.name });
      }
    }
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
