# Games — Crystal Party, first playable slice (session)

- Date: 2026-09-20
- Scope: [../../scope/games/crystal-party-scope.md](../../scope/games/crystal-party-scope.md)
- Status: playable, placeholder art; **driven in a desktop browser, never under a thumb** — see Tests

## Goal

Build the seventh mini-game, and the second **journey** rather than a place. Cat Run proved that a
scrolling world with something coming up ahead is the most exciting thing in this app; this one
keeps that frame and changes the verb.

Cat Run is a **moment** — a fence is coming, press now. Crystal Party is a **height**: hold the
screen and the unicorn lifts off on a rainbow, let go and she drifts back down to a gallop. There is
no right instant to find, so there is no instant to miss.

## Two decisions taken before building

The scope left nine open questions. Seven have a clear default in its own *What* section and were
built that way. Two genuinely changed the shape of the code, and were settled with the maintainer:

- **Does either colour fill the whole arch, or does it need both sides?** → **Both sides, quietly
  helped.** The arch has a blue half and a pink half, so flying has an actual shape: you have to go
  up sometimes. Safe only because of the quiet help (below).
- **How long is a land?** → **12 crystals, six a side.** About a minute of flying, close to Cat
  Run's ten fish so the app's rhythm stays consistent, and short enough that a child actually
  reaches the snowy mountain in one sitting. It is one constant, deliberately.

## What changed

New game under `lib/games/crystal_party/` — see its
[README](../../../lib/games/crystal_party/README.md) for the file-by-file table.

Wiring outside the game:

| File | Change |
|---|---|
| `lib/router.dart` | The `/crystal-party` route |
| `lib/menu/home_screen.dart` | **Rewritten layout.** The games are now a list, and the menu lays them out in one row or two |
| `lib/shared/kid_palette.dart` | A seventh play colour (teal), so no two tiles share one |

### The menu had to change, and why

The menu was a hand-written `Row` of six tiles with a comment saying seven would not fit a small
landscape phone. It was right: at `GameTile.minSize` (88 — the kid-rule floor) plus any gap at all,
seven across overflows a 640px-wide phone.

Three options, two of which break a rule:

- a smaller tile → breaks the 80×80 kid rule;
- a scrolling row → breaks "everything visible at once"; a five-year-old does not know content
  exists off-screen;
- **a second row** → breaks nothing.

So `_MenuLayout.fit` prefers one row, falls back to two, and **never shrinks the tile below the
floor** — the spacing gives way instead. It is a pure class so the rule it protects is testable
without pumping a widget, and the layout test asserts every tile clears 80×80 on all five target
sizes.

## The one hard problem

**"Collect them all" is a completion goal, and completion invites being incomplete.** A child who
reaches the end of a land three crystals short has failed, however gently it is phrased — and
CLAUDE.md §3 forbids that outright.

Resolved by making completion **guaranteed rather than earned**, in three mechanisms that only work
together:

1. **A missed crystal is not missed** — fly past one and the same colour is owed back into the run
   ahead (`_owed`, drained by `_placeThings`).
2. **The land does not end until the arch is full** — there is no distance, no timer, no end of
   level. The only thing that finishes a land is the arch filling.
3. **The quiet help** — a colour that falls behind starts appearing more often *and lower down*
   (`helpingColour`, `helpedPinkHigh`). A child who never works out the hold still fills the pink
   side. Never announced; nothing on screen says it happened.

## Flying implies falling, so the falling was engineered out

Every piece of the "flying kills you" machinery is deliberately absent. The load-bearing numbers:

| Rule | How |
|---|---|
| No falling | `fallSpeed` (165) is **slower** than `riseSpeed` (300) — a leaf, not a stone |
| No ceiling to bump | The climb tapers over the top `_easeBand`, so the sky ends in a settle, not a wall |
| No ground slam | Every landing is soft, on four hooves, from any height; `_land()` has no failure branch |
| No bottom of the screen | `airHeight` is never negative |
| No flight meter | Nothing drains; holding is the only limit |

A **two-second hold reaches the highest crystal** — the scope's ceiling on a small hand, and the
number the sky's height is derived from rather than guessed at.

## A bug the first version of the quiet help had

