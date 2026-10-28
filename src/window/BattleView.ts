/**
 * Draws a running battle from what the host sends: each ship's picture once, then a snapshot every tick. Player
 * squad at the bottom, enemy at the top (GDD 3A), the barrier between them standing for the off-screen distance
 * (GDD 3Q, 3R): two lines with a strip of drifting stars, labelled in Gatometers. Holds no game state:
 * everything drawn comes from the last snapshot.
 */

import type { ShipPicture } from '../shared/ShipPicture';
import type { Snapshot, SnapshotShip, SnapshotShot } from '../shared/Snapshot';
import { ShipDrawing } from './ShipDrawing.js';
import { formationSlots } from './Formation.js';
import type { FormationDefinition } from '../shared/Formation';

const SVG = 'http://www.w3.org/2000/svg';
/** The barrier strip's height: two lines with the star field between them, six cells. */
const STRIP = 6 * 35;
/** Room above a ship's art for its tag: name, hull bar and shield pips, drawn at screen scale. */
const LABEL_SPACE = 64;
const TAG = { width: 170, height: 34 };
const LOOK = {
  divider: '#4a6a8a',
  strip: 'rgba(28, 36, 44, 0.55)',
  zone: 'rgba(79, 143, 255, 0.10)',
  zoneEdge: 'rgba(79, 143, 255, 0.45)',
  star: '#9fb3c8',
  crossing: 'rgba(255, 224, 102, 0.45)',
  hullBar: '#66FF66',
  hullBarLow: '#FF3B3B',
  barBack: '#1d2a3a',
  shieldPip: '#4F8FFF',
  shieldPipEmpty: '#263445',
  laser: '#FFE066',
  missile: '#FF8500',
  damagedSymbol: '#FF3B3B',
  selected: '#FFFFFF',
  /** Red marks a target the weapon keeps (autofire), yellow one it fires at once (genre reference frames 05, 06). */
  targetAuto: '#FF3B3B',
  targetOnce: '#FFE066',
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
  /** Target Lines setting: a dashed line to each target room as well as the room mark. */
  targetLines = false;
  /** Shots Crossing Barrier setting (GDD 3R): the tiny dash of a shot in the strip. */
  shotsCrossingBarrier = true;
  /** Show Zones (debug): the formation zones drawn translucent, to check the spacing. */
  showZones = false;
  private zonesGroup?: SVGGElement;
  /** The strip's top and bottom, in battle pixels; the near line for the enemy is the top, for the player the bottom. */
  private stripTop = 0;
  private stripBottom = 0;
  private stars: SVGGElement;
  private distanceText?: SVGTextElement;
  private delayText?: SVGTextElement;
  private labels?: SVGGElement;
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
    this.stars = document.createElementNS(SVG, 'g');
  }

  /** Lays both squads out from their pictures, each in its formation curve facing the divider (GDD 3H). */
  start(pictures: Record<number, ShipPicture>, playerShipIds: number[], formations: { player: FormationDefinition; enemy: FormationDefinition }): void {
    this.root.replaceChildren();
    this.ships.clear();
    this.playerShipIds = playerShipIds;
    const enemy = Object.entries(pictures).filter(([id]) => !playerShipIds.includes(Number(id)));
    const player = Object.entries(pictures).filter(([id]) => playerShipIds.includes(Number(id)));
    const enemyLayout = formationSlots(enemy.map(([, picture]) => footprint(picture)), 'down', formations.enemy);
    const playerLayout = formationSlots(player.map(([, picture]) => footprint(picture)), 'up', formations.player);
    // a tag may hang above the enemy squad's top zone: leave it room
    const tagRoom = LABEL_SPACE;
    // both squads share the grid's columns from the left (GDD 3S); the player file's shift is already in its layout
    this.width = Math.max(enemyLayout.width, playerLayout.width);
    const enemyX = 0;
    const playerX = 0;
    // each squad's zones run to its barrier line (GDD 3R, 3S)
    this.stripTop = tagRoom + enemyLayout.height;
    this.stripBottom = this.stripTop + STRIP;
    this.dividerY = this.stripTop + STRIP / 2;
    this.height = this.stripBottom + tagRoom + playerLayout.height;

    this.root.appendChild(this.barrier());
    this.zonesGroup = this.zoneBoxes([...enemyLayout.zones.map((z) => ({ ...z, y: z.y + tagRoom })), ...playerLayout.zones.map((z) => ({ ...z, y: z.y + this.stripBottom + tagRoom }))]);
    this.root.appendChild(this.zonesGroup);
    this.root.appendChild(this.selectionRing);   // under the ships

    this.placeSquad(enemy, enemyLayout.slots, enemyX, tagRoom);
    this.placeSquad(player, playerLayout.slots, playerX, this.stripBottom + tagRoom);
    this.root.appendChild(this.targetsGroup);
    this.root.appendChild(this.shotsGroup);
    this.rescaleTags();
  }

  /** The formation zones (GDD 3S) drawn translucent, numbered, for checking the spacing; shown by the Show Zones toggle. */
  private zoneBoxes(zones: { slot: number; x: number; y: number; size: number }[]): SVGGElement {
    const group = document.createElementNS(SVG, 'g');
    group.setAttribute('pointer-events', 'none');
    group.setAttribute('visibility', this.showZones ? 'visible' : 'hidden');
    for (const zone of zones) {
      group.appendChild(this.rect(zone.x, zone.y, zone.size, zone.size, LOOK.zone));
      const edge = this.rect(zone.x, zone.y, zone.size, zone.size, 'none');
      edge.setAttribute('stroke', LOOK.zoneEdge); edge.setAttribute('stroke-width', '1.5'); edge.setAttribute('stroke-dasharray', '6 6');
      group.appendChild(edge);
      const label = document.createElementNS(SVG, 'text');
      label.setAttribute('x', String(zone.x + 6)); label.setAttribute('y', String(zone.y + 16)); label.setAttribute('font-size', '12'); label.setAttribute('fill', LOOK.zoneEdge);
      label.textContent = `zone ${zone.slot}`;
      group.appendChild(label);
    }
    return group;
  }

  setShowZones(show: boolean): void {
    this.showZones = show;
    this.zonesGroup?.setAttribute('visibility', show ? 'visible' : 'hidden');
  }

  /** The barrier (GDD 3R): two lines, a strip of stars that drift toward the player between them, and the labels. */
  private barrier(): SVGGElement {
    const group = document.createElementNS(SVG, 'g');
    group.setAttribute('pointer-events', 'none');
    group.appendChild(this.rect(0, this.stripTop, this.width, STRIP, LOOK.strip));
    for (const y of [this.stripTop, this.stripBottom]) {
      const line = document.createElementNS(SVG, 'line');
      line.setAttribute('x1', '0'); line.setAttribute('x2', String(this.width));
      line.setAttribute('y1', String(y)); line.setAttribute('y2', String(y));
      line.setAttribute('stroke', LOOK.divider); line.setAttribute('stroke-width', '1.5');
      group.appendChild(line);
    }
    this.stars = document.createElementNS(SVG, 'g');
    const count = Math.max(24, Math.round(this.width / 14));
    for (let i = 0; i < count; i++) {
      const star = document.createElementNS(SVG, 'circle');
      star.setAttribute('cx', String(Math.random() * this.width));
      star.setAttribute('cy', String(this.stripTop + 4 + Math.random() * (STRIP - 8)));
      star.setAttribute('r', String(0.6 + Math.random() * 1.1));
      star.setAttribute('fill', LOOK.star); star.setAttribute('opacity', String(0.25 + Math.random() * 0.5));
      this.stars.appendChild(star);
    }
    group.appendChild(this.stars);
    // the labels keep their screen size (rescaleLabels), like the ship tags
    this.labels = document.createElementNS(SVG, 'g');
    this.distanceText = document.createElementNS(SVG, 'text');
    this.distanceText.setAttribute('y', '-3');
    this.distanceText.setAttribute('text-anchor', 'middle'); this.distanceText.setAttribute('font-size', '13'); this.distanceText.setAttribute('font-family', 'system-ui, sans-serif');
    this.distanceText.setAttribute('fill', '#cfd6e2'); this.distanceText.setAttribute('letter-spacing', '1');
    this.labels.appendChild(this.distanceText);
    this.delayText = document.createElementNS(SVG, 'text');
    this.delayText.setAttribute('y', '12');
    this.delayText.setAttribute('text-anchor', 'middle'); this.delayText.setAttribute('font-size', '10'); this.delayText.setAttribute('font-family', 'system-ui, sans-serif');
    this.delayText.setAttribute('fill', LOOK.star);
    this.labels.appendChild(this.delayText);
    group.appendChild(this.labels);
    this.rescaleLabels();
    return group;
  }

  private rescaleLabels(): void {
    this.labels?.setAttribute('transform', `translate(${this.width / 2} ${this.dividerY}) scale(${1 / this.zoom})`);
  }

  /** The stars drift slowly toward the player while the squads hold their distance. */
  private driftStars(tick: number): void {
    const shift = (tick * 0.15) % STRIP;
    this.stars.childNodes.forEach((node) => {
      const star = node as SVGCircleElement;
      const base = Number(star.dataset.baseY ?? (star.dataset.baseY = star.getAttribute('cy')!));
      let y = base + shift;
      if (y > this.stripBottom - 4) y -= STRIP - 8;
      star.setAttribute('cy', String(y));
    });
  }

  size(): { width: number; height: number } {
    return { width: this.width, height: this.height };
  }

  /** The camera moved or zoomed: the tags keep their screen size. */
  setZoom(zoom: number): void {
    this.zoom = zoom;
    this.rescaleTags();
    this.rescaleLabels();
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

  /** Marks the tile under the pointer as the one a shot would land on (GDD 3L), or none. */
  hoverTile(tile: SVGRectElement | undefined): void {
    this.root.querySelectorAll('rect.tile.hover-room').forEach((other) => other.classList.remove('hover-room'));
    tile?.classList.add('hover-room');
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
    this.driftStars(snapshot.tick);
    if (this.distanceText) this.distanceText.textContent = `${snapshot.distanceGm} Gatometers`;
    if (this.delayText) this.delayText.textContent = `${(0.6 + snapshot.distanceGm / 1000).toFixed(1)} s flight`;
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

  /** The selected ship's aimed weapons: a reticle with the slot number on each target room, red for autofire and yellow for fire once, plus a line when Target Lines is on (GDD 3L: any enemy ship). */
  private drawTargets(snapshot: Snapshot): void {
    this.targetsGroup.replaceChildren();
    const ship = snapshot.squads.flatMap((squad) => squad.ships).find((candidate) => candidate.id === this.selectedShipId);
    const from = ship && this.ships.get(ship.id);
    if (!ship || !from) return;
    ship.weapons.forEach((weapon, index) => {
      if (!weapon.target) return;
      const to = this.ships.get(weapon.target.shipId);
      if (!to) return;
      const colour = weapon.autofire ? LOOK.targetAuto : LOOK.targetOnce;
      const centre = this.tileCentre(to, weapon.target.tile);
      if (this.targetLines) {
        const grid = ShipDrawing.sizeOf(from.picture);
        const start = { x: from.offsetX + grid.width * (index + 1) / (ship.weapons.length + 1), y: from.offsetY - from.print.top + from.print.height - grid.height / 2 };
        const line = document.createElementNS(SVG, 'line');
        line.setAttribute('x1', String(start.x)); line.setAttribute('y1', String(start.y));
        line.setAttribute('x2', String(centre.x)); line.setAttribute('y2', String(centre.y));
        line.setAttribute('stroke', colour); line.setAttribute('stroke-width', '1.5'); line.setAttribute('stroke-dasharray', '6 4');
        line.setAttribute('opacity', '0.7'); line.setAttribute('pointer-events', 'none');
        this.targetsGroup.appendChild(line);
      }
      this.targetsGroup.appendChild(reticleMark(centre.x + index * 4, centre.y + index * 4, colour, String(index + 1)));
    });
  }

  /** The screen position (in battle pixels) of a ship's tile centre, by the tile's signed coordinates. */
  private tileCentre(placed: PlacedShip, tile: { x: number; y: number }): { x: number; y: number } {
    const at = placed.tileByCoordinate.get(`${tile.x},${tile.y}`) ?? { column: placed.picture.floorTiles[0].column, row: placed.picture.floorTiles[0].row };
    const size = placed.picture.tileSize;
    return { x: placed.offsetX + at.column * size + size / 2, y: placed.offsetY + at.row * size + size / 2 };
  }

  /** A ship's own firing point: not in the docs yet, its first room's first tile until mounts have coordinates. */
  private firingPoint(placed: PlacedShip): { x: number; y: number } {
    const first = placed.picture.floorTiles[0];
    return this.tileCentre(placed, { x: first.x, y: first.y });
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
    // enemy crew can't be ordered, so a click on one is a click on the room under it
    if (!this.playerShipIds.includes(ship.id)) placed.drawing.root.querySelector('#crew')?.setAttribute('pointer-events', 'none');
    placed.group.setAttribute('opacity', ship.isGone ? '0.35' : '1');
  }

  /**
   * A shot flies one straight line from its ship to its target (GDD 3R): drawn until that line meets the near
   * barrier line, gone across the strip (a tiny faint dash shows it crossing), drawn again from the far line.
   */
  private drawShots(snapshot: Snapshot): void {
    this.shotsGroup.replaceChildren();
    const onScreenShare = 0.3 / (0.6 + snapshot.distanceGm / 1000);
    for (const shot of snapshot.shots) {
      const from = this.ships.get(shot.fromShipId);
      const to = this.ships.get(shot.toShipId);
      if (!from || !to) continue;
      const start = this.firingPoint(from);
      const end = this.tileCentre(to, shot.toTile);
      const path = this.shotPath(start, end);
      const angle = Math.atan2(end.y - start.y, end.x - start.x) * 180 / Math.PI + 90;
      if (shot.progress < onScreenShare) {
        const t = shot.progress / onScreenShare;
        this.shotsGroup.appendChild(this.projectile(shot, lerp(start, path.vanish, t), angle, snapshot.tick));
      } else if (shot.progress > 1 - onScreenShare) {
        const t = (shot.progress - (1 - onScreenShare)) / onScreenShare;
        this.shotsGroup.appendChild(this.projectile(shot, lerp(path.reappear, end, t), angle, snapshot.tick));
      } else if (this.shotsCrossingBarrier) {
        const t = (shot.progress - onScreenShare) / (1 - 2 * onScreenShare);
        const at = lerp(path.vanish, path.reappear, t);
        const dash = document.createElementNS(SVG, 'line');
        const dx = (path.reappear.x - path.vanish.x), dy = (path.reappear.y - path.vanish.y), len = Math.hypot(dx, dy) || 1;
        dash.setAttribute('x1', String(at.x - dx / len * 3)); dash.setAttribute('y1', String(at.y - dy / len * 3));
        dash.setAttribute('x2', String(at.x + dx / len * 3)); dash.setAttribute('y2', String(at.y + dy / len * 3));
        dash.setAttribute('stroke', LOOK.crossing); dash.setAttribute('stroke-width', '1.2');
        this.shotsGroup.appendChild(dash);
      }
    }
  }

  /** Where the straight line from start to end meets the near barrier line and the far one. */
  private shotPath(start: { x: number; y: number }, end: { x: number; y: number }): { vanish: { x: number; y: number }; reappear: { x: number; y: number } } {
    const downward = end.y > start.y;
    const nearY = downward ? this.stripTop : this.stripBottom;
    const farY = downward ? this.stripBottom : this.stripTop;
    const at = (y: number) => ({ x: start.x + (end.x - start.x) * ((y - start.y) / (end.y - start.y || 1)), y });
    return { vanish: at(nearY), reappear: at(farY) };
  }

  private projectile(shot: SnapshotShot, at: { x: number; y: number }, angle: number, tick: number): SVGGElement {
    return shot.type === 'Missile' ? missileShape(at.x, at.y, angle, LOOK.missile) : laserBolt(at.x, at.y, angle, LOOK.laser, tick + shot.id);
  }

  private rect(x: number, y: number, width: number, height: number, fill: string): SVGRectElement {
    const rect = document.createElementNS(SVG, 'rect');
    rect.setAttribute('x', String(x)); rect.setAttribute('y', String(y));
    rect.setAttribute('width', String(width)); rect.setAttribute('height', String(height));
    rect.setAttribute('fill', fill);
    return rect;
  }
}

/**
 * A laser bolt as the genre draws one (docs/reference/genre-battle-screen): a glowing streak with a bright
 * rounded head and a tail that thins out behind it, flickering a little, head first along its path. Placeholder
 * until each weapon file names its own projectile art.
 */
function laserBolt(x: number, y: number, angle: number, colour: string, flicker: number): SVGGElement {
  const group = document.createElementNS(SVG, 'g');
  group.setAttribute('pointer-events', 'none');
  // drawn pointing up with the head at the origin, then turned along the path
  group.setAttribute('transform', `translate(${x} ${y}) rotate(${angle})`);
  const length = 34 + (flicker % 3) * 3;
  group.innerHTML =
    `<line x1="0" y1="0" x2="0" y2="${length}" stroke="${colour}" stroke-width="7" stroke-linecap="round" opacity="0.35"/>`
    + `<line x1="0" y1="4" x2="0" y2="${length - 6}" stroke="${colour}" stroke-width="3" stroke-linecap="round" opacity="0.8"/>`
    + `<circle r="4.5" fill="${colour}"/><circle r="2" fill="#ffffff"/>`;
  return group;
}

/** A missile as the genre draws one: a slim rocket seen from above, nose first, small fins, an exhaust flame. Placeholder. */
function missileShape(x: number, y: number, angle: number, flameColour: string): SVGGElement {
  const group = document.createElementNS(SVG, 'g');
  group.setAttribute('pointer-events', 'none');
  // drawn pointing up, then turned to fly along the path
  group.setAttribute('transform', `translate(${x} ${y}) rotate(${angle})`);
  group.innerHTML =
    `<polygon points="0,-14 3,-8 3,6 -3,6 -3,-8" fill="#d8dde6" stroke="#6b7280" stroke-width="0.8"/>`
    + `<polygon points="-3,2 -7,8 -3,8" fill="#8a94a3"/><polygon points="3,2 7,8 3,8" fill="#8a94a3"/>`
    + `<polygon points="-2,8 2,8 0,16" fill="${flameColour}"/><polygon points="-1,8 1,8 0,12" fill="#fff2a8"/>`;
  return group;
}

/** A target mark: a ring with a cross and the weapon's slot number beside it, in the fire mode's colour. */
function reticleMark(x: number, y: number, colour: string, label: string): SVGGElement {
  const group = document.createElementNS(SVG, 'g');
  group.setAttribute('pointer-events', 'none');
  const r = 11;
  const parts = [
    `<circle cx="${x}" cy="${y}" r="${r}" fill="none" stroke="${colour}" stroke-width="2"/>`,
    `<circle cx="${x}" cy="${y}" r="3" fill="${colour}"/>`,
    `<line x1="${x - r - 4}" y1="${y}" x2="${x - r + 4}" y2="${y}" stroke="${colour}" stroke-width="2"/>`,
    `<line x1="${x + r - 4}" y1="${y}" x2="${x + r + 4}" y2="${y}" stroke="${colour}" stroke-width="2"/>`,
    `<line x1="${x}" y1="${y - r - 4}" x2="${x}" y2="${y - r + 4}" stroke="${colour}" stroke-width="2"/>`,
    `<line x1="${x}" y1="${y + r - 4}" x2="${x}" y2="${y + r + 4}" stroke="${colour}" stroke-width="2"/>`,
    `<text x="${x + r + 3}" y="${y + r + 6}" font-size="11" font-weight="bold" font-family="system-ui, sans-serif" fill="${colour}">${label}</text>`,
  ];
  group.innerHTML = parts.join('');
  return group;
}

function lerp(a: { x: number; y: number }, b: { x: number; y: number }, t: number): { x: number; y: number } {
  return { x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t };
}

/** The space a ship takes on screen: its tiles plus the hull art's overhang on each side, plus the labels above. */
function footprint(picture: ShipPicture): { width: number; height: number; left: number; top: number; tag: number } {
  const grid = ShipDrawing.sizeOf(picture);
  const art = picture.hullArt;
  const left = art ? Math.max(0, art.gridX) : 0;
  const right = art ? Math.max(0, art.width - art.gridX - grid.width) : 0;
  const above = art ? Math.max(0, art.gridY) : 0;
  const below = art ? Math.max(0, art.height - art.gridY - grid.height) : 0;
  return { width: left + grid.width + right, height: LABEL_SPACE + above + grid.height + below, left, top: LABEL_SPACE + above, tag: LABEL_SPACE };
}
