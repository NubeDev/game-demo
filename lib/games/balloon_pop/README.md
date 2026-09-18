# Balloon Pop

Balloons float up through a drifting sky; touching one pops it with a rising note and a burst of
rubber. Every 10 pops there is a celebration, then more balloons. It never ends and it cannot be
lost.

| File | What it is |
|---|---|
| `balloon_pop_game.dart` | The `FlameGame`: spawning, pop counting, swipe handling, celebration rhythm |
| `balloon_pop_screen.dart` | The Flutter screen hosting it, plus the shared home button |
| `components/balloon.dart` | One balloon — placeholder art drawn in code |
| `components/pop_burst.dart` | The shreds-and-ring burst a popped balloon leaves behind |
| `components/sky.dart` | The drifting sky: gradient, sun, parallax clouds, hills |
| `components/progress_stars.dart` | Progress toward the next celebration |
| `assets.dart` | Every asset path, in one place |

## What there is to *do*

Tapping one balloon at a time is a thing to look at, not a thing to play. Three mechanics give the
child something to **cause**.

**Bunches chain.** Balloons arrive in bunches of three of the **same colour**, and popping one sets
its neighbours off in a ripple 110ms apart — which cascades, because each link sets off its own
neighbours. One tap, three or more pops, with the pop note climbing through the whole run. It is the
best thing in the game and the first thing a child discovers by accident.

One colour is the whole point. A mixed cluster is clutter; a matching one is a pattern a child can
learn to look for, which is the closest this game gets to a skill — and it is a skill with no
failure state attached, because a mistimed tap just pops one balloon instead of three.

Two invariants keep it working, both pinned by tests: bunches are laid out at 1.35 radii apart so
even the widest bunch sits inside `chainRadius` end to end (otherwise bunches silently stop
chaining, with no error to notice), and `catchesRipple` refuses a balloon that is already on its way
out, so a ripple can never bounce between two balloons forever.

**Big balloons take three taps.** `bigBalloonRadius` is 74 — visibly the biggest thing in the sky —
and it **swells on every tap**. That swelling is the entire instruction: a five-year-old cannot be
told "keep going", so the balloon has to say it. It rises slower than anything else, because three
taps has to be a promise the game can keep; a big balloon that floated off before it could be tapped
three times would make the swelling a lie.

Every tap counts as progress, including the two that don't finish it. Progress only rises, so
rewarding the unfinished taps costs nothing, and a child who taps once and wanders off still got
something. On the third it bursts into a **shower of five little balloons** — the reward for popping
is more to pop, never a bigger number.

**The sun and the clouds answer.** A five-year-old taps everything, and at this age a thing that
does nothing when touched is not scenery, it is broken. The sun turns out a set of rays; a cloud
squashes and puffs sparkles. Neither fills a star, so balloons stay the point — but it means a tap
that missed every balloon can be *something the child did* rather than a near-miss.

`Sky.containsLocalPoint` is overridden so the sky only claims taps that actually land on the sun or
a cloud. Everything else falls straight through to the game's own handler, and balloons — at a
higher priority — always win.

## Three decisions about hands, not balloons

These are the difference between a game a five-year-old can play and one they can only watch.

**A dragged finger pops.** `onDragUpdate` pops every balloon the finger passes within
`isWithinDragReach` of. Aiming a tap at a moving target is a fine-motor skill a five-year-old is
still building; sweeping an arm is not — and a sweep is what a child actually does once they get
excited. The reach is the balloon's touch target *plus* a margin, because a moving finger only
samples a handful of points a second and the gaps between those samples are where a fast swipe would
otherwise appear to pass straight through a balloon.

A drag over empty sky is deliberately **not** paired with the empty-sky cue: it would fire over and
over, which is exactly the nagging that cue is rate-limited to avoid.

**Three balloon sizes, and the big ones are the easy ones.** `balloonRadii` is `[38, 46, 56]`, and
`_riseSpeedFor` makes the bigger balloon the *slower* one — so the largest target is also the one
that hangs around longest, and a child who is struggling gets an easier game without anything being
adjusted. The smallest touch target is still 98×98; `BalloonPopGame.smallestTouchTarget` is pinned
against the 80×80 floor by a test.

