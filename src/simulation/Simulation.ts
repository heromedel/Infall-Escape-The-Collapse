/**
 * One battle, advanced a tick at a time (GDD 3E). Read `tick()` top to bottom for the order things happen in.
 * Orders come in through `applyOrders`; the window and the LAN send the same ones. Nothing here touches a file,
 * a window or a clock: the host calls tick() twenty times a second (Ticks.ts).
 */

import { ShipDefinition } from './content/ShipDefinition';
import { WeaponDefinition } from './content/WeaponDefinition';
import { RaceDefinition } from './content/RaceDefinition';
import { Order } from './Order';
import { Ship, Side } from './Ship';
import { Squad } from './Squad';
import { Shot } from './Shot';
import { RandomSource } from './RandomSource';
import { BattleLog } from './BattleLog';
import { findPath } from './CrewPathing';
import { crewStep } from './steps/CrewStep';
import { lifeSupportStep } from './steps/LifeSupportStep';
import { shieldsStep, shieldLayersMax } from './steps/ShieldsStep';
import { evasionPercent } from './steps/EnginesStep';
import { weaponsStep, poweredWeapons } from './steps/WeaponsStep';
import { secondsToTicks, ticksToSeconds } from './Ticks';
import type { Snapshot, SnapshotShip } from '../shared/Snapshot';

/**
 * The off-screen distance between the squads (GDD 3Q), in GATO Meters: a shot crosses it unseen, one GM a
 * millisecond, after 0.3 s on screen leaving and before 0.3 s on screen arriving. 400 GM is a one-second flight.
 */
export const DEFAULT_DISTANCE_GM = 400;
export const ON_SCREEN_FLIGHT_SECONDS = 0.3;

export interface BattleResult {
  winner: Side | 'draw';
  reason: string;
}

export class Simulation {
  tick = 0;
  readonly squads: Squad[] = [];
  readonly shots: Shot[] = [];
  readonly log = new BattleLog();
  readonly random: RandomSource;
  result?: BattleResult;
  private readonly pendingOrders: Order[] = [];
  private nextShipId = 1;
  private nextCrewId = 1;
  private nextShotId = 1;

  constructor(
    seed: number,
    private readonly weaponsByName: (name: string) => WeaponDefinition,
    private readonly raceByName: (name: string) => RaceDefinition,
    readonly distanceGm: number = DEFAULT_DISTANCE_GM,
  ) {
    this.random = new RandomSource(seed);
  }

  /** Ticks a shot takes from its mount to the target: on screen out, the gap, on screen in. */
  get shotFlightTicks(): number {
    return secondsToTicks(2 * ON_SCREEN_FLIGHT_SECONDS + this.distanceGm / 1000);
  }

  addSquad(name: string, side: Side, mawjig: number, ships: ShipDefinition[]): Squad {
    const squad = new Squad(name, side, mawjig);
    for (const definition of ships) {
      const ship = new Ship(this.nextShipId++, definition, side, this.weaponsByName, this.raceByName, this.nextCrewId);
      this.nextCrewId += ship.crew.length;
      squad.ships.push(ship);
    }
    this.squads.push(squad);
    return squad;
  }

  /** Queues orders for the next tick. */
  applyOrders(orders: Order[]): void {
    this.pendingOrders.push(...orders);
  }

  /**
   * Carries out orders now, without a tick passing: an order given while paused takes effect at once (the genre
   * lets the player set power, aim and send crew while paused), and the next tick simply finds it done.
   */
  applyOrdersNow(orders: Order[]): void {
    this.pendingOrders.push(...orders);
    if (!this.result) this.carryOutOrders();
  }

  /** One tick of battle, in this order. */
  advanceOneTick(): void {
    if (this.result) return;
    this.tick++;
    this.log.tick = this.tick;
    this.carryOutOrders();
    for (const squad of this.squads) {
      for (const ship of squad.livingShips) {
        crewStep(ship, this.log);
        lifeSupportStep(ship, this.log);
        shieldsStep(ship);
        weaponsStep(ship, squad, this.shots, this.shotFlightTicks, () => this.nextShotId++, this.log);
      }
    }
    this.flyShots();
    this.checkForResult();
  }

  ship(id: number): Ship | undefined {
    for (const squad of this.squads) for (const ship of squad.ships) if (ship.id === id) return ship;
    return undefined;
  }

