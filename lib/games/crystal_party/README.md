# Crystal Party

A unicorn gallops left to right at one gentle speed, forever. **Hold anywhere on the screen and she
rises on a rainbow; let go and she floats back down to a gallop.** That is the whole control scheme
— the entire screen is the button. Blue crystals live low, pink ones float high, so going up and
coming back down is the skill, and sorting by colour happens as a side effect of flying well.

Every crystal joins the trail streaming behind her and slots a piece into the half-built rainbow
arch on the horizon. Fill the arch and it blazes into the crystal party — then the next land.

It never ends, it cannot be lost, and **there is no state in which a child is one crystal short**.

| File | What it is |
|---|---|
| `crystal_party_game.dart` | The `FlameGame`: scrolling, collisions, the chime ladders, idle, the party |
| `crystal_party_screen.dart` | The Flutter screen: the whole-screen hold area, and the home button's band |
| `world.dart` | **What comes next, and where in the sky** — pure, seedable, and where the fairness rules and the quiet help live |
| `lands.dart` | The six places, as colours only. Scenery, never gates |
| `components/unicorn.dart` | **The flight model** — rise, float, land. No gravity anywhere |
| `components/crystal.dart` | A crystal: pointy blue shard or round pink blob |
| `components/prop.dart` | Pine, rocks, stone arch, washing line — things to rise over and drop under |
| `components/treat.dart` | Waterfall, cloud, butterflies, rainbow puddle — things that are lovely to fly through |
| `components/trail.dart` | The crystals streaming out behind her: progress, as a picture |
| `components/arch.dart` | The arch on the horizon: progress again, in front of her, and the party blaze |
| `components/sky.dart` | Sky, clouds, hills, ground, and the creatures that notice her |
| `assets.dart` | Every asset path, in one place |

## The one hard problem

**"Collect them all" is a completion goal, and completion invites being incomplete** — which is the
shape of failure CLAUDE.md §3 forbids. A child who reaches the end of a land three crystals short
has failed, however gently it is phrased.

It is resolved by making completion **guaranteed rather than earned**, in three places that all have
to stay true together:

1. **A missed crystal is not missed.** Fly past one and it twinkles and drifts, and the same colour
   is put back into the run ahead (`_recycle` / `_owed` in the game, drained by `_placeThings`).
2. **The land does not end until the arch is full.** There is no distance, no timer and no end of
   level — the only thing that finishes a land is the arch filling, so nobody can run out of
   anything.
3. **The quiet help.** A colour that falls behind starts appearing more often *and lower down*
   (`CrystalPartyWorld.helpingColour`). A child who never works out the hold still fills the pink
   side. **It is never announced**, and nothing on screen says it happened.

Together: the party is not something a child can fail to reach, only something that takes as long as
it takes.

## Flying implies falling, and this game has none of it

Flying is the oldest way a game has of killing you. Every piece of that machinery is deliberately
absent, and the numbers in `components/unicorn.dart` are what keep it absent:

| Rule | How |
|---|---|
| No falling | `fallSpeed` (165) is **slower** than `riseSpeed` (300). A descent that matched the climb reads as falling, and at five that reads as danger. This is a leaf coming down, not a stone |
| No ceiling to bump | The climb tapers to nothing over the top `_easeBand` of the sky, so the top is a **settle**, not a wall. With a hard clamp the child felt the game take the control away |
| No ground slam | Every landing is soft, on four hooves, from any height. `_land()` has no failure branch |
| No bottom of the screen | `airHeight` is never negative. There is never anything below her but ground or shallow water |
| No flight meter | Nothing drains. She can fly as long as a thumb can hold, and holding is the only limit |

A **two-second hold reaches the highest crystal** — the scope's ceiling on what a small hand can be
asked to do, and the number the sky's height is derived from rather than guessed at. If a real
child's thumb tires before the arch fills, **the fix is a shorter land, not an easier sky**:
lower `CrystalPartyGame.crystalsPerSide`.

## The colours are three cues, not one

Blue and pink are told apart **three** ways, and any one of them is enough on its own — so a
colourblind child is never locked out (CLAUDE.md §3):

- **colour** — blue and pink;
- **shape** — blue is a pointy shard, pink is a round blob. Pinned by a render test that measures
  how much of its bounding box each silhouette fills, with no reference to colour at all;
- **sound** — they ring on different halves of the chime ladder (`chimeProgress`).

Real art must keep the two silhouettes clearly different. That is a kid rule, not a style choice.

## The party is bright but SLOW

**The most likely rule in this repo to be broken by a future session trying to make the ending feel
bigger.** A "crystal party" is a strobe waiting to happen, and that is a real photosensitivity risk.

So the blaze *swells* over 1.6 seconds, the shimmer is capped at `Arch._shimmerHz` (1.6 Hz, under
the scope's "nothing changing faster than about twice a second"), and the glow grows by scale and
blur rather than by flicking on. **Big is achieved with scale and colour, never with rate.** A test
pins the swell.

## What was found by actually running it

Three things that 435 passing tests did not catch, all found by driving the built app in a browser
and *looking*:

- **The arch was invisible at the start of every land.** With no crystals gathered, every piece was
  skipped and it painted nothing — so the "progress is visible in front of her too" half of the
  whole design simply did not happen. Unfilled pieces are now drawn as ghosts. Pinned by a render
  test.
- **The arch was a paper fan.** Its bands spanned most of the radius, filling the disc and covering
  the sky the pink crystals live in. It is now a slim ring with sky showing through.
- **Two hard crashes**, caught by driving a fully mounted game in tests rather than a hand-booted
  one: a concurrent-modification error the first time anything scrolled off the left edge, and an
  effect applied to a crystal taken in the same frame it was added. Both would have hit a child.

## Still open

- **Hold, or tap-to-flap?** Hold is what is built, because it has no rhythm to keep up and nothing
  to be late for — a flap is Flappy Bird with the failure filed off. Swapping it is a change to
  `hold()`/`release()` alone; nothing else reads the control. Owned by the first real-child session.
- **Does a five-year-old's thumb tire before the arch fills?** Only a real hand settles it.
- **Is this the Rive character's job?** The scope calls a unicorn with a reacting face the strongest
  candidate `lib/shared/rive_character.dart` has had. The flight model was tuned against this exact
  shape-drawn body height, so a sprite has to keep the same body height and hoof line.
- **Never run on a phone or tablet.** Proven in a desktop browser under a driven pointer, and in
  441 tests — not under a thumb.
