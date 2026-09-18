# Games — Balloon Pop, second pass: feel, then mechanics (session)

- Date: 2026-09-18
- Scope: [../../scope/games/balloon-pop-scope.md](../../scope/games/balloon-pop-scope.md)
- Status: done
- Siblings: [balloon-pop-session.md](balloon-pop-session.md),
  [../shared/sound-effects-session.md](../shared/sound-effects-session.md)

## Goal

Done in two passes, the second because the first was not enough. **Pass one** made the game *feel*
better — burst, sky, animated stars, the pop ladder. The maintainer's response was the right one:
*"you didn't make the game any funner?"* And they were correct. Pass one added juice, not play: the
verb was still "tap the balloon", and no amount of nicer feedback on a single verb makes a game
more fun. **Pass two** added mechanics. Both passes are recorded below, in that order.

## Pass one — feel

Balloon Pop was correct and dull. Every kid rule was obeyed, the loop worked, the tests were green —
and a balloon popping was a circle that stopped existing over a flat gradient. The ask was to make
it ten times better without loosening a single rule.

Two questions drove the work:

1. **What would a five-year-old actually be unable to do here?** Answer: reliably tap a moving
   target. That is a fine-motor problem, not a game-design one, and no amount of prettier art fixes
   it.
2. **With no score and no winning, what is the reward?** Answer: the moment. So the moment — the
   pop, the star filling, the sound — is where the effort belongs.

## What changed

### For the child's hands

**Swipe to pop** (`balloon_pop_game.dart`). The game mixes in `DragCallbacks`; a dragged finger
pops every balloon it passes within `isWithinDragReach` of — the balloon's touch target plus 18px,
because a moving finger only samples a handful of points a second, and a fast sweep would otherwise
appear to pass straight through a balloon. This is the single biggest accessibility change: aiming
is a skill they are still building, sweeping an arm is not, and a sweep is what an excited child
does anyway.

**Three balloon sizes, big ones slowest.** `balloonRadii = [38, 46, 56]`, and `_riseSpeedFor`
inverts speed against size, so the biggest target is also the longest-lived. A struggling child gets
an easier game without anything being configured. Smallest touch target is 98×98 — a test pins
`smallestTouchTarget` against the 80×80 floor so a future size tweak cannot quietly breach it.

**Seven balloons maximum.** Past that the screen reads as clutter rather than as a sky, and a child
who cannot choose just stabs.

### For the moment

**`PopBurst`** (new). Rubber shreds fly out and arc down under gravity, a white ring expands and
thins, sparkly balloons add stars. All in the popped balloon's own colour, so the child reads it as
*that one, the one I hit*. Drawn as one component from a single time counter rather than a component
per shred — pops are frequent and none of it may accumulate.

**`Sky`** (new, replaces the private `_Sky`). Gradient, a sun breathing on an 8-second cycle,
clouds drifting in two parallax layers, hills along the bottom. This is not decoration: a balloon
rising off a flat gradient *vanishes*, and one rising out of a landscape *floats away*. That second
reading is what stops a missed balloon feeling like a loss.

**Balloons look like balloons.** Radial shading, a pinched knot, a string that trails against the
sway, a body that breathes, and about four degrees of tilt into its own drift. Still placeholder
art, still drawn in code, still no assets.

**Sparkly balloons.** Roughly one in seven glitters and bursts into a local `Celebration.puff`. It
fills exactly one star, like every other balloon.

**Real stars, animated.** `ProgressStars` drew circles. It now draws five-point stars (via the new
`shared/kid_shapes.dart`), a newly earned one springs in with an overshoot so the child connects it
to the balloon they just hit, the empty stars ahead warm as the row fills, and the row lifts as it
completes.

**The pop cue climbs.** `AudioController.playSfx` takes an optional `variant`;
`KidSounds.pop(progress:)` walks up the ascending `kid_pop*` samples instead of picking at random.
The sound now says "nearly there" on its own — the only progress signal a child who cannot read a
number can *hear*.

**Haptics** (`shared/kid_haptics.dart`, new). Light impact on a pop, medium on a celebration,
nothing at all on a mistake.

