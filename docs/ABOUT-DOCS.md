# About these docs

How `docs/` is organized and which folder a given note belongs in. This is the local adaptation of
the working method used across the family of repos (the `rubix-ai` app's
`app/docs/ABOUT-DOCS.md` is the parent copy). Same discipline, different subject: this repo builds
a **Flutter/Flame mini-game app for 5-year-olds**, fully offline, with no backend at all.

The docs track a feature through three stages — **what we want → how we built it → what shipped**:

```
docs/
├── scope/      ← "hey, we want this"   — the ask, before any work
├── sessions/   ← the AI-agent sessions — what was done, while doing it
├── vision/     ← the north star        — where the app is going
├── testing/    ← the runbooks          — how to drive the app by hand, on a real device
└── debugging/  ← the working history   — every issue and how it became working
```

Top-level guides tie it together: [`STATUS.md`](STATUS.md) (the live "where are we" dashboard),
[`SCOPE-WRITTING.md`](SCOPE-WRITTING.md) (how to write a scope), [`HOW-TO-CODE.md`](HOW-TO-CODE.md)
(how to build one), and [`FILE-LAYOUT.md`](FILE-LAYOUT.md) (how to lay out the Dart).

## What is different here from the parent copy

The parent app talks to two backends (`rubix-ai`, `rubix-auto`) behind one port, so it carries a
`products/` axis and a hard rule that nothing is proven until it has read from a **live node**.

**Neither applies here.** This app:

- makes **no network calls at all** — that is a kids-privacy requirement, not just a simplification,
  so there is no `products/` folder and no product label on index rows;
- has no gateway contract to land upstream, so there is no `WORKFLOW-LB.md` — every change is an
  app change;
