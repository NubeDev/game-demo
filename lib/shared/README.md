# Shared pieces

Built once, used by every game, so game number four is mostly assembly — and so the *feel* is
consistent. A child should learn what a celebration means in one game and recognise it in the next.

| File | What it is |
|---|---|
| `kid_palette.dart` | The colour vocabulary |
| `kid_shapes.dart` | Shapes drawn in more than one place — the star, the cloud |
| `kid_sounds.dart` | Named cues (`pop`, `celebrate`, `wobble`, `tap`) over the template's `AudioController` |
| `kid_haptics.dart` | The small physical answer to a success. Never to a mistake |
| `home_button.dart` | The one way out of any game |
| `parental_gate.dart` | The 3-second hold protecting the parent area |
| `celebration.dart` | Confetti — the reward loop |
| `rive_character.dart` | A Rive artboard driven by data binding |

**`shared/` never imports from `games/`.** If a shared piece needs to know about a specific game,
the dependency is backwards — pass it in.

## Decisions worth knowing

### `kid_sounds.dart` — games ask for a feeling, not a file

A game calls `sounds.pop()`, not an asset path, so swapping audio later is a one-file change.
Everything routes through `AudioController`, which already honours the mute setting, so no game has
to check whether sound is on.

The cues are synthesised placeholders from [`tools/make_sfx.py`](../../tools/make_sfx.py) — a soft
rising "boop" rather than a realistic balloon *bang*, which would startle a five-year-old and fires
many times a minute. Real recordings drop into `assets/sfx/` under the same names, with no Dart
change.

**`pop(progress:)` climbs a ladder.** The `kid_pop*` samples are ascending notes, and `pop` picks
the rung from how full the current set is rather than at random — so the cue rises as the child gets
closer and the celebration lands as the resolution of a phrase. This is the only progress signal a
child who cannot read a number can *hear*, and it matters: it works with the sound on and the screen
barely looked at. Nothing assumes how many rungs there are, so a deeper ladder is purely a matter of
generating more samples.

### `parental_gate.dart` — the text is the barrier

Everywhere else in this app text is forbidden because the player cannot read. Here that is exactly
the point: a five-year-old cannot follow a written instruction, and cannot sustain a deliberate
3-second hold on a target they don't understand. **Do not "improve" this screen by replacing the
instructions with icons.**

Route every protected destination through `ParentalGate.guard()` so a future screen cannot
accidentally skip it. `router.dart` is where you check that: `/settings` is only ever reached from
a `guard` call.

Chosen over a PIN (state to store and forget), a date-of-birth question (that *is* personal data),
and arithmetic (needs localising). It is not security against a determined older child — it is a
deliberate-action check, which is what the store programmes actually require.

### `kid_haptics.dart` — success only, and always optional

A five-year-old's finger is ahead of their eye: a pop they can *feel* lands even while they are
already looking at the next balloon. Three rules are load-bearing:

- **Light end of the scale only.** A heavy buzz startles; a long one reads as an alarm.
- **Never after a mistake.** There is no haptic on the wobble cue. A physical jolt following a wrong
  tap is punishment, however small, and CLAUDE.md §3 has no room for it.
- **Never depended on.** Every call is fire-and-forget and swallows failure, so desktop, the
  simulator and tablets with no vibrator simply do nothing.

### `home_button.dart` — no confirmation dialog

A child cannot read "Are you sure?", and leaving costs nothing because there is no score to lose.
Same corner in every game (top-right), 96×96, so it is learned once and never needs aim.

### `celebration.dart` — generous but never startling

With no score and no winning, this is the *only* thing that says "you did it". So it is deliberately
big — but pieces fall over 1.6–2.8s with a small stagger, tumble slowly, and fade out. A fast flash
of confetti would be a photosensitivity risk and would read as frantic rather than joyful.

A quarter of the pieces rise from the bottom instead of falling. Confetti that all moves one way
reads as weather; a few pieces going the other way reads as something bubbling over.

`puff(position)` is the small sibling — a local shower at one point, used for the rare sparkly
balloon. Deliberately about a fifth the size of a `burst`: if a single lucky balloon got a full
celebration, the every-ten-pops celebration would stop meaning anything.

Pieces remove themselves when their fade finishes, so repeated celebrations can't accumulate.
There's a regression test for that in `test/balloon_pop_test.dart`.

### `kid_shapes.dart` — a star that is actually a star

Placeholder art is "simple coloured shapes" (CLAUDE.md §5), and the progress stars were circles
because a circle is one call. But a five-year-old is *learning shapes*: a star that is a dot teaches
them nothing and reads as a full stop. These are the real outlines, so the placeholder stage still
looks like what it means.

### `rive_character.dart` — the 0.14 API, and failing softly

Uses the **new** Rive API throughout (`File.asset` with a `riveFactory`, `defaultStateMachine()`,
`bindViewModelInstance`). The deprecated `StateMachineController` / `SMIInput` path is gone from
Rive 0.14 — see CLAUDE.md §2 before touching this file, because most examples online still show it.

Two things worth knowing if you're extending it:

- **`Factory` is ambiguous.** Flutter's `foundation.dart` and Rive both export a `Factory`. This
  file imports `foundation` with `hide Factory`.
- **`RiveNative.init()` must run before any file loads.** It's called once in `main()`.
- **Nothing uses this component right now.** No game instantiates it and no `.riv` ships — the
  Balloon Pop stand-in was removed because it was a rewards screen, not a character. The file stays
  because the drop-in path is the whole point of it.

The component **degrades gracefully**: missing file, missing state machine, missing view model, or
a missing named property each log and do nothing. A character that fails to load must never take a
game down — the child should still be able to play.

Property names are passed in as `RiveCharacterProperties` rather than hard-coded, so a custom `.riv`
is a drop-in. See `lib/games/balloon_pop/README.md` for what a file must expose.
