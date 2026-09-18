# Games — Dress the Dog (scope)

- Date: 2026-09-18
- Status: building
- Session: [../../sessions/games/dress-the-dog-session.md](../../sessions/games/dress-the-dog-session.md)

## Why

The second mini-game, and a different kind of thing from Balloon Pop: a **toy, not a round**.
There is nothing to complete, so there is nothing to fail — the child dresses a dog, and the dog
reacts. The reward is not confetti for finishing, it is that **a character responded to what they
chose**, which at five is a stronger pull than any score.

The weather adds the only "thinking" in the app: the child picks the weather, and the dog's
clothes either suit it or very much do not. Whether a coat is needed today is a real question a
five-year-old is actively working out, and here they get to test it on a dog with no consequence —
including, especially, the funny wrong answer.

It is also the game that finally earns the Rive work: a dog with clothing slots and reactions
driven by data binding is exactly what `lib/shared/rive_character.dart` was built to drive.

## What

- A **big dog in the middle** of the screen, on a simple stage, always visibly happy.
- A **wardrobe rail** of large picture tiles down one side — hats, faces, body, feet — and picture
  tabs to change category. **Tap an item and it flies onto the dog**; tap another in the same slot
  and it swaps. Items can also be **dragged onto the dog**, which is the motion many children reach
  for — but **tap always works**, so a child who cannot manage a drag is never locked out, and a
  missed drop is silent and costs nothing.
- **Every item has its own reaction.** Sunglasses get a slow cool head-tilt; big boots get a
  clomp-and-sit; a party hat toots a horn; a scarf causes a sneeze that ends up over the dog's eyes.
- A **weather switch** of three big picture buttons — **sun, rain, snow**. Tapping one changes the
  sky, the ground and the sound behind the dog. The child controls the weather; it never changes
  on its own.
- **The dog reacts to clothes-plus-weather**, and the mismatch is the joke:
  - swimming trunks in the **snow** — shivers, hops foot to foot, teeth chatter, tail still wagging;
  - a woolly coat in the **sun** — pants, tongue out, fans itself with a paw, slumps;
  - nothing on in the **rain** — goes drippy, then shakes water at the screen.
- **Dressing for the weather is the bigger payoff.** Get the key item right and the dog
  **bursts out to play in it** — bounding through snow, stamping in puddles, flopping out to
  sunbathe in shades — with the shared celebration. Then it trots back in, ready to be changed again.
- **The wardrobe is never filtered by weather.** Every item is always available in every weather,
  or the funny wrong answer becomes impossible to reach.
- A **big silly paw button** that dresses the dog at random — a laugh with no decision required,
  for a child who doesn't want to choose.
- A **ta-da button**: the dog poses, confetti, and the outfit is saved to a little shelf of past
  outfits (local `shared_preferences` only — game progress, nothing personal, no camera).
- The shared **home button** in the usual corner.

Lives in `lib/games/dress_the_dog/`. Placeholder art is shape-drawn — a crude dog with simple slot
shapes and tweened reactions — so layout, targets, sound and the weather logic are all playable and
tunable before any real artwork exists. Asset paths collected in one `assets.dart`.

## Not this

- **No "correct!" badge, tick, star or score for dressing right.** The reward is what the dog does.
- **No wrong buzzer, no red cross, no scolding voice, no blocked action.** A mismatch is always
  allowed, and can be left in place forever.
- **No distressed dog.** Shivering and panting are slapstick and the tail keeps wagging. Nothing
  whimpers, cries, gets ill or looks like it is suffering — a five-year-old reads an unhappy animal
  as real.
- No quiz. Nothing ever asks the child what the dog *should* wear.
- **No weather that changes by itself** and undoes an outfit they were pleased with.
- No locked items, no unlocking, no collection to complete, no shop.
- No timer, no round, no "get 5 outfits right".
- **No dragging as the ONLY input** — drag is offered alongside tap, never instead of it. No
  multi-touch gestures.
- **No penalty, sound or animation for a missed drop.** Dropping an item in mid-air is not an event.
- No real camera, no sharing, no saved image leaving the device.

## Kid-rules impact

- **Weather matching creates a right answer, which is the first thing in this app that could read
  as failure.** Resolved by inverting it: the wrong outfit is never punished, it is *rewarded with
  comedy* — the shivering dog is the funniest thing in the game and many children will do it on
  purpose. The right outfit is not "correct", it is "now we can go out and play", which is simply a
  bigger reward. Nothing is blocked, nothing is marked, nothing is counted.
- **A shivering or panting dog risks reading as an animal in distress.** Resolved above under
  *Not this*: permanently happy body language, cartoon slapstick, no distress sounds. This is the
  single biggest thing to check on a real child — if a child looks worried rather than delighted,
  the reaction is wrong and must be softened.
- **Drag introduces the only way to "miss" in this game.** Resolved: a missed drop is completely
  silent — no sound, no wobble, no snap-back — the item simply stays in the rail, the drop target
  is far larger than the dog, and **tap always works as an alternative**, so a child whose fingers
  cannot yet manage a drag is never locked out. Drag is an addition, never a replacement.
- **The weather buttons and wardrobe tabs must carry no text.** Sun, rain and snow are pictures;
  categories are pictures of a hat, a face, a coat, a boot.
- **Touch targets:** wardrobe tiles ~120×120, weather buttons ~100×100, generously spaced. The rail
  must not need scrolling to reach a basic item.
- **Nothing startling:** no thunderclap, no lightning flash. Rain is soft, snow is silent, the
  camera flash on ta-da is a gentle white bloom, not a strobe.
- **A toy can be left, not finished.** There is no completion, so the home button matters more here
  than anywhere — leaving must always be one obvious tap.

## Open questions

- [x] **Does "dressed right" need every slot, or one key item?** **One key item.** Built that way:
      the warmth thresholds are wide, so a snow coat alone reaches `justRight` in the snow. Most
      outfits land in the comfortable middle. Still wants a child to confirm it is not *too* easy.
- [ ] **Three weathers or four?** Sun/rain/snow to start; wind is tempting but has no obvious
      clothing answer a child would know.
- [ ] **Does the going-out moment re-fire?** If every correct change triggers it, it may get
      tiresome; if it fires once per weather, changing clothes afterwards may feel flat.
- [ ] **Are combo jokes worth it** (hat + glasses + bow tie = a fancy-dog fanfare), or does the
      weather layer already supply enough to discover?
- [ ] **How many items per slot** before the rail gets crowded or needs scrolling?
- [ ] Do we keep the outfit shelf at all, or is it an adult's idea of fun?
- [x] This game is mostly art. **How much is worth building against placeholder shapes?**
      **All of it except the comedy.** Mechanics, layout, targets, weather and sound wiring are
      built and tested against a shape-drawn dog; the reactions are tweened stand-ins. Whether a
      shivering dog reads as funny rather than sad cannot be settled without real art and a child.

## Built so far

The first slice (2026-09-18, [session](../../sessions/games/dress-the-dog-session.md)): the dog,
the wardrobe rail, the weather switch, and the full clothes-plus-weather reaction — playable, with
placeholder art, **never yet run on a device**. Drag-and-drop was added in the same session,
alongside tap.

Not built yet, still wanted: the silly paw button, the ta-da button and outfit shelf, the
go-outside animation (the just-right moment currently plays the shared celebration cue only), and
combo jokes.

## Done when

A child picks the weather, dresses the dog however they like, laughs at what the dog does about it,
discovers that dressing it for the weather sends it out to play, does that a few times, and leaves
when they want to — with no adult speaking, nothing to fail, and no moment where the dog looks
genuinely unhappy.
