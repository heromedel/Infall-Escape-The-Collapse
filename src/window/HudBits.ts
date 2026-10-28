/**
 * Small SVG helpers shared by the battle GUI: rectangles, text and the races' placeholder crew shapes (GDD 12D).
 */

const SVG = 'http://www.w3.org/2000/svg';

export function rect(x: number, y: number, width: number, height: number, fill: string, extra: { stroke?: string; rx?: string; opacity?: string } = {}): SVGRectElement {
  const element = document.createElementNS(SVG, 'rect');
  element.setAttribute('x', String(x)); element.setAttribute('y', String(y));
  element.setAttribute('width', String(width)); element.setAttribute('height', String(height));
  element.setAttribute('fill', fill);
  if (extra.stroke) element.setAttribute('stroke', extra.stroke);
  if (extra.rx) element.setAttribute('rx', extra.rx);
  if (extra.opacity) element.setAttribute('opacity', extra.opacity);
  return element;
}

export function text(x: number, y: number, content: string, style: { size: number; anchor?: string; fill?: string; weight?: string }): SVGTextElement {
  const element = document.createElementNS(SVG, 'text');
  element.setAttribute('x', String(x)); element.setAttribute('y', String(y));
  element.setAttribute('font-size', String(style.size));
  element.setAttribute('font-family', 'system-ui, sans-serif');
  element.setAttribute('fill', style.fill ?? '#ffffff');
  if (style.anchor) element.setAttribute('text-anchor', style.anchor);
  if (style.weight) element.setAttribute('font-weight', style.weight);
  element.textContent = content;
  return element;
}

export function group(attributes: Record<string, string> = {}): SVGGElement {
  const element = document.createElementNS(SVG, 'g');
  for (const [name, value] of Object.entries(attributes)) element.setAttribute(name, value);
  return element;
}

/** The race's placeholder shape (GDD 12D) as markup around the origin, 16 pixels across, for the crew boxes. */
export function placeholderShape(shape: string, colour: string): string {
  const r = 8;
  const common = `fill="${colour}" stroke="#0b1018" stroke-width="1.5"`;
  switch (shape) {
    case 'Square': return `<rect x="${-r}" y="${-r}" width="${2 * r}" height="${2 * r}" ${common}/>`;
    case 'Circle': return `<circle r="${r}" ${common}/>`;
    case 'Triangle': return `<polygon points="0,${-r} ${r},${r} ${-r},${r}" ${common}/>`;
    case 'Diamond': return `<polygon points="0,${-r} ${r},0 0,${r} ${-r},0" ${common}/>`;
    case 'Cross': return `<path d="M-3 ${-r} h6 v5 h5 v6 h-5 v5 h-6 v-5 h-5 v-6 h5 z" ${common}/>`;
    case 'Star': {
      const points = [];
      for (let i = 0; i < 10; i++) {
        const radius = i % 2 === 0 ? r : r * 0.45;
        const angle = -Math.PI / 2 + (i * Math.PI) / 5;
        points.push(`${(radius * Math.cos(angle)).toFixed(2)},${(radius * Math.sin(angle)).toFixed(2)}`);
      }
      return `<polygon points="${points.join(' ')}" ${common}/>`;
    }
    case 'Crescent': return `<path d="M2 ${-r} A${r} ${r} 0 1 0 2 ${r} A${r * 0.7} ${r * 0.7} 0 1 1 2 ${-r} Z" ${common}/>`;
    default: return `<text y="6" font-size="18" font-weight="bold" text-anchor="middle" fill="${colour}">?</text>`;
  }
}
