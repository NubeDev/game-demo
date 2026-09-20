# Games — Cat Run (scope)

- Date: 2026-09-20
- Status: proposed
- Session: (none yet)

## Why

The third mini-game, and the first one with **timing** in it. Balloon Pop is a tap game and Dress
the Dog is a toy; neither ever asks the child to act *at a moment*. Here something is coming, and
the child presses at the right time and the cat sails over it. That leap — the crouch, the arc, the
landing — is the whole game, and at five it is a genuinely new skill to practise.

The ask was "like Mario, jumping over and under things", and that is exactly what a five-year-old
wants from Mario: not the levels, not the lives, the *jump*. So we give them the jump and the
scrolling world and the pop-out blocks, and change the one part we cannot keep. In Mario the jump
matters because missing it kills you. Here, **missing is funny instead of fatal** — the cat bonks,
tumbles, lands on its feet and carries on — and the reason to jump well moves into what you get
when you do: a rising chime, a fish, a butterfly out of a block.

## What

- **A cat that runs by itself**, left to right, at one gentle speed that never increases, across a
  side-on world that scrolls past. The child never steers.
- **Two huge picture buttons in the bottom corners** — a paw to **jump** (right thumb), a crouching
  cat to **duck** (left thumb). That is the entire control scheme.
- **Things to jump over:** a fence, a flowerpot, a wobbly log, a puddle.
- **Things to duck under:** a low pipe, a hanging branch, a washing line of socks. These arrive
  **rarely and slowly**, and are announced before they appear — the cat's ears flatten and the
  music dips a bar — so the child has time to see it coming and find the other button.
- **Things to bounce on:** a wobbly mushroom, a snail, a springy cushion. Land on one and it
  **giggles and launches the cat high** — the Mario stomp, minus anything being squashed.
- **Blocks overhead to headbutt.** Jump into one and something pops out: a butterfly, a fish, a
  music note, a shower of leaves.
- **Missing has three outcomes, all of them keep going:**
  - hit a fence — comic tumble, dust puff, lands on its feet, soft "boing", runs on;
  - miss a duck — squashed flat like a pancake for half a second, pops back into shape, runs on;
  - land in the water — belly-flop, splash, a duck floats the cat back up, runs on.
- **A rising chime for a clean run.** Each thing cleared without a bonk is a note higher than the
  last — the same ladder as Balloon Pop's pops. This is the entire reward gradient: no score, no
  number, nothing that can go down and be noticed.
- **Fish collected along the way fill the progress stars.** Full row → the shared celebration →
  **the scenery changes** (garden → beach → snow) and it carries on forever. There is no end.
- **A tap a moment too late still jumps**, and a tap a moment too early still jumps when the cat
  lands. Late and early both work; the child should never feel their press was ignored.
- **Leave it alone and the cat slows to a trot, then sits down and sniffs a flower.** It does not
  keep running into things while nobody is playing.
- The shared **home button** in the usual corner, well away from the two play buttons so it cannot
  be hit mid-jump.

Lives in `lib/games/cat_run/`. Obstacles are a data list, not hand-placed levels. Placeholder art
is shape-drawn — a blob cat, coloured-block fences, a rectangle pipe — so the jump can be felt and
tuned long before any real artwork exists. Asset paths collected in one `assets.dart`.

## Not this

- **No pits, no falling off the bottom of the screen, no lives, no health, no restart, no
  checkpoint, no game over.** The run never stops for any reason but the home button.
- **No score, no distance, no coin count, no "1-1", no timer, no stars that can be missed.**
- **No difficulty ramp.** It does not get faster, denser or harder the longer they play. A child
  who is still learning the jump must not be punished for staying.
- **No enemies.** Nothing chases the cat, nothing hurts it, nothing is stomped out of existence.
  Anything the cat lands on bounces, giggles and is still there afterwards.
