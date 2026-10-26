/**
 * The admin and debug commands (standards: more logs and admin commands let heromedel see real play).
 * Systems register their own commands here as they are built; this class only keeps the list and runs a line.
 * The command list for players and testers is documented in its own doc, not here (coding rule 10).
 */

import { Log } from './Log';

export interface DebugCommand {
  name: string;
  description: string;
  run: (arguments_: string[]) => string;
}

export class DebugConsole {
  private readonly commands = new Map<string, DebugCommand>();

  constructor(private readonly log: Log) {
    this.register({ name: 'help', description: 'List the debug commands.', run: () => this.helpText() });
  }

  register(command: DebugCommand): void {
    this.commands.set(command.name, command);
  }

  /** Runs one typed line, e.g. "ships" or "give 10", and returns what to show the person who typed it. */
  run(line: string): string {
    this.log.event('debug.command', { line });
    const [name, ...arguments_] = line.trim().split(/\s+/);
    const command = this.commands.get(name);
    if (!command) {
      this.log.event('debug.unknown_command', { command: name });
      return `No such command: ${name}. Type help.`;
    }
    return command.run(arguments_);
  }

  private helpText(): string {
    return [...this.commands.values()].map((command) => `${command.name}: ${command.description}`).join('\n');
  }
}
