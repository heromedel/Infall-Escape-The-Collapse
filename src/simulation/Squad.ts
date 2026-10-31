/**
 * A squad: a named list of live ships in slot order (the first is slot 1), with the one shared Mawjig pool
 * (GDD 4E, 8C). Enemy squads work the same way, so a fight is always squad against squad.
 */

import { Ship, Side } from './Ship';

export class Squad {
  readonly ships: Ship[] = [];

  constructor(readonly name: string, readonly side: Side, public mawjig: number) {}

  get livingShips(): Ship[] {
    return this.ships.filter((ship) => !ship.isGone);
  }

  /** Spends Mawjig from the pool when it can; a squad never goes below zero (GDD 8C: shots are paid for). */
  pay(amount: number): boolean {
    if (this.mawjig + 1e-9 < amount) return false;
    this.mawjig = Math.round((this.mawjig - amount) * 1000) / 1000;
    return true;
  }
}
