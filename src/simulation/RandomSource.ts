/**
 * The simulation's dice, seeded so a run replays from its seed (coding rule 11). Every roll in the simulation
 * comes from here, never from Math.random, or the host and a replay would disagree.
 */

export class RandomSource {
  private state: number;

  constructor(readonly seed: number) {
    this.state = seed >>> 0;
  }

  /** A number from 0 up to but not including 1. Mulberry32: small, fast, good enough for a game's dice. */
  next(): number {
    this.state = (this.state + 0x6d2b79f5) >>> 0;
    let t = this.state;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  }

  /** True with the given chance, 0 to 1. */
  chance(probability: number): boolean {
    return this.next() < probability;
  }

  /** A whole number from 0 up to but not including the count. */
  index(count: number): number {
    return Math.floor(this.next() * count);
  }
}
