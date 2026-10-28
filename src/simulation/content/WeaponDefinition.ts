/**
 * A weapon's card (GDD 8E): the parts it is built from and the numbers the cost tables gave it. Pure data, read
 * from content/weapons/<folder>/weapon.xml (GDD 8F, 11B). A weapon is data and tags, never code: changing it from
 * laser to missile behaviour is changing its type (coding rule 5).
 */

export type WeaponType = 'Laser' | 'Missile' | 'Beam' | 'Bomb' | 'Flak';

export interface WeaponDefinition {
  name: string;
  /** The fun nickname, e.g. "Triblast" for the Gat 3.1 (race profiles, Terrans 6). */
  nickname?: string;
  type: WeaponType;
  /** Effects by name, e.g. Damage, Breach, Spores, Stun, Hull bonus. The tick steps know what each does. */
  effects: string[];
  techType: string;
  race: string;
  shots: number;
  damage: number;
  /** Bars the weapon needs from its weapon system. */
  power: number;
  /** Full charge time in seconds on a matching tech system (weapon-budget-table). */
  chargeSeconds: number;
  /** Mawjig per shot (mawjig-cost-table); a volley costs shots × this (GDD 8C). */
  mawjigPerShot: number;
  /** Chances per hit, 0 to 1. */
  breachChance: number;
  fireChance: number;
  conduitDamageChance: number;
  description?: string;
  /** The projectile's picture, an SVG file beside weapon.xml, drawn nose up with its top centre on the flight path. */
  projectileArt?: string;
}
