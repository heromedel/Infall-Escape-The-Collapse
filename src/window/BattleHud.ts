/**
 * The battle GUI as floating elements over the battle, placed as the genre places them (GDD 1C, 3J) and drawn
 * with our own icons and colours (GDD 14B, 14D): hull, shields and crew down the top-left; the reactor, the
 * powered systems and then the subsystems along the bottom-left; the weapons along the bottom; the enemy's hull
 * and shields top-right; the squad, the time and the pause state top-centre. Everything shows the selected
 * player ship. Drawn once per ship into a screen-sized SVG over the battle and updated in place, so a click
 * never lands on an element that was just replaced. Clickable parts carry data-action; BattleControls reads them.
 */

import type { ShipPicture } from '../shared/ShipPicture';
import type { Snapshot, SnapshotCrew, SnapshotShip, SnapshotSystem, SnapshotWeapon } from '../shared/Snapshot';
import { systemSymbolElement, SYMBOL_BOX } from './SystemSymbols.js';
import { group, placeholderShape, rect, text } from './HudBits.js';

const LOOK = {
  frame: 'rgba(29, 42, 58, 0.55)',
  edge: '#4a6a8a',
  text: '#ffffff',
  faint: '#9fb3c8',
  hull: '#66FF66',
  hullLow: '#FF3B3B',
  barBack: 'rgba(11, 16, 24, 0.7)',
  barEmpty: '#2a3a4e',
  shield: '#4F8FFF',
  shieldEmpty: '#263445',
  charge: '#2f6b4f',
  chargeFull: '#66FF66',
  armed: '#ffffff',
  auto: '#FF3B3B',
  once: '#FFE066',
  damaged: '#FF3B3B',
  enemy: '#FF8500',
};

const MARGIN = 16;
/** Room under the bottom rows for their labels (WEAPONS, SUBSYSTEMS), as the genre writes them. */
const LABEL_ROOM = 14;
/** The screen bands the GUI takes above and below the battle (GDD 3J), kept clear by the camera. */
export const GUI_BANDS = { top: 60, bottom: 130 };
const BAR = { width: 24, height: 6, step: 8 };
const SYSTEM_STEP = 42;
const WEAPON_BOX = { width: 160, height: 34, gap: 8 };
const AUTOFIRE_BOX = { width: 92, height: 34 };
const CREW_ROW = 24;

export interface HudSelection {
  armedMount?: number;
  selectedCrewId?: number;
  /** The mode the next room click gives: autofire (red) or fire once (yellow). */
  aimMode: 'auto' | 'once';
  /** The Autofire default, shown on its button. */
  autofire: boolean;
}

/** The elements built for one ship, updated in place while it stays selected. */
interface ShipElements {
  shipId: number;
  root: SVGGElement;
  topLeft: SVGGElement;
  bottomLeft: SVGGElement;
  /** The subsystems, anchored bottom-right as the genre's are. */
  bottomRight: SVGGElement;
  weapons: SVGGElement;
  systemsWidth: number;
  subsystemsWidth: number;
  hullBar: SVGRectElement;
  hullText: SVGTextElement;
  shieldPips: SVGCircleElement[];
  evasionText: SVGTextElement;
  reactorBars: SVGRectElement[];
  systems: Map<string, { icon: SVGGElement; bars: SVGRectElement[]; manned: SVGRectElement; hit: SVGRectElement; subsystem: boolean }>;
  weaponBoxes: Map<number, { box: SVGRectElement; fill: SVGRectElement; aimed: SVGTextElement; name: SVGTextElement; costBars: SVGRectElement[] }>;
  /** The mounts in slot order the row was built for; a reorder rebuilds it. */
  slotOrder: string;
  autofireBox: SVGRectElement;
  autofireText: SVGTextElement;
  crew: Map<number, { box: SVGRectElement; health: SVGRectElement; shape: SVGElement }>;
  weaponsWidth: number;
}

export class BattleHud {
  private elements?: ShipElements;
  private readonly topCentre: SVGGElement;
  private readonly squadText: SVGTextElement;
  private readonly pausedText: SVGTextElement;
  private readonly hintText: SVGTextElement;
  private readonly topRight: SVGGElement;
  private readonly enemyName: SVGTextElement;
  private readonly enemyHull: SVGRectElement;
  private readonly enemyPips: SVGCircleElement[] = [];

