/**
 * Crew each tick: walk along their path, man the system on the tile they stand on, and repair damage in their
 * room. Fighting waits for boarding (not in Goal P). Numbers are the genre's (GDD 1C); where the baseline tables
 * have none they are from memory of the genre and listed in the step 4 report.
 */

import { sameTile } from '../content/Tile';
import { Crew, Ship } from '../Ship';
import { secondsToTicks } from '../Ticks';
import { BattleLog } from '../BattleLog';

/** Walking speed: a tile every half second. */
const TICKS_PER_STEP = secondsToTicks(0.5);
/** Repairing one damage point takes about six seconds for one crew member; more crew repair in parallel. */
const TICKS_PER_REPAIR_POINT = secondsToTicks(6);

export function crewStep(ship: Ship, log: BattleLog): void {
  for (const system of ship.systems) system.mannedBy = undefined;
  for (const member of ship.crew) {
    if (!member.isAlive) continue;
    if (member.stunnedTicks > 0) { member.stunnedTicks--; continue; }
    walk(member);
    man(ship, member);
    repair(ship, member, log);
  }
}

function walk(member: Crew): void {
  if (member.path.length === 0) return;
  if (member.stepTicks > 0) { member.stepTicks--; return; }
  member.tile = member.path.shift()!;
  member.stepTicks = TICKS_PER_STEP;
}

/** Standing still on a system's tile mans it; one crew member per system, the first to be there. */
function man(ship: Ship, member: Crew): void {
  if (member.path.length > 0) return;
  const system = ship.systems.find((candidate) => sameTile(candidate.tile, member.tile));
  if (system && !system.mannedBy) system.mannedBy = member;
}

/** Standing in a room with a damaged or spored system repairs it, the most damaged first. */
function repair(ship: Ship, member: Crew, log: BattleLog): void {
  if (member.path.length > 0) return;
  const room = ship.roomOfTile(member.tile);
  if (!room) return;
  const damaged = ship.systemsInRoom(room).filter((system) => system.damage > 0 || system.spored)
    .sort((a, b) => b.damage - a.damage)[0];
  if (!damaged) return;
  damaged.repairTicks++;
  if (damaged.repairTicks < TICKS_PER_REPAIR_POINT) return;
  damaged.repairTicks = 0;
  if (damaged.spored) damaged.spored = false;
  else damaged.damage--;
  log.event('repair', { ship: ship.name, crew: member.name, system: damaged.key, damageLeft: damaged.damage });
}
