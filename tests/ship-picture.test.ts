/**
 * The picture the window draws from: the Outrider lands on a 5 by 13 grid, its airlocks face space, and a ship
 * with Point centering leaves no gap where x = 0 would be.
 */

import { describe, expect, it } from 'vitest';
import * as fs from 'node:fs';
import * as path from 'node:path';
import { ShipFileReader } from '../src/simulation/content/ShipFileReader';
import { shipPictureOf } from '../src/host/ShipPicture';
import type { ContentLibrary } from '../src/host/ContentLibrary';
import { Settings } from '../src/host/Settings';
import { COLOURS } from '../src/simulation/content/Palette';

const shipsFolder = path.join(__dirname, '..', 'content', 'ships');
const reader = new ShipFileReader();

function pictureOf(folder: string, side: 'player' | 'enemy' = 'player') {
  const definition = reader.readShip(fs.readFileSync(path.join(shipsFolder, folder, 'ship.xml'), 'utf8'));
  const noSystems = { system: () => undefined } as unknown as ContentLibrary;
  return shipPictureOf({ definition, folder: path.join(shipsFolder, folder) }, side, noSystems, new Settings());
}

describe('the Outrider picture', () => {
  const picture = pictureOf('outrider');
  it('is 5 columns by 13 rows with every room tile on the floor', () => {
    expect(picture.columns).toBe(5);
    expect(picture.rows).toBe(13);
    expect(picture.floorTiles).toHaveLength(47);
  });
  it('marks the four doors that face space as airlocks', () => {
    expect(picture.doors.filter((door) => door.airlock).map((door) => door.id)).toEqual([10, 11, 12, 13]);
  });
  it('carries the hull SVG with the grid origin the art tools used', () => {
    expect(picture.hullArt?.kind).toBe('svg');
    expect(picture.hullArt?.width).toBe(460);
    expect(picture.hullArt?.gridX).toBe(142.5);
  });
  it('stands its three crew on tiles, in power green on the player side', () => {
    expect(picture.crew).toHaveLength(3);
    expect(picture.crew[0].shape).toBe('Square');
    expect(picture.crew.every((member) => member.colour === COLOURS.powerGreen)).toBe(true);
  });
});

describe('a Point-centred ship', () => {
  it('maps x = -1 and x = 1 onto neighbouring columns', () => {
    const picture = pictureOf('light-attack-frame', 'enemy');
    expect(picture.columns).toBe(6);
    const columns = picture.systems.map((system) => [system.key, system.column]);
    expect(columns).toContainEqual(['Piloting', 2]);
    expect(columns).toContainEqual(['Shields', 3]);
    expect(picture.powerColour).toBe(COLOURS.mechaPurple);
    expect(picture.hullArt?.kind).toBe('png');
    expect(picture.hullArt?.width).toBe(340);
  });
  it('shows a pirate hull in pirate orange on the enemy side', () => {
    expect(pictureOf('pirate-hijacker', 'enemy').powerColour).toBe(COLOURS.pirateOrange);
  });
});

describe('the player power colour setting', () => {
  it('colours the player side from the setting, by palette name or hex', async () => {
    const { parsePowerColour } = await import('../src/simulation/content/Palette');
    expect(parsePowerColour('mecha')).toBe(COLOURS.mechaPurple);
    expect(parsePowerColour('#AA28EB')).toBe('#AA28EB');
    expect(parsePowerColour('plaid')).toBeUndefined();
  });
});
