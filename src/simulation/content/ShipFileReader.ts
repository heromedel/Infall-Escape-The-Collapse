/**
 * Turns ship XML text into a ShipDefinition (GDD 5F to 5L), and applies a loadout file to its base ship
 * (GDD 5J: Inherit Patch or Replace). Takes text, not files, so the simulation never touches the file system;
 * the host's ContentLibrary finds the files and hands the text in.
 *
 * Reading never checks the ship for sense; ShipChecks does that, so a reader error is always "the file can't be
 * read" and a check error is always "the ship can't exist".
 */

import { XMLParser } from 'fast-xml-parser';
import {
  Centering, CenteringMode, ConduitTile, DIRECTIONS, Direction, parseConduitList, parseTile, tileKey,
} from './Tile';
import {
  Door, PowerSource, StartingCrew, Room, ShipArt, ShipDefinition, StartingWeapon, SystemPlacement, systemKey,
} from './ShipDefinition';

/** A ship file that can't be read, with the reason in plain words. */
export class ShipFileError extends Error {}

type XmlNode = Record<string, any>;

const LIST_ELEMENTS = new Set(['room', 'system', 'door', 'weapon', 'member', 'suit']);

const parser = new XMLParser({
  ignoreAttributes: false,
  attributeNamePrefix: '',
  parseAttributeValue: false,
  parseTagValue: false,
  trimValues: true,
  isArray: (name) => LIST_ELEMENTS.has(name),
});

export class ShipFileReader {
  /** A base ship from its ship.xml text. */
  readShip(xmlText: string): ShipDefinition {
    const root = this.parseRoot(xmlText, 'ship');
    const name = this.required(root, 'name', 'ship');
    const where = `ship "${name}"`;
    return this.readWholeShip(root, name, name, where);
  }

  /** A loadout from its text and its base ship's text. The result is a complete ship named after the loadout. */
  readLoadout(shipXmlText: string, loadoutXmlText: string): ShipDefinition {
    const base = this.readShip(shipXmlText);
    const root = this.parseRoot(loadoutXmlText, 'loadout');
    const name = this.required(root, 'name', 'loadout');
    const where = `loadout "${name}"`;
    const forShip = this.required(root, 'ship', where);
    if (forShip !== base.name) {
      throw new ShipFileError(`${where} is for ship "${forShip}" but was read against ship "${base.name}"`);
    }
    const inherit = (root.inherit ?? 'Patch') as string;
    if (inherit === 'Replace') {
      return this.readWholeShip(root, name, base.name, where);
    }
    if (inherit !== 'Patch') {
      throw new ShipFileError(`${where}: inherit="${inherit}" is not Patch or Replace`);
    }
    return this.patchShip(base, root, name, where);
  }

  // ---- whole ships ----------------------------------------------------------------------------------------

  private readWholeShip(root: XmlNode, name: string, baseShip: string, where: string): ShipDefinition {
    const centering = this.readCentering(root.center, where);
    const ship: ShipDefinition = {
      name,
      race: this.required(root, 'race', where),
      baseShip,
      centering,
      hullPoints: this.readHullPoints(root.hull, where),
      power: this.readPower(root.power, where),
      art: this.readArt(root.art, { hull: undefined, floor: undefined, offset: { x: 0, y: 0 } }, where),
      mountCount: this.readMountCount(root.mounts, where),
      rooms: this.children(root.rooms, 'room').map((node) => this.readRoom(node, where)),
      systems: this.children(root.systems, 'system').map((node) => this.readSystem(node, where)),
      doors: this.children(root.doors, 'door').map((node) => this.readDoor(node, where)),
      conduits: this.readConduits(root.conduits, where),
      weapons: this.children(root.weapons, 'weapon').map((node) => this.readWeapon(node, where)),
      crew: this.children(root.crew, 'member').map((node) => this.readStartingCrew(node, where)),
      suits: this.children(root.suits, 'suit').map((node) => this.required(node, 'name', `${where} suit`)),
    };
    if (ship.conduits.some((conduit) => conduit.removed)) {
      throw new ShipFileError(`${where}: (x,y,Remove) only belongs in a loadout patch`);
    }
    return ship;
  }

  // ---- patches (GDD 5J) -----------------------------------------------------------------------------------

