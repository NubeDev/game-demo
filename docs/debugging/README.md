# Debugging index

Append-only. Every issue and how it became working. One file per symptom:
`debugging/<area>/<symptom>.md`.

Name the file after the **symptom as observed**, not the cause — that is what the next person
searches for. `balloons-froze-after-celebration.md`, not `fix-null-check.md`.

| Symptom | Area | Status | Root cause | Regression test |
|---|---|---|---|---|
| _none yet_ | | | | |

## Entry template

```markdown
# <symptom as observed>

- Date: YYYY-MM-DD
- Area: <games/balloon_pop | shared | setup | platform>
- Status: investigating | resolved
- Session: ../../sessions/<topic>/<name>-session.md

## Symptom
What was seen, on what device, doing what. Exact steps.

## Investigation
What was ruled out, in order. Dead ends included — they are the useful part.

## Root cause
The actual mechanism.

## Fix
What changed, linked as path:line.

## Regression test
The test that now fails without the fix.
```
