/**
 * The host runs a battle for its clients: a client's order changes the next snapshot, pause stops ticks, and
 * every client gets the battle's pictures when it joins.
 */

import { describe, expect, it } from 'vitest';
import * as path from 'node:path';
import { Host } from '../src/host/Host';
import { Battle } from '../src/host/Battle';
import { ContentLibrary } from '../src/host/ContentLibrary';
import { Log } from '../src/host/Log';
import { Settings } from '../src/host/Settings';
import type { ClientConnection } from '../src/host/ClientConnection';
import type { ClientToHost, HostToClient } from '../src/shared/Messages';

const log = Log.open(path.join(__dirname, '..', 'logs', 'tests'));
const content = ContentLibrary.load(path.join(__dirname, '..', 'content'), log);

/** A stand-in client that remembers what it was sent and lets the test speak for it. */
class FakeClient implements ClientConnection {
  readonly name = 'test client';
  readonly received: HostToClient[] = [];
  private listener?: (message: ClientToHost) => void;
  send(message: HostToClient): void { this.received.push(message); }
  onMessage(listener: (message: ClientToHost) => void): void { this.listener = listener; }
  say(message: ClientToHost): void { this.listener?.(message); }
  lastSnapshot() { return [...this.received].reverse().find((message) => message.kind === 'Snapshot') as Extract<HostToClient, { kind: 'Snapshot' }> | undefined; }
}

function hostWithBattle() {
  const settings = new Settings();
  const host = new Host(log, settings);
  const client = new FakeClient();
  host.connect(client);
  const battle = new Battle(content, log, settings, 'SC-1 Outrider', 'Light Attack Frame', 5);
  host.startBattle(battle);
  battle.simulation; // the clock is running; tests drive ticks by hand too
  return { host, client, battle, settings };
}

describe('the host', () => {
  it('sends the battle pictures when it starts and a snapshot each tick', () => {
    const { host, client } = hostWithBattle();
    expect(client.received[0].kind).toBe('BattleStarted');
    host.tick();
    host.tick();
    expect(client.received.filter((message) => message.kind === 'Snapshot')).toHaveLength(2);
    expect(client.lastSnapshot()!.snapshot.tick).toBe(2);
  });
  it('applies a client order on the next tick', () => {
    const { host, client } = hostWithBattle();
    const playerShipId = (client.received[0] as Extract<HostToClient, { kind: 'BattleStarted' }>).playerShipIds[0];
    client.say({ kind: 'Order', order: { kind: 'SetPower', shipId: playerShipId, systemKey: 'Shields', bars: 2 } });
    host.tick();
    const ship = client.lastSnapshot()!.snapshot.squads[0].ships[0];
    expect(ship.systems.find((system) => system.key === 'Shields')!.bars).toBe(2);
  });
  it('stops ticking while paused and tells every client', () => {
    const { host, client } = hostWithBattle();
    host.tick();
    client.say({ kind: 'Pause' });
    host.tick();
    host.tick();
    expect(client.lastSnapshot()!.snapshot.tick).toBe(1);
    expect(client.received.some((message) => message.kind === 'Paused' && message.paused)).toBe(true);
    client.say({ kind: 'Unpause' });
    host.tick();
    expect(client.lastSnapshot()!.snapshot.tick).toBe(2);
  });
  it('auto pauses every interval when Turn Mode asks (GDD 4I)', () => {
    const { host, client, settings } = hostWithBattle();
    settings.autoPause = true;
    settings.autoPauseIntervalTicks = 3;
    for (let i = 0; i < 6; i++) host.tick();
    expect(host.paused).toBe(true);
    expect(client.lastSnapshot()!.snapshot.tick).toBe(3);
  });
});
