# Games — Neil the Seal (scope)

- Date: 2026-09-20
- Status: built (placeholder art and sound)
- Session: [../../sessions/games/neil-the-seal-session.md](../../sessions/games/neil-the-seal-session.md)
- Code: [`lib/games/neil_the_seal/`](../../../lib/games/neil_the_seal/) and its
  [README](../../../lib/games/neil_the_seal/README.md)

## Why

The sixth mini-game, and the first one where the child is the **biggest thing in the world**.

Neil is a southern elephant seal from a small seaside town in Tasmania. He is enormous, extremely
relaxed, and entirely unbothered. He hauls himself up the boat ramp, flops across the road, sits on
a car until it sinks on its springs, burps at a seagull, and goes to sleep. The whole town
rearranges itself around one huge animal who has no idea he is doing anything at all.

That is the fantasy, and it is a good one for a five-year-old. They are small, they are moved
around by adults all day, they are told where not to sit. This game hands them a two-tonne body
that everybody makes room for, and nobody is ever cross about it. Neil is not naughty. Neil is
just *large*.

The verb is new for this app. Balloon Pop is where to tap, Dress the Dog is which to pick, Cat Run
is when to press, Blast Off is how long to wait, Car Trip is holding a line. Neil is **choose a
place, then watch what a big soft heavy thing does when it gets there.** The child picks the
destination; the comedy is the journey and the landing. It exercises something none of the others
do — deciding what to make happen next in a world that is entirely made of things worth sitting on.

## What

- **Tap anywhere and Neil galumphs there.** He heaves himself along on his belly, slow and wobbly,
  in a rhythm — heave, flump, heave, flump — and flops down when he arrives. No stick, no buttons,
  no dragging. The whole screen is the control.
- **Tap somewhere else while he is moving and he changes his mind.** He never has to finish a trip,
  and a child can redirect him as often as they like. He never refuses.
- **Everything in the town is worth flopping on**, and each thing answers differently: a car sinks
  on its springs with a long *boing*; a traffic cone squashes flat and springs back up; the jetty
  planks go *doing-oing*; a pile of kelp goes *squelch*; a wheelie bin tips over and seagulls
  explode out of it; a garden hose starts spraying; a trampoline is a mistake everyone is glad he
  made; dry sand takes a perfect Neil-shaped dent.
- **The car and the cone are the two the game is built around.** They are the signature move — the
  real Neil's whole reputation — and they are the two props where the springback has to be perfect,
  because everything else in the town is judged against them.
- **Nothing stays squashed.** The moment he moves off, the car pops back up with a spring, the bin
  rights itself, the sand smooths over. Nothing is ever broken, and the town is brand new behind
  him.
- **There is no dead tap.** Flopping onto an empty patch of grass still gets a flump, a puff of
  dust, a contented sigh and a settling wobble. Every tap is answered, always.
- **A big honk button, and the town answers back.** Neil lets out a low comedy bellow — and then
  the answers arrive one after another, like a round: the dog barks, the seagulls lift, a wallaby
  thumps the ground, a ute goes *parp*, a curtain twitches, a cow answers from over the fence.
  Never the same order twice.
- **Rub Neil and he loves it.** Drag a finger over him and he wriggles, kicks a back flipper, flings
  sand about, and goes completely floppy. It has no purpose, fills nothing, and is probably the
  reason a child comes back to this game rather than another one.
- **A town that watches.** Wallabies and pademelons in the grass, a wombat by the fence, seagulls on
  every post, a dog on a verandah, kids on bikes keeping a respectful distance. They all stop what
  they are doing to look at Neil, and they are all delighted he is here.
- **Every new thing he flops on fills one progress dot.** Dots full → an enormous yawn → the whole
  town gathers round → someone sets a bucket of fish down beside him → Neil sleeps, snoring hard
  enough to rattle the windows → the shared celebration → he wakes up somewhere new in town. Beach
  → boat ramp → main street → caravan park → footy oval, and round again, forever.