- replaces "tested against a live node" with **"tested on a real device or simulator"** (see
  [Rules for AI sessions](#rules-for-ai-sessions-required) below). A game is not proven by
  `flutter test` alone: touch targets, animation feel, and sound are only real under a thumb.

The audience is also different. The parent app's readers are engineers driving a building-automation
gateway. This app's reader is **a parent and a five-year-old**, and the person maintaining it is
learning Flutter. So docs here lean explanatory: say *why* a constraint exists (store policy,
child development, Rive API version) rather than assuming it is known.

## The three stages

### `scope/` — what we want

The **intent**, written *before* the work: the goal, rough requirements, constraints, open
questions. One file per feature/ask under a topic subfolder (`scope/<topic>/<name>-scope.md`).
Don't write it from scratch — follow [`SCOPE-WRITTING.md`](SCOPE-WRITTING.md).

Topics here are `setup/` (project, tooling, platform config), `games/` (one per mini-game), and
`shared/` (the reusable pieces under `lib/shared/`).

### `sessions/` — the AI agent session

The **working log** of a Claude Code session — what was explored, decided, and changed *while doing
the work*. One file per session under the matching topic subfolder
(`sessions/<topic>/<name>-session.md`). Captures *how* it got done and *why*, not just that it did.

### Shipped truth

There is **no doc-site**. Durable, reader-facing truth lands in the repo's
[`README.md`](../README.md), in [`CLAUDE.md`](../CLAUDE.md) (the rules every future session must
follow), and in area READMEs beside the code — `lib/shared/README.md` and
`lib/games/<game>/README.md` are the pattern: a decision record living next to what it decided.

## `testing/` — the runbooks

How to drive the app by hand: which device, what to tap, what should happen. Every runbook is
walked on a real target (an Android device/emulator, an iOS simulator, or `-d macos`) and the real
result recorded before it lands.

Because the player cannot read, a runbook here has a section a normal app's would not: **what a
child does without instruction**. Note where a tester had to be *told* what to tap — that is a
design bug, not a tester problem.

This answers "how do I drive this right now"; `debugging/` answers "this broke once, here's the
cause and fix".

## `debugging/` — the working history

Append-only. Every issue and how it became working: `debugging/<area>/<symptom>.md` + a row in
[`debugging/README.md`](debugging/README.md). On resolution, fill in root cause + fix and add a
regression test.

Name the file after the **symptom as observed**, not the eventual cause — that is what the next
person searches for. Good names look like `balloons-froze-after-celebration.md` or
`rive-character-invisible-on-android.md`; bad ones look like `fix-null-check.md`.

## `vision/` — the north star

Where the app is going beyond the current slice: the roster of mini-games we imagine, what "done"
would look like, what we have deliberately decided never to do.

---

## Rules for AI sessions (required)

**Documentation is part of every task, not an afterthought.** A session that changed code or
decisions but wrote no docs is **incomplete**.

### At the start of a session
1. Read [`../CLAUDE.md`](../CLAUDE.md) — it is the binding rulebook (stack, Rive API, design rules,
   kids-policy rules, code structure). Then [`../README.md`](../README.md).
2. Read [`FILE-LAYOUT.md`](FILE-LAYOUT.md) before writing code.
3. Read the `scope/<topic>/` doc covering the work. If there isn't one, **write it first** —
   see [`SCOPE-WRITTING.md`](SCOPE-WRITTING.md).
4. Create the session doc `sessions/<topic>/<name>-session.md` from the template below.

### While working
- Keep the session doc updated as you go — it is the working log, not a final report.
- Record the alternative you rejected and *why*.
- If the scope was wrong, update the `scope/` doc — don't silently diverge.
- **Check the API, don't recall it.** Package versions move (Rive 0.14 broke its whole Flutter
  API). Verify against `pubspec.lock` and the installed source in `~/.pub-cache`, not memory.

### At the end of a session
- Resolve or update open questions in the relevant `scope/` doc.
- Test the change (see below) and paste the green output into the session doc.
- Cross-link scope ↔ session ↔ any README the change touched.
- Move [`STATUS.md`](STATUS.md).

### Testing & debugging are part of the session
- **Test it** in the same session; show the green output. "Tests later" is not allowed.
- **On a real target.** `flutter test` covers widgets and logic; gameplay is not proven until it has
  run under a finger. Build for the platform (`flutter build apk`, `flutter build ios --simulator`)
  and where possible run it (`flutter run -d macos`). If a target genuinely cannot be reached from
  the current machine, **say so explicitly in the session doc** and name what is left unverified —
  never let a `flutter test` pass stand in silently for a device run.
- **Check it against the kid rules**: no text needed to play, touch targets ≥ 80×80 logical px, no
  failure state, no timer that can cause a loss, a visible home button, no network call.
- **Log the debugging**: open a `debugging/<area>/<symptom>.md` entry as you investigate; on
  resolution add root cause + fix + a regression test and update `debugging/README.md`.

### Definition of done for a session
Work complete **and** the session doc exists and is filled in **and** the change is tested on a real
target (or the gap is named) **and** it passes the kid-rules check **and** any debugging is captured
with a regression test **and** the scope doc's open questions are current **and** `STATUS.md`
reflects the new state.

### Session doc template

```markdown
# <Topic> — <short title> (session)

- Date: YYYY-MM-DD
- Scope: ../../scope/<topic>/<name>-scope.md
- Status: in-progress | done | blocked

## Goal
What this session set out to do.

## What changed
The concrete edits/decisions (link files as path:line where useful).

## Decisions & alternatives
- Chose X over Y because …

## Tests
What was tested and the **green command output pasted here** — including the real-target run.
If a target could not be reached from this machine, say which and what is unverified.

## Kid-rules check
- [ ] Playable with no reading
- [ ] Touch targets ≥ 80×80
- [ ] No failure state, no punishing timer
- [ ] Home button present and obvious
- [ ] No network calls

## Debugging
Links to any `debugging/<area>/<symptom>.md` entries, each with its regression test.

## Scope updates
Which scope open questions resolved; anything promoted to a README.

## Follow-ups
- Open questions pushed back to the scope doc; STATUS.md updated?
```
