# Games — Crystal Party (scope)

- Date: 2026-09-20
- Status: **built** — playable, placeholder art
- Session: [../../sessions/games/crystal-party-session.md](../../sessions/games/crystal-party-session.md)

## Why

The seventh mini-game, and the second one that is a **journey** rather than a place. Cat Run proved
that a scrolling world with something coming up ahead is the most exciting thing in this app; Neil
and Dress the Dog are toys, and a toy is lovely for ten minutes but it does not pull a child back.
This one is built on Cat Run's frame — a world that moves, a horizon with something on it, a run
that goes somewhere — and changes the verb.

Cat Run is a **moment**: a fence is coming, press now. Crystal Party is a **height**: hold the
screen and the unicorn lifts off the ground on a rainbow, let go and she drifts back down to a
gallop. There is no right instant to find, so there is no instant to miss. The child is not timing
a press, they are choosing where in the sky to be, continuously, for as long as they like — which
at five is a much more forgiving thing to be asked and a much prettier one to watch.

The crystals are what makes it a game rather than a flight. **Blue ones live low** — in the grass,
on rocks, on lily pads, at hoof height. **Pink and purple ones float high** — in the clouds, around
treetops, over floating islands. So the colours are not decoration and they are not a quiz: they
are *where things are*. Going up and coming back down is the whole skill, and sorting by colour,
which is a real five-year-old thing to be getting good at, happens as a side effect of flying well.

At the end of every land there is a rainbow arch, half-built, visible on the horizon from the start.
Every crystal gathered adds a piece to it. Fill it and the arch blazes into life — **the crystal
party** — and then there is another land.

## What

- **A unicorn that gallops by herself**, left to right, at one gentle speed that never increases,
  across a side-on world that scrolls past. The child never has to make her go.
- **One control: hold anywhere on the screen and she rises**, trailing a rainbow behind her. Let go
  and she floats gently down and lands back into a gallop, four hooves, with a little sparkle. That
  is the entire control scheme — the whole screen is the button.
- **She cannot crash and she cannot fall.** She levels out under the clouds rather than leaving the
  top of the screen, and every landing is soft. There is never anything below her but ground or
  shallow water.
- **Blue crystals sit low, pink and purple ones float high.** Fly through one and it joins the
  **trail streaming out behind her** — a growing string of crystals that is the progress readout.
  A picture that only ever gets longer. No number anywhere.
- **The arch ahead builds as the trail grows.** It stands on the horizon from the first second,
  visibly unfinished, and each crystal slots a piece into it. Progress is visible twice: behind her
  and in front of her.
- **Each crystal is the next note up a rising chime** — the same ladder as Balloon Pop's pops and
  Cat Run's clean clears. Blue rings like a bell, pink chimes; the two colours sound different as
  well as looking different.
- **A missed crystal is not missed.** Fly past one and it twinkles, drifts along behind and shows up
  again further up the path. The land does not end until the arch is full, so nobody can ever be one
  crystal short of the party.
- **Things to rise over and drop under:** a tall pine, a stack of rocks, a low stone arch, a washing
  line strung between two trees. Clip one and leaves scatter, she wobbles, a soft *boing*, and the
  gallop carries on. Nothing stops, nothing breaks, nothing is counted.
- **Things that are a delight to fly straight through:** a waterfall (she comes out sparkling), a
  cloud (she comes out fluffy), a flock of butterflies (they swirl into the trail), a rainbow puddle
  (a splash of colour up her legs).
- **A world that notices her.** A friendly dragon asleep on a rock opens one eye and puffs a smoke
  ring as she passes; rabbits wave from a burrow; a whale breaches in the sea below; sheep bounce.
  None of it is in the way and none of it wants anything.
- **Arch full → the crystal party.** She gallops through, the arch blazes into a full rainbow, the
  whole land lights up, other unicorns come over the hill, confetti, music, dancing — the shared
  celebration, at its biggest.
- **Then the next land**, always, forever: meadow → beach → snowy mountain → cloud island →
  glowworm cave → night sky. Prettier every time, never harder, never faster, never denser.
- **Leave it alone and she slows to a trot, then stops to eat a flower.** The world waits.
- The shared **home button** in the usual corner, in the top band, well away from where a holding
  thumb rests.

Lives in `lib/games/crystal_party/`. A land is a data list of crystals, props and scenery at
heights, not a hand-built level, so a new land is a new list. Placeholder art is shape-drawn — a
white blob unicorn with a triangle horn and a rainbow ribbon, round pink crystals, pointy blue ones,
green ground, blue sky — so the rise and the float can be felt and tuned long before there is real
artwork. Asset paths collected in one `assets.dart`.

## Not this

- **No falling, no crashing, no ground slam, no ceiling to bump, no bottom of the screen.** Flying
  is the oldest way a game has of killing you, and none of that machinery is here.
- **No magic, stamina, sparkle or flight meter that runs out.** She can fly for as long as a thumb
  can hold, and holding is the only limit.
- **No score, no crystal count as a number, no timer, no "collect them all before…", no distance.**
- **No locked lands, no world map, no stars out of three, no replaying a land for a better result.**
  A land is the next place, never a gate.
- **No enemies, no chase, no storm, no dark forest, no dragon that wakes up angry.** Anything that
  is catching up is pressure, which is the same shape as failure.
- **No crystals that can be lost, dropped, stolen, broken or taken back.**
- **No wrong noise.** No buzzer, no thud, no descending "aww", nothing that marks a moment as a
  mistake.
