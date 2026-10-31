/** Formations (GDD 3S): zones on the tile grid from a file, ships centred and snapped; bad files refused. */

import { describe, expect, it } from 'vitest';
import * as fs from 'node:fs';
import * as path from 'node:path';
import { formationSlots, CELL } from '../src/window/Formation';
import { readFormationDefinition } from '../src/simulation/content/FormationDefinition';

const curve = readFormationDefinition(fs.readFileSync(path.join(__dirname, '..', 'content', 'formations', 'curve', 'formation.xml'), 'utf8'));
const three = [{ width: 100, height: 200 }, { width: 100, height: 200 }, { width: 100, height: 200 }];

describe('formation files', () => {
  it('reads the curve: six zones sized for the largest hull art (24 cells, measured), slot 1 first, a player shift', () => {
    expect(curve.name).toBe('Curve');
    expect(curve.zoneSize).toBe(24);
    expect(curve.shift).toBeGreaterThan(0);
    expect(curve.zones.map((zone) => zone.slot)).toEqual([1, 2, 3, 4, 5, 6]);
    expect(curve.zones[2].row).toBeGreaterThan(curve.zones[0].row);   // the centre ship sits back from the barrier
    expect(Math.min(...curve.zones.map((zone) => zone.row))).toBeGreaterThanOrEqual(6);   // no ship crowds the barrier
    expect(curve.margin).toBeGreaterThan(0);   // the barrier runs past the outermost ships
  });
  it('keeps the margin open on both sides of the field', () => {
    const withMargin = formationSlots(three, 'up', curve);
    const without = formationSlots(three, 'up', { ...curve, margin: 0 });
    expect(withMargin.width).toBe(without.width + 2 * curve.margin * CELL);
    expect(withMargin.slots[0].x).toBe(without.slots[0].x + curve.margin * CELL);
  });
  it('refuses overlapping zones and gaps in the slot numbers', () => {
    expect(() => readFormationDefinition('<formation name="Bad" zoneSize="12"><zone slot="1" column="0" row="0"/><zone slot="2" column="6" row="3"/></formation>')).toThrow(/overlap/);
    expect(() => readFormationDefinition('<formation name="Bad" zoneSize="12"><zone slot="1" column="0" row="0"/><zone slot="3" column="20" row="0"/></formation>')).toThrow(/without gaps/);
  });
});

describe('formation layout', () => {
  it('centres each ship in its slot\'s zone, snapped to the grid, with space on every side (the zone stays the same size whatever sits in it)', () => {
    const player = formationSlots(three, 'up', curve);
    for (const slot of player.slots) { expect(slot.x % CELL).toBe(0); expect(slot.y % CELL).toBe(0); }
    player.slots.forEach((slot, index) => {
      const zone = player.zones[index];
      const print = three[index];
      // centred: the gap on the left is within a cell of the gap on the right, same above and below
      expect(Math.abs((slot.x - zone.x) - (zone.x + zone.size - slot.x - print.width))).toBeLessThanOrEqual(CELL);
      expect(Math.abs((slot.y - zone.y) - (zone.y + zone.size - slot.y - print.height))).toBeLessThanOrEqual(CELL);
      // and well inside: at least 8 cells clear on each side for a 100 by 200 ship in a 24-cell zone
      expect(slot.x - zone.x).toBeGreaterThanOrEqual(8 * CELL);
      expect(slot.y - zone.y).toBeGreaterThanOrEqual(8 * CELL);
    });
  });
  it('spans the whole field, every zone of the file, so the barrier runs edge to edge', () => {
    const one = formationSlots([three[0]], 'up', curve);
    const all = formationSlots(three.concat(three), 'up', curve);
    expect(one.width).toBe(all.width);
    expect(one.zones).toHaveLength(6);
  });
  it('counts rows away from the barrier on both sides, so the centre ship is further from it than the outer ships', () => {
    const player = formationSlots(three, 'up', curve);     // barrier above: further away is larger y
    expect(player.slots[1].y).toBeGreaterThan(player.slots[0].y);
    const enemy = formationSlots(three, 'down', curve);    // barrier below: further away is smaller y
    expect(enemy.slots[1].y).toBeLessThan(enemy.slots[0].y);
  });
  it('shifts the player side right by the file\'s shift and keeps the enemy side at the left', () => {
    const player = formationSlots([three[0]], 'up', curve);
    const enemy = formationSlots([three[0]], 'down', curve);
    expect(player.slots[0].x - enemy.slots[0].x).toBe(curve.shift * CELL);
  });
});
