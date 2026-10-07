# Games — Surf's Up (session)

- Date: 2026-10-07
- Scope: [../../scope/games/surfs-up-scope.md](../../scope/games/surfs-up-scope.md)
- Status: done. Playable; driven in headless Chrome. Never run on a device, never heard

## Goal

Start building the Lantern Island spec (`game-script/`) with a first runnable slice. Chosen: Koko's
**Surf's Up** from spec §8, as the tenth menu tile, using the approved SVG characters.

## What changed

- **Assets:** the six cast SVGs copied to `assets/lantern_island/` as-is, plus `koko-surf.svg`
  (Koko with her leaning board and ground shadow removed, view box trimmed; the rest untouched).
- **Shared:** [`lib/shared/lantern_cast.dart`](../../../lib/shared/lantern_cast.dart): the
  `LanternFriend` enum (names in one place, as the spec asks) and `rasterizeSvg`, which draws an
  SVG into a `ui.Image` once at load. New dependency: `flutter_svg` 2.3.0 (added with
  `flutter pub add`; it parses local files, no network).
- **Game:** [`lib/games/surfs_up/`](../../../lib/games/surfs_up/): a pure `Surf` model, three
  beaches, layers for sky/sea/beach, Koko and her board, shells, the dots and the veil.
- **App:** route `/surfs-up`; a tenth palette colour (lime); `GameTile.picture` now takes an `.svg`
  path, so the tile shows Koko.
- **Tests:** `surfs_up_test.dart` (13: never-tap, tap spam, random taps, shells, hop buffer,
  dots never decrease, veil), `surfs_up_screen_test.dart` (9: three screen sizes),
  `surfs_up_render_test.dart` (writes PNG stills, tagged `render`).

## Decisions & alternatives

- **Surf's Up first, not spec phase 1 (restyling the old games).** The spec's own CLAUDE.md asks
  for a plan before each phase; the maintainer said "get coding", and the repo's CLAUDE.md says
  small runnable steps. A new game keeps every working game untouched.
- **SVG at runtime vs converting to PNG.** No rasteriser was installed, and the art will need
  layers later (the spec's expression system). `flutter_svg` + rasterise-once keeps frames cheap.
- **Scenery drawn in code, not generated.** No `GEMINI_API_KEY` in this session. The soft-outline
  style (flat fills, brown `#5A3A28` outline) is easy to draw in code and sits with the cast.
- **Sounds borrowed** from the existing set (`boing` springback for the pop-up, `flump` for a hop,
  the pop ladder for shells, `celebrate` at the party). No new audio.

## Found by looking, not by tests

- The friends looked like they were standing in the far sea: added a back beach up to the horizon.
- The board pitched down so steeply on the wave that Koko looked like she was falling: tilt is now
  60% of the slope, capped at 0.3 rad.
- **In the browser run only:** the back beach was closed down to the bottom of the screen and
  showed as a block of sand standing in the water as it slid in. The near sand also started at a
  cliff. Both now rise out of the sea, with the underwater slope tinted by the water.

## Verification

- `flutter analyze`: clean. `flutter test`: **602 passing** (25 new).
- Render stills at 1280×720, 1024×768 and 844×390, looked at.
- **Headless Chrome over CDP**, 1280×720, touch events: menu → Koko's tile → taps → three rides →
  party → the midday beach and its party. No console errors. Built with
  `flutter build web --no-web-resources-cdn`; the first frames came out blank, but that was a bug in
  the driver script (its viewport and reload steps never ran), not the CDN — the network was
  reachable, so the flag was probably not needed.

## Not verified

- **Never run on a phone, tablet or iOS.** Feel, timing of the catch window, and target size under
  a real thumb are unproven.
- **No sound heard.** The cues were chosen by name from the existing set.
- No voice: the counting and spoken prompts the spec wants are not there.