  snapshot(): Snapshot {
    return {
      tick: this.tick,
      seconds: ticksToSeconds(this.tick),
      distanceGm: this.distanceGm,
      squads: this.squads.map((squad) => ({
        side: squad.side, name: squad.name, mawjig: squad.mawjig, ships: squad.ships.map((ship) => this.snapshotShip(ship)),
      })),
      shots: this.shots.map((shot) => ({
        id: shot.id, weaponName: shot.weapon.name, type: shot.weapon.type, fromShipId: shot.fromShipId,
        toShipId: shot.toShipId, toRoomId: shot.toRoomId, progress: shot.progress,
      })),
      result: this.result,
    };
  }

  // ---- the tick's parts -----------------------------------------------------------------------------------

  private carryOutOrders(): void {
    for (const order of this.pendingOrders.splice(0)) {
      const ship = this.ship(order.shipId);
      if (!ship || ship.isGone) continue;
      switch (order.kind) {
        case 'SetPower': {
          const system = ship.systemByKey(order.systemKey);
          if (system) ship.power.setBars(system, order.bars);
          break;
        }
        case 'TargetWeapon': {
          const weapon = ship.weapons.find((candidate) => candidate.mount === order.mount);
          const target = this.ship(order.targetShipId);
          if (weapon && target && target.room(order.targetRoomId)) weapon.target = { shipId: order.targetShipId, roomId: order.targetRoomId };
          break;
        }
        case 'ClearTarget': {
          const weapon = ship.weapons.find((candidate) => candidate.mount === order.mount);
          if (weapon) weapon.target = undefined;
          break;
        }
        case 'MoveCrew': {
          const member = ship.crew.find((candidate) => candidate.id === order.crewId);
          if (member?.isAlive) member.path = findPath(ship, member.tile, order.tile);
          break;
        }
        case 'ToggleDoor': {
          const door = ship.doors.find((candidate) => candidate.id === order.doorId);
          if (door) door.open = !door.open;
          break;
        }
      }
    }
  }

  private flyShots(): void {
    for (let index = this.shots.length - 1; index >= 0; index--) {
      const shot = this.shots[index];
      if (shot.fly(this.ship(shot.toShipId), this.random, this.log)) this.shots.splice(index, 1);
    }
  }

  /** A side loses when all its ships are gone (GDD 1F). Both at once is a draw. */
  private checkForResult(): void {
    const alive = this.squads.filter((squad) => squad.livingShips.length > 0);
    if (alive.length === this.squads.length) return;
    if (alive.length === 0) this.result = { winner: 'draw', reason: 'every ship on both sides is gone' };
    else {
      const loser = this.squads.find((squad) => squad.livingShips.length === 0)!;
      this.result = { winner: alive[0].side, reason: `every ship of ${loser.name} is gone` };
    }
    this.log.event('battle_over', { winner: this.result.winner, reason: this.result.reason, seconds: ticksToSeconds(this.tick) });
  }

  private snapshotShip(ship: Ship): SnapshotShip {
    const powered = poweredWeapons(ship);
    return {
      id: ship.id, name: ship.name, race: ship.race, side: ship.side,
      hullPoints: ship.hullPoints, hullMax: ship.hullMax,
      shieldLayers: ship.shieldLayers, shieldLayersMax: shieldLayersMax(ship),
      evasionPercent: evasionPercent(ship),
      powerKind: ship.power.kind, barsTotal: ship.power.totalBars, barsInUse: ship.power.barsInUse,
      isGone: ship.isGone,
      rooms: ship.rooms.map((room) => ({ id: room.id, oxygen: Math.round(room.oxygen) })),
      systems: ship.systems.map((system) => ({
        key: system.key, name: system.name, level: system.level, damage: system.damage,
        bars: system.selfPower ?? system.bars, maxBars: system.needsPower ? system.maxBars : 0, isWorking: system.isWorking, spored: system.spored,
        mannedBy: system.mannedBy?.id,
      })),
      doors: ship.doors.map((door) => ({ id: door.id, open: door.open })),
      crew: ship.crew.map((member) => ({
        id: member.id, name: member.name, race: member.race.name, health: Math.round(member.health),
        x: member.tile.x, y: member.tile.y, walking: member.path.length > 0, stunned: member.stunnedTicks > 0,
      })),
      weapons: ship.weapons.map((weapon) => ({
        name: weapon.definition.name, mount: weapon.mount, charge: weapon.chargeTicks / weapon.chargeNeeded,
        powered: powered.has(weapon), target: weapon.target,
      })),
    };
  }
}
