# Car Trip

A car drives itself down a road. The child puts a thumb on the bottom half of the screen and the
car goes there. Animals waiting at the kerb hop in as the car pulls alongside, and when the car is
full the road arrives somewhere — a farm, a beach, a park, a snowy village — and a new road starts.

Scope: [`docs/scope/games/car-trip-scope.md`](../../../docs/scope/games/car-trip-scope.md).
Session: [`docs/sessions/games/car-trip-session.md`](../../../docs/sessions/games/car-trip-session.md).

## Why it is built this way

### It is the first game in the app that the child **steers**

Balloon Pop is where to tap, Dress the Dog is which to pick, Cat Run is when to press, Blast Off is
how long to wait. None of them asks for a held, continuous input. Holding a line with a thumb is
the motion that later becomes drawing and handwriting, and at five it is worth practising.

That also makes it **the first thing in this app a child can genuinely be bad at**, which CLAUDE.md
§3 forbids. Everything below is how that is resolved.

### The road is wide and the verge is drivable

`driveableLateral` is 1.45 — half as much grass again beyond the tarmac, and driving on it is
bumpy and slightly slower and nothing else. There is no edge to fall off, no way to leave the
world, and no state the car can get into that is worse than any other. **A child who holds their
thumb still in the middle drives the whole road safely, forever.**

### Picking someone up asks for as little aim as possible

A waiting passenger **walks down to the kerb itself** when it sees the car coming
(`CarTripGame._moveCreatures`), so collecting one is a lean of the thumb rather than a piece of
aim. `test/car_trip_test.dart` pins how small that lean is: if the number ever grows, the game has
quietly started demanding precision a five-year-old does not have.

### Nothing alive can be hit — at all

Not "rarely", not "gently": there is **no branch in `car_trip_game.dart` that lets a living thing
be collided with**. Ducks and hedgehogs notice the car and move aside faster than the car can
steer, and wander off into the field if they are chased. Only cones, balls, bales and bins bounce.

Driving into an animal is funny in a game and appalling in life, and a five-year-old does not hold
those apart. This is the one rule here that is about the world outside the app.

### Clipping a cone costs nothing

The same trick Cat Run plays with its fences: keep the obstacle, delete the loss. A clip is a
wobble, a soft parp and a comedy tumble into the grass. No damage, no stop, no progress removed,
and **no haptic** — a physical jolt after a mistake is punishment, however small.

### The hit test must not depend on the frame rate

`_interact` widens its depth window by however far the car moved that frame. That is not
defensive tidiness — without it, a device drawing at 2fps moves the car further between frames than
the whole window is wide, and **passengers the child correctly steered to are silently missed**.
Found by running it on a software-rendered emulator; a green test suite had no opinion about it.

A five-year-old's device is a hand-me-down. Anywhere in this app that asks "did the child hit it"
from an instantaneous position has the same bug waiting.

### Nothing grows big enough to blind the child

`Perspective.scaleAt` clamps at `-focal * 0.15`, capping how big anything is ever drawn at about
1.2×. The clamp was 0.55 (a 2.2× cap), which let the rainbow arch draw wider than the screen as the
car went under it — sky, horizon and road all gone behind a wall of pink. That is a startle
(CLAUDE.md §3) and it hides the road being steered on.

The arch and the car wash are 2.0 road units wide **on purpose**, so they cannot be missed. If one
of them ever looks too big again, the number to change is the clamp, not their width.

### Two coordinates, and neither is in pixels

`road.dart` works in **lateral** (0 is the centre line, ±1 is the tarmac edge) and **depth** (world
pixels ahead of the car). Every rule in the game — how wide a cone is, how close counts as pulling
alongside, how far out the grass goes — is written in those units, so it means the same thing on a
phone and on a tablet. Only the *drawing* knows about pixels, through `Perspective`.

### The camera is not Cat Run's

The road runs away from the viewer to a horizon, with a textbook `focal / (focal + depth)`
projection. Side-on would have made the two games look like the same game with different art, and
top-down loses the "going somewhere" that the whole trip is built on.

### The horn does nothing

It is not a control. It beeps, everything in the fields waves back, and the trip is untouched. A
five-year-old will press it far more than they steer, and that is a perfectly good way to play.

## The files

| File | What is in it |
|---|---|
| `road.dart` | The data list of things on the road, the destinations, and the projection maths. Pure — no Flame, no canvas. |
| `world.dart` | The spawner: what is up the road and where. Pure, so the fairness rules are testable without a game. |
| `car_trip_game.dart` | The Flame game: steering, interactions, arriving. |
| `car_trip_screen.dart` | The screen: the steering area, the horn, the home button. |
| `components/road_view.dart` | Sky, fields, tarmac, verges, the dashes that sell the speed. Scenery only. |
| `components/traffic.dart` | Every thing on the road, drawn back to front. |
| `components/car.dart` | The car, and its steering physics. |
| `components/progress_dots.dart` | How full the car is. A count, never a score. |
| `components/horn_button.dart` | The horn. |
| `assets.dart` | Where real artwork lands when it arrives. |

## Placeholder art

Everything is drawn in code. When real art arrives it goes through `assets.dart` and nothing else
changes — but the sizes in `road.dart` are in road units and the reaches are deliberately *not* the
same numbers as the art, so a sprite that changes the drawn size without changing `drawWidth` will
change how generous the game is. See the comment there before swapping anything.

## Known gaps

- **The road does not literally bend into the destination** the way the scope describes; arriving
  is a cross-fade to the new place plus the confetti. The scope's open question about how a trip
  should end is still open.
- **No Rive character.** A shape-drawn car does everything this game needs so far.
- The progress row is this app's **third** hand-written copy of the same idea (Balloon Pop's stars,
  Cat Run's fish, these dots). Three is the point at which it should move to `lib/shared/`.
