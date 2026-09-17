# Setup — project from template (session)

- Date: 2026-09-17
- Scope: [../../scope/setup/project-from-template-scope.md](../../scope/setup/project-from-template-scope.md)
- Status: done

## Goal

Step 1 of the build plan: stand the project up from the Casual Games Toolkit `endless_runner`
template, rename it to Little Games, remove ad/analytics/Firebase-style integrations, add Rive, and
confirm it builds and runs. Also set up this `docs/` tree and the scope.

## What changed

**Template imported.** Cloned <https://github.com/flutter/games> and copied
`templates/endless_runner` into the repo root, excluding `codelab_rebuild.yaml` (template
maintenance tooling, not part of an app). The repo previously held only an empty `README.md`,
which the template's own README replaced — nothing was lost.

**Renamed to Little Games / `com.example.littlegames`** across Dart, `pubspec.yaml`, Gradle
(`namespace`, `applicationId`), the Android manifest label, the Kotlin package directory
(`com/example/endless_runner/` → `com/example/littlegames/`), `Info.plist`, the Xcode project, and
the macOS xcconfig.

The Dart game class and file were renamed too, since the sed pass had already rewritten every
reference to them: `lib/flame_game/endless_runner.dart` → `lib/flame_game/little_games.dart`,
class `EndlessRunner` → `LittleGamesGame`.

**Rive added** via `flutter pub add rive flame_rive`, resolving to the versions in
[`../../STATUS.md`](../../STATUS.md).

**Docs tree created** — this file, [`../../ABOUT-DOCS.md`](../../ABOUT-DOCS.md),
[`../../SCOPE-WRITTING.md`](../../SCOPE-WRITTING.md), [`../../HOW-TO-CODE.md`](../../HOW-TO-CODE.md),
[`../../FILE-LAYOUT.md`](../../FILE-LAYOUT.md), [`../../STATUS.md`](../../STATUS.md), the scope set
under [`../../scope/`](../../scope/), and the `vision/`, `testing/`, `debugging/` skeletons.

## Decisions & alternatives

**Nothing needed removing.** The scope assumed ads/analytics/Firebase had to be stripped. A grep
across the template for `firebase|crashlytics|admob|google_mobile_ads|analytics|in_app_purchase|
games_services|sentry` — over Dart, YAML, Gradle, plists, manifests, Swift and Kotlin — returned
**zero hits**. The current toolkit template has already dropped them; older versions carried them
behind flags, which is where the assumption came from. Verified rather than assumed, because
"removed it" and "it was never there" leave the same result but different confidence.

**Kept the endless-runner gameplay for now** rather than deleting it in this step. It is the only
thing making the app runnable end-to-end, and it gets replaced in step 4 anyway. It does violate
the kid rules (it has a losing state and a win dialog) — noted in the scope, not shipped to a
child.

**Fixed a bad rename I introduced.** The blanket sed included an `endlessRunner` → `littleGames`
rule, which rewrote the iOS/macOS bundle identifiers to `com.example.littleGames` — camelCase, and
not the id you specified. Corrected to `com.example.littlegames` everywhere. Same pass left several
user-visible display names as the raw `little_games`; those are now `Little Games`
(`android:label`, `CFBundleDisplayName`, `CFBundleName`, `PRODUCT_NAME`).

**Adapted the docs convention rather than copying it.** The source `ABOUT-DOCS.md` is written for
the rubix-ai app, which has two backends and a hard "tested against a live node" rule. This app has
no backend at all — by policy, not by omission — so the `products/` axis and `WORKFLOW-LB.md` are
dropped, and the live-node rule becomes "tested on a real device or simulator". The three-stage
structure, the session-doc requirement, and the definition of done are kept as-is. Reasoning
recorded in [`../../ABOUT-DOCS.md`](../../ABOUT-DOCS.md) under "What is different here".

Added one section the parent convention doesn't have: a **kid-rules check** in the session
template, because the constraints that matter most in this app (no reading, no failure, target
size) are exactly the ones a passing test suite will not catch.

## Tests

`flutter analyze`:

```
Analyzing game-demo...
No issues found! (ran in 4.5s)
```

`flutter test`:

```
00:00 +0: loading /home/user/code/flutter/game-demo/test/smoke_test.dart
00:00 +0: smoke test menus
00:00 +1: smoke test flame game
00:00 +2: All tests passed!
```

`flutter build apk --debug` — the meaningful one, since it proves the Rive native runtime links:

```
[rive_native]   Initializing Rive Native for TargetPlatform.android.
[rive_native]   Downloading "android" libraries for version "0.1.11+3"
[rive_native]   Downloaded and unzipped "android" libraries for version "0.1.11+3"
[rive_native]   Setup complete. You can now use Rive Native in your project.
Running Gradle task 'assembleDebug'...                            139.8s
✓ Built build/app/outputs/flutter-apk/app-debug.apk
```

**Not verified from this session:** iOS and macOS builds, and any run under a finger. This machine
is Linux with no Apple toolchain, and no Android device or emulator is attached — the APK was
built, not launched. A Linux desktop build also fails, but for an unrelated reason: the host is
missing the `gstreamer-1.0` system library that `audioplayers_linux` needs. Linux is not a target,
so this is not being fixed.

**The user should run `flutter run -d macos` to confirm the app actually launches.** Until then,
"builds" is proven and "runs" is not.

## Kid-rules check

Not applicable to this step — no child-facing surface was designed. The template's own gameplay is
still in place and **does** break the rules (losing state, win dialog); it is scheduled for
replacement in step 4.

- [ ] Playable with no reading — n/a this step
- [ ] Touch targets ≥ 80×80 — n/a this step
- [ ] No failure state — **currently violated by the template's game**, replaced in step 4
- [ ] Home button — n/a this step
- [x] No network calls — verified: no HTTP/analytics/SDK dependency in `pubspec.yaml`. Note
      `rive_native` downloads native artifacts **at build time**; the shipped app makes no calls.

## Debugging

None — no issue survived the session. The bundle-identifier and display-name slips were caught and
fixed within the step, before anything depended on them.

## Scope updates

Closed in [the scope](../../scope/setup/project-from-template-scope.md):

- Integrations to remove → none existed.
- Rive version → 0.14.11 (new API), `rive_native` 0.1.11.

Still open there: whether to keep `nes_ui` (its 8-bit arcade look is wrong for this audience), and
pruning the template's unused Dash/arcade assets.

## Follow-ups

- Step 2: write `CLAUDE.md`.
- Lock landscape orientation —
  [scope](../../scope/setup/landscape-and-platform-config-scope.md).
- Remove `web/`, `windows/`, `linux/`; keep `macos/` as the dev target.
- Prune template assets once the games' needs are known.
- [`../../STATUS.md`](../../STATUS.md) updated.
