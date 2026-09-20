# Games — Neil the Seal (session)

- Date: 2026-09-20
- Scope: [../../scope/games/neil-the-seal-scope.md](../../scope/games/neil-the-seal-scope.md)
- Status: done

## Goal

Build the sixth mini-game from its scope: an enormous elephant seal who galumphs
wherever the child taps, flops onto whatever is there, and leaves the town
exactly as he found it.

## What changed

**The game** — `lib/games/neil_the_seal/`, and a
[README](../../../lib/games/neil_the_seal/README.md) beside it:

| File | What it is |
|---|---|
| `town.dart` | Pure data: 18 prop kinds, five locations as lists of placements, and the oblique projection. No Flame, no canvas. |
| `world.dart` | Pure simulation: Neil's galumph, the squash and springback, the creatures getting clear, the dots, the nap, the bellow round. |
| `components/neil_painter.dart` | Neil, plus his face on its own (the bellow button wears it). |
| `components/town_layer.dart` | Props and Neil, depth-sorted in one pass. |
| `components/town_backdrop.dart` | Sky, sea, ground, cross-fading between locations. |
| `components/progress_shells.dart` | The scope's progress dots, as scallop shells. |
| `components/bellow_button.dart` | 140×140, bottom-right, wearing Neil's face. |
| `neil_the_seal_game.dart` / `_screen.dart` | Wiring, and the whole screen as one control. |

**Sound** — this game is built around its noises more than any other, so it
brought fourteen new placeholder cues: `flump` (×2), `boing` (×2, the sink and
the springback), `squelch`, `bellow` (×2), `snore`, `wriggle` (×2) and the five
`answer` voices the town replies with. Added to `tools/make_sfx.py` with a new
`bend()` helper (a tone whose *pitch* is the shape — a boing is a pitch wobble,
not a hit), then `lib/audio/sounds.dart` and `lib/shared/kid_sounds.dart`.

**ffmpeg with libmp3lame is on this machine now**, which it was not when
STATUS.md recorded "no mp3 encoder here". The new cues are encoded and checked
in; the existing mp3s were not touched.

**The menu** grew a sixth tile, which broke the single row on a short landscape
phone. Fixed by shrinking the *spacing* rather than the tile — 88 is the
kid-rule floor and may not give way. (A parallel session has since rewritten
that layout to wrap to two rows at seven games, keeping this tile and its
comment.)

## Decisions & alternatives

**Tap-to-go over drag.** The scope's first open question. Tap-to-go is the new
verb and the reason the game exists; drag is Car Trip's control, and his weight
is better felt when the child cannot pull him. Drag remains the fallback if a
real child never discovers tapping — though the very first touch anywhere makes
an enormous seal set off, so discovery should be automatic. **No hint is
drawn**, unlike Car Trip's pulsing hand, for exactly that reason.

**One screen per location, not a scrolling town.** Everything worth sitting on
is visible from wherever he is. A child never has to discover that the game
continues off-screen.

**The dots stay.** The scope wondered whether this game is honestly a toy rather
than a game. Kept them because the nap is the best thing in it and the dots are
what bring it round — but they are five against seven or eight floppable things
per location, so there is always something left and never a set to complete.

**Creatures may leave the town; Neil may not.** Chosen after the "nothing alive
is ever squashed" test caught a real hole: with both confined to the same box, a
determined child could pin a seagull into a corner. Giving creatures a wider box
(`creatureMargin`) makes the rule a guarantee instead of a hope, and matches Car
Trip's ducks wandering off into the field.

