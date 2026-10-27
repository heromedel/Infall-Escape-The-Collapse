/**
 * The selected ship's panel (GDD 3B, Proposed): hull and shields, weapons, crew, and the systems with their power
 * bars, laid out as the genre does and drawn as SVG so it can sit under the ship's hull at hull scale or docked
 * in the bottom band (Settings: Ship Panel). Built once per ship and then updated in place, so a click never
 * lands on an element that was just replaced. Clickable parts carry data-action; BattleControls reads them.
 * Placeholder look until the GUI discussion (GDD 14A); colours per 14B and the palette.
 */

import type { ShipPicture } from '../shared/ShipPicture';
import type { SnapshotCrew, SnapshotShip, SnapshotSystem, SnapshotWeapon } from '../shared/Snapshot';
import { systemSymbolElement, SYMBOL_BOX } from './SystemSymbols.js';
import { placeholderShape, rect, text } from './HudBits.js';

const SVG = 'http://www.w3.org/2000/svg';

export const PANEL_WIDTH = 340;
export const PANEL_HEIGHT = 180;

const LOOK = {
  back: '#1d2a3a',
  edge: '#4a6a8a',
  text: '#ffffff',
  faint: '#9fb3c8',
  hull: '#66FF66',
  hullLow: '#FF3B3B',
  barBack: '#0b1018',
  barEmpty: '#2a3a4e',
  shield: '#4F8FFF',
  shieldEmpty: '#263445',
  health: '#66FF66',
  healthLow: '#FF3B3B',
  charge: '#2f6b4f',
  chargeFull: '#66FF66',
  armed: '#ffffff',
  damaged: '#FF3B3B',
  unpowered: '#5d6573',
};

/** The layout, top to bottom: status line, weapons, crew, then the systems with bars above their icons. */
const ROW = { status: 4, weapons: 22, crew: 48, bars: 150, icons: 154 };
const BAR = { width: 16, height: 4, gap: 1.5 };
const SYSTEM_STEP = 30;
const WEAPON_BOX = { width: 154, height: 20, gap: 6 };
const CREW_BOX = { width: 106, height: 22, gap: 5 };

export interface PanelSelection {
  armedMount?: number;
  selectedCrewId?: number;
}

export class ShipPanel {
  readonly root: SVGGElement;
  private readonly hullBar: SVGRectElement;
  private readonly hullText: SVGTextElement;
  private readonly shieldPips: SVGCircleElement[] = [];
  private readonly evasionText: SVGTextElement;
  private readonly powerText: SVGTextElement;
  private readonly reactorBars: SVGRectElement[] = [];
  private readonly systems = new Map<string, { icon: SVGGElement; bars: SVGRectElement[]; hit: SVGRectElement }>();
  private readonly weapons = new Map<number, { box: SVGRectElement; fill: SVGRectElement; target: SVGTextElement }>();
  private readonly crew = new Map<number, { box: SVGRectElement; health: SVGRectElement; shape: SVGElement }>();

  constructor(ship: SnapshotShip, private readonly picture: ShipPicture) {
    this.root = document.createElementNS(SVG, 'g');
    this.root.setAttribute('class', 'ship-panel');
    this.root.appendChild(rect(0, 0, PANEL_WIDTH, PANEL_HEIGHT, LOOK.back, { stroke: LOOK.edge, rx: '4' }));

    // status line: hull bar with its number, shield pips, evasion and the reactor's count
    this.root.appendChild(rect(6, ROW.status, 120, 12, LOOK.barBack));
    this.hullBar = rect(6, ROW.status, 120, 12, LOOK.hull);
    this.root.appendChild(this.hullBar);
    this.hullText = text(66, ROW.status + 10, '', { size: 10, anchor: 'middle', weight: 'bold' });
    this.root.appendChild(this.hullText);
    for (let pip = 0; pip < 4; pip++) {
      const circle = document.createElementNS(SVG, 'circle');
      circle.setAttribute('cx', String(140 + pip * 12)); circle.setAttribute('cy', String(ROW.status + 6)); circle.setAttribute('r', '4.5');
      this.root.appendChild(circle); this.shieldPips.push(circle);
    }
    this.evasionText = text(192, ROW.status + 10, '', { size: 10, fill: LOOK.faint });
    this.root.appendChild(this.evasionText);
    this.powerText = text(PANEL_WIDTH - 6, ROW.status + 10, '', { size: 10, anchor: 'end', fill: LOOK.faint });
    this.root.appendChild(this.powerText);

    this.buildWeapons(ship.weapons);
    this.buildCrew(ship.crew, picture);
    this.buildSystems(ship);
  }