  /**
   * Patch: listed entries replace or add; `removed="true"` takes one out; unlisted entries stay. Attributes a
   * patched entry leaves out keep the ship's values, so a loadout can say only "Shields level 1" (GDD 5J says the
   * entry is replaced; keeping unlisted attributes is the same thing for a writer who lists only what changes).
   * Weapons, crew and suits are replaced whole when given. Conduits are patched tile by tile.
   */
  private patchShip(base: ShipDefinition, root: XmlNode, name: string, where: string): ShipDefinition {
    const centering = root.center ? this.readCentering(root.center, where) : base.centering;
    const ship: ShipDefinition = {
      ...base,
      name,
      baseShip: base.name,
      centering,
      race: root.race ?? base.race,
      hullPoints: root.hull ? this.readHullPoints(root.hull, where) : base.hullPoints,
      power: root.power ? this.readPower(root.power, where) : base.power,
      art: root.art ? this.readArt(root.art, base.art, where) : base.art,
      mountCount: root.mounts ? this.readMountCount(root.mounts, where) : base.mountCount,
      rooms: this.patchList(base.rooms, this.children(root.rooms, 'room'), (room) => room.id,
        (node) => Number(this.required(node, 'id', `${where} room`)),
        (node, old) => this.readRoom(this.withDefaults(node, old), where), where, 'room'),
      systems: this.patchList(base.systems, this.children(root.systems, 'system'), systemKey,
        (node) => systemKey({ name: this.required(node, 'name', `${where} system`), label: node.label }),
        (node, old) => this.readSystem(this.withDefaults(node, old), where), where, 'system'),
      doors: this.patchList(base.doors, this.children(root.doors, 'door'), (door) => door.id,
        (node) => Number(this.required(node, 'id', `${where} door`)),
        (node, old) => this.readDoor(this.withDefaults(node, old), where), where, 'door'),
      conduits: this.patchConduits(base.conduits, this.readConduits(root.conduits, where)),
      weapons: root.weapons !== undefined
        ? this.children(root.weapons, 'weapon').map((node) => this.readWeapon(node, where)) : base.weapons,
      crew: root.crew !== undefined
        ? this.children(root.crew, 'member').map((node) => this.readStartingCrew(node, where)) : base.crew,
      suits: root.suits !== undefined
        ? this.children(root.suits, 'suit').map((node) => this.required(node, 'name', `${where} suit`)) : base.suits,
    };
    return ship;
  }

  /** The patched node's attributes laid over the old entry's values, so unlisted attributes are kept. */
  private withDefaults(node: XmlNode, old: object | undefined): XmlNode {
    if (!old) return node;
    const defaults: XmlNode = {};
    for (const [key, value] of Object.entries(old)) {
      if (value === undefined) continue;
      if (Array.isArray(value)) defaults[key] = value.join(',');
      else if (typeof value === 'object' && 'x' in value) defaults[key] = `${value.x},${value.y}`;
      else if (typeof value === 'boolean') defaults[key] = value ? 'Yes' : 'No';
      else defaults[key] = String(value);
    }
    return { ...defaults, ...node };
  }

  private patchList<T>(
    baseList: T[], patchNodes: XmlNode[], keyOf: (entry: T) => string | number,
    keyOfNode: (node: XmlNode) => string | number, read: (node: XmlNode, old: T | undefined) => T,
    where: string, what: string,
  ): T[] {
    const byKey = new Map<string | number, T>(baseList.map((entry) => [keyOf(entry), entry]));
    for (const node of patchNodes) {
      const key = keyOfNode(node);
      if (this.isRemoved(node)) {
        if (!byKey.has(key)) throw new ShipFileError(`${where} removes ${what} ${key}, which the ship doesn't have`);
        byKey.delete(key);
      } else {
        byKey.set(key, read(node, byKey.get(key)));
      }
    }
    return [...byKey.values()];
  }

  /** Conduits patch tile by tile: a re-listed tile replaces its entry, (x,y,Remove) takes it out (GDD 5J). */
  private patchConduits(baseConduits: ConduitTile[], patch: ConduitTile[]): ConduitTile[] {
    const byTile = new Map(baseConduits.map((conduit) => [tileKey(conduit.tile), conduit]));
    for (const conduit of patch) {
      if (conduit.removed) byTile.delete(tileKey(conduit.tile));
      else byTile.set(tileKey(conduit.tile), conduit);
    }
    return [...byTile.values()];
  }

  private isRemoved(node: XmlNode): boolean {
    return String(node.removed ?? '').toLowerCase() === 'true';
  }

  // ---- single entries -------------------------------------------------------------------------------------

  private readCentering(node: XmlNode | undefined, where: string): Centering {
    const read = (value: unknown, axis: string): CenteringMode => {
      const mode = String(value ?? 'Tile');
      if (mode !== 'Tile' && mode !== 'Point') throw new ShipFileError(`${where}: center ${axis}="${mode}" is not Tile or Point`);
      return mode;
    };
    return { x: read(node?.x, 'x'), y: read(node?.y, 'y') };
  }

  private readHullPoints(node: XmlNode | undefined, where: string): number {
    return this.wholeNumber(this.required(node ?? {}, 'points', `${where} hull`), `${where} hull points`);
  }

  private readPower(node: XmlNode | undefined, where: string): PowerSource {
    const kind = String(node?.kind ?? 'Reactor');
    switch (kind) {
      case 'Reactor': return { kind, bars: this.wholeNumber(this.required(node ?? {}, 'bars', `${where} power`), `${where} reactor bars`) };
      case 'AZC': return { kind, level: this.wholeNumber(this.required(node ?? {}, 'level', `${where} power`), `${where} AZC level`) };
      case 'SelfPowered': return { kind };
      default: throw new ShipFileError(`${where}: power kind="${kind}" is not Reactor, AZC or SelfPowered`);
    }
  }

