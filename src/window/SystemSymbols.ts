/**
 * The standard symbol for each system, as small SVG shapes drawn in a 20 by 20 box, so a system reads at a glance
 * on any race's console (ideas: ship interior art). A name with no symbol gets a lettered square, so a modder's
 * new system still shows (GDD 5K's spirit, as 8J does for weapons).
 */

const BOX = 20;

/** The symbol's SVG inner markup, drawn with the current colour (fill and stroke use currentColor). */
const SYMBOLS: Record<string, string> = {
  Piloting: '<path d="M10 2 L18 17 L10 13 L2 17 Z" fill="currentColor"/>',
  Shields: '<path d="M10 2 L17 5 V10 C17 14 14 17 10 18 C6 17 3 14 3 10 V5 Z" fill="none" stroke="currentColor" stroke-width="2"/>',
  Weapons: '<path d="M3 15 L12 6 M12 6 L17 3 L14 8 M9 9 L11 11" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"/><circle cx="5" cy="15" r="2" fill="currentColor"/>',
  'Weapon Pod': '<path d="M3 15 L12 6 M12 6 L17 3 L14 8 M9 9 L11 11" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"/><circle cx="5" cy="15" r="2" fill="currentColor"/>',
  Engines: '<path d="M4 6 H13 L17 10 L13 14 H4 Z" fill="none" stroke="currentColor" stroke-width="2"/><path d="M1 8 H4 M1 12 H4" stroke="currentColor" stroke-width="2"/>',
  'Life Support': '<circle cx="10" cy="10" r="6.5" fill="none" stroke="currentColor" stroke-width="2"/><path d="M10 3.5 V16.5 M3.5 10 H16.5" stroke="currentColor" stroke-width="1.5"/>',
  Doors: '<rect x="4" y="3" width="12" height="14" rx="1" fill="none" stroke="currentColor" stroke-width="2"/><path d="M10 3 V17" stroke="currentColor" stroke-width="2"/>',
  Sensors: '<circle cx="10" cy="10" r="2" fill="currentColor"/><path d="M5 5 A7 7 0 0 1 15 5 M3 13 A9 9 0 0 1 3 7" fill="none" stroke="currentColor" stroke-width="1.8"/>',
  Medbay: '<path d="M8 3 H12 V8 H17 V12 H12 V17 H8 V12 H3 V8 H8 Z" fill="currentColor"/>',
  AZC: '<circle cx="10" cy="10" r="7" fill="none" stroke="currentColor" stroke-width="2"/><path d="M11 4 L7 11 H10 L9 16 L13 9 H10 Z" fill="currentColor"/>',
  'Crew Teleporter': '<circle cx="10" cy="10" r="3" fill="currentColor"/><circle cx="10" cy="10" r="7" fill="none" stroke="currentColor" stroke-width="1.5" stroke-dasharray="3 2"/>',
  'Supershield Generator': '<path d="M10 2 L17 5 V10 C17 14 14 17 10 18 C6 17 3 14 3 10 V5 Z" fill="none" stroke="currentColor" stroke-width="2"/><path d="M10 6 L13 10 L10 14 L7 10 Z" fill="currentColor"/>',
  'Cybernetic Servicing Core': '<path d="M8 3 H12 V8 H17 V12 H12 V17 H8 V12 H3 V8 H8 Z" fill="none" stroke="currentColor" stroke-width="1.8"/><circle cx="10" cy="10" r="2" fill="currentColor"/>',
  'EVB Dock': '<rect x="3" y="4" width="14" height="12" rx="2" fill="none" stroke="currentColor" stroke-width="2"/><path d="M10 4 V16 M3 10 H10" stroke="currentColor" stroke-width="1.5"/>',
};

export function systemSymbol(name: string): string {
  return SYMBOLS[name] ?? letteredSquare(name);
}

function letteredSquare(name: string): string {
  const letter = name.trim().charAt(0).toUpperCase() || '?';
  return `<rect x="2" y="2" width="16" height="16" rx="2" fill="none" stroke="currentColor" stroke-width="2"/>`
    + `<text x="10" y="14.5" font-size="12" font-family="sans-serif" text-anchor="middle" fill="currentColor">${letter}</text>`;
}

export const SYMBOL_BOX = BOX;
