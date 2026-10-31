/**
 * The host's side of a battle: builds a Simulation from loaded content, runs it headless to a result or tick by
 * tick, and writes the simulation's events to the real log with the tick in front. Step 5 drives this at
 * 20 ticks a second for the window; step 4 runs it straight through for the `fight` command and the tests.
 */

import { Simulation } from '../simulation/Simulation';
import { battleOrders } from '../simulation/BattleAI';
import { Order } from '../simulation/Order';
import { Squad } from '../simulation/Squad';
import { ContentLibrary } from './ContentLibrary';
import { Log } from './Log';
import { Settings } from './Settings';
import { shipPictureOf } from './ShipPicture';
import { ticksToSeconds } from '../simulation/Ticks';
import type { HostToClient } from '../shared/Messages';
import type { ShipPicture } from '../shared/ShipPicture';

/** Mawjig each side starts a test battle with. Not in the docs yet: what a squad has when a run begins. */
const STARTING_MAWJIG = 10;
/** A fight nobody can win ends as a draw after this long, so a test never hangs. */
const LONGEST_BATTLE_SECONDS = 600;

export class Battle {
  readonly simulation: Simulation;

  constructor(
    private readonly content: ContentLibrary, private readonly log: Log, private readonly settings: Settings,
    playerShips: string | string[], enemyShips: string | string[], seed: number, distanceGm?: number,
  ) {
    const player = [playerShips].flat();
    const enemy = [enemyShips].flat();
    this.simulation = new Simulation(seed, (name) => content.weapon(name), (name) => content.race(name), distanceGm);
    this.simulation.addSquad('Player squad', 'player', STARTING_MAWJIG, player.map((name) => content.ship(name).definition));
    this.simulation.addSquad('Enemy squad', 'enemy', STARTING_MAWJIG, enemy.map((name) => content.ship(name).definition));
    log.event('battle.started', { player: player.join(' + '), enemy: enemy.join(' + '), seed });
  }

  /** What a client needs once to draw the battle: every ship's picture, and which ships are the player's. */
  startMessage(): HostToClient {
    const pictures: Record<number, ShipPicture> = {};
    for (const squad of this.simulation.squads) {
      for (const ship of squad.ships) pictures[ship.id] = shipPictureOf(this.content.ship(ship.name), squad.side, this.content, this.settings);
    }
    const playerShipIds = this.simulation.squads.filter((squad) => squad.side === 'player').flatMap((squad) => squad.ships.map((ship) => ship.id));
    return { kind: 'BattleStarted', pictures, playerShipIds, formations: { player: this.content.formation(this.settings.playerFormation), enemy: this.content.formation(this.settings.enemyFormation) }, projectiles: this.content.projectileArt(), look: { battleGui: this.settings.battleGui, autofire: this.settings.autofire, targetLines: this.settings.targetLines, shotsCrossingBarrier: this.settings.shotsCrossingBarrier, showZones: this.settings.showZones } };
  }

  /**
   * One tick, with whoever steers each squad giving its orders: the AI for both sides when run headless, the AI
   * for the enemy only under the host. Events are written to the log.
   */
  advanceOneTick(ordersFor: (squad: Squad) => Order[] = (squad) => battleOrders(this.simulation, squad)): void {
    for (const squad of this.simulation.squads) this.simulation.applyOrders(ordersFor(squad));
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
