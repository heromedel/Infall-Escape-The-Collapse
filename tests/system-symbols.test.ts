/** Every system folder names its system and carries a symbol drawn in the 20 by 20 box with currentColor. */

import { describe, expect, it } from 'vitest';
import * as fs from 'node:fs';
import * as path from 'node:path';

const systemsFolder = path.join(__dirname, '..', 'content', 'systems');

describe('system symbols', () => {
  for (const folder of fs.readdirSync(systemsFolder).sort()) {
    it(`${folder} has a named system.xml and a recolourable symbol.svg`, () => {
      const xml = fs.readFileSync(path.join(systemsFolder, folder, 'system.xml'), 'utf8');
      expect(xml).toMatch(/<system\s[^>]*name="[^"]+"/);
      const svg = fs.readFileSync(path.join(systemsFolder, folder, 'symbol.svg'), 'utf8');
      expect(svg).toContain('viewBox="0 0 20 20"');
      expect(svg).toContain('currentColor');
      expect(svg).not.toMatch(/#[0-9a-f]{6}/i);
    });
  }
});