**Pop on tap-down, not tap-up.** A five-year-old's finger often slides between the two; an ignored
tap reads to them as the game being broken.

## Other decisions worth knowing

**The touch target is bigger than the balloon.** `Balloon.size` is `radius * 2.6` while the drawn
balloon is about `radius * 1.85` wide. Aiming at a balloon and landing just outside it still pops
it — the classic frustration at this age is a target that looks hittable but isn't quite.

**A balloon reaching the top is a non-event.** It fades and shrinks out over about half a second:
no sound, no counter change, nothing subtracted. There is no miss, so there is nothing to be bad at.
The fade rather than an instant removal is the point — a balloon the child was reaching for visibly
*leaves*, rather than being taken away. `driftAway()` is idempotent, because the game calls it on
every off-screen balloon every frame.

**The sky is doing work, not decoration.** Clouds drift in two parallax layers, the sun breathes on
an 8-second cycle, and hills sit along the bottom. A balloon that rises off a flat gradient
*vanishes*; one that rises out of a landscape *floats away* — and that reading is what keeps a
missed balloon from feeling like a loss. Nothing in it moves fast enough to pull the eye off a
balloon, and it is non-interactive at a low priority, so a tap always reaches a balloon or the
game's own handler, never the scenery.

**The pop cue climbs as the stars fill.** `sounds.pop(progress:)` walks up the ascending `kid_pop*`
samples, so the sound itself says "nearly there" and the celebration lands as the resolution of a
phrase. It is the same trick as a coin ladder, and it is the only progress signal a child who cannot
read a number can *hear* — it works with the screen barely looked at. See `lib/shared/README.md`.

**A sparkly balloon is worth a better moment, never a bigger number.** Roughly one balloon in seven
glitters and bursts into stars with a local `Celebration.puff`. It fills exactly one star, like
every other balloon. There is no score, so "better balloon" can only ever mean a better moment —
the instant it means more progress, popping becomes something to be efficient at.

**The burst is one component, not one per shred.** `PopBurst` draws its shreds, ring and sparkles
itself from a single time counter. A child pops many balloons a minute, so each pop has to stay
cheap, and none of it may accumulate — there is a regression test for that.

**Nine balloons, maximum — and a hard ceiling above that.** Past `maxBalloons` the screen stops
reading as "balloons in a sky" and starts reading as clutter, and a child who cannot choose just
stabs at it. A big balloon's shower deliberately ignores that cap, because the brief moment of
plenty is the reward for three taps; `maxBalloonsHard` is the backstop that stops that exception
stacking with whatever mechanic gets added next.

**The progress row has a tray behind it.** Clouds drift through that corner, and an empty star on
white cloud loses nearly all its contrast. The tray guarantees the row always sits on the same
background — it matters more than usual here, because it is the only progress signal a child who
cannot read can *see*.

**Pops are latched.** `Balloon._isPopping` means a child mashing the same balloon counts it once.

**Progress is a count, not a score.** Ten stars fill as they pop, and reset to empty after each
celebration. Never a number, never decreasing, no time limit on filling it. A newly earned star
*pops in* with an overshoot, so the child connects it to the balloon they just hit, and the empty
stars ahead warm as the row fills — "nearly" without a number.

The row empties in the same frame the confetti arrives, not when play resumes: balloons already in
the air can still be popped during the pause, and a row that emptied afterwards would visibly fall
from ten back to one. Progress draining away is the one thing it must never do.

**Celebration doesn't stop play.** Confetti overlays the screen, spawning pauses for 1.8s so the
burst is the thing you see, then balloons resume. There is no "well done" dialog — a child cannot
read one, and dismissing something breaks the rhythm.

## The Rive character

`RiveCharacter` (in `lib/shared/`) drives an artboard through **data binding**, per CLAUDE.md §2.
Which properties it looks for is `balloonPopCharacterProperties` at the bottom of
`balloon_pop_game.dart`.

### Right now: there isn't one

**The game loads no `.riv` file.** There is no character on screen, and `RiveCharacter` is not
instantiated anywhere.

