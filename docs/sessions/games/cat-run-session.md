# Games — Cat Run, first playable slice (session)

- Date: 2026-09-20
- Scope: [../../scope/games/cat-run-scope.md](../../scope/games/cat-run-scope.md)
- Status: playable, placeholder art; **never run on a device or in a browser** — see Tests

## Goal

Build the third mini-game, and the first one with **timing** in it: a cat that runs by itself,
jumps over and ducks under things, bounces on creatures and headbutts blocks — and **never loses**.

The scope calls this "the biggest tension in the app so far", and it is: a runner with obstacles is
failure-shaped, and CLAUDE.md §3 forbids losing outright. Most of the work below is about that
tension rather than about the runner.

## What changed

New game under `lib/games/cat_run/`:

| File | What it is |
|---|---|
| `obstacles.dart` | `ObstacleKind` (11 obstacles as **data**), `ObstacleAction`, `MissStyle`, `BlockPrize`, `Scene` |
| `world.dart` | `CatRunWorld` — pure and seedable: what comes next, when, and every fairness rule |
| `cat_run_game.dart` | The `FlameGame`: scrolling, collisions, the chime ladder, idle, celebrations |
| `cat_run_screen.dart` | The two play buttons, their quarter-screen hit areas, the home button |
| `components/cat.dart` | The cat: jump arc, duck, four slapsticks, ear telegraph |
| `components/obstacle.dart` | One thing in the world, drawn as the thing it means |
| `components/scenery.dart` | Three parallax layers and the scene cross-fade |
| `components/prize.dart` | `Prize` (what pops out of a block) and `Fish` (fills the stars) |
| `components/progress_fish.dart` | Progress toward the next celebration |
| `components/play_buttons.dart` | The paw and the crouching cat, drawn not fonted |
| `assets.dart` | Empty of paths; says what real art must preserve |
| `README.md` | Why the game is built this way, and the open questions decided |

Wired in: a `/cat-run` route in [`lib/router.dart`](../../../lib/router.dart) and a menu tile in
[`lib/menu/home_screen.dart`](../../../lib/menu/home_screen.dart).

## How "no losing" was actually built

Keeping the obstacle and deleting the loss. Every miss is slapstick — a tumble, a pancake, a
belly-flop — and the cat always lands on its feet and runs on. There is no life, no counter, no
restart, no checkpoint and no end. The reason to play *well* moved entirely into the chime ladder and
what pops out of a block: a gradient of nicer outcomes with nothing at the bottom of it.

Two decisions worth recording:

- **A bonk does not reset the chime ladder**, it only stops it climbing until the next clean clear.
  The scope leaned this way; a reset is the one place a miss could read as a punishment.
- **The bonk gets a *nicer* response than silence** — a soft cue and a puff of dust — because it is
  meant to be funny rather than something to avoid. There is deliberately **no haptic** on it: a
  physical jolt after a mistake is punishment, however small.

## The fairness numbers, and where they came from

Derived rather than guessed, and each pinned by a test:

- `minGap` (420px) is over **double** the distance the world travels during one jump arc
  (`scrollSpeed × jumpDuration` = 163px), so a child who has just landed always gets a clear beat.
- `duckGap` (760px) is much wider, because moving a thumb across the screen is the slowest thing a
  five-year-old does here. Duck obstacles are also rare and **never back-to-back**.
- `duckTelegraph` (460px) is ≈2.4 seconds of warning at the one fixed speed. A test pins it above two
  seconds; below that, ducking becomes a reaction test.
- **No difficulty ramp anywhere.** A test runs the spawner 400,000px into a session and checks the
  gap distribution is within 15% of the start — because nothing in `world.dart` reads elapsed time or
  distance at all.

## A real bug the tests caught

The first version of `Cat.jumpBufferTime` was 0.22s — "a press just before landing is remembered".
The test for an early press failed, and it was right to: the **natural** eager press is right after
take-off, which is the *furthest* possible moment from the landing, so a 0.22s window silently threw
away exactly the press children actually make. It now spans a whole jump arc plus a recovery
(`jumpDuration + recoveryDuration`), so a press made at any point during a jump or a slapstick fires
the moment the cat can act on it.