**Rubbing him does not interrupt a trip.** Considered stopping him ("goes
completely floppy"), rejected: rubbing him on the way somewhere is a perfectly
good thing to want to do, and stopping him would feel like the control being
taken away.

**A tap during the nap bumps the town instead of being ignored** — the nap is
the one moment he cannot be sent anywhere, and "there is nowhere on the screen
that does nothing" still has to hold.

**Bottom-right for the bellow, wearing Neil's face.** Car Trip's horn is
bottom-left with a megaphone icon; two games with the same useless-button gag in
the same corner start to look like one game. A speaker icon would read as a
volume control — the only way to tell a non-reader what a button does is to show
them the thing that does it.

## What looking at it changed

Four real problems were invisible to a green test suite and obvious in a
screenshot:

1. **Neil covered the car he was sitting on.** The signature move of the whole
   game happened underneath him. Fixed by lifting him onto the prop's squashed
   height.
2. **He was drawn as a ball, not a mound** — the body rect was twice its
   intended height and hung below the ground line. He loomed instead of
   lounging.
3. **The car read as flattened rather than sunk.** Fixed by drawing the wheels
   outside the squash, so the body comes down onto them.
4. **A patch of dry sand on a sandy beach was invisible** — a prop a child
   cannot see is a prop they cannot choose. It now has a rim and ripples.

Plus: he could walk to the screen edge and be clipped in half (the walkable box
now sets in by more than half his length), the beach boat lay across where he
wakes up, and a seagull started standing inside him on the beach — so a new
location opened with the town scattering away from him, which is the one thing
this game may not get wrong.

## Tests

`flutter analyze`:

```
Analyzing game-demo...
No issues found! (ran in 1.3s)
```

`flutter test --exclude-tags render`:

```
00:13 +387: All tests passed!
```

(Mid-session this suite showed one failure in `test/crystal_party_render_test.dart` — a **parallel
session's in-flight game**, not touched here. It was green by the end.)

Neil's own suites, run alone:

```
00:03 +45: All tests passed!      test/neil_the_seal_test.dart
00:03 +21: All tests passed!      test/neil_the_seal_screen_test.dart
00:00 +16: All tests passed!      test/neil_the_seal_render_test.dart  (--tags render)
```

Two cues were also added to `test/sounds_test.dart`, generalising the mix rule now that one game
has brought seven new `SfxType`s: **no kid cue may be louder than the celebration or quieter than
the wobble**, whatever gets added later.

What the 45 pin, beyond the obvious: the heave's mean matches the curve that
generates it; he crosses the screen in 3.2–4.8s; `clearSpeed` beats his fastest
heave; a minute of being driven straight at a living thing in every location
never reaches one; a whole town walked over is left exactly as it was found;
every near-miss tap on every prop in every location lands on something; and — the
Cat Run lesson — **pixel-level** checks that the heave, the landing wobble and
the squash are actually *drawn* rather than merely calculated.

### On a real target

**Run in Chrome, and driven.** `flutter build web` → served → a Chrome DevTools
Protocol session that taps the town, changes his mind mid-trip, drags to rub
him, presses the bellow four times, and fills the shells to the nap.
**No console errors or warnings** across the whole session. Screenshots confirm:
he walks, he lands on the car, the car sinks on its wheels, shells fill, and he
wakes up at the boat ramp with the town reset.

**Not verified:** iOS and Android (no device or emulator reachable from this
machine), macOS, haptics (no vibrator), and **none of the fourteen new sounds
has been listened to** — they were checked numerically (all peak at −3.5 dBFS,
no clipping) and by design, never by ear. The boing is the sound this whole game
rests on and nobody has heard it.

## Kid-rules check

- [x] Playable with no reading — no text anywhere; the bellow button is a
      picture of the animal that bellows
- [x] Touch targets ≥ 80×80 — pinned by test at the smallest supported screen
      *and* at the back of the town, where perspective makes everything
      smallest; Neil is a hand-sized target for rubbing; both buttons ≥ 140/96
- [x] No failure state, no punishing timer — nothing to lose, nothing to miss,
      the nap ends by itself, and the only thing that "runs out" is his patience
      for staying awake
- [x] Home button present, in its usual corner, and proven clear of the bellow
      button at every screen size
- [x] No network calls, no SDKs, no stored personal data

## Debugging

No `debugging/` entry: nothing here was a regression in shipped code. The four
drawing problems and the creature-corner hole were all found and fixed inside
this session, each with the test that would now catch it.

## Scope updates

Resolved in [the scope doc](../../scope/games/neil-the-seal-scope.md): tap-to-go
vs drag, one screen vs scrolling, dots vs no dots, honk-as-button, and the Rive
question. Left open for a real child: how slow is funny, whether the self-snore
idle rewards putting the tablet down, the pademelon, the shared cone, and
whether the name ships.

## Follow-ups

- **Listen to the sounds.** Fourteen new cues, none heard.
- The hose borrows the squelch; it wants a hiss of its own.
- Neil is the obvious job for the shared Rive character — see `assets.dart`.
- STATUS.md updated.
