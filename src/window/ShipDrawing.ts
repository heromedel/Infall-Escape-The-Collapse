/**
 * Draws one ShipPicture as inline SVG: the hull art under the floor, then floor tiles, walls, doors, system
 * symbols and placeholder crew (GDD 5K, 12D). Inline SVG keeps a hull's named parts reachable for recolouring
 * and hiding later (GDD 10A).
 */

import type { PictureCrew, ShipPicture } from '../shared/ShipPicture';
import { systemSymbolElement, SYMBOL_BOX } from './SystemSymbols.js';

const SVG = 'http://www.w3.org/2000/svg';

const LOOK = {
  floor: '#cfd4db',
  floorLine: '#b3bac4',
  wall: '#161b25',
  door: '#7fb2ff',
  airlock: '#f0b54a',
  conduit: '#5d6573',
  crewOutline: '#0b1018',
  /** Console blue (docs/art/palette.md): the disc behind a symbol, standing in for the console. */
  consoleDisc: '#1C242C',
};

const CONSOLE_DISC_RADIUS = 13;

export class ShipDrawing {
  /** The group everything is drawn into; the camera moves this. */
  readonly root: SVGGElement;

  constructor() {
    this.root = document.createElementNS(SVG, 'g');
  }

  /** Replaces whatever was drawn with this ship. */
  draw(picture: ShipPicture): void {
    this.root.replaceChildren();
    if (picture.hullArt) this.root.appendChild(this.hullArt(picture));
    this.root.appendChild(this.floor(picture));
    this.root.appendChild(this.conduits(picture));
    this.root.appendChild(this.walls(picture));
    this.root.appendChild(this.doors(picture));
    this.root.appendChild(this.systems(picture));
    this.root.appendChild(this.crew(picture));
  }

  /** Live crew from a snapshot replace the placeholder crew: same shapes, on the tiles they stand on now. */
  updateCrew(crew: { id: number; column: number; row: number; race: string; health: number; walking: boolean }[], picture: ShipPicture, shipId: number): void {
    const old = this.root.querySelector('#crew');
    const group = this.group('crew');
    const size = picture.tileSize;
    const shapeOf = new Map(picture.crew.map((member) => [member.race, member]));
    for (const member of crew) {
      const look = shapeOf.get(member.race) ?? picture.crew[0] ?? { race: member.race, shape: 'QuestionMark' as const, colour: picture.powerColour, column: 0, row: 0 };
      const centreX = member.column * size + size / 2;
      const centreY = member.row * size + size / 2;
      const shape = this.crewShape({ ...look, column: member.column, row: member.row }, centreX, centreY);
      shape.setAttribute('fill', look.colour);
      shape.setAttribute('stroke', LOOK.crewOutline);
      shape.setAttribute('stroke-width', '1.5');
      shape.setAttribute('opacity', member.health <= 0 ? '0.25' : '1');
      shape.dataset.crewId = String(member.id);
      shape.dataset.shipId = String(shipId);
      shape.style.cursor = 'pointer';
      group.appendChild(shape);
    }
    if (old) old.replaceWith(group); else this.root.appendChild(group);
  }

  /** A damaged or broken system's symbol turns damaged red (GDD 14C); a working one shows the power colour. */
  updateSystems(systems: { key: string; broken: boolean }[], powerColour: string, damagedColour: string): void {
    for (const system of systems) {
      const symbol = this.root.querySelector(`#system-${CSS.escape(system.key.replace(/\s+/g, '-'))}`) as SVGElement | null;
      if (symbol) symbol.setAttribute('color', system.broken ? damagedColour : powerColour);
    }
  }

  /** The drawn size in ship pixels, so the camera can centre it. */
  static sizeOf(picture: ShipPicture): { width: number; height: number } {
    return { width: picture.columns * picture.tileSize, height: picture.rows * picture.tileSize };
  }

