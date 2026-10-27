/**
 * The host owns the running game (GDD 4B): the battle, the tick clock, the pause state and the clients. A
 * client's order is carried out the moment it arrives, paused or not, and every client sees it in a fresh
 * snapshot; each tick then adds the AI's orders, advances the simulation and sends a snapshot. Read `tick()` for
 * the order. The host's own window is a client like any LAN client.
 */

import { Order } from '../simulation/Order';
import { battleOrders } from '../simulation/BattleAI';
import { ticksToSeconds } from '../simulation/Ticks';
import type { ClientToHost, HostToClient } from '../shared/Messages';
import { Battle } from './Battle';
import { ClientConnection } from './ClientConnection';
import { TickClock } from './TickClock';
import { Log } from './Log';
import { Settings } from './Settings';

export class Host {
  battle?: Battle;
  paused = false;
  private readonly clients: ClientConnection[] = [];
  private readonly clock = new TickClock(() => this.tick());
  private ticksSinceAutoPause = 0;

  constructor(private readonly log: Log, private readonly settings: Settings) {}

  connect(client: ClientConnection): void {
    this.clients.push(client);
    client.onMessage((message) => this.receive(client, message));
    this.log.event('host.client_connected', { client: client.name });
    if (this.battle) client.send(this.battle.startMessage());
  }

  /** Starts a battle on the clock, telling every client what to draw. */
  startBattle(battle: Battle): void {
    this.battle = battle;
    this.paused = false;
    this.ticksSinceAutoPause = 0;
    this.sendAll(battle.startMessage());
    this.clock.start();
  }

  /** Tells every client the look settings changed, so the window can switch without a new battle. */
  announceLook(): void {
    this.sendAll({ kind: 'Look', look: { battleGui: this.settings.battleGui } });
  }

  /** Pause Control (GDD 4H): Captain mode, so any client of the host's own window pauses. Who asked is logged. */
  setPaused(paused: boolean, by: string): void {
    if (this.paused === paused) return;
    this.paused = paused;
    this.log.event('host.paused', { paused, by });
    this.sendAll({ kind: 'Paused', paused, by });
  }

  /** One tick on the real clock, also usable by tests without the clock. */
  tick(): void {
    const battle = this.battle;
    if (!battle || this.paused || battle.simulation.result) return;
    battle.advanceOneTick((squad) => squad.side === 'enemy' ? battleOrders(battle.simulation, squad) : []);
    this.sendAll({ kind: 'Snapshot', snapshot: battle.simulation.snapshot() });
    this.autoPauseIfDue();
    if (battle.simulation.result) this.endBattle();
  }

  private receive(client: ClientConnection, message: ClientToHost): void {
    switch (message.kind) {
      case 'Order': this.carryOut(message.order); break;
      case 'Pause': this.setPaused(true, client.name); break;
      case 'Unpause': this.setPaused(false, client.name); break;
    }
  }

  /** An order takes effect at once, so a paused game still answers the player; everyone sees the result. */
  private carryOut(order: Order): void {
    const battle = this.battle;
    if (!battle || battle.simulation.result) return;
    const fields = order.kind === 'MoveCrew' ? { kind: order.kind, shipId: order.shipId, crewId: order.crewId, x: order.tile.x, y: order.tile.y } : order;
    this.log.event('host.order', { ...fields, paused: this.paused });
    battle.simulation.applyOrdersNow([order]);
    this.sendAll({ kind: 'Snapshot', snapshot: battle.simulation.snapshot() });
  }

  /** Turn Mode's auto pause (GDD 4I): every N ticks when it is on. */
  private autoPauseIfDue(): void {
    if (!this.settings.autoPause) return;
    this.ticksSinceAutoPause++;
    if (this.ticksSinceAutoPause >= this.settings.autoPauseIntervalTicks) {
      this.ticksSinceAutoPause = 0;
      this.setPaused(true, 'auto pause');
    }
  }

  private endBattle(): void {
    const result = this.battle!.simulation.result!;
    this.clock.stop();
    this.log.event('host.battle_ended', { winner: result.winner, reason: result.reason, seconds: ticksToSeconds(this.battle!.simulation.tick) });
    this.sendAll({ kind: 'BattleEnded', winner: result.winner, reason: result.reason });
  }

  private sendAll(message: HostToClient): void {
    for (const client of this.clients) client.send(message);
  }
}
