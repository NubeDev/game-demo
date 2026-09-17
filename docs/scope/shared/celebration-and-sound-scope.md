# Shared — celebration, sound, home button, Rive character (scope)

- Date: 2026-09-17
- Status: shipped
- Session: [../../sessions/shared/kid-shell-and-first-game-session.md](../../sessions/shared/kid-shell-and-first-game-session.md)

## Why

Four pieces every mini-game needs, built once in `lib/shared/` so game number four is mostly
assembly rather than reinvention — and so the *feel* is consistent. A child should learn what a
celebration means in one game and recognise it in the next.

The reward loop is doing the heaviest lifting in this app. With no score, no winning and no
losing, the celebration **is** the reason to keep playing.

## What

Four pieces, each usable on its own:

- **A reward/celebration effect** — confetti or stars bursting, with a bouncy motion curve. One
  API call from a game (`Celebration.play(...)`), tuned to feel generous but not to obscure the
  play area for long.
- **A sound helper** — a thin wrapper over the template's `AudioController` giving games named
  cues (`pop`, `success`, `wobble`, `tap`) instead of raw asset paths, honouring the mute setting.
- **A home button** — one component, identical in every game: big, always in the same corner,
  obvious icon, no confirm dialog (a child cannot read one).
- **A Rive character component** — a Flame component wrapping a Rive artboard, driven through
  **data binding** (`ViewModelInstance`) so a game can say `character.celebrate()` without knowing
  anything about Rive.

### The Rive API rule

`rive` 0.14 replaced its Flutter API wholesale. This component must use the **new** one:

- load with `File.asset(...)`
- get the state machine via `artboard.defaultStateMachine()`
- drive animation through **data binding** — `ViewModelInstance` properties

and must **not** use the deprecated `StateMachineController`, `SMIInput`, `RiveFile.asset`, or
state-machine inputs. Reference: the official
[`flame_rive` example](https://github.com/flame-engine/flame/tree/main/packages/flame_rive/example)
and [the flame_rive docs](https://docs.flame-engine.org/latest/bridge_packages/flame_rive/rive.html).

Development uses `rewards.riv` from that example until real art exists. Part of the deliverable is
**documenting what view-model properties a custom `.riv` must expose** so replacement art is a
drop-in.

## Not this

- No haptics for now — inconsistent across devices and easy to overdo.
- No music layer in this scope; the template's music handling stays as-is.
- No generic "effects framework". Four concrete pieces, extracted further only when a third game
  actually needs it.
- No confirm-on-exit. Leaving a game is free and instant.

## Kid-rules impact

- **Celebration must not be startling** — no sudden loud sting, no strobing. Bright and bouncy,
  not explosive. This is the rule most easily broken while making something feel exciting.
- **No flashing.** Confetti at a rate that could read as strobe is a photosensitivity risk;
  keep motion smooth and frequency low.
- **The home button must not be reachable by accident mid-play** but must be instantly findable.
  Same corner in every game, away from the main action.
- **The Rive character must never look sad, cross or disappointed**, even on a wrong answer — a
  character's reaction to a mistake is exactly where punishment sneaks back in. Its "wrong"
  animation is encouraging, not disapproving.

## Open questions

- [x] Interrupt or overlay? **Overlay**, with spawning paused 1.8s so the burst is what you see.
      No dialog to dismiss.
- [x] Particles or Rive confetti? **Flame components** (`RectangleComponent` + effects) — easy to
      tune, and independent of whether the character's art has landed.
- [x] Which view-model properties? **Two triggers + one number**: `Celebrate`, `Encourage`,
      `Excitement` (0-1). Documented for a custom file in
      [`../../../lib/games/balloon_pop/README.md`](../../../lib/games/balloon_pop/README.md).
- [ ] Sound cue set: four cues (`pop`, `celebrate`, `wobble`, `tap`) is enough for one game —
      revisit at game three.
- [ ] **The cues are still the template's arcade sfx.** They need replacing with soft, friendly
      audio; a realistic balloon bang would startle a five-year-old.

## Done when

Balloon Pop uses all four pieces, a second game could use them without changes, and the document
of required Rive view-model properties is complete enough that a custom `.riv` can replace
`rewards.riv` without touching Dart.
