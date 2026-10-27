/**
 * Draws a running battle from what the host sends: each ship's picture once, then a snapshot every tick. Player
 * squad at the bottom, enemy at the top (GDD 3A), the divider between them standing for the off-screen distance
 * (GDD 3Q). Holds no game state: everything drawn comes from the last snapshot.
 */

import type { ShipPicture } from '../shared/ShipPicture';
import type { Snapshot, SnapshotShip, SnapshotShot } from '../shared/Snapshot';
import { ShipDrawing } from './ShipDrawing.js';
import { formationSlots, FormationSettings } from './Formation.js';

const SVG = 'http://www.w3.org/2000/svg';
/** Space between the front line of each squad and the divider: the off-screen gap's on-screen edge. */
const ROW_GAP = 120;
/** Room above a ship's art for its tag: name, hull bar and shield pips, drawn at screen scale. */
const LABEL_SPACE = 64;
const TAG = { width: 170, height: 34 };
const LOOK = {
  divider: '#4a6a8a',
  hullBar: '#66FF66',
  hullBarLow: '#FF3B3B',
  barBack: '#1d2a3a',
  shieldPip: '#4F8FFF',
  shieldPipEmpty: '#263445',
  laser: '#FFE066',
  missile: '#FF8500',
  damagedSymbol: '#FF3B3B',
  selected: '#FFFFFF',
  targetLine: '#FF3B3B',
};

/** One ship on screen: its drawing, where it sits, and its live overlays. */
interface PlacedShip {
  id: number;
  picture: ShipPicture;
  drawing: ShipDrawing;
  group: SVGGElement;
  offsetX: number;
  offsetY: number;
  /** The footprint's edges around the tile grid, for placing things beside the ship. */
  print: { width: number; height: number; left: number; top: number };
  hullBar: SVGRectElement;
  shieldPips: SVGCircleElement[];
  /** The screen-scale tag above the ship. */
  tag: SVGGElement;
  tileByCoordinate: Map<string, { column: number; row: number }>;
}

export class BattleView {
  readonly root: SVGGElement;
  readonly ships = new Map<number, PlacedShip>();
  playerShipIds: number[] = [];
  private readonly shotsGroup: SVGGElement;
  private readonly targetsGroup: SVGGElement;
  /** The ring under the selected ship. */
  private readonly selectionRing: SVGRectElement;
  private zoom = 1;
  private dividerY = 0;
  private width = 0;
  private height = 0;
  private selectedShipId?: number;

  constructor() {
    this.root = document.createElementNS(SVG, 'g');
    this.shotsGroup = document.createElementNS(SVG, 'g');
    this.targetsGroup = document.createElementNS(SVG, 'g');
    this.selectionRing = document.createElementNS(SVG, 'rect');
    this.selectionRing.setAttribute('rx', '14');
    this.selectionRing.setAttribute('fill', 'rgba(102, 255, 102, 0.07)');
    this.selectionRing.setAttribute('stroke', 'rgba(102, 255, 102, 0.75)');
    this.selectionRing.setAttribute('stroke-width', '2');
    this.selectionRing.setAttribute('pointer-events', 'none');
    this.selectionRing.setAttribute('visibility', 'hidden');
  }

  /** Lays both squads out from their pictures, each in its formation curve facing the divider (GDD 3H). */
  start(pictures: Record<number, ShipPicture>, playerShipIds: number[], formation: FormationSettings): void {
    this.root.replaceChildren();
    this.ships.clear();
    this.playerShipIds = playerShipIds;
    const enemy = Object.entries(pictures).filter(([id]) => !playerShipIds.includes(Number(id)));
    const player = Object.entries(pictures).filter(([id]) => playerShipIds.includes(Number(id)));
    const enemyLayout = formationSlots(enemy.map(([, picture]) => footprint(picture)), 'down', formation);
    const playerLayout = formationSlots(player.map(([, picture]) => footprint(picture)), 'up', formation);
    this.width = Math.max(enemyLayout.width, playerLayout.width);
    const enemyHeight = enemyLayout.height;
    this.dividerY = enemyHeight + ROW_GAP / 2;
    this.height = enemyHeight + ROW_GAP + playerLayout.height;

    const divider = document.createElementNS(SVG, 'line');
    divider.setAttribute('x1', '0'); divider.setAttribute('x2', String(this.width));
    divider.setAttribute('y1', String(this.dividerY)); divider.setAttribute('y2', String(this.dividerY));
    divider.setAttribute('stroke', LOOK.divider); divider.setAttribute('stroke-dasharray', '8 8');
    this.root.appendChild(divider);
    this.root.appendChild(this.selectionRing);   // under the ships

    this.placeSquad(enemy, enemyLayout.slots, (this.width - enemyLayout.width) / 2, 0);
    this.placeSquad(player, playerLayout.slots, (this.width - playerLayout.width) / 2, enemyHeight + ROW_GAP);
    this.root.appendChild(this.targetsGroup);
    this.root.appendChild(this.shotsGroup);
    this.rescaleTags();
  }

