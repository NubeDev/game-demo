# Games — Little Train (session)

- Date: 2026-10-06
- Scope: [../../scope/games/little-train-scope.md](../../scope/games/little-train-scope.md)
- Status: done. Playable with generated art, voice and music; played by the maintainer

## Goal

Use Google's Gemini API to generate characters and backgrounds (and, as it turned out, voice and
music) and build a whole new game around them. The method is written up for reuse in
[`GENERATING-ASSETS.md`](../../GENERATING-ASSETS.md).

## What changed

- **Generators:** [`tools/gen_little_train_art.py`](../../../tools/gen_little_train_art.py) (47
  pictures, chroma-keyed to `.webp`) and
  [`tools/gen_little_train_audio.py`](../../../tools/gen_little_train_audio.py) (10 voice lines + a
  Lyria music loop). Local venv and the raw cache are gitignored.
- **Game:** [`lib/games/little_train/`](../../../lib/games/little_train/): a pure `Ride` model,
  lands, three render layers, the game and the screen, plus a
  [README](../../../lib/games/little_train/README.md).
- **Shared/app:** `TrainLine` + `KidSounds.say` and `SfxType.kidTrainVoice`; `Song.loops` and an
  audio-controller change so a short loop repeats instead of rolling to the next track; a ninth
  palette colour (indigo); `GameTile.picture`, so the menu tile shows the generated engine; route
  `/little-train`.
- **Tests:** `little_train_test.dart` (18), `little_train_screen_test.dart` (12, three screen
  sizes), `little_train_render_test.dart` (writes frames to PNG for eyeballing).

## Decisions & alternatives

- **Generation is offline-at-build, never at runtime.** CLAUDE.md §4 stands untouched.
- **Style anchor plus reference images**, rather than a long style prompt alone. It is what kept 47
  pictures consistent.
- **Chroma key** rather than asking for transparency, because the model only returns JPEG.
- **Mirror-tiling** rather than asking the model for seamless tiles. A mirror seam always matches.
- **Every passenger boards** (chase if missed) rather than "try again at the next lap". A missed
  passenger who is gone forever is a loss.
- **Passengers in front of the track.** The first version had them behind it; see Debugging.

## Tests

```
flutter analyze   → No issues found!
flutter test      → 00:19 +577: All tests passed!   (544 before, 33 new)
flutter build web → ✓ Built build/web
```

**Run in Chrome over CDP** (1280×720, real touch events): menu → the ninth tile → rolling → a tap
brakes it → a passenger boards → the station party → the forest → the home button back to the menu.
No console errors or exceptions. **Then played by the maintainer**, who reported the result as much
better than the placeholder-art games.

**Not verified by this session:** any phone, tablet or iOS run; **sound** (the voice lines were
checked by duration and loudness only, the music by loudness and by asking Gemini to describe it);
haptics. A final browser replay was stopped by the maintainer before it ran.

## Kid-rules check

- [x] Playable with no reading: a paw-print stop sign and spoken lines
- [x] Touch targets ≥ 80×80: the whole screen below the home band; home button 96×96 (tested)
- [x] No failure state and no timer: every passenger boards; the train never sticks (tested,
      including under random taps)
- [x] Home button present and obvious
- [x] No network calls: generation happened on the dev machine; nothing in `lib/` reaches out

## Debugging

- **The train hid the passenger the child was stopping for.** It was found only in the browser run:
  render stills of single moments did not show it. Waiting passengers were drawn behind the train.
  Fix: `Passengers` is drawn twice, in front of and behind the train, and a leap switches layer at
  its top. Covered by eye (render frames), not by an assertion.
- **The first TTS line was 7.5 s.** The stage directions were spoken out loud, and a transcription
  check missed it. The fix is in the generator: transcript only, plus a duration ceiling.

## Follow-ups

- Listen to every voice line and the music on a device; check for lines talking over each other.
- Run on a real tablet and phone.
- Consider generated art for the eight placeholder games, using the same scripts.
