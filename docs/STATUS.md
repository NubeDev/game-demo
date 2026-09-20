# Status

Where we are, right now. Updated at the end of every session.

- **Last updated:** 2026-09-20
- **Now:** the app is playable, has its own sound, and the menu carries **seven** tiles plus a
  parent-gated settings screen. Picture menu → **Balloon Pop** (pop or swipe balloons, colour
  bunches ripple, big balloons shower) → **Cat Run** (a cat that runs, jumps, ducks, bounces and
  bonks, and never loses) → **Dress the Dog** (dress a dog against the weather) → **Car Trip**
  (steer a car down a road with a thumb and pick up animals) → **Neil the Seal** (tap
  anywhere and an enormous elephant seal galumphs there and flops on whatever is in the way) →
  **Crystal Party** (hold anywhere and a unicorn rises on a rainbow; gather low blue and high pink
  crystals to fill the arch on the horizon) → **Blast Off** (a countdown
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
- **Run every game on a device before believing it.** Car Trip was the first game here actually
  driven under a finger, and the run found two bugs that 319 passing tests and a set of still
  renders had both missed: a hit test that silently failed whenever a frame took too long, and a
  prop that grew until it covered the whole screen. Both would have hit a child on cheap hardware.
  Several games in the table below are still marked *never run on a device* — **on this evidence
  that is the highest-value work left**, ahead of any new game. See the
  [Car Trip session](sessions/games/car-trip-session.md).

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
| 16 | Car Trip — the first game the child **steers**: a thumb on the bottom half drives a car down a road, picking up animals until it arrives somewhere | **playable, placeholder art** — [scope](scope/games/car-trip-scope.md), [session](sessions/games/car-trip-session.md); **run on the Android emulator under real touch**, which found two bugs the tests could not |
| 17 | Neil the Seal — the sixth game and a new verb: **choose a place**, and watch what two tonnes of relaxed animal does when it gets there. Everything he lands on squashes and springs straight back | **playable, placeholder art** — [scope](scope/games/neil-the-seal-scope.md), [session](sessions/games/neil-the-seal-session.md), [README](../lib/games/neil_the_seal/README.md); **driven in Chrome over CDP** — taps, a mid-trip redirect, a rub, the bellow and a full nap, with no console errors; **never run on a device, and none of its fourteen new sounds has been heard** |
| 18 | Crystal Party — the seventh game, and the second **journey**: hold anywhere and a unicorn rises on a rainbow, gathering low blue and high pink crystals to fill the arch on the horizon | **playable, placeholder art** — [scope](scope/games/crystal-party-scope.md), [session](sessions/games/crystal-party-session.md), [README](../lib/games/crystal_party/README.md); **played through in a desktop browser under a driven pointer** — a full land, the party, and on into the next land — which found the arch painting nothing at all; never run on a phone or tablet |
| 19 | Quacky the Duck — the eighth game and a new verb: **close a gap**. A grumpy park duck dashes after children and ducks carrying bread, and skids under benches on the way | **scope only, no code** — [scope](scope/games/quacky-the-duck-scope.md); the ask is captured, nothing built. Deliberately behind the device runs above |

## Build health

| Check | State | Notes |
|---|---|---|
| `flutter analyze` | clean | 0 issues |
| `flutter test` | passing | **441 tests**; 36 of them new for Crystal Party |
| Android APK | builds | debug APK; `rive_native` links |
| Web (dev only) | runs | used to drive and screenshot the app from this machine. **Neil the Seal was played through it over the DevTools Protocol** — taps, a mid-trip redirect, a rub, the bellow and a full nap, with no console errors. **Crystal Party too** — a held pointer lifts the unicorn into the clouds and a release floats her down, with no page errors. Note headless Chrome throttles `requestAnimationFrame` to nothing unless `--disable-background-timer-throttling` and friends are passed, and a bare mouse event never reaches Flutter's gesture arena without `pointerType` |
| Played, headless | **yes** | menu → swipe → 10 pops → celebration → home, 1280x720 landscape, no console or page errors |
| Played, Android emulator | **Car Trip only** | 2400x1080 landscape, real touch events. Steering, pickups, the horn and the home button all work. Only ever seen at ~2fps (software rendering), so **nothing has been judged for feel** |
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
| The pop ladder still has only **three rungs**. The reason has gone away — **ffmpeg with libmp3lame is on this machine now**, and Neil the Seal generated and encoded fourteen new cues with it — so this is now just a job nobody has done. No Dart change needed when it is | [tools/README.md](../tools/README.md) |
| **Haptics have no settings switch.** Light impacts only, fire-and-forget, never on a mistake — but a parent who wants them off cannot turn them off | [shared README](../lib/shared/README.md) |
| Template **arcade music** still plays under the games; only the sfx were replaced | [celebration scope](scope/shared/celebration-and-sound-scope.md) |
| No real artwork; balloons are drawn shapes, tiles are Material icons | [balloon pop README](../lib/games/balloon_pop/README.md) |
| **The ± steppers drop out on a narrow screen** (under ~736dp wide, so every landscape phone). The presets still reach every length, but an adult loses the one-rung nudge on a phone | [controls session](sessions/games/blast-off-controls-overlap-session.md) |
| Blast Off's rocket grows with the countdown length, but on a very short landscape phone (~375dp) the sky leaves it only a 15% spread — correct and legal, barely visible. The dots stay the readout that always works | [rocket size session](sessions/games/blast-off-rocket-size-session.md) |
| Dress the Dog fits every landscape phone, but on a very short one (~375dp) the dog ends up small in the corner — correct and hittable, not pretty. Smaller than any target device | [layout session](sessions/games/dress-the-dog-responsive-layout-session.md) |
| **Frame-rate-dependent hit tests are a whole class of bug here.** Car Trip's was found and fixed; every other game that decides "did the child hit it" from an instantaneous position should be checked the same way | [car trip session](sessions/games/car-trip-session.md) |
| Car Trip has **never been seen at a normal frame rate**. Steering speed, road speed and the arrival cross-fade are all unjudged for feel | [car trip session](sessions/games/car-trip-session.md) |
| The progress row is now the app's **fourth** hand-written copy of the same component (Balloon Pop's stars, Cat Run's fish, Car Trip's dots, Neil the Seal's shells). Well past the point at which it should move to `lib/shared/` | [car trip README](../lib/games/car_trip/README.md) |
| Candidate pool for the next games grew after a survey of other open-source kids' apps; **which one is next is still unchosen** | [references](vision/references.md), [roadmap](vision/roadmap.md) |
| **No persistence between sessions.** Celebrations do not add up to anything — a sticker book is the obvious next feature, and `shared_preferences` is already wired in | [roadmap](vision/roadmap.md) |
| **There is no character on screen.** The `rewards.riv` stand-in (a mock rewards *screen*, not a character) was removed — it read as a small dark phone lying in the grass and did nothing when tapped. `RiveCharacter` and `RiveNative.init()` remain, unused and ready for real art | [balloon pop README](../lib/games/balloon_pop/README.md) |
| Landscape set in `main.dart`, **not** yet in the native manifests | [platform scope](scope/setup/landscape-and-platform-config-scope.md) |
| `web/`, `windows/`, `linux/` folders still present; not shipping targets | same |
| Template leftovers: Dash sprites, arcade music, unused `nes_ui` dep | [setup scope](scope/setup/project-from-template-scope.md) |
| **Fourteen new sound cues, none of them listened to** — flump, boing (the sink and the springback), squelch, bellow, snore, wriggle, and the town's five answering voices. Verified numerically only: all peak at −3.5 dBFS, no clipping. The boing is the sound Neil the Seal rests on, and nobody has heard it | [neil session](sessions/games/neil-the-seal-session.md) |
| Neil the Seal's hose borrows the squelch cue; it wants a hiss of its own | [neil README](../lib/games/neil_the_seal/README.md) |
| **Crystal Party has no crystal chime of its own.** Blue and pink ring on different halves of the existing three-rung `kid_pop` ladder, which separates them but thinly — the scope asks for a bell and a chime that are audibly different instruments. Deepening the pop ladder (already an open thread above) fixes both at once | [crystal party session](sessions/games/crystal-party-session.md) |
| **The menu is now two rows on a small landscape phone**, which is correct and tested but has never been looked at on a real one. Seven tiles no longer fit one row at the 88px kid-rule floor | [crystal party session](sessions/games/crystal-party-session.md) |
| Crystal Party's **party has been seen but never heard or felt** — a two-minute driven run filled the arch, fired the celebration and moved on to the beach, all correct in stills. The blaze is specified as a *slow* swell for photosensitivity reasons, and **whether it actually reads as slow is a motion judgement nobody has made** | [crystal party README](../lib/games/crystal_party/README.md) |

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
