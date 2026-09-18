# Games — Dress the Dog, first playable slice (session)

- Date: 2026-09-18
- Scope: [../../scope/games/dress-the-dog-scope.md](../../scope/games/dress-the-dog-scope.md)
- Status: done (placeholder art; drag added; never run on a device — see Tests)

## Goal

Build the first runnable slice of Dress the Dog: a shape-drawn dog, a wardrobe rail that puts
clothes on it, and the weather switch — with the dog reacting to what it is wearing against the
weather. Placeholder art throughout.

## What changed

New game under `lib/games/dress_the_dog/`:

| File | What it is |
|---|---|
| `wardrobe.dart` | `Weather`, `Slot`, `WardrobeItem`, `Outfit`, `DogFeeling`. 12 items across 4 slots. |
| `components/dog.dart` | The placeholder dog drawn in code, with tweened reactions. |
| `components/wardrobe_rail.dart` | 120×120 clothes tiles + 84×84 slot tabs, no scrolling. |
| `components/weather_switch.dart` | Three 100×100 weather buttons. |
| `components/weather_backdrop.dart` | Sky, ground, falling rain/snow. No lightning. |
| `dress_the_dog_screen.dart` | Assembles it; one `Ticker` drives the idle motion. |
| `assets.dart` | Empty of paths, documents what the Rive artboard must expose. |
| `README.md` | Why the game is built this way. |

Wired in: a `/dress-the-dog` route in [`lib/router.dart`](../../../lib/router.dart), and the menu's
third "coming soon" tile is now the real game in
[`lib/menu/home_screen.dart`](../../../lib/menu/home_screen.dart).

Tests: `test/dress_the_dog_test.dart` (16), plus two render harnesses
(`dress_the_dog_render_test.dart`, `dress_the_dog_screen_shot_test.dart`) that write PNGs so the
code-drawn art can actually be looked at. They are tagged `render` and no-op without `SHOT_DIR`.

## Decisions & alternatives

- **Widgets, not a `FlameGame`.** Balloon Pop is Flame because things move and collide; this is a
  dressing table — tap a picture, a picture changes. A Flame loop and component tree would buy
  nothing. One `Ticker` drives the dog's idle motion.
- **The feeling rule lives in one place** (`Outfit.feelingIn`), keyed off two numbers per item —
  `warmth` and `dry` — rather than scattering "if snowing and wearing trunks" through the drawing
  code. Adding an item is then data, not logic.
- **Tap-to-wear, not drag.** Dragging is a harder motor skill and a dropped item reads as failure.
  Rejected drag for the first slice; it can be added alongside later.
- **Tapping the worn item removes it**, rather than a separate "take off" control a child would
  have to find and understand.
- **Thresholds are wide: one sensible item reaches `justRight`.** This closes a scope open question
  in favour of "one key item" — a four-slot puzzle is too much at five.
- **Rejected a "correct!" marker of any kind.** The scope's inversion is implemented literally: a
  mismatch gets only the soft `wobble` cue and the dog's comedy; `justRight` gets the celebration.
  Mismatches get **no haptic** — a jolt after a "wrong" choice is punishment.

## Tests

`flutter analyze` — clean:

```
Analyzing game-demo...
No issues found! (ran in 1.0s)
```

`flutter test` — 62 pass (was 38; 24 new):

```
00:00 +62: All tests passed!
```

The new tests pin the rules rather than the look: swimming trunks go on in the snow and are **not
blocked**; the wardrobe is never filtered by weather; one sensible item is enough; every touch
target clears 80×80; nothing child-facing renders text; the home button is present; and a full
playthrough — cold in swimmers → dressed → just right → all removable — with the outfit surviving
every weather change.

Network/SDK grep over the new folder: nothing. No storage of any kind was added.

### Rendered and looked at, not just passing

The dog is drawn in code, and `flutter test` cannot tell whether a shivering dog reads as funny or
sad. Both harnesses were rendered to PNG and inspected, which **found six things tests did not**:

