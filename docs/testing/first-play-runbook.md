# First play — menu, Balloon Pop, parental gate

- Target: macOS desktop for a quick look; **an Android tablet or iPad for the real test**
- Last walked: 2026-09-17 — partially, in a browser only (see Results)

## Setup

```bash
flutter pub get
flutter run -d macos          # quick look
flutter run -d <device-id>    # the real test; `flutter devices` to list
```

## Steps

1. **App opens** → landscape, cream background, three big rounded tiles in a row. The left one
   (pink, party-popper icon) is vivid; the other two are washed out.
2. **Tap the pink tile** → Balloon Pop opens. Pale blue sky, ten empty dots top-left, big white
   home button top-right, a small Rive panel bottom-left.
3. **Balloons rise from the bottom** in six colours, drifting slightly sideways.
4. **Tap a balloon** → it pops (brief squash, then gone), a sound plays, one dot turns gold.
5. **Let a balloon reach the top** → it disappears silently. Nothing should change: no sound, no
   dot lost, no reaction at all.
6. **Pop ten** → confetti falls across the screen, the dots reset to empty, balloons pause about
   two seconds, then resume. There should be **no dialog to dismiss**.
7. **Tap the home button** → straight back to the menu, no confirmation.
8. **Tap a washed-out tile** → it wobbles and makes a soft sound, and does *not* navigate.
9. **Tap the settings cog** (top-right of the menu) → the gate appears: "Grown-ups only", a lock
   ring, Cancel.
10. **Tap the lock quickly** → nothing happens. **Press and hold 3 seconds** → the ring fills and
    settings opens. Sound and music switches, reset progress, and a privacy note; no name field.

## Kid-rules spot check

- Touch targets big enough under an actual child's finger? (Tiles 168, home button 96, balloon hit
  area ~120 logical px.)
- Any way to fail, lose, run out of time, or get stuck? There should be none.
- Home button visible from inside the game at all times?
- Does anything require reading, outside the gate and settings?
- Is the pop sound soft, or does it startle? **Expect this to fail** — the sounds are still the
  template's arcade effects.

## What a child did without instruction

Record: age, what they tapped first, whether they found the game unprompted, whether they got back
to the menu on their own, and anywhere an adult had to speak. **An adult having to explain anything
is a design bug, not a tester problem.**

_Not yet filled in — no child has used it._

## Results

**2026-09-17, browser only (headless Chrome against `flutter run -d web-server`).**

Steps 1–6 verified visually via screenshots, plus several hundred synthetic taps with no Dart
errors. Progress dots filled and reset, which proves celebrations fired. The Rive file loaded and
rendered.

Steps 9–10 are covered by widget tests (a quick tap does not pass; a full 3-second hold does)
rather than by hand.

**Not walked:** steps 7–8 by hand, anything on a real device, and every question about *feel*.
Two issues were found and fixed from screenshots: unfilled dots were invisible against the sky, and
the Rive placeholder was too big and sat in the play area.
