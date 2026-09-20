# Games — Quacky the Duck (scope)

- Date: 2026-09-20
- Status: proposed
- Session: (none yet)

## Why

The eighth mini-game, and the first one where **there is something ahead that the child wants and
cannot reach yet**.

Quacky is a grumpy old duck in a park. Not a nasty duck — a *grumpy* one, the way a very small
person is grumpy: loudly, and about food. He has strong opinions about bread and he is not getting
enough of it. Up ahead on the path there is always a child swinging a paper bag, or another duck
with a crust in its beak, and Quacky is going to catch up with them. He mutters the whole way.

Anyone who has taken a five-year-old to a park has met this duck. There is always one — bossy,
unbothered, shouldering past the polite ducks, honking at a pram. The child has *seen* this
happen. That is the whole appeal: it is not a fantasy world, it is the funny thing that happened
at the pond, and now they are the duck.

The verb is new for this app. Balloon Pop is where to tap, Dress the Dog is which to pick, Cat Run
is when to press, Blast Off is how long to wait, Car Trip is holding a line, Neil the Seal is
choosing a place, Crystal Party is where in the sky to be. Quacky is **closing a gap** — there is
a thing up there, it is not here yet, and pushing makes it arrive sooner. It is pursuit, which is
the most naturally motivating shape a game has and also the most dangerous one under our rules,
because pursuit normally comes with getting away. So the bread never gets away. See
*Kid-rules impact*; that one decision is the game.

It is also the first game where the **world answers back socially**. The cat's fences do not care
about the cat. Here, a child in the park turns round, sees a cross duck bearing down on them at
full waddle, shrieks with laughter and tips the bag out. Being noticed — being the thing everyone
in the park reacts to — is its own reward at five, and no other game here offers it.

## What

- **A duck that waddles by himself**, left to right, at one gentle speed that never increases,
  across a side-on park that scrolls past. The child never has to make him go.
- **Always something up ahead to chase**: a child swinging a bread bag, a duck with a crust, a
  toddler dropping crumbs from a pushchair, a pigeon who has found half a sandwich. One at a time,
  always visible on the path in front, always getting closer.
- **Two huge picture buttons in the bottom corners** — a cross little duck face to **DASH**
  (bottom-right), a flattened duck to **DUCK** (bottom-left). Same hands as Cat Run, on purpose:
  left is always "get low", right is always "go", across the whole app.
- **Dash**: press or hold the right side and Quacky puts his head down, wings out, feet going like
  mad, and scrambles up the path in a cloud of feathers with an indignant honk. Let go and he
  settles back to a waddle. Short bursts; nothing needs holding down for long.
- **Duck**: press the left side and he flattens his neck and skids along on his belly, under the
  thing in the way.
- **Things to duck under**: a park bench, a low gate, a washing line of towels, a picnic rug being
  shaken out, a sprinkler, a dog's lead stretched across the path. They arrive **rarely and
  slowly**, and are announced before they appear — Quacky's neck stretches out flat and the music
  dips a bar — so the child has time to see it and find the other button.
- **Catching up is the whole event.** Close the gap and the thing ahead turns round: the child
  squeals with laughter and tips out a crust, the other duck shares half, the pigeon gives up the
  sandwich with bad grace. Quacky gobbles it with an enormous CHOMP and a triumphant QUACK that is
  the best noise in the game.
- **Every crust makes Quacky less grumpy.** His eyebrows lift a notch, his mutter softens, his
  waddle gets bouncier. This is the reward gradient and it is drawn on his face — the child can
  see the whole state of the game by looking at the duck.
- **A row of bread rolls at the top fills as he eats.** Full row → the shared celebration →
  Quacky beams, does a delighted flappy spin in the fountain, every duck in the park quacks at
  once, and **the park changes** (pond → bandstand → playing field → allotments) and it carries on
  forever. There is no end.
- **Missing a duck is slapstick, not a failure**: he bonks his beak on the bench, spins round in a
  huff with a puff of feathers, shakes himself, mutters, and carries on. The thing he was chasing
  waits for him.
- **Things to bump into for fun** along the way: a wobbly bin that rattles, a puddle that splashes,
  a flock of pigeons that explodes upwards and settles again, a deckchair that folds up on itself.
  None of them stop him.
