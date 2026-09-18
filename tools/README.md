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

Then encode to mp3, to match the other files in `assets/sfx/`:

```bash
cd assets/sfx
for f in kid_*.wav; do
  ffmpeg -y -i "$f" -codec:a libmp3lame -b:a 128k "${f%.wav}.mp3"
done
rm kid_*.wav
```

No ffmpeg? GStreamer does the same job:

```bash
gst-launch-1.0 filesrc location=kid_pop1.wav ! wavparse ! audioconvert ! audioresample \
  ! lamemp3enc target=bitrate bitrate=128 cbr=true ! id3v2mux ! filesink location=kid_pop1.mp3
```

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