There used to be a stand-in: `assets/rive/rewards.riv` from the
[official flame_rive example](https://github.com/flame-engine/flame/tree/main/packages/flame_rive/example),
rendered small in the bottom-left corner. It was never a character — it is a mock rewards *screen*
(treasure chest, coin and gem counters, energy bar), and it exposed no triggers, so the game bound
"excitement" to its coin counter and `celebrate()` fired nothing. It was a wire test for the
data-binding path, not art.

It was removed. On screen it read as a small dark rectangle lying in the grass, and it did nothing
when tapped — which at this age is not scenery, it is a broken thing in the play area
(CLAUDE.md §3). Nothing is better than a stand-in until real character art exists.

**What survives is the plumbing, unused and ready:** `lib/shared/rive_character.dart`,
`RiveNative.init()` in `main()`, and the drop-in steps below. Adding a character is an asset plus
about six lines.

### What your own `.riv` file needs

Build one artboard with a **default state machine** and a **default view model** (data binding —
not state machine *inputs*, which are the removed 0.14 API). Expose these properties on the view
model:

| Property | Type | What it drives |
|---|---|---|
| `Celebrate` | **Trigger** | The big reaction: every 10 pops. Bouncy, happy, a second or two. |
| `Encourage` | **Trigger** | The gentle "try again" reaction. See the warning below. |
| `Excitement` | **Number**, 0–1 | Anticipation as the stars fill. 0 = idle, 1 = about to celebrate. Drive a lean-in, a wider smile, a faster idle. |

Nested properties are addressed with a path, e.g. `Body/Eyes` — that is why the stand-in uses
`Coin/Item_Value`.

Then wire it up. Drop the file in `assets/rive/`, re-add `- assets/rive/` to `pubspec.yaml`
(the entry was removed with the directory), and:

```dart
// lib/games/balloon_pop/assets.dart — uncomment and point at your file
static const character = 'assets/rive/my_character.riv';

// lib/games/balloon_pop/balloon_pop_game.dart — restore the constant
const balloonPopCharacterProperties = RiveCharacterProperties(
  celebrateTrigger: 'Celebrate',
  encourageTrigger: 'Encourage',
  excitementNumber: 'Excitement',
  excitementScale: 1,        // use 100 if your file works in 0-100
);
```

Then re-add the field, the `RiveCharacter(...)` in `onLoad` (the comment marking where it went is
still there), and the three calls: `setExcitement()` as the stars fill, `celebrate()` in
`_celebrate()`, and `setExcitement(0)` when play resumes.

Every property is optional — `RiveCharacter` logs and carries on if one is missing, so a
partially-finished file still works and the game never breaks because of art.

### One rule for the animation

**The character must never look sad, cross or disappointed** — not even on `Encourage`. A
character's reaction to a mistake is exactly where punishment sneaks back into a game that is
supposed to have none (CLAUDE.md §3). Encouraging, curious, "ooh, try another one" — never a frown,
never a head shake.

Also: nothing startling. No sudden lunges toward the screen, no loud-looking motion, no flashing.

## Still to do

- Real balloon artwork (paths go in `assets.dart`). Everything on screen is still drawn in code.
- Real recorded audio. The cues are synthesised placeholders and **none of them has been listened
  to** — they were verified numerically. See `tools/README.md`.
- A deeper pop ladder. There are only three rungs, because this machine has no mp3 encoder to make
  more; `tools/make_sfx.py` is ready for it and no Dart change is needed.
- Tune spawn rate, rise speed, balloon sizes, the swipe reach, `chainRadius` and `bunchInEvery`
  against an actual child. Every number in this game is a guess until then.
- **Watch for crowding.** Bunches of three plus showers of five make a much fuller sky than before.
  It looked right in screenshots and the hard ceiling bounds it, but "calm" is a judgement only a
  real screen in real hands can make.
- A **sticker book** is the obvious next thing: something that persists between sessions, so the
  celebrations add up to more than the moment. `shared_preferences` is already wired in for
  progress.
- **A character.** There is none — the stand-in was removed (see above) and the corner is empty.
  The plumbing is ready; it needs a real `.riv`, or a coded placeholder in the meantime.
