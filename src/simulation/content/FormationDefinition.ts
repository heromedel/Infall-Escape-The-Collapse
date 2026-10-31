/**
 * Reads a formation file (GDD 3S; the types are in src/shared/Formation.d.ts). No file or DOM code. Zones that
 * overlap each other refuse the file: a formation is a layout, and an overlapping one is not.
 */

import type { FormationDefinition, FormationZone } from '../../shared/Formation';
export type { FormationDefinition, FormationZone };

export class FormationFileError extends Error {}

export function readFormationDefinition(xmlText: string): FormationDefinition {
  const head = /<formation\s([^>]*)>/.exec(xmlText);
  if (!head) throw new FormationFileError('no <formation> element');
  const attribute = (name: string, from: string) => new RegExp(`\\b${name}="([^"]*)"`).exec(from)?.[1];
  const name = attribute('name', head[1]);
  if (!name) throw new FormationFileError('the <formation> element has no name="..."');
  const number = (what: string, text: string | undefined, fallback?: number) => {
    if (text === undefined) { if (fallback !== undefined) return fallback; throw new FormationFileError(`formation "${name}": ${what} is missing`); }
    const value = Number(text);
    if (!Number.isInteger(value) || value < 0) throw new FormationFileError(`formation "${name}": ${what}="${text}" is not a whole number of cells`);
    return value;
  };
  const zoneSize = number('zoneSize', attribute('zoneSize', head[1]), 12);
  const shift = number('shift', attribute('shift', head[1]), 0);
  const margin = number('margin', attribute('margin', head[1]), 0);
  const zones: FormationZone[] = [];
  for (const match of xmlText.matchAll(/<zone\s([^>]*)\/?>/g)) {
    const slot = number('zone slot', attribute('slot', match[1]));
    zones.push({ slot, column: number(`zone ${slot} column`, attribute('column', match[1])), row: number(`zone ${slot} row`, attribute('row', match[1])) });
  }
  if (zones.length === 0) throw new FormationFileError(`formation "${name}" has no zones`);
  zones.sort((a, b) => a.slot - b.slot);
  zones.forEach((zone, index) => { if (zone.slot !== index + 1) throw new FormationFileError(`formation "${name}": zone slots must run 1, 2, 3… without gaps (found slot ${zone.slot} at position ${index + 1})`); });
  for (const a of zones) for (const b of zones) {
    if (a.slot < b.slot && Math.abs(a.column - b.column) < zoneSize && Math.abs(a.row - b.row) < zoneSize) {
      throw new FormationFileError(`formation "${name}": zones ${a.slot} and ${b.slot} overlap`);
    }
  }
  return { name, zoneSize, shift, margin, zones };
}
