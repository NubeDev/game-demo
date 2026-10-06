# Generating art, voice and music with Google's Gemini API

How Little Train got real pictures, a speaking conductor and its own music, and how to do the same
for the next game. Companion to [`HOW-TO-CODE.md`](HOW-TO-CODE.md). Everything here was verified on
**2026-10-06** with `google-genai` 2.28.0. Model names change quickly, so check them (§2) before
trusting this file.

The working scripts are [`tools/gen_little_train_art.py`](../tools/gen_little_train_art.py) and
[`tools/gen_little_train_audio.py`](../tools/gen_little_train_audio.py). Copy them for a new game
rather than starting from scratch.

---

## 1. Where this fits — and the rule it must not break

```
Gemini API  ──>  files on disk (assets/)  ──>  the app
(once, on a dev machine)   (checked in)        (offline, always)
```

**The app never calls Google.** CLAUDE.md §4 forbids any network call at runtime, and that has not
changed. Generation is a developer step, like drawing art in a paint program. The output is ordinary
`.webp` and `.mp3` files in `assets/`, and the shipped game has no idea where they came from.
Nothing from `google-genai` ever goes into `pubspec.yaml`.

So: **generate first, then build the game around the files.** Treat generated files as cached
artwork, made once and reused. Do not generate anything while the game runs.

---

## 2. Setup

### The key

Get one at <https://aistudio.google.com/apikey>. Keys now start with `AQ.` (older ones `AIza`);
both work the same.

**The key never goes in the repo.** Not in a script, not in a doc, not in a commit. The scripts read
it only from the `GEMINI_API_KEY` environment variable:

```bash
export GEMINI_API_KEY=...        # in your shell, for this session only
```

If you keep it in a file, keep it **outside** the repo, or in `.env` at the repo root (which is in
`.gitignore`), and load it with `set -a; . ./.env; set +a`. A key that has been pasted into a chat,
a log or a terminal history should be treated as leaked: delete it in AI Studio when you're done.

Send the key as the `x-goog-api-key` header. `Authorization: Bearer` returns a misleading 401.

### The Python environment

```bash
python3 -m venv tools/.venv                 # gitignored
tools/.venv/bin/pip install google-genai pillow numpy
```

`ffmpeg` with `libmp3lame` is also needed for the audio (it is on the dev machine already).

### Check the key before spending anything

```bash
# 1. Is the key good? (a 200 and a model list)
curl -s "https://generativelanguage.googleapis.com/v1beta/models?pageSize=200" \
  -H "x-goog-api-key: $GEMINI_API_KEY" | grep -o '"models/[^"]*"'

# 2. Can it make images? (200 = yes; 429 with "limit: 0" = billing is not on)
curl -s -o /dev/null -w '%{http_code}\n' \
  -H "x-goog-api-key: $GEMINI_API_KEY" -H 'Content-Type: application/json' \
  -d '{"contents":[{"parts":[{"text":"A plain grey cube on a white background."}]}]}' \
  https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-image:generateContent
```

**Images, video and music need a billing-enabled project.** On the free tier they return HTTP 429
with `limit: 0`. That is a billing boundary, not a rate limit, and waiting will not clear it.

### The models used

| Need | Model | What comes back |
|---|---|---|
| Pictures | `gemini-3.1-flash-image` | JPEG. 1:1 → 1024×1024, 4:3 → 1200×896, 21:9 → 1584×672 |
| Voice | `gemini-3.8-flash-tts` | A real WAV file, 24 kHz mono |
| Music | `lyria-3-clip-preview` | ~30 s instrumental MP3, 44.1 kHz stereo |
| Video | `veo-3.1-fast-generate-preview` | 8 s 720p MP4 **with sound**. Not used in this repo yet (§7) |

The model list call above also shows `lyria-3.5` (full ~3-minute songs) and other image and TTS
models. Being listed does not prove a model is callable, so try one cheap call first.

---

## 3. Pictures

### The recipe that worked

**1. One style sentence, repeated in every prompt.** Little Train's:

> Children's picture-book illustration for a game for 5-year-olds: soft rounded shapes, thick
> friendly dark outlines, bright cheerful flat colours with gentle shading, cute and calm, nothing
> scary. No text, no letters, no numbers anywhere.

The last sentence is a kid rule (CLAUDE.md §3: no text to play). Still look at every picture,
because models sneak in signs and labels.

**2. A style anchor.** Generate one hero picture first (the engine). Pass it **as a reference image**
in every later prompt with *"Use exactly the same art style, outline weight and colouring as the
reference picture."* This is what makes 47 separately generated pictures look like one game. Without
it, each picture comes out in a slightly different style.

