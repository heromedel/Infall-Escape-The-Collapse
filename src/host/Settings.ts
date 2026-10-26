/**
 * The settings in play (GDD 1K, 4G, 14D). For now only what the debug console can change; the settings screen
 * comes with the GUI. Settings are written default first in the docs, and the default is the value here.
 */

import { COLOURS } from '../simulation/content/Palette';

export class Settings {
  /** Player Power Color (GDD 14D): Default (Green) > Racial > Specific Color. The colour in use. */
  playerPowerColour: string = COLOURS.powerGreen;
}
