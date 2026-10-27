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
   * Ship Panel (GDD 3B, Proposed): Docked > Beside Ship. Docked: the panel sits over the battle's bottom-left
   * corner at screen scale, as the genre's does. Beside: it sits under the selected ship's hull and zooms with it.
   * Not in the docs yet: docked is the default because a hull-scale panel is unreadable once the camera is out far
   * enough to show both squads.
   */
  shipPanel: ShipPanelPlace = 'docked';
}

export type ShipPanelPlace = 'beside' | 'docked';
