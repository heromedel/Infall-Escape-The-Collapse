/**
 * Turns what the player does in the window into orders for the host (GDD 4B: the window never changes state
 * itself). Click a crew member then a tile: move. Click a weapon then an enemy room: target. Click a bar in the
 * ship panel: set power. Space: pause or unpause.
 */

import type { Order } from '../shared/Order';
import type { Snapshot, SnapshotShip } from '../shared/Snapshot';
import { BattleView } from './BattleView.js';

export class BattleControls {
  private selectedCrew?: { shipId: number; crewId: number };
  private selectedWeapon?: { shipId: number; mount: number };
  private latest?: Snapshot;
  paused = false;

  constructor(
    private readonly view: BattleView,
    private readonly viewport: SVGSVGElement,
    private readonly panel: HTMLElement,
    private readonly sendOrder: (order: Order) => void,
    private readonly sendPause: (paused: boolean) => void,
  ) {
    viewport.addEventListener('click', (event) => this.clicked(event));
    window.addEventListener('keydown', (event) => {
      if (event.key === ' ' && !(event.target instanceof HTMLInputElement)) { event.preventDefault(); this.sendPause(!this.paused); }
    });
  }

  /** Keeps the panel in step with the last snapshot. */
  update(snapshot: Snapshot): void {
    this.latest = snapshot;
    this.drawPanel();
  }

  private clicked(event: MouseEvent): void {
    const target = event.target as Element;
    const tile = target.closest('rect.tile') as SVGRectElement | null;
    const crewShape = target.closest('[data-crew-id]') as SVGElement | null;
    if (crewShape) {
      const shipId = Number(crewShape.dataset.shipId);
      if (!this.view.playerShipIds.includes(shipId)) return;
      this.selectedCrew = { shipId, crewId: Number(crewShape.dataset.crewId) };
      this.selectedWeapon = undefined;
      this.view.select(shipId);
      this.drawPanel();
      return;
    }
    if (!tile) return;
    const shipId = Number(tile.dataset.shipId);
    const isPlayerShip = this.view.playerShipIds.includes(shipId);
    if (this.selectedWeapon && !isPlayerShip) {
      this.sendOrder({ kind: 'TargetWeapon', shipId: this.selectedWeapon.shipId, mount: this.selectedWeapon.mount, targetShipId: shipId, targetRoomId: Number(tile.dataset.roomId) });
      this.selectedWeapon = undefined;
      this.drawPanel();
      return;
    }
    if (this.selectedCrew && isPlayerShip && this.selectedCrew.shipId === shipId) {
      this.sendOrder({ kind: 'MoveCrew', shipId, crewId: this.selectedCrew.crewId, tile: { x: Number(tile.dataset.x), y: Number(tile.dataset.y) } });
      this.selectedCrew = undefined;
      this.drawPanel();
      return;
    }
    if (isPlayerShip) { this.view.select(shipId); this.drawPanel(); }
  }

  /** The selected player ship's systems, weapons and crew (GDD 3B's per-ship panel, first form). */
  private drawPanel(): void {
    const snapshot = this.latest;
    const shipId = this.view.playerShipIds[0];
    const ship = snapshot?.squads.flatMap((squad) => squad.ships).find((candidate) => candidate.id === shipId);
    if (!snapshot || !ship) { this.panel.replaceChildren(); return; }
    this.panel.replaceChildren();
    this.panel.appendChild(this.heading(`${ship.name}: hull ${ship.hullPoints}/${ship.hullMax}, shields ${ship.shieldLayers}/${ship.shieldLayersMax}, evasion ${ship.evasionPercent}%, power ${ship.barsInUse}/${ship.barsTotal}${ship.powerKind === 'AZC' ? ' (AZC)' : ''}`));
    this.panel.appendChild(this.heading(`Mawjig ${snapshot.squads.find((squad) => squad.side === 'player')?.mawjig ?? 0}, ${snapshot.seconds.toFixed(1)} s${this.paused ? ', paused' : ''}`));
    this.panel.appendChild(this.systemsRows(ship));
    this.panel.appendChild(this.weaponsRows(ship));
    this.panel.appendChild(this.crewRows(ship));
    if (snapshot.result) this.panel.appendChild(this.heading(`Battle over: ${snapshot.result.winner} wins, ${snapshot.result.reason}.`));
  }

  private systemsRows(ship: SnapshotShip): HTMLElement {
    const box = document.createElement('div');
    box.className = 'rows';
    for (const system of ship.systems) {
      const row = document.createElement('div');
      row.className = 'row';
      const name = document.createElement('span');
      name.textContent = `${system.key}${system.damage > 0 ? ` (${system.damage} damage)` : ''}${system.mannedBy !== undefined ? ' manned' : ''}`;
      name.style.color = system.isWorking ? '' : '#FF3B3B';
      row.appendChild(name);
      const bars = document.createElement('span');
      bars.className = 'bars';
      for (let bar = 1; bar <= system.maxBars; bar++) {
        const pip = document.createElement('button');
        pip.className = bar <= system.bars ? 'bar on' : 'bar';
        pip.title = `${system.key}: ${bar} bar(s)`;
        pip.addEventListener('click', () => this.sendOrder({ kind: 'SetPower', shipId: ship.id, systemKey: system.key, bars: bar === system.bars ? bar - 1 : bar }));
        bars.appendChild(pip);
      }
      row.appendChild(bars);
      box.appendChild(row);
    }
    return box;
  }

  private weaponsRows(ship: SnapshotShip): HTMLElement {
    const box = document.createElement('div');
    box.className = 'rows';
    for (const weapon of ship.weapons) {
      const row = document.createElement('button');
      const selected = this.selectedWeapon?.shipId === ship.id && this.selectedWeapon.mount === weapon.mount;
      row.className = `weapon${selected ? ' selected' : ''}${weapon.powered ? '' : ' unpowered'}`;
      const target = weapon.target ? `target ship ${weapon.target.shipId} room ${weapon.target.roomId}` : 'no target';
      row.textContent = `${weapon.name} (mount ${weapon.mount}): ${Math.round(weapon.charge * 100)}% ${target}`;
      row.style.backgroundImage = `linear-gradient(90deg, #2f6b4f ${weapon.charge * 100}%, transparent ${weapon.charge * 100}%)`;
      row.addEventListener('click', () => { this.selectedWeapon = selected ? undefined : { shipId: ship.id, mount: weapon.mount }; this.selectedCrew = undefined; this.drawPanel(); });
      box.appendChild(row);
    }
    return box;
  }

  private crewRows(ship: SnapshotShip): HTMLElement {
    const box = document.createElement('div');
    box.className = 'rows';
    for (const member of ship.crew) {
      const row = document.createElement('button');
      const selected = this.selectedCrew?.shipId === ship.id && this.selectedCrew.crewId === member.id;
      row.className = `crew${selected ? ' selected' : ''}`;
      row.textContent = `${member.name}: ${member.health} health${member.walking ? ', walking' : ''}${member.stunned ? ', stunned' : ''}`;
      row.addEventListener('click', () => { this.selectedCrew = selected ? undefined : { shipId: ship.id, crewId: member.id }; this.selectedWeapon = undefined; this.drawPanel(); });
      box.appendChild(row);
    }
    return box;
  }

  private heading(text: string): HTMLElement {
    const line = document.createElement('div');
    line.className = 'heading';
    line.textContent = text;
    return line;
  }
}
