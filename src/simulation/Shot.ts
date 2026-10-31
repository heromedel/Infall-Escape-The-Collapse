/**
 * One projectile in flight and what happens when it arrives (GDD 1C: fire, then check for a miss against
 * evasion, then a block by shields). Lasers are stopped by a shield layer and take it down; missiles pass
 * shields. A hit does its damage to the hull, to the system in the room, and to the crew standing there.
 */

import { WeaponDefinition } from './content/WeaponDefinition';
import { Ship } from './Ship';
import { Tile } from './content/Tile';
import { RandomSource } from './RandomSource';
import { evasionPercent } from './steps/EnginesStep';
import { BattleLog } from './BattleLog';
import { secondsToTicks } from './Ticks';

/** Health a crew member loses per point of damage landing in their room (the genre's rate). */
const CREW_DAMAGE_PER_POINT = 15;
const STUN_TICKS = secondsToTicks(5);

export class Shot {
  readonly flightTicks: number;

  constructor(
    readonly id: number,
    readonly weapon: WeaponDefinition,
    readonly fromShipId: number,
    readonly toShipId: number,
    readonly toTile: Tile,
    public ticksLeft: number,
  ) {
    this.flightTicks = ticksLeft;
  }

  get progress(): number {
    return 1 - this.ticksLeft / this.flightTicks;
  }

  /** True once it has arrived and been resolved. */
  fly(target: Ship | undefined, random: RandomSource, log: BattleLog): boolean {
    this.ticksLeft--;
    if (this.ticksLeft > 0) return false;
    if (!target || target.isGone) return true;
    this.land(target, random, log);
    return true;
  }

  private land(target: Ship, random: RandomSource, log: BattleLog): void {
    const fields = { weapon: this.weapon.name, target: target.name, tile: `${this.toTile.x},${this.toTile.y}` };
    if (random.chance(evasionPercent(target) / 100)) {
      log.event('shot_missed', fields);
      return;
    }
    const passesShields = this.weapon.type === 'Missile' || this.weapon.type === 'Bomb';
    if (!passesShields && target.shieldLayers > 0) {
      target.shieldLayers--;
      log.event('shot_blocked', { ...fields, layersLeft: target.shieldLayers });
      return;
    }
    // the shot lands on its tile: the room's air and crew feel it, but only the system on that tile is hit (GDD 3L)
    const room = target.roomOfTile(this.toTile);
    const onTile = target.systemOnTile(this.toTile);
    const systems = onTile ? [onTile] : [];
    let damage = this.weapon.damage;
    if (this.weapon.effects.includes('Hull bonus') && systems.length === 0) damage *= 2;

    target.hullPoints = Math.max(0, target.hullPoints - damage);
    for (const system of systems) system.damage = Math.min(system.level, system.damage + this.weapon.damage);
    if (this.weapon.effects.includes('Spores')) for (const system of systems) system.spored = true;
    if (room) {
      for (const member of target.livingCrewInRoom(room)) {
        member.health -= CREW_DAMAGE_PER_POINT * this.weapon.damage;
        if (this.weapon.effects.includes('Stun')) member.stunnedTicks = STUN_TICKS;
        if (!member.isAlive) log.event('crew_died', { ship: target.name, crew: member.name, cause: this.weapon.name });
      }
    }
    log.event('shot_hit', { ...fields, damage, hullLeft: target.hullPoints, systemsHit: systems.map((system) => system.key).join('+') || 'none' });
    if (target.isDestroyed) log.event('ship_destroyed', { ship: target.name, by: this.weapon.name });
  }
}
