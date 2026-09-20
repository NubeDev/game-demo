# Games — Blast Off, the rocket that shows how long (session)

- Date: 2026-09-20
- Scope: [../../scope/games/blast-off-scope.md](../../scope/games/blast-off-scope.md)
- Status: done
- Siblings: —

## Goal

The maintainer's ask, in full: *"when i adjust the time, make the rocket bigger/smaller."*

A longer countdown draws a bigger rocket, and the rocket changes size **while the child is
pressing more and less** — so the button they are pressing visibly does something to the biggest
thing on the screen.

It is a kid-rules win as much as a bit of charm. The chosen length already had two readouts that
need no reading (the row of dots, and the star jar once it is counting) plus one that does (the
grey clock, which is the adult's). The rocket is a third, in the one place a child is already
looking — and unlike the dots it is not something they have to notice is a row of dots
(CLAUDE.md §3).

## What changed

### The model says *where on the ladder*, not *how big*

`CountdownLength.sizeStep` — 0 at five seconds, 1 at ten minutes. Deliberately a position and not
a size: how much room there is to be big in depends on the screen, and only the scene knows that.

### The scene says *how much room*

`LaunchPad.maxSceneScale` is new and `sceneScale` is now `min(1, maxSceneScale)` — the same number
it always was, expressed in terms of the new one. `maxSceneScale` is the biggest the sky above the
pad can hold; `sceneScale` is that capped at 1, because nothing in the scene used to be allowed to
grow past its natural size. The rocket now is.

### The rocket sizes itself

`BlastOffGame._layoutScene` no longer sets `_rocket.scale` — it calls `rocket.fitTo(skyScale:)`
and the rocket does the rest, reading the countdown each frame like it already reads the phase for
its rattle and smoke. So a length change needs no wiring at all: the child presses *more*, the
model notifies, and the next frame is drawn bigger.

The size is the ladder **spread across the room the screen actually has**:

```dart
final big = min(maxScale, _skyScale);          // 1.4, or what the sky holds
final small = max(minScale, big * 0.6);        // never below 80px wide
return small + (big - small) * countdown.length.sizeStep;
```

It springs rather than snaps (stiffness 180, damping 22 — just under critical, so it arrives with
a small bounce). A size that changes smoothly reads as *this button made the rocket grow*; a snap
just looks like the picture was swapped.

### The rejected first attempt

The first version was the obvious one: a `sizeFactor` of 0.8–1.4 multiplying `sceneScale`, clamped
to the sky. It is wrong on a phone, and the rendered ladder showed it immediately — on a Pixel in
landscape the sky is 218px and the rocket is 220px tall at full size, so everything from 30 seconds
upward hit the ceiling and drew **identically**. Half the ladder, the half with the toothbrush
timer in it, said nothing at all. Spreading between a floor and the ceiling instead gives every
rung its own size on every screen that has any room.

## What it looks like

Settled widths (the rocket is 120px wide at scale 1), measured from the components, not the target:

| Screen | 5s | 30s | 2min | 10min |
|---|---|---|---|---|
| Tablet 1280×800 | 101 | 126 | 143 | 168 |
| Pixel 892×412 | 80 | 92 | 100 | 112 |
| iPhone SE 667×375 | 80 | 85 | 88 | 92 |

**On the SE the cue is weak** — a 15% spread across the whole ladder, which is honestly not much.
There is nowhere for it to go: the sky above the pad is 181px there, and the small end may not go
under 80px wide because the rocket honks when poked and is therefore a touch target. The dots
remain the readout that works on every screen; this is an extra, and it degrades quietly rather
than breaking the layout.

## Tests

- **`test/blast_off_rocket_size_test.dart`** (10 tests, in the normal suite): on four screen
  sizes — pressing *more* never shrinks the rocket, every length stays ≥80px wide and on screen,
  a tablet shows at least a 1.4× difference between the shortest and the longest, and the model
  ladder climbs.
- **`test/blast_off_render_test.dart`** (3 shots, tagged `render`): the whole ladder in one still,
  standing on the real ground line, at tablet, Pixel and SE size. Built with `testWithFlameGame`
  and a `PictureRecorder`, not a `GameWidget` — the same trap `cat_run_render_test.dart`
  documents, and one worth repeating: a second `testWidgets` case hosting a `GameWidget` hangs
  forever under `flutter_test`, which is exactly how two attempts at these screenshots were lost.

  Run it with a directory to write into — there is no `make` target for shots yet:

  ```
  flutter test test/blast_off_render_test.dart --tags render --dart-define=SHOT_DIR=/tmp/shots
  ```

## Verified

- `make check` — `flutter analyze` clean, **248 tests passing**, privacy grep clean.
- The ladder looked at as PNGs at 1280×800, 892×412 and 667×375. On tablet and Pixel the
  difference is obvious at a glance; on the SE it is faint, as the numbers above say.

**Not verified: any device, emulator or browser run.** Nothing here was felt under a thumb, so the
one thing still unproven is the *feel* of the change: whether the spring bounce is a delight or a
distraction when a child presses *more* five times quickly, and whether a rocket growing under
their finger reads as "longer wait" or just as "the rocket got bigger". That is a `make run-device`
job (CLAUDE.md §6) and a question only a child settles.

## Kid-rules check

- **No reading needed** — this *removes* reading, it does not add any.
- **Touch targets** — the rocket is tappable, and the 80px floor is now enforced in the rocket
  itself (`Rocket.minScale`) and pinned by a test at every length on every screen size.
- **No way to lose** — nothing about size touches the clock.
- **Home button** — untouched.
- **No network, no SDK, no stored data** — nothing added; privacy grep clean.
