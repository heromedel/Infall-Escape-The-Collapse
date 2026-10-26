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
  /** The disc behind a system symbol, standing in for the console until console art exists (heromedel, 2026-10-26). */
  consoleBlue: '#1C242C',
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

/** The plain colour words of the palette, so "blue" means Azurethea power blue. */
export const POWER_COLOUR_BY_WORD: Record<string, string> = {
  green: COLOURS.powerGreen,
  orange: COLOURS.pirateOrange,
  purple: COLOURS.mechaPurple,
  pink: COLOURS.tentauriPink,
  blue: COLOURS.azuretheaBlue,
  'yellow-green': COLOURS.sentiYellowGreen,
  magenta: COLOURS.whispwraithMagenta,
  silver: COLOURS.lykarioSilver,
  flesh: COLOURS.malphenFlesh,
};

/**
 * A power colour from a race or palette name ("Mecha", "Pirate"), a colour word ("blue"), or a hex value with or
 * without its # ("aa28eb"); nothing if it is none of these. Several words are joined, so "power blue" works.
 */
export function parsePowerColour(text: string): string | undefined {
  const trimmed = text.trim().replace(/^power\s+/i, '');
  if (/^#?[0-9a-f]{6}$/i.test(trimmed)) return `#${trimmed.replace('#', '')}`.toUpperCase();
  const wanted = trimmed.toLowerCase();
  const byName = Object.keys(POWER_COLOUR_BY_NAME).find((name) => name.toLowerCase() === wanted);
  if (byName) return POWER_COLOUR_BY_NAME[byName];
  return POWER_COLOUR_BY_WORD[wanted];
}

/**
 * The power colour an enemy ship shows: its own colour name when the ship file gives one, else its race's. An
 * enemy Terran ship reads as a pirate and shows pirate orange (heromedel, 2026-10-26; the setting
 * `Enemy Terran Color: Pirate Power Orange > Power Green` is Proposed in GDD 14D and not built yet).
 */
export function enemyPowerColourOf(race: string, colourName?: string): string {
  if (colourName) return powerColourOf(colourName);
  return race === 'Terran' ? COLOURS.pirateOrange : powerColourOf(race);
}

export function placeholderShapeOf(race: string): PlaceholderShape {
  return PLACEHOLDER_SHAPE_BY_RACE[race] ?? 'QuestionMark';
}
