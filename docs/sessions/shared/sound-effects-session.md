# Shared — Sound effects (session)

- Date: 2026-09-18
- Scope: [../../scope/shared/celebration-and-sound-scope.md](../../scope/shared/celebration-and-sound-scope.md)
- Status: done
- Sibling: [../games/balloon-pop-session.md](../games/balloon-pop-session.md)

## Goal

Give the app real sound. The plumbing already existed — `KidSounds` routed through the template's
`AudioController`, and Balloon Pop already called `pop()`, `celebrate()` and `tap()` — but every cue
resolved to the template's **arcade sfx**, which the open threads in `STATUS.md` flagged as wrong
for this audience. Four things were missing: kid-appropriate audio, distinct cues per event,
a call site for `wobble()` in-game, and per-screen music.

## What changed

**New audio.** `assets/sfx/kid_{pop1,pop2,pop3,celebrate1,wobble1,tap1}.mp3`, synthesised by
[`tools/make_sfx.py`](../../../tools/make_sfx.py) and checked in. Pure sine tones with a soft
attack and gentle decay, tuned to a C-major pentatonic scale so overlapping cues stay consonant.

**`lib/audio/sounds.dart`** — four new `SfxType`s (`kidPop`, `kidCelebrate`, `kidWobble`, `kidTap`)
with per-cue volumes. The template types are kept but no longer used by any game.

**`lib/shared/kid_sounds.dart`** — the cues now point at the new audio; the stale `TODO(art)` is
gone.

**`lib/games/balloon_pop/balloon_pop_game.dart`** — the game now mixes in `TapCallbacks` and
answers a tap that landed on empty sky with the wobble cue, rate-limited to one per 0.45s.

**`lib/audio/songs.dart` / `audio_controller.dart`** — a named `Songs.play` / `Songs.menu` and a new
`AudioController.playSong`, so each screen chooses its track instead of shuffling arcade music
underneath whatever the child is doing. Music volume pinned to 0.25.

**Tests** — `test/sounds_test.dart` (7 new) and two empty-sky tap tests in `balloon_pop_test.dart`.

## Decisions & alternatives

**Synthesised placeholders, not downloaded audio.** Real recorded sound needs a human ear, and
nothing good was going to be sourced from here. Generating them means the app has audio that obeys
the kid rules *today*, the generator is readable and re-runnable, and the licensing is unambiguous —
these are ours, unlike the CC0 files already in `assets/sfx/`. They are honest placeholders, and
swapping in real recordings touches only the files, not a line of Dart.

**No bang for the pop.** A realistic balloon burst is a percussive transient — exactly the thing
that startles a five-year-old, and it would fire many times a minute. The pop is a gentle rising
"boop" instead. Three variants, so twenty pops don't sound like one sample on repeat. Verified:
zero energy above 4 kHz across every cue, nothing piercing.

**The mistake cue is the quietest thing in the app, the celebration the loudest.** Mixed
deliberately (`kidWobble` 0.3 < `kidPop` 0.55 < `kidCelebrate` 0.8) and locked in by a test, because
the ordering *is* the kid rule — never scold, and make the reward the biggest thing they hear.

**The empty-sky cue is not a miss cue.** This was the risky one. `STATUS.md` listed "whether silence
on a completely missed tap feels broken" as an open question, and the fix for that must not become
a failure signal by another name. So: no counter moves, no progress is lost, the sound is the
softest in the set, and it is rate-limited so drumming fingers get one calm response rather than a
stutter. It acknowledges the child; it does not judge the tap. **Still needs a child to settle** —
if it reads as "you missed", it should come out.

**A popped balloon must not also fire it.** Flame's `deliverAtPoint` stops at the first
`TapCallbacks` component and `Balloon` doesn't set `continuePropagation`, so the game never sees a
tap a balloon handled — no success-and-mistake chord. Checked against the Flame 1.38.2 source and
pinned by a test, since it depends on someone else's dispatch behaviour.

**Music per screen rather than a shuffled playlist.** `playSong` remembers the request even when
music is muted, so unmuting later lands on the right track instead of a random one.

## Surprises

**The first tap on empty sky was silent.** The rate-limit timer started at zero, so the opening tap
of a session was suppressed — the one tap that most needs an answer. The test caught it; the timer
now starts "ready".

**`BalloonPopGame` can't be loaded in a widget test.** `onLoad` builds the Rive character, which
needs `RiveNative.init()` from `main()`, so the game's `onLoad` never completes under
`flutter test`. The tap tests exercise the components and the shared interval constant instead of
booting the whole game. Worth knowing before the next attempt to test a game end to end.

## Verification

`flutter analyze` clean. `flutter test` — 19 passing (was 10). Every filename referenced in
`sounds.dart` confirmed present in `assets/sfx/`. Audio checked programmatically: no clipping,
clean zero-crossing edges (no clicks), consistent -3 dBFS peaks, and effectively no content above
4 kHz.

**Not verified: any of it under a thumb.** Nothing here has been heard on a device, or at all — the
audio was inspected numerically, not listened to, and no iOS, Android or macOS run was reached from
this session. Whether the pop is satisfying, whether the celebration feels like a reward, whether
the music is too present, and above all whether the empty-sky cue reads as friendly or as "you
missed" are all open until a real child plays it.
