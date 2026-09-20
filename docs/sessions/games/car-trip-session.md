# Games — Car Trip, the first game the child steers (session)

- Date: 2026-09-20
- Scope: ../../scope/games/car-trip-scope.md
- Status: done (playable, placeholder art)

## Goal

Build Car Trip from its scope: a car that drives itself down a road, steered by a thumb, picking up
animal passengers until the road arrives somewhere. The first continuous control in the app —
everything else is a press.

## What changed

New game under `lib/games/car_trip/`, plus a route, a menu tile and one new shared sound.

| File | What it is |
|---|---|
| `road.dart` | The data list of things on the road, the four destinations, and the projection maths. Pure Dart. |
| `world.dart` | The spawner. Pure, so the fairness rules are testable without a game. |
| `car_trip_game.dart` | The Flame game: steering, interactions, arriving. |
| `car_trip_screen.dart` | Steering area, horn, home button, and the hand hint. |
| `components/road_view.dart` | Sky, fields, tarmac, verges, the dashes that sell the speed. |
| `components/traffic.dart` | Everything on the road, drawn back to front. |
| `components/car.dart` | The car and its steering physics. |
| `components/progress_dots.dart` | How full the car is. |
| `components/horn_button.dart` | The horn. |
| `assets.dart`, `README.md` | Where real art lands; why it is built this way. |

Outside the game folder:

- `lib/router.dart`, `lib/menu/home_screen.dart` — the route and the tile.
- `tools/make_sfx.py`, `assets/sfx/kid_horn{1,2}.mp3`, `lib/audio/sounds.dart`,
  `lib/shared/kid_sounds.dart` — a new **horn** cue. Two variants, alternated, because it is the one
  sound a child presses for its own sake; a single sample would grate within a minute. Mixed below
  the pop so leaning on the horn never drowns out the cue that says "that worked".

## Decisions & alternatives

**The road runs away to a horizon, not side-on.** Cat Run is already side-on; the same camera would
have made them read as one game with different art. The projection is the textbook
`focal / (focal + depth)`, and one number drives position, size and the width of the road, so
nothing can drift out of agreement.

**Every rule is in road units, not pixels.** `lateral` (0 = centre line, ±1 = tarmac edge) and
`depth` (world pixels ahead). "This cone is narrow" then means the same on a phone and a tablet,
and the whole game logic is testable with no screen at all. Only the drawing knows about pixels.

**Drag-to-steer, not two buttons.** Rejected the Cat Run-style corner buttons: the pre-writing
motion is the point of the game, and a held thumb is the biggest possible target. The buttons
remain the fallback if a real child cannot hold a line.

**Nothing alive can be hit — structurally, not statistically.** There is no branch in the game that
lets a living thing be collided with; the ducks move aside faster than the car can steer and wander
into the field if chased. Rejected "make it rare": a five-year-old does not separate a funny game
collision from the real thing.

**A passenger walks to the kerb.** Found while writing the tests, not while writing the scope: a
passenger standing on the verge is further out than the car's reach, so a child driving down the
middle would have completed *no* trips. Rather than widen the reach (which makes steering
pointless) or move passengers into the road (which makes them a target), the animal now comes to
meet the car. The ask is a lean of the thumb, and a test pins how small it is.

**Lifting the thumb stops the car where it is**, not "pulls over to the kerb" as the scope said.
Drifting the car sideways while nobody is touching it contradicts the scope's own finish line.
Scope updated rather than diverged from.

**A hand hint until the first touch.** This is the only game in the app whose control cannot be
seen — there is no button to point at. The player cannot read an instruction, so the instruction is
a picture of the thing to do, and it goes away the moment they do it.

## Tests

`flutter analyze` clean for this game's files, and the whole suite green (358 tests,
`--exclude-tags render`):

```
00:37 +358: All tests passed!
```

New: `test/car_trip_test.dart` (20), `test/car_trip_layout_test.dart` (25),
`test/car_trip_screen_shot_test.dart` (3, render-tagged).

