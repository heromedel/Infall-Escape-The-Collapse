/**
 * Turns what the player does in the window into orders for the host (GDD 4B: the window never changes state
 * itself) and keeps the selection the player is working with: which ship, which weapon is armed, which crew
 * member is picked. Orders go to the host at once, paused or not; the host answers with a snapshot. The look
 * follows the genre: click a system's icon to add a bar, right click to take one away; click a weapon (or its
 * number key) to arm it, then an enemy room; click a crew member, then a tile; click a door to toggle it; space
 * pauses; Escape drops the selection. The cursor and the status line always say what the next click will do.
 * Fire mode is the genre's: Autofire (the V key or its button) is the default, and holding Ctrl at the room click
 * gives that target the opposite; red marks autofire, yellow fire once (docs/reference/genre-battle-screen).
 */

import type { Order } from '../shared/Order';
import type { Look } from '../shared/Messages';
import type { ShipPicture } from '../shared/ShipPicture';
import type { Snapshot, SnapshotShip } from '../shared/Snapshot';
import { BattleView } from './BattleView.js';
import { ShipPanel } from './ShipPanel.js';
import { BattleHud } from './BattleHud.js';

export class BattleControls {
  paused = false;
  private selectedShipId?: number;
  private armedMount?: number;
  private selectedCrewId?: number;
  private latest?: Snapshot;
  private pictures: Record<number, ShipPicture> = {};
  private panels = new Map<number, ShipPanel>();
  private floating = true;
  /** The fire mode weapons get without Ctrl (Settings: Autofire; the V key flips it for this battle). */
  private autofire = false;
  private ctrlHeld = false;
  /** Set when a drag just ended, so the click that follows it is not an order. */
  private swallowNextClick = false;
  private readonly hud: BattleHud;

  constructor(
    private readonly view: BattleView,
    private readonly viewport: SVGSVGElement,
    hudSurface: SVGSVGElement,
    private readonly dock: SVGSVGElement,
    private readonly sendOrder: (order: Order) => void,
    private readonly sendPause: (paused: boolean) => void,
  ) {
    this.hud = new BattleHud(hudSurface);
    for (const surface of [viewport, hudSurface, dock]) {
      surface.addEventListener('click', (event) => this.clicked(event));
      surface.addEventListener('contextmenu', (event) => { event.preventDefault(); this.rightClicked(event); });
    }
    viewport.addEventListener('pointerover', (event) => this.hovered(event));
    this.listenForSlotDrags(hudSurface);
    window.addEventListener('keydown', (event) => this.keyPressed(event));
    window.addEventListener('keyup', (event) => { if (event.key === 'Control') this.setCtrl(false); });
    window.addEventListener('blur', () => this.setCtrl(false));
  }

  /** A new battle: forget the old selection and panels, select the first player ship. */
  start(pictures: Record<number, ShipPicture>, playerShipIds: number[], look: Look): void {
    this.pictures = pictures;
    this.panels.clear();
    this.hud.clear();
    this.latest = undefined;
    this.armedMount = undefined;
    this.selectedCrewId = undefined;
    this.setLook(look);
    this.selectShip(playerShipIds[0]);
  }

  /** The look settings, at the start and whenever they change. */
  setLook(look: Look): void {
    this.floating = look.battleGui === 'floating';
    this.autofire = look.autofire;
    this.view.targetLines = look.targetLines;
    this.refresh();
  }

  /** The mode the next room click would give: the default, or the opposite while Ctrl is held. */
  get aimMode(): 'auto' | 'once' {
    return this.autofire !== this.ctrlHeld ? 'auto' : 'once';
  }

  /** Pause state from the host, shown by the GUI. */
  setPaused(paused: boolean): void {
    this.paused = paused;
    this.refresh();
  }

  /** Keeps the panel and the view in step with the last snapshot. */
  update(snapshot: Snapshot): void {
    this.latest = snapshot;
    this.refresh();
  }

  get selectedShip(): number | undefined {
    return this.selectedShipId;
  }

  // ---- what the player did ---------------------------------------------------------------------------------

