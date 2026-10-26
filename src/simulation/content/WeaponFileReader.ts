/**
 * Turns weapon XML text into a WeaponDefinition. Takes text, not files, like the ship reader.
 */

import { XMLParser } from 'fast-xml-parser';
import { WeaponDefinition, WeaponType } from './WeaponDefinition';

export class WeaponFileError extends Error {}

const WEAPON_TYPES: readonly WeaponType[] = ['Laser', 'Missile', 'Beam', 'Bomb', 'Flak'];

const parser = new XMLParser({ ignoreAttributes: false, attributeNamePrefix: '', parseAttributeValue: false, parseTagValue: false, trimValues: true });

export class WeaponFileReader {
  readWeapon(xmlText: string): WeaponDefinition {
    let parsed: Record<string, any>;
    try {
      parsed = parser.parse(xmlText);
    } catch (error) {
      throw new WeaponFileError(`not valid XML: ${(error as Error).message}`);
    }
    const root = parsed.weapon;
    if (!root || typeof root !== 'object') throw new WeaponFileError("the file's top element is not <weapon>");
    const name = this.required(root, 'name', 'weapon');
    const where = `weapon "${name}"`;
    const type = this.required(root, 'type', where);
    if (!WEAPON_TYPES.includes(type as WeaponType)) throw new WeaponFileError(`${where}: type="${type}" is not ${WEAPON_TYPES.join(', ')}`);
    return {
      name,
      nickname: this.optional(root.nickname),
      type: type as WeaponType,
      effects: String(root.effects ?? 'Damage').split(',').map((effect) => effect.trim()).filter((effect) => effect.length > 0),
      techType: this.required(root, 'techType', where),
      race: this.required(root, 'race', where),
      shots: this.number(root.shots ?? '1', `${where} shots`),
      damage: this.number(root.damage ?? '1', `${where} damage`),
      power: this.number(root.power ?? '1', `${where} power`),
      chargeSeconds: this.number(this.required(root, 'chargeSeconds', where), `${where} chargeSeconds`),
      mawjigPerShot: this.number(this.required(root, 'mawjigPerShot', where), `${where} mawjigPerShot`),
      breachChance: this.chance(root.breachChance, `${where} breachChance`),
      fireChance: this.chance(root.fireChance, `${where} fireChance`),
      conduitDamageChance: this.chance(root.conduitDamageChance, `${where} conduitDamageChance`),
      description: this.optional(root.description),
    };
  }

  private required(node: Record<string, any>, attribute: string, where: string): string {
    const value = node[attribute];
    if (value === undefined || value === '') throw new WeaponFileError(`${where} is missing ${attribute}="..."`);
    return String(value);
  }

  private optional(value: unknown): string | undefined {
    return value === undefined || value === '' ? undefined : String(value);
  }

  private number(value: unknown, where: string): number {
    const number = Number(value);
    if (Number.isNaN(number) || number < 0) throw new WeaponFileError(`${where}: "${value}" is not a number`);
    return number;
  }

  /** "20%" or "0.2" to a chance from 0 to 1; absent is 0. */
  private chance(value: unknown, where: string): number {
    if (value === undefined || value === '') return 0;
    const text = String(value).trim();
    const number = text.endsWith('%') ? Number(text.slice(0, -1)) / 100 : Number(text);
    if (Number.isNaN(number) || number < 0 || number > 1) throw new WeaponFileError(`${where}: "${value}" is not a chance like 20% or 0.2`);
    return number;
  }
}
