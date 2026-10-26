/**
 * The game's log (coding rule 10). Every entry is two lines: a machine line with every field, and a human line
 * written from those fields. Entries go to the console and to a file under logs/, one file per program run.
 */

import * as fs from 'node:fs';
import * as path from 'node:path';

export type LogFields = Record<string, string | number | boolean | undefined>;

/** How the human line is written for each event name. An event with no template gets a plain listing. */
const HUMAN_LINES: Record<string, (fields: LogFields) => string> = {
  'program.started': (f) => `Infall started; logging to ${f.logFile}.`,
  'content.folder_missing': (f) => `There is no content folder at ${f.folder}; nothing was loaded.`,
  'content.ship_loaded': (f) => `Loaded ship "${f.ship}" (${f.race}): ${f.rooms} rooms, ${f.systems} systems, ${f.doors} doors, ${f.conduits} conduit tiles, hull art ${f.hullArt}.`,
  'content.ship_refused': (f) => `Refused ship "${f.ship}" from ${f.file}: ${f.reason}`,
  'content.ship_warning': (f) => `Ship "${f.ship}": ${f.warning}`,
  'content.art_missing': (f) => `Ship "${f.ship}" names ${f.kind} art ${f.art}, which is not in its folder; it will draw without it (GDD 5K).`,
  'content.system_loaded': (f) => `Loaded system "${f.system}"${f.symbol ? ' with its symbol' : ' without a symbol'}.`,
  'content.system_refused': (f) => `Refused system file ${f.file}: ${f.reason}`,
  'content.symbol_missing': (f) => `System "${f.system}" has no symbol file; it draws as a lettered square.`,
  'content.loaded': (f) => `Content loaded: ${f.ships} ships, ${f.systems} systems.`,
  'debug.command': (f) => `Debug command: ${f.line}`,
  'debug.unknown_command': (f) => `No such debug command: ${f.command}. Type help.`,
};

export class Log {
  private constructor(private readonly logFile: string) {}

  /** Opens the log for this program run: logs/<timestamp>.log plus the console. */
  static open(logsFolder: string): Log {
    fs.mkdirSync(logsFolder, { recursive: true });
    const stamp = new Date().toISOString().replace(/[:.]/g, '-');
    const log = new Log(path.join(logsFolder, `${stamp}.log`));
    log.event('program.started', { logFile: log.logFile });
    return log;
  }

  /** Writes one entry: the machine line, then the human line. */
  event(name: string, fields: LogFields = {}): void {
    const machineLine = `${new Date().toISOString()} ${name} ${formatFields(fields)}`.trimEnd();
    const humanLine = `  ${(HUMAN_LINES[name] ?? plainListing)(fields)}`;
    const text = `${machineLine}\n${humanLine}\n`;
    process.stdout.write(text);
    fs.appendFileSync(this.logFile, text);
  }
}

function formatFields(fields: LogFields): string {
  return Object.entries(fields)
    .filter(([, value]) => value !== undefined)
    .map(([key, value]) => `${key}=${JSON.stringify(value)}`)
    .join(' ');
}

function plainListing(fields: LogFields): string {
  const parts = Object.entries(fields).filter(([, value]) => value !== undefined).map(([key, value]) => `${key} ${value}`);
  return parts.length > 0 ? parts.join(', ') + '.' : 'Nothing to report.';
}