- **No difficulty ramp.** Later lands are more beautiful, not more demanding.
- **No strobing, no rapid colour cycling, no flash.** See below — this is the one in this game that
  will get broken if it is not written down.
- **No shop, no currency, no crystals spent on anything.** They are treasure, not money.
- **No tap-to-flap.** One hold, not a rhythm to keep up.

## Kid-rules impact

- **"Collect them all" is a completion goal, and completion invites being incomplete.** This is the
  central tension of the ask. Resolved by making completion guaranteed rather than earned: missed
  crystals come back, the land does not end until the arch is full, and the party is therefore not
  something a child can fail to reach — only something that takes as long as it takes. There is no
  state in which a child has "not got them all".
- **A child who cannot manage the hold must still get the party.** If the arch needed both colours
  equally, a five-year-old who never lifts off would be stuck on the ground forever watching a
  half-built arch. Resolved: the arch takes whatever she brings, and if one side is lagging, that
  colour starts appearing more often and lower down. The game quietly comes to meet them and never
  says so.
- **Levels are the thing this ask asked for and the thing the rules most distrust.** Resolved above
  under *Not this*: lands are scenery, not gates. Nothing is locked, nothing is unlocked, nothing is
  missed by leaving early, and the next land always arrives.
- **Flying implies falling.** Resolved: descent is a slow float, not gravity; every landing is on
  four hooves; and there is never a pit, a cliff edge or a drop under her. A five-year-old reads
  height as danger unless the game is careful, and being airborne must feel like floating, never
  like being held up.
- **A "crystal party" is a strobe waiting to happen.** This is a real photosensitivity risk and the
  most likely rule in this repo to be broken by a future session trying to make the ending feel big.
  Resolved: the party is bright but **slow** — swelling glows, one rainbow sweep across the sky,
  drifting confetti, nothing changing faster than about twice a second. Big is achieved with scale
  and colour, never with rate.
- **Colour sorting fails a colourblind child if colour is the only cue.** Resolved: pink and purple
  crystals are round and blobby, blue ones are pointy shards, and the two ring differently. Any one
  of the three cues is enough on its own.
- **Clipping a pine tree is failure-shaped**, the same tension Cat Run has with its fences and Car
  Trip with its cones. Resolved the same way: keep the obstacle, delete the loss. A clip is a
  scatter of leaves and a wobble, and the reason to fly well lives entirely in the chime ladder and
  in the crystals.
- **Holding a finger down is physically tiring for a small hand**, and it is the first sustained
  press in the app. Resolved by keeping the sky low — about two seconds of hold reaches the highest
  crystal — and by making the ground genuinely worth staying on. Flagged below, because only a real
  hand settles it.
- **No text anywhere.** Lands are pictures, progress is an arch, the crystals are crystals.
- **Touch targets:** the entire screen is the control, which is the largest target the app has. The
  unicorn flies in the upper two-thirds so a thumb at the bottom never covers her. The home button
  keeps its usual corner.
- **Nothing startling:** no thunder, no roar, no sudden dark, no loud arrival. The glowworm cave
  dims, it never goes black.

## Open questions

- [ ] **Hold-to-rise, or tap-to-flap?** Hold has no rhythm to keep up and nothing to be late for,
      which is why it is in *What*. Flap is more responsive and more fun for an older child, and it
      is also Flappy Bird, which is a failure machine with the failure filed off. Owned by the first
      real-child session.
- [ ] **Does a five-year-old's thumb tire before the arch fills?** If it does, the fix is a shorter
      land, not an easier sky.
- [ ] **Is the arch visible on the horizon the whole time, or revealed at the end?** Seeing it build
      is motivating, but seeing how much is left may read as "a long way to go" to a child who
      cannot count it.
- [x] **Should either colour be able to fill the whole arch,** or does it genuinely need both sides?
      **Answered: both sides, quietly helped.** Six pieces a side. It gives flying a shape — you
      have to go up sometimes — and it is safe only because the quiet help is built with it.
- [ ] **Is this finally the Rive character's job?** A unicorn with a glowing horn and a face that
      reacts to every crystal is the strongest candidate `lib/shared/rive_character.dart` has had
      since it was plumbed in.
- [x] **How long is a land** — one celebration's worth, or three? **Answered for now: twelve
      crystals, one celebration's worth**, close to Cat Run's ten fish so the rhythm matches. It is
      one constant (`CrystalPartyGame.crystalsPerSide`); a real child may still move it.
- [ ] **Does anything need to be avoided at all**, or is a world made entirely of nice things enough
      at five? The trees and rocks are in here because a journey with nothing in it stops being a
      journey — but that is an adult's instinct, and it is worth checking against a child before
      building them.
- [ ] **A third crystal colour in later lands** — tempting, and it is a difficulty ramp wearing a
      pretty hat. Only if a real child is visibly bored with two.
- [ ] **Two colours, or two colours and two places to put them?** Right now the crystals sort
      themselves by where they live. An alternative is that the child chooses which side of the arch
      each one goes to — real sorting, with a wrong answer in it, which would need the whole
      gentle-refusal design worked out. Calmer as it stands; less of a game.

## Done when

A child who has never seen it presses the screen, sees a unicorn lift off on a rainbow, and works
out within a few seconds that holding takes her up and letting go brings her down. They fly through
a waterfall on purpose. They gather a blue crystal off a rock and then hold to go up and get a pink
one out of a cloud, and see both of them join the trail behind her. They clip a pine tree, laugh,
and carry on. They watch the arch on the horizon finish, gallop through it into the party, and want
to see the next land — with no adult speaking, nothing to fail, nothing to fall off, and no moment
at which they are short of one crystal.