  private hullArt(picture: ShipPicture): SVGElement {
    const art = picture.hullArt!;
    const group = this.group('hull-art');
    // The art's grid origin lands on the ship's top-left tile corner, so art and floor line up.
    group.setAttribute('transform', `translate(${-art.gridX} ${-art.gridY})`);
    if (art.kind === 'svg') {
      const parsed = new DOMParser().parseFromString(art.content, 'image/svg+xml').documentElement;
      parsed.setAttribute('width', String(art.width));
      parsed.setAttribute('height', String(art.height));
      group.appendChild(document.importNode(parsed, true));
    } else {
      const image = document.createElementNS(SVG, 'image');
      image.setAttribute('href', art.content);
      image.setAttribute('width', String(art.width));
      image.setAttribute('height', String(art.height));
      image.setAttribute('image-rendering', 'pixelated');   // pixel art stays crisp when zoomed (Mecha style)
      group.appendChild(image);
    }
    return group;
  }

  private floor(picture: ShipPicture): SVGElement {
    const group = this.group('floor');
    const size = picture.tileSize;
    for (const tile of picture.floorTiles) {
      const rect = this.rect(tile.column * size, tile.row * size, size, size, LOOK.floor);
      rect.setAttribute('stroke', LOOK.floorLine);
      rect.setAttribute('stroke-width', '1');
      group.appendChild(rect);
    }
    return group;
  }

  private conduits(picture: ShipPicture): SVGElement {
    const group = this.group('conduits');
    const size = picture.tileSize;
    const half = size / 2;
    for (const conduit of picture.conduits) {
      const centreX = conduit.column * size + half;
      const centreY = conduit.row * size + half;
      for (const run of conduit.runs) {
        const endX = centreX + (run === 'East' ? half : run === 'West' ? -half : 0);
        const endY = centreY + (run === 'South' ? half : run === 'North' ? -half : 0);
        group.appendChild(this.line(centreX, centreY, endX, endY, LOOK.conduit, 3));
      }
      const hub = document.createElementNS(SVG, 'circle');
      hub.setAttribute('cx', String(centreX));
      hub.setAttribute('cy', String(centreY));
      hub.setAttribute('r', '2.5');
      hub.setAttribute('fill', LOOK.conduit);
      group.appendChild(hub);
    }
    return group;
  }

  private walls(picture: ShipPicture): SVGElement {
    const group = this.group('walls');
    for (const wall of picture.walls) group.appendChild(this.line(wall.x1, wall.y1, wall.x2, wall.y2, LOOK.wall, 3));
    return group;
  }

  /** Doors are clickable (BattleControls toggles them), so each carries its id. */
  private doors(picture: ShipPicture): SVGElement {
    const group = this.group('doors');
    for (const door of picture.doors) {
      const rect = this.rect(door.x, door.y, door.width, door.height, door.airlock ? LOOK.airlock : LOOK.door);
      rect.dataset.doorId = String(door.id);
      rect.classList.add('door');
      group.appendChild(rect);
    }
    return group;
  }

  /** An open door shows as an outline, a closed one as a solid bar. */
  updateDoors(doors: { id: number; open: boolean }[], shipId: number): void {
    for (const door of doors) {
      const rect = this.root.querySelector(`#doors rect[data-door-id="${door.id}"]`) as SVGRectElement | null;
      if (!rect) continue;
      rect.dataset.shipId = String(shipId);
      rect.setAttribute('fill-opacity', door.open ? '0.25' : '1');
      rect.setAttribute('stroke', door.open ? LOOK.door : 'none');
    }
  }

  /** Each system's symbol in the ship's power colour, against its wall or over the tile's centre (GDD 5H). */
  private systems(picture: ShipPicture): SVGElement {
    const group = this.group('systems');
    const size = picture.tileSize;
    for (const system of picture.systems) {
      let x = system.column * size + (size - SYMBOL_BOX) / 2;
      let y = system.row * size + (size - SYMBOL_BOX) / 2;
      const lean = (size - SYMBOL_BOX) / 2 - 2;
      if (system.wall === 'North') y -= lean;
      if (system.wall === 'South') y += lean;
      if (system.wall === 'West') x -= lean;
      if (system.wall === 'East') x += lean;
      const symbol = this.group(`system-${system.key.replace(/\s+/g, '-')}`);
      symbol.setAttribute('transform', `translate(${x} ${y})`);
      symbol.setAttribute('color', picture.powerColour);
      const disc = document.createElementNS(SVG, 'circle');
      disc.setAttribute('cx', String(SYMBOL_BOX / 2)); disc.setAttribute('cy', String(SYMBOL_BOX / 2));
      disc.setAttribute('r', String(CONSOLE_DISC_RADIUS)); disc.setAttribute('fill', LOOK.consoleDisc);
      symbol.appendChild(disc);
      symbol.appendChild(systemSymbolElement(system.name, system.symbolSvg));
      const title = document.createElementNS(SVG, 'title');
      title.textContent = `${system.key}, level ${system.level}`;
      symbol.appendChild(title);
      group.appendChild(symbol);
    }
    return group;
  }

