/**
 * A live ship in a battle, built from its ShipDefinition: hull, rooms with air, systems with damage and power,
 * doors, crew and mounted weapons. It holds state and answers questions about itself; the tick steps in
 * Simulation.ts change it. One owner for every value (standards, principle 11).
 */

import { ShipDefinition, SystemPlacement, systemKey } from './content/ShipDefinition';
import { WeaponDefinition } from './content/WeaponDefinition';
import { RaceDefinition } from './content/RaceDefinition';
import { Direction, Tile, neighbourTile, sameTile, tileKey, tilesBetween } from './content/Tile';
import { PowerSupply } from './PowerSupply';
import { secondsToTicks } from './Ticks';

export type Side = 'player' | 'enemy';

export class Room {
  /** Air from 0 to 100 percent; crew suffocate below a few percent (LifeSupport step). */
  oxygen = 100;
  constructor(readonly id: number, readonly tiles: Tile[]) {}
}

/** Systems that take no bars at all: they work as long as they aren't broken (the genre's subsystems). */
const UNPOWERED_SYSTEMS = new Set(['Piloting', 'Sensors', 'Doors', 'AZC']);   // the AZC is the source, not a drain

export class ShipSystem {
  readonly key: string;
  readonly name: string;
  readonly tile: Tile;
  readonly level: number;
  /** Bars one level is worth: shields are two to a level (GDD 8H), everything else one. */
  readonly barsPerLevel: number;
  /** Bars the ship's power supply has given it. Self-powered systems keep theirs (Mecha). */
  bars = 0;
  /** Damage points, up to the level; at the level the system is broken. */
  damage = 0;
  /** Repair progress toward the next damage point coming off, in ticks. */
  repairTicks = 0;
  /** Spores (the Sporewing) hold the system down until cleared like a repair. */
  spored = false;
  mannedBy?: Crew;

  constructor(placement: SystemPlacement, readonly selfPower?: number) {
    this.key = systemKey(placement);
    this.name = placement.name;
    this.tile = placement.tile;
    this.level = placement.level;
    this.barsPerLevel = placement.name === 'Shields' ? 2 : 1;
  }

  get needsPower(): boolean {
    return !UNPOWERED_SYSTEMS.has(this.name);
  }

  get maxBars(): number {
    return this.level * this.barsPerLevel;
  }

  /**
   * Bars the system can actually use right now: its own bars plus what an integrating crew member adds (the
   * Mecha, race profiles), never above its level (Decided 2026-10-23); damage takes levels away from the top.
   */
  get workingBars(): number {
    if (this.spored) return 0;
    const workingLevels = Math.max(0, this.level - this.damage);
    const integration = this.needsPower ? (this.mannedBy?.race.integrationBars ?? 0) : 0;
    return Math.min((this.selfPower ?? this.bars) + integration, workingLevels * this.barsPerLevel);
  }

  get isBroken(): boolean {
    return this.spored || this.damage >= this.level;
  }

  /** Working at all: a subsystem needs no bars, a powered system needs at least one. */
  get isWorking(): boolean {
    return !this.isBroken && (!this.needsPower || this.workingBars > 0);
  }
}

export class Door {
  open = false;
  constructor(readonly id: number, readonly tile: Tile, readonly facing: Direction, readonly airlock: boolean) {}
}

export class Crew {
  health = 100;
  /** The tiles still to walk, first next; empty when standing. */
  path: Tile[] = [];
  /** Ticks until the next step along the path. */
  stepTicks = 0;
  stunnedTicks = 0;

  constructor(readonly id: number, readonly name: string, readonly race: RaceDefinition, public tile: Tile) {}

  get isAlive(): boolean {
    return this.health > 0;
  }
}

export class Weapon {
  /** Charge in ticks, from 0 up to the ticks the definition needs. */
  chargeTicks = 0;
  /** The tile aimed at (GDD 3L): a shot lands on it and only the system on it takes system damage. */
  target?: { shipId: number; tile: Tile };
  /** Keep the target after a volley (the genre's autofire); otherwise one volley, then the target is let go. */
  autofire = false;
  /**
   * The player has given this weapon its bars (the genre's slot click). Damage to the weapon system takes them
   * back from the last slot first, and repair does not return them: the player powers the weapon again.
   */
  powered = false;
  /** Shots of the current volley still to leave, with the ticks until each. */
  volleyShotsLeft = 0;
  nextShotTicks = 0;

  constructor(readonly definition: WeaponDefinition, readonly mount: number, readonly chargeNeeded: number) {}

  get isCharged(): boolean {
    return this.chargeTicks >= this.chargeNeeded;
  }

  /** Bars the weapon needs from its weapon system. */
  get cost(): number {
    return this.definition.power;
  }
}

export class Ship {
  readonly name: string;
  readonly race: string;
  hullPoints: number;
  readonly hullMax: number;
  readonly rooms: Room[];
  readonly systems: ShipSystem[];
  readonly doors: Door[];
  readonly crew: Crew[];
  /** In slot order: the first is slot 1. The order is the player's (ReorderWeapons), not the mount number's. */
  readonly weapons: Weapon[];
  readonly power: PowerSupply;
  shieldLayers = 0;
  shieldRechargeTicks = 0;
  private readonly roomByTile = new Map<string, Room>();

