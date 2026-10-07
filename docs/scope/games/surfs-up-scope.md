# Games — Surf's Up (scope)

- Date: 2026-10-07
- Status: built: playable, **approved SVG cast** + scenery drawn in code. Driven in Chrome over CDP
- Session: [../../sessions/games/surfs-up-session.md](../../sessions/games/surfs-up-session.md)
- Code: [`lib/games/surfs_up/`](../../../lib/games/surfs_up/) and its
  [README](../../../lib/games/surfs_up/README.md)
- Source spec: [`game-script/LANTERN_ISLAND_SPEC.md`](../../../game-script/LANTERN_ISLAND_SPEC.md)
  §8 ("Surf's Up — Koko — ride gentle waves, pop up on the board, collect shells")

## Why

The maintainer dropped in the **Lantern Island** spec: six animal friends (Koko the quokka, Biggy,
Luna, Tobi, Tiko, Pacho) with approved soft-outline SVG art, and a long roadmap (island map,
three languages, Word Jar, Lantern Night, restyling the old games, new character games). The ask
was "get coding".

That spec is a whole product. The first runnable slice picked here is **one new character game
using the approved cast**, because:

- it is a journey game (the maintainer's preference), not a sandbox;
- it is self-contained (CLAUDE.md §5: a game owns its folder) and touches nothing that works;
- it proves the SVG cast renders in Flame, which every later Lantern Island step needs.

The verb is new: **catch the moment**. Little Train's target waits for the child; here it comes from
behind and goes past.

## Requirements

- Koko sits on her board. Swells roll in from behind. **A tap as one lifts her** = pop up and ride.
- While riding, **a tap is a hop**. Low shells are free; high ones (in a bubble) need a hop.
- Three waves per trip, shown as three filling dots. Then the beach, with three friends waiting,
  and a party. Then the next beach: morning → midday → soft sunset, different friends each time.

## Kid-rules impact

- **A swell can be missed.** Resolved: another always comes, and after 2 misses in a row Koko catches
  the next one herself. A child who never taps still reaches every beach (tested).
- A tap too early is a paddle with a splash, never a "wrong".
- A missed high shell just floats on. Shells are a bonus; the progress is the waves.
- The whole screen below the home button's band is the control.
- No text. Names live in one config (`lib/shared/lantern_cast.dart`) and are never shown.

## Where this departs from the Lantern Island spec

CLAUDE.md wins over a scope doc, so:

- **Age 5, not 3–7.** The kid rules here are the binding ones.
- **No spoken words yet**, so no counting aloud and no home-language words. Voice is the next step
  for this game (see Open questions).
- **Not done:** the island map, Word Jar, languages, Lantern Night, restyling old games, adaptive
  difficulty. Each is its own scope.

## Open questions

- Voice lines for Koko ("Here it comes!", "Up!", counting shells "one, two, three…") via the
  Gemini TTS pipeline — needs a `GEMINI_API_KEY` session. Also an Australian English voice?
- Should the island map (spec phase 2) replace the picture menu, or sit behind one tile?
- Real surf music instead of the template's track.