- **Leave it alone and Quacky slows to a stop, sits down on the path and grumbles to himself.**
  The park stops with him. Any press starts him off again.
- The shared **home button** in the usual corner, well away from both play buttons.

Lives in `lib/games/quacky_the_duck/`. The chase targets and the things to duck under are data
lists, not hand-placed levels. Placeholder art is shape-drawn — a fat oval duck with an orange
triangle beak and two cross eyebrow lines, block benches, blob children — so the dash and the
gobble can be felt and tuned long before any real artwork exists. Asset paths collected in one
`assets.dart`.

## Not this

- **The bread never gets away.** There is no target that escapes, no gap that becomes
  unrecoverable, no "too slow", no one running off with the bag. Dashing makes the crust arrive
  *sooner*; it is never the condition for it arriving. A child who never once touches the dash
  button eats every single crust in the game, just at a gentler pace.
- **No race, no timer, no finish line, no rival duck who gets there first.** Nothing in the game
  reads elapsed time to decide an outcome.
- **No score, no crust count as a number, no distance, no "best run", no stars that can be missed.**
- **No difficulty ramp.** It never gets faster, denser or harder the longer they play.
- **Nothing chases Quacky.** No dog let off the lead, no swan, no angry park keeper, no goose. A
  thing behind you that is catching up is pressure, which is the same shape as failure — Cat Run
  settled this and it stays settled.
- **Nobody is frightened of him and nothing is taken.** No child cries, screams in fear, or runs
  away to get away. No pecking, no biting, no snatching from a hand. Every crust in this game is
  **given**, laughing, on purpose. Quacky arrives at their heels and they feed him.
- **Quacky is never cross with the player** and never cross with a *child*. His grumpiness is aimed
  at the world in general and at the unfairness of not having bread yet. Nothing scolds, nothing
  tuts, nothing shakes its head at the player.
- **No water to fall in, no drowning, no going under.** The pond is ankle deep and splashy. A duck
  in water is a duck having a nice time.
- **No pits, no lives, no health, no restart, no checkpoint, no game over.** The waddle never stops
  for any reason but the home button.
- **No levels to unlock, no world map, no boss, no collection to complete.**
- **No tilt, no swipe, no D-pad, no flying, no two-finger anything.** Two buttons, one thumb each.
- **No duck-and-dash demanded back-to-back** faster than a small child can move a thumb across.

## Kid-rules impact

- **A chase is pressure-shaped, and this is the central tension of the ask.** Pursuit implies a
  gap that can fail to close, and that is a loss with a friendly face on it. Resolved by taking the
  outcome out of the chase entirely: **the target slows down, stops to look at a dog, trips over
  its own feet giggling, and waits.** Quacky always catches up. The dash is a throttle on *when*
  the nice thing happens, never on *whether* it happens. This is the same trick as Cat Run's
  slapstick — keep the exciting shape, delete the loss underneath it — and if a future session ever
  makes a target genuinely outrun the player, this game has quietly grown a fail state.
- **"Chases children" could read as menacing, and it must not.** Resolved in the body language,
  which has to be got right in the art and not just in the code: the children run *backwards*,
  facing him, waving the bag, laughing. Nobody flees. Nobody cries. The moment of contact is a
  shared joke — they turn and tip the bread out deliberately. A five-year-old reads a frightened
  child as real, exactly as they read a hurt animal as real.
- **"Grumpy" could read as angry, and angry is scary.** Resolved by making the grumpiness the
  *joke* rather than the mood: cross little eyebrow lines, an outraged honk, a mutter. And it is
  the thing the child is fixing. Every crust softens him a notch, so the arc of a round is
  **cheering a grumpy duck up**, which is a job a five-year-old will take extremely seriously.
- **A face as a progress meter must never go backwards mid-round.** Resolved: within a round it
  only ever climbs. It resets at the celebration, alongside a new park and a fresh appetite — but
  a reset is still a decrease, so it is flagged as an open question below. The bread-roll row at
  the top follows the app's existing rule (filling pictures, no number, never decreasing).
