# CLAUDE.md — Little Games

Binding rules for every session in this repo, human or AI. Read this before writing code.

**Little Games** is a collection of simple mini-games for **5-year-olds**, on iOS and Android.
Fully offline, no ads, no tracking, no way to lose.

The reasoning behind these rules is in [`docs/scope/little-games-scope.md`](docs/scope/little-games-scope.md).
Where this file and a scope doc disagree, **this file wins** — and fix the scope doc.

---

## 1. Tech stack

- **Flutter + [Flame](https://flame-engine.org/)** for the games.
- **[`flame_rive`](https://pub.dev/packages/flame_rive) + [`rive`](https://pub.dev/packages/rive)**
  for animated characters and rewards.
- Built from the official Flutter **Casual Games Toolkit** `endless_runner` template
  (<https://github.com/flutter/games>) — its app skeleton is kept, its gameplay replaced.
- Targets **iOS and Android**. `flutter run -d macos` is used for development only; macOS, web,
  Windows and Linux are **not shipping targets**.
- **Landscape only.**

### Versions — check, don't recall

**Always add packages with `flutter pub add`** so the current version is pinned, and check
[pub.dev](https://pub.dev) if unsure. Read the resolved version in `pubspec.lock` and the installed
source in `~/.pub-cache/hosted/pub.dev/<package>-<version>/` rather than trusting memory.

If an API call fails to compile, **look up the current API**. Do not try variations until one
sticks.

---

## 2. The Rive API — use the NEW one

`rive` **0.14 changed its Flutter API wholesale**. Most examples online are the old API and will
not work. Currently resolved: `rive` 0.14.11, `rive_native` 0.1.11, `flame_rive` 1.11.2.

**Use:**

- `await RiveNative.init()` once, before loading any file (in `main()`).
- `File.asset('assets/rive/<name>.riv', riveFactory: Factory.flutter)` to load.
- `await loadArtboard(file)` for the artboard.
- `artboard.defaultStateMachine()` — or `artboard.stateMachine('<name>')` for a named one.
- **Data binding** for all animation control:
  ```dart
  final vm = file.defaultArtboardViewModel(artboard);
  final instance = vm?.createDefaultInstance();
  if (instance != null) stateMachine.bindViewModelInstance(instance);
  // then reach properties through the bound instance:
  final bound = stateMachine.boundRuntimeViewModelInstance;
  final trigger = bound?.trigger('Celebrate');     // ViewModelInstanceTrigger
  final number  = bound?.number('Mood');           // ViewModelInstanceNumber
  final nested  = bound?.viewModel('Coin')?.number('Item_Value');
  ```

**Never use** (deprecated/removed): `StateMachineController`, `SMIInput`, `SMITrigger`,
`SMINumber`, `SMIBool`, `RiveFile.asset`, `RiveAnimation`, or state-machine *inputs*.

Reference: the [official flame_rive example](https://github.com/flame-engine/flame/tree/main/packages/flame_rive/example)
and [the flame_rive docs](https://docs.flame-engine.org/latest/bridge_packages/flame_rive/rive.html).

---

## 3. Design rules for 5-year-olds

These are not preferences. Each one is load-bearing.

| Rule | Why |
|---|---|
| **No text needed to play.** Icons, pictures, voice and sound instead. | The player **cannot read**. Text is allowed **only** in the parent area. |
| **Touch targets ≥ 80×80 logical pixels**, generously spaced. | Coarse motor control; the finger covers the target. A mis-tap reads as the game ignoring them. |
| **No losing. No game over. No timer that can cause failure.** | Failure at this age stops play rather than sharpening it. |
| Mistakes get a **gentle wobble or soft sound**, then they try again. | Never punish. Never scold. |
| **Lots of positive feedback** — sounds, bouncy animation, confetti, stars. | With no score and no winning, this *is* the reward loop. |
| **Bright, friendly, calm.** No flashing, nothing scary. | Avoids startling, and photosensitivity risk. |
| **Every game has a big, obvious home button.** | The child must be able to leave without finding an adult. |
| **Works fully offline. No network calls, ever.** | Privacy requirement, not a simplification. |
| **Landscape only.** | One layout; the screen never rearranges under their hands. |

**A progress count is allowed; a score is not.** Show progress toward the next celebration as
filling dots or stars — never a number, never decreasing, never something to miss.

---

## 4. Kids store and privacy rules

Built to clear **Apple Kids Category**, **Google Play Families**, and **COPPA**.

- **No ads. No tracking. No analytics. No crash reporting.** No third-party SDK that collects data.
- **No collection of personal data.** Nothing asked for, nothing sent. The only persisted state is
  game progress and sound settings, in local `shared_preferences`.
- **No Firebase, no IAP, no games services, no leaderboards, no social features.**
- **A parental gate** protects the settings screen and any external link or purchase: hold a button
  for ~3 seconds, or a simple adult arithmetic question shown **as text**.
  - The gate is the **one place text is required** — it is the barrier. Do not "fix" it by adding
    icons.

Before any release, grep for network and SDK usage. Nothing should reference `http`, `dio`, a
socket, or any analytics package.

---

## 5. Code structure

See [`docs/FILE-LAYOUT.md`](docs/FILE-LAYOUT.md) for the full layout.

```
lib/
├── games/<game_name>/   ← one self-contained folder per mini-game
├── shared/              ← celebration, sounds, home button, parental gate, Rive character
├── menu/                ← the picture home screen
└── audio/ settings/ player_progress/ app_lifecycle/ style/   ← from the template
```

- **A game owns its folder.** Shared needs move to `lib/shared/`; games never import each other.
- **`shared/` never imports from `games/`.**
- **Asset paths live in one place per game** (`assets.dart`), never inline string literals — so
  placeholder art becomes real art in a one-file edit.
- **Placeholder art is simple coloured shapes** until real artwork arrives.
- Keep it **simple and readable**. Short comments explaining non-obvious parts.
- **Comment the kid-rule and policy constraints where they are implemented**, or a future session
  will tidy them away.

---

## 6. Working method

- **Small steps, each one runnable.** The maintainer is learning Flutter; four small visible
  changes beat one big invisible one.
- **Test it in the same session.** `flutter analyze` clean, `flutter test` passing — then actually
  run it. Feel, target size, and sound are only proven under a thumb.
- **Say what was not verified.** If iOS or a device run could not be reached, name it; never let a
  green test suite silently stand in for a device run.
- **Docs are part of the task.** See [`docs/ABOUT-DOCS.md`](docs/ABOUT-DOCS.md) — a session that
  changed code and wrote no session doc is incomplete. Update
  [`docs/STATUS.md`](docs/STATUS.md) at the end.

### The kid-rules check, before calling anything done

- [ ] Could a child who cannot read do this?
- [ ] Every touch target ≥ 80×80, with space around it?
- [ ] Any way to lose, fail, run out of time, or get stuck?
- [ ] Home button visible?
- [ ] Any new network call, SDK, or stored personal data?
