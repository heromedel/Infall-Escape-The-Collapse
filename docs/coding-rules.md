# Infall: Coding Rules

**All of these are Proposed rules, not hard rules, unless a different document or heromedel says otherwise.**

Rules for the coding session, from heromedel (2026-10-26). They sit on top of `game-project-standards.md` (the
elegant code principles and the standard rules) and `CLAUDE.md` (the hard rule for code).

1. **Feel.** Match FTL's feel and speed as closely as possible without plagiarizing: no FTL code, data, assets or
   names anywhere in the code.
2. **Readable.** Efficient, elegant, human-readable code; class, variable and function names match what they do.
   The standards' elegant code principles apply.
3. **Electron with TypeScript:** a desktop program with full file access, local files, no browser permissions.
   Game logic runs in the main process; the window only draws.
4. **Open engine.** Art is visible in its folders, data is in XML or text documents, and both are easily moddable.
5. **ECS.** An entity is a folder with a file naming the entity, its tags and components, and its art by name or
   path. The game systems load the file, see the components and know what to do. A weapon is an entity with
   component tags and no code: changing it from laser to missile behaviour is changing a tag. No code per entity.
   A ship is the worked example (GDD 5F to 5L): `Ships/shipname.xml` holds the floor layout, systems, doors,
   hull data, starting weapons and crew; `loadout.shipname.loadoutname.xml` derives a loadout from it (5J); the art
   sits beside them in the same folder.
6. **Approval.** Code is presented as blocks with a plain explanation of what each does, for heromedel's approval,
   before it goes in. Class and function names come first, so nobody ends up halfway down the pipeline wondering
   what a class does or why it has a journal.
7. **Vanilla as a setting.** FTL vanilla behaviour is a setting, not a different branch of the game: classic power
   versus a race's own power model is a simple toggle built on shared code. Settings are written with the default
   first (GDD 1K).
8. **Main shows the flow.** Reading through the main class clearly shows the flow of the game: clean logic calling
   what it needs, functions and classes, and returning. Never a spaghetti of classes calling classes.
   - Bad: main calls a power change function, which draws the GUI; the GUI changes the power level.
   - Good: main calls draw GUI; main calls change power; main calls refresh GUI.
   - A system changes state and returns; drawing is always its own call from main. *(the last line: Ai-Generated-Proposal, 2026-10-26)*
9. **Art is SVG or PNG** (GDD 10A, 5K), loaded live from the entity's folder. The engine renders either, the same
   way or differently as needed: an SVG's named parts are handles for recolouring, hiding and animating; a PNG is
   drawn as needed, or the system to handle each will be decided by the coder and heromedel. The game can handle
   missing art: with none, the ship is built from its XML as walls, floor tiles, icons and door rectangles (5K), and
   a weapon shows a square with its name (8J).
10. **Logs.** Every log entry is two lines: a machine line with every field, and a human-readable line written from
    it. Extra logs, debug logs and admin commands are welcome (standards); the command list is kept in its own doc,
    not here.
11. **Saves** are local, hand-readable XML or text files, and a save holds the run's seed.
12. **Tests.** Run the tests the change needs. Don't run every test every time.
13. **Ticks.** The simulation runs on fixed ticks (GDD 3E), 20 a second (0.05 s); every time in the reference
    tables is converted to ticks.

Branch and merge rules for the coding session are heromedel's to set.
