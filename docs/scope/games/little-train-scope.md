# Games — Little Train (scope)

- Date: 2026-10-06
- Status: built: playable, **generated art, voice and music**. Played by the maintainer, and driven
  in Chrome over CDP
- Session: [../../sessions/games/little-train-session.md](../../sessions/games/little-train-session.md)
- Code: [`lib/games/little_train/`](../../../lib/games/little_train/) and its
  [README](../../../lib/games/little_train/README.md)

## Why

The ask: *use the Google API and make a whole new game, and push to see what can be generated:
characters, background images.* Two things in one. Game nine, and the first test of whether
generated art can replace the shapes-drawn-in-code placeholders that every other game still has.

The game was picked from three journey pitches (the maintainer prefers journeys to toys). It is a
toy train through four lands, picking up animal passengers. The verb is new: **stop at the right
place**. Balloon Pop is where to tap, Cat Run is when to press, Car Trip is steering, Crystal Party is
holding. Here it is *letting go of the throttle at the right moment*, which is the same skill as
stopping a ride-on toy beside a friend.

## Requirements

- A train that runs by itself. One tap anywhere brakes it, and one tap while stopped sets it off.
- Three animals per land, one per wagon. **A full train is the progress readout**, with no number.
- Each land ends at a station: celebration, the passengers hop off and wave, then the next land.
- Spoken lines for everything a child needs to understand: next stop, hop on, wait for me, we're here.
- Generated: characters (two poses each), wide backgrounds, track, props, stations, voice, music.

## Kid-rules impact

- **A stop is a target, and a target can be missed.** That is resolved in the design: every
  passenger gets on whatever the child does (see the README). Tapping well buys *sooner and
  sparklier*, never *whether*.
- No reading: the stop sign shows a paw print, and the voice lines carry the instructions.
- The whole screen below the home button's band is the control.
- Calm: one cruise speed, no difficulty ramp. The change between lands is a slow veil, never a flash.
- Offline: generation happens on a dev machine, and the app ships plain files.

## Open questions

- Do the voice lines sound right, and do they overlap badly when two events fire close together?
  (Not heard by the session that built it.)
- Is "tap anywhere to stop" discovered without being shown, or does the first stop need a hint?
- Is the 30-second music loop too short to stay pleasant across a long ride?
- Should the other games get generated art now? See [`GENERATING-ASSETS.md`](../../GENERATING-ASSETS.md).
