# Games — Dress the Dog, layout that fits a phone (session)

- Date: 2026-09-18
- Scope: [../../scope/games/dress-the-dog-scope.md](../../scope/games/dress-the-dog-scope.md)
- Debugging: [../../debugging/games/dress-the-dog-overflows-on-a-phone.md](../../debugging/games/dress-the-dog-overflows-on-a-phone.md)
- Status: done (verified on the Android emulator — see Tests)

## Goal

Reported from the Android emulator: the Dress the Dog screen was misaligned and showed
**"BOTTOM OVERFLOWED BY 133 PIXELS"**, with the wardrobe rail running off the bottom and under the
home button.

Make the screen fit every landscape phone, without breaking the kid rules that made the original
sizes what they are.

## What changed

The screen was built from hard-coded pixel offsets (`right: 300`, `bottom: 74`, a fixed 420x400 dog
box) chosen against a tablet. It now lays itself out from a `LayoutBuilder`, and each control knows
how to give way:

| File | What changed |
|---|---|
| `dress_the_dog_screen.dart` | Whole layout derived from the real constraints and the safe-area insets. One `scale` for every control; the dog scaled to the space left over and given a reserved minimum width. |
| `components/wardrobe_rail.dart` | Takes `scale`. Items wrap into more columns when one column will not fit; slot tabs move from the side of the rail to a row across the top as a last resort. Tiles and tabs never drop below 84px. |
| `components/weather_switch.dart` | Takes `scale` and `columns`; the three buttons wrap onto another row rather than shrinking. |
| `components/dog.dart` | Exposes `Dog.artSize` instead of burying `Size(280, 292)` in its `build`, so the screen can scale it instead of guessing its size. |

### The rules that drove the shape of the fix

Every "shrink it to fit" option was rejected by CLAUDE.md §3, and that is the interesting part:

- **Tiles and buttons stop shrinking at 84px.** Below the 80x80 floor a coarse finger cannot hit
  them, so on a short screen things **wrap or move** instead of getting smaller.
- **Nothing scrolls.** A five-year-old should not have to discover that clothes exist off-screen,
  so the rail wraps into columns rather than gaining a scrollbar.
- **The rail never changes shape when a tab is tapped.** Every slot is laid out over the number of
  rows the *fullest* slot needs, so the layout does not rearrange under the child's hands.
- **The home button is never covered**, and no two targets overlap — two things a child can hit at
  once is the one thing this layout must not allow.

## Tests

`test/dress_the_dog_layout_test.dart` is new: 21 cases across five screen sizes, including the
892x412 emulator size this was reported on, plus a small 667x375 phone as the hard case.

Each size asserts no overflow, every control **and the dog** fully on screen, targets still >= 80px,
and no overlap between dog, rail, weather row and home button. Every slot tab is tapped, because
the rail is only as tall as its fullest slot.

`flutter analyze` clean; **81 tests pass** (`flutter test --exclude-tags render`).

Screens were rendered to PNG at 892x412, 667x375 and 1280x800 and looked at — the emulator size and
the tablet both read well. **At 667x375 the layout is correct but cramped**: everything fits and is
hittable, but the dog ends up small in the corner. That size is smaller than any target device and
was added as a stress case, not a target.

**Run on the Android emulator** (`district_pixel`, 1080x2400 at 420dpi = 914x411 logical), which is
where the bug was reported. The overflow stripe is gone; the dog is full size on the ground band,
all four slot tabs and their clothes are on screen, the weather buttons are back in one row along
the bottom, and the home button is clear in its corner. Tapping through the slot tabs and putting
wellies on the dog both work.

Two things the emulator showed that the widget tests could not, and both were fixed:

- **The weather buttons wrapped to three rows when there was width for one.** The wrap decision
  subtracted the dog's reserved share unconditionally, so it fired on a screen that had plenty of
  room. It now keeps a full row whenever one fits the space beside the rail.
- **Odd-numbered slots read as a stair-step**, because the item columns were centred independently.
  They are top-aligned now, so three boots read as a block with a gap at the end.

One pre-existing test moved with the layout: the "missed drop" case dragged to `Offset(700, 60)`,
which was empty sky under the old fixed layout and is now over the dog. It drags to the far corner
instead; what it asserts is unchanged.

## Not verified

- **Never run on the emulator or a device this session.** The overflow stripe is gone in widget
  tests and rendered screens at the exact reported size, but feel, real touch targets under a thumb,
  and the actual emulator have not been checked. `make run-emulator` is the next step.
- iOS not touched at all.