  constructor(private readonly hud: SVGSVGElement) {
    this.topCentre = group({ 'pointer-events': 'none' });
    this.squadText = text(0, 18, '', { size: 14, anchor: 'middle' });
    this.pausedText = text(0, 48, 'PAUSED', { size: 26, anchor: 'middle', weight: 'bold' });
    this.pausedText.setAttribute('letter-spacing', '6');
    this.hintText = text(0, 0, '', { size: 13, anchor: 'middle', fill: LOOK.faint });
    this.hintText.setAttribute('visibility', 'hidden');   // the control hints are off (heromedel, 2026-10-28): the tooltips carry them
    this.topCentre.append(this.squadText, this.pausedText, this.hintText);

    this.topRight = group({ 'pointer-events': 'none' });
    this.enemyName = text(0, 14, '', { size: 13, anchor: 'end' });
    this.topRight.appendChild(this.enemyName);
    this.topRight.appendChild(rect(-200, 20, 200, 12, LOOK.barBack));
    this.enemyHull = rect(-200, 20, 200, 12, LOOK.enemy);
    this.topRight.appendChild(this.enemyHull);
    for (let pip = 0; pip < 4; pip++) {
      const circle = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
      circle.setAttribute('cx', String(-6 - pip * 16)); circle.setAttribute('cy', '42'); circle.setAttribute('r', '6');
      this.topRight.appendChild(circle); this.enemyPips.push(circle);
    }
    hud.append(this.topCentre, this.topRight);
    window.addEventListener('resize', () => this.layout());
  }

  clear(): void {
    this.elements?.root.remove();
    this.elements = undefined;
    this.enemyName.textContent = '';
    this.squadText.textContent = '';
    this.hintText.textContent = '';
  }

  /** Redraws from the snapshot: builds the selected ship's elements when the selection changed. */
  update(snapshot: Snapshot, ship: SnapshotShip | undefined, picture: ShipPicture | undefined, selection: HudSelection, paused: boolean, hint: string): void {
    const player = snapshot.squads.find((squad) => squad.side === 'player');
    this.squadText.textContent = player ? `${player.name}  ·  Mawjig ${player.mawjig.toFixed(2)}  ·  ${snapshot.seconds.toFixed(1)} s` : '';
    this.pausedText.setAttribute('visibility', paused ? 'visible' : 'hidden');
    this.hintText.textContent = hint;
    this.updateEnemy(snapshot, ship);
    if (!ship || !picture) { this.elements?.root.remove(); this.elements = undefined; return; }
    const slotOrder = ship.weapons.map((weapon) => weapon.mount).join(',');
    if (!this.elements || this.elements.shipId !== ship.id || this.elements.slotOrder !== slotOrder) {
      this.elements?.root.remove();
      this.elements = this.build(ship, picture);
      this.hud.appendChild(this.elements.root);
    }
    this.updateShip(this.elements, ship, picture, selection);
    this.layout();
  }

  /** Anchors each block to its corner of the viewport, whatever the window size. */
  private layout(): void {
    const width = this.hud.clientWidth;
    const height = this.hud.clientHeight;
    this.topCentre.setAttribute('transform', `translate(${width / 2} ${MARGIN})`);
    this.topRight.setAttribute('transform', `translate(${width - MARGIN} ${MARGIN})`);
    if (!this.elements) return;
    this.elements.topLeft.setAttribute('transform', `translate(${MARGIN} ${MARGIN})`);
    const bottom = height - MARGIN - LABEL_ROOM;
    this.elements.bottomLeft.setAttribute('transform', `translate(${MARGIN} ${bottom})`);
    this.elements.bottomRight.setAttribute('transform', `translate(${width - MARGIN - this.elements.subsystemsWidth} ${bottom})`);
    // the weapons sit at the centre, but never over the systems row on the left or the subsystems on the right
    const leftEdge = MARGIN + this.elements.systemsWidth + 24;
    const rightEdge = width - MARGIN - this.elements.subsystemsWidth - 24 - this.elements.weaponsWidth;
    const x = Math.min(Math.max(width / 2 - this.elements.weaponsWidth / 2, leftEdge), Math.max(leftEdge, rightEdge));
    this.elements.weapons.setAttribute('transform', `translate(${x} ${bottom - WEAPON_BOX.height})`);
    this.hintText.setAttribute('y', String(bottom - WEAPON_BOX.height - 14));
  }

