# Games — Blast Off, the countdown (scope)

- Date: 2026-09-20
- Status: building
- Session: (none yet)

## Why

Children who love countdowns love them for a reason: a countdown is the only thing in a small
child's day where **they can see the future arriving**. Ten is far away, three is nearly, zero is
*now* — and unlike almost everything else, it is completely predictable. That is enormously
satisfying at five, and counting backwards is a genuinely hard skill they are working on anyway.

So this is a mini-game where the child **sets a countdown going and watches it arrive**, out loud,
with everything on screen getting more excited as zero approaches. It is the first thing in the app
with anticipation in it: Balloon Pop and Dress the Dog both answer instantly, and waiting-on-purpose
is its own pleasure.

It is also the first game that is **useful outside itself**. A rocket that launches in two minutes
is a tooth-brushing timer a child will actually stand still for, and "we leave when the rocket goes"
is a sentence that ends arguments. Nothing in the app so far helps at half past seven in the
morning.

## What

- **The child picks what they are counting down to, by picture** — a rocket, a birthday cake, a
  race flag, an egg timer, a bath. Big tiles, no reading. The picture decides what zero looks like.
- **The child picks how long, by picture, never by typing.** Two ways, because a child and the
  adult beside them want different things:
  - **three quick presets** — a mouse (five seconds), a rabbit (thirty), a tortoise (five minutes),
    each one tap. Speed is the only idea for "how long" a five-year-old already has.
  - **more and less**, stepping one rung at a time along a fixed ladder of sensible lengths
    (5, 10, 15, 30 seconds, 1, 2, 3, 5, 10 minutes). The steps get coarser as they get longer,
    because "one more" means something different at five seconds than at five minutes.
- **The chosen length shows as a row of dots** — more dots, longer wait — never as "02:00". It is
  the same trick the star jar plays during the count, and an adult reads it perfectly well after
  pressing *more* twice.
- **The rocket itself is bigger for a longer countdown**, and grows or shrinks as the child presses
  more and less. A third readout of the length that needs no reading, in the one place a child is
  already looking — and the only one that answers "what does this button do?" while the button is
  being pressed. How big it can get depends on the sky the screen has: obvious on a tablet, slight
  on the shortest phones.
- **There is no number pad and no free typing**, so there is no such thing as a countdown of 47
  seconds: every reachable length is a rung someone chose.
- **The length cannot be changed once it is counting.** Adding seconds back on mid-count reads as a
  punishment and cutting them off reads as the clock being taken away.
- **A big GO button starts it.** One obvious button, nothing else to understand.
- **A friendly voice counts every number out loud**, and the child counts along. This is the
  actual activity, and it is why the game needs no text: a child who cannot read can absolutely
  count, and counting backwards from ten is a real thing they are learning.
- **Every number is also a quantity, not just a digit** — ten stars in a jar, and one leaves each
  time. A child who does not know digits still sees, plainly, that there is less left than before.
- **Something happens on screen every single second.** A star leaves the jar and spins off, the
  rocket rattles a bit harder, its smoke gets thicker, the cat climbs one more branch, the lift
  dings up one floor, a paper chain loses a loop.
- **The excitement is built into the sound.** One note higher per number — the same chime ladder as
  Balloon Pop's pops — plus a rising rumble, a growing crowd murmur, and at **three, two, one**
  everything goes bigger and slower: a drumroll, a screen-wide lean-in, the engines glowing.
- **The countdown is not a dead waiting screen.** Everything on it can be poked while it runs —
  tap the rocket and it honks, tap a star and it spins, tap the clouds and they puff. Waiting is
  never nothing-to-do.
- **Zero is enormous.** The rocket launches with a roar and a real shove of speed, confetti, the
  shared celebration, the sky filling with stars; the cake's candles all light at once; the race
  flag drops and everything runs. Whatever the picture promised, it delivers, loudly.
- **After zero there is something to do** — the rocket keeps flying and can be tapped to loop, the
  cat sits at the top of the tree — and then one big **again** button (a circular arrow), because
  the thing a child wants most after a blast off is another blast off.
- **A pause button, and play to carry on.** One button that swaps its picture in place rather than
  two that move, so a child tracks "the button there". Nothing drains while it is held and nothing
  is taken away — someone knocks at the door mid-toothbrush, and the alternative to pausing is
  starting the whole thing again.
- **A big stop button, always visible.** Stopping is free: nothing is lost, nothing is scolded,
  nothing counts how many they abandoned. Tap again to start over.
- **The time in digits, small and grey in the corner, for the adult.** See *Kid-rules impact* — the
  dots and the jar remain the child's readout, and nothing about playing needs the digits.
- The shared **home button** in the usual corner.
- **The menu grows past three tiles for the first time.** With Blast Off and Cat Run there are four
  games, so [`lib/menu/home_screen.dart`](../../../lib/menu/home_screen.dart) becomes a 2×2 grid
  rather than a row — still everything visible at once, still no scrolling, still the same layout
  every time.

Lives in `lib/games/blast_off/`. Placeholder art is shape-drawn — a block rocket, a circle-and-
triangle cat, a jar of dots — so the pacing, the voice and the sound ladder can be tuned before any
artwork exists. Asset paths collected in one `assets.dart`.

## Not this

- **The countdown is never attached to a task the child has to finish.** No "tidy up before it gets
  to zero", no race against it, no "oh dear, too slow". Zero is a reward arriving, never a deadline
  passing. This is the whole reason a countdown is allowed here at all.
