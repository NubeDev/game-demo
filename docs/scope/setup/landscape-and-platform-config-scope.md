# Setup — landscape lock and platform config (scope)

- Date: 2026-09-17
- Status: proposed
- Session: —

## Why

The app is designed for a tablet held sideways in two hands. If the device is allowed to rotate,
every layout has to work twice and a child tilting the tablet mid-play gets the whole screen
rearranged under their fingers — which reads as the game breaking. Locking orientation removes a
whole class of layout bugs and a whole class of confusion.

The other platform settings (icon, launch screen, and which targets we even build) are the
housekeeping that makes the app look like a real app rather than a template.

## What

- **Lock to landscape** on both platforms: `SystemChrome.setPreferredOrientations` in
  `main.dart`, plus the native declarations so the OS never offers portrait —
  `android:screenOrientation` in the manifest, `UISupportedInterfaceOrientations` in `Info.plist`
  (including the `~ipad` variant).
- Both landscape directions (left and right) allowed, so it doesn't matter which way the child
  picks the tablet up.
- Replace the template's app icon and launch screen with Little Games artwork (placeholder until
  real art exists).
- Remove the platform folders we do not ship: `web/`, `windows/`, `linux/`. Keep `macos/` — it is
  the development run target.

## Not this

- No portrait layout, now or later.
- No tablet-vs-phone split layouts. One landscape layout that scales.
- No app-store metadata, screenshots or listing work — that is a release task, not this.

## Kid-rules impact

- The launch screen is the first thing on screen and must be **calm** — no loud splash, no
  animation that could be mistaken for the game having started.
- Removing rotation is itself a kid rule in disguise: predictability. The screen should never
  change shape while they are playing.

## Open questions

- [ ] Does removing `web/` break the template's smoke tests or any tooling that assumes it?
      Verify before deleting.
- [ ] Icon artwork — placeholder, or wait for the real thing? A placeholder icon that ships by
      accident is worse than an obviously-temporary one.

## Done when

The app launches in landscape on an Android device and an iOS simulator, refuses to rotate to
portrait, shows the Little Games icon on the home screen, and the repo contains only the platform
folders we actually target.
