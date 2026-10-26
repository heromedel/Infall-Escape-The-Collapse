/**
 * A race's crew traits as data (race profiles, point 9; coding rule 5): what one crew member of the race does on
 * a ship. Read from content/races/<folder>/race.xml. A race with no file gets the plain defaults.
 */

export interface RaceDefinition {
  name: string;
  /** Skill XP multiplier (GDD 7H). */
  xpRate: number;
  /** Bars a crew member adds to the system they man, never above its level (the Mecha's integration). */
  integrationBars: number;
}

export const DEFAULT_RACE: RaceDefinition = { name: 'Unknown', xpRate: 1, integrationBars: 0 };

/** Reads a race file's text. Small enough not to need its own reader class. */
export function readRaceDefinition(xmlText: string): RaceDefinition {
  const name = /<race\s[^>]*\bname="([^"]+)"/.exec(xmlText)?.[1];
  if (!name) throw new Error('the <race> element has no name="..."');
  const number = (attribute: string, fallback: number) => {
    const match = new RegExp(`\\b${attribute}="([^"]+)"`).exec(xmlText);
    const value = match ? Number(match[1]) : fallback;
    if (Number.isNaN(value)) throw new Error(`race "${name}": ${attribute}="${match![1]}" is not a number`);
    return value;
  };
  return { name, xpRate: number('xpRate', 1), integrationBars: number('integrationBars', 0) };
}