  /** Everything that moves: bars, charges, health, targets and what is selected. */
  update(ship: SnapshotShip, selection: PanelSelection): void {
    const hullShare = ship.hullMax > 0 ? ship.hullPoints / ship.hullMax : 0;
    this.hullBar.setAttribute('width', String(120 * hullShare));
    this.hullBar.setAttribute('fill', hullShare < 0.34 ? LOOK.hullLow : LOOK.hull);
    this.hullText.textContent = `${ship.hullPoints} / ${ship.hullMax}`;
    this.shieldPips.forEach((pip, index) => {
      pip.setAttribute('fill', index < ship.shieldLayers ? LOOK.shield : LOOK.shieldEmpty);
      pip.setAttribute('visibility', index < ship.shieldLayersMax ? 'visible' : 'hidden');
    });
    this.evasionText.textContent = `evade ${ship.evasionPercent}%`;
    this.powerText.textContent = ship.powerKind === 'SelfPowered' ? 'self-powered' : `${ship.powerKind} ${ship.barsTotal - ship.barsInUse}/${ship.barsTotal} free`;
    this.reactorBars.forEach((bar, index) => bar.setAttribute('fill', index < ship.barsTotal - ship.barsInUse ? this.picture.powerColour : LOOK.barEmpty));

    for (const system of ship.systems) {
      const drawn = this.systems.get(system.key);
      if (!drawn) continue;
      drawn.icon.setAttribute('color', system.isWorking || system.maxBars === 0 && system.damage === 0 ? this.picture.powerColour : LOOK.damaged);
      drawn.icon.setAttribute('opacity', system.isWorking ? '1' : '0.8');
      drawn.bars.forEach((bar, index) => {
        const level = index + 1;
        const damagedAway = level > system.maxBars - system.damage * (system.maxBars / system.level);
        bar.setAttribute('fill', index < system.bars ? (damagedAway ? LOOK.damaged : this.picture.powerColour) : damagedAway ? LOOK.damaged : LOOK.barEmpty);
        bar.setAttribute('opacity', index < system.bars || damagedAway ? '1' : '0.6');
      });
      const title = drawn.hit.querySelector('title')!;
      title.textContent = `${system.key}: ${system.bars} of ${system.maxBars} bars${system.damage > 0 ? `, ${system.damage} damage` : ''}${system.mannedBy !== undefined ? ', manned' : ''}. Click adds power, right click removes.`;
    }

    for (const weapon of ship.weapons) {
      const drawn = this.weapons.get(weapon.mount);
      if (!drawn) continue;
      const armed = selection.armedMount === weapon.mount;
      drawn.fill.setAttribute('width', String((WEAPON_BOX.width - 2) * (weapon.powered ? weapon.charge : 0)));
      drawn.fill.setAttribute('fill', weapon.charge >= 1 ? LOOK.chargeFull : LOOK.charge);
      drawn.box.setAttribute('stroke', armed ? LOOK.armed : weapon.powered ? LOOK.edge : LOOK.unpowered);
      drawn.box.setAttribute('stroke-width', armed ? '2' : '1');
      drawn.target.textContent = weapon.target ? 'aimed' : weapon.powered ? 'no target' : 'no power';
      drawn.target.setAttribute('fill', weapon.target ? this.picture.powerColour : LOOK.faint);
    }

    for (const member of ship.crew) {
      const drawn = this.crew.get(member.id);
      if (!drawn) continue;
      const selected = selection.selectedCrewId === member.id;
      drawn.box.setAttribute('stroke', selected ? LOOK.armed : LOOK.edge);
      drawn.box.setAttribute('stroke-width', selected ? '2' : '1');
      drawn.health.setAttribute('width', String((CREW_BOX.width - 28) * Math.max(0, member.health) / 100));
      drawn.health.setAttribute('fill', member.health < 34 ? LOOK.healthLow : LOOK.health);
      drawn.shape.setAttribute('opacity', member.health <= 0 ? '0.25' : '1');
    }
  }

  private buildWeapons(weapons: SnapshotWeapon[]): void {
    weapons.forEach((weapon, index) => {
      const x = 6 + index * (WEAPON_BOX.width + WEAPON_BOX.gap);
      const y = ROW.weapons;
      const group = document.createElementNS(SVG, 'g');
      group.dataset.action = 'weapon';
      group.dataset.mount = String(weapon.mount);
      group.setAttribute('class', 'clickable');
      const box = rect(x, y, WEAPON_BOX.width, WEAPON_BOX.height, LOOK.barBack, { stroke: LOOK.edge, rx: '2' });
      const fill = rect(x + 1, y + 1, 0, WEAPON_BOX.height - 2, LOOK.charge);
      group.appendChild(box); group.appendChild(fill);
      group.appendChild(text(x + 5, y + 14, String(index + 1), { size: 10, fill: LOOK.faint, weight: 'bold' }));
      group.appendChild(text(x + 16, y + 14, weapon.name, { size: 11 }));
      const target = text(x + WEAPON_BOX.width - 5, y + 14, '', { size: 9, anchor: 'end', fill: LOOK.faint });
      group.appendChild(target);
      const title = document.createElementNS(SVG, 'title');
      title.textContent = `${weapon.name} (key ${index + 1}): click to arm, then click an enemy room. Right click clears its target.`;
      group.appendChild(title);
      this.root.appendChild(group);
      this.weapons.set(weapon.mount, { box, fill, target });
    });
  }

