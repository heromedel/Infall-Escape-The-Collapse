/** Formations (GDD 3S): zones on the tile grid from a file, ships centred and snapped; bad files refused. */

import { describe, expect, it } from 'vitest';
import * as fs from 'node:fs';
import * as path from 'node:path';
import { formationSlots, CELL } from '../src/window/Formation';
import { readFormationDefinition } from '../src/simulation/content/FormationDefinition';

const curve = readFormationDefinition(fs.readFileSync(path.join(__dirname, '..', 'content', 'formations', 'curve', 'formation.xml'), 'utf8'));
const three = [{ width: 100, height: 200 }, { width: 100, height: 200 }, { width: 100, height: 200 }];

describe('formation files', () => {
  it('reads the curve: six zones of 12 cells, slot 1 first, player shift 4', () => {
    expect(curve.name).toBe('Curve');
    expect(curve.zoneSize).toBe(12);
    expect(curve.shift).toBe(4);
    expect(curve.zones.map((zone) => zone.slot)).toEqual([1, 2, 3, 4, 5, 6]);
    expect(curve.zones[2].row).toBeGreaterThan(curve.zones[0].row);   // the centre ship sits back from the barrier
  });
  it('refuses overlapping zones and gaps in the slot numbers', () => {
    expect(() => readFormationDefinition('<formation name="Bad" zoneSize="12"><zone slot="1" column="0" row="0"/><zone slot="2" column="6" row="3"/></formation>')).toThrow(/overlap/);
    expect(() => readFormationDefinition('<formation name="Bad" zoneSize="12"><zone slot="1" column="0" row="0"/><zone slot="3" column="20" row="0"/></formation>')).toThrow(/without gaps/);
  });
});

describe('formation layout', () => {
  it('centres each ship in its slot\'s zone and snaps it to the grid', () => {
    const player = formationSlots(three, 'up', curve);
    for (const slot of player.slots) { expect(slot.x % CELL).toBe(0); expect(slot.y % CELL).toBe(0); }
    // zone 1 of the player side starts at column shift (4): the ship is centred in a 12-cell zone, so about 4 + (12 cells - 100 px) / 2 from the left
    const zoneLeft = (curve.zones[0].column + curve.shift) * CELL;
    expect(Math.abs(player.slots[0].x - (zoneLeft + (12 * CELL - 100) / 2))).toBeLessThan(CELL);
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
