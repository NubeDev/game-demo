# Dress the Dog

A **toy, not a round.** There is no goal, so there is nothing to fail: the child dresses a dog,
picks the weather, and the dog reacts. The reward is what the dog does.

Scope: [`docs/scope/games/dress-the-dog-scope.md`](../../../docs/scope/games/dress-the-dog-scope.md)

## The one rule that holds this game together

Weather matching creates a **right answer**, and a right answer is one step from failing. It is
inverted on purpose:

| | What happens |
|---|---|
| Wrong for the weather | The dog is **funny** — shivering in swimming trunks, panting in a snow coat. Nothing is blocked, marked or counted. |
| Right for the weather | The dog is **happier still** and can go out to play, with the shared celebration. |

So being right is a **bigger reward**, never being wrong a punishment. Plenty of children will put
the trunks on in the snow deliberately — that is a success, not a mistake to correct.

**The dog is always visibly happy.** The tail never stops wagging, the mouth stays smiling, nothing
whimpers. A five-year-old reads a distressed animal as real, and a game about making a dog
miserable is not this game. `_paintWeatherFeeling` and the idle motion in
[`components/dog.dart`](components/dog.dart) are written to that limit — do not "improve" them by
making the sad states sadder.

## Two ways in, on purpose

Clothes go on by **tap** or by **drag**, and both must keep working.

Drag is the motion a child reaches for with a dressing toy, and it is worth having. But it is a
harder motor skill, and it introduces the one thing this game otherwise does not have: **a way to
miss.** So it is built to make a miss cost nothing:

- **A missed drop is silent.** No sound, no wobble, no item snapping back with a thud. The item is
  simply still in the rail, ready to be tapped instead. This is the single place drag could make a
  child feel they got something wrong, and it is deliberately uneventful.
- **The drop target is far bigger than the dog** (420×400 around it). A child aims at "the dog",
  not at its collar.
- **The tile never leaves the rail** while dragging — it dims, and a ghost follows the finger. A
  vanishing tile reads as having broken something.
- **The dog perks up** — ears lift, it bounces — while an item is in the air. With no words
  allowed, that is what says "put it here".
- **Plain `Draggable`, never `LongPressDraggable`.** Making a child hold still before dragging is a
  timing skill they do not have, and the wait reads as the tile ignoring them.
- **Tap is never removed.** A child who cannot manage a drag must still be able to dress the dog.
  A test pins this.

## Why widgets, not Flame

Unlike Balloon Pop this is not a `FlameGame`. Nothing moves on its own, nothing collides — it is a
dressing table: tap a picture, a picture changes. A Flame game would add a loop and a component
tree for no gain. One `Ticker` drives the dog's idle motion.

## The pieces

| File | What it is |
|---|---|
| `wardrobe.dart` | The model: `Weather`, `Slot`, `WardrobeItem`, `Outfit`, and `DogFeeling`. **The feeling rule lives here alone** — no `if snowing and wearing trunks` anywhere else. |
| `components/dog.dart` | The placeholder dog, drawn in code, with its reactions tweened. |
| `components/wardrobe_rail.dart` | The clothes rail and slot tabs. 120×120 tiles, no scrolling. |
| `components/weather_switch.dart` | The three weather buttons. 100×100. |
| `components/weather_backdrop.dart` | Sky, ground, rain and snow. No lightning, ever. |
| `assets.dart` | Asset paths, and what the Rive artboard must expose when it arrives. |

## Things that look like tidying but are not

- **The wardrobe is never filtered by weather.** Swimming trunks stay available in the snow, or the
  funny wrong answer — the thing the child actually wants — becomes unreachable. A test pins this.
- **Warmth thresholds are deliberately wide.** One sensible item reaches `justRight`; a four-slot
  puzzle is too much at five. Most outfits land in `fine`, which is a fine place to stay.
- **Nothing changes the weather except the child.** An outfit they were pleased with must never be
  invalidated by something they did not do.
- **No haptic on a mismatch.** A physical jolt after a "wrong" choice is punishment, however small.
- **Tap-down, not tap-up**, everywhere: a five-year-old's finger slides between the two.