- **Duck is meaningfully harder than jump at five**, which Cat Run learnt. Resolved the same way:
  duck obstacles are rare, slow and telegraphed a beat early, and **not ducking one is not a
  failure state** — it is a beak-bonk and a puff of feathers. If a real child struggles with the
  button, the fix is to demote the benches to scenery and leave the game dash-only; it still works.
- **Holding a button tires a small hand**, which Crystal Party flagged. Resolved: the dash is a
  burst, not a sustained hold. A single tap gives a full burst; holding just chains them.
- **A scrolling world takes control away from the child.** Resolved by the idle behaviour: stop
  pressing and Quacky sits down and the park stops. They can always look at something.
- **Bread is not actually good for real ducks**, and a parent may well know that. Resolved cheaply
  and charmingly: the bag also has peas, sweetcorn and lettuce in it, and the park has a duck-food
  dispenser. No lecture, no text, nobody is corrected — the good food is simply *also* there and is
  the nicest-sounding chomp.
- **No text anywhere.** The buttons are a cross duck and a flat duck. Progress is bread rolls. The
  parks are pictures.
- **Touch targets:** both buttons ~140×140 in the bottom corners, with the whole bottom-left and
  bottom-right quarters of the screen acting as their hit areas, exactly as Cat Run does — a
  mis-aimed thumb still works. The home button keeps its usual top-right corner, far from both.
- **Nothing startling:** the honk is comedy, not a horn, and never louder than the celebration. No
  sudden loud noises, no flashing, no barking dog, no strobing. The flock of pigeons is a flutter,
  not a bang.

## Open questions

- [ ] **Does Quacky's face reset to grumpy after a celebration?** Going back to grumpy is a visible
      decrease, which the rules distrust. The alternatives are: he stays happy forever and the meter
      becomes something else; or each new park gives him a *fresh* small grievance, so the reset
      reads as a new joke rather than lost ground. Leaning towards the fresh grievance. Owned by
      the first real-child session.
- [ ] **Is the dash a burst or a hold?** A burst is kinder on a small thumb and impossible to get
      wrong; a hold gives finer control over the gap and is more satisfying. Only a real hand
      settles it.
- [ ] **Does duck earn its place at all,** or is this a dash-only game with benches as decoration?
      Cat Run is still asking the same question. Decide on a device, with a child.
- [ ] **How close does "caught up" need to be?** Touching them, or just getting near? Touching is
      clearer; near is far more forgiving and avoids any frame where a duck is pressed against a
      child.
- [ ] **Should the child ahead ever hand bread over *before* being caught** — a crust dropped out of
      the bag on the way — so a child who is not dashing at all still gets something every few
      seconds? Probably yes, and it may be what makes the no-fail promise actually feel true.
- [ ] **Are the other ducks rivals or friends?** A duck with a crust that Quacky takes it from is
      the ask as written, but it is the one place in the game where something is lost by someone.
      Sharing is safer and slightly less funny.
- [ ] **Is Quacky the Rive character** (`lib/shared/rive_character.dart`)? A face that runs a mood
      from furious to delighted, driven by one bound number, is the most natural job that plumbing
      has been offered — better than the cat and arguably better than the unicorn.
- [ ] **How many kinds of chase target** before it stays interesting, and how many before it stops
      being predictable enough for a five-year-old to anticipate?
- [ ] **Does the app need an eighth game more than the seven existing ones need a device run?**
      `STATUS.md` says several games have never been played by a child on real hardware, and says
      that is the highest-value work left. This scope does not change that; it is written so the
      idea is captured, not to jump the queue.

## Done when

A child who has never seen it presses the right side, sees a cross duck put his head down and
scramble up the path in a cloud of feathers, and works out within a few seconds that pressing makes
him go faster. They catch up to the kid with the bread bag, the kid laughs and tips it out, and
they hear the CHOMP. They notice Quacky's eyebrows are a bit less cross than they were. They skid
under a park bench, or they don't and they laugh at the feathers. They fill the row of bread rolls,
watch Quacky do a delighted spin in the fountain while the whole park quacks, and want to see the
next park — with no adult speaking, nothing to fail, nobody frightened, and no moment at which the
bread got away.
