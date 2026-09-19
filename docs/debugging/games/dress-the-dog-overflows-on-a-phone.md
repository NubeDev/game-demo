# Dress the Dog overflows the bottom of the screen on a phone

- Date: 2026-09-18
- Area: games/dress_the_dog
- Status: resolved
- Session: ../../sessions/games/dress-the-dog-responsive-layout-session.md

## Symptom

On the Android emulator (`make run-emulator`, Pixel in landscape, 892x412 logical), the Dress the
Dog screen showed Flutter's yellow-and-black overflow stripe and
**"BOTTOM OVERFLOWED BY 133 PIXELS"** across the bottom right. The wardrobe rail's lowest item tile
was cut off, and the rail ran underneath the home button.

The same screen was fine on a tablet, which is why it had not been caught.

## Investigation

Ruled out in order:

1. **Not the dog, the backdrop or the ticker.** The overflow was a `RenderFlex`, and the only
   `Column`s on the screen are the wardrobe rail's tab column and its item column.
2. **Not a missing `SafeArea`.** Insets were already handled; the content was simply taller than
   the screen.
3. **The actual arithmetic.** The rail stacks one tile per wardrobe item at a fixed 120px, and the
   fullest slot (`head`) holds 4:

   ```
   4 x 120  +  3 x 16 gaps  =  528px
   ```

   ...in a screen 412px tall, of which the rail could use ~280px once the home button's strip and
   the margins were reserved. 528 - 395 ≈ 133, the reported overflow.

Three dead ends worth recording, because each looked like the fix and was not:

- **Shrinking everything with one scale factor.** Scaling the rail to fit means tiles of ~60px,
  well under the 80x80 floor in CLAUDE.md §3. A target a five-year-old cannot hit is not a fix.
- **Closing up the tab column's gaps until it fits.** Gets the tabs into the box, but four 84px
  tabs need 348px of the 280px available even at a 4px gap. The tabs have to move, not shrink.
- **Reserving a home-button-tall strip above the rail.** This was the original layout's approach
  and is what made the rail short enough to need its wide "tabs across the top" shape, which then
  crowded the dog out of the screen. Keeping the rail clear of the home button by **width** costs
  nothing; doing it by **height** costs the one dimension the rail cannot spare.

## Root cause

The screen was built from **hard-coded pixel offsets** — `right: 300`, `bottom: 74`, a 420x400 dog
box, `Alignment(0.94, 0.28)` — chosen against a tablet-sized window. Nothing consulted the actual
constraints, so on any shorter screen the fixed-size rail simply ran off the bottom.

## Fix

The screen now lays itself out from the box it is actually given
([dress_the_dog_screen.dart:196](../../../lib/games/dress_the_dog/dress_the_dog_screen.dart#L196)),
and each control knows how to give way without breaking the kid rules:

- **`WardrobeRail`** takes a `scale`, wraps its items into more columns when one column will not
  fit, and moves its slot tabs from the side to a row across the top as a last resort — tiles and
  tabs never go below 84px
  ([wardrobe_rail.dart](../../../lib/games/dress_the_dog/components/wardrobe_rail.dart)).
- **`WeatherSwitch`** wraps its three buttons onto more than one row rather than shrinking them
  ([weather_switch.dart](../../../lib/games/dress_the_dog/components/weather_switch.dart)).
- **The dog** is scaled with `Transform.scale` to whatever space the controls leave, keeps a
  reserved minimum width, and stands on the ground band.
- **The rail keeps the full screen height** and stays clear of the home button by width.

## Regression test

[`test/dress_the_dog_layout_test.dart`](../../../test/dress_the_dog_layout_test.dart) — 21 cases
over five screen sizes, including the 892x412 emulator size this was reported on. Each size
asserts: no overflow exception, every control **and the dog** fully on screen, tiles and weather
buttons still >= 80px, and no overlap between the dog, the rail, the weather row and the home
button. Every slot's tab is tapped, because the rail is only as tall as its fullest slot.

Two details the test had to get right, both of which produced false results first:

- It measures **painted bounds** (`getTransformTo`), not the raw render box. The dog is drawn
  through a `Transform.scale` whose box still reports the unscaled size, which reported overlaps
  that were not on screen.
- It asserts on **the dog as well as the controls**. An earlier version checked only the controls
  and passed while the dog was squeezed to nothing behind a weather button.
