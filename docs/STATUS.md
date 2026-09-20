# Status

Where we are, right now. Updated at the end of every session.

- **Last updated:** 2026-09-20
- **Now:** the app is playable, has its own sound, and there are now four built games plus a
  parent-gated settings screen. Picture menu → **Balloon Pop** (pop or swipe balloons, colour bunches
  ripple, big balloons shower) → **Dress the Dog** (dress a dog against the weather) → **Cat Run**
  (a cat that runs, jumps, ducks, bounces and bonks, and never loses) → **Blast Off** (a countdown
  the child sets going and cheers at zero; the rocket is bigger the longer the wait). All
  placeholder art (drawn in code) and placeholder (but kid-appropriate) audio, and **no voice yet**
  for the countdown, which is the feature Blast Off is really waiting on.
- **Cat Run is the first game with timing in it**, which is the nearest this app has come to a
  failure state. It is resolved by keeping the obstacle and deleting the loss: every miss is
  slapstick (tumble, pancake, belly-flop) and the run never stops. See its
  [session](sessions/games/cat-run-session.md) for the fairness numbers and what they are derived
  from.
- **Next:** play it on a real tablet with a real child. Everything left is either art, sound, or
  tuning that only a child can settle.

## The plan

| # | Step | Status |
|---|---|---|
| 1 | Project from template, renamed, integrations checked, builds | **done** |
| 2 | `CLAUDE.md` — the binding rules for every future session | **done** |
| 3 | Kid-friendly home screen with picture buttons + gated settings | **done** |
| 4 | Balloon Pop — the first mini-game | **done** |
| 5 | Rive character reacting to pops, via data binding | **plumbing done, not wired** — stand-in removed, awaiting real art |
| 6 | Kid sound cues + per-screen music, replacing the arcade sfx | **done** (placeholder audio) |
| 7 | Balloon Pop — feel: swipe-to-pop, burst, living sky, animated stars, pop ladder | **done** |
| 8 | Balloon Pop — mechanics: chaining colour bunches, three-tap big balloons, a sky that answers | **done** |
| 9 | Dress the Dog — the second game: dress a dog (tap or drag), toggle the weather, the dog reacts | **playable, placeholder art** — [scope](scope/games/dress-the-dog-scope.md), [session](sessions/games/dress-the-dog-session.md); never run on a device |
| 10 | Dress the Dog — a layout that fits a phone, not just a tablet | **done** — [session](sessions/games/dress-the-dog-responsive-layout-session.md), [debugging](debugging/games/dress-the-dog-overflows-on-a-phone.md); **run on the Android emulator**, overflow gone |
| 11 | Cat Run — the third game: a cat that runs, jumps over and ducks under things, and never loses | **playable, placeholder art** — [scope](scope/games/cat-run-scope.md), [session](sessions/games/cat-run-session.md); **never run on a device or in a browser** |
| 12 | Blast Off — a countdown the child sets going, counts along with, and cheers at zero | **playable, placeholder art, no voice** — [scope](scope/games/blast-off-scope.md); never run on a device |
| 13 | Cat Run — the jump, which was never drawn: the cat's air height reached its hitbox but never the canvas | **done** — [session](sessions/games/cat-run-jump-session.md); arc looked at as stills, **still never felt in motion** |
| 14 | Blast Off — the rocket grows with the chosen countdown, so the length has a readout that needs no reading | **done** — [session](sessions/games/blast-off-rocket-size-session.md); ladder looked at as stills, **never run on a device** |
| 15 | Blast Off — the control buttons were drawn over the rocket and the star jar | **done** — [session](sessions/games/blast-off-controls-overlap-session.md), [debugging](debugging/games/blast-off-controls-cover-the-rocket.md); fixed at every target size, **looked at as stills only** |

## Build health

| Check | State | Notes |
|---|---|---|
| `flutter analyze` | clean | 0 issues |
| `flutter test` | passing | 217 tests with `--exclude-tags render` (was 199 before the controls fix). The earlier 248 counted the render-tagged tests too |
| Android APK | builds | debug APK; `rive_native` links |
| Web (dev only) | runs | used to drive and screenshot the app from this machine |
| Played, headless | **yes** | menu → swipe → 10 pops → celebration → home, 1280x720 landscape, no console or page errors |
| Haptics, felt | **not done** | no vibrator in reach of these sessions |
| iOS | **unverified** | no macOS machine available to these sessions |
| macOS | **unverified** | the user's dev run target |
| Sound, heard | **not done** | audio checked numerically only; never played on a device |
| Real device, real child | **not done** | the thing that actually matters — see below |

