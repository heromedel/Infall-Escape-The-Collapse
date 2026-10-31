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
   * Battle GUI (GDD 1C, 3J): Floating > Card. Floating: the genre's placement, elements over the battle. Card:
   * one panel in the bottom-left corner. Not in the docs yet.
   */
  battleGui: BattleGui = 'floating';
  /** Autofire: Off > On (the genre's default for every weapon; Ctrl at the room click gives the opposite). */
  autofire = false;
  /** Target Lines: Off > On. A dashed line from the ship to each target room, on top of the genre's room marks. */
  targetLines = false;
}

export type BattleGui = 'floating' | 'card';
