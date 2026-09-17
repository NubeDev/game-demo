# How to code in this repo

Companion to [`FILE-LAYOUT.md`](FILE-LAYOUT.md) (where code goes) and
[`../CLAUDE.md`](../CLAUDE.md) (the binding rules). This is *how* to work.

## 1. Small steps, each one runnable

Every change should end at a state you can run and look at. This project is being built by someone
learning Flutter, so a large change that only works at the end is worse than four small ones that
each show something on screen — even if the total is more work.

## 2. Check the API, never recall it

The single biggest source of wasted time here is a confidently-wrong API call. **Rive 0.14 replaced
its entire Flutter API**, and most examples on the internet are the old one.

Before using an unfamiliar call:

- check the resolved version in `pubspec.lock`;
- read the actual installed source in `~/.pub-cache/hosted/pub.dev/<package>-<version>/`;
- for Rive and Flame specifically, check the official example and docs linked in
  [`../CLAUDE.md`](../CLAUDE.md).

If something fails to compile, **look it up** — do not try variations until one sticks.

Add packages with `flutter pub add`, which pins the current version, rather than hand-writing a
constraint from memory.

## 3. Placeholder art, real structure

Use flat coloured shapes until real artwork exists, but wire them up as if they were real: paths in
the game's `assets.dart`, correct sizes, correct layering. Swapping art should be a one-file edit,
never a refactor.

## 4. Comments explain why, not what

The reader is learning Flutter and Flame. A comment earns its place when it explains something the
code cannot say: why a constant is that value, why a rule exists, why an obvious-looking
alternative is wrong.

```dart
// Pop on tap-DOWN, not tap-up: a five-year-old's finger often slides between
// the two, and an ignored tap reads to them as the game being broken.
```

Kid-rule and store-policy constraints in particular **must** be commented where they are
implemented, or a future session will "clean them up".

## 5. Test what can be tested, then use it

- `flutter test` for logic and widgets — spawn behaviour, the gate's timing, progress counting.
- `flutter analyze` clean before anything is called done.
- Then **run it**. Gameplay feel, touch target size, sound and animation are not testable in CI;
  they are checked by playing. `flutter run -d macos` for fast iteration, a real device or
  simulator before a step is signed off.
- State plainly in the session doc what was only verified by build and not by hand.

## 6. The kid-rules check is part of coding, not review

Before calling a change done, walk it:

- Could a child who cannot read do this?
- Is every touch target ≥ 80×80 logical pixels, with space around it?
- Is there any way to lose, fail, run out of time, or get stuck?
- Is the home button visible?
- Did anything just add a network call, an SDK, or stored personal data?

The last one is worth a literal grep before a release: nothing in this app should reference `http`,
`dio`, a socket, or any analytics package.

## 7. Write the docs as you go

A session that changed code and wrote no session doc is not finished — see
[`ABOUT-DOCS.md`](ABOUT-DOCS.md). Update the scope doc's open questions in the scope doc, not only
in the log.