  // ---- building ------------------------------------------------------------------------------------------

  private build(ship: SnapshotShip, picture: ShipPicture): ShipElements {
    const root = group();
    const topLeft = group();
    const bottomLeft = group();
    const bottomRight = group();
    const weapons = group();
    root.append(topLeft, bottomLeft, bottomRight, weapons);

    // top-left: the ship's name, hull bar, shield bubbles and evasion, then the crew list
    topLeft.appendChild(text(0, 14, ship.name, { size: 13 }));
    topLeft.appendChild(rect(0, 20, 200, 14, LOOK.barBack));
    const hullBar = rect(0, 20, 200, 14, LOOK.hull);
    topLeft.appendChild(hullBar);
    const hullText = text(100, 31, '', { size: 11, anchor: 'middle', weight: 'bold', fill: '#0b1018' });
    topLeft.appendChild(hullText);
    const shieldPips: SVGCircleElement[] = [];
    for (let pip = 0; pip < 4; pip++) {
      const circle = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
      circle.setAttribute('cx', String(8 + pip * 16)); circle.setAttribute('cy', '46'); circle.setAttribute('r', '6');
      topLeft.appendChild(circle); shieldPips.push(circle);
    }
    const evasionText = text(200, 50, '', { size: 11, anchor: 'end', fill: LOOK.faint });
    topLeft.appendChild(evasionText);
    const crew = this.buildCrew(topLeft, ship.crew, picture, 64);

    // bottom-left: reactor stack, powered systems, then the subsystems a little apart
    const reactorBars: SVGRectElement[] = [];
    for (let bar = 0; bar < ship.barsTotal; bar++) {
      const drawn = rect(0, -SYMBOL_BOX - 12 - bar * BAR.step, BAR.width, BAR.height, LOOK.barEmpty);
      bottomLeft.appendChild(drawn); reactorBars.push(drawn);
    }
    bottomLeft.appendChild(text(BAR.width / 2, -2, 'free', { size: 9, anchor: 'middle', fill: LOOK.faint }));
    const { systems, systemsWidth, subsystemsWidth } = this.buildSystems(bottomLeft, bottomRight, ship, picture);

    // bottom: the weapon slots
    const weaponBoxes = this.buildWeapons(weapons, ship.weapons);
    // the Autofire button after the slots (genre reference frame 15): the default mode for every weapon
    const buttonX = ship.weapons.length * (WEAPON_BOX.width + WEAPON_BOX.gap);
    const button = group({ 'data-action': 'autofire', class: 'clickable' });
    const autofireBox = rect(buttonX, 0, AUTOFIRE_BOX.width, AUTOFIRE_BOX.height, LOOK.frame, { stroke: LOOK.edge, rx: '3' });
    const autofireText = text(buttonX + AUTOFIRE_BOX.width / 2, 21, 'AUTOFIRE', { size: 11, anchor: 'middle', weight: 'bold' });
    autofireText.setAttribute('letter-spacing', '1');
    const title = document.createElementNS('http://www.w3.org/2000/svg', 'title');
    title.textContent = 'Autofire: weapons keep their target and fire every time they charge. Key V. Holding Ctrl when clicking the room gives that target the opposite.';
    button.append(autofireBox, autofireText, title);
    weapons.appendChild(button);
    const weaponsWidth = buttonX + AUTOFIRE_BOX.width;
    weapons.appendChild(text(weaponsWidth / 2, WEAPON_BOX.height + 11, 'WEAPONS', { size: 9, anchor: 'middle', fill: LOOK.faint, weight: 'bold' }));

    return { shipId: ship.id, root, topLeft, bottomLeft, weapons, hullBar, hullText, shieldPips, evasionText, reactorBars, systems, weaponBoxes, autofireBox, autofireText, crew, weaponsWidth, bottomRight, systemsWidth, subsystemsWidth, slotOrder: ship.weapons.map((weapon) => weapon.mount).join(',') };
  }