1. the dog floated above the ground — legs ended in mid-air;
2. stubby legs with no paws;
3. round ears behind the head, reading as a bear rather than a dog;
4. swimming trunks floating beside the body instead of worn on it;
5. the scarf a plank across the face, covering the mouth — where all the expression is;
6. on the full screen, the dog floated again and the home button overlapped the top wardrobe tile.

All six fixed and re-rendered.

### NOT verified — the honest list

- **Never run on a device, a simulator, or `-d macos`.** No device was reachable from this session.
  Everything above is `flutter test` plus rendered stills; **feel, target size under a real thumb,
  and animation timing are unproven.**
- **No sound was heard.** The cues are wired (`tap`, `wobble`, `celebrate`) but never played.
- **No haptics felt** — no vibrator in reach.
- **The comedy is unproven.** The reactions are tweened placeholders. Whether a shivering dog reads
  as funny rather than sad is the single most important thing in this game and **only a child can
  settle it**.
- The icon glyphs render as empty squares in the test environment (no icon font); they are correct
  in the real app but have not been seen rendered.

## Addendum — drag and drop (same session)

Added after the first slice, on request: clothes can be **dragged** onto the dog as well as tapped.

**Tap was kept.** Drag is the motion a child reaches for, but it is a harder motor skill and it
introduces the one thing this game otherwise lacks — a way to miss. So a miss costs nothing:

- a missed drop is **silent** (no sound, no wobble, no snap-back), the item just stays in the rail;
- the drop target is **420×400** around the dog, far bigger than its outline;
- the tile **stays in the rail** while dragging (dimmed) with a ghost following the finger, because
  a vanishing tile reads to a child as having broken it;
- the dog **perks up** — ears lift, eager bounce — while an item is in the air, which is the only
  wordless way to say "put it here";
- **plain `Draggable`, not `LongPressDraggable`** — the `delay` parameter belongs to the latter, and
  a hold-still-then-drag gesture is a timing skill a five-year-old does not have.

Six new tests (62 total, from 56): drop wears the item; it wears **once**, not twice, despite the
tile also having a tap handler; a missed drop changes nothing; the dog perks up and settles back;
the rail tile never disappears; and **tap still works**.

### Two hypotheses I had wrong, corrected by probing

1. I assumed a drag would wear the item twice (tap-down firing as well as the drop). A probe showed
   `worn=0` after touch-down and after a sky drop — it never did. The test pinning "once, not twice"
   is kept as a guard.
2. I then assumed the drag ghost was not rendering, because it was missing from the screenshot. A
   probe showed the ghost exists and `dog.reaching == true`. `Draggable` renders feedback in an
   `Overlay`, which sits **outside** the `RepaintBoundary` being captured — a limitation of the
   screenshot harness, not a bug. Both behaviours are now pinned by tests instead of by a picture.

Also fixed while here: the drag screenshot test's `pumpAndSettle` could never settle, because the
screen's idle `Ticker` never stops. Bounded `pump` is used throughout.

## Kid-rules check

- [x] Playable with no reading — no `Text` widget on the screen, pinned by a test
- [x] Touch targets ≥ 80×80 — tiles 120, weather 100, tabs 84, home 96; pinned by a test
- [x] No failure state, no punishing timer — no timer, no score, no blocked action, nothing counted
- [x] Home button present and obvious — same corner as every game, pinned by a test
- [x] No network calls, no SDK, no stored personal data — grep clean, nothing persisted

## Debugging

No `debugging/` entry: the six problems above were found by looking at renders during development,
not symptoms of a broken build.

## Scope updates

Closed in the scope doc:

- **"Does dressed-right need every slot, or one key item?"** → one key item.
- **"How much is worth building against placeholder shapes?"** → all mechanics, layout and sound
  wiring; the comedy is not.

Still open, and pushed back: three-or-four weathers, whether the going-out moment re-fires, combo
jokes, items per slot, and the outfit shelf.

## Follow-ups

- **Play it on a device with a real child** — the only thing that can settle the comedy.
- Not built in this slice, still scoped: the silly paw button (random outfit), the ta-da button and
  outfit shelf, the go-outside animation (currently the shared celebration cue only), and combo jokes.
- The Rive dog: `assets.dart` records the properties the artboard must expose.
