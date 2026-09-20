# Games — Car Trip (scope)

- Date: 2026-09-20
- Status: proposed
- Session: (none yet)

## Why

The fifth mini-game, and the first one the child **steers**. Everything in the app so far is
answered with a press: Balloon Pop is where to tap, Dress the Dog is which to pick, Cat Run is when
to press, Blast Off is how long to wait. None of them asks the child to hold a line and guide
something along it. Dragging a car down a road with a thumb is exactly the motion that later
becomes drawing and handwriting, and at five it is worth practising for its own sake.

It is also the fantasy a five-year-old already owns. They have pushed a toy car along a carpet and
made the noise; they know that you drive *somewhere*, that you beep at things, and that people get
in. So the loop is not "avoid the obstacles" — it is **go on a trip**: the road unrolls, animals
waiting at the kerb hop in as you pull alongside, and the road eventually bends into a beach, a
farm or a park where everyone piles out. Arriving is the whole reward, and it always arrives.

The cones and the puddles are texture along the way, not a test. The only thing the child is really
being asked to do is keep a thumb on a car that is going somewhere nice anyway.

## What

- **A car that drives itself forward**, at one gentle speed that never increases, along a road that
  scrolls past. The child never has to make it go, and can never make it stop by doing the wrong
  thing.
- **Steering is a thumb on the screen.** Put a finger anywhere in the lower half and the car slides
  to follow it, smoothed so a jittery hand still draws a smooth line. No wheel, no buttons, no
  tilt: the largest possible target, and nothing to discover.
- **Lift the thumb and the car coasts to a stop at the kerb** and idles, with the world stopped
  around it, until a finger comes back. A child who wants to look at the cows can look at the cows.
- **A big horn button in the corner that does nothing useful.** Beep it and the animals along the
  roadside jump, wave, moo and flap. It has no purpose, costs nothing, cannot be wrong, and will
  probably be the most-pressed thing in the app.
- **A wide road with soft edges.** Grass either side is perfectly fine to drive on — the ride goes
  bumpy and the car slows a touch, and that is all. There is no edge to fall off and no way to
  leave the world.
- **Things that are fun to drive straight through:** a puddle (sheet of spray), a pile of leaves
  (scatter and swirl), a rainbow arch (the car comes out a different colour), a muddy patch (the
  car gets filthy, until the next roadside car wash rinses it and it comes out sparkling).
- **Things it is satisfying to steer around:** cones, a beach ball, a wobbly hay bale, a wheelie
  bin. Clip one and it **bounces away with a comedy boing**, the car wobbles, a soft parp, and the
  trip carries on. Nothing stops, nothing breaks, nothing is counted.
- **Passengers waiting at the kerb.** Pull up alongside a dog, a duck, a sheep or a bear and it
  hops in with a delighted noise and rides along looking out of the window, and the car gets
  visibly fuller as the trip goes on.
- **Each passenger fills one progress dot.** Dots full → the road bends into the destination →
  everyone piles out → the shared celebration → **a new road to somewhere else** (beach → farm →
  park → snowy village), forever. There is no last trip.
- **A rising chime as the car fills**, one note per passenger — the same ladder as Balloon Pop's
  pops and Cat Run's clean clears. It only ever climbs.
- **A missed passenger is not missed.** Drive past one and it waves, and the same animal is waiting
  a little further up the road. The trip cannot be shortened or lengthened by being good at it.
- The shared **home button** in the usual corner, in the top band, well clear of the steering half
  of the screen so a wandering thumb cannot leave the game.

Lives in `lib/games/car_trip/`. The road is a data list of segments and roadside items, not
hand-built levels, so a new destination is a new list. Placeholder art is shape-drawn — a rounded
rectangle car with two circle wheels, grey road, green verge, blob animals — so the steering can be
felt and tuned long before any real artwork exists. Asset paths collected in one `assets.dart`.

## Not this

- **No crashing.** No damage, no dents, no wreck, no spin-out, no "try again", no restart. The
  worst thing that can happen to the car is that it gets muddy and then gets washed.
- **No fuel, no battery, no engine trouble, no anything that runs out.**
- **No speed to manage.** No accelerator, no brake, no gears, no reverse. The car handles all of
  that; the child handles the steering and nothing else.
- **No racing.** No other car to beat, no lap, no finish line you can come second at, no stopwatch,
  no "3, 2, 1, GO" start light. Other vehicles on the road are friendly scenery going the same way,
  and driving alongside them and beeping is the whole interaction.
- **No oncoming traffic, no junctions, no crossroads, no anything head-on.** A thing coming
  towards you is a collision waiting to happen, which is the shape of failure even when it is
  harmless.
