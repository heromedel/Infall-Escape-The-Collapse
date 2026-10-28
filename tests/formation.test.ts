/** The formation curve (GDD 3H): outer ships forward, centre back, mirrored across the divider; inverted on request. */

import { describe, expect, it } from 'vitest';
import { formationSlots } from '../src/window/Formation';

const three = [{ width: 100, height: 200 }, { width: 100, height: 200 }, { width: 100, height: 200 }];

describe('formation', () => {
  it('puts the centre ship back by the curve depth and the outer ships on the front line', () => {
    const player = formationSlots(three, 'up', { depth: 0.7, inverted: false });
    expect(player.slots.map((slot) => slot.y)).toEqual([0, 140, 0]);          // facing up: forward is smaller y
    const enemy = formationSlots(three, 'down', { depth: 0.7, inverted: false });
    expect(enemy.slots.map((slot) => slot.y)).toEqual([140, 0, 140]);         // facing down: forward is larger y
    expect(player.height).toBe(340);
  });
  it('inverts to centre forward when asked (GDD 3I)', () => {
    const player = formationSlots(three, 'up', { depth: 0.7, inverted: true });
    expect(player.slots.map((slot) => slot.y)).toEqual([140, 0, 140]);
  });
  it('spaces ships 35 percent wider than the first mockups and keeps a lone ship at the front', () => {
    const layout = formationSlots(three, 'up', { depth: 0.7, inverted: false });
    expect(layout.slots[1].x - layout.slots[0].x).toBe(100 + 81);
    expect(formationSlots([three[0]], 'up', { depth: 0.7, inverted: false }).slots[0].y).toBe(0);
  });
});
