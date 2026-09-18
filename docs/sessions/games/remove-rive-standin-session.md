# Games — remove the Rive stand-in from Balloon Pop (session)

- Date: 2026-09-18
- Scope: ../../scope/games/balloon-pop-scope.md
- Status: done

## Goal

The maintainer looked at the emulator and could not tell what the small dark rectangle in the
bottom-left of Balloon Pop was meant to be, and asked whether it should be removed or replaced.

It was the Rive stand-in. This session establishes what it was, removes it, and keeps the
data-binding plumbing intact for when real character art arrives.

## What it actually was

`assets/rive/rewards.riv`, copied from the
[official flame_rive example](https://github.com/flame-engine/flame/tree/main/packages/flame_rive/example).

It is **not a character**. It is a mock rewards *screen* — a treasure chest, coin and gem counters,
an energy bar — rendered into a 150×150 box in the corner of the play area. That is why it read as a
small dark phone lying in the grass.

It exposed no triggers, only nested view-model numbers, so the wiring was:

- `celebrate()` → fired nothing (no `Celebrate` trigger in the file)
- `encourage()` → fired nothing
- `setExcitement()` → drove `Coin/Item_Value`, 0–100 — an invisible coin counter climbing as the
  child popped balloons

So two of the three reactions were no-ops and the third was invisible. It was a **wire test** for
the Rive 0.14 data-binding path, never art, and the balloon_pop README already said so and flagged
it as "more obviously wrong now" after the hills landed.

## What changed

Removed from the game:

- [balloon_pop_game.dart](../../../lib/games/balloon_pop/balloon_pop_game.dart) — the
  `rive_character.dart` import, the `_character` field, the `RiveCharacter(...)` construction in
  `onLoad`, the three call sites (`setExcitement` on pop, `celebrate()` in `_celebrate()`,
  `setExcitement(0)` on resume), and the `balloonPopCharacterProperties` constant. A comment marks
  where the character went and why, so a future session does not re-add a stand-in.
- [assets.dart](../../../lib/games/balloon_pop/assets.dart) — `character` commented out with a
  `TODO(art)` pointing at the README. The `assets.dart` import in the game went with it, as the file
  now has no active members.
- `assets/rive/rewards.riv` — deleted (221 KB), and the now-empty `assets/rive/` entry removed from
  `pubspec.yaml`. Flutter errors on a declared asset directory that does not exist.

Kept, deliberately:

- [rive_character.dart](../../../lib/shared/rive_character.dart) — untouched. Graceful degradation,
  data binding, property names as data. This is the piece worth keeping; it makes real art a
  six-line drop-in.
- `RiveNative.init()` in [main.dart](../../../lib/main.dart) — comment expanded to say nothing loads
  a `.riv` yet and why it stays: a `.riv` added later without it fails at load with no obvious cause.

Docs:

- [balloon_pop/README.md](../../../lib/games/balloon_pop/README.md) — "Right now: a stand-in" became
  "Right now: there isn't one", recording what the stand-in was and why it went. The drop-in
  instructions now list the full restore (pubspec entry, assets path, properties constant, field,
  `onLoad`, three call sites), because more was removed than just the path.
- [lib/shared/README.md](../../../lib/shared/README.md) — notes the component is currently unused.
- [STATUS.md](../../STATUS.md) — milestone 5 moved from "done (stand-in art)" to "plumbing done, not
  wired"; the known-gaps row rewritten; the "what is proven" paragraph now says the data-binding path
  was proven with the stand-in and is unexercised until real art arrives.

## Decisions & alternatives

**Chose: remove the asset, keep the component.** The stand-in was actively harmful on screen — a
thing sitting in the play area that does nothing when touched reads to a five-year-old as the game
being broken (CLAUDE.md §3, and the game's own README makes this argument about the sun and clouds).
Nothing is better than a wrong thing.

**Rejected: a coded placeholder character** (a friendly shape drawn in code that bounces on
celebrate). It would match CLAUDE.md §5's "placeholder art is simple coloured shapes" and give the
corner a presence now. Not done because it was not asked for, and because a coded character is a
design decision about what the character *is* — better made once, with the real art, than twice.
It is the obvious next step if the corner should not stay empty; recorded as a follow-up.

**Rejected: leaving it until real art arrives.** That was the status quo, and the README had already
flagged it as wrong. Waiting only works if the art is imminent, and it is not.

**Rejected: removing `RiveNative.init()` too.** It costs nothing at startup and its absence is a
confusing failure mode later.

**Rejected: deleting `assets.dart`.** It has no active members now, but CLAUDE.md §5 makes
one-asset-file-per-game the convention, and the balloon sprite TODO still lives there.

## Tests

`flutter analyze` — clean:

```
Analyzing game-demo...
No issues found! (ran in 1.6s)
```

`flutter test` — all 38 pass:

```
00:00 +38: All tests passed!
```

No test changes were needed. The suite never covered the character: `BalloonPopGame.onLoad` requires
`RiveNative.init()` and so cannot run under `flutter test` at all — which is itself part of why the
stand-in's uselessness went unnoticed.

**Real-target run — Android emulator (`emulator-5554`, Pixel, Android 15 / API 35), debug build.**
Launched, entered Balloon Pop from the menu, tapped a bunch:

- The bottom-left corner is **clear sky and hills** — the dark rectangle is gone.
- The menu renders and the Balloon Pop tile enters the game.
- Balloons spawn, rise and **pop on tap**; the first star filled on the first pop; play continues.
- The home button is present, top-right.
- Frame pacing steady at ~60fps (`app_time_stats avg ~15ms`) across the session.
- **Zero errors or exceptions** in the run log, and no `RiveCharacter:` debug lines — nothing
  attempts to load a `.riv` any more.

**Not verified: iOS.** No macOS host is available from this machine, so neither the simulator nor a
device could be reached. The change is asset removal plus Dart-only edits, with no platform-specific
code touched, but the iOS build has not been run this session.

**Also not verified: sound.** The emulator run was screenshot-driven; nothing was listened to. This
is the same standing gap as previous sessions, not something this change introduced.

## Kid-rules check

- [x] Playable with no reading — unchanged; nothing removed was interactive or instructive
- [x] Touch targets ≥ 80×80 — unchanged; the removed component was not a touch target
- [x] No failure state, no punishing timer — unchanged
- [x] Home button present and obvious — unchanged
- [x] No network calls — unchanged; this session only removed an asset and its dependency

Worth noting the removal is a small *gain* against the first rule: the play area no longer contains
an inert object that a child would tap and get nothing from.

## Debugging

None — no defect was investigated. The stand-in behaved exactly as the code said it would; the
problem was that what it did was not worth doing.

## Scope updates

[balloon-pop-scope.md](../../scope/games/balloon-pop-scope.md) line 28 still reads "A **Rive
character** watches and reacts when balloons pop, via data binding." That remains the intent — it is
now an open item rather than a shipped one, and STATUS reflects that.

## Follow-ups

- **Decide what the character is.** The corner is empty. Either real `.riv` art, or a coded
  placeholder character in the CLAUDE.md §5 spirit. The README documents exactly what a `.riv` must
  expose (`Celebrate`, `Encourage`, `Excitement`) and the rule that it must never look sad or cross.
- The Rive data-binding path is now unexercised. When art lands, that load path needs a real-target
  run again — the last one that proved it used the file just deleted.
