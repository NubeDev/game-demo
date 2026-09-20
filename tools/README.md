# tools

Developer scripts. Nothing here ships in the app.

## `make_sfx.py` — placeholder sound effects

Regenerates the kid sound cues in `assets/sfx/kid_*.mp3`.

These are **placeholders**: honest synthesised tones that obey the kid rules in
[`CLAUDE.md`](../CLAUDE.md) §3, standing in until real audio is recorded. They are checked in, so
you only need this if you want to change them.

```bash
python3 tools/make_sfx.py          # writes assets/sfx/kid_*.wav
```

The script is deterministic and rewrites **every** `kid_*.wav`, so regenerating one cue
regenerates all of them. Encode only the ones you actually changed — re-encoding the rest churns
checked-in binaries for no reason:

```bash
cd assets/sfx
for f in kid_*.wav; do
  ffmpeg -y -i "$f" -codec:a libmp3lame -b:a 128k "${f%.wav}.mp3"
done
rm kid_*.wav
```

ffmpeg with `libmp3lame` **is** available on the machine these sessions run on (it was not when the
first batch was made, which is why STATUS.md carried a "no encoder here" note for a while). If it
ever is not, GStreamer does the same job:

```bash
gst-launch-1.0 filesrc location=kid_pop1.wav ! wavparse ! audioconvert ! audioresample \
  ! lamemp3enc target=bitrate bitrate=128 cbr=true ! id3v2mux ! filesink location=kid_pop1.mp3
```

### The cues it makes

The originals — `kid_pop`, `kid_celebrate`, `kid_wobble`, `kid_tap`, `kid_count`, `kid_launch`,
`kid_horn` — plus the set Neil the Seal brought, which is the largest batch any one game has
needed because that game is mostly made of noises:

| Cue | What it is |
|---|---|
| `kid_flump` ×2 | Two tonnes of seal landing. Plays on **every** tap, including the ones that land on bare ground |
| `kid_boing` ×2 | The car going down on its springs, and popping back up. The sound the whole game rests on |
| `kid_squelch` | The pile of kelp |
| `kid_bellow` ×2 | Neil's comedy burp-bellow. A burp, never a roar |
| `kid_snore` | The nap. The softest attack in the app, so the loudest moment still cannot startle |
| `kid_wriggle` ×2 | Him enjoying a rub |
| `kid_answer` ×5 | The town replying to a bellow: dog, seagulls, wallaby, ute, cow — played in a shuffled order |

These use `bend()`, which takes a **frequency function** rather than a fixed pitch: a boing, a
squelch and a bellow are pitch *shapes*, where the movement is the sound. It integrates the phase
rather than computing `sin(2*pi*f*t)`, because with a changing `f` the latter jumps every time `f`
moves — an audible click, and a click is exactly the transient these cues must not have.

### What the design is protecting

- **No transients.** Soft attack, gentle decay, no percussive edge. A realistic balloon *bang*
  startles a five-year-old — and the pop fires many times a minute.
- **Nothing piercing.** Sine tones with one quiet harmonic; effectively no energy above 4 kHz.
- **Consonant when overlapping.** Everything sits on a C-major pentatonic scale, so two cues landing
  together never clash.
- **The mix carries the meaning.** Loudness is set in `lib/audio/sounds.dart`, not baked into the
  files: the wobble is the quietest cue in the app and the celebration the loudest. That ordering is
  the kid rule — never scold, and make the reward the biggest thing they hear.

Replacing these with real recordings means dropping new files into `assets/sfx/` under the same
names. No Dart changes.