- **A rising chime as the dots fill**, one note per new thing sat on — the same ladder as Balloon
  Pop's pops and Car Trip's passengers. It only ever climbs.
- **Flopping on the same car twice is still fun**, it just doesn't fill a dot. Nothing tells the
  child off for it, and nothing marks it as used.
- **If nobody touches anything, Neil falls asleep by himself** and snores gently until they come
  back. The game waits, and waiting looks like something.
- The shared **home button** in the usual corner.

Lives in `lib/games/neil_the_seal/`. The town is a data list of floppable props with a reaction
each, not a hand-built scene, so a new location is a new list. Placeholder art is shape-drawn — Neil
is a big grey rounded blob with a snout and two huge dark eyes, the town is coloured rectangles with
a grey sea behind — so the galumph rhythm and the boing can be felt long before there is real
artwork. Asset paths collected in one `assets.dart`.

## Not this

- **Nothing breaks.** No dents that stay, no cracked glass, no broken fence, no damage of any kind.
  Neil squashes; he does not wreck. A five-year-old can tell those apart if the game is careful, and
  the difference is entirely in whether it springs back.
- **No car alarms, no sirens, no shouting, no angry neighbour.** Nobody in this town is cross that
  Neil is here, ever. Not once, not mildly, not as a joke.
- **No ranger, no truck, no fence, no relocation, no being moved on.** The real Neil was eventually
  taken somewhere else, and that is a genuinely sad ending. It is not in this game and never will
  be.
- **Nothing alive is ever squashed.** Seagulls, wallabies, the dog and the kids all notice him and
  move clear early — well before he could reach them — so the child never even aims at one. Same
  rule as Car Trip.
- **No other bull seals, no fighting, no territory, no rearing up, no roaring.** Real elephant seals
  do all of that and it is terrifying. Neil bellows like a burp and that is the extent of it.
- **No hunger, no health, no tiredness meter, no pet-care loop.** Nothing about Neil ever goes down.
  The fish at the nap is a gift, not a refill.
- **No score, no count of things squashed, no timer, no "you found them all".**
- **No swimming or diving level.** Deep water is a different feeling and probably a different game.
- **No levels to unlock, no collection to complete, no map.**
- **No difficulty.** Later locations are prettier and have more to sit on, never harder, faster or
  denser.
- **No camera, no photo, no sharing, no anything that leaves the app.**

## Kid-rules impact

- **The whole game is sitting on things that belong to other people, which is the joke and also the
  risk.** Resolved by springiness: every squash is elastic, loud, funny and completely undone the
  moment he moves. Nothing in the art suggests damage — no cracks, no shattered glass, no wonky
  wheel. The read is "that car is a bouncy castle", not "that car is wrecked".
- **Nobody may ever be annoyed with Neil.** This is the rule the game will be tempted to break,
  because "cross neighbour" is where the comedy usually lives in stories like this. It is forbidden
  here: at five, an adult being angry about something you just did is the thing that stops play. The
  town's only reaction to Neil is delight.
- **A two-tonne wild animal is frightening if drawn honestly.** Resolved by making him round,
  soft-edged, slow, wet-eyed and wobbly, with every movement comedic. No teeth, no proboscis
  display, no bulk used as threat. He is closer to a beanbag than to a predator.
- **Point-and-go puts a layer between the finger and the thing that moves**, and a mis-read tap
  reads as the game ignoring the child. Resolved by having him set off for *every* tap without
  exception, by letting a new tap override an old one instantly, and by making an empty-ground flop
  as satisfying as any other. There is nowhere on the screen that does nothing.
- **Slow is funny; too slow is boring.** He is the slowest thing in the app on purpose, and that is
  a real risk with a five-year-old's patience. Starting point: about four seconds to cross the
  screen, with the redirect always available so nobody is ever stuck watching. Named as an open
  question because only a child settles it.
- **The honk overlaps with Car Trip's horn**, and two games with the same useless-button gag start
  to look like one game. Resolved by making this one a call-and-response: Car Trip's horn makes
  things jump, Neil's bellow makes the town *answer*, in a chain, in a different order each time.
  Placement differs too — Neil has no steering thumb to keep clear of.
