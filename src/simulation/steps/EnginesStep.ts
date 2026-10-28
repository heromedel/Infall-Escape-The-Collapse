/**
 * Evasion: the genre's chance to dodge a shot, from the engines' working bars, only while the ship is piloted
 * (Piloting working and manned) and the engines work; a manned engine room adds a little. The bar table is the
 * baseline's rough curve (docs/reference, the baseline table: about 5% a bar early, tapering to about 35% at the top).
 */

import { Ship } from '../Ship';

const EVASION_BY_ENGINE_BARS = [0, 5, 10, 15, 20, 25, 28, 31, 35];
const PILOT_MANNED_BONUS = 5;
const ENGINES_MANNED_BONUS = 5;

export function evasionPercent(ship: Ship): number {
  const piloting = ship.system('Piloting');
  const engines = ship.system('Engines');
  if (!piloting?.isWorking || !piloting.mannedBy || !engines?.isWorking) return 0;
  const bars = Math.min(engines.workingBars, EVASION_BY_ENGINE_BARS.length - 1);
  return EVASION_BY_ENGINE_BARS[bars] + PILOT_MANNED_BONUS + (engines.mannedBy ? ENGINES_MANNED_BONUS : 0);
}
