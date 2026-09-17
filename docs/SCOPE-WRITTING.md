# How to write a scope

A scope is the ask, written **before** the work: what we want, why, and what would make it wrong.
It is not a design doc and not a task list. If it takes more than a page, the ask is too big —
split it.

One file per ask: `scope/<topic>/<name>-scope.md`. Topics are `setup/`, `games/`, `shared/`.

## The shape

```markdown
# <Topic> — <short title> (scope)

- Date: YYYY-MM-DD
- Status: proposed | agreed | building | shipped | dropped
- Session: ../../sessions/<topic>/<name>-session.md   (link once one exists)

## Why
The problem, in the player's terms. For a mini-game, this is what the child gets to *do*
and what it teaches or exercises. Two or three sentences.

## What
The concrete ask. Bullets. Each one testable by watching a child use it.

## Not this
What is deliberately out of scope, so the next reader doesn't "helpfully" add it.

## Kid-rules impact
Anything in this ask that pushes against the rules in CLAUDE.md — a timer, a score, a text
label, a sound that could startle. Name it here and say how it is resolved, or the review
will find it later.

## Open questions
- [ ] Unresolved decisions, each one owned. Resolve them in this file as they close.

## Done when
The observable finish line. "A child can play three rounds without an adult speaking."
```

## Rules

**Write it in the child's terms, not the code's.** "Tapping a balloon pops it with a happy sound"
is a scope line. "`BalloonComponent` implements `TapCallbacks`" is not — that is the session doc's
job.

**Every `What` bullet must be observable.** If you cannot tell whether it is done by watching
someone play, rewrite it until you can.

**Name the kid-rules tension up front.** Most feature ideas for a kids' game carry one: a score
invites losing, a timer invites failure, a label invites reading. The `Kid-rules impact` section
is where that gets resolved *before* it is built, not in review.

**Open questions stay in the scope doc.** Sessions link back and close them there. A question
answered only in a session log is a question the next reader will ask again.

**Status moves in the file and in [`STATUS.md`](STATUS.md).** Both, every time.