- **No spikes, no lava, no darkness, no heights that read as dangerous, nothing pursuing them.**
  A thing behind you that is catching up is pressure, which is the same shape as failure.
- **No levels to unlock, no world map, no boss, no collection to complete.**
- **No tilt, no swipe, no D-pad, no run button, no two-finger anything.** Two buttons, one thumb
  each.
- **No jump-and-duck demanded back-to-back** faster than a small child can move a thumb across.

## Kid-rules impact

- **A runner with obstacles is failure-shaped, and this is the biggest tension in the app so far.**
  Resolved by keeping the obstacle and deleting the loss: every miss is a slapstick outcome the
  child will want to see at least once, and several will deliberately farm the pancake. The reason
  to play *well* is moved entirely into the chime ladder and what pops out of blocks — a gradient
  of nicer outcomes, with nothing at the bottom of it.
- **Timing pressure is the nearest thing to a timer this app has had.** Resolved: one fixed gentle
  speed forever, a floor on the spacing between obstacles, every duck telegraphed a beat early, and
  an idle cat that sits down rather than running on alone. Nothing is ever missed by being slow —
  only by pressing at the wrong moment, which costs a tumble and nothing else.
- **Duck is meaningfully harder than jump at five.** Resolved: duck obstacles are rare, slow and
  announced, and **not ducking one is not a failure state** — the branch knocks the cat's hat off,
  that is all. If a real child struggles with the button at all, the fix is to cut duck obstacles
  to scenery and leave the game jump-only; it still works.
- **Bouncing on a creature risks reading as hurting it.** Resolved under *Not this*: mushrooms and
  snails giggle, spring back and stay on screen. Nothing is squashed, nothing vanishes, nothing
  makes a pained noise — a five-year-old reads a hurt animal as real.
- **A scrolling world takes control away from the child**, which no other game here does. Resolved
  by the idle behaviour: stop pressing and the world stops. They can always look at something.
- **No text anywhere.** The two buttons are a paw and a crouching cat. No world numbers, no labels,
  no "GO".
- **Touch targets:** both buttons ~140×140 in the bottom corners, and the whole bottom-left and
  bottom-right quarters of the screen act as their hit areas, so a mis-aimed thumb still works. The
  home button stays in its usual corner, far from both.
- **Nothing startling:** no sudden loud noises, no flashing, no strobing. Tunnels dim, they never
  go black.

## Open questions

- [ ] **Auto-run, or hold a button to run?** Auto-run is simpler and frees both thumbs for jump and
      duck, but a child who wants to stop and look at a butterfly currently cannot, except by doing
      nothing and waiting for the idle. Owned by the first real-child session.
- [ ] **Does duck earn its place at all,** or is this a jump-only game with low branches as
      decoration? Decide on a device, with a child, not in this file.
- [ ] **Two buttons, or tap-anywhere-to-jump?** Tap-anywhere is the largest possible target and
      needs no discovery, but it leaves nowhere to put duck.
- [ ] **Does a bonk reset the chime ladder, or just fail to advance it?** A reset is the one place
      a miss could read as a punishment. Leaning towards: it does not reset, it simply stops
      climbing until the next clean clear.
- [ ] **How long before the scenery changes** — one celebration, or three? Too soon and the world
      never settles; too late and most children never see the beach.
- [ ] **Is this cat the Rive character** (`lib/shared/rive_character.dart`), and does a
      side-scrolling runner finally give that plumbing a real job, or does a shape-drawn cat do
      everything this game needs?
- [ ] **How many kinds of obstacle** before it is enough to stay interesting, and how many before
      it stops being predictable?

## Done when

A child who has never seen it presses the paw, works out within a few seconds that it makes the cat
jump, clears a fence, bonks into the next one and laughs, hears the chime climb when they get three
in a row, fills the stars, sees the world turn into a beach, and plays on or leaves when they feel
like it — with no adult speaking, nothing to fail, and no moment at which they look like they have
just lost.