  private clicked(event: MouseEvent): void {
    if (this.swallowNextClick) { this.swallowNextClick = false; return; }
    const target = event.target as Element;
    const action = target.closest('[data-action]') as SVGElement | null;
    if (action) { this.panelClicked(action); return; }
    const crewShape = target.closest('[data-crew-id]') as SVGElement | null;
    if (crewShape?.dataset.shipId) {
      const shipId = Number(crewShape.dataset.shipId);
      if (!this.view.playerShipIds.includes(shipId)) return;
      this.selectShip(shipId);
      this.selectedCrewId = Number(crewShape.dataset.crewId);
      this.armedMount = undefined;
      this.refresh();
      return;
    }
    const door = target.closest('rect.door') as SVGRectElement | null;
    if (door?.dataset.shipId && this.view.playerShipIds.includes(Number(door.dataset.shipId))) {
      this.sendOrder({ kind: 'ToggleDoor', shipId: Number(door.dataset.shipId), doorId: Number(door.dataset.doorId) });
      return;
    }
    const tile = target.closest('rect.tile') as SVGRectElement | null;
    if (!tile) return;
    const shipId = Number(tile.dataset.shipId);
    const isPlayerShip = this.view.playerShipIds.includes(shipId);
    if (this.armedMount !== undefined && this.selectedShipId !== undefined && !isPlayerShip) {
      this.sendOrder({ kind: 'TargetWeapon', shipId: this.selectedShipId, mount: this.armedMount, targetShipId: shipId, targetRoomId: Number(tile.dataset.roomId), autofire: this.aimMode === 'auto' });
      this.armedMount = undefined;
      this.refresh();
      return;
    }
    if (this.selectedCrewId !== undefined && isPlayerShip && this.selectedShipId === shipId) {
      this.sendOrder({ kind: 'MoveCrew', shipId, crewId: this.selectedCrewId, tile: { x: Number(tile.dataset.x), y: Number(tile.dataset.y) } });
      this.selectedCrewId = undefined;
      this.refresh();
      return;
    }
    if (isPlayerShip && shipId !== this.selectedShipId) { this.selectShip(shipId); this.refresh(); }
  }

  /** Right click while aiming cancels the aim and clears that weapon's target; on a system it takes a bar off. */
  private rightClicked(event: MouseEvent): void {
    const action = (event.target as Element).closest('[data-action]') as SVGElement | null;
    const ship = this.ship();
    if (ship && this.armedMount !== undefined) {
      this.sendOrder({ kind: 'ClearTarget', shipId: ship.id, mount: this.armedMount });
      this.clearSelection();
      return;
    }
    if (action && ship) {
      if (action.dataset.action === 'power') {
        const system = ship.systems.find((candidate) => candidate.key === action.dataset.systemKey);
        if (system && system.bars > 0) this.sendOrder({ kind: 'SetPower', shipId: ship.id, systemKey: system.key, bars: system.bars - 1 });
        return;
      }
      if (action.dataset.action === 'weapon') {
        this.sendOrder({ kind: 'DepowerWeapon', shipId: ship.id, mount: Number(action.dataset.mount) });
        return;
      }
    }
    this.clearSelection();
  }

  private panelClicked(action: SVGElement): void {
    const ship = this.ship();
    if (!ship) return;
    switch (action.dataset.action) {
      case 'power': {
        const system = ship.systems.find((candidate) => candidate.key === action.dataset.systemKey);
        if (system && system.bars < system.maxBars) this.sendOrder({ kind: 'SetPower', shipId: ship.id, systemKey: system.key, bars: system.bars + 1 });
        break;
      }
      case 'weapon': {
        const mount = Number(action.dataset.mount);
        const weapon = ship.weapons.find((candidate) => candidate.mount === mount);
        // a dark slot is powered first (the genre's slot click); a lit one is armed
        if (weapon && !weapon.powered) this.sendOrder({ kind: 'PowerWeapon', shipId: ship.id, mount });
        else this.armWeapon(mount);
        break;
      }
      case 'autofire': this.autofire = !this.autofire; this.refresh(); break;
      case 'crew': {
        const crewId = Number(action.dataset.crewId);
        this.selectedCrewId = this.selectedCrewId === crewId ? undefined : crewId;
        this.armedMount = undefined;
        this.refresh();
        break;
      }
    }
  }

  private keyPressed(event: KeyboardEvent): void {
    if (event.target instanceof HTMLInputElement) return;
    if (event.key === ' ') { event.preventDefault(); this.sendPause(!this.paused); return; }
    if (event.key === 'Escape') { this.clearSelection(); return; }
    if (event.key === 'Control') { this.setCtrl(true); return; }
    if (event.key === 'v' || event.key === 'V') { this.autofire = !this.autofire; this.refresh(); return; }
    const ship = this.ship();
    const number = Number(event.code.startsWith('Digit') ? event.code.slice(5) : event.key);
    if (!ship || !(number >= 1 && number <= ship.weapons.length)) return;
    const weapon = ship.weapons[number - 1];
    if (event.shiftKey) { this.sendOrder({ kind: 'DepowerWeapon', shipId: ship.id, mount: weapon.mount }); return; }
    if (!weapon.powered) { this.sendOrder({ kind: 'PowerWeapon', shipId: ship.id, mount: weapon.mount }); return; }
    this.armWeapon(weapon.mount);
  }

  private hovered(event: PointerEvent): void {
    const tile = (event.target as Element).closest('rect.tile') as SVGRectElement | null;
    if (tile && this.armedMount !== undefined && tile.classList.contains('enemy')) this.view.hoverRoom(Number(tile.dataset.shipId), Number(tile.dataset.roomId));
    else this.view.hoverRoom(undefined, undefined);
  }

