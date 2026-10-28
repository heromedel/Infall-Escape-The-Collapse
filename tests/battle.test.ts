/**
 * The simulation fights: the Outrider against the Light Attack Frame runs to a result, the same seed gives the
 * same fight, shields stop lasers and missiles pass them, and crew walk through doors but not walls.
 */

import { describe, expect, it } from 'vitest';
import * as fs from 'node:fs';
import * as path from 'node:path';
import { ShipFileReader } from '../src/simulation/content/ShipFileReader';
import { WeaponFileReader } from '../src/simulation/content/WeaponFileReader';
import { Simulation } from '../src/simulation/Simulation';
import { battleOrders } from '../src/simulation/BattleAI';
import { findPath } from '../src/simulation/CrewPathing';
import { Shot } from '../src/simulation/Shot';
import { RandomSource } from '../src/simulation/RandomSource';
import { BattleLog } from '../src/simulation/BattleLog';
import { secondsToTicks } from '../src/simulation/Ticks';
import { readRaceDefinition, DEFAULT_RACE } from '../src/simulation/content/RaceDefinition';
import { DEFAULT_DISTANCE_GM } from '../src/simulation/Simulation';

const contentFolder = path.join(__dirname, '..', 'content');
const shipReader = new ShipFileReader();
const weaponReader = new WeaponFileReader();

const weapons = new Map(fs.readdirSync(path.join(contentFolder, 'weapons')).map((folder) => {
  const weapon = weaponReader.readWeapon(fs.readFileSync(path.join(contentFolder, 'weapons', folder, 'weapon.xml'), 'utf8'));
  return [weapon.name, weapon];
}));
const weaponsByName = (name: string) => { const w = weapons.get(name); if (!w) throw new Error(name); return w; };
const races = new Map(fs.readdirSync(path.join(contentFolder, 'races')).map((folder) => {
  const race = readRaceDefinition(fs.readFileSync(path.join(contentFolder, 'races', folder, 'race.xml'), 'utf8'));
  return [race.name, race];
}));
const raceByName = (name: string) => races.get(name) ?? { ...DEFAULT_RACE, name };
const shipFile = (folder: string) => shipReader.readShip(fs.readFileSync(path.join(contentFolder, 'ships', folder, 'ship.xml'), 'utf8'));

function fight(seed: number): Simulation {
  const simulation = new Simulation(seed, weaponsByName, raceByName);
  simulation.addSquad('Player', 'player', 10, [shipFile('outrider')]);
  simulation.addSquad('Enemy', 'enemy', 10, [shipFile('light-attack-frame')]);
  while (!simulation.result && simulation.tick < secondsToTicks(600)) {
    for (const squad of simulation.squads) simulation.applyOrders(battleOrders(simulation, squad));
    simulation.advanceOneTick();
  }
  return simulation;
}

describe('a battle', () => {
  it('runs the Outrider against the Light Attack Frame to a result', () => {
    const simulation = fight(7);
    expect(simulation.result).toBeDefined();
    expect(simulation.result!.winner).toBe('player');
    expect(simulation.tick).toBeGreaterThan(secondsToTicks(10));
    expect(simulation.log.events.some((event) => event.name === 'shot_hit')).toBe(true);
  });
  it('replays the same fight from the same seed', () => {
    const first = fight(42);
    const second = fight(42);
    expect(second.tick).toBe(first.tick);
    expect(second.snapshot()).toEqual(first.snapshot());
    expect(fight(43).snapshot()).not.toEqual(first.snapshot());
  });
  it('powers the Outrider as an AZC of 5 bars a level and the Mecha frame from its own bars', () => {
    const simulation = fight(1);
    const [outrider, frame] = simulation.squads.map((squad) => squad.ships[0]);
    expect(outrider.power.totalBars).toBe(10);
    expect(frame.power.kind).toBe('SelfPowered');
    expect(frame.system('Shields')!.workingBars).toBeLessThanOrEqual(2);
  });
  it('lets a Mecha crew member power the weapon pod up to its level by integrating', () => {
    // The pod has one bar of its own and the laser needs two; an integrating HalfMech makes up the second.
    const simulation = new Simulation(1, weaponsByName, raceByName);
    const squad = simulation.addSquad('Enemy', 'enemy', 10, [shipFile('light-attack-frame')]);
    const frame = squad.ships[0];
    const pod = frame.system('Weapon Pod')!;
    expect(pod.workingBars).toBe(1);
    for (let ticks = 0; ticks < secondsToTicks(10); ticks++) {
      simulation.applyOrders(battleOrders(simulation, squad));
      simulation.advanceOneTick();
    }
    expect(pod.mannedBy?.race.name).toBe('Mecha');
    expect(pod.workingBars).toBe(2);
    expect(simulation.snapshot().squads[0].ships[0].weapons[0].powered).toBe(true);
  });
});