- **No hitting an animal, ever.** Anything alive on or near the road notices the car and steps
  aside by itself, well before it could be reached. Only cones, balls, leaves and bins bounce.
- **No police, no sirens, no flashing lights, no rules that can be broken.**
- **No score, no distance, no top speed, no coins, no passenger count as a number, no timer.**
- **No map, no levels to unlock, no garage to buy things in, no collection to complete.**
- **No tilt steering, no on-screen wheel to rotate, no two-thumb controls.** One thumb, anywhere.
- **No difficulty ramp.** Later trips are prettier, never harder, faster or denser.

## Kid-rules impact

- **Steering is the first continuous control in the app, and a five-year-old cannot hold a line.**
  That is the point of including it, but it must not be the thing they fail at. Resolved by making
  the road about three car-widths wide, the verges drivable, and the obstacles sparse and central
  with room either side of every one. A child who simply holds their thumb still in the middle of
  the screen completes the entire trip.
- **"Steer around the cones" is failure-shaped**, the same tension Cat Run has with its fences.
  Resolved the same way: keep the obstacle, delete the loss. Clipping a cone is a bounce and a parp
  that several children will deliberately farm, and the reason to steer well lives entirely in the
  chime ladder and in picking up passengers — a gradient of nicer outcomes with nothing at the
  bottom.
- **Driving into animals is funny in a game and appalling in life.** A five-year-old does not hold
  those apart, and this is the one rule here that is about the world outside the app rather than
  about the app. Resolved under *Not this*: living things always move themselves out of the way in
  good time and cannot be hit at all. Nothing on this road reads as hurt.
- **A thumb on the screen covers part of the picture.** Resolved by steering from the lower half
  with the car riding above the finger, so the hand never sits on top of the thing being steered or
  on the road ahead.
- **A traffic light teaches a rule that can be disobeyed**, and disobeying it would have to either
  do nothing (so why is it there) or punish (which is forbidden). Left out of *What* for now and
  parked in an open question; if it arrives, it arrives as a friendly gate that opens by itself
  while you wait, never as a thing you can run.
- **Losing control of where you are going is frightening at five.** Resolved by the lift-to-stop
  idle: the child ends the motion at any moment by taking their thumb off, and the world waits.
- **No text anywhere.** Destinations are pictures on the horizon, progress is dots, the horn is a
  horn. No signs, no place names, no numbers on the road.
- **Touch targets:** the whole lower half of the screen is the steering area; the horn is ~140×140
  in a bottom corner, far enough from the natural steering thumb that it is never hit by accident;
  the home button keeps its usual corner in the top band.
- **Nothing startling:** no crash bang, no screech, no siren, no other car's horn — only the
  child's own. Tunnels dim, they never go dark.

## Open questions

- [ ] **Drag-to-steer, or two big corner buttons like Cat Run?** Drag is the bigger target and needs
      no discovery, and it is the pre-writing motion that justifies the game. But it is untested
      with a real small hand, and it is the one control in the app that a child could hold wrong.
      Owned by the first real-child session; the buttons are the fallback and cost little.
- [ ] **Top-down, side-on, or three-quarter view?** Three-quarter looks best and reads as "driving",
      top-down makes the steering clearest, side-on is what Cat Run already does and would make the
      two games look like the same game.
- [ ] **Does clipping a cone need to do anything at all** beyond the bounce — or is even the wobble
      too much like being told off?
- [ ] **Do passengers need to be steered to**, or should driving anywhere near one be enough? If
      they must be aimed at, the steering has a purpose; if they are free, the game is calmer.
- [ ] **Is the horn always on screen,** or does a permanent button in the corner steal attention
      from the road entirely? A child who discovers the horn may never steer again — which may be
      a perfectly good outcome for a five-year-old, and is worth watching before deciding.
- [ ] **A friendly traffic light or lollipop person** — is waiting-on-purpose worth teaching here,
      or does Blast Off already own waiting?
- [ ] **How many passengers make a trip?** Too few and arriving is meaningless; too long and no
      child ever sees the beach.
- [ ] **Does the shared Rive character drive the car,** and is this the game that finally gives
      `lib/shared/rive_character.dart` a real job — a face in the window reacting to every puddle?
- [ ] **Is the car wash an event on the road, or the beginning of its own game?** Washing, painting
      and filling a car is a whole toy of its own, and putting it here may be putting two games in
      one folder.

## Done when

A child who has never seen it puts a thumb on the screen, sees the car follow it, drives through a
puddle on purpose and then goes back for the next one, beeps the horn far more than necessary,
picks up a dog and a duck and watches them look out of the window, clips a cone and laughs, fills
the dots, arrives at the beach to confetti, and sets off again — with no adult speaking, nothing to
fail, nothing to crash, and no moment at which the car does anything they did not ask it to.
