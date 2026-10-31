/**
 * CLAUDE.md's hard rule for code: the game this project is inspired by is never named in the code or the
 * content. This test fails if its name appears anywhere under src/ or content/, so it can't slip in by habit.
 * The name is spelled from its letters here so this file passes its own check.
 */

import { describe, expect, it } from 'vitest';
import * as fs from 'node:fs';
import * as path from 'node:path';

const forbiddenName = new RegExp(`\\b${['f', 't', 'l'].join('')}\\b`, 'i');
const root = path.join(__dirname, '..');

function filesUnder(folder: string): string[] {
  if (!fs.existsSync(folder)) return [];
  return fs.readdirSync(folder, { withFileTypes: true }).flatMap((entry) => {
    const full = path.join(folder, entry.name);
    return entry.isDirectory() ? filesUnder(full) : [full];
  });
}

describe('the hard rule for code', () => {
  it('names the inspiring game nowhere under src/ or content/', () => {
    const offenders = [...filesUnder(path.join(root, 'src')), ...filesUnder(path.join(root, 'content'))]
      .filter((file) => forbiddenName.test(fs.readFileSync(file, 'utf8')))
      .map((file) => path.relative(root, file));
    expect(offenders).toEqual([]);
  });
});