> `flutter analyze` over the whole repo currently reports 5 errors in `lib/games/crystal_party/`,
> which is another session's untracked, in-progress game. Nothing in it is mine and nothing in
> Car Trip depends on it. `flutter analyze lib/games/car_trip test/car_trip*` is clean.

The ones that are load-bearing against the kid rules:

- **nothing on the tarmac can block the way through** — the widest nudge thing plus the car against
  the drivable width.
- **a duck crossing the road always gets clear, even when chased** — drives straight at it for six
  seconds and asserts it is never hit and never even approached closely.
- **needs only a small lean of the thumb** — how much steering the game actually demands. If that
  number grows, the game has started asking for aim a five-year-old does not have.
- **never puts two things closer than the floor** and **never gets denser the longer the child
  plays** — no difficulty ramp, over 300 placements.
- **clipping a cone costs nothing at all** — nothing removed, nothing stopped, nothing ended.
- **lifting the thumb stops the world** / **the car never moves sideways on its own**.
- **the horn does nothing to the trip, and makes the fields wave**.
- 25 layout assertions across six screen sizes (including 2.22:1, the shape that found
  the arch bug): both buttons on screen and ≥80×80, the horn and
  the home button in opposite corners, the steering band covering the bottom half and never
  overlapping the home button, and a real pointer gesture in the bottom-right corner actually
  steering the car.

**Three bugs the tests caught while building, all of them real** (two more came later, from
actually driving it — see *Played on a device*):

1. The spawner re-rolled each stream's gap every frame and asked "is it due yet", so the first roll
   small enough to fit always won and every gap collapsed to the floor. Now decided once, when the
   previous thing is placed.
2. The nudge reaches were set by eye and came out slightly **mean** — a cone registered a hit
   before it visually overlapped the car. Retuned so a hit needs about 85% of a visual overlap, and
   the test now compares hit distance against the two drawn half-widths rather than the art alone.
3. Passengers were unreachable from the middle of the road (see *Decisions*).

**Looked at, as stills:** `flutter test --tags render --dart-define=SHOT_DIR=…` renders the screen
at tablet, iPhone SE and Pixel sizes, empty and after driving. Two things were fixed by eye and
could not have been by assertion: the drivable verge was a green almost identical to the field
behind it (now dust/sand/packed snow, so the child can see how far out they may drive), and the
rainbow arch filled a landscape phone's whole screen as the car went under it (lower and narrower).

## Played on a device — and it found two bugs the tests could not

Run on an Android emulator (`sdk gphone64 x86 64`, API 36, 2400×1080 landscape — 2.22:1),
software-rendered, driven with real touch events (`adb shell input swipe` / `tap`). This is the
step that mattered: **both bugs below were invisible to 319 passing tests and to the still
renders**, and both are the kind a child would have hit.

**1. Passengers were never picked up on a slow device.**
The emulator drew at a median **550ms per frame** (`dumpsys gfxinfo`: 100% janky). The pickup test
was a window ±55 world units around the car — about half a second at `speed = 210`. At 550ms per
frame the car moves ~115 units between frames, *more than the whole window*, so passengers tunnelled
straight through it and the dots stayed empty no matter how well the car was steered.

This is not an emulator curiosity. It is a **frame-rate-dependent hit test**, and a five-year-old's
device is a hand-me-down. A frame spike silently eating the passenger they correctly aimed at reads
as "the game ignored me" — the exact failure CLAUDE.md §3 rules out. `_interact` now widens its
window by however far the car moved that frame, so **the child's aim decides what happens, never the
frame rate**. Pinned by *still works on a tablet that cannot hold 60fps*, which drives at 2fps.

**2. A rainbow arch could cover the entire screen.**
`Perspective.scaleAt` clamped at `-focal * 0.55`, which is also the cap on how big anything is ever
drawn: **2.2×**. A 2.0-unit arch at 2.2× draws ~2670px across on a 2400px screen — the sky, the
horizon and the road all vanished behind a wall of pink as the car went under it. A passing sheep
did the same thing. That is a startle (CLAUDE.md §3: "bright, friendly, calm ... nothing scary") and
it briefly hides the road the child is steering on.

