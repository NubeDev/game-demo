# Public references — where game ideas and assets come from

Researched 2026-09-20. The external material worth knowing about when picking the next mini-game,
defending a design rule, or replacing placeholder art.

This sits in `vision/` because it feeds the [roadmap](roadmap.md), not any one game. It is a
**reading list, not a rulebook** — [`../../CLAUDE.md`](../../CLAUDE.md) is still the binding
document, and nothing here overrides it.

> **Licence discipline.** Everything below is used for *ideas and mechanics*. Copying code or art
> needs its licence checked first, and most of these were not checked. The one hard rule: nothing
> enters this repo that would drag in a network call, an SDK, or an attribution obligation nobody
> wrote down. See [kids store and privacy rules](../../CLAUDE.md#4-kids-store-and-privacy-rules).

---

## 1. Open-source projects built under the same constraints

These matter more than the general "educational apps for kids" lists, because their authors already
filtered for *our* constraints — no reading, offline, no failure state, big targets. Their game
lists are a pre-filtered idea pool.

### [tiny-explorers](https://github.com/xia0mingx/tiny-explorers) — the closest match

A tablet-first learning app for 2–5 year olds. Its stated rules are almost ours: **88 px minimum**
on anything interactive ("because toddlers aim badly and plant a whole fingertip rather than a
point"), and "nothing is timed, nothing can be lost, no score goes down".

| Its games | Ours? |
|---|---|
| Counting, Shapes, Patterns, Tracing, Mazes, Spot It | Counting/Shapes already on the [roadmap](roadmap.md) |
| **Shadows** — match an object to its silhouette, 2 → 4 options, including mirrored | **new idea, adopted** |
| **Balance Scale** — comparison, up to 8 items a side | new idea, not adopted (needs a concept of *heavier*, which is a stretch at 5) |
| Free play: Drawing, Dress-Up, Dot-to-Dot, Drive, Gear Machine | Dress-Up ≈ our Dress the Dog |
| **Music Maker** — a *pentatonic* sequencer, so every combination sounds pleasant | **new idea, adopted** |

The pentatonic detail is the single best thing found in this research. A pentatonic scale has no
combination that sounds wrong, which makes it the musical form of our "no way to lose" rule —
a free-play toy where the child cannot produce a bad result. Worth stealing exactly.

### [little-explorer](https://github.com/pazarman/little-explorer) — the widest idea list

MIT-licensed, ~38 games for ages 2–4, offline PWA. Its rules read like ours verbatim: *"No reading
required — every instruction is spoken aloud"*, *"Big tap targets, no fail states, no time
pressure"*, data local only. Worth skimming the whole list; the ones that fit a 5-year-old and our
rules:

- **Day & Night** — tap the sun or the moon, the scene and its sounds change. **Adopted:** a pure
  cause-and-effect toy with no correct answer at all.
- Three Cups, Big & Small, Tall or Short, Sort It — comparison and sorting, all one-tap
- Who Says? / Animal Band — ≈ our Animal Sounds candidate
- Pet Care, Hide & Seek, Go Find It, Feelings, Five Senses

A caution about it: 38 games is the opposite of this repo's deliberate *"five or six, not fifty"*
([roadmap](roadmap.md)). Mine it for loops, not for ambition.

### Also worth a look

- **[eduActiv8](https://www.eduactiv8.org/)** — open source, maintained since 2011. Flashcards,
  mazes, matching, interactive worksheets. Longest-running of the bunch, so its activity set is
  battle-tested by real classrooms.
- GitHub topics **[kids-games](https://github.com/topics/kids-games)** and
  **[preschool](https://github.com/topics/preschool)** — the general trawl, when the above run dry.

---

## 2. Design research — the evidence behind our rules

Useful for two things: settling an argument about a number, and knowing which of our rules is
load-bearing versus merely a preference.

### Nielsen Norman Group

- **[Design for Kids Based on Their Stage of Physical Development](https://www.nngroup.com/articles/children-ux-physical-development/)**
  recommends **≥ 2 cm × 2 cm** touch targets for young children — four times the 1 cm adult
  minimum. On a typical tablet that lands around 75–80 logical pixels, so **our 80×80 rule is
  sitting right on the research line, not above it**. That is the citation to reach for when
  somebody proposes shrinking a button. It also notes that *dragging* is hard for young children
  while tapping and swiping are easy — relevant to Shape Sorter and Simple Puzzle, both of which
  are drag-based and should keep a tap fallback the way Dress the Dog does.
- **[Designing for Kids: Cognitive Considerations](https://www.nngroup.com/articles/kids-cognition/)**
  — 3–5 year olds are *pre-operational*: they reason in icons and symbols, and cannot interpret
  abstract navigation or hierarchy. Supports the flat picture menu and argues against ever adding
  a second level of menu.
- **[UX Design for Children (Ages 3–12), 4th edition](https://www.nngroup.com/reports/children-on-the-web/)**
  — 156 tips from testing 80 websites and 36 apps. **Paid**; the free articles above carry most of
  what we need, so this is a "if we ever have budget" item.

### Early-childhood-education sources

- **[NAEYC / Fred Rogers Center joint position statement](https://www.naeyc.org/sites/default/files/globally-shared/downloads/PDFs/resources/position-statements/ps_technology.pdf)**
  (free PDF) — the authoritative educator view on interactive media for under-8s. Fred Rogers'
  six learning-readiness fundamentals — *self-worth, trust, curiosity, the capacity to look and
  listen, the capacity to play, and times of solitude* — make a good screen for a candidate game:
  does this build one of those, or just fill time? Note that **"times of solitude"** is the same
  conviction as the roadmap's *"a child putting the tablet down is a fine outcome"*, arrived at
  independently. That is the strongest argument we have against ever adding streaks or daily
  rewards.
- **[5Rights — Child Rights by Design](https://cms.childrightsbydesign.5rightsfoundation.com/wp-content/uploads/2023/04/CRbD-spread_web.pdf)**
  (free PDF) — 11 principles for building digital products for children. Supporting material for
  our privacy rules if a store review ever needs an argued position rather than a checkbox.

---

## 3. Flutter, Flame and Rive

- **[awesome-flame](https://github.com/flame-engine/awesome-flame)** — the curated list of Flame
  games, libraries, tutorials and articles. First stop for *"how is this mechanic normally built"*.
- **[flame-games](https://github.com/flame-games)** — small, readable sample games. `push_puzzle`
  is directly relevant to the Simple Puzzle candidate; `breakout` and the isometric RPG are useful
  for reading how others structure a Flame world.
- **[awesome-rive](https://github.com/rive-app/awesome-rive)** — runtime examples and articles.
  Handle with care: **Rive 0.14 replaced its whole Flutter API**, so anything written before it is
  wrong for us. Cross-check every example against
  [`CLAUDE.md` §2](../../CLAUDE.md#2-the-rive-api--use-the-new-one) and the installed source in
  `~/.pub-cache` before believing it.
- The [official flame_rive example](https://github.com/flame-engine/flame/tree/main/packages/flame_rive/example)
  remains the reference already named in `CLAUDE.md`.

---

## 4. Art and sound — for when the placeholders go

All placeholder art here is coloured shapes drawn in code, by design. When that changes, these are
the no-cost routes. Because every game keeps its asset paths in one `assets.dart`
([`CLAUDE.md` §5](../../CLAUDE.md#5-code-structure)), swapping placeholders for real files is a
one-file edit per game.

| Source | Licence | Why |
|---|---|---|
| **[Kenney](https://kenney.itch.io/kenney-game-assets)** | **CC0**, no attribution required | 60,000+ assets including audio, bright flat style that suits this age. The best single source for a team with no artist, and CC0 means no attribution file to maintain. |
| **[itch.io, filtered to CC0](https://itch.io/game-assets/assets-cc0)** | CC0 | Broader than Kenney; still no attribution obligation. |
| **[Rive Community / Marketplace](https://rive.app/community/files/tag/Characters/)** | mixed, free and paid | Where a real character for `RiveCharacter` could come from. These ship with state machines, which is what we need — but check whether a file's state machine exposes **data-binding view models** rather than the removed *inputs*, or it will not drive from our code. |
| **[OpenGameArt](https://opengameart.org/)** | mixed (CC0 / CC-BY / GPL) | Deep archive; every file needs its licence read individually. |

---

## 5. Commercial apps worth playing, as research

Not resources — competitors, and the benchmark for "no reading, no losing" done well.

- **Toca Boca** and **Sago Mini** — open-ended toys with no goals at all. The reference point for
  the free-play half of our roster (Day & Night, Music Maker, Animal Sounds).
- **ScratchJr** — free and open source, and genuinely usable by a pre-reader. Good study in how
  far you can get with symbols alone.
- **Monkey Preschool Lunchbox** — the short-mini-game loop, which is structurally what this app is.
- **[Common Sense Education's preschool game list](https://www.commonsense.org/education/lists/educational-games-for-preschool-and-kindergarten)**
  — a vetted index, useful for finding more without wading through app-store SEO.

---

## What this research did *not* settle

Named explicitly so a future session does not assume otherwise:

- **No repo here was cloned, built or played.** The game lists above come from their READMEs.
- **Licences were not verified** except where stated (little-explorer is MIT; Kenney is CC0).
  tiny-explorers' licence is unknown.
- The **NN/g paid report was not read**; the 2 cm figure comes from their free article.
- The 2 cm → ~80 px conversion is **approximate** and device-dependent. It says our 80×80 rule is
  defensible, not that it is exactly right. Only a real child on a real tablet settles that.
