/**
 * Air each tick (GDD 8B: Life Support is the genre's oxygen system). A working Life Support refills every room;
 * without it rooms slowly lose air; an open airlock empties its room fast; air moves between rooms through open
 * doors; crew in airless rooms lose health.
 */

import { neighbourTile } from '../content/Tile';
import { Ship } from '../Ship';
import { TICKS_PER_SECOND } from '../Ticks';
import { BattleLog } from '../BattleLog';

/** Percent of air a second: refill per Life Support bar, loss with none, loss through an open airlock. */
const REFILL_PER_BAR = 1.5 / TICKS_PER_SECOND;
const LOSS_WITHOUT_SUPPORT = 1.0 / TICKS_PER_SECOND;
const LOSS_THROUGH_AIRLOCK = 40 / TICKS_PER_SECOND;
/** Air moving through an open door between rooms, as a share of their difference each second. */
const DOOR_MIXING = 2.0 / TICKS_PER_SECOND;
/** Below this much air crew suffocate, at this much health a second (the genre's rate). */
const SUFFOCATION_BELOW = 5;
const SUFFOCATION_PER_SECOND = 6.4;

export function lifeSupportStep(ship: Ship, log: BattleLog): void {
  const support = ship.system('Life Support');
  const bars = support?.isWorking ? support.workingBars : 0;
  for (const room of ship.rooms) {
    room.oxygen += bars > 0 ? REFILL_PER_BAR * bars : -LOSS_WITHOUT_SUPPORT;
  }
  for (const door of ship.doors) {
    if (!door.open) continue;
    const room = ship.roomOfTile(door.tile)!;
    const across = ship.roomOfTile(neighbourTile(door.tile, door.facing, ship.definition.centering));
    if (door.airlock || !across) room.oxygen -= LOSS_THROUGH_AIRLOCK;
    else {
      const flow = (across.oxygen - room.oxygen) * DOOR_MIXING;
      room.oxygen += flow;
      across.oxygen -= flow;
    }
  }
  for (const room of ship.rooms) room.oxygen = Math.max(0, Math.min(100, room.oxygen));

  for (const member of ship.crew) {
    if (!member.isAlive) continue;
    const room = ship.roomOfTile(member.tile);
    if (room && room.oxygen < SUFFOCATION_BELOW) {
      member.health -= SUFFOCATION_PER_SECOND / TICKS_PER_SECOND;
      if (!member.isAlive) log.event('crew_died', { ship: ship.name, crew: member.name, cause: 'suffocation' });
    }
  }
}