**3. Pose pairs from a reference.** For a character in two poses, generate pose A, then generate
pose B **with pose A as the first reference**: *"The SAME character as the first reference picture,
now sitting with both arms in the air."* All twelve animals stayed recognisably themselves. The only
slip was the turtle losing its swim ring.

**4. Flat key-colour backgrounds for transparency.** The model only returns JPEG, which has no
transparency. Ask for *"on a perfectly flat solid pure green (#00FF00) background, no ground, no
shadow, no other objects"*, then remove the green in code (§3.2). Use **magenta (#FF00FF) for
anything that is itself green**: grass, trees, a frog or turtle. Use green for anything pink or
purple.

**5. Pick the aspect ratio to suit the job.** `1:1` for characters, `4:3` for vehicles and
buildings, `21:9` for wide scrolling backgrounds. Pass it as `ImageConfig(aspect_ratio=...)`.

### Removing the background (chroma key)

`key_out()` in the art script does this. The idea, so it can be changed safely:

- **Keyness** = how much more of the key colour a pixel has than its other channels. For green it is
  `G − max(R, B)`, for magenta `min(R, B) − G`. The background scores ~200, the subject ~0, and the
  soft outline lands in between.
- Map keyness 45→120 onto alpha 1→0. The ramp keeps edges smooth instead of jagged.
- **De-spill** pixels near the edge, pulling the key channel back down. Otherwise every outline
  carries a faint green or pink fringe from JPEG bleed.
- Crop to the visible pixels, scale to ≤512 px (2048 for wide backgrounds), and save as `.webp`.
  47 pictures came to **1.8 MB** in total.

Holes are handled for free: the gaps between the engine's wheel spokes came out transparent.

### Backgrounds that scroll

- **Sky:** one 21:9 picture per land, opaque, no characters. Prompt for *"lots of open sky in the
  top half"* so the train and passengers stand out against it.
- **Track:** a separate 21:9 strip of rails on ground, with magenta above it. The model drew these
  much **thinner** than asked and put the rails at a **different height in each one**. The rail line
  and rail gauge were measured by eye against a ruler image and written into `lands.dart`. Expect
  to do this per strip.
- **Seamless looping:** generated pictures do not tile, because their edges do not match. Draw every
  other copy **mirrored** (`flip: k.isOdd` in `scenery.dart`). Each seam then meets its own mirror
  image, so the join cannot show. A grown-up might spot the symmetry; a child won't.
- **Props** (trees, a snowman, a beach umbrella) as separate keyed pictures, scattered in code. This
  gives variety without generating a huge panorama.

### Review, then review again in place

1. **Contact sheet.** Composite every output onto a mid-grey background and look at them all at
   once. Grey shows up bad keying that white and black hide.
2. **In the game.** `test/little_train_render_test.dart` renders real frames of the running game to
   PNG (`flutter test --tags render --dart-define=SHOT_DIR=/tmp/shots test/little_train_render_test.dart`).
   This caught the train being dwarfed by the trees and the leap being too high. Neither shows up in
   a picture viewed on its own.
3. **In motion, in a browser or on a device.** That caught the worst one: passengers were drawn
   behind the track, so the arriving train **covered the animal the child was trying to stop for**.
   None of the stills showed it.

### Things the model gets wrong

- It ignores direction. The engine was asked to face right and faces left, so the game flips it.
  Check orientation; don't spend a regeneration on it.
