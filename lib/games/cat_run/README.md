# Cat Run

A cat runs left to right at one gentle speed, forever. A paw button jumps, a crouching-cat button
ducks. Things come past to jump over, duck under, bounce on and headbutt. Fish fill the progress
stars; a full row is a celebration and the world changes place. It never ends and it cannot be lost.

| File | What it is |
|---|---|
| `cat_run_game.dart` | The `FlameGame`: scrolling, collisions, the chime ladder, idle, celebrations |
| `cat_run_screen.dart` | The Flutter screen: the two play buttons, their quarter-screen hit areas, the home button |
| `world.dart` | **What comes next and when** — pure, seedable, and where every fairness rule lives |
| `obstacles.dart` | The obstacle data list, the miss styles, the scenes |
| `components/cat.dart` | The cat: the jump arc, the duck, the four slapsticks |
| `components/obstacle.dart` | One thing in the world, drawn as the thing it means |
| `components/scenery.dart` | Sky, clouds, hills, ground — three parallax layers, and the scene cross-fade |
| `components/prize.dart` | What pops out of a block, and the fish that fill the stars |
| `components/progress_fish.dart` | Progress toward the next celebration |
| `components/play_buttons.dart` | The paw and the crouching cat — the only instructions in the game |
| `assets.dart` | Every asset path, in one place |

## The one hard problem

**A runner with obstacles is failure-shaped**, and CLAUDE.md §3 forbids losing outright. This is the
biggest tension in the app so far, and it is resolved by keeping the obstacle and deleting the loss.

Every miss is slapstick the child will want to see at least once:

| Miss | What happens |
|---|---|
| Hit a fence, pot or log | Comic tumble, dust puff, lands on its feet, runs on |
| Missed a duck | Squashed flat for half a second, pops back into shape, runs on |
| Landed in the puddle | Belly-flop, sinks, floats back up, runs on |

Several children will deliberately farm the pancake, and that is a feature. The reason to play
*well* is moved entirely into a gradient of nicer outcomes — the chime ladder and what pops out of a
block — **with nothing at the bottom of it**. There is no life, no counter, no restart, no end.

## What keeps the timing fair

The nearest thing this app has had to a timer, so every one of these is load-bearing and pinned by a
test in `test/cat_run_test.dart`:

- **One speed, forever** (`CatRunWorld.scrollSpeed`). **There is no difficulty ramp anywhere** —
  nothing in `world.dart` or `cat_run_game.dart` reads elapsed time or distance to decide how hard to
  be, and a test proves the spacing distribution is identical after a very long session. A child
  still learning the jump must not be punished for staying.
- **A floor on the spacing** (`minGap`, 420px). Derived, not guessed: over double the distance the
  world travels during one jump arc, so a child who has just landed always gets a clear beat.
- **A much wider floor around a duck** (`duckGap`, 760px), because moving a thumb from one button to
  the other is the slowest thing a five-year-old does here. Duck obstacles are also rare
  (`duckInEvery`) and **never back-to-back** — a jump-and-duck pair in quick succession is out of
  scope, and a test pins it.
- **Every duck is telegraphed**: the cat's ears flatten progressively and a soft cue plays
  `duckTelegraph` (460px ≈ 2.4 seconds) before it arrives. A test pins that warning above two
  seconds — below that, ducking becomes a reaction test.
- **Late and early presses both work.** `Cat.coyoteTime` still jumps for 160ms after the cat has left
  the ground; `Cat.jumpBufferTime` remembers a press made at *any* point during a jump or a slapstick
  and fires it the moment the cat can act. The natural eager press is right after take-off — the
  furthest possible moment from the landing that will honour it — so the buffer deliberately spans a
  whole arc plus a recovery. A shorter window silently throws away exactly the press children make.
- **Hitboxes are more forgiving than the art** (`ObstacleKind.hitInset`). A jump that visually
  cleared the fence must never register as a bonk. The one exception is the block, whose box is
  *generous* the other way — it is a reward, so a near-miss headbutt should connect.
- **Leave it alone and the cat slows to a trot, then sits down and sniffs a flower**
  (`idleTimeout`). The world stops scrolling, so the child can look at something — this is what
  gives back the control a scrolling world takes away. Any press wakes it; there is nothing to
  dismiss.

## Decisions taken on the scope's open questions

All reversible, and all of them want a real child to settle. Recorded here so the next session knows
what was chosen rather than guessing from the code.

| Question | Taken | Why |
|---|---|---|
| Auto-run, or hold to run? | **Auto-run**, with the idle sit-down as the way to stop | Frees both thumbs for jump and duck; the idle answers the "stop and look at a butterfly" case without a third control |
| Two buttons, or tap-anywhere? | **Both** — two drawn buttons, but the whole bottom-left and bottom-right *quarters* are their hit areas | Keeps a place for duck while making the target as large as tap-anywhere in practice |
| Does a bonk reset the chime ladder? | **No.** It stops climbing until the next clean clear | A reset is the one place a miss could read as a punishment |
| How long before the scenery changes? | **Every celebration** (10 fish) | Too late and most children never see the beach |
| Is this cat the Rive character? | **No** — a shape-drawn cat | It does everything this game needs, and the jump arc is tuned against its exact body height. `lib/shared/rive_character.dart` stays ready and unused |
| Does duck earn its place? | **Kept, deliberately marginal** | Rare, slow, announced, and *not ducking one is not a failure* — the pancake is just funny. If a real child struggles with the button, cut duck obstacles to scenery and the game still works jump-only |

## Nothing is squashed

Mushrooms, snails and cushions **giggle, spring back and are still there afterwards**. Nothing
vanishes, nothing makes a pained noise, and the cat smiles through every bonk — a five-year-old reads
a hurt animal as real. A test pins that no bouncy thing has a painful miss style, and another that a
bounced mushroom is still mounted afterwards.

There are also **no pits, no enemies, no spikes, no darkness, no heights that read as dangerous and
nothing pursuing the cat**. A thing behind you that is catching up is pressure, which is the same
shape as failure.

## Placeholder art

Everything is drawn in code, but drawn *as the thing it means*: a fence has palings, a flowerpot has
a flower, a snail has a spiral shell and eye stalks. A child who cannot read has only the silhouette
to go on, so a grey rectangle would teach them nothing about which button to press.

`test/cat_run_render_test.dart` (tagged `render`) writes every posture and every obstacle to PNGs so
they can be looked at — including all four slapsticks, because whether a pancaked cat reads as funny
rather than hurt is the single thing this game must get right and no assertion can check it.

Real art lands in `assets.dart` and the `render` methods. **The sprite that replaces the cat must
keep the same body height and foot line**, or the clearances in `cat_run_game.dart` stop matching
what the child sees.