  /** Dragging a weapon slot onto another reorders the weapons (the genre's drag to rearrange). */
  private listenForSlotDrags(hud: SVGSVGElement): void {
    let dragged: { mount: number; x: number; y: number } | undefined;
    let moved = false;
    hud.addEventListener('pointerdown', (event) => {
      if (event.button !== 0) return;
      const slot = (event.target as Element).closest('[data-action="weapon"]') as SVGElement | null;
      if (!slot) return;
      dragged = { mount: Number(slot.dataset.mount), x: event.clientX, y: event.clientY };
      moved = false;
    });
    window.addEventListener('pointermove', (event) => {
      if (!dragged || moved) return;
      if (Math.abs(event.clientX - dragged.x) + Math.abs(event.clientY - dragged.y) > 8) { moved = true; document.body.classList.add('dragging-slot'); }
    });
    window.addEventListener('pointerup', (event) => {
      if (!dragged) return;
      const from = dragged;
      dragged = undefined;
      document.body.classList.remove('dragging-slot');
      if (!moved) return;
      this.swallowNextClick = true;
      const under = document.elementFromPoint(event.clientX, event.clientY)?.closest('[data-action="weapon"]') as SVGElement | null;
      const ship = this.ship();
      if (!under || !ship) return;
      const toMount = Number(under.dataset.mount);
      const slot = ship.weapons.findIndex((weapon) => weapon.mount === toMount);
      if (toMount !== from.mount && slot >= 0) this.sendOrder({ kind: 'ReorderWeapons', shipId: ship.id, mount: from.mount, slot });
    });
  }

  private setCtrl(held: boolean): void {
    if (this.ctrlHeld === held) return;
    this.ctrlHeld = held;
    this.refresh();
  }

  // ---- selection ------------------------------------------------------------------------------------------

  private armWeapon(mount: number): void {
    this.armedMount = this.armedMount === mount ? undefined : mount;
    this.selectedCrewId = undefined;
    this.refresh();
  }

  private clearSelection(): void {
    this.armedMount = undefined;
    this.selectedCrewId = undefined;
    this.view.hoverRoom(undefined, undefined);
    this.refresh();
  }

  private selectShip(shipId: number | undefined): void {
    this.selectedShipId = shipId;
    this.armedMount = undefined;
    this.selectedCrewId = undefined;
    this.view.select(shipId);
  }

  private ship(): SnapshotShip | undefined {
    return this.latest?.squads.flatMap((squad) => squad.ships).find((candidate) => candidate.id === this.selectedShipId);
  }

  /** Redraws the GUI and the cursor hints from the latest snapshot and the selection. */
  private refresh(): void {
    const ship = this.ship();
    document.body.classList.toggle('armed', this.armedMount !== undefined);
    document.body.classList.toggle('aim-auto', this.armedMount !== undefined && this.aimMode === 'auto');
    document.body.classList.toggle('aim-once', this.armedMount !== undefined && this.aimMode === 'once');
    document.body.classList.toggle('crew-selected', this.selectedCrewId !== undefined);
    document.body.classList.toggle('gui-card', !this.floating);
    const selection = { armedMount: this.armedMount, selectedCrewId: this.selectedCrewId, aimMode: this.aimMode, autofire: this.autofire };
    if (this.latest) this.hud.update(this.latest, this.floating ? ship : undefined, ship && this.pictures[ship.id], selection, this.paused, ship ? this.statusText(ship) : '');
    if (!ship || this.floating) { this.dock.replaceChildren(); return; }
    let panel = this.panels.get(ship.id);
    if (!panel) { panel = new ShipPanel(ship, this.pictures[ship.id]); this.panels.set(ship.id, panel); }
    panel.update(ship, selection);
    panel.root.setAttribute('transform', 'translate(8 6)');
    if (panel.root.parentNode !== this.dock) this.dock.replaceChildren(panel.root);
  }

  private statusText(ship: SnapshotShip): string {
    const armed = ship.weapons.find((weapon) => weapon.mount === this.armedMount);
    if (armed) return `${armed.name} armed: click an enemy room to ${this.aimMode === 'auto' ? 'keep firing at it (autofire)' : 'fire once'}. Ctrl gives the opposite, right click cancels.`;
    const crew = ship.crew.find((member) => member.id === this.selectedCrewId);
    if (crew) return `${crew.name} selected: click a tile on ${ship.name} to send them there.`;
    if (this.latest?.result) return `Battle over: ${this.latest.result.winner} wins, ${this.latest.result.reason}.`;
    return `${ship.name}. Click a system to power it, a weapon or its number to arm it, a crew member to move them.`;
  }
}