  private buildCrew(into: SVGGElement, crew: SnapshotCrew[], picture: ShipPicture, top: number): ShipElements['crew'] {
    const built: ShipElements['crew'] = new Map();
    const shapeOf = new Map(picture.crew.map((member) => [member.race, member]));
    crew.forEach((member, index) => {
      const y = top + index * CREW_ROW;
      const row = group({ 'data-action': 'crew', 'data-crew-id': String(member.id), class: 'clickable' });
      const box = rect(0, y, 200, CREW_ROW - 3, LOOK.frame, { rx: '3' });
      row.appendChild(box);
      const look = shapeOf.get(member.race) ?? picture.crew[0];
      const shape = group({ transform: `translate(12 ${y + (CREW_ROW - 3) / 2}) scale(0.7)` });
      shape.innerHTML = placeholderShape(look?.shape ?? 'QuestionMark', look?.colour ?? picture.powerColour);
      row.appendChild(shape);
      row.appendChild(text(26, y + 14, member.name, { size: 11 }));
      row.appendChild(rect(106, y + 8, 88, 6, LOOK.barBack));
      const health = rect(106, y + 8, 88, 6, LOOK.hull);
      row.appendChild(health);
      const title = document.createElementNS('http://www.w3.org/2000/svg', 'title');
      title.textContent = `${member.name} (${member.race}): click to select, then click a tile on this ship.`;
      row.appendChild(title);
      into.appendChild(row);
      built.set(member.id, { box, health, shape });
    });
    return built;
  }

  /** Powered systems in file order after the reactor, bottom-left; the subsystems (no bars to give) bottom-right under their own label, as the genre's. */
  private buildSystems(left: SVGGElement, right: SVGGElement, ship: SnapshotShip, picture: ShipPicture): { systems: ShipElements['systems']; systemsWidth: number; subsystemsWidth: number } {
    const built: ShipElements['systems'] = new Map();
    const symbolOf = new Map(picture.systems.map((system) => [system.key, system]));
    const powered = ship.systems.filter((system) => system.maxBars > 0);
    const subsystems = ship.systems.filter((system) => system.maxBars === 0);
    let x = BAR.width + 16;
    let into = left;
    const place = (system: SnapshotSystem, subsystem: boolean) => {
      const column = group({ 'data-action': 'power', 'data-system-key': system.key, class: 'clickable', transform: `translate(${x} 0)` });
      const barCount = subsystem ? system.level : system.maxBars;
      const hit = rect(-6, -SYMBOL_BOX - 16 - barCount * BAR.step, SYSTEM_STEP - 6, SYMBOL_BOX + 20 + barCount * BAR.step, 'transparent');
      hit.appendChild(document.createElementNS('http://www.w3.org/2000/svg', 'title'));
      column.appendChild(hit);
      const bars: SVGRectElement[] = [];
      for (let bar = 0; bar < barCount; bar++) {
        const drawn = rect(0, -SYMBOL_BOX - 12 - bar * BAR.step, BAR.width, BAR.height, LOOK.barEmpty);
        column.appendChild(drawn); bars.push(drawn);
      }
      const manned = rect(BAR.width - 6, -SYMBOL_BOX - 4, 6, 3, picture.powerColour);
      column.appendChild(manned);
      const icon = group({ transform: `translate(${(BAR.width - SYMBOL_BOX * 1.3) / 2} ${-SYMBOL_BOX * 1.3 - 2}) scale(1.3)`, color: picture.powerColour });
      icon.appendChild(systemSymbolElement(system.name, symbolOf.get(system.key)?.symbolSvg));
      column.appendChild(icon);
      into.appendChild(column);
      built.set(system.key, { icon, bars, manned, hit, subsystem });
      x += SYSTEM_STEP;
    };
    for (const system of powered) place(system, false);
    const systemsWidth = x - 6;
    left.appendChild(text(systemsWidth / 2, 11, 'SYSTEMS', { size: 9, anchor: 'middle', fill: LOOK.faint, weight: 'bold' }));
    x = 6;
    into = right;
    for (const system of subsystems) place(system, true);
    const subsystemsWidth = Math.max(0, x - 6);
    right.appendChild(text(subsystemsWidth / 2, 11, 'SUBSYSTEMS', { size: 9, anchor: 'middle', fill: LOOK.faint, weight: 'bold' }));
    return { systems: built, systemsWidth, subsystemsWidth };
  }

