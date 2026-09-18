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

**Seven balloons, maximum.** Past `maxBalloons` the screen stops reading as "balloons in a sky" and
starts reading as clutter, and a child who cannot choose just stabs at it.

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

### Right now: a stand-in

The game currently loads **`assets/rive/rewards.riv`**, taken from the
[official flame_rive example](https://github.com/flame-engine/flame/tree/main/packages/flame_rive/example).
It is not a character at all — it is a mock rewards *screen* (a treasure chest, coin and gem
counters, an energy bar). It is here only to prove the loading and data-binding path works end to
end before real art exists, so it is rendered small in the bottom-left corner, out of the play area.

It exposes nested view models rather than triggers, so the game binds excitement to its coin
counter (`Coin/Item_Value`, 0–100). Popping balloons makes the coin number climb. That is not a
reaction anyone wants to ship — it is a wire test.

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

Then point the game at it:

```dart
// lib/games/balloon_pop/assets.dart
static const character = 'assets/rive/my_character.riv';

// lib/games/balloon_pop/balloon_pop_game.dart
const balloonPopCharacterProperties = RiveCharacterProperties(
  celebrateTrigger: 'Celebrate',
  encourageTrigger: 'Encourage',
  excitementNumber: 'Excitement',
  excitementScale: 1,        // use 100 if your file works in 0-100
);
```

No other Dart changes. Every property is optional — `RiveCharacter` logs and carries on if one is
missing, so a partially-finished file still works and the game never breaks because of art.

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
- Tune spawn rate, rise speed, balloon sizes and the swipe reach against an actual child. Every
  number in this game is a guess until then.
- The Rive stand-in now sits on the new hills, where it reads as a small phone lying in the grass.
  It was always a wire test rather than art (see above); it is more obviously wrong now.