- It ignores proportions in strips (see the track above).
- It occasionally drops a detail between poses (the turtle's ring).
- Regenerate a single picture with `--force <name>`. The cache means only that one is billed.

---

## 4. Voice

The players cannot read, so **a voice is the best instruction this app has**. "Hop on!" needs no
explanation. Little Train has ten lines: the conductor uses voice `Puck` (warm, adult) and the
passengers use `Leda` (younger, brighter), so a child can tell "the train is talking" from "a friend
is talking".

### Send the transcript, nothing else

The first attempt sent *"Say warmly and cheerfully, like a kind train conductor talking to a small
child: All aboard!"*. The model **read the whole instruction out loud**: 7.5 seconds, of which
"All aboard!" was the last two. Delivery comes from punctuation (`Choo choo! Here we go!`) and from
choosing the voice, not from stage directions.

### Check the duration, not a transcription

That bad clip was then given to Gemini to transcribe. **It reported only "All aboard!"** and skipped
the five seconds of spoken instructions. A transcription model will tidy the text up, so it can't be
used to check what was actually said. Duration can: every line here is a few words, so the script
rejects anything over 3.5 s and retries. Clean lines came out at 0.6–1.9 s after trimming.

### Finishing

The 3.8 TTS model returns a real WAV file. (The older 2.5 model returned bare PCM samples with no
WAV header, so the script handles both.) Each line then goes through ffmpeg: trim the silence from
both ends, normalise loudness to −18 LUFS with a −3 dBTP ceiling (so no line is startlingly louder
than another, CLAUDE.md §3), and encode to MP3 at `assets/sfx/train_<name>.mp3`.

In Dart, all the lines are one `SfxType.kidTrainVoice` with one variant per line, in the same order
as the `TrainLine` enum in `lib/shared/kid_sounds.dart`. A test pins that the two lists match.

---

## 5. Music

`lyria-3-clip-preview` with a plain description:

> A gentle, happy instrumental children's song for a toy train journey: soft xylophone, ukulele and
> light brushed drums, a steady chugging rhythm, calm and cheerful, 100 bpm, no vocals, no sudden
> loud moments, loops smoothly.

It comes back at ~30 s and **hot**: −13 LUFS, peaking at 0 dBFS. It was normalised to −16 LUFS to sit
with the template's tracks. Two app changes were needed:

- `Song.loops` in `lib/audio/songs.dart`. The audio controller rolls on to the next playlist track
  when a song ends, so without this a 30 s clip would switch to a template track half a minute in.
- The track is kept **out of** the shuffled `songs` list, so no other screen ever lands on it.

`lyria-3.5` makes full ~3-minute songs (4 MB as MP3) if a loop gets tiresome.

---

## 6. Wiring generated files into a game

1. **Paths in one place:** `lib/games/<game>/assets.dart` (CLAUDE.md §5). Paths are relative to
   `assets/images/`, which is where Flame's image cache looks.
2. **Declare the folder** in `pubspec.yaml` under `flutter: assets:`, e.g.
   `- assets/images/little_train/`.
3. **Preload everything** in `onLoad` with `images.loadAll([...])`, then draw with
   `images.fromCache(path)`. Loading every land up front (~2 MB) means a land change can never
   stutter on a load.
4. **Tests that touch real pictures** need `tester.runAsync(() => game.loaded)` in widget tests,
   because image decoding is real async work. They also need a silent `AudioController` stub,
   because `runAsync` lets the real one try to reach the audio plugin. See
   `test/little_train_screen_test.dart`.
5. **A test that every path exists on disk.** A renamed file is otherwise a blank sprite.

---

## 7. Video (Veo) — not used here yet

The same key can make video with `veo-3.1-fast-generate-preview`: an 8-second 1280×720 clip **with
an AAC sound track**, about a minute to render, billed per request. It works by submitting a job and
polling it, not with one call. The full working recipe, including failure modes, is in the kinocut
repo: `/home/user/code/vids/kino-demo/packages/kinocut-kit/GEMINI_GUIDE.md` (§4 and
`templates/generate.py`).

Nothing in this app uses it, and it would need thought before it did:

- A clip is a **shipped asset**, so it is a few MB per clip in the app download.
- Its sound track has to be stripped or levelled to the kid rules, the same as any other audio.
- Anything played to a child has to pass the same checks as a still: no flashing, nothing scary, no
  text.

A trailer for a store listing is a different matter: it is made outside the app, and Veo is a good
fit for it.

---

## 8. Cost and pacing

The whole of Little Train was **47 pictures + 10 voice lines + 1 music clip**, plus a handful of
probes and retries. Pictures and voice are cheap enough to regenerate freely while iterating, and
Veo is the expensive one. Both scripts **cache** the raw output in `tools/art_raw/` (gitignored),
so a re-run only generates what is missing. `--force <name>` redoes one item, and `--process`
re-keys every picture from the cache without calling the API at all.

Generation runs four requests at a time. The image model sometimes returns a 503 under load or no
image at all; the scripts retry with a backoff.

---

## 9. Checklist for the next game

- [ ] Write the style sentence and generate the **style anchor** first. Look at it before generating
      anything else.
- [ ] Choose a key colour per item (magenta for green things).
- [ ] Generate characters as pose pairs, the second from the first.
- [ ] Generate the backgrounds wide (21:9) and plan for mirror tiling.
- [ ] Contact sheet on grey, then **look at every picture**: nothing scary, no text, no brand-like
      characters.
- [ ] Voice lines as bare transcripts, duration-checked, levelled.
- [ ] Wire in through `assets.dart`, the pubspec folder and `images.loadAll`. Add a test that every
      path exists.
- [ ] Render real frames, then run it in motion. Fix layering and scale by eye.
- [ ] Prompts stay in the generator script: they are the record of where each file came from.
- [ ] Grep the app for network use before release. Nothing from this step belongs in `lib/`.
- [ ] Delete the API key in AI Studio if it was ever pasted anywhere.
