/**
 * Draws a running battle from what the host sends: each ship's picture once, then a snapshot every tick. Player
 * squad at the bottom, enemy at the top (GDD 3A), the divider between them standing for the off-screen distance
 * (GDD 3Q). Holds no game state: everything drawn comes from the last snapshot.
 */

import type { ShipPicture } from '../shared/ShipPicture';
import type { Snapshot, SnapshotShip, SnapshotShot } from '../shared/Snapshot';
import { ShipDrawing } from './ShipDrawing.js';

const SVG = 'http://www.w3.org/2000/svg';
const SHIP_GAP = 60;
const ROW_GAP = 120;
/** Room above a ship's art for its hull bar, shield pips and name. */
const LABEL_SPACE = 44;
/** The on-screen parts of a shot's flight (Simulation.ON_SCREEN_FLIGHT_SECONDS) as a share of the whole, for 400 GM. */
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
};

/** One ship on screen: its drawing, where it sits, and its live overlays. */
interface PlacedShip {
  id: number;
  picture: ShipPicture;
  drawing: ShipDrawing;
  group: SVGGElement;
  offsetX: number;
  offsetY: number;
  hullBar: SVGRectElement;
  shieldPips: SVGCircleElement[];
  tileByCoordinate: Map<string, { column: number; row: number }>;
}

export class BattleView {
  readonly root: SVGGElement;
  readonly ships = new Map<number, PlacedShip>();
  playerShipIds: number[] = [];
  private readonly shotsGroup: SVGGElement;
  private dividerY = 0;
  private width = 0;
  private height = 0;
  private selectedShipId?: number;

  constructor() {
    this.root = document.createElementNS(SVG, 'g');
    this.shotsGroup = document.createElementNS(SVG, 'g');
  }

  /** Lays both squads out from their pictures. */
  start(pictures: Record<number, ShipPicture>, playerShipIds: number[]): void {
    this.root.replaceChildren();
    this.ships.clear();
    this.playerShipIds = playerShipIds;
    const enemy = Object.entries(pictures).filter(([id]) => !playerShipIds.includes(Number(id)));
    const player = Object.entries(pictures).filter(([id]) => playerShipIds.includes(Number(id)));
    const rowWidth = (row: [string, ShipPicture][]) => row.reduce((sum, [, picture]) => sum + footprint(picture).width, 0) + SHIP_GAP * Math.max(0, row.length - 1);
    const rowHeight = (row: [string, ShipPicture][]) => Math.max(0, ...row.map(([, picture]) => footprint(picture).height));
    this.width = Math.max(rowWidth(enemy), rowWidth(player));
    const enemyHeight = rowHeight(enemy);
    this.dividerY = enemyHeight + ROW_GAP / 2;
    this.height = enemyHeight + ROW_GAP + rowHeight(player);

    const divider = document.createElementNS(SVG, 'line');
    divider.setAttribute('x1', '0'); divider.setAttribute('x2', String(this.width));
    divider.setAttribute('y1', String(this.dividerY)); divider.setAttribute('y2', String(this.dividerY));
    divider.setAttribute('stroke', LOOK.divider); divider.setAttribute('stroke-dasharray', '8 8');
    this.root.appendChild(divider);

    this.placeRow(enemy, (this.width - rowWidth(enemy)) / 2, 0);
    this.placeRow(player, (this.width - rowWidth(player)) / 2, enemyHeight + ROW_GAP);
    this.root.appendChild(this.shotsGroup);
  }

  size(): { width: number; height: number } {
    return { width: this.width, height: this.height };
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
  }

  select(shipId: number | undefined): void {
    this.selectedShipId = shipId;
    for (const placed of this.ships.values()) {
      placed.group.setAttribute('filter', placed.id === shipId ? 'drop-shadow(0 0 6px white)' : '');
    }
  }

  /** The screen position (in battle pixels) of a ship's tile centre, for shots. */
  private tileCentre(placed: PlacedShip, roomId: number): { x: number; y: number } {
    const tiles = placed.picture.floorTiles.filter((tile) => tile.roomId === roomId);
    const tile = tiles[0] ?? placed.picture.floorTiles[0];
    const size = placed.picture.tileSize;
    return { x: placed.offsetX + tile.column * size + size / 2, y: placed.offsetY + tile.row * size + size / 2 };
  }

  private placeRow(row: [string, ShipPicture][], startX: number, y: number): void {
    let x = startX;
    for (const [idText, picture] of row) {
      const id = Number(idText);
      const drawing = new ShipDrawing();
      drawing.draw(picture);
      const print = footprint(picture);
      // the tile grid sits inside its footprint: past the art's overhang on the left, and below the labels and overhang on top
      const gridX = x + print.left;
      const gridY = y + print.top;
      const group = document.createElementNS(SVG, 'g');
      group.setAttribute('transform', `translate(${gridX} ${gridY})`);
      group.dataset.shipId = String(id);
      group.appendChild(drawing.root);
      const size = ShipDrawing.sizeOf(picture);
      const labelY = -print.top + 4;   // the labels sit at the top of the footprint, above the art
      const hullBack = this.rect(0, labelY + 30, size.width, 8, LOOK.barBack);
      const hullBar = this.rect(0, labelY + 30, size.width, 8, LOOK.hullBar);
      group.appendChild(hullBack); group.appendChild(hullBar);
      const shieldPips: SVGCircleElement[] = [];
      for (let pip = 0; pip < 4; pip++) {
        const circle = document.createElementNS(SVG, 'circle');
        circle.setAttribute('cx', String(8 + pip * 14)); circle.setAttribute('cy', String(labelY + 18)); circle.setAttribute('r', '5');
        circle.setAttribute('fill', LOOK.shieldPipEmpty);
        group.appendChild(circle); shieldPips.push(circle);
      }
      const label = document.createElementNS(SVG, 'text');
      label.setAttribute('x', String(size.width)); label.setAttribute('y', String(labelY + 22)); label.setAttribute('text-anchor', 'end');
      label.setAttribute('font-size', '12'); label.setAttribute('fill', '#cfd6e2'); label.textContent = picture.name;
      group.appendChild(label);
      this.tagTilesForClicks(drawing, picture, id);
      this.root.appendChild(group);
      const tileByCoordinate = new Map(picture.floorTiles.map((tile) => [`${tile.x},${tile.y}`, { column: tile.column, row: tile.row }]));
      this.ships.set(id, { id, picture, drawing, group, offsetX: gridX, offsetY: gridY, hullBar, shieldPips, tileByCoordinate });
      x += print.width + SHIP_GAP;
    }
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
      rect.classList.add('tile');
    });
  }

  private updateShip(placed: PlacedShip, ship: SnapshotShip): void {
    const size = ShipDrawing.sizeOf(placed.picture);
    const share = ship.hullMax > 0 ? ship.hullPoints / ship.hullMax : 0;
    placed.hullBar.setAttribute('width', String(size.width * share));
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
