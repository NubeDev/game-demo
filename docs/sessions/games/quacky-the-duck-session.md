# Games — Quacky the Duck (session)

- Date: 2026-09-20
- Scope: [../../scope/games/quacky-the-duck-scope.md](../../scope/games/quacky-the-duck-scope.md)
- Status: done — playable, placeholder art, **driven in a browser**

## Goal

Build the eighth mini-game from the ask "a grumpy duck who chases other ducks
and children to get bread, so the gamer needs to duck, and chase for bread".
Scope first, then the game.

## What changed

New: [`lib/games/quacky_the_duck/`](../../../lib/games/quacky_the_duck/) —
`park.dart` (data), `world.dart` (spawner + chase maths), the game, the screen,
six components, `assets.dart`, and a
[README](../../../lib/games/quacky_the_duck/README.md).

Wired in: a route in [`lib/router.dart`](../../../lib/router.dart), an eighth
menu tile in [`lib/menu/home_screen.dart`](../../../lib/menu/home_screen.dart),
and an eighth colour in
[`lib/shared/kid_palette.dart`](../../../lib/shared/kid_palette.dart) — the
palette had exactly seven, and no two tiles may share one.

Tests: 71 new across four files (unit, screen, layout, render).

Also reconciled the stale status column in
[`docs/scope/README.md`](../../scope/README.md) and the Cat Run scope's own
header, which said *proposed* for a game that has been playable for a while.

## Decisions & alternatives

**The chase closes on a timer, not on skill.** This is the whole design. A
chase is pressure-shaped and the scope's central promise is that the bread never
gets away, so the gap closes at `QuackyWorld.drift` every frame the park moves,
and dash only subtracts from it. Rejected: making the target's speed a function
of how hard the child presses, which is the obvious implementation and is a
difficulty curve wearing a friendly hat.

**Left is duck, right is go — the same as Cat Run.** Rejected giving this game
its own arrangement. A child who has played Cat Run already knows which thumb is
which, and consistency across the app is doing the job an instruction would.

**The mood is a second progress signal, drawn on the character.** The bread-roll
row is the app's standard, but a row in the corner is not where a child is
looking. `Mood.brightness` is a 0..1 that only climbs within a round — and it is
exactly the shape a bound Rive number would take later.

**Plain countdowns, not `TimerComponent`s**, for the respawn and the
post-celebration hold. See *Debugging*.

## Tests

`flutter analyze` — clean. `flutter test` — **544 passing** (71 new).

```
00:20 +544: All tests passed!
```

```
Analyzing game-demo...
No issues found! (ran in 1.2s)
```

The tests worth knowing about, because they encode the rules rather than the
code:

- `a child who NEVER presses dash still gets every treat`
- `the gap only ever shrinks, never grows`
- `a beak-bonk does not cost any ground`
- `the chase closes before the idle sits him down`
- `at the catch, Quacky is never drawn inside anybody`
- `every duck hazard clears a flat duck and blocks a standing one`
- `a tapped duck outlasts the widest thing it has to pass`
- `two duck hazards never arrive back to back`
- `nothing crowds up the longer the child plays`
- `the mood only ever climbs as treats are eaten`

### On a real target

**Run in Chrome and played, over the DevTools Protocol** — menu → the eighth
tile → dashing, ducking, catching, a celebration, and the home button back to
the menu. 1280×720 landscape, real pointer events with `pointerType: touch`.
**No console errors**; the only warning is headless Chrome having no WebGL.

**Not verified:** iOS, Android (no device or emulator reachable from this
machine), macOS, haptics (no vibrator), and **no sound has been heard** — this
game adds no new cues, reusing `pop`, `wobble` and `celebrate`, but the chomp is
currently the pop ladder and nobody has listened to whether that reads as *a
duck eating*.

**Never played by a child**, which is the thing that actually matters.

## Kid-rules check

- [x] Playable with no reading — no text anywhere; the two buttons are a
      leaning duck and a flat duck, both verified by eye as PNGs