  private buildWeapons(into: SVGGElement, weapons: SnapshotWeapon[]): ShipElements['weaponBoxes'] {
    const built: ShipElements['weaponBoxes'] = new Map();
    weapons.forEach((weapon, index) => {
      const x = index * (WEAPON_BOX.width + WEAPON_BOX.gap);
      const slot = group({ 'data-action': 'weapon', 'data-mount': String(weapon.mount), class: 'clickable' });
      const box = rect(x, 0, WEAPON_BOX.width, WEAPON_BOX.height, LOOK.frame, { stroke: LOOK.edge, rx: '3' });
      const fill = rect(x + 14, WEAPON_BOX.height - 9, 0, 8, LOOK.charge);
      slot.append(box, fill);
      // the weapon's cost as small bars on the slot's left edge, lit while it has them (genre reference frames 08, 52)
      const costBars: SVGRectElement[] = [];
      for (let bar = 0; bar < weapon.cost; bar++) {
        const drawn = rect(x + 4, WEAPON_BOX.height - 8 - bar * 7, 7, 5, LOOK.barEmpty);
        slot.appendChild(drawn); costBars.push(drawn);
      }
      slot.appendChild(text(x + 18, 16, String(index + 1), { size: 11, fill: LOOK.faint, weight: 'bold' }));
      const name = text(x + 30, 16, weapon.name, { size: 12 });
      slot.appendChild(name);
      const aimed = text(x + WEAPON_BOX.width - 6, 16, '', { size: 10, anchor: 'end', fill: LOOK.faint });
      slot.appendChild(aimed);
      const title = document.createElementNS('http://www.w3.org/2000/svg', 'title');
      title.textContent = `${weapon.name} (key ${index + 1}, ${weapon.cost} bar${weapon.cost === 1 ? '' : 's'}): click to power it or, powered, to arm it; then click an enemy room. Right click depowers it (Shift+${index + 1}); right click while aiming cancels. Drag to another slot to reorder.`;
      slot.appendChild(title);
      into.appendChild(slot);
      built.set(weapon.mount, { box, fill, aimed, name, costBars });
    });
    return built;
  }

  // ---- updating ------------------------------------------------------------------------------------------