describe('fire modes (the genre: autofire keeps the target, fire once lets it go)', () => {
  function aimedFight(autofire: boolean): { simulation: Simulation; weapon: () => { target?: unknown } } {
    const simulation = new Simulation(3, weaponsByName, raceByName);
    simulation.addSquad('Player', 'player', 10, [shipFile('outrider')]);
    simulation.addSquad('Enemy', 'enemy', 10, [shipFile('light-attack-frame')]);
    const player = simulation.squads[0].ships[0];
    const enemy = simulation.squads[1].ships[0];
    const gat = player.weapons[0];
    simulation.applyOrders([{ kind: 'TargetWeapon', shipId: player.id, mount: gat.mount, targetShipId: enemy.id, targetRoomId: enemy.rooms[0].id, autofire }]);
    // charge, fire the whole volley and a little more
    for (let tick = 0; tick < gat.chargeNeeded + secondsToTicks(2); tick++) simulation.advanceOneTick();
    return { simulation, weapon: () => gat };
  }
  it('fire once: the target is let go after the volley', () => {
    const { weapon } = aimedFight(false);
    expect(weapon().target).toBeUndefined();
  });
  it('autofire: the target stays after the volley', () => {
    const { weapon } = aimedFight(true);
    expect(weapon().target).toBeDefined();
  });
});

describe('per-weapon power (the genre: slots take bars from the reactor into the weapon system)', () => {
  function outriderFight() {
    const simulation = new Simulation(4, weaponsByName, raceByName);
    simulation.addSquad('Player', 'player', 10, [shipFile('outrider')]);
    simulation.addSquad('Enemy', 'enemy', 10, [shipFile('light-attack-frame')]);
    const ship = simulation.squads[0].ships[0];
    const weaponsSystem = ship.system('Weapons')!;
    const [gat, missile] = ship.weapons;   // Gat 3.1 (2 bars) in slot 1, Gat M1 (1 bar) in slot 2, Weapons level 3
    return { simulation, ship, weaponsSystem, gat, missile };
  }
  const tick = (simulation: Simulation) => simulation.advanceOneTick();

  it('starts with slots powered left to right while the bars last', () => {
    const { gat, missile, weaponsSystem } = outriderFight();
    expect(gat.powered && missile.powered).toBe(true);
    expect(weaponsSystem.bars).toBe(3);
  });
  it('example 2: damage knocks out the last slot first and its bars go back to the reactor; the player then swaps', () => {
    const { simulation, ship, weaponsSystem, gat, missile } = outriderFight();
    const freeBefore = ship.power.barsFree;
    weaponsSystem.damage = 1;   // 2 working bars for 3 bars of weapons
    tick(simulation);
    expect(gat.powered).toBe(true);
    expect(missile.powered).toBe(false);
    expect(weaponsSystem.bars).toBe(2);
    expect(ship.power.barsFree).toBe(freeBefore + 1);
    // the player depowers the laser and powers the missile with the room that frees
    simulation.applyOrders([{ kind: 'DepowerWeapon', shipId: ship.id, mount: gat.mount }, { kind: 'PowerWeapon', shipId: ship.id, mount: missile.mount }]);
    tick(simulation);
    expect(gat.powered).toBe(false);
    expect(missile.powered).toBe(true);
    expect(weaponsSystem.bars).toBe(1);
    // repair gives nothing back by itself
    weaponsSystem.damage = 0;
    tick(simulation);
    expect(gat.powered).toBe(false);
    expect(weaponsSystem.bars).toBe(1);
  });
  it('refuses to power a weapon the damaged system has no room for', () => {
    const { simulation, ship, weaponsSystem, gat, missile } = outriderFight();
    weaponsSystem.damage = 1;
    tick(simulation);
    simulation.applyOrders([{ kind: 'PowerWeapon', shipId: ship.id, mount: missile.mount }]);
    tick(simulation);
    expect(missile.powered).toBe(false);
    expect(gat.powered).toBe(true);
  });
  it('example 1: a dragged weapon changes which slot goes offline first', () => {
    const { simulation, ship, weaponsSystem, gat, missile } = outriderFight();
    simulation.applyOrders([{ kind: 'ReorderWeapons', shipId: ship.id, mount: missile.mount, slot: 0 }]);
    weaponsSystem.damage = 1;
    tick(simulation);
    expect(ship.weapons[0]).toBe(missile);
    expect(missile.powered).toBe(true);
    expect(gat.powered).toBe(false);
  });
  it('an unpowered weapon keeps its charge, losing it slowly, and resumes from there', () => {
    const { simulation, ship, gat } = outriderFight();
    const enemy = simulation.squads[1].ships[0];
    simulation.applyOrders([{ kind: 'TargetWeapon', shipId: ship.id, mount: gat.mount, targetShipId: enemy.id, targetRoomId: enemy.rooms[0].id, autofire: true }]);
    for (let i = 0; i < 40; i++) tick(simulation);
    const charged = gat.chargeTicks;
    expect(charged).toBeGreaterThan(30);
    simulation.applyOrders([{ kind: 'DepowerWeapon', shipId: ship.id, mount: gat.mount }]);
    for (let i = 0; i < 10; i++) tick(simulation);
    expect(gat.chargeTicks).toBe(charged - 10);
    simulation.applyOrders([{ kind: 'PowerWeapon', shipId: ship.id, mount: gat.mount }]);
    for (let i = 0; i < 10; i++) tick(simulation);
    expect(gat.chargeTicks).toBeGreaterThan(charged - 10);
  });
});

