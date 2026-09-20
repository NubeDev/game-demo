# Blast Off buttons are drawn over the rocket and the star jar

- Date: 2026-09-20
- Area: games/blast_off
- Status: resolved
- Session: ../../sessions/games/blast-off-controls-overlap-session.md

## Symptom

On Blast Off, the row of control buttons sits on top of the scene. The rocket
and the star jar are drawn *through* the buttons: the minus button covers the
rocket's body, and the star jar is behind the plus button and the GO button.

Reported from a dev window roughly 1068x348. Present at every size, but only
visible where the screen is short enough that the scene and the buttons want
the same pixels — on a tall tablet there is enough sky that the collision is
hidden rather than absent.

## Investigation

- **Not a z-order problem.** Raising the buttons above the game or lowering the
  scene changes which thing is on top, not the fact that they occupy the same
  space. A button on top of the rocket still hides it, and a rocket on top of
  the buttons hides those.
- **Not a Flame camera issue.** The scene has no camera transform; everything
  is laid out in screen coordinates directly.
- Measured what each side claimed. The scene: `LaunchPad.padTop` was
  `size.y - 70 - 12`, and the rocket (220 tall) and star jar (190) stand on it,
  so the scene occupied the bottom ~300px. The controls: `Positioned(bottom:
  24)` with a 132px GO button, so the buttons occupied the bottom ~156px. Both
  measured from the bottom edge, neither aware of the other.

## Root cause

The scene and the controls are laid out by two different layers — the Flame
game draws the rocket, the Flutter screen lays out the buttons — and **both
anchored themselves to the bottom of the canvas with hard-coded offsets**.
Nothing in either layer knew the other existed, so the overlap was not a bug in
either one; it was the absence of any agreement between them.

Worse than cosmetic: the rocket is *tappable* (it honks when poked,
`BlastOffGame.onTapDown`), so its hit area sat underneath the buttons. A tap
low on the rocket hit a control instead.

A second, narrower cause sat behind it. On a screen too narrow for one row, the
controls wrapped the presets onto a **second row**, making the band 268px tall.
On a landscape iPhone SE (375px) that leaves 107px of sky for a rocket that
needs at least 171px at its minimum legal size — so on that device the overlap
could not be fixed by moving the scene at all.

## Fix

One number passed between the layers, and one layout rule.

1. **`BlastOffScreen.controlsReserve(width)`** — the screen states the height
   its buttons own. It is the same for every countdown phase on purpose: a
   per-phase reserve would be tighter, but the ground (and the rocket standing
   on it) would visibly jump each time the phase changed.
2. **The grass grows to fill that band** (`LaunchPad.groundHeight`), so the
   buttons rest ON the ground and the rocket stands clear above it. The scene
   is placed relative to the pad rather than to the screen's bottom edge.
3. **The grass stops growing** once the sky left would no longer hold the
   smallest legal rocket, and the rocket and jar then scale down to fit
   (`LaunchPad.sceneScale`), floored at 80/120 so the rocket — a touch target —
   never drops below 80px wide (CLAUDE.md §3).
4. **The controls are now always one row.** When the row will not fit, the ±
   step buttons drop out instead of the layout gaining a second line. The
   presets still reach every length, so nothing becomes unreachable and the
   child's route (pick a picture, press GO) is untouched.

Point 4 is what makes iPhone SE work: the band is 182px at every width, leaving
193px of sky where the scene needs 171px.

## Regression test

[`test/blast_off_layout_test.dart`](../../../test/blast_off_layout_test.dart) —
pins the contract directly: at every target size the rocket's feet are above the
top of the control band, the rocket is still fully on screen, and it never
scales below the 80px touch-target floor. Also pins that the reserve does not
change with width, which is what would silently return if a second row crept
back in.

[`test/blast_off_screen_test.dart`](../../../test/blast_off_screen_test.dart) —
pins that the presets and GO never drop, that the steppers are what goes on a
narrow screen, and that no control is *painted* below 80px after the FittedBox
has scaled the row.

## What is still not proven

Nothing here was run on a device. The layout is proven by test and by rendered
screenshots at three sizes; how the shorter rocket *feels*, and whether an adult
misses the ± buttons on a phone, needs hands.
