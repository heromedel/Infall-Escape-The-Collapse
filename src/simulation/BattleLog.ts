/**
 * What the simulation has to say, collected per tick for the host to write to the real log (coding rule 10).
 * The simulation never writes files itself; it only records events with their tick.
 */

export interface BattleEvent {
  tick: number;
  name: string;
  fields: Record<string, string | number | boolean | undefined>;
}

export class BattleLog {
  readonly events: BattleEvent[] = [];
  tick = 0;

  event(name: string, fields: BattleEvent['fields'] = {}): void {
    this.events.push({ tick: this.tick, name, fields });
  }

  /** Hands over and clears the events recorded so far. */
  drain(): BattleEvent[] {
    return this.events.splice(0, this.events.length);
  }
}