## What is proven, and what isn't

**Proven:** the menu renders with no text and three big tiles; tapping one enters Balloon Pop;
balloons rise, pop on tap, and respawn; progress stars fill and reset, so celebrations fire; a
Rive file loaded and rendered through the 0.14 data-binding API (proven with the stand-in, which has
since been removed — the path is unexercised until real art arrives); a quick tap cannot open settings but
a 3-second hold can; no Dart errors across several hundred synthetic taps. Every sfx filename
referenced in Dart exists; the generated audio has no clipping, no edge clicks and no content above
4 kHz; the cue volume ordering (wobble < pop < celebrate) is locked by a test; a tap consumed by a
balloon cannot also fire the empty-sky cue.

From the second pass, confirmed on screen in a driven browser session: a **swipe pops the balloons
it passes through**; the sky, sun, parallax clouds and hills render and drift; the shred-and-ring
burst appears in the popped balloon's colour and clears itself; sparkly balloons fire a local puff;
the star row springs a newly earned star, stays legible over a drifting cloud, resets under the
confetti, and the celebration mixes falling and rising pieces. **A chain caught mid-ripple:** one
tap on a bunch of three, next frame all three gone, three stars filled, three burst rings, and the
odd-coloured balloon beside them untouched. The sun turns out rays on a tap. Pinned by test: the smallest balloon
the game can spawn still clears 80x80; the pop ladder only ever climbs and never indexes off the end
of the sample list; a balloon that drifted away cannot then be popped; bursts and confetti both
remove themselves.

**Cat Run, not proven at all — it has never been seen moving:**

- **Never run on a device, an emulator or in a browser.** The scrolling, the parallax, the jump arc
  and the scene cross-fade are all unverified in motion. A green suite is standing in for a device
  run here more than anywhere else in this app.
- **The jump has never been felt**, and the whole game is that one arc. `jumpDuration`,
  `coyoteTime` and `jumpBufferTime` are reasoned and tested, not played. The rise itself is now
  fitted to the screen (`Cat.fitTo`) rather than a flat 250, which does not fit a phone — see the
  [jump session](sessions/games/cat-run-jump-session.md).
- **The jump was, until 2026-09-20, not drawn at all**: `airHeight` fed the hitbox and never the
  canvas, so the cat's hitbox cleared the fence while the cat stayed on the ground lifting its legs.
  Eleven green tests did not catch it, because all of them asserted on the model. A pixel-level test
  now pins that the cat is *drawn* off the ground. Worth remembering elsewhere in this app: a test
  that reads the same number the code wrote proves nothing about what the child sees.
- **Whether a miss reads as funny rather than as failing.** The tumble, the pancake and the
  belly-flop are the entire answer to "a runner is failure-shaped", and whether a five-year-old
  laughs or looks crushed is the one thing that cannot be asserted. `test/cat_run_render_test.dart`
  renders all four to PNGs so they can at least be looked at.
- **Whether the crouch button is discovered at all.** If not, the scope's fallback stands: cut duck
  obstacles to scenery and the game still works jump-only.
- **Whether the ear-flattening telegraph reads as a warning** to a child, or as nothing.
- **The chime ladder has only Balloon Pop's three rungs**, so "a note higher than the last" is
  shallower than the scope asks. Same blocked thread as the pop ladder — no mp3 encoder here.

**Not proven — needs a tablet and a five-year-old:**

- Whether balloons are too fast, too slow, too sparse or too dense — and whether three sizes reads
  as variety or as inconsistency.
- **Whether swipe-to-pop feels generous or feels like cheating.** A mouse drag in headless Chrome is
  not a child sweeping a hand across a tablet, and this feature rests on that difference being
  small. `dragReach` is a guess.
- **Whether the pop note climbing is audible as a climb.** Three rungs across ten pops may be too
  shallow to notice; it was verified as an index sequence, never heard.
- Whether the light haptic on a pop helps or is just noise in the hand.
- **Whether a child works out that the big balloon wants more taps.** The swelling is the only
  instruction in the game, and it was never caught in a screenshot — only proven by test.
- **Whether the sky is now too busy.** Bunches of three plus showers of five make it much fuller.
  `maxBalloonsHard` bounds it; "calm" is still a judgement only real hands can make.