describe('the distance between the squads (GDD 3Q)', () => {
  it('makes a shot fly longer at a longer distance, 1 GM a millisecond plus the on-screen parts', () => {
    const near = new Simulation(1, weaponsByName, raceByName, 400);
    const far = new Simulation(1, weaponsByName, raceByName, 2400);
    expect(near.distanceGm).toBe(DEFAULT_DISTANCE_GM);
    expect(near.shotFlightTicks).toBe(secondsToTicks(1.0));
    expect(far.shotFlightTicks).toBe(secondsToTicks(3.0));
  });
});

describe('shots', () => {
  const simulation = new Simulation(3, weaponsByName, raceByName);
  const squad = simulation.addSquad('Enemy', 'enemy', 10, [shipFile('outrider')]);
  const target = squad.ships[0];
  const log = new BattleLog();
  const noDodge = { chance: () => false } as unknown as RandomSource;
  const room = target.roomOfTile(target.system('Shields')!.tile)!;

  it('a laser takes a shield layer instead of the hull', () => {
    target.shieldLayers = 1;
    const laser = new Shot(1, weaponsByName('Gat 3.1'), 9, target.id, room.id, 1);
    laser.fly(target, noDodge, log);
    expect(target.shieldLayers).toBe(0);
    expect(target.hullPoints).toBe(30);
  });
  it('a missile passes shields and damages hull, the system in the room and the crew there', () => {
    target.shieldLayers = 1;
    const crewBefore = target.livingCrewInRoom(room).map((member) => member.health);
    const missile = new Shot(2, weaponsByName('Gat M1'), 9, target.id, room.id, 1);
    missile.fly(target, noDodge, log);
    expect(target.shieldLayers).toBe(1);
    expect(target.hullPoints).toBe(29);
    expect(target.system('Shields')!.damage).toBe(1);
    expect(target.livingCrewInRoom(room).map((member) => member.health)).toEqual(crewBefore.map((health) => health - 15));
  });
});

describe('crew pathing', () => {
  const simulation = new Simulation(5, weaponsByName, raceByName);
  const ship = simulation.addSquad('Player', 'player', 10, [shipFile('outrider')]).ships[0];
  it('walks from the bridge to the engine room through the doors', () => {
    const path = findPath(ship, { x: 0, y: -6 }, { x: 0, y: 6 });
    expect(path.length).toBeGreaterThan(10);
    expect(path.at(-1)).toEqual({ x: 0, y: 6 });
  });
  it('finds no path through a wall into space', () => {
    expect(findPath(ship, { x: 0, y: -6 }, { x: 4, y: 4 })).toEqual([]);
  });
});
