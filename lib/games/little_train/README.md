# Little Train

A toy steam train chuffs through a meadow, a forest, the seaside and the snow. Animals wait beside
the line, waving. **Tap anywhere and the train stops.** Stop beside a passenger and they hop straight
in. Three passengers fill the three wagons, then the train rolls into the station for a party,
everyone waves goodbye, and it's off to the next land.

Scope: [`docs/scope/games/little-train-scope.md`](../../../docs/scope/games/little-train-scope.md).
How the art, voice and music were made: [`docs/GENERATING-ASSETS.md`](../../../docs/GENERATING-ASSETS.md).

**The first game in this app with real artwork, a real voice and its own music**, all generated
ahead of time with Google's Gemini models. At runtime it is as offline as every other game.

## The one thing not to break

**Every passenger gets on.** The verb is *stop at the right place*, and a target can be missed.
So the outcome is taken out of the stop (see `Ride` in `ride.dart`):

| The child... | What happens |
|---|---|
| stops a wagon beside them (`perfectWindow`) | they hop straight in: "Hop on!", "Thank you!", a big sparkle |
| stops short (`walkWindow`) | they trot over and get in |
| sails past, or never taps at all | "Wait for me!", and they chase the train, **always faster than it** (`chaseExtra > 0`), and leap in |

A child who never taps still fills every wagon and reaches every station. Every way of standing
still has a timer out of it, so the train never gets stuck. Tests pin both promises, including
under a thousand random taps.

## Layout

```
ride.dart        the whole ride as plain numbers — pure, tested without Flame
lands.dart       the four lands: pictures, passengers, measured rail geometry
assets.dart      every path
little_train_game.dart     events → voice, sparkle, confetti, haptics
little_train_screen.dart   the whole screen is the brake (minus the home band)
components/      scenery (mirror-tiled sky and track, props, station),
                 passengers (two layers — see below), train (engine, wagons,
                 riders, steam)
```

## Things that look odd and are deliberate

- **`Passengers` is added twice**, before and after the train. Waiting passengers stand in front
  of the track. The first version had them behind it, and in a browser run the arriving train
  covered the very animal the child was stopping for. A leap in switches layer at its top, so the
  passenger ends up inside the wagon's sides.
- **The engine is drawn flipped.** It was generated facing left.
- **Sky and track are drawn mirrored on every other tile.** The generated pictures don't tile, but
  a mirror seam always matches.
- **`railLine` and `gauge` per land** were measured by eye. The model put the rails at a different
  height in each strip, and scaling every strip to the same gauge is what makes four tracks read as
  one railway.
- **`unit` shrinks on a 4:3 tablet** so the whole train still fits with line ahead of it. That
  leaves a lot of sky on a tablet, which is calm rather than empty.

## Not proven yet

Never run on a phone or tablet, and **no line of the voice or the music has been listened to by
this session**. You've played it yourself; the session doc lists what the automated runs covered.
