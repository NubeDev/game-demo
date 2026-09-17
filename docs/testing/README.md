# Testing runbooks

How to drive the app by hand. Every runbook is walked on a real target and the real result recorded
before it lands — `flutter test` proves logic, a thumb proves a game.

| Runbook | Covers | Last walked |
|---|---|---|
| [first-play-runbook.md](first-play-runbook.md) | Menu → Balloon Pop → celebration → parental gate | 2026-09-17 (browser only) |

## Targets

| Target | Command | Use |
|---|---|---|
| macOS desktop | `flutter run -d macos` | fast iteration during development |
| Android | `flutter run -d <device>` | the real thing; check touch sizes on a tablet |
| iOS simulator | `flutter run -d <simulator>` | the other real thing |

## What a runbook here has that a normal one doesn't

A section on **what a child does without instruction**. Note anywhere a tester had to be *told*
what to tap — for this audience that is a design bug, not a tester problem. Record the child's age
and whether an adult spoke.

## Runbook template

```markdown
# <what this walks>

- Target: <macOS | Android device | iOS simulator>
- Last walked: YYYY-MM-DD — result

## Setup
Commands to get the app running, with real output.

## Steps
1. Tap X → expect Y.

## Kid-rules spot check
- Touch targets look/feel big enough under an actual finger?
- Any way to fail, lose, or get stuck?
- Home button visible from every screen?
- Anything require reading?

## What a child did without instruction
Age, what they tried first, where they needed an adult.
```