**A richer celebration.** Three confetti shapes instead of one, a quarter of the pieces rising from
the bottom rather than all falling, and the new `puff` for local moments.

**Files:** new `components/pop_burst.dart`, `components/sky.dart`, `shared/kid_shapes.dart`,
`shared/kid_haptics.dart`. Rewritten `components/balloon.dart`, `components/progress_stars.dart`,
`balloon_pop_game.dart`, `shared/celebration.dart`. Touched `shared/kid_sounds.dart`,
`audio/audio_controller.dart`, `shared/kid_palette.dart` (sun, hills, `starBright`).

## Pass two — actual mechanics

**Bunches that chain.** Balloons now arrive in bunches of three of the same colour, and popping one
sets its neighbours off in a ripple 110ms apart, cascading as each link sets off its own. One tap,
a run of pops, the pop note climbing through all of them.

The bunching is the half that matters and it is easy to miss: chain-popping same-colour neighbours
on its own does almost nothing, because with six colours scattered at random two of a colour are
practically never neighbours. Without bunches the mechanic would have existed in the code and never
once fired in front of a child.

**Big balloons.** `bigBalloonRadius` 74, three taps, visibly swelling on each — the swelling is the
whole instruction, since a five-year-old cannot be told "keep going". Slower than anything else,
because three taps has to be a promise the game can keep. Every tap counts as progress, including
the two that don't finish it. The third bursts into a shower of five little balloons.

**A sky that answers.** The sun turns out rays, a cloud squashes and puffs sparkles.
`Sky.containsLocalPoint` is overridden so the sky claims *only* taps that land on the sun or a
cloud — everything else falls through to the game's handler, and balloons at a higher priority
always win. Neither fills a star, so balloons stay the point.

**Files:** rewrote the spawn path in `balloon_pop_game.dart` (`_spawnSomething`, `_spawnBunch`,
`_spawnBigBalloon`, `_burstIntoLittleOnes`, `_enqueueChain`, `_advanceChain`, `catchesRipple`), gave
`Balloon` a `taps` count and a swelling `_squeeze`, and made `Sky` tappable.

## Decisions & alternatives

**A pitch ladder from existing samples, not a playback rate.** The obvious way to make the pop climb
is `AudioPlayer.setPlaybackRate`. Rejected: on iOS, `AVPlayer` preserves pitch across rate changes
by default, so the ladder would silently do nothing on half the shipping targets — and there is no
iOS device in reach of these sessions to find that out. The ladder instead walks the three
*already ascending* `kid_pop{1,2,3}` samples, which behaves identically everywhere.

The cost is a shallow ladder: three rungs across ten pops. More rungs is purely a matter of
generating more samples — `tools/make_sfx.py` is set up for it — but **this machine has no mp3
encoder** (no ffmpeg, lame, sox or gstreamer), so new audio could not be produced here. Nothing in
Dart assumes the rung count, so adding samples needs no code change.

**Sparkly balloons are worth a better moment, never more progress.** The temptation is to make the
rare balloon fill two stars. That is a score in disguise: the instant one balloon is worth more than
another, popping becomes something a child can be *inefficient* at, and CLAUDE.md §3 is gone.

**The progress row empties with the confetti, not after it.** Originally the reset moved to the end
of the 1.8s pause, on the theory that the child should not see the row empty. It is the opposite:
balloons already in the air can still be popped during the pause, so a row that emptied *afterwards*
would visibly fall from ten back to one. Reset lands in the same frame as the confetti instead.

**The row got a tray behind it.** Caught in a screenshot, not in review: clouds drift through that
corner, and an empty star on white cloud loses almost all its contrast. The tray guarantees one
consistent background. It is the only progress signal a child who cannot read can see, so it cannot
depend on what happens to be behind it.

**Every tap on a big balloon counts, including the unfinished ones.** The alternative — progress
only on the burst — makes the first two taps feel like nothing happened, which is the exact reading
CLAUDE.md §3 forbids. Progress only ever rises, so paying out on a squeeze costs nothing, and a
child who taps a big balloon once and wanders off still got something.

**The chain is staggered, not instant.** Popping a bunch simultaneously is one loud noise. At 110ms
apart it is a *run*: the note climbs link by link and the ripple visibly travels outward. The delay
is the mechanic, not an implementation detail.

