/**
 * Fires the host's tick 20 times a second on the real clock (Ticks.ts). If the machine stalls, at most a few
 * ticks are caught up at once and the rest are dropped, so a long pause never runs a whole fight in a burst.
 */

import { TICKS_PER_SECOND } from '../simulation/Ticks';

const TICK_MILLISECONDS = 1000 / TICKS_PER_SECOND;
const MOST_TICKS_CAUGHT_UP = 4;

export class TickClock {
  private timer?: NodeJS.Timeout;
  private due = 0;

  constructor(private readonly onTick: () => void) {}

  start(): void {
    if (this.timer) return;
    this.due = Date.now();
    this.timer = setInterval(() => this.catchUp(), TICK_MILLISECONDS / 2);
  }

  stop(): void {
    if (this.timer) clearInterval(this.timer);
    this.timer = undefined;
  }

  get isRunning(): boolean {
    return this.timer !== undefined;
  }

  private catchUp(): void {
    const now = Date.now();
    let ticks = 0;
    while (this.due <= now && ticks < MOST_TICKS_CAUGHT_UP) {
      this.onTick();
      this.due += TICK_MILLISECONDS;
      ticks++;
    }
    if (this.due <= now) this.due = now;   // too far behind: drop the rest rather than burst
  }
}
