# Neil the Seal

An enormous, extremely relaxed elephant seal in a small Tasmanian seaside town.
Tap anywhere and he galumphs there. Whatever he lands on squashes, boings, and
springs straight back the moment he moves off.

Scope: [`docs/scope/games/neil-the-seal-scope.md`](../../../docs/scope/games/neil-the-seal-scope.md) ·
Session: [`docs/sessions/games/neil-the-seal-session.md`](../../../docs/sessions/games/neil-the-seal-session.md)

## The verb is new, and that is why this game exists

| Game | What the child is doing |
|---|---|
| Balloon Pop | where to tap |
| Dress the Dog | which to pick |
| Cat Run | when to press |
| Blast Off | how long to wait |
| Car Trip | holding a line |
| **Neil** | **choose a place, then watch what a big soft heavy thing does when it gets there** |

The child picks the destination; the comedy is the journey and the landing.

## Where things live

```
town.dart      pure data: the props, the five locations, the projection
world.dart     pure simulation: Neil, the squashing, the dots, the bellow round
components/    the drawing only — they decide nothing
```

`town.dart` and `world.dart` are **pure Dart** — no Flame, no canvas, no
widgets. Every rule that keeps this game kind is testable without standing up a
game, the same reason `car_trip/road.dart` and `cat_run/world.dart` are pure.
The components render what `world.dart` has already decided.

## The rules, and what enforces them

| Rule | Where it lives |
|---|---|
| **Every tap is answered.** No queueing, no refusing, no dead ground. A new tap replaces the old destination in the same frame | `NeilWorld.tapAt`, and the landing on bare ground is as good as any other (`_land`) |
| **Nothing alive is ever sat on.** Creatures move clear from a fifth of the town away, faster than his fastest heave | `NeilWorld._stepClear`, `clearRadius`, `clearSpeed`. There is no branch anywhere that squashes a `PropNature.alive` |
| **Nothing stays squashed.** Every prop springs back through an overshoot and is *exactly* at rest afterwards | `Prop.tick`, `springSettle` |
| **Nothing is ever lost.** A dot fills the first time he sits on a thing; sitting on it again is just as much fun and simply fills nothing | `_land`, and nothing in the art marks a prop as used |
| **He can never leave the town, or be clipped by it** | `minX`..`maxY`, set in from the edge by more than half his own length |
| **The game waits, and waiting looks like something** | `idleBeforeSleep`, then he dozes and snores until somebody comes back |

## Three decisions worth knowing about

**Creatures may leave the town; Neil may not.** `creatureMargin` lets anything
alive walk outside his walkable box. Without it there is a corner of every
location where a determined child could eventually pin a seagull against the
edge, and "nothing alive is ever squashed" becomes a hope rather than a
guarantee. A chased seagull lifts off and leaves, exactly as Car Trip's ducks
wander off into the field.

**The car's wheels are drawn outside the squash.** They stay where they are
while the body comes down onto them — a car *on its springs*, not a flattened
car. That is the single most important drawing in the game: the difference
between "an enormous seal is sitting on the car" and "the car is wrecked" is
entirely in what springs back, and a five-year-old can tell them apart.

**Neil is drawn lifted onto whatever he is sitting on.** Without it the seal
covers the car completely, and the signature move of the whole game happens
somewhere the child cannot see.

## Placeholder art, real rhythm

Everything is drawn in code. The *shapes* are placeholder; the **timing is
not** — the heave-flump lurch, the landing wobble, the springback overshoot and
the flipper kick are the game, and they are meant to be felt long before there
is artwork. `test/neil_the_seal_render_test.dart` renders Neil, every prop and
every location to PNGs so they can be looked at, because `flutter test` cannot
tell whether a squashed car reads as *bouncy* rather than *wrecked*.

Paths for real art go in [`assets.dart`](assets.dart), which is also where the
note lives about Neil being the obvious candidate for the shared Rive
character.

## What is deliberately not here

No car alarms, no sirens, no shouting, no cross neighbour — **nobody in this
town is ever annoyed that Neil is there**, and that is the rule this game will
be most tempted to break. Nothing breaks, nothing cracks, nothing stays bent.
No ranger, no truck, no relocation. No hunger, health or tiredness meter. No
score, no timer, no "you found them all".