- **Nothing is lost, failed or missed at zero**, and nothing is lost by stopping early.
- **No typing and no number pad.** The digits are a readout, never an input: the only way to change
  the time is the presets and more/less.
- **No countdown that drains while paused**, and no penalty of any kind for pausing.
- **No alarm sound.** Zero is a celebration, not a buzzer. Nothing harsh, nothing urgent, nothing
  that sounds like a smoke alarm or a school bell.
- **No notifications, no reminders, no background alerts.** Nothing wakes the device up, which also
  keeps the app clear of push permissions entirely.
- **No real clock, no date, no calendar, no "how many sleeps"** in this first slice — see the open
  questions; that is a different app shape and it needs an adult to set it.
- **No counting-up stopwatch.** Counting up has no arrival in it, which is the entire point.
- **No score, no history, no "you did 12 countdowns today", no streak.**
- **No balloon that bangs.** A balloon that swells as it counts is tempting and the pop is exactly
  the kind of sudden loud noise that ends play for a nervous child.

## Kid-rules impact

- **CLAUDE.md bans timers — this is a timer.** The rule is precisely "no timer that can cause
  failure", and this one cannot: nothing is being raced, nothing is required before zero, and zero
  is the nicest moment in the game. Resolved by the first *Not this* bullet, which is load-bearing
  and must be defended in review: the moment a countdown is pointed at something the child must
  finish, this becomes the only failure state in the app.
- **A countdown shows numbers, and numbers look like text.** Resolved three ways: the numbers are
  **spoken aloud**, they are **drawn as a quantity** (stars leaving a jar) as well as a digit, and
  nothing about playing requires recognising a digit at all. The digits are there for the child who
  is ready for them — counting along is the treat, not the toll.
- **There is now a clock readout in digits, which this scope originally ruled out.** Added on the
  maintainer's call, twice asked for, and the reason is real: an adult setting a two-minute
  toothbrush timer cannot tell two minutes from three by counting dots, and this is the one game in
  the app meant to be handed over by a parent. It is resolved the way the settings cog is — **small,
  grey, cornered, low contrast, and referred to by nothing in the game**, so a child's eye slides
  off it. It is a *second* readout and never the only one; a test pins that it is the single piece
  of text on the screen, so anything else that creeps in gets caught.
- **Choosing a duration is the one place an adult idea (minutes) leaks in.** Resolved: durations are
  chosen as pictures of what they are for — a toothbrush, a tidy-up — never as a number of minutes.
- **Anticipation is close to tension, and tension can tip into anxiety.** Resolved: the build is
  musical and comic, never threatening — no heartbeat, no sirens, no darkening screen, no ticking
  that sounds like a bomb. If a child looks worried rather than thrilled at "three, two, one", the
  build is too strong and comes down.
- **Nothing startling at zero:** the launch is loud-ish and bright but has no bang, no flash, no
  strobe. Confetti and a roar, not an explosion.
- **Touch targets:** picture tiles ~120×120, the GO and stop buttons ~140×140, well apart so a
  thumb cannot start and stop in one clumsy jab.
- **A countdown can be left mid-way** — quite often, a child will start one and wander off. Nothing
  follows them, nothing nags, and the home button is always one tap away.
- **Still fully offline.** No clock service, no network, nothing stored but which pictures they last
  chose.

## Open questions

- [ ] **Does the "how many sleeps" countdown belong here at all?** A parent setting a date behind
      the gate, and a paper chain that loses one loop a day until the birthday, is the other thing
      people mean by a countdown app — and it is the one a child checks every morning. It needs a
      real date, persistence and probably a notification to be any good, which is a different app
      shape. Decide whether it is a second mode, a second game, or out.
- [ ] **How long is too long?** Ten seconds always works. Is two minutes still fun to watch, or does
      it need something new to happen every fifteen seconds to hold a five-year-old?
- [ ] **Is the voice recorded or synthesised,** and whose is it? A parent's recorded voice counting
      would be lovely and is trivially offline, but it needs an adult flow behind the gate.
- [x] **Does the child pick the length at all,** or does each picture simply come with its own?
      **They pick.** Built as three presets plus a more/less stepper over a fixed ladder, with the
      length shown as dots. Whether nine rungs is too many to step through, and whether the three
      preset animals read as "how long" rather than as three animals, both want a real child.
- [ ] **Can they speed it up?** Some children will want to skip to the good bit. A "faster" button
      is either delightful or destroys the entire point.
- [ ] **Does the menu really become a 2×2 grid**, or does the fourth game force a rethink of the
      home screen — and what happens at five?

## Built so far

The first slice (2026-09-20): the rocket, the sky, the star jar, the big number, the sound ladder,
the launch and the full set-the-time controls — playable, with placeholder art and **no voice**,
and **never yet run on a device**. `lib/games/blast_off/`, on the menu as a fourth tile.

Pause/play and the adult clock readout landed in the same slice, on request. The rocket then grew
a size that follows the chosen length (2026-09-20) —
[session](../../sessions/games/blast-off-rocket-size-session.md).

Not built yet, still wanted: **the recorded voice counting**, which is the real feature and the one
thing a shape-drawn placeholder cannot stand in for; the other skins (cake, race flag, egg timer,
bath); and the poke-everything pass beyond the rocket honk and the cloud puffs.

## Done when

A child chooses a rocket, presses GO, counts backwards out loud along with the voice while the jar
empties and the rumble builds, gets loud at three-two-one, cheers at the launch, and immediately
presses again — with no adult speaking, nothing to fail, and no moment where the wait feels like
pressure rather than excitement. And an adult, separately, finds themselves using it to get teeth
brushed.