- Whether the ripple is discovered at all, or whether bunches need to be more frequent.
- Whether a Material icon on a coloured tile reads as "a game I can play".
- **Whether the empty-sky cue reads as friendly or as "you missed."** This replaced the silence on a
  missed tap; if it reads as a failure signal it should come out.
- Whether the pop is satisfying, the celebration feels like a reward, and the music sits far enough
  back. **None of the audio has actually been listened to** — it was verified numerically.
- Whether a "coming soon" tile reads as not-yet rather than broken.
- Whether a child who has watched a parent can copy the 3-second hold.

## Open threads

| Thread | Where |
|---|---|
| Sound is **synthesised placeholder tone**, not recorded audio — good enough to be safe, not good enough to be charming | [tools/README.md](../tools/README.md) |
| The pop ladder has only **three rungs**: no mp3 encoder on this machine (no ffmpeg/lame/sox/gstreamer), so more samples could not be generated. No Dart change needed when they are | [tools/README.md](../tools/README.md) |
| **Haptics have no settings switch.** Light impacts only, fire-and-forget, never on a mistake — but a parent who wants them off cannot turn them off | [shared README](../lib/shared/README.md) |
| Template **arcade music** still plays under the games; only the sfx were replaced | [celebration scope](scope/shared/celebration-and-sound-scope.md) |
| No real artwork; balloons are drawn shapes, tiles are Material icons | [balloon pop README](../lib/games/balloon_pop/README.md) |
| **The ± steppers drop out on a narrow screen** (under ~736dp wide, so every landscape phone). The presets still reach every length, but an adult loses the one-rung nudge on a phone | [controls session](sessions/games/blast-off-controls-overlap-session.md) |
| Blast Off's rocket grows with the countdown length, but on a very short landscape phone (~375dp) the sky leaves it only a 15% spread — correct and legal, barely visible. The dots stay the readout that always works | [rocket size session](sessions/games/blast-off-rocket-size-session.md) |
| Dress the Dog fits every landscape phone, but on a very short one (~375dp) the dog ends up small in the corner — correct and hittable, not pretty. Smaller than any target device | [layout session](sessions/games/dress-the-dog-responsive-layout-session.md) |
| Candidate pool for the next games grew after a survey of other open-source kids' apps; **which one is next is still unchosen** | [references](vision/references.md), [roadmap](vision/roadmap.md) |
| **No persistence between sessions.** Celebrations do not add up to anything — a sticker book is the obvious next feature, and `shared_preferences` is already wired in | [roadmap](vision/roadmap.md) |
| **There is no character on screen.** The `rewards.riv` stand-in (a mock rewards *screen*, not a character) was removed — it read as a small dark phone lying in the grass and did nothing when tapped. `RiveCharacter` and `RiveNative.init()` remain, unused and ready for real art | [balloon pop README](../lib/games/balloon_pop/README.md) |
| Landscape set in `main.dart`, **not** yet in the native manifests | [platform scope](scope/setup/landscape-and-platform-config-scope.md) |
| `web/`, `windows/`, `linux/` folders still present; not shipping targets | same |
| Template leftovers: Dash sprites, arcade music, unused `nes_ui` dep | [setup scope](scope/setup/project-from-template-scope.md) |

## Dependency versions in play

Checked against `pubspec.lock`, not memory.

| Package | Version | Note |
|---|---|---|
| `flame` | 1.38.2 | |
| `flame_rive` | 1.11.2 | |
| `rive` | 0.14.11 | **new API** — `File.asset`, `defaultStateMachine()`, data binding |
| `rive_native` | 0.1.11 | transitive; downloads native artifacts at build time |

Gotcha worth remembering: `Factory` is exported by both `flutter/foundation.dart` and Rive —
`lib/shared/rive_character.dart` imports foundation with `hide Factory`.

## Index

- [`ABOUT-DOCS.md`](ABOUT-DOCS.md) — how these docs are organised
- [`scope/README.md`](scope/README.md) — the asks
- [`sessions/README.md`](sessions/README.md) — the working logs
- [`debugging/README.md`](debugging/README.md) — issues and fixes
- [`testing/README.md`](testing/README.md) — runbooks
- [`vision/roadmap.md`](vision/roadmap.md) — where this is going
- [`vision/references.md`](vision/references.md) — public resources the game ideas and the
  design rules are drawn from
- [`../CLAUDE.md`](../CLAUDE.md) — the binding rules
