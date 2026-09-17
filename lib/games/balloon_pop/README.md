# Balloon Pop

Balloons float up from the bottom; tapping one pops it with a sound and a burst. Every 10 pops
there is a celebration, then more balloons. It never ends and it cannot be lost.

| File | What it is |
|---|---|
| `balloon_pop_game.dart` | The `FlameGame`: spawning, pop counting, celebration rhythm |
| `balloon_pop_screen.dart` | The Flutter screen hosting it, plus the shared home button |
| `components/balloon.dart` | One balloon — placeholder art drawn in code |
| `components/progress_stars.dart` | Progress toward the next celebration |
| `assets.dart` | Every asset path, in one place |

## Decisions worth knowing

**Pop on tap-down, not tap-up.** A five-year-old's finger often slides between the two; an ignored
tap reads to them as the game being broken.

**The touch target is bigger than the balloon.** `Balloon.size` is `radius * 2.6` while the drawn
balloon is about `radius * 1.85` wide. Aiming at a balloon and landing just outside it still pops
it — the classic frustration at this age is a target that looks hittable but isn't quite.

**A balloon reaching the top is a non-event.** It is removed silently: no sound, no counter change,
nothing subtracted. There is no miss, so there is nothing to be bad at.

**Pops are latched.** `Balloon._isPopping` means a child mashing the same balloon counts it once.

**Progress is a count, not a score.** Ten dots fill as they pop, and reset to empty after each
celebration. Never a number, never decreasing, no time limit on filling it.

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

- Real balloon artwork (paths go in `assets.dart`).
- Soft pop and celebration sounds — currently reusing the template's arcade sfx, and a realistic
  balloon *bang* would startle a five-year-old. See `lib/shared/kid_sounds.dart`.
- Tune spawn rate and rise speed against an actual child.
