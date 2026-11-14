# Genre captures (raw)

Raw captures of the genre's game taken by the Infall: Init Coding session under Wine on 2026-10-27, kept so
other sessions can study real play. Reference only; never in code folders (CLAUDE.md hard rule). The curated
frames with notes are in `../genre-battle-screen/`.

| File | What it is |
|---|---|
| `genre-recording-20fps.mp4` | 30 s of a Kestrel vs Rebel Elite Fighter fight at 1280x720, 20 frames a second. Split with `ffmpeg -i genre-recording-20fps.mp4 -vf fps=20 f%04d.png`. |
| `genre-gui-states.zip` | 40 screenshots walking the battle GUI's states: weapon armed, aiming, Ctrl held, targets set, right-click, autofire on and off, tooltips, crew selected. |
| `genre-fights-and-walk.zip` | 224 screenshots: beacon hops, map, dialogs, stores, and two more fights at a few frames a second (folders `ftl-walk`, `fight`, `fight2`). |

Saved as JPEG at quality 85 from the original PNGs to keep the repo small.

**Not in the repo any more (heromedel, 2026-11-14):** the three files were taken out of the current files to keep
every session's download small; they are to live on Google Drive instead. Until then they can still be fetched from
git history, from commit `3cc2a13` (branch `Cloud-C-Init-Coding`), e.g.
`git show 3cc2a13:docs/reference/genre-captures/genre-gui-states.zip > genre-gui-states.zip`.
