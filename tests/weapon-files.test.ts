/** Every weapon folder reads as a card, and a bad chance is refused with a reason. */

import { describe, expect, it } from 'vitest';
import * as fs from 'node:fs';
import * as path from 'node:path';
import { WeaponFileReader } from '../src/simulation/content/WeaponFileReader';

const weaponsFolder = path.join(__dirname, '..', 'content', 'weapons');
const reader = new WeaponFileReader();

describe('weapon files', () => {
  for (const folder of fs.readdirSync(weaponsFolder).sort()) {
    it(`${folder}/weapon.xml reads`, () => {
      const weapon = reader.readWeapon(fs.readFileSync(path.join(weaponsFolder, folder, 'weapon.xml'), 'utf8'));
      expect(weapon.chargeSeconds).toBeGreaterThan(0);
      expect(weapon.mawjigPerShot).toBeGreaterThan(0);
      // projectile art, when named, is an SVG beside the card
      if (weapon.projectileArt) expect(fs.existsSync(path.join(weaponsFolder, folder, weapon.projectileArt))).toBe(true);
    });
  }
  it('reads the Gat 3.1 card', () => {
    const weapon = reader.readWeapon(fs.readFileSync(path.join(weaponsFolder, 'gat-3-1', 'weapon.xml'), 'utf8'));
    expect(weapon).toMatchObject({ name: 'Gat 3.1', nickname: 'Triblast', type: 'Laser', shots: 3, damage: 1, power: 2, chargeSeconds: 13.1, conduitDamageChance: 0.1, projectileArt: 'bolt.svg' });
  });
  it('refuses a chance that is not a chance', () => {
    expect(() => reader.readWeapon('<weapon name="X" type="Laser" techType="M" race="R" chargeSeconds="5" mawjigPerShot="0.02" breachChance="five"/>'))
      .toThrow('breachChance');
  });
});
