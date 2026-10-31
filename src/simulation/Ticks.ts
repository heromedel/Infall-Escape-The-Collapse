/**
 * The simulation's clock (GDD 3E, coding rule 13): 20 ticks a second, 0.05 s each. Every time in the reference
 * tables is written in seconds and converted here, once, so no other file does arithmetic on seconds.
 */

export const TICKS_PER_SECOND = 20;

export function secondsToTicks(seconds: number): number {
  return Math.max(1, Math.round(seconds * TICKS_PER_SECOND));
}

export function ticksToSeconds(ticks: number): number {
  return ticks / TICKS_PER_SECOND;
}