This is the kind of thing that would have read to a child as the game ignoring them, and it would
never have shown up in a screenshot.

## A surprise: a second agent in the same checkout

Part way through, `lib/menu/home_screen.dart` and `lib/router.dart` changed under this session — a
fourth game, **Blast Off**, appeared with its own scope, screen, game, test and route. Another
session is working in this checkout concurrently.

Nothing of Cat Run was lost (both tiles and both routes survived), but two things needed fixing:

- a doc comment for `_games` had landed *inside* the `HomeScreen` class docstring — moved out;
- `test/smoke_test.dart` still asserted exactly 3 menu tiles. Rather than bumping it to 4, it now
  asserts that there **are** tiles and that **none of them is a `comingSoon` placeholder** — the
  property that actually matters, and one that does not fail every time a game is added.

Worth knowing for the next session: this checkout is not necessarily exclusive.

## Tests

`test/cat_run_test.dart` — 30 tests, all passing. The ones that matter are the kid-rule invariants,
not the mechanics:

- the jump clears the **tallest jumpable obstacle** plus 30px of margin — so adding a taller
  obstacle fails this test rather than quietly making it unclearable;
- the ducked cat fits under every duck obstacle, and a *stabbed* duck (pressed and released at once)
  still lasts long enough to pass under;
- **every** `MissStyle` ends with the cat upright and running — there is no slapstick that can strand
  it, and a bonk cannot interrupt a bonk;
- the spawner never goes below its gap floors, never puts two ducks together, and does not get
  harder over a very long run;
- every fish is within reach of a jump (a fish that could not be got would be the one missable thing
  in the game);
- hitboxes are narrower than the art, except the block, which is deliberately generous;
- no bouncy creature has a painful miss, and a bounced mushroom is **still on screen afterwards**.

`test/cat_run_layout_test.dart` — 26 tests across five landscape sizes down to 667×375: no overflow,
both buttons and the home button fully on screen, every target ≥80×80, the home button a clear 40px
margin from both play buttons, the two buttons in the correct opposite corners, and **a tap well away
from the drawn paw still counted** (the quarter-screen hit area).

`test/cat_run_render_test.dart` (tagged `render`) — writes every cat posture, all four slapsticks and
all 11 obstacles to PNGs. Not a golden test; it exists so a human can answer the question no
assertion can: does the pancaked cat read as *funny* rather than hurt?

Whole gate: `flutter analyze` clean, **157 tests passing**, `make privacy` clean.

## What is NOT proven

- **Never run on a device, an emulator, or in a browser.** This session had no device and no working
  browser target to hand. The game has never been seen moving — the scrolling, the parallax, the
  jump arc under a thumb and the scene cross-fade are all unverified in motion.
- **The jump has never been felt.** `jumpRise`, `jumpDuration`, `coyoteTime` and `jumpBufferTime` are
  reasoned and tested but not *played*, and the whole game is that one arc.
- **No sound was heard.** The chime ladder reuses Balloon Pop's three-rung `kid_pop` samples, so the
  "rising chime for a clean run" currently has only three rungs — the same open thread as Balloon
  Pop's pop ladder (no mp3 encoder on this machine).
- **The duck telegraph has never been watched.** Whether flattening ears read as a warning to a real
  five-year-old is exactly the kind of thing only a child can settle.
- **Whether a child works out the crouch button at all.** The scope's fallback stands: if they
  cannot, cut duck obstacles to scenery and the game still works jump-only.

## Kid-rules check

- [x] **Could a child who cannot read do this?** No text anywhere. Two picture buttons, both drawn
      rather than fonted because no Material icon says "crouch".
- [x] **Every touch target ≥80×80, with space around it?** Buttons are 140 drawn, with the whole
      bottom-left and bottom-right *quarters* as their hit areas. Pinned at five screen sizes.
- [x] **Any way to lose, fail, run out of time, or get stuck?** No. Every miss is slapstick that ends
      with the cat running; no pits, no lives, no timer, no difficulty ramp, no end.
- [x] **Home button visible?** Top-right as always, and tested to be a clear margin from both play
      buttons so it cannot be hit mid-jump.
- [x] **Any new network call, SDK, or stored personal data?** None. `make privacy` clean.