  private readArt(node: XmlNode | undefined, previous: ShipArt, where: string): ShipArt {
    return {
      hull: this.emptyAsUndefined(node?.hull) ?? previous.hull,
      floor: this.emptyAsUndefined(node?.floor) ?? previous.floor,
      offset: node?.offset ? parseTile(node.offset, `${where} art offset`) : previous.offset,
    };
  }

  private readMountCount(node: XmlNode | undefined, where: string): number {
    return node?.count === undefined ? 0 : this.wholeNumber(node.count, `${where} mounts count`);
  }

  private readRoom(node: XmlNode, where: string): Room {
    const id = this.wholeNumber(this.required(node, 'id', `${where} room`), `${where} room id`);
    const at = `${where} room ${id}`;
    return {
      id,
      from: parseTile(this.required(node, 'from', at), `${at} from`),
      to: parseTile(this.required(node, 'to', at), `${at} to`),
      note: this.emptyAsUndefined(node.note),
    };
  }

  private readSystem(node: XmlNode, where: string): SystemPlacement {
    const name = this.required(node, 'name', `${where} system`);
    const at = `${where} system ${systemKey({ name, label: node.label })}`;
    return {
      name,
      label: this.emptyAsUndefined(node.label),
      tile: parseTile(this.required(node, 'tile', at), `${at} tile`),
      level: this.wholeNumber(node.level ?? '1', `${at} level`),
      selfPower: node.selfPower === undefined ? undefined : this.wholeNumber(node.selfPower, `${at} selfPower`),
      mounts: node.mounts === undefined ? undefined : this.numberList(node.mounts, `${at} mounts`),
      wall: node.wall === undefined ? undefined : this.direction(node.wall, `${at} wall`),
      rotation: this.emptyAsUndefined(node.rotation),
      mirror: node.mirror === undefined ? undefined : String(node.mirror).toLowerCase() === 'yes',
      art: this.emptyAsUndefined(node.art),
    };
  }

  private readDoor(node: XmlNode, where: string): Door {
    const id = this.wholeNumber(this.required(node, 'id', `${where} door`), `${where} door id`);
    const at = `${where} door ${id}`;
    return {
      id,
      tile: parseTile(this.required(node, 'tile', at), `${at} tile`),
      facing: this.direction(this.required(node, 'facing', at), `${at} facing`),
      note: this.emptyAsUndefined(node.note),
    };
  }

  private readConduits(node: unknown, where: string): ConduitTile[] {
    if (node === undefined || node === null) return [];
    const text = typeof node === 'string' ? node : String((node as XmlNode)['#text'] ?? '');
    try {
      return parseConduitList(text, where);
    } catch (error) {
      throw new ShipFileError((error as Error).message);
    }
  }

  private readWeapon(node: XmlNode, where: string): StartingWeapon {
    const name = this.required(node, 'name', `${where} weapon`);
    return {
      name,
      mount: node.mount === undefined ? undefined : this.wholeNumber(node.mount, `${where} weapon ${name} mount`),
    };
  }

  private readStartingCrew(node: XmlNode, where: string): StartingCrew {
    const race = this.required(node, 'race', `${where} crew member`);
    return { race, count: this.wholeNumber(node.count ?? '1', `${where} crew ${race} count`) };
  }

  // ---- small helpers --------------------------------------------------------------------------------------

  private parseRoot(xmlText: string, rootName: string): XmlNode {
    let parsed: XmlNode;
    try {
      parsed = parser.parse(xmlText);
    } catch (error) {
      throw new ShipFileError(`not valid XML: ${(error as Error).message}`);
    }
    const root = parsed[rootName];
    if (!root || typeof root !== 'object') throw new ShipFileError(`the file's top element is not <${rootName}>`);
    return root;
  }

  /** The child elements of a list element, e.g. the <room>s inside <rooms>. An absent list is empty. */
  private children(listNode: unknown, childName: string): XmlNode[] {
    if (!listNode || typeof listNode !== 'object') return [];
    return ((listNode as XmlNode)[childName] ?? []) as XmlNode[];
  }

  private required(node: XmlNode, attribute: string, where: string): string {
    const value = node[attribute];
    if (value === undefined || value === '') throw new ShipFileError(`${where} is missing ${attribute}="..."`);
    return String(value);
  }

  private wholeNumber(value: unknown, where: string): number {
    const number = Number(value);
    if (!Number.isInteger(number)) throw new ShipFileError(`${where}: "${value}" is not a whole number`);
    return number;
  }

  /** "1,2,3" to whole numbers. */
  private numberList(value: unknown, where: string): number[] {
    return String(value).split(',').map((part) => this.wholeNumber(part.trim(), where));
  }

  private direction(value: unknown, where: string): Direction {
    const text = String(value);
    if (!DIRECTIONS.includes(text as Direction)) throw new ShipFileError(`${where}: "${text}" is not North, South, East or West`);
    return text as Direction;
  }

  private emptyAsUndefined(value: unknown): string | undefined {
    return value === undefined || value === null || value === '' ? undefined : String(value);
  }
}