Clamped to `-focal * 0.15`, capping growth at about 1.2×. The arch and the car wash are *meant* to
span the road — being driven under is the point of them — so the fix is the growth cap, not their
width; the test says exactly that.

Worth recording: my earlier attempt at this, tuned against a 1.5:1 test surface, was **not enough**
at 2.22:1. The layout tests now include a 2.22:1 size.

**What the device run confirmed working**, under a real finger:

- Steering follows the thumb anywhere in the bottom half; the hand hint vanishes on first touch.
- Driving through a rainbow arch repaints the car (pink → blue).
- Passengers walk to the kerb, hop in, and appear as heads in the window; the dots fill.
- The horn fires and changes nothing about the trip — car, dots and passengers all untouched.
- The home button returns to the menu.
- The menu renders all seven games in one row with no overflow, no text, no scrolling.

## Kid-rules check

- [x] Playable with no reading — no text anywhere; the controls are the screen itself, the horn is
      a picture, progress is dots.
- [x] Touch targets ≥ 80×80 — horn 140, home button 96, steering area is half the screen. Pinned at
      five sizes.
- [x] No failure state, no punishing timer — no crash, no damage, no fuel, no score, no timer;
      nothing alive can be hit; a passenger driven past comes back.
- [x] Home button present and obvious — usual top-right corner, far from the steering hand.
- [x] No network calls — `make privacy` clean.

## What was NOT verified

- **Never played by a child.** It has now been played by me, on a device, with real touch — but
  every remaining open question in the scope is one only a five-year-old can close.
- **Sound never heard.** The horn was *pressed* on the emulator and the app did reach the audio
  layer (the emulator's virtual sound card logged a PCM write failure, which is the emulator having
  no audio device, not the app failing). **Nobody has heard the horn, or any other cue, out loud.**
  Whether two horn variants are enough to stop it grating is still unanswered.
- **Haptics never felt** — no vibrator in reach.
- **iOS unverified** — no macOS machine available.
- **Only ever run at ~2fps.** The emulator was software-rendered, which is what exposed the pickup
  bug, but it means **nothing here has been seen at a normal frame rate**. Everything about *feel* —
  whether the steering is twitchy or sluggish, whether 210 units/sec is too fast, whether the
  arrival cross-fade reads — is still unproven. A run on real hardware is the obvious next step.
- **Never played long enough to arrive anywhere.** Six passengers at 2fps was more driving than the
  session had; the arrival celebration and the destination change have only ever been seen in
  tests and in the still renders.

## Debugging

No `debugging/` entry: nothing broke in the shipped app. Two test-harness traps were worth writing
down here instead, because the next session will hit them:

- A root `FlameGame`'s `updateTree` deliberately skips its own `update`, so a hand-rolled test
  harness runs the components and never the game. Use `flame_test`'s `testWithGame`, and drive with
  `game.update(dt)`.
- `RenderRepaintBoundary.toImage()` must be awaited inside `tester.runAsync`, or the screenshot
  test hangs outright — sometimes on the first shot, sometimes the second. The existing Blast Off
  and Dress the Dog shot tests do not do this and are presumably living on luck.

## Scope updates

Six open questions closed in the scope doc (steering method, camera, whether passengers need
steering to, trip length, the car wash, the Rive character). Five left open, each marked with what
was built and what a real child still has to settle. Two *What* bullets corrected where the build
deliberately went a different way.

## Follow-ups

- **Play it with a child.** Every remaining open question is one only a five-year-old can close.
- The progress row is now the app's **third** copy of the same component (Balloon Pop's stars, Cat
  Run's fish, these dots). Three is the point at which it should move to `lib/shared/`.
- The road does not literally bend into the destination; arriving is a cross-fade plus confetti.
- Consider fixing the two older screenshot tests' `toImage()` calls before one of them hangs CI.
