/**
 * Where each ship of a squad sits on screen (GDD 3S): the formation file's zones on the tile grid, each ship
 * centred in its slot's zone and snapped to the grid, rows counting away from the barrier. Pure arithmetic, so
 * it is tested without a window. Formation changes nothing in the simulation (3M).
 */

import type { FormationDefinition } from '../shared/Formation';

export interface Footprint {
  width: number;
  height: number;
  /** Room above the hull for its tag, inside the height; not part of the hull, so it may lie outside the zone. The hull art's overhang is hull. */
  tag?: number;
}

export interface Slot {
  x: number;
  y: number;
}

/** A ship tile in ship pixels; the grid cell. */
export const CELL = 35;

/**
 * Lays the footprints into the formation's zones, in slot order. `facing` says where the barrier is: 'down' for
 * the enemy squad above it, 'up' for the player squad below it. Returns each footprint's top-left corner in
 * squad pixels (the squad's own top-left is 0,0; the barrier side is its bottom for 'down', its top for 'up')
 * and the squad's size, which covers every used zone. The player side's zones are shifted right by the file's
 * shift, and both sides' by the file's margin, which the field also keeps open on the right. A footprint is centred in its zone, then snapped to the cell so rooms line up across ships.
 */
export interface ZoneBox {
  slot: number;
  x: number;
  y: number;
  size: number;
}

export function formationSlots(footprints: Footprint[], facing: 'up' | 'down', formation: FormationDefinition): { slots: Slot[]; width: number; height: number; zones: ZoneBox[] } {
  const zone = formation.zoneSize * CELL;
  // the player's zones are shifted right; both sides' zones are moved in by the open margin on the left
  const shiftColumns = (facing === 'up' ? formation.shift : 0) + formation.margin;
  const used = footprints.map((_, index) => formation.zones[Math.min(index, formation.zones.length - 1)]);
  // the field spans every zone of the file, used or not: the barrier runs across the whole battlefield (GDD 3R)
  const columnsAcross = Math.max(...formation.zones.map((z) => z.column)) + formation.zoneSize + shiftColumns + formation.margin;
  // a hull taller than its zone overflows away from the barrier, never into it; the squad grows to hold it
  const overflow = Math.max(0, ...footprints.map((print) => hullHeight(print) - zone));
  const rowsDeep = Math.max(...formation.zones.map((z) => z.row)) + formation.zoneSize + Math.ceil(overflow / CELL);
  const width = columnsAcross * CELL;
  const height = rowsDeep * CELL;
  const zones: ZoneBox[] = formation.zones.map((z) => ({
    slot: z.slot, size: zone,
    x: (z.column + shiftColumns) * CELL,
    y: facing === 'down' ? height - (z.row + formation.zoneSize) * CELL : z.row * CELL,
  }));
  if (footprints.length === 0) return { slots: [], width, height, zones };
  const slots = footprints.map((print, index) => {
    const z = used[index];
    const left = (z.column + shiftColumns) * CELL;
    const hull = hullHeight(print);
    const tag = print.tag ?? 0;
    // the hull is centred in the zone; a taller hull keeps its nose at the zone's barrier edge and overflows away
    const inset = Math.max(0, (zone - hull) / 2);
    const x = snap(left + (zone - print.width) / 2);
    let y: number;
    if (facing === 'up') {
      // barrier above: the zone's top is its barrier edge; the footprint's top (tag) sits above the hull
      const zoneTop = z.row * CELL;
      y = snap(zoneTop + inset) - tag;
    } else {
      // barrier below: the zone's bottom is its barrier edge
      const zoneBottom = height - z.row * CELL;
      y = snap(zoneBottom - inset - hull) - tag;
    }
    return { x, y };
  });
  return { slots, width, height, zones };
}

function hullHeight(print: Footprint): number {
  return print.height - (print.tag ?? 0);
}

/** The nearest cell edge. */
function snap(value: number): number {
  return Math.round(value / CELL) * CELL;
}
