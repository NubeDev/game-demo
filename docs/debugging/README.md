# Debugging index

Append-only. Every issue and how it became working. One file per symptom:
`debugging/<area>/<symptom>.md`.

Name the file after the **symptom as observed**, not the cause — that is what the next person
searches for. `balloons-froze-after-celebration.md`, not `fix-null-check.md`.

| Symptom | Area | Status | Root cause | Regression test |
|---|---|---|---|---|
| [Dress the Dog overflows the bottom of the screen on a phone](games/dress-the-dog-overflows-on-a-phone.md) | games/dress_the_dog | resolved | Layout built from hard-coded pixel offsets sized against a tablet | [`dress_the_dog_layout_test.dart`](../../test/dress_the_dog_layout_test.dart) |

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
