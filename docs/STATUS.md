# Status

Where we are, right now. Updated at the end of every session.

- **Last updated:** 2026-09-18
- **Now:** the app is playable, has its own sound, and Balloon Pop has had a second pass for *feel*.
  Picture menu → Balloon Pop → pop or **swipe** balloons through a drifting sky → stars spring in as
  the pop note climbs → confetti → repeat, with a parent-gated settings screen. All placeholder art
  (drawn in code) and placeholder (but kid-appropriate) audio.
- **Next:** play it on a real tablet with a real child. Everything left is either art, sound, or
  tuning that only a child can settle.

## The plan

| # | Step | Status |
|---|---|---|
| 1 | Project from template, renamed, integrations checked, builds | **done** |
| 2 | `CLAUDE.md` — the binding rules for every future session | **done** |
| 3 | Kid-friendly home screen with picture buttons + gated settings | **done** |
| 4 | Balloon Pop — the first mini-game | **done** |
| 5 | Rive character reacting to pops, via data binding | **done** (stand-in art) |
| 6 | Kid sound cues + per-screen music, replacing the arcade sfx | **done** (placeholder audio) |
| 7 | Balloon Pop second pass: swipe-to-pop, burst, living sky, animated stars, pop ladder | **done** |

## Build health

| Check | State | Notes |
|---|---|---|
| `flutter analyze` | clean | 0 issues |
| `flutter test` | passing | 29 tests (was 19) |
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
balloons rise, pop on tap, and respawn; progress stars fill and reset, so celebrations fire; the
Rive file loads and renders through the 0.14 data-binding API; a quick tap cannot open settings but
a 3-second hold can; no Dart errors across several hundred synthetic taps. Every sfx filename
referenced in Dart exists; the generated audio has no clipping, no edge clicks and no content above
4 kHz; the cue volume ordering (wobble < pop < celebrate) is locked by a test; a tap consumed by a
balloon cannot also fire the empty-sky cue.

From the second pass, confirmed on screen in a driven browser session: a **swipe pops the balloons
it passes through**; the sky, sun, parallax clouds and hills render and drift; the shred-and-ring
burst appears in the popped balloon's colour and clears itself; sparkly balloons fire a local puff;
the star row springs a newly earned star, stays legible over a drifting cloud, resets under the
confetti, and the celebration mixes falling and rising pieces. Pinned by test: the smallest balloon
the game can spawn still clears 80x80; the pop ladder only ever climbs and never indexes off the end
of the sample list; a balloon that drifted away cannot then be popped; bursts and confetti both
remove themselves.

**Not proven — needs a tablet and a five-year-old:**

- Whether balloons are too fast, too slow, too sparse or too dense — and whether three sizes reads
  as variety or as inconsistency.
- **Whether swipe-to-pop feels generous or feels like cheating.** A mouse drag in headless Chrome is
  not a child sweeping a hand across a tablet, and this feature rests on that difference being
  small. `dragReach` is a guess.
- **Whether the pop note climbing is audible as a climb.** Three rungs across ten pops may be too
  shallow to notice; it was verified as an index sequence, never heard.
- Whether the light haptic on a pop helps or is just noise in the hand.
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
| Rive character is `rewards.riv` — a mock rewards *screen*, not a character. Now sits on the new hills, where it reads as a small phone lying in the grass | same |
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
- [`../CLAUDE.md`](../CLAUDE.md) — the binding rules
