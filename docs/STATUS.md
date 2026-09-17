# Status

Where we are, right now. Updated at the end of every session.

- **Last updated:** 2026-09-17
- **Now:** the app is playable. Picture menu → Balloon Pop → pop balloons → celebration → repeat,
  with a parent-gated settings screen. All placeholder art.
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

## Build health

| Check | State | Notes |
|---|---|---|
| `flutter analyze` | clean | 0 issues |
| `flutter test` | passing | 10 tests |
| Android APK | builds | debug APK; `rive_native` links |
| Web (dev only) | runs | used to drive and screenshot the app from this machine |
| iOS | **unverified** | no macOS machine available to these sessions |
| macOS | **unverified** | the user's dev run target |
| Real device, real child | **not done** | the thing that actually matters — see below |

## What is proven, and what isn't

**Proven:** the menu renders with no text and three big tiles; tapping one enters Balloon Pop;
balloons rise, pop on tap, and respawn; progress dots fill and reset, so celebrations fire; the
Rive file loads and renders through the 0.14 data-binding API; a quick tap cannot open settings but
a 3-second hold can; no Dart errors across several hundred synthetic taps.

**Not proven — needs a tablet and a five-year-old:**

- Whether balloons are too fast, too slow, too sparse or too dense.
- Whether a Material icon on a coloured tile reads as "a game I can play".
- Whether silence on a completely missed tap feels broken.
- Whether a "coming soon" tile reads as not-yet rather than broken.
- Whether a child who has watched a parent can copy the 3-second hold.

## Open threads

| Thread | Where |
|---|---|
| Sound effects are still the template's **arcade sfx** — a realistic pop would startle a child | [celebration scope](scope/shared/celebration-and-sound-scope.md) |
| No real artwork; balloons are drawn shapes, tiles are Material icons | [balloon pop README](../lib/games/balloon_pop/README.md) |
| Rive character is `rewards.riv` — a mock rewards *screen*, not a character | same |
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
