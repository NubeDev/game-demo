# Little Games

Simple, friendly mini-games for **5-year-olds**, on iOS and Android. Fully offline, no ads, no
tracking, no data collection, and no way to lose.

Built with Flutter + [Flame](https://flame-engine.org/), starting from the official
[Casual Games Toolkit](https://github.com/flutter/games) `endless_runner` template, with
[Rive](https://rive.app/) for animated characters and rewards.

## The two rules everything follows from

**The player cannot read.** No instruction is written, no button is labelled, nothing relies on a
word. Pictures, sound and motion only. Text appears in exactly one place — the parent area, behind
a parental gate, where it is the barrier rather than the interface.

**Nothing can be lost.** No game over, no failure timer, no score to be bad at. A mistake gets a
gentle wobble and a soft sound, and the child tries again.

The full reasoning is in [`docs/scope/little-games-scope.md`](docs/scope/little-games-scope.md);
the binding version every contributor (human or AI) must follow is [`CLAUDE.md`](CLAUDE.md).

## Running it

```bash
flutter pub get
flutter run -d macos     # fast iteration during development
flutter run -d <device>  # a real phone or tablet — the only way to judge a game
```

Landscape only. `flutter test` and `flutter analyze` cover logic; gameplay feel, touch-target size
and sound are only proven under a thumb.

## Layout

```
lib/
├── games/     ← one self-contained folder per mini-game
├── shared/    ← celebration, sounds, home button, parental gate, Rive character
├── menu/      ← the picture home screen
└── …          ← audio/, settings/, player_progress/, app_lifecycle/, style/ from the template
```

See [`docs/FILE-LAYOUT.md`](docs/FILE-LAYOUT.md) for the rules — the short version is that a game
owns its folder and reaches into `shared/`, and nothing reaches into a game.

## Docs

| | |
|---|---|
| [`docs/STATUS.md`](docs/STATUS.md) | where we are right now — **start here** |
| [`docs/ABOUT-DOCS.md`](docs/ABOUT-DOCS.md) | how the docs are organised and the rules for AI sessions |
| [`docs/scope/`](docs/scope/README.md) | what we want, before the work |
| [`docs/sessions/`](docs/sessions/README.md) | what was done, while doing it |
| [`docs/vision/roadmap.md`](docs/vision/roadmap.md) | where this is going |
| [`docs/testing/`](docs/testing/README.md) | runbooks for driving the app by hand |
| [`docs/debugging/`](docs/debugging/README.md) | every issue and how it became working |

## Privacy

Nothing leaves the device. No network calls of any kind, no analytics, no crash reporting, no
third-party SDK that collects anything. The only stored state is game progress and sound settings,
in local preferences. Built to clear Apple's Kids Category, Google Play Families, and COPPA.
