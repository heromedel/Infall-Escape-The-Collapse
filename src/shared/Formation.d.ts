/**
 * A formation (GDD 3S): six zones a side on the tile grid, each a square of zoneSize cells placed by its top-left
 * cell, rows counting away from the barrier. Types only, shared by the host (loading), the window (laying out)
 * and the simulation (reading the file).
 */

export interface FormationZone {
  slot: number;
  column: number;
  row: number;
}

export interface FormationDefinition {
  name: string;
  /** Each zone's side in grid cells: the largest hull plus a margin. */
  zoneSize: number;
  /** The player side's zones shifted right by this many columns (GDD 3R squad offset). */
  shift: number;
  zones: FormationZone[];
}
