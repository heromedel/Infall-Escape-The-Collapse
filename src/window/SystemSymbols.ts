/**
 * A system's symbol in the window: the symbol.svg from its content folder (content/systems), drawn in the ship's
 * power colour through currentColor. A system with no symbol file gets a lettered square, so a modder's new
 * system still shows (GDD 5K's spirit, as 8J does for weapons).
 */

const SVG = 'http://www.w3.org/2000/svg';

/** The symbol's size in ship pixels; the files are drawn in a 20 by 20 box. */
export const SYMBOL_BOX = 20;

export function systemSymbolElement(name: string, symbolSvg: string | undefined): SVGElement {
  if (symbolSvg) {
    const parsed = new DOMParser().parseFromString(symbolSvg, 'image/svg+xml').documentElement;
    if (parsed.tagName === 'svg') {
      parsed.setAttribute('width', String(SYMBOL_BOX));
      parsed.setAttribute('height', String(SYMBOL_BOX));
      return document.importNode(parsed, true) as unknown as SVGElement;
    }
  }
  return letteredSquare(name);
}

function letteredSquare(name: string): SVGElement {
  const letter = name.trim().charAt(0).toUpperCase() || '?';
  const group = document.createElementNS(SVG, 'g');
  group.innerHTML = `<rect x="2" y="2" width="16" height="16" rx="2" fill="none" stroke="currentColor" stroke-width="2"/>`
    + `<text x="10" y="14.5" font-size="12" font-family="sans-serif" text-anchor="middle" fill="currentColor">${letter}</text>`;
  return group;
}
