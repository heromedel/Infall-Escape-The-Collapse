/**
 * The shared colours and placeholder shapes, one home for them (docs/art/palette.md, GDD 12D, 14D). The art
 * tools keep the same values in docs/art/palette.py; a shared colour changes in both places.
 */

export const COLOURS = {
  /** GDD 14D, Decided: every powered player system, power bar and intact system symbol. */
  powerGreen: '#66FF66',
  pirateOrange: '#FF8500',
  mechaPurple: '#AA28EB',
  tentauriPink: '#FF5ECA',
  azuretheaBlue: '#4F8FFF',
  sentiYellowGreen: '#D2FF00',
  whispwraithMagenta: '#FF00E6',
  lykarioSilver: '#D1DBE7',
  malphenFlesh: '#FFA480',
  /** A damaged or cut-off system, either side (GDD 14C; ideas, ship interior art). */
  damagedRed: '#FF3B3B',
} as const;

/** The power colour an enemy ship of each race shows (GDD 14D). "Pirate" is a colour name, not a race. */
export const POWER_COLOUR_BY_NAME: Record<string, string> = {
  Terran: COLOURS.powerGreen,
  Pirate: COLOURS.pirateOrange,
  Mecha: COLOURS.mechaPurple,
  Tentauri: COLOURS.tentauriPink,
  Azurethea: COLOURS.azuretheaBlue,
  'Senti-GPH': COLOURS.sentiYellowGreen,
  Lykario: COLOURS.lykarioSilver,
  Malphen: COLOURS.malphenFlesh,
  Whispwraith: COLOURS.whispwraithMagenta,
};

/** Placeholder shapes for crew with no art (GDD 12D, Likely). */
export type PlaceholderShape = 'Square' | 'Cross' | 'Triangle' | 'Star' | 'Diamond' | 'Crescent' | 'Circle' | 'QuestionMark';

export const PLACEHOLDER_SHAPE_BY_RACE: Record<string, PlaceholderShape> = {
  Terran: 'Square',
  Azurethea: 'Cross',
  Mecha: 'Triangle',
  Tentauri: 'Star',
  'Senti-GPH': 'Diamond',
  Lykario: 'Crescent',
  Malphen: 'Circle',
  Whispwraith: 'QuestionMark',
};

export function powerColourOf(name: string): string {
  return POWER_COLOUR_BY_NAME[name] ?? COLOURS.powerGreen;
}

export function placeholderShapeOf(race: string): PlaceholderShape {
  return PLACEHOLDER_SHAPE_BY_RACE[race] ?? 'QuestionMark';
}
