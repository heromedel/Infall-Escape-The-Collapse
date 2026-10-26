/**
 * The settings in play (GDD 1K, 4G, 14D). For now only what the debug console can change; the settings screen
 * comes with the GUI. Settings are written default first in the docs, and the default is the value here.
 */

import { COLOURS } from '../simulation/content/Palette';
import { secondsToTicks } from '../simulation/Ticks';

export class Settings {
  /** Player Power Color (GDD 14D): Default (Green) > Racial > Specific Color. The colour in use. */
  playerPowerColour: string = COLOURS.powerGreen;
  /** Turn Mode (GDD 4I): Auto Pause Off > On, and its interval, stored in ticks and shown in seconds. */
  autoPause = false;
  autoPauseIntervalTicks = secondsToTicks(10);
  /** Squad formation (GDD 3H, 3I): curve depth as a share of the tallest ship, and the inverted curve. */
  formationDepth = 0.7;
  formationInverted = false;
  /**
   * Ship Panel (GDD 3B, Proposed): Beside Ship > Docked. Beside: the selected ship's panel sits under its hull
   * and zooms with it. Docked: the panel sits in the bottom GUI band (3J) at screen scale.
   */
  shipPanel: ShipPanelPlace = 'beside';
}

export type ShipPanelPlace = 'beside' | 'docked';
