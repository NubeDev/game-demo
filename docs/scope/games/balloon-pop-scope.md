# Games — Balloon Pop (scope)

- Date: 2026-09-17
- Status: shipped
- Session: [../../sessions/games/balloon-pop-session.md](../../sessions/games/balloon-pop-session.md)

## Why

The first mini-game, and the one that proves the whole design. Popping a balloon is the simplest
possible complete loop for a five-year-old: they already know what a balloon is, they already know
what tapping does, and the result — it bursts, it makes a noise — is immediate and obviously caused
by them.

It is also the right first build for us: it exercises every shared piece (sound, celebration, home
button, Rive character) with gameplay simple enough that if something feels wrong, the problem is
the shared piece, not the game.

## What

- Colourful balloons **float up from the bottom** of the screen at a gentle, varied pace, drifting
  slightly sideways so the motion isn't mechanical.
- **Tapping a balloon pops it**: a pop sound, a small burst effect, and the balloon is gone.
- Balloons that reach the top simply **drift off screen** — no penalty, nothing lost, no sound of
  failure.
- After **10 pops**, a celebration plays, then more balloons come. The loop never ends and never
  fails.
- Progress toward the 10 is shown as **filling dots or stars** — never a number.
- A **Rive character** watches and reacts when balloons pop, via data binding.
- The shared **home button** in a consistent corner.

Lives in `lib/games/balloon_pop/`. Placeholder art: flat coloured circles with a string, asset
paths collected in one file so real art is a drop-in swap.

## Not this

- **No timer.** Not even a friendly one.
- **No miss counter, no accuracy, no combo, no streak.** A balloon escaping is not an event.
- No levels, no speed ramp that outpaces the child, no difficulty selection. If pacing changes at
  all it is gentle and invisible.
- No special balloons, bonus balloons or bombs in the first version — get the core loop right first.
- No two-finger or gesture input. One tap, one balloon.

## Kid-rules impact

- **"After 10 pops" is a goal, and goals imply failure.** Resolved: the count only ever rises, it
  is never shown as a number, there is no time limit on reaching it, and escaping balloons don't
  subtract. It is a rhythm for celebrations, not a target to miss.
- **Balloons must be big and tappable well beyond their visual edge.** A balloon that looks tappable
  but isn't quite is the classic five-year-old frustration; make hit areas ≥ 80×80 and generous
  around the art.
- **Pop sound must be soft.** A realistic balloon bang is startling — this needs a friendly
  "boop", not a burst.
- **Spawn rate must not overwhelm.** Too many balloons at once reads as chaos; err sparse.
- Nothing chases the player, nothing scary rises from the bottom.

## Open questions

- [x] Tap-down or tap-up? **Down** — more forgiving for a finger that slides.
- [x] Celebration pauses or overlays? **Overlays**, spawning pauses 1.8s.
- [x] Should colour matter? Not yet, and nothing is designed out — balloons carry their colour, so
      a colour-naming cue can be added later.
- [ ] What happens if the child taps and misses entirely — silence, or a soft acknowledgement?
      **Shipped as silence.** Needs a real child to judge whether that feels broken.
- [ ] Spawn rate (1.4-2.4s) and rise speed (34-60 px/s) are guesses. **Needs tuning against a real
      child**, on a real tablet — the screenshot-driven tuning done so far only proves it is not
      obviously wrong.

## Done when

A child taps balloons, they pop with a happy sound, a celebration arrives every ten, play continues
indefinitely, there is no way to lose or get stuck, and they can leave to the menu whenever they
want.