**Chain pops are queued, then fired after the queue is drained.** Popping inside the loop that walks
the queue means a link can append to the list being iterated. It cannot run away regardless — a
balloon latches the moment it starts popping and `_queuedForChain` stops double-queueing — but the
list mutation is a real bug waiting for a busier screen, so `_advanceChain` collects what is due
first and pops afterwards.

**A hard ceiling above `maxBalloons`.** A big balloon's shower deliberately ignores the cap, because
that brief moment of plenty is the reward for three taps. That exception is fine on its own and
dangerous as a precedent, so `maxBalloonsHard` bounds it: the next mechanic that spawns past the cap
cannot stack with this one. This came out of looking at a screenshot and thinking the sky looked
busy, not out of a test.

**Big balloons are not exempt from chains.** A ripple that reaches one squeezes it, exactly like a
finger would. Coherent: a chain link *is* a tap.

**A drag over empty sky does not fire the wobble.** It would fire continuously, which is exactly the
nagging the wobble's rate limit exists to prevent. A swipe that hits nothing stays silent.

**`driftAway` fades instead of removing.** It is called every frame on every off-screen balloon, so
it had to become idempotent. Worth it: a balloon the child was reaching for visibly *leaves* rather
than being taken away.

**Haptics are not settings-gated.** There is no haptics switch, and adding one to the parent area
was out of scope for this pass. Every call is fire-and-forget and swallows failure, and only the
lightest impacts are used, so the worst case is a parent who wants it off and can't turn it off —
flagged as an open thread rather than guessed at.

## Verified, and not

Ran `flutter analyze` (clean), `flutter test` (**38 tests, 0 failures** — 19 new, up from 19), and
`make privacy` (clean: nothing new touches the network; the only new import across the whole change
is `flutter/services.dart` for `HapticFeedback`).

One of the new tests failed first time and was worth having: the bunch-geometry invariant caught a
mistake in *the test's own* arithmetic (an extra radius added to a centre-to-centre distance). The
real geometry chains fine. It stays in because the thing it guards — bunches drifting wider than
`chainRadius` — would silently delete the best mechanic in the game with no error anywhere.

**Then actually played it,** both passes. Built for web (`--no-web-resources-cdn`, since this box
has no network) and drove it in headless Chrome at 1280×720 landscape. **No console errors, no page
errors** across four driven sessions.

Confirmed on screen: the sky, sun, hills, shaded balloons, sparkle stars, the shred-and-ring burst,
the star row mid-spring, the reset, and a full confetti celebration. The progress-row tray fix came
straight out of reading those frames.

From pass two: **a chain caught mid-ripple** — one tap on a yellow bunch of three, and the next
frame has all three gone, three stars filled, three overlapping burst rings and a cloud of yellow
shreds, with the purple balloon beside them untouched. Same-colour bunches are clearly readable as
bunches. The sun's rays turn out on a tap and drop a sparkle. Big balloons appear and are obviously
the biggest thing in the sky.

**Not verified, and nobody should assume otherwise:**

- **No audio was heard.** The pop ladder was verified as an index sequence by test, not by ear. That
  the climb sounds like a climb is still a guess.
- **No haptic was felt.** There is no vibrator in reach of this session.
- **No touch.** Headless Chrome dispatches mouse events. A mouse drag is not a five-year-old
  sweeping a hand, and the whole swipe-to-pop feature rests on that difference being small.
- **The big balloon's three-tap swell and its shower were never caught in a frame.** Verified by
  test (three taps, each counted, burst and `PopBurst` on the third) but the timing never lined up
  with a screenshot, so *how legible the swelling is* remains unproven — and it is the only
  instruction in the game.
- **Crowding.** Bunches of three plus showers of five make a much fuller sky. It looked right in
  screenshots and `maxBalloonsHard` bounds it, but "bright, friendly, calm" is a judgement only a
  real screen in real hands can make.
- **iOS and macOS unverified** — no Mac available to these sessions.
- Every tuned number in here (spawn rate, three radii, `dragReach`, `sparklyInEvery`, `maxBalloons`)
  is a considered guess. The only instrument that settles them is a child.
