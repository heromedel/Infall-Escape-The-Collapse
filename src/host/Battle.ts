/**
 * The host's side of a battle: builds a Simulation from loaded content, runs it headless to a result or tick by
 * tick, and writes the simulation's events to the real log with the tick in front. Step 5 drives this at
 * 20 ticks a second for the window; step 4 runs it straight through for the `fight` command and the tests.
 */

import { Simulation } from '../simulation/Simulation';
import { battleOrders } from '../simulation/BattleAI';
import { ContentLibrary } from './ContentLibrary';
import { Log } from './Log';
import { ticksToSeconds } from '../simulation/Ticks';

/** Mawjig each side starts a test battle with. Not in the docs yet: what a squad has when a run begins. */
const STARTING_MAWJIG = 10;
/** A fight nobody can win ends as a draw after this long, so a test never hangs. */
const LONGEST_BATTLE_SECONDS = 600;

export class Battle {
  readonly simulation: Simulation;

  constructor(content: ContentLibrary, private readonly log: Log, playerShip: string, enemyShip: string, seed: number) {
    this.simulation = new Simulation(seed, (name) => content.weapon(name), (name) => content.race(name));
    this.simulation.addSquad('Player squad', 'player', STARTING_MAWJIG, [content.ship(playerShip).definition]);
    this.simulation.addSquad('Enemy squad', 'enemy', STARTING_MAWJIG, [content.ship(enemyShip).definition]);
    log.event('battle.started', { player: playerShip, enemy: enemyShip, seed });
  }

  /** One tick with the AI steering both sides, events written to the log. */
  advanceOneTick(): void {
    for (const squad of this.simulation.squads) this.simulation.applyOrders(battleOrders(this.simulation, squad));
    this.simulation.advanceOneTick();
    for (const event of this.simulation.log.drain()) {
      this.log.event(`battle.${event.name}`, { tick: event.tick, seconds: ticksToSeconds(event.tick), ...event.fields });
    }
  }

  /** Runs to a result, or to the time limit. */
  runToResult(): { winner: string; reason: string; seconds: number } {
    const limit = LONGEST_BATTLE_SECONDS * 20;
    while (!this.simulation.result && this.simulation.tick < limit) this.advanceOneTick();
    const result = this.simulation.result ?? { winner: 'draw', reason: `nobody won in ${LONGEST_BATTLE_SECONDS} s` };
    return { ...result, seconds: ticksToSeconds(this.simulation.tick) };
  }
}
