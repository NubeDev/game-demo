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

Both rules cost something on every screen, and that cost is the design. With no score there is no
reward loop, so the celebration *is* the reward and it has to be generous. With no text there is no
tutorial, so the first thing a child touches has to answer them. Most of what looks like polish in
here is one of those two bills being paid.

The full reasoning is in [`docs/scope/little-games-scope.md`](docs/scope/little-games-scope.md);
the binding version every contributor (human or AI) must follow is [`CLAUDE.md`](CLAUDE.md).

## What's in it

**A picture home screen** — one big tile per game, no words anywhere, and a muted settings corner
behind a 3-second hold that a child cannot pass but an adult reads in a second.

**Balloon Pop** — balloons rise through a drifting sky; touch one and it bursts into rubber shreds
with a rising note. Ten pops fills a row of stars and the screen throws confetti, then it rolls
straight on. A **dragged finger pops too**, because sweeping an arm is easier than aiming a tap at
five. Balloons come in three sizes and the big ones climb slowest, so the easiest target is also the
one that waits longest. A balloon that reaches the top just floats away — silently, with nothing
subtracted, because there is no miss to record.
See [`lib/games/balloon_pop/README.md`](lib/games/balloon_pop/README.md).

**Shared pieces** — the celebration, the sound cues, the home button, the parental gate and the
Rive character are built once in [`lib/shared/`](lib/shared/README.md), so game number four is
mostly assembly and, more importantly, so a child who learns what a celebration means in one game
recognises it in the next.

All the artwork is still placeholder shapes drawn in code, and all the audio is synthesised
placeholder tone. Both swap out without touching logic — see
[`docs/STATUS.md`](docs/STATUS.md) for what is real and what is standing in.

## Running it

```bash
make deps                      # flutter pub get
make run                       # desktop, fast iteration (DEV_DEVICE=macos on a Mac)
make run-device DEVICE=<id>    # a real phone or tablet — the only run that counts
make devices                   # list the ids
```

`make run-emulator` and `make run-web` exist for when no device is to hand; neither proves anything
about a thumb. See the [`Makefile`](Makefile) for what each one is good for.

## Checking it

```bash
make check     # analyze clean + tests passing + the privacy grep
```

That is the gate, and it is deliberately not the whole story. Touch-target size, gameplay feel and
sound only answer on hardware a five-year-old is holding — a mouse click is not a thumb, and a green
test suite has never heard the pop. Anything a session could not verify gets said out loud rather
than assumed; `docs/STATUS.md` keeps the running list.

Before calling anything done, the kid-rules check in [`CLAUDE.md`](CLAUDE.md) §6: could a child who
cannot read do this, is every target ≥ 80×80 with space around it, is there any way to lose or get
stuck, is the home button visible, and did anything new touch the network.

## Layout

```
lib/
├── games/     ← one self-contained folder per mini-game
├── shared/    ← celebration, sounds, haptics, shapes, home button, parental gate, Rive character
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
| [`docs/HOW-TO-CODE.md`](docs/HOW-TO-CODE.md) | how to build a piece of this |
| [`docs/FILE-LAYOUT.md`](docs/FILE-LAYOUT.md) | where Dart goes |
| [`docs/scope/`](docs/scope/README.md) | what we want, before the work |
| [`docs/sessions/`](docs/sessions/README.md) | what was done, while doing it |
| [`docs/vision/roadmap.md`](docs/vision/roadmap.md) | where this is going |
| [`docs/testing/`](docs/testing/README.md) | runbooks for driving the app by hand |
| [`docs/debugging/`](docs/debugging/README.md) | every issue and how it became working |
| [`tools/README.md`](tools/README.md) | the placeholder sound generator |

## Privacy

Nothing leaves the device. No network calls of any kind, no analytics, no crash reporting, no
third-party SDK that collects anything. The only stored state is game progress and sound settings,
in local preferences. Built to clear Apple's Kids Category, Google Play Families, and COPPA.

`make privacy` greps `lib/` and `pubspec.yaml` for network and SDK references and fails on a single
hit — the promise is a requirement, not a simplification, so it is checked rather than remembered.