  constructor(
    readonly id: number,
    readonly definition: ShipDefinition,
    readonly side: Side,
    weaponsByName: (name: string) => WeaponDefinition,
    raceByName: (name: string) => RaceDefinition,
    firstCrewId: number,
  ) {
    this.name = definition.name;
    this.race = definition.race;
    this.hullPoints = definition.hullPoints;
    this.hullMax = definition.hullPoints;
    this.rooms = definition.rooms.map((room) => new Room(room.id, tilesBetween(room.from, room.to, definition.centering)));
    for (const room of this.rooms) for (const tile of room.tiles) this.roomByTile.set(tileKey(tile), room);
    this.systems = definition.systems.map((placement) => new ShipSystem(placement, placement.selfPower));
    this.doors = definition.doors.map((door) => {
      const across = neighbourTile(door.tile, door.facing, definition.centering);
      return new Door(door.id, door.tile, door.facing, !this.roomByTile.has(tileKey(across)));
    });
    this.power = new PowerSupply(definition.power, this.systems);
    this.power.assignStartingBars();
    this.weapons = definition.weapons.map((weapon) => {
      const card = weaponsByName(weapon.name);
      // A weapon on another tech type's ship charges about 20% slower (GDD 8E; weapon-budget-table).
      const foreignTech = this.techType !== card.techType ? 1.2 : 1;
      return new Weapon(card, weapon.mount ?? 0, secondsToTicks(card.chargeSeconds * foreignTech));
    });
    this.powerStartingWeapons();
    this.crew = this.startingCrew(firstCrewId, raceByName);
  }

  /** The weapon systems: Weapons, the Mecha's Weapon Pod, and whatever a race adds with mounts (GDD 8L). */
  get weaponSystems(): ShipSystem[] {
    return this.systems.filter((system) => system.name === 'Weapons' || system.name === 'Weapon Pod');
  }

  /** The weapon system a weapon draws from: the one whose mounts list its mount, else the ship's first. */
  weaponSystemOf(weapon: Weapon): ShipSystem | undefined {
    const systems = this.weaponSystems;
    return systems.find((system) => this.definition.systems.find((placement) => systemKey(placement) === system.key)?.mounts?.includes(weapon.mount)) ?? systems[0];
  }

  /** A weapon system's weapons, in slot order. */
  weaponsOf(system: ShipSystem): Weapon[] {
    return this.weapons.filter((weapon) => this.weaponSystemOf(weapon) === system);
  }

  /** Bars a weapon system has given to its powered weapons so far. */
  barsUsedByWeapons(system: ShipSystem): number {
    return this.weaponsOf(system).filter((weapon) => weapon.powered).reduce((sum, weapon) => sum + weapon.cost, 0);
  }

  /** A ship starts a fight with its slots powered left to right while the system's bars last (genre). */
  private powerStartingWeapons(): void {
    for (const system of this.weaponSystems) {
      let barsLeft = system.workingBars;
      for (const weapon of this.weaponsOf(system)) {
        if (weapon.cost <= barsLeft) { weapon.powered = true; barsLeft -= weapon.cost; }
      }
    }
  }

  /** The ship's tech type by race (GDD 8D). Not in the docs yet: which races count as biomechanical; Terrans and Mecha are mechanical, the rest biomechanical. */
  get techType(): string {
    return this.race === 'Terran' || this.race === 'Mecha' ? 'Mechanical' : 'Biomechanical';
  }

  get isDestroyed(): boolean {
    return this.hullPoints <= 0;
  }

  get hasLivingCrew(): boolean {
    return this.crew.some((member) => member.isAlive);
  }

  /** Gone when blown up or when all crew are dead (GDD 1F). */
  get isGone(): boolean {
    return this.isDestroyed || !this.hasLivingCrew;
  }

  system(name: string): ShipSystem | undefined {
    return this.systems.find((system) => system.name === name);
  }

  systemByKey(key: string): ShipSystem | undefined {
    return this.systems.find((system) => system.key === key);
  }

  roomOfTile(tile: Tile): Room | undefined {
    return this.roomByTile.get(tileKey(tile));
  }

  room(id: number): Room | undefined {
    return this.rooms.find((room) => room.id === id);
  }

  /** The system whose console sits on this tile, if any. */
  systemOnTile(tile: Tile): ShipSystem | undefined {
    return this.systems.find((system) => sameTile(system.tile, tile));
  }

  systemsInRoom(room: Room): ShipSystem[] {
    return this.systems.filter((system) => room.tiles.some((tile) => sameTile(tile, system.tile)));
  }

  livingCrewInRoom(room: Room): Crew[] {
    return this.crew.filter((member) => member.isAlive && this.roomOfTile(member.tile) === room);
  }

  /** The door between two neighbouring tiles, if there is one. */
  doorBetween(from: Tile, to: Tile): Door | undefined {
    return this.doors.find((door) =>
      (sameTile(door.tile, from) && sameTile(neighbourTile(from, door.facing, this.definition.centering), to))
      || (sameTile(door.tile, to) && sameTile(neighbourTile(to, door.facing, this.definition.centering), from)));
  }

  /**
   * Starting crew stand on their systems' tiles in file order, then on free room tiles. Names are the race and a
   * number until the race name lists exist (production goals: no name lists yet).
   */
  private startingCrew(firstId: number, raceByName: (name: string) => RaceDefinition): Crew[] {
    const spots = [...this.systems.map((system) => system.tile), ...this.rooms.flatMap((room) => room.tiles)];
    const taken = new Set<string>();
    const crew: Crew[] = [];
    let id = firstId;
    for (const group of this.definition.crew) {
      for (let count = 1; count <= group.count; count++) {
        const spot = spots.find((tile) => !taken.has(tileKey(tile)));
        if (!spot) break;
        taken.add(tileKey(spot));
        crew.push(new Crew(id++, `${group.race} ${count}`, raceByName(group.race), spot));
      }
    }
    return crew;
  }
}
