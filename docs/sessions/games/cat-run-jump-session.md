# Games — Cat Run, the jump that was never drawn (session)

- Date: 2026-09-20
- Scope: [../../scope/games/cat-run-scope.md](../../scope/games/cat-run-scope.md)
- Status: done
- Siblings: [cat-run-session.md](cat-run-session.md)

## Goal

The maintainer's report, after playing it: *"the hunch/duck down is kind ok but kind sucks, the jump
is really bad, it only seems to lift its legs up, not jump."*

That description turned out to be literally accurate, and it named the bug precisely. Only the jump
was in scope this session; the duck was left alone.

## The bug

`Cat` tracked its height above the ground in `_height` (exposed as `airHeight`), advanced it along a
sine arc, and used it in exactly one place: `hitBox`, for collision.

**Nothing ever applied it to the canvas.** `render()` drew the cat at its `position`, which the game
pins to the ground line and never moves. So during a jump:

- the *hitbox* rose 250px and sailed over the fence;
- the *cat* stayed on the ground, stretched about 3px by squash-and-stretch, with its legs tucked up
  (`legDrop` shrinks in the jumping state).

Legs lifting, cat not moving. Exactly what was reported.

Every jump test passed throughout, because all of them assert on `airHeight` — the model was right,
and the model was the only thing under test. This is the interesting part of the session: a test
suite of eleven tests covering coyote time, input buffering, bounce height and obstacle clearance,
all green, on a game whose central mechanic was invisible.

## What changed

### The fix

One line in `Cat.render`, before the rotate and scale so the squash cannot scale the travel:

```dart
canvas.translate(0, -_height);
```

`position` stays pinned to the ground line — the game sets it there and `hitBox` measures up from
it — so the air is applied at draw time.

### The rise no longer walks off the top of the screen

`jumpRise = 250` was tuned "by looking" in an earlier session, raised from 138 because that "read as
a shuffle". Both judgements were made while the cat was not moving vertically at all, so neither
was worth much — and 250 does not fit a phone.

On a landscape phone (~390 logical tall) the ground line sits at `0.7 × 390 = 273`. A 92-tall cat
rising 250 puts its ears 69px *above* the top of the screen, and a mushroom bounce (1.45×) puts them
at 362. Losing the cat off the top is disorienting at five: it reads as the character being gone.

So the arc is now fitted to the screen. `Cat.fitTo(headroom:)` sets an instance `rise` from the sky
actually available, sized so that the *highest* thing the cat does — a bounce, not a jump — keeps
its ears on screen, with a `minJumpRise = 150` floor. The floor wins over the headroom on purpose:
a jump that cannot clear a fence is a broken game, whereas a cat that grazes the top of the screen
is merely a big jump. `CatRunGame` calls it in `onLoad` and `onGameResize`, and the block and the
fish are now placed against `cat.rise` rather than the `Cat.jumpRise` constant, so they stay
reachable on a short screen.

Result: 250 on a tablet (unchanged), 150 on a phone — 1.6× the cat's own height and clearing the
tallest obstacle's 86px hitbox by 64px.

### Squash and stretch, the right way round

The airborne stretch was `sin(p * pi)` — peaking at the apex, the one moment in the arc where the
cat is not moving at all. The cat was longest while it hung and shortest while it shot upwards,
which is squash and stretch exactly backwards.

Stretch now follows *speed*: the height curve is `sin(p * pi)`, so vertical speed is its derivative,
`cos(p * pi)` — fastest at the launch and the touchdown, still at the top. The cat stretches out of
the launch, rounds off at the apex, and stretches again into the landing.

A landing squash was added too (`landSquashDuration = 0.16s`): a jump that simply stops looks like
the cat was switched off at the ground. It is cosmetic only and never gates input, so a child
pressing again the instant they land still jumps.

## Tests

Two new tests in `test/cat_run_test.dart`, both in the `the jump` group:

- **`is actually DRAWN off the ground, not just measured`** — renders the cat to a real image at
  ground level and at the apex and compares the topmost painted pixel row. Pixels rather than a
  transform spy on purpose: the question is "did the player see the cat move", and only the image
  answers it. Verified to have teeth — with the `canvas.translate` removed it fails with the drawn
  cat rising 3px against an `airHeight` of 225.
- **`never leaves the top of a short screen`** — a bounce at phone headroom must keep the cat's ears
  on screen *and* clear the tallest obstacle by 30px.

`test/cat_run_render_test.dart` gained a **jump-arc filmstrip**: the whole arc drawn ghosted at
phone and tablet size against the real ground line and the tallest obstacle. The existing shots are
one posture each on a blank field, which is how a broken jump shipped in the first place — a
single-frame portrait of a squashed cat looks identical whether or not it is ten feet in the air.
The posture shots also had to start adding `airHeight` back when framing, or the jumping cat now
renders off the top of their 200×160 canvas.

## Verified

- `flutter analyze` clean.
- `flutter test` — 229 passing.
- The arc looked at as PNGs at 780×390 and 1024×768: the cat visibly leaves the ground, clears the
  fence with room, and stays on screen at both sizes.

**Not verified: any device or emulator run.** The arc was judged from rendered stills, not in
motion, so the *timing* — whether 0.86s reads as floaty under a thumb, and whether the new landing
squash lands — is still unproven. That is a `make run-device` job (CLAUDE.md §6).

## Left alone

The **duck** ("kind ok but kind sucks"). Not touched this session — the jump was the ask. Worth a
look next: the duck is a flat 0.55 squash with no anticipation and no landing, and now that the
jump has speed-driven squash the duck will look cruder by comparison.