  private buildCrew(crew: SnapshotCrew[], picture: ShipPicture): void {
    const shapeOf = new Map(picture.crew.map((member) => [member.race, member]));
    crew.forEach((member, index) => {
      const column = index % 3;
      const row = Math.floor(index / 3);
      const x = 6 + column * (CREW_BOX.width + CREW_BOX.gap);
      const y = ROW.crew + row * (CREW_BOX.height + CREW_BOX.gap);
      const group = document.createElementNS(SVG, 'g');
      group.dataset.action = 'crew';
      group.dataset.crewId = String(member.id);
      group.setAttribute('class', 'clickable');
      const box = rect(x, y, CREW_BOX.width, CREW_BOX.height, LOOK.barBack, { stroke: LOOK.edge, rx: '2' });
      group.appendChild(box);
      const look = shapeOf.get(member.race) ?? picture.crew[0];
      const shape = document.createElementNS(SVG, 'g');
      shape.setAttribute('transform', `translate(${x + 11} ${y + 11}) scale(0.7)`);
      shape.innerHTML = placeholderShape(look?.shape ?? 'QuestionMark', look?.colour ?? picture.powerColour);
      group.appendChild(shape);
      group.appendChild(text(x + 22, y + 10, member.name, { size: 9 }));
      group.appendChild(rect(x + 22, y + 14, CREW_BOX.width - 28, 4, LOOK.barBack));
      const health = rect(x + 22, y + 14, CREW_BOX.width - 28, 4, LOOK.health);
      group.appendChild(health);
      const title = document.createElementNS(SVG, 'title');
      title.textContent = `${member.name} (${member.race}): click to select, then click a tile on this ship.`;
      group.appendChild(title);
      this.root.appendChild(group);
      this.crew.set(member.id, { box, health, shape });
    });
  }

  /** The reactor's free bars first, then each system: bars stacked above its symbol, bottom bar first. */
  private buildSystems(ship: SnapshotShip): void {
    const symbolOf = new Map(this.picture.systems.map((system) => [system.key, system]));
    const reactor = document.createElementNS(SVG, 'g');
    for (let bar = 0; bar < ship.barsTotal; bar++) {
      const drawn = rect(6, ROW.bars - 4 - bar * (BAR.height + BAR.gap), BAR.width, BAR.height, LOOK.barEmpty);
      reactor.appendChild(drawn); this.reactorBars.push(drawn);
    }
    reactor.appendChild(text(6 + BAR.width / 2, ROW.icons + 14, 'free', { size: 8, anchor: 'middle', fill: LOOK.faint }));
    this.root.appendChild(reactor);

    ship.systems.forEach((system, index) => {
      const x = 6 + SYSTEM_STEP * (index + 1);
      const group = document.createElementNS(SVG, 'g');
      group.dataset.action = 'power';
      group.dataset.systemKey = system.key;
      group.setAttribute('class', 'clickable');
      const hit = rect(x - 3, ROW.bars - 60, SYSTEM_STEP - 2, ROW.icons + SYMBOL_BOX + 4 - (ROW.bars - 60), 'transparent');
      hit.appendChild(document.createElementNS(SVG, 'title'));
      group.appendChild(hit);
      const bars: SVGRectElement[] = [];
      for (let bar = 0; bar < system.maxBars; bar++) {
        const drawn = rect(x, ROW.bars - 4 - bar * (BAR.height + BAR.gap), BAR.width, BAR.height, LOOK.barEmpty);
        group.appendChild(drawn); bars.push(drawn);
      }
      const icon = document.createElementNS(SVG, 'g');
      icon.setAttribute('transform', `translate(${x - 2} ${ROW.icons})`);
      icon.setAttribute('color', this.picture.powerColour);
      icon.appendChild(systemSymbolElement(system.name, symbolOf.get(system.key)?.symbolSvg));
      group.appendChild(icon);
      this.root.appendChild(group);
      this.systems.set(system.key, { icon, bars, hit });
    });
  }
}
