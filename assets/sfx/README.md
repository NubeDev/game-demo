# Sound effects

## `kid_*.mp3` — the cues the games actually use

Placeholder audio, synthesised by [`tools/make_sfx.py`](../../tools/README.md) in this repo.
Soft sine tones tuned to the kid rules in [`CLAUDE.md`](../../CLAUDE.md) §3: no transients, nothing
piercing, nothing that reads as a buzzer or a bang.

They stand in until real audio is recorded. Replacing them means dropping new files in under the
same names — no Dart changes.

| File | Cue |
|---|---|
| `kid_pop1-3.mp3` | a balloon popped — three variants so it doesn't grate |
| `kid_celebrate1.mp3` | the reward, after a set of successes |
| `kid_wobble1.mp3` | a gentle "not that one" — the quietest sound in the app |
| `kid_tap1.mp3` | a button or menu tap |

## Everything else

The remaining files (`click*`, `damage*`, `hit*`, `jump*`, `score*`) come from the
`endless_runner` template, are made by Lukas Klingsbo and are CC0 (Public Domain).

They are **not used by any game** — they are arcade hit and damage sounds, too harsh for this
audience. Kept only for reference.
