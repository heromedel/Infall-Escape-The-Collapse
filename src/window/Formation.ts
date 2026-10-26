/**
 * Where each ship of a squad sits on screen (GDD 3H, Likely): a gentle curve facing the divider, the outer ships
 * forward and the centre ships back, noses along the curve, with some vertical overlap between neighbours. Curve
 * depth is a share of the squad's tallest ship, 0.7 by default; the inverted curve (centre forward) is a setting
 * (GDD 3I). Pure arithmetic, so it is tested without a window. Formation changes nothing in the simulation (3M).
 */

export interface Footprint {
  width: number;
  height: number;
}

export interface FormationSettings {
  /** Curve depth as a share of the tallest ship's height. */
  depth: number;
  /** Centre ships forward instead of back. */
  inverted: boolean;
}

export interface Slot {
  x: number;
  y: number;
}

/** Horizontal space between neighbouring ships: the first mockups' gap plus 35 percent (GDD 3H). */
const SHIP_GAP = 60 * 1.35;

/**
 * Lays the footprints out left to right. `facing` says where the divider is: 'down' for the enemy squad above
 * it, 'up' for the player squad below it. Returns each footprint's top-left corner and the whole layout's size.
 */
export function formationSlots(footprints: Footprint[], facing: 'up' | 'down', settings: FormationSettings): { slots: Slot[]; width: number; height: number } {
  if (footprints.length === 0) return { slots: [], width: 0, height: 0 };
  const tallest = Math.max(...footprints.map((print) => print.height));
  const count = footprints.length;
  // a lone ship has no curve: it sits on the front line
  const depth = count > 1 ? tallest * settings.depth : 0;
  const slots: Slot[] = [];
  let x = 0;
  footprints.forEach((print, index) => {
    // t runs from -1 at the left end to 1 at the right end; 0 for a lone ship or the exact centre
    const t = count === 1 ? 0 : (index / (count - 1)) * 2 - 1;
    // how far back from the front line this slot sits: centre ships back, outer ships forward (or the reverse)
    const backShare = settings.inverted ? t * t : 1 - t * t;
    const back = depth * backShare;
    // the front line is the divider's side: for a squad facing down, forward means a larger y
    const y = facing === 'down' ? depth - back + (tallest - print.height) : back;
    slots.push({ x, y });
    x += print.width + SHIP_GAP;
  });
  const width = x - SHIP_GAP;
  const height = tallest + depth;
  return { slots, width, height };
}
