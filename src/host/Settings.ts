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
  /** Player Formation and Enemy Formation (GDD 3S): formation files by name; Curve > the others loaded. */
  playerFormation = 'Curve';
  enemyFormation = 'Curve';
  /**
   * Battle GUI (GDD 1C, 3J): Floating > Card. Floating: the genre's placement, elements over the battle. Card:
   * one panel in the bottom-left corner. Not in the docs yet.
   */
  battleGui: BattleGui = 'floating';
  /** Autofire: Off > On (the genre's default for every weapon; Ctrl at the room click gives the opposite). */
  autofire = false;
  /** Target Lines: Off > On. A dashed line from the ship to each target room, on top of the genre's room marks. */
  targetLines = false;
  /** Shots Crossing Barrier (GDD 3R): Shown > Hidden, the tiny faint dash of a shot crossing the strip. */
  shotsCrossingBarrier = true;
  /** Show Zones (debug): Off > On, the formation zones drawn translucent. */
  showZones = false;
}

export type BattleGui = 'floating' | 'card';
