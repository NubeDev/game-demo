# Roadmap — where Little Games is going

The north star beyond the current slice. Nothing here is committed; the committed asks live in
[`../scope/`](../scope/). The outside material these ideas were drawn from — other open-source
kids' apps, the design research behind our rules, and where free art will come from — is in
[`references.md`](references.md).

## The shape of the finished thing

A small, calm collection of mini-games — think **five or six**, not fifty — that a five-year-old
opens and plays alone, and that a parent trusts without reading a privacy policy. Quality and
consistency over quantity: each game feels like it belongs to the same world, uses the same
celebration, the same home button, the same character.

Growing it is adding a folder under `lib/games/` and a button on the menu. That is the whole
architecture, and it is deliberate.

## Candidate games

Each exercises something slightly different while staying inside the rules (no reading, no losing):

| Game | The loop | Exercises |
|---|---|---|
| **Balloon Pop** (first) | Balloons rise, tap to pop, celebrate every 10 | Cause and effect; tapping accuracy |
| **Dress the Dog** | Dress a dog, pick the weather, the dog reacts — funnily when the outfit is wrong | Weather and clothing sense; choice with no wrong answer |
| **Shape Sorter** | Drag a shape to the matching hole; wrong ones wobble back | Shape recognition; drag gestures |
| **Colour Match** | Tap the thing that matches the shown colour | Colour naming; visual matching |
| **Counting Friends** | Tap animals one at a time, each counts aloud | Early counting, one-to-one correspondence |
| **Animal Sounds** | Tap an animal, hear its sound and see it react | Association; pure delight, no goal at all |
| **Simple Puzzle** | Drag 3–4 big pieces into place | Spatial reasoning; persistence |
| **Music Maker** | Tap pads to build a tune | Rhythm and cause-and-effect; **pentatonic, so nothing can sound wrong** |
| **Shadow Match** | Tap the silhouette the animal belongs to | Visual matching that does not depend on colour |
| **Day & Night** | Tap the sun or moon; the scene and its sounds change | Nothing at all to get right — the purest toy in the set |

The last three came out of the 2026-09-20 survey of other open-source kids' apps
([references](references.md#1-open-source-projects-built-under-the-same-constraints)). They were
picked because the roster was leaning **quiz-shaped** — most of the earlier candidates have a right
answer, even a forgiving one. These three have none, which balances the set: half of it asks the
child something, half of it just answers back. Note the list is now longer than the "five or six"
above, and that is fine — it is a pool to choose from, not a queue to work through.

## Beyond the games

- **Real artwork and real Rive characters** replacing placeholders — the single biggest jump in
  how finished this feels.
- **A character with continuity** appearing across games, reacting to success, giving the app a
  face.
- **Voice cues** replacing some sound effects, so the game can gently *say* what to do. Needs a
  recorded voice and a localisation story.
- **Accessibility**: reduced-motion for the confetti, and sound-off play that loses nothing
  essential.

## Deliberately not going here

Written down so it doesn't get re-proposed:

- No accounts, no cloud, no cross-device sync.
- No ads, no IAP, no subscription.
- No social anything — no leaderboards, no sharing, no multiplayer.
- No progress reports or assessment for parents. This is play, not measurement.
- No daily streaks or engagement mechanics. A child putting the tablet down is a fine outcome.