  size(): { width: number; height: number } {
    return { width: this.width, height: this.height };
  }

  /** The camera moved or zoomed: the tags keep their screen size. */
  setZoom(zoom: number): void {
    this.zoom = zoom;
    this.rescaleTags();
  }

  /** Tags keep screen size until neighbours would overlap; then they shrink to the ship's pitch. */
  private rescaleTags(): void {
    for (const placed of this.ships.values()) {
      const grid = ShipDrawing.sizeOf(placed.picture);
      const scale = Math.min(1 / this.zoom, (placed.print.width + 50) / TAG.width);
      const x = placed.offsetX + grid.width / 2 - (TAG.width / 2) * scale;
      const y = placed.offsetY - placed.print.top + LABEL_SPACE - TAG.height * scale;
      placed.tag.setAttribute('transform', `translate(${x} ${y}) scale(${scale})`);
    }
  }

  /** Where a ship's tile grid sits on the battle, for the camera. */
  shipBox(shipId: number): { x: number; y: number; width: number; height: number } | undefined {
    const placed = this.ships.get(shipId);
    if (!placed) return undefined;
    return { x: placed.offsetX - placed.print.left, y: placed.offsetY - placed.print.top, width: placed.print.width, height: placed.print.height };
  }

  /** Marks every tile of a room as hovered (so a whole room lights up under the pointer), or none. */
  hoverRoom(shipId: number | undefined, roomId: number | undefined): void {
    this.root.querySelectorAll('rect.tile.hover-room').forEach((tile) => tile.classList.remove('hover-room'));
    if (shipId === undefined || roomId === undefined) return;
    this.root.querySelectorAll(`rect.tile[data-ship-id="${shipId}"][data-room-id="${roomId}"]`).forEach((tile) => tile.classList.add('hover-room'));
  }

  /** Redraws everything that moves from the snapshot. */
  update(snapshot: Snapshot): void {
    for (const squad of snapshot.squads) {
      for (const ship of squad.ships) {
        const placed = this.ships.get(ship.id);
        if (placed) this.updateShip(placed, ship);
      }
    }
    this.drawShots(snapshot);
    this.drawTargets(snapshot);
  }

  /** The selected ship gets a ring under its hull (heromedel, 2026-10-27). */
  select(shipId: number | undefined): void {
    this.selectedShipId = shipId;
    const box = shipId === undefined ? undefined : this.shipBox(shipId);
    if (!box) { this.selectionRing.setAttribute('visibility', 'hidden'); return; }
    const pad = 10;
    this.selectionRing.setAttribute('x', String(box.x - pad)); this.selectionRing.setAttribute('y', String(box.y + LABEL_SPACE - pad));
    this.selectionRing.setAttribute('width', String(box.width + 2 * pad)); this.selectionRing.setAttribute('height', String(box.height - LABEL_SPACE + 2 * pad));
    this.selectionRing.setAttribute('visibility', 'visible');
  }

  /** The room's rectangle on the battle, for reticles. */
  private roomBox(placed: PlacedShip, roomId: number): { x: number; y: number; width: number; height: number } | undefined {
    const room = placed.picture.rooms.find((candidate) => candidate.id === roomId);
    if (!room) return undefined;
    const size = placed.picture.tileSize;
    return { x: placed.offsetX + room.column * size, y: placed.offsetY + room.row * size, width: room.width * size, height: room.height * size };
  }

