# Sprite process: one detail at a time

**Date:** 2026-10-27
How the art session works on a sprite, so improvements never wipe out what already works. Written after the 2x
drifter test, where a softening pass over the whole picture erased the belt, the collar and the shirt buttons.
Tags follow `docs/tag-styles.md`.

## Rules from heromedel

- **Hard Rule (2026-10-27):** never apply an effect to the whole image. No global blur, softening, smoothing, outline
  or shading pass over everything.
- **Decided (2026-10-27):** look at the image and work one detail at a time. Each detail is its own goal: shading the
  torso without losing the collar is one goal; blending the coat's outline, the hair's outline and the face's outline
  are separate goals; the boots' shape is one; the jaw line and head shape is one; the eyes are one.
- **Decided (2026-10-27):** each goal is a multi-step, multi-path process: try more than one way, look, correct, and
  look again before moving on.
- **Decided (2026-10-27):** check the work with test tools, including a blind checker that tries to identify each
  part. If it calls an eye an apricot, something is wrong.
- **Decided (2026-10-27):** other sessions' test checks (e.g. the 3D-to-Diablo-2-style render's) are for a different
  process. Learn from them, but don't treat them as this process.

## The process for each detail (Ai-Generated-Proposal, 2026-10-27)

1. **Name the goal and its part.** One part, one aim, e.g. "the belt reads as a belt, a step darker than the coat,
   with its buckle". Write down what must not change.
2. **Mark the part.** Every pixel in the sprite belongs to a named part (a part map: coat-near, belt, buckle, lapel,
   collar, buttons, face, eye-left, …). A change may only touch its own part's pixels, plus the edge where it meets
   a neighbour if the goal is the edge.
3. **Protect the details.** Before the change, list the detail pixels (buttons, buckle, emblem, eyes, belt, collar).
   After it, check they are all still there and still stand out from their surroundings. If one is gone or blended
   away, undo and try again.
4. **Try 2–3 ways.** Make the change more than one way, show them side by side at working size and true size, and
   keep the best. Look at the result before deciding, every time.
5. **Correct and re-look.** Fix what's off, look again. Repeat until the part reads right, then move to the next goal.
6. **Run the checks** (below) on the changed part and on the whole sprite.
7. **Record it.** One line in the piece's README per finished goal: what changed, and what was protected.

## Checks (Ai-Generated-Proposal, 2026-10-27)

- **Blind checker:** a separate agent with no context gets a crop of one part (at true size and enlarged) and is
  asked "what is this?". The answer must name the part (an eye, a belt buckle, a boot). A wrong answer means the part
  doesn't read yet. The checker never sees my notes or the goal, so it can't just agree with me.
- **Detail survival:** every protected detail pixel still exists after a change, and keeps enough contrast against its
  neighbours to be seen at true size.
- **Part-only diff:** a diff of before and after must show changes only inside the goal's part (and its edge, if the
  goal was the edge).
- **Stray pixels:** nothing hangs off the silhouette (touching it on one side or none).
- **Symmetry where it belongs:** matched parts (a pair of boots, the eyes) are the same shape, with the light still
  coming from the upper left on both.
- **Contrast:** shading steps inside a part stay subtle (no embossed-panel look); outlines and key details (belt,
  collar, eyes) stay strong enough to read.
- **True size:** every change is also judged at the size the game shows it, not only enlarged.
- **Reference:** the angle and proportions are checked against heromedel's render or rig, side by side.

## Lessons so far

- A whole-image pass (round 5 at 2x) blurred the belt, collar and buttons. Work per part.
- Turning the figures 3/4 (round 1) distorted the heads and feet; heromedel's angle is facing forward from about 45°
  above (the 1/2 view).
- Square, flat-shadowed faces (round 3) read worse than the earlier ones.
- Tracing over heromedel's render and rig gave the right angle and proportions; drawing from my own guesses did not.
