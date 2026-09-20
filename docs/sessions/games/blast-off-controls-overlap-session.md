# Games — Blast Off: the controls were in the way (session)

- Date: 2026-09-20
- Scope: ../../scope/games/blast-off-scope.md
- Status: done

## Goal

Reported from a dev window: on Blast Off the control buttons are drawn over the
rocket and the star jar. Get the scene out from under the buttons.

## What changed

The scene and the controls were laid out by two layers that could not see each
other — the Flame game drew the rocket, the Flutter screen laid out the buttons,
and **both anchored to the bottom of the canvas** with hard-coded offsets. The
fix is one number passed between them, plus one layout rule.

- **`BlastOffScreen.controlsReserve(width)`** — the screen states how much of
  the bottom its buttons own. Public so the layout test checks the scene
  against the same number the buttons use, rather than a copy that can drift.
- **`LaunchPad.groundHeight`** — the grass grows to fill that band, so the
  buttons rest ON the ground and the rocket stands clear above it. It stops
  growing once the remaining sky would no longer hold the smallest legal
  rocket; `sceneScale` then shrinks the scene, floored so the rocket (a touch
  target — it honks) never drops below 80px wide.
- **`BlastOffGame._layoutScene()`** — everything is now placed relative to the
  pad, and re-placed on resize, instead of against the screen's bottom edge.
  `Rocket._home` had to stop being `late final` for this.
- **The controls are always one row** — when the row will not fit, the ±
  steppers drop out rather than the layout gaining a second line.
- **`LaunchPad.jarRight`** — the star jar slides left when a full-height jar
  would reach the home button's corner.

## Decisions & alternatives

- **Raise the grass, not shrink the scene** (the maintainer chose this when
  asked). The rocket is the thing a child looks at and pokes, so shrinking it
  to make room was the worse trade; buttons resting on grass also reads
  naturally rather than as a UI bar pasted over a game.
- **One reserve for every phase, not per-phase.** The phases want different
  heights (waiting 132, counting 110, launched 150), so a per-phase reserve
  would be tighter. Rejected: the ground and the rocket would visibly jump each
  time the phase changed, and a screen that rearranges under a child's hands is
  the thing CLAUDE.md §3 is most insistent about.
- **Dropping the ± steppers on a narrow screen, rather than wrapping to a
  second row.** This is the load-bearing decision. The old layout wrapped the
  presets onto a second line, making the band 268px — on a landscape iPhone SE
  (375px) that leaves 107px of sky for a rocket needing at least 171px, so the
  overlap was unfixable there by moving the scene at all. The maintainer said
  iPhones must be supported, so the second row had to go. The presets still
  reach every length on the ladder, so nothing becomes unreachable and the
  child's route (pick a picture, press GO) is untouched; what is lost is the
  adult's fine-tuning pair, on small phones only.
  - Considered and rejected: a vertical preset column on the left edge. It
    keeps the steppers, but it is a second layout that only exists on small
    screens — more to maintain, and it crowds the countdown number.
- **The jar moves rather than shrinks.** The first version of the corner fix
  capped the jar's height to duck under the home button, which left it a
  thumbnail on a phone. The jar is the countdown made visible for a child who
  cannot read a digit (CLAUDE.md §3) — it is load-bearing, so it keeps the
  scene's scale and slides sideways instead. A landscape-only game has width to
  spare; it is only ever height that is short.

## Tests

`flutter analyze` clean, and the full suite green — **217 tests, up from 199**
(and 81 before this run of work).

```
$ flutter analyze lib/ test/
No issues found! (ran in 2.7s)

$ flutter test --exclude-tags render
00:26 +217: All tests passed!
```

New: [`test/blast_off_layout_test.dart`](../../../test/blast_off_layout_test.dart)
pins the contract directly — at every target size the rocket's feet are above
the control band, the rocket is fully on screen, it never scales below the 80px
floor, and the star jar's rect does not overlap the home button's. It also pins
that the reserve does not vary with width, which is what would silently return
if a second row crept back.

Added to [`test/blast_off_screen_test.dart`](../../../test/blast_off_screen_test.dart):
the presets and GO never drop, the steppers are what goes on a narrow screen,
and no control is *painted* under 80px once the FittedBox has scaled the row.

New: [`test/blast_off_screen_shot_test.dart`](../../../test/blast_off_screen_shot_test.dart)
(tagged `render`) renders the screen at tablet, iPhone SE and the reported dev
window so the layout can be looked at.

A note on the screenshots: they take about five minutes for three sizes here.
Killing them early still yields the PNG, which is why they briefly looked like
they were hanging.

**Looking at it mattered.** The assertions all passed while the star jar was
sitting under the home button — raising the ground had lifted it into the
corner, and nothing in the test suite was watching that. The screenshot caught
it; the test for it was written afterwards. Same again for the overcorrection:
the jar cleared the corner by shrinking to a thumbnail, which also passed
everything until it was rendered.

**Not verified:** no device or simulator run. iOS is unverified as ever (no
macOS machine here). The layout is proven by test and by rendered screenshots
at three sizes; whether the shorter rocket still *feels* like the centre of the
screen, and whether an adult misses the ± buttons on a phone, needs hands. The
Material icons render as boxes in the screenshots — a headless-font artifact,
not a layout problem.

## Kid-rules check

- [x] Playable with no reading — unchanged; the presets are pictures and the
  jar still shows the length as a quantity.
- [x] Touch targets ≥ 80×80 — now pinned on *painted* size at five screen
  sizes, which is stricter than before. The scene's own floor exists for the
  same reason: the rocket is tappable.
- [x] No failure state, no punishing timer — untouched.
- [x] Home button present and obvious — **this got better**: the jar used to
  sit right under it and now provably cannot.
- [x] No network calls, no new dependency.

## Debugging

[`debugging/games/blast-off-controls-cover-the-rocket.md`](../../debugging/games/blast-off-controls-cover-the-rocket.md)
— root cause and fix, with the regression tests named.

## Scope updates

None needed; the scope doc did not specify a layout, and nothing in it turned
out to be wrong.

## Follow-ups

- **Play it on a device.** This is the third layout bug in this app found by
  rendering rather than by asserting, and the second in a row that only showed
  on a short landscape phone.
- The `render`-tagged screenshot tests are **slow, not broken** — about five
  minutes for three sizes on this machine. During the session they were run
  under `timeout` and killed after writing their PNG, which looked like a hang;
  a later unattended run exited 0 with all three files written. Nothing to fix
  beyond knowing to let them finish.
- `STATUS.md` updated: yes.
