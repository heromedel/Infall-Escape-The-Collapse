/**
 * Shields each tick: one layer per two working bars (GDD 8H), a lost layer comes back after about two seconds
 * (the genre's rate), a manned shield room recharges a little faster.
 */

import { Ship } from '../Ship';
import { secondsToTicks } from '../Ticks';

const RECHARGE_TICKS = secondsToTicks(2.0);
const MANNED_SPEEDUP = 1.1;

export function shieldLayersMax(ship: Ship): number {
  const shields = ship.system('Shields');
  return shields?.isWorking ? Math.floor(shields.workingBars / 2) : 0;
}

export function shieldsStep(ship: Ship): void {
  const max = shieldLayersMax(ship);
  if (ship.shieldLayers > max) ship.shieldLayers = max;
  if (ship.shieldLayers >= max) { ship.shieldRechargeTicks = 0; return; }
  const manned = ship.system('Shields')?.mannedBy ? MANNED_SPEEDUP : 1;
  ship.shieldRechargeTicks += manned;
  if (ship.shieldRechargeTicks >= RECHARGE_TICKS) {
    ship.shieldRechargeTicks = 0;
    ship.shieldLayers++;
  }
}
