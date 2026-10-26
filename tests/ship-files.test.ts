/**
 * Every ship and loadout in content/ships reads and passes the checks, and a broken loadout is refused with a
 * reason that says what is wrong.
 */

import { describe, expect, it } from 'vitest';
import * as fs from 'node:fs';
import * as path from 'node:path';
import { ShipFileReader, ShipFileError } from '../src/simulation/content/ShipFileReader';
import { checkShip } from '../src/simulation/content/ShipChecks';
import { systemKey } from '../src/simulation/content/ShipDefinition';
import { tileKey } from '../src/simulation/content/Tile';

const shipsFolder = path.join(__dirname, '..', 'content', 'ships');
const reader = new ShipFileReader();

function read(folder: string, file: string): string {
  return fs.readFileSync(path.join(shipsFolder, folder, file), 'utf8');
}

describe('every ship folder', () => {
  for (const folder of fs.readdirSync(shipsFolder).sort()) {
    const shipText = read(folder, 'ship.xml');
    it(`${folder}/ship.xml reads and passes the checks`, () => {
      const ship = reader.readShip(shipText);
      const result = checkShip(ship);
      expect(result.refusals).toEqual([]);
      expect(result.warnings).toEqual([]);
    });
    for (const loadoutFile of fs.readdirSync(path.join(shipsFolder, folder)).filter((file) => file.startsWith('loadout.'))) {
      it(`${folder}/${loadoutFile} reads and passes the checks`, () => {
        const ship = reader.readLoadout(shipText, read(folder, loadoutFile));
        const result = checkShip(ship);
        expect(result.refusals).toEqual([]);
        expect(result.warnings).toEqual([]);
      });
    }
  }
});

describe('the Outrider', () => {
  const ship = reader.readShip(read('outrider', 'ship.xml'));
  it('has the rooms, systems, doors and conduits of its layout', () => {
    expect(ship.rooms).toHaveLength(10);
    expect(ship.systems.map(systemKey)).toContain('Life Support');
    expect(ship.doors).toHaveLength(14);
    expect(ship.conduits).toHaveLength(41);
    expect(ship.power).toEqual({ kind: 'AZC', level: 2 });
  });
  it('reads a tile with no directions as a full intersection (GDD 5H)', () => {
    const core = ship.conduits.find((conduit) => tileKey(conduit.tile) === '0,1')!;
    expect(core.runs).toEqual(['North', 'South', 'East', 'West']);
  });
});

describe('the Cutpurse loadout', () => {
  const ship = reader.readLoadout(read('pirate-hijacker', 'ship.xml'), read('pirate-hijacker', 'loadout.cutpurse.xml'));
  it('is named after the loadout and remembers its base ship', () => {
    expect(ship.name).toBe('Terran Pirate Cutpurse');
    expect(ship.baseShip).toBe('Terran Pirate Hijacker');
  });
  it('keeps unlisted entries, removes the removed ones and keeps a patched system on its tile', () => {
    const names = ship.systems.map(systemKey);
    expect(names).not.toContain('Sensors');
    expect(names).not.toContain('Medbay');
    expect(names).toContain('AZC');
    const shields = ship.systems.find((system) => system.name === 'Shields')!;
    expect(shields.level).toBe(1);
    expect(tileKey(shields.tile)).toBe('-2,-3');
    expect(shields.wall).toBe('West');
  });
  it('patches conduits tile by tile and replaces the weapon list whole', () => {
    expect(ship.conduits.some((conduit) => tileKey(conduit.tile) === '-1,-2')).toBe(false);
    expect(ship.conduits.find((conduit) => tileKey(conduit.tile) === '-2,-2')!.runs).toEqual(['North', 'South']);
    expect(ship.weapons.map((weapon) => weapon.name)).toEqual(['Sporewing']);
    expect(ship.hullPoints).toBe(9);
  });
});

describe('refusals', () => {
  const frame = read('light-attack-frame', 'ship.xml');
  it('refuses a door and a system on a tile whose room was removed, and says so', () => {
    const loadout = `<loadout ship="Light Attack Frame" name="Broken" inherit="Patch">
      <rooms><room id="5" removed="true"/></rooms>
      <doors><door id="9" tile="2,2" facing="South"/></doors>
    </loadout>`;
    const result = checkShip(reader.readLoadout(frame, loadout));
    expect(result.refusals).toEqual([
      'system Life Support is on tile 2,2, which is in no room',
      'door 9 is on tile 2,2, which is in no room',
    ]);
  });
  it('refuses removing something the ship does not have', () => {
    const loadout = `<loadout ship="Light Attack Frame" name="Broken" inherit="Patch">
      <systems><system name="Cloaking" removed="true"/></systems>
    </loadout>`;
    expect(() => reader.readLoadout(frame, loadout)).toThrow(ShipFileError);
    expect(() => reader.readLoadout(frame, loadout)).toThrow('removes system Cloaking, which the ship doesn\'t have');
  });
  it('refuses a loadout written for another ship', () => {
    const loadout = `<loadout ship="SC-1 Outrider" name="Wrong" inherit="Patch"/>`;
    expect(() => reader.readLoadout(frame, loadout)).toThrow('is for ship "SC-1 Outrider"');
  });
  it('refuses a ship with no airlock (GDD 5D)', () => {
    const ship = `<ship name="Box" race="Terran"><hull points="1"/><power kind="Reactor" bars="1"/>
      <rooms><room id="0" from="0,0" to="1,1"/></rooms></ship>`;
    expect(checkShip(reader.readShip(ship)).refusals).toContain('the ship has no airlock: every ship has a door facing space (GDD 5D)');
  });
});

describe('warnings', () => {
  it('warns about a conduit tile that reaches neither power nor a system (GDD 5H)', () => {
    const ship = `<ship name="Spur" race="Terran"><hull points="1"/><power kind="AZC" level="1"/>
      <rooms><room id="0" from="-1,-1" to="1,1"/></rooms>
      <systems><system name="AZC" tile="0,0"/></systems>
      <doors><door id="0" tile="1,0" facing="East"/></doors>
      <conduits>(0,0) (1,0,W) (-1,1,N)</conduits></ship>`;
    const result = checkShip(reader.readShip(ship));
    expect(result.refusals).toEqual([]);
    expect(result.warnings).toEqual(['conduit tile -1,1 reaches neither a power source nor a system']);
  });
});
