# Infall: Escape The Collapse

A squad roguelike of ships, rooms and crew. The design lives in `docs/` (`docs/gdd.html` is the game design
document); this is the game itself, started 2026-10-26 on the Goal P prototype (`docs/production-goals.md`).

## Running it

On Windows, double-click `start.bat`: it installs Node.js if it is missing, installs the packages on the first
run, then builds and opens the game. By hand, on any system:

    npm install
    npm start        builds and opens the game
    npm test         runs the tests the code has
    npm run check    type-checks without building

Logs go to `logs/`, one file per program run, two lines per entry (`docs/coding-rules.md`, rule 10).

## Where things are

| Folder | What |
|---|---|
| `src/main.ts` | The flow of the whole program, top to bottom |
| `src/simulation/` | The game: ships, crew, systems, ticks. Imports nothing from Electron or the window |
| `src/host/` | Electron's main process: files, logs, the debug console, later saves and LAN |
| `src/window/` | The viewer: draws what the host sends, sends back what the player did |
| `content/ships/<ship>/` | One folder per ship: `ship.xml`, `loadout.<name>.xml` and its art (GDD 5F to 5L, 11A) |
| `content/weapons/`, `content/races/` | The same pattern for weapons and races (GDD 11B) |
| `tests/` | Vitest tests; `npm test` |
| `docs/` | The design documents, art workshop and reference tables |

The rules the code follows are in `docs/coding-rules.md` and `docs/game-project-standards.md`.