  private updateShip(elements: ShipElements, ship: SnapshotShip, picture: ShipPicture, selection: HudSelection): void {
    const hullShare = ship.hullMax > 0 ? ship.hullPoints / ship.hullMax : 0;
    elements.hullBar.setAttribute('width', String(200 * hullShare));
    elements.hullBar.setAttribute('fill', hullShare < 0.34 ? LOOK.hullLow : LOOK.hull);
    elements.hullText.textContent = `${ship.hullPoints} / ${ship.hullMax}`;
    elements.shieldPips.forEach((pip, index) => {
      pip.setAttribute('fill', index < ship.shieldLayers ? LOOK.shield : LOOK.shieldEmpty);
      pip.setAttribute('visibility', index < ship.shieldLayersMax ? 'visible' : 'hidden');
    });
    elements.evasionText.textContent = `evade ${ship.evasionPercent}%`;
    elements.reactorBars.forEach((bar, index) => bar.setAttribute('fill', index < ship.barsTotal - ship.barsInUse ? picture.powerColour : LOOK.barEmpty));

    for (const system of ship.systems) {
      const drawn = elements.systems.get(system.key);
      if (!drawn) continue;
      const broken = !system.isWorking || system.damage > 0;
      drawn.icon.setAttribute('color', broken ? LOOK.damaged : picture.powerColour);
      drawn.manned.setAttribute('visibility', system.mannedBy !== undefined ? 'visible' : 'hidden');
      const barsPerLevel = drawn.subsystem ? 1 : system.maxBars / system.level;
      const barsDamagedAway = system.damage * barsPerLevel;
      drawn.bars.forEach((bar, index) => {
        const damagedAway = index >= drawn.bars.length - barsDamagedAway;
        const lit = drawn.subsystem ? !damagedAway : index < system.bars;
        bar.setAttribute('fill', damagedAway ? LOOK.damaged : lit ? picture.powerColour : LOOK.barEmpty);
      });
      drawn.hit.querySelector('title')!.textContent = drawn.subsystem
        ? `${system.key}: level ${system.level}, needs no power${system.damage > 0 ? `, ${system.damage} damage` : ''}${system.mannedBy !== undefined ? ', manned' : ''}.`
        : `${system.key}: ${system.bars} of ${system.maxBars} bars${system.damage > 0 ? `, ${system.damage} damage` : ''}${system.mannedBy !== undefined ? ', manned' : ''}. Click adds power, right click removes.`;
    }

    for (const weapon of ship.weapons) {
      const drawn = elements.weaponBoxes.get(weapon.mount);
      if (!drawn) continue;
      const armed = selection.armedMount === weapon.mount;
      const modeColour = selection.aimMode === 'auto' ? LOOK.auto : LOOK.once;
      drawn.fill.setAttribute('width', String((WEAPON_BOX.width - 15) * weapon.charge));
      drawn.fill.setAttribute('opacity', weapon.powered ? '1' : '0.4');
      drawn.costBars.forEach((bar) => bar.setAttribute('fill', weapon.powered ? picture.powerColour : LOOK.barEmpty));
      drawn.fill.setAttribute('fill', weapon.charge >= 1 ? LOOK.chargeFull : LOOK.charge);
      drawn.box.setAttribute('stroke', armed ? modeColour : LOOK.edge);
      drawn.box.setAttribute('stroke-width', armed ? '2' : '1');
      drawn.name.setAttribute('fill', weapon.powered ? LOOK.text : LOOK.faint);
      drawn.aimed.textContent = weapon.target ? (weapon.autofire ? 'auto' : 'once') : weapon.powered ? '' : 'no power';
      drawn.aimed.setAttribute('fill', weapon.target ? (weapon.autofire ? LOOK.auto : LOOK.once) : LOOK.faint);
    }

    elements.autofireBox.setAttribute('fill', selection.autofire ? 'rgba(255, 59, 59, 0.25)' : LOOK.frame);
    elements.autofireBox.setAttribute('stroke', selection.autofire ? LOOK.auto : LOOK.edge);
    elements.autofireText.setAttribute('fill', selection.autofire ? LOOK.auto : LOOK.faint);

    for (const member of ship.crew) {
      const drawn = elements.crew.get(member.id);
      if (!drawn) continue;
      const selected = selection.selectedCrewId === member.id;
      drawn.box.setAttribute('stroke', selected ? LOOK.armed : 'none');
      drawn.box.setAttribute('stroke-width', selected ? '2' : '0');
      drawn.health.setAttribute('width', String(88 * Math.max(0, member.health) / 100));
      drawn.health.setAttribute('fill', member.health < 34 ? LOOK.hullLow : LOOK.hull);
      drawn.shape.setAttribute('opacity', member.health <= 0 ? '0.25' : '1');
    }
  }

  /** Top-right: the enemy ship the selected ship is aiming at, else the first enemy still in the fight. */
  private updateEnemy(snapshot: Snapshot, ship: SnapshotShip | undefined): void {
    const enemies = snapshot.squads.filter((squad) => squad.side === 'enemy').flatMap((squad) => squad.ships);
    const aimedId = ship?.weapons.find((weapon) => weapon.target)?.target?.shipId;
    const enemy = enemies.find((candidate) => candidate.id === aimedId) ?? enemies.find((candidate) => !candidate.isGone) ?? enemies[0];
    if (!enemy) { this.enemyName.textContent = ''; this.topRight.setAttribute('visibility', 'hidden'); return; }
    this.topRight.setAttribute('visibility', 'visible');
    this.enemyName.textContent = enemy.name;
    const share = enemy.hullMax > 0 ? enemy.hullPoints / enemy.hullMax : 0;
    this.enemyHull.setAttribute('x', String(-200 * share));
    this.enemyHull.setAttribute('width', String(200 * share));
    this.enemyPips.forEach((pip, index) => {
      pip.setAttribute('fill', index < enemy.shieldLayers ? LOOK.shield : LOOK.shieldEmpty);
      pip.setAttribute('visibility', index < enemy.shieldLayersMax ? 'visible' : 'hidden');
    });
  }
}