- **No text anywhere.** Tasmania is weatherboard, kelp, wallabies and a big grey sky, not a place
  name. No signs, no numbers, no labels on anything.
- **Touch targets:** every floppable prop is furniture-sized and well clear of the next one, all far
  above 80×80; Neil himself is a target the size of a hand for rubbing; the honk button is ~140×140;
  the home button keeps its usual corner. Because any tap is valid, a mis-tap costs nothing at all.
- **Nothing startling:** no alarms, no sirens, no thunder, no sudden loud bark. The biggest noise in
  the game is a snore, and it arrives after a yawn that telegraphs it.

## Open questions

Answered by the first build. Each one is a starting point, not a settlement —
the thing that settles any of them is a five-year-old.

- [x] **Tap-to-go, or drag Neil directly?** **Tap-to-go.** It is the new verb
      and the reason the game exists, and his weight is better felt when the
      child cannot pull him. Drag stays the fallback if a real child never
      discovers tapping — though the first touch anywhere sends an enormous
      seal across the screen, so discovery should look after itself. No hint is
      drawn, unlike Car Trip's pulsing hand, for exactly that reason.
- [x] **One screen per location, or a town that scrolls?** **One screen.**
      Everything worth sitting on is visible from wherever he is, and a child
      never has to discover that the game continues off-screen.
- [x] **Does this game need the dots at all?** **Kept**, because the nap is the
      best thing in it and the dots are what bring it round. Five dots against
      seven or eight floppable things per location, so there is always
      something left and never a set to complete. Still the question to watch
      hardest with a real child.
- [x] **Is Neil the job the shared Rive character has been waiting for?** Not
      yet, and not decided. He is shape-drawn like every other game here;
      `assets.dart` records that the galumph, the flop, the wriggle and the
      yawn are exactly what a state machine is for, and that an animal this
      specific may not belong in `shared/`.
- [x] **Honk as a button, or tap Neil to honk and drag to rub?** **A button**,
      bottom-right, 140×140, **wearing Neil's face** rather than an icon — the
      only way to tell a non-reader what a button does is to show them the
      thing that does it. Tapping Neil rubs him; the best noise in the game is
      not hidden behind a gesture nobody is told about.
- [x] **Cones appear in Car Trip too.** Kept, as a rhyme rather than a repeat:
      there they are steered around and bounce off a bumper, here they squash
      flat and spring back. Cheap to drop if it ever reads as running out of
      ideas.

Still open, and only a child can close them:

- [ ] **How slow is funny, and where does it turn into boring?** Built at about
      four seconds to cross the screen, pinned by a test so that changing it is
      deliberate. Every trip restarts the rhythm on a heave so a tap moves him
      immediately — which makes short trips average a little quicker than long
      ones. Tune under a thumb.
- [ ] **The self-snore idle is charming, but does it reward putting the tablet
      down?** Built at fourteen seconds to doze, with a gentle snore every six
      and a half. Watch it.
- [ ] **A pademelon means nothing to a child outside Tasmania.** Still a
      deliberate choice rather than an accident. In play it is a small bouncing
      animal that gets out of the way, which is all a five-year-old needs.
- [ ] **Do we keep the name?** Untouched — nothing in the game says it, because
      nothing in the game says anything. Worth a deliberate decision before
      anything ships publicly.
- [ ] **Has anybody heard it?** No. Fourteen new sound cues were written for
      this game and every one was verified numerically rather than by ear. The
      boing is what the whole thing rests on.

## Done when

A child who has never seen it taps a car, watches an enormous seal wobble across the screen and
land on it, hears the boing, laughs, and immediately taps a different car. They rub his belly until
he kicks a flipper. They find the honk and press it eight times to hear the town answer. They fill
the dots without ever knowing there were dots, watch him yawn and snore hard enough to shake the
windows, and want to do it again — with no adult speaking, nothing broken, nobody cross, and nobody
coming to take Neil away.
