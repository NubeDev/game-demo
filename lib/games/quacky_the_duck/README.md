# Quacky the Duck

A grumpy park duck chases whoever has the bread. **Right side dashes, left side
ducks.** Catch up and they laugh and tip the bread out; every treat lifts his
eyebrows a notch and fills a bread roll. A full row is a celebration and the
park changes.

Scope: [`docs/scope/games/quacky-the-duck-scope.md`](../../../docs/scope/games/quacky-the-duck-scope.md).

## The one thing not to break

**The bread never gets away.** A chase is pressure-shaped — pursuit implies a
gap that can fail to close, which is a loss with a friendly face on it. The
whole game is legal under CLAUDE.md §3 only because the outcome is taken out of
the chase:

- the gap closes **on its own** at `QuackyWorld.drift`, every frame the park is
  moving, whether or not the dash button is ever discovered;
- dashing subtracts from the gap (`QuackyWorld.dashClose`) and nothing else — it
  buys *sooner*, never *otherwise-impossible*;
- a beak-bonk does not touch the gap at all. Whatever he is chasing waits.

`QuackyTheDuckGame.chaseGap` only ever decreases until a catch, and a test pins
that. **If a future change lets a target genuinely outrun the player, this game
has quietly grown a fail state.**

Two numbers are coupled to it and both are pinned by tests:

| Coupling | Why |
|---|---|
| `catchUpSeconds` < `idleTimeout` | Quacky sits down when nobody presses anything. If the gap takes longer to close than that, a child who only *watches* never eats — the promise is false in exactly the case it was written for. It shipped wrong once (9s against a 6s idle). |
| `caughtWithin` > half Quacky + half the widest target | The gap is centre-to-centre. At the first value the bodies overlapped by 53px and Quacky was drawn *inside* the child, which the scope rules out. No test saw it; the browser run did. |

## Layout

```
park.dart          the data: hazards, chase targets, moods, the four parks
world.dart         the spawner + the chase maths. Pure, so the safety rules are
                   testable without a running game
quacky_the_duck_game.dart    the loop, the collisions, the celebration
quacky_the_duck_screen.dart  the two hit areas + the home button
components/
  quacky.dart        the duck: dash, skid, huff, sit, and the mood face
  chase_target.dart  whoever has the bread. NOBODY HERE IS FRIGHTENED
  hazard.dart        benches to skid under, bins to bump
  park_view.dart     parallax scenery, cross-fading between parks
  progress_rolls.dart the bread-roll row
  play_buttons.dart  the two picture buttons — the only instructions there are
```

## Things learnt the hard way here

- **A duck hazard cleared cleanly produces no collision at all** — a flat duck
  passes *below* the hitbox. The chime therefore fires from `_checkPassed`, when
  the bench clears his beak, not from the collision check. Detecting it on
  despawn instead puts the sound seconds after the press that earned it.
- **Don't schedule game logic on a `TimerComponent`.** Spawning the next chase
  target is the core loop; a component timer makes it depend on Flame's async
  add/load lifecycle, which is invisible in production and silently dead in a
  synchronous test. `_respawnIn` and `_placingHeldFor` are plain countdowns for
  that reason — the first version shipped a chase that stopped after one catch.
- **`FlameGame.update` only forwards to `updateTree` when the game has no
  parent.** Under `FlameTester` it has one. Tests drive `update`, not
  `updateTree` — driving the tree directly runs the scenery and stops running
  the game.
- **Run it.** Four art bugs got through 544 passing tests and a set of still
  renders: tree canopies swallowing their own trunks, the target duck floating
  above the ground, a dog lead hanging from nothing, and the catch overlap
  above. None of them is visible except in motion, at size, in a browser.

## Placeholder art

All drawn in code. `test/quacky_the_duck_render_test.dart` writes every posture,
target, hazard and button to PNGs so they can be **looked at**:

```
flutter test --tags render --dart-define=SHOT_DIR=/tmp/quacky \
  test/quacky_the_duck_render_test.dart
```

The shots that matter most are the chase targets: **every one of them must read
as laughing.** A child who looks frightened is a bug in the game's premise, not
in its art.

Real artwork lands via [`assets.dart`](assets.dart) and nothing else changes.
`Mood.brightness` is already a 0..1 that a bound Rive `ViewModelInstanceNumber`
would take — this is the strongest candidate `lib/shared/rive_character.dart`
has had.
