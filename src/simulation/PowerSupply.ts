/**
 * Hands bars to a ship's systems. The one place that knows the power models apart (coding rule 7: vanilla as a
 * setting, shared code):
 *   Reactor: a pool of bars shared out by the player, the genre's default.
 *   AZC: the Terran core. Until conduits are simulated it is a pool of 5 bars a level, the conversion the race
 *        profile gives for the conduits setting Off (race profiles, Terrans 6).
 *   SelfPowered: no pool; each system keeps the bars it brought (Mecha). SetPower does nothing to it.
 */

import { PowerSource } from './content/ShipDefinition';
import { ShipSystem } from './Ship';

const BARS_PER_AZC_LEVEL = 5;

/** The order systems take bars when a ship powers up and when the AI shares power: the genre's priorities. */
export const POWER_ORDER = ['Shields', 'Engines', 'Weapons', 'Weapon Pod', 'Life Support', 'Medbay', 'Crew Teleporter', 'Supershield Generator', 'EVB Dock'];

export class PowerSupply {
  readonly kind: PowerSource['kind'];
  readonly totalBars: number;

  constructor(source: PowerSource, private readonly systems: ShipSystem[]) {
    this.kind = source.kind;
    switch (source.kind) {
      case 'Reactor': this.totalBars = source.bars ?? 0; break;
      case 'AZC': this.totalBars = (source.level ?? 0) * BARS_PER_AZC_LEVEL; break;
      case 'SelfPowered': this.totalBars = systems.reduce((sum, system) => sum + (system.selfPower ?? 0), 0); break;
    }
  }

  get barsInUse(): number {
    if (this.kind === 'SelfPowered') return this.totalBars;
    return this.systems.filter((system) => system.needsPower).reduce((sum, system) => sum + system.bars, 0);
  }

  get barsFree(): number {
    return this.totalBars - this.barsInUse;
  }

  /** Powers the ship up as it starts a fight: each system in POWER_ORDER takes its full bars while the pool lasts. */
  assignStartingBars(): void {
    for (const name of POWER_ORDER) {
      for (const system of this.systems.filter((candidate) => candidate.name === name)) this.setBars(system, system.maxBars);
    }
  }

  /** Gives a system this many bars, as far as the pool and the system's level allow. Returns what it got. */
  setBars(system: ShipSystem, wanted: number): number {
    if (this.kind === 'SelfPowered' || !system.needsPower) return system.bars;
    const freeForIt = this.barsFree + system.bars;
    system.bars = Math.max(0, Math.min(wanted, system.maxBars, freeForIt));
    return system.bars;
  }
}
