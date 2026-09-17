# Games — Balloon Pop (session)

- Date: 2026-09-17
- Scope: [../../scope/games/balloon-pop-scope.md](../../scope/games/balloon-pop-scope.md)
- Status: done
- Sibling: [../shared/kid-shell-and-first-game-session.md](../shared/kid-shell-and-first-game-session.md)

## Goal

Build the first mini-game (step 4) and attach a Rive character driven by data binding (step 5).

## What changed

`lib/games/balloon_pop/` — `balloon_pop_game.dart`, `balloon_pop_screen.dart`,
`components/balloon.dart`, `components/progress_stars.dart`, `assets.dart`, and a
[README](../../../lib/games/balloon_pop/README.md) carrying the Rive spec.

Balloons spawn from below every 1.4–2.4s, rise at 34–60 px/s with a sine drift, and pop on tap-down
with a squash-and-vanish. Ten pops fires confetti, pauses spawning 1.8s, and resets the dots.

## Decisions & alternatives

**Pop on tap-down, not tap-up.** A five-year-old's finger slides between the two, and an ignored
tap reads as the game being broken. Commented in the code so it doesn't get "corrected".

**The touch target is bigger than the art.** `Balloon.size` is `radius * 2.6` while the drawn
balloon is about `radius * 1.85` wide. The classic frustration at this age is a target that looks
hittable but isn't quite — so aiming at a balloon and landing just outside still pops it.

**Pops are latched** (`_isPopping`), so mashing one balloon counts once. There's a test.

**Escaping balloons are silent non-events.** Not `driftAway()` with a sad sound, not a counter —
removed, nothing else. A "miss" would be a failure state by another name.

**Progress as ten dots, never a number.** Only rises, resets after each celebration, no time limit.
`ProgressStars.filled` clamps both ends, tested — so no code path can make it look like something
was lost.

**No "well done" dialog.** Confetti overlays and play resumes. A child cannot read a dialog, and
dismissing one breaks the rhythm.

**Rive: `rewards.riv` bound to a coin counter.** The stand-in from the official example is a mock
rewards *screen*, not a character, and exposes nested numbers rather than triggers. Binding
excitement to `Coin/Item_Value` proves the data-binding path works end to end without pretending
it is the intended reaction. Rendered small and cornered, out of the play area.

The spec for a real file — triggers `Celebrate` and `Encourage`, number `Excitement` (0–1) — is in
the game's README, along with the rule that the character must never look sad or disappointed, even
on `Encourage`.

## Tests

Five game tests, all passing (full run in the sibling session doc):

```
00:00 +0: Balloon floats upward
00:00 +1: Balloon reports a pop exactly once, even when mashed
00:00 +2: Balloon has a touch target larger than the drawn balloon
00:00 +3: ProgressStars never goes below zero or above the total
00:00 +4: Celebration burst adds confetti, and it clears itself up
```

The confetti test drives 400 frames and asserts the piece count returns to zero — repeated
celebrations must not accumulate components.

**Driven in a browser** with headless Chrome: balloons rise, pop, and respawn; dots fill and reset
(so celebrations fired); no Dart errors across several hundred taps. The Rive file **loaded and
rendered**, which is the real proof the 0.14 API path is right.

**Not verified:** iOS/macOS (no Apple toolchain here), and everything about *feel*. Spawn rate and
rise speed are guesses that look reasonable in a screenshot; only a child on a tablet can say
whether they are right.

## Kid-rules check

- [x] Playable with no reading
- [x] Touch targets ≥ 80×80 (balloon hit area ~120, home button 96)
- [x] No failure state — no timer, no miss, no game over, progress only rises
- [x] Home button top-right, 96×96, no confirm
- [x] No network calls

## Debugging

None survived. Two rendering issues were caught from screenshots and fixed inline: the unfilled
progress dots were invisible against the sky, and the Rive placeholder was too large and sat in the
play area.

## Scope updates

[The scope](../../scope/games/balloon-pop-scope.md) is **shipped**. Tap-down, overlay celebration,
and colour-not-yet-meaningful are resolved. Still open and needing a real child: whether silence on
a completely missed tap feels broken, and the spawn/speed tuning.

## Follow-ups

- Soft pop and celebration sounds (currently the template's arcade sfx).
- Real balloon art — paths go in `assets.dart`.
- A real character `.riv` to the spec in the game README.
