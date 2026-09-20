# Vision — public resources for game ideas (session)

- Date: 2026-09-20
- Scope: none — this was a research ask, not a feature. Output landed in
  [`../../vision/references.md`](../../vision/references.md) and
  [`../../vision/roadmap.md`](../../vision/roadmap.md).
- Status: done

## Goal

Find out what public material exists to draw mini-game ideas from, and whether anything out there
either gives us a better idea than the roadmap already has, or evidence for the design rules in
`CLAUDE.md`. No code change intended.

## What changed

- **New:** [`docs/vision/references.md`](../../vision/references.md) — the reading list, in five
  parts: open-source projects built under our constraints, the design research behind our rules,
  Flutter/Flame/Rive resources, free art and sound sources, and commercial apps worth playing.
  It ends with a section naming what the research did *not* establish.
- **Updated:** [`docs/vision/roadmap.md`](../../vision/roadmap.md) — three new candidate games
  (**Music Maker**, **Shadow Match**, **Day & Night**), a note on why those three and not others,
  and a pointer to `references.md` from the intro.
- **Updated:** [`docs/STATUS.md`](../../STATUS.md) — index row for the new doc.

No Dart was touched.

## Decisions & alternatives

- **Three ideas adopted, not ten.** The two closest projects
  ([tiny-explorers](https://github.com/xia0mingx/tiny-explorers),
  [little-explorer](https://github.com/pazarman/little-explorer)) between them list well over forty
  games. Adopting more would fight the roadmap's own *"five or six, not fifty"*. The three chosen
  are the ones that fill an actual gap: the roster was leaning quiz-shaped, with a right answer in
  most entries, and these three have no right answer at all.
- **Balance Scale rejected** despite being a clean mechanic — it needs a working notion of
  *heavier*, which is past where most five-year-olds are. Recorded in `references.md` with the
  reason, so it does not get re-proposed as a fresh idea.
- **Ideas only, no code or art taken.** little-explorer is MIT and would need attribution if copied;
  tiny-explorers' licence was not established. Cheaper to re-implement a one-sentence mechanic than
  to carry a licence obligation nobody documented. Stated as a banner at the top of
  `references.md`.
- **The reading list went in `vision/`, not `scope/`.** It is not an ask and has no acceptance
  criteria; per [`ABOUT-DOCS.md`](../../ABOUT-DOCS.md), `vision/` is where the imagined roster and
  the deliberate never-do list live, and this feeds exactly that. A `scope/games/` doc still has to
  be written before any of the three new candidates is built.
- `docs/sessions/vision/` is a **new topic folder**. Sessions previously only had
  `setup/`, `games/` and `shared/`; a vision-level session had no home.

## Tests

Nothing executable changed, so there is no green output to paste. What was checked instead:

- Every relative link in the two new/edited docs resolves to a file that exists (checked with a
  link-extraction pass over `docs/vision/*.md`; output pasted below).
- `flutter analyze` / `flutter test` were **not run** — no Dart, asset or `pubspec` change in this
  session, so neither could be affected.

```
$ python3 <link-check>   # every relative link in docs/vision/, anchors stripped
docs/vision/references.md: 7 relative links, 0 broken
docs/vision/roadmap.md: 3 relative links, 0 broken
```

**Not verified — named per the rules in `ABOUT-DOCS.md`:**

- **No repository listed was cloned, built or played.** Every game list in `references.md` comes
  from reading that project's README, nothing more. If one of the three adopted ideas gets scoped,
  play the original first.
- **Licences were not audited** beyond what each README states.
- The **NN/g paid report was not read.** The 2 cm touch-target figure comes from their free
  article; the 2 cm → ~80 logical px conversion is arithmetic on a typical tablet density, not a
  measurement.
- No device or simulator run happened, because nothing ran.

## Kid-rules check

Not applicable in the usual sense — nothing shipped that a child can touch. The check the research
*did* perform, on our rules rather than on new code:

- [x] Playable with no reading — both closest projects independently arrived at the same rule
  (*"no reading required — every instruction is spoken aloud"*), which is mild confirmation the rule
  is normal for the genre rather than unusually strict.
- [x] Touch targets ≥ 80×80 — NN/g recommends ≥ 2 cm × 2 cm for young children, ≈ 75–80 logical px
  on a tablet. **Our rule sits on the research line, not above it — there is no slack to give
  back.** tiny-explorers independently landed on 88 px.
- [x] No failure state — matches all three comparable projects. Also underpinned by the Fred
  Rogers / NAEYC position statement's learning-readiness fundamentals, one of which is *times of
  solitude*: the same conviction as this roadmap's "a child putting the tablet down is a fine
  outcome", reached independently. Good ammunition against streaks or daily rewards.
- [x] No network calls, no new dependency — nothing was added to `pubspec.yaml`. The art sources in
  `references.md` are download-and-commit, not packages.
- One thing to carry forward: NN/g notes **dragging is genuinely hard at this age** while tapping
  and swiping are easy. **Shape Sorter** and **Simple Puzzle** are both drag-based; both should
  offer a tap fallback the way Dress the Dog already does. Worth writing into their scope docs.

## Debugging

None — nothing broke, nothing ran.

## Scope updates

- [`../../scope/little-games-scope.md`](../../scope/little-games-scope.md) open question *"Which
  mini-games follow Balloon Pop?"* is **still open** — deliberately. The candidate pool grew and is
  better justified, but choosing the next game is the maintainer's call, not this session's.
- Nothing promoted to a README; no code area was affected.

## Follow-ups

- Pick one of the three new candidates and write its `scope/games/<name>-scope.md`. **Day & Night**
  is the cheapest: no new mechanic, tap-only, and it reuses the living-sky work already built for
  Balloon Pop.
- Add the tap-fallback requirement to Shape Sorter and Simple Puzzle when either is scoped.
- If real art is ever budgeted, start at **Kenney** (CC0, no attribution) — see
  [`references.md` §4](../../vision/references.md#4-art-and-sound--for-when-the-placeholders-go).
- When sourcing a Rive character, check the file exposes **data-binding view models** and not the
  removed state-machine *inputs*, or it will not drive from our code.
- `STATUS.md` updated: yes.