  /** The selected ship's aimed weapons: a line to the target room and a box around it (GDD 3L: any enemy ship). */
  private drawTargets(snapshot: Snapshot): void {
    this.targetsGroup.replaceChildren();
    const ship = snapshot.squads.flatMap((squad) => squad.ships).find((candidate) => candidate.id === this.selectedShipId);
    const from = ship && this.ships.get(ship.id);
    if (!ship || !from) return;
    ship.weapons.forEach((weapon, index) => {
      if (!weapon.target) return;
      const to = this.ships.get(weapon.target.shipId);
      const box = to && this.roomBox(to, weapon.target.roomId);
      if (!to || !box) return;
      const grid = ShipDrawing.sizeOf(from.picture);
      const start = { x: from.offsetX + grid.width * (index + 1) / (ship.weapons.length + 1), y: from.offsetY - from.print.top + from.print.height - grid.height / 2 };
      const line = document.createElementNS(SVG, 'line');
      line.setAttribute('x1', String(start.x)); line.setAttribute('y1', String(start.y));
      line.setAttribute('x2', String(box.x + box.width / 2)); line.setAttribute('y2', String(box.y + box.height / 2));
      line.setAttribute('stroke', LOOK.targetLine); line.setAttribute('stroke-width', '1.5'); line.setAttribute('stroke-dasharray', '6 4');
      line.setAttribute('opacity', '0.8'); line.setAttribute('pointer-events', 'none');
      this.targetsGroup.appendChild(line);
      const reticle = this.rect(box.x + 2, box.y + 2, box.width - 4, box.height - 4, 'none');
      reticle.setAttribute('stroke', LOOK.targetLine); reticle.setAttribute('stroke-width', '2'); reticle.setAttribute('pointer-events', 'none');
      this.targetsGroup.appendChild(reticle);
    });
  }

  /** The screen position (in battle pixels) of a ship's tile centre, for shots. */
  private tileCentre(placed: PlacedShip, roomId: number): { x: number; y: number } {
    const tiles = placed.picture.floorTiles.filter((tile) => tile.roomId === roomId);
    const tile = tiles[0] ?? placed.picture.floorTiles[0];
    const size = placed.picture.tileSize;
    return { x: placed.offsetX + tile.column * size + size / 2, y: placed.offsetY + tile.row * size + size / 2 };
  }

  private placeSquad(row: [string, ShipPicture][], slots: { x: number; y: number }[], startX: number, startY: number): void {
    row.forEach(([idText, picture], index) => {
      const id = Number(idText);
      const drawing = new ShipDrawing();
      drawing.draw(picture);
      const print = footprint(picture);
      // the tile grid sits inside its footprint: past the art's overhang on the left, and below the labels and overhang on top
      const gridX = startX + slots[index].x + print.left;
      const gridY = startY + slots[index].y + print.top;
      const group = document.createElementNS(SVG, 'g');
      group.setAttribute('transform', `translate(${gridX} ${gridY})`);
      group.dataset.shipId = String(id);
      group.appendChild(drawing.root);
      // the tag: name, hull bar and shield pips, kept at screen scale by rescaleTags
      const tag = document.createElementNS(SVG, 'g');
      tag.setAttribute('pointer-events', 'none');
      const name = document.createElementNS(SVG, 'text');
      name.setAttribute('x', String(TAG.width / 2)); name.setAttribute('y', '12'); name.setAttribute('text-anchor', 'middle');
      name.setAttribute('font-size', '12'); name.setAttribute('font-family', 'system-ui, sans-serif'); name.setAttribute('fill', '#cfd6e2'); name.textContent = picture.name;
      tag.appendChild(name);
      tag.appendChild(this.rect(0, 18, TAG.width, 8, LOOK.barBack));
      const hullBar = this.rect(0, 18, TAG.width, 8, LOOK.hullBar);
      tag.appendChild(hullBar);
      const shieldPips: SVGCircleElement[] = [];
      for (let pip = 0; pip < 4; pip++) {
        const circle = document.createElementNS(SVG, 'circle');
        circle.setAttribute('cx', String(TAG.width - 6 - pip * 12)); circle.setAttribute('cy', '10'); circle.setAttribute('r', '4');
        circle.setAttribute('fill', LOOK.shieldPipEmpty);
        tag.appendChild(circle); shieldPips.push(circle);
      }
      this.tagTilesForClicks(drawing, picture, id);
      this.root.appendChild(group);
      this.root.appendChild(tag);
      const tileByCoordinate = new Map(picture.floorTiles.map((tile) => [`${tile.x},${tile.y}`, { column: tile.column, row: tile.row }]));
      this.ships.set(id, { id, picture, drawing, group, offsetX: gridX, offsetY: gridY, print, hullBar, shieldPips, tag, tileByCoordinate });
    });
  }

  /** Floor tiles carry the ship, tile and room they are, so BattleControls can read a click. */
  private tagTilesForClicks(drawing: ShipDrawing, picture: ShipPicture, shipId: number): void {
    const floor = drawing.root.querySelector('#floor');
    if (!floor) return;
    const rects = floor.querySelectorAll('rect');
    picture.floorTiles.forEach((tile, index) => {
      const rect = rects[index] as SVGRectElement | undefined;
      if (!rect) return;
      rect.dataset.shipId = String(shipId);
      rect.dataset.x = String(tile.x);
      rect.dataset.y = String(tile.y);
      rect.dataset.roomId = String(tile.roomId);
      rect.classList.add('tile', this.playerShipIds.includes(shipId) ? 'own' : 'enemy');
    });
  }