- [x] Touch targets ≥ 80×80 — both buttons are 140 drawn, with the whole bottom
      quarter of the screen as the hit area; pinned at five screen sizes
- [x] No failure state, no punishing timer — nothing to lose, nothing to miss;
      the bread cannot get away and a bonk costs nothing at all
- [x] Home button present, in its usual corner, proven clear of both play
      quarters at every screen size
- [x] No network calls, no SDKs, no stored personal data

One thing the checklist does not cover and this game needed: **nobody in the
park is frightened of Quacky.** The children run backwards facing him, laughing,
and hand the bread over on purpose. `ChaseTarget._renderFace` has no unhappy
branch to reach, and the render test exists mostly to check that by eye.

## Debugging

No `debugging/` entry: nothing here was a regression in shipped code. Everything
below was found and fixed inside this session, each with the test that now
catches it.

**Found by tests:**

1. **The chase stopped after exactly one catch.** The respawn was scheduled on a
   `TimerComponent` guarded by `_target == target`, but `_target` was already
   null when it fired. Behind that was a bigger problem: `add()` is async, so a
   component timer depends on Flame's load lifecycle. Both timers are now plain
   countdowns in `update`.
2. **A passive child never ate anything.** `catchUpSeconds` was 9 against an
   `idleTimeout` of 6, so Quacky sat down before the gap ever closed — the
   scope's central promise was false in exactly the case it was written for. Now
   4.5, and the coupling is pinned by a test.
3. **A clean duck registered seconds late.** A successful duck produces no
   collision at all, so the clean-clear branch inside `_checkCollisions` was
   unreachable and the chime only fired when the bench left the screen. Now
   `_checkPassed`, which fires as it clears his beak.
4. **Concurrent modification** when the first hazard scrolled off screen — the
   same crash Crystal Party hit. `query<Hazard>().toList()`.
5. **A tapped duck ended halfway under the washing line.** `duckDuration` was
   shorter than the widest hazard takes to pass. Now derived from it, with a
   test that fails if a wider hazard is added.

**Found by looking at the render PNGs:**

6. The eyebrow — the entire mood signal — merged into the head outline when
   furious and floated off the skull when delighted. Rebuilt to rotate about
   the eye, with a bigger head to carry it.
7. A ducking duck was a ball hanging below its own flattened body. A ducking
   bird stretches its neck *forward*, level.
8. The dash was a six-degree lean nobody could see. Now a real lean, a spread
   wing and motion streaks.
9. The flat-duck button was two dark stripes and said nothing. It is one of only
   two instructions in the game.

**Found only by running it in a browser** — the lesson the Car Trip session
wrote down, and it held again. None of these is visible in a still or a test:

10. **At the catch, Quacky was drawn inside the child.** The gap is measured
    centre-to-centre and `caughtWithin` was 56 against 126px-wide art — a 53px
    overlap, which the scope explicitly rules out. Now 150, pinned by a test
    against every target's width.
11. Tree canopies were sized so they swallowed their own trunks; the park was a
    row of green blobs floating in the sky.
12. The target duck and pigeon floated above the ground line.
13. The dog lead hung at head height from nothing. Everything overhead now has
    a visible post.
14. The deckchair was a bare purple parallelogram leaning on nothing.

## Scope updates

The scope's *Done when* is met except for the last clause — no child has played
it. Two open questions are now answered in code and want confirming with a real
one:

- **How close counts as caught?** Answered: near, not touching
  (`caughtWithin`), and forced to clear both bodies.
- **Is the dash a burst or a hold?** Built as a burst (`Quacky.dashDuration`
  0.6s); holding just chains them.

The rest stay open, including the big one — whether his face resetting to
grumpy after a celebration reads as a fresh joke or as lost ground.

## Follow-ups

- **Play it on a device with a child.** `STATUS.md` already says this is the
  highest-value work left, and this game does not change that — it adds to the
  queue.
- No new sounds were added; the chomp is the pop ladder. A real gobble, a
  grumpy quack and a triumphant QUACK are the obvious next thing, and the scope
  leans on them.
- `Mood.brightness` is ready for a Rive Quacky whenever art arrives.