  private crew(picture: ShipPicture): SVGElement {
    const group = this.group('crew');
    const size = picture.tileSize;
    for (const member of picture.crew) {
      const centreX = member.column * size + size / 2;
      const centreY = member.row * size + size / 2;
      const shape = this.crewShape(member, centreX, centreY);
      shape.setAttribute('fill', member.colour);
      shape.setAttribute('stroke', LOOK.crewOutline);
      shape.setAttribute('stroke-width', '1.5');
      group.appendChild(shape);
    }
    return group;
  }

  /** The race's placeholder shape (GDD 12D), about 16 pixels across, centred on the tile. */
  private crewShape(member: PictureCrew, cx: number, cy: number): SVGElement {
    const r = 8;
    const polygon = (points: string) => { const p = document.createElementNS(SVG, 'polygon'); p.setAttribute('points', points); return p; };
    const path = (d: string) => { const p = document.createElementNS(SVG, 'path'); p.setAttribute('d', d); return p; };
    switch (member.shape) {
      case 'Square': return this.rect(cx - r, cy - r, 2 * r, 2 * r, member.colour);
      case 'Circle': { const c = document.createElementNS(SVG, 'circle'); c.setAttribute('cx', String(cx)); c.setAttribute('cy', String(cy)); c.setAttribute('r', String(r)); return c; }
      case 'Triangle': return polygon(`${cx},${cy - r} ${cx + r},${cy + r} ${cx - r},${cy + r}`);
      case 'Diamond': return polygon(`${cx},${cy - r} ${cx + r},${cy} ${cx},${cy + r} ${cx - r},${cy}`);
      case 'Cross': return path(`M${cx - 3} ${cy - r} h6 v${r - 3} h${r - 3} v6 h-${r - 3} v${r - 3} h-6 v-${r - 3} h-${r - 3} v-6 h${r - 3} z`);
      case 'Star': {
        const points = [];
        for (let i = 0; i < 10; i++) {
          const radius = i % 2 === 0 ? r : r * 0.45;
          const angle = -Math.PI / 2 + (i * Math.PI) / 5;
          points.push(`${cx + radius * Math.cos(angle)},${cy + radius * Math.sin(angle)}`);
        }
        return polygon(points.join(' '));
      }
      case 'Crescent': return path(`M${cx + 2} ${cy - r} A${r} ${r} 0 1 0 ${cx + 2} ${cy + r} A${r * 0.7} ${r * 0.7} 0 1 1 ${cx + 2} ${cy - r} Z`);
      case 'QuestionMark': {
        const text = document.createElementNS(SVG, 'text');
        text.setAttribute('x', String(cx)); text.setAttribute('y', String(cy + 6));
        text.setAttribute('font-size', '18'); text.setAttribute('font-weight', 'bold'); text.setAttribute('text-anchor', 'middle');
        text.textContent = '?';
        return text;
      }
    }
  }

  private group(id: string): SVGGElement {
    const group = document.createElementNS(SVG, 'g');
    group.setAttribute('id', id);
    return group;
  }

  private rect(x: number, y: number, width: number, height: number, fill: string): SVGRectElement {
    const rect = document.createElementNS(SVG, 'rect');
    rect.setAttribute('x', String(x)); rect.setAttribute('y', String(y));
    rect.setAttribute('width', String(width)); rect.setAttribute('height', String(height));
    rect.setAttribute('fill', fill);
    return rect;
  }

  private line(x1: number, y1: number, x2: number, y2: number, stroke: string, width: number): SVGLineElement {
    const line = document.createElementNS(SVG, 'line');
    line.setAttribute('x1', String(x1)); line.setAttribute('y1', String(y1));
    line.setAttribute('x2', String(x2)); line.setAttribute('y2', String(y2));
    line.setAttribute('stroke', stroke); line.setAttribute('stroke-width', String(width));
    line.setAttribute('stroke-linecap', 'square');
    return line;
  }
}
