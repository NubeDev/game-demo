# Shared — kid shell, and the first game (session)

- Date: 2026-09-17
- Scopes: [home-screen](../../scope/shared/home-screen-scope.md),
  [parental-gate](../../scope/shared/parental-gate-scope.md),
  [celebration-and-sound](../../scope/shared/celebration-and-sound-scope.md),
  [balloon-pop](../../scope/games/balloon-pop-scope.md)
- Status: done

Covers build steps 2-5: `CLAUDE.md`, the kid-friendly home screen, Balloon Pop, and the Rive
character. The game-specific detail is in
[`../games/balloon-pop-session.md`](../games/balloon-pop-session.md).

## Goal

Turn the renamed template into something a five-year-old could actually be handed: a picture menu,
one playable game, the shared pieces underneath, and the rules written down so future sessions
follow them.

## What changed

**`CLAUDE.md`** at the repo root — stack, the Rive 0.14 API rules with the exact call sequence,
design rules with the *why* for each, kids-policy rules, code structure, and a kid-rules checklist.

**Shared pieces**, all under `lib/shared/` with a [README](../../../lib/shared/README.md):
`kid_palette.dart`, `kid_sounds.dart`, `home_button.dart`, `parental_gate.dart`,
`celebration.dart`, `rive_character.dart`.

**The menu** — `lib/menu/home_screen.dart` + `game_tile.dart`. Three 168×168 picture tiles, no text
at all, muted "coming soon" tiles that wobble instead of navigating, and a small grey settings cog
behind the gate.

**Balloon Pop** — `lib/games/balloon_pop/`. See the game session doc.

**Template code removed**: `lib/flame_game/` (the endless runner), `lib/level_selection/`,
`lib/main_menu/`, `lib/style/` (palette, wobbly button, page transition, responsive screen), and
`lib/settings/custom_name_dialog.dart`.

**Settings screen rewritten** as a plain adult screen — and the template's **player-name field was
deleted**: a name is personal data, and this app collects none (CLAUDE.md §4). Added a short
plain-English note about what the app doesn't collect.

**`main.dart`** — added `RiveNative.init()`, explicit `SystemChrome.setPreferredOrientations` for
landscape, and dropped the template's `nes_ui` 8-bit theme and pixel font (arcade edges are wrong
for this audience, and the font is near-illegible for an adult reading the parent area).

## Decisions & alternatives

**Kept the template's `AudioController` rather than writing a sound layer.** It already handles
polyphony, preloading, app-lifecycle pausing and the mute settings. `KidSounds` is a thin naming
layer over it, so games ask for `pop()` rather than an asset path — swapping the real audio later
is a one-file change.

**Confetti as Flame components, not Rive.** Rive confetti would look better but couples the reward
loop to art that doesn't exist yet. `RectangleComponent` + effects is tunable now and can be
swapped later.

**Hold-to-open gate over an arithmetic question.** Friendlier for an adult, and no localisation
story. Noted in the scope that a child copying a parent is the failure mode to watch for — only a
real child can settle that.

**The gate's text is deliberate and commented as such.** The obvious "improvement" is to replace
the written instruction with icons, which would defeat the entire mechanism. That warning is in the
code, the shared README, and CLAUDE.md.

**Property names for the Rive character are data, not literals.** `RiveCharacterProperties` holds
them, so a custom `.riv` is a drop-in with no Dart change.

**`RiveCharacter` fails soft.** Missing file, state machine, view model or named property each log
and continue. A character that fails to load must never stop a child playing.

## Tests

`flutter analyze`:

```
Analyzing game-demo...
No issues found! (ran in 3.2s)
```

`flutter test` — 10 tests, including the two policy-critical ones:

```
00:00 +0: Balloon floats upward
00:00 +1: Balloon reports a pop exactly once, even when mashed
00:00 +2: Balloon has a touch target larger than the drawn balloon
00:00 +3: ProgressStars never goes below zero or above the total
00:00 +4: Celebration burst adds confetti, and it clears itself up
00:00 +5: home screen shows a picture button per game and no child-facing text
00:00 +6: home screen game tiles are far bigger than the 80x80 minimum
00:00 +7: parental gate settings are unreachable without completing the hold
00:00 +8: parental gate a full 3-second hold opens it
00:00 +9: home button is at least 80x80
00:00 +10: All tests passed!
```

`flutter build apk --debug` → `✓ Built build/app/outputs/flutter-apk/app-debug.apk`.

**Run and driven in a browser.** No macOS/iOS toolchain and no attached device on this machine, so
the app was served (`flutter run -d web-server`) and driven with headless Chrome: the menu renders,
tapping the first tile enters Balloon Pop, balloons rise and pop, the progress dots fill, and the
counter resets — so celebrations fired. **No Dart errors** across several hundred synthetic taps.

Screenshots also caught two things tests could not, both fixed: the unfilled progress dots were
translucent white and nearly invisible against the pale sky (now an ink wash), and the Rive
placeholder was rendering at 220×220 in the play area (now 150×150, cornered).

### Not verified

- **iOS and macOS** — no Apple toolchain here.
- **Anything about feel**: whether balloons are too fast or too sparse, whether the sounds are
  right, whether a child understands the menu. Browser screenshots prove it is *not obviously
  wrong*; they prove nothing about play. This needs a tablet and a child.
- **Landscape lock** — set in `main.dart`, but the native manifest declarations are not done yet
  (see [the setup scope](../../scope/setup/landscape-and-platform-config-scope.md)).

## Kid-rules check

- [x] Playable with no reading — menu has zero `Text` widgets (asserted in a test); the game needs
      none.
- [x] Touch targets ≥ 80×80 — tiles 168, home button 96, balloon hit area ~120. Three tests assert
      the minimum.
- [x] No failure state — no timer, no miss counter, no game over. Escaping balloons are silent
      non-events; progress only rises.
- [x] Home button present — top-right of the game, 96×96, no confirm dialog.
- [x] No network calls — nothing added. `rive_native` downloads native artifacts at *build* time;
      the shipped app makes no calls.

## Debugging

No entries — nothing survived the session. Three issues were caught and fixed inline:

- `Factory` is exported by both `flutter/foundation.dart` and Rive; `rive_character.dart` imports
  foundation with `hide Factory`. Worth knowing, as anyone using Rive will hit it.
- The first "coming soon" wobble used unreadable arithmetic that would not have produced a clean
  shake; replaced with `sin(t * pi * 6) * 10 * (1 - t)`.
- A `pkill -f "flutter run"` killed the session's own shell process group. Used `setsid` after.

## Scope updates

Four scopes moved to **shipped** with their open questions resolved in place. What remains open is
recorded there — most of it genuinely needs a real child (spawn tuning, whether an icon reads as
"a game", whether silence on a missed tap feels broken), plus replacing the arcade sound effects.

## Follow-ups

- Lock landscape in the native manifests; remove `web/`, `windows/`, `linux/`.
- Replace the template's arcade sfx with soft kid-friendly audio.
- Prune unused template assets (Dash sprites, arcade music, `nes_ui` dep).
- Real art, and a real `.riv` character — spec in
  [`lib/games/balloon_pop/README.md`](../../../lib/games/balloon_pop/README.md).
- [`../../STATUS.md`](../../STATUS.md) updated.