The helped-pink ceiling was first written as `0.5` while `pinkLow` is `0.55` — so the "helped" range
inverted, and a helped pink crystal would have been placed **below the blue band**. That quietly
destroys the one thing the colours exist to teach.

Caught by the test that asserts a helped pink is still inside the pink band. The fix: help lowers
the **ceiling only** (to `0.68`), never the floor. A shorter hold, not a free one.

## Tests

`flutter analyze` clean. **441 tests pass**, 36 of them new:

| File | What it pins |
|---|---|
| `test/crystal_party_test.dart` | The flight model, the world's fairness rules, the quiet help, the arch, the lands, the chime ladders, and the whole game end to end |
| `test/crystal_party_layout_test.dart` | The control and the home button on five screen sizes — **and every menu tile clearing 80×80 now there are seven** |
| `test/crystal_party_screen_test.dart` | A **real hold through the real widget tree**, and that the home button's band does not fly her |
| `test/crystal_party_render_test.dart` | That she is drawn higher when flying, that blue and pink differ **in silhouette alone**, and that an empty arch is still visible |
| `test/smoke_test.dart` | New: **no two games share a tile colour or icon** |

Two of those exist because the thing they test was broken:

- **The widget-tree hold test.** `onTapDown` alone does not fire until a press resolves, so a hold
  built from taps would not lift her until the child let go — and every unit test would still pass.
- **The empty-arch render test.** See below.

### Five real bugs, and what caught each

| Bug | Caught by |
|---|---|
| Concurrent-modification crash the first time anything scrolled off the left edge | Driving a **fully mounted** game in tests, not a hand-booted one |
| Effect applied to a crystal taken in the same frame it was added | The same |
| Helped pink placed below the blue band | The quiet-help test |
| **The arch painted nothing at all until the first crystal** — so it was invisible at the start of every land, and half the design did not happen | **Looking at the running app**. No test asked whether it was visible, because I had not thought to |
| **The arch was a paper fan**, filling the disc and covering the pink crystals' sky | The same |

The last two are the point of CLAUDE.md §6. A green suite said the arch had the right size and
position; it did, and it still was not there.

## Run

`flutter build web` compiles the whole app. The built app was then **driven in headless Chrome over
the DevTools protocol**: menu → `/crystal-party` → hold → release → watch, with screenshots.

Confirmed by eye: she gallops, a hold lifts her into the clouds trailing a rainbow, a release floats
her back down onto four hooves, blue crystals sit at hoof height and pink ones in the sky, the arch
stands unfinished on the horizon and fills with solid rainbow as crystals go in, and the waterfall,
rainbow puddle, sheep, dragon and rabbits all render. **Zero page errors.**

A second, longer run played a **whole land through to the party**: alternating holds and releases for
two minutes filled both sides of the arch, and the screenshots show the trail behind her as
alternating blue shards and pink blobs (progress visible twice, with no number anywhere), the arch
completing with one ghost piece left, and then **the next land** — the beach, with sand and shallow
water — with the arch reset to ghosts and the trail emptied. The whole loop works end to end.

Two notes on that run:

- Headless Chrome throttles `requestAnimationFrame` to nothing by default, and the first pass of
  screenshots showed a **frozen world** that looked exactly like a broken game. It needs
  `--disable-background-timer-throttling`, `--disable-renderer-backgrounding` and friends.
- A bare `Input.dispatchMouseEvent` does not reach Flutter web's gesture arena; it needs
  `pointerType` and a small move, or the hold appears to do nothing.

What is still unjudged from stills: **the party is specified as a slow swell** for photosensitivity
reasons, and whether it reads as slow is a motion judgement. Nobody has watched it move.

**Not done: no run on a phone or tablet.** Only iOS and Android ship, and neither was available —
`flutter devices` offers only Linux desktop (no Ninja/C++ toolchain here) and Chrome. Feel, target
size and sound are still unproven under a thumb.

## Open questions left for a real child

Unchanged from the scope, and none of them settleable here: hold vs tap-to-flap; whether a
five-year-old's thumb tires before the arch fills; whether a land is one celebration's worth or
three (shared with Cat Run); whether anything needs avoiding at all; a third crystal colour; and
whether this is finally the Rive character's job.
