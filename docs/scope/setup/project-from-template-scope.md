# Setup — project from the Casual Games Toolkit template (scope)

- Date: 2026-09-17
- Status: shipped
- Session: [../../sessions/setup/project-from-template-session.md](../../sessions/setup/project-from-template-session.md)

## Why

We need a working app skeleton before any game can be built. Writing one from `flutter create`
means hand-rolling routing, settings persistence, audio management and app-lifecycle handling —
all of which the official Flutter **Casual Games Toolkit** already solves, and solves in the way
the Flutter team recommends. Starting there means the parts we are not interested in are already
right, and we spend our time on the games.

`endless_runner` is the template to take because it is the Flame-based one: it wires Flame into
the Flutter widget tree, which is exactly the integration we would otherwise have to work out.

## What

- Take `templates/endless_runner` from <https://github.com/flutter/games>.
- Keep its skeleton: `main.dart`, `router.dart`, `settings/`, `audio/`, `player_progress/`,
  `app_lifecycle/`, `style/`.
- Rename the app to **Little Games**, package/bundle id **`com.example.littlegames`**, on every
  platform (Dart, Gradle, Android manifest, Xcode project, Info.plist, macOS xcconfig).
- Remove anything for ads, analytics, crash reporting, games services, in-app purchases, or
  Firebase.
- Add `rive` and `flame_rive` at their current versions via `flutter pub add`.
- Confirm it analyzes clean, tests pass, and produces a real build.

## Not this

- **No gameplay changes yet.** The endless-runner game itself stays in place this step, so the app
  still runs end-to-end; it is replaced in the Balloon Pop step.
- **No home-screen redesign yet** — that is [`../shared/home-screen-scope.md`](../shared/home-screen-scope.md).
- **No orientation lock yet** — that is
  [`landscape-and-platform-config-scope.md`](landscape-and-platform-config-scope.md).

## Kid-rules impact

None yet — this step deliberately leaves the template's own game, score and win dialog in place so
there is something runnable. **Those violate the rules** (it has a losing state and a win dialog)
and are removed in the following steps. Nothing shipped from this step is meant to be seen by a
child.

## Open questions

- [x] Does the current template still carry Firebase/ads/analytics integrations that need removing?
      **No.** Resolved in session: a grep across the template for `firebase|crashlytics|admob|
      google_mobile_ads|analytics|in_app_purchase|games_services|sentry` returned zero hits. The
      toolkit has stripped them since the older versions that had them behind flags. Nothing to
      remove.
- [x] Which Rive version resolves? **0.14.11**, with `rive_native` 0.1.11 — the new API, as
      required.
- [ ] The template's `nes_ui` dependency gives an 8-bit "NES" look that is wrong for this audience
      (hard pixel edges, arcade framing). Keep it for the parent-facing settings screen, or drop it
      and style our own? Decide during the home-screen step.
- [ ] `assets/` still holds the template's Dash sprites, enemy art and arcade music. Prune once we
      know what the games need, so we don't ship megabytes of unused art.

## Done when

`flutter analyze` is clean, `flutter test` passes, and a real artifact builds for a shipping
platform — and the app's name and identifier say Little Games everywhere, with no trace of the
template's name in configuration.