  private updateShip(placed: PlacedShip, ship: SnapshotShip): void {
    const share = ship.hullMax > 0 ? ship.hullPoints / ship.hullMax : 0;
    placed.hullBar.setAttribute('width', String(TAG.width * share));
    placed.hullBar.setAttribute('fill', share < 0.34 ? LOOK.hullBarLow : LOOK.hullBar);
    placed.shieldPips.forEach((pip, index) => {
      pip.setAttribute('fill', index < ship.shieldLayers ? LOOK.shieldPip : LOOK.shieldPipEmpty);
      pip.setAttribute('visibility', index < ship.shieldLayersMax ? 'visible' : 'hidden');
    });
    placed.drawing.updateCrew(ship.crew.map((member) => {
      const at = placed.tileByCoordinate.get(`${member.x},${member.y}`) ?? { column: 0, row: 0 };
      return { id: member.id, column: at.column, row: at.row, race: member.race, health: member.health, walking: member.walking };
    }), placed.picture, ship.id);
    placed.drawing.updateSystems(ship.systems.map((system) => ({ key: system.key, broken: !system.isWorking && system.maxBars > 0 || system.damage > 0 })), placed.picture.powerColour, LOOK.damagedSymbol);
    placed.drawing.updateDoors(ship.doors, ship.id);
    placed.group.setAttribute('opacity', ship.isGone ? '0.35' : '1');
  }

  /** A shot: on screen leaving its ship, gone across the divider, on screen again arriving (GDD 3Q). */
  private drawShots(snapshot: Snapshot): void {
    this.shotsGroup.replaceChildren();
    const onScreenShare = 0.3 / (0.6 + snapshot.distanceGm / 1000);
    for (const shot of snapshot.shots) {
      const from = this.ships.get(shot.fromShipId);
      const to = this.ships.get(shot.toShipId);
      if (!from || !to) continue;
      const start = this.tileCentre(from, from.picture.rooms[0]?.id ?? 0);
      const end = this.tileCentre(to, shot.toRoomId);
      const position = this.shotPosition(shot, start, end, onScreenShare);
      if (!position) continue;
      const dot = document.createElementNS(SVG, 'circle');
      dot.setAttribute('cx', String(position.x)); dot.setAttribute('cy', String(position.y));
      dot.setAttribute('r', shot.type === 'Missile' ? '5' : '3.5');
      dot.setAttribute('fill', shot.type === 'Missile' ? LOOK.missile : LOOK.laser);
      this.shotsGroup.appendChild(dot);
    }
  }

  private shotPosition(shot: SnapshotShot, start: { x: number; y: number }, end: { x: number; y: number }, onScreenShare: number): { x: number; y: number } | undefined {
    const divider = this.dividerY;
    if (shot.progress < onScreenShare) {
      const t = shot.progress / onScreenShare;
      return { x: start.x, y: start.y + (divider - start.y) * t };
    }
    if (shot.progress > 1 - onScreenShare) {
      const t = (shot.progress - (1 - onScreenShare)) / onScreenShare;
      return { x: end.x, y: divider + (end.y - divider) * t };
    }
    return undefined;
  }

  private rect(x: number, y: number, width: number, height: number, fill: string): SVGRectElement {
    const rect = document.createElementNS(SVG, 'rect');
    rect.setAttribute('x', String(x)); rect.setAttribute('y', String(y));
    rect.setAttribute('width', String(width)); rect.setAttribute('height', String(height));
    rect.setAttribute('fill', fill);
    return rect;
  }
}

/** The space a ship takes on screen: its tiles plus the hull art's overhang on each side, plus the labels above. */
function footprint(picture: ShipPicture): { width: number; height: number; left: number; top: number } {
  const grid = ShipDrawing.sizeOf(picture);
  const art = picture.hullArt;
  const left = art ? Math.max(0, art.gridX) : 0;
  const right = art ? Math.max(0, art.width - art.gridX - grid.width) : 0;
  const above = art ? Math.max(0, art.gridY) : 0;
  const below = art ? Math.max(0, art.height - art.gridY - grid.height) : 0;
  return { width: left + grid.width + right, height: LABEL_SPACE + above + grid.height + below, left, top: LABEL_SPACE + above };
}
