#!/usr/bin/env python3
"""
Generate Little Train's voice lines and music with Google's Gemini models.

Like `gen_little_train_art.py`, this runs on a developer's machine once and
writes plain mp3 files into `assets/`. The app never calls Google (CLAUDE.md §4).

    export GEMINI_API_KEY=...          # never commit it, never write it in a doc
    tools/.venv/bin/python tools/gen_little_train_audio.py          # only what is missing
    tools/.venv/bin/python tools/gen_little_train_audio.py --force hop_on

Voice is the point. The players cannot read (CLAUDE.md §3), and a voice saying
"All aboard!" is instruction a five-year-old understands immediately.

Things learned the hard way, so they stay learned:

- **Send the transcript and nothing else.** `gemini-3.8-flash-tts` will happily
  read stage directions ("Say warmly, like a conductor: ...") OUT LOUD as part
  of the line. Delivery comes from the punctuation and the voice choice.
- **Do not trust a transcription model to catch that.** Asked to transcribe a
  clip that began with five seconds of spoken stage directions, Gemini reported
  only the line itself. Duration is the check that works: every line here is a
  couple of words, so anything over [MAX_LINE_SECONDS] is rejected.
- The 3.8 TTS model returns a real WAV container (24 kHz mono), not the
  headerless PCM the 2.5 model returned.
- Lyria's clip model returns a ~30s instrumental mp3, hot (around -13 LUFS,
  peaks at 0 dBFS). It is brought down to match the template's music here.
"""

from __future__ import annotations

import argparse
import io
import os
import subprocess
import time
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "tools" / "art_raw" / "little_train" / "audio"
SFX = ROOT / "assets" / "sfx"
MUSIC = ROOT / "assets" / "music"

TTS_MODEL = "gemini-3.8-flash-tts"
MUSIC_MODEL = "lyria-3-clip-preview"
MAX_LINE_SECONDS = 3.5

# The conductor is a grown-up, warm and unhurried. The passengers are a younger,
# brighter voice, so a child can tell "the train is talking" from "a friend is".
CONDUCTOR = "Puck"
PASSENGER = "Leda"

# name -> (transcript, voice). File is assets/sfx/train_<name>.mp3.
LINES = {
    "all_aboard": ("All aboard!", CONDUCTOR),
    "here_we_go": ("Choo choo! Here we go!", CONDUCTOR),
    "hop_on": ("Hop on!", CONDUCTOR),
    "next_stop": ("Next stop!", CONDUCTOR),
    "toot_toot": ("Toot toot!", CONDUCTOR),
    "we_are_here": ("Hooray! We're here!", CONDUCTOR),
    "thank_you": ("Thank you!", PASSENGER),
    "wait_for_me": ("Wait for me!", PASSENGER),
    "yay": ("Yay!", PASSENGER),
    "bye_bye": ("Bye bye!", PASSENGER),
}

MUSIC_PROMPT = (
    "A gentle, happy instrumental children's song for a toy train journey: soft "
    "xylophone, ukulele and light brushed drums, a steady chugging rhythm, calm and "
    "cheerful, 100 bpm, no vocals, no sudden loud moments, loops smoothly."
)


def _client():
    from google import genai
    key = os.environ.get("GEMINI_API_KEY")
    if not key:
        raise SystemExit("GEMINI_API_KEY is not set. Export it in your shell; never put it in a file in this repo.")
    return genai.Client(api_key=key)


def _audio_part(resp):
    for part in resp.candidates[0].content.parts:
        if part.inline_data:
            return part.inline_data
    raise RuntimeError("no audio in response")


def _wav_seconds(data: bytes) -> float:
    with wave.open(io.BytesIO(data)) as w:
        return w.getnframes() / w.getframerate()


def tts(client, name: str, text: str, voice: str) -> Path:
    from google.genai import types
    raw = RAW / f"{name}.wav"
    for attempt in range(4):
        try:
            resp = client.models.generate_content(
                model=TTS_MODEL, contents=text,
                config=types.GenerateContentConfig(
                    response_modalities=["AUDIO"],
                    speech_config=types.SpeechConfig(voice_config=types.VoiceConfig(
                        prebuilt_voice_config=types.PrebuiltVoiceConfig(voice_name=voice))),
                ),
            )
            blob = _audio_part(resp)
            data = blob.data
            if "wav" not in blob.mime_type:  # older models: headerless 24 kHz PCM
                buf = io.BytesIO()
                with wave.open(buf, "wb") as w:
                    w.setnchannels(1); w.setsampwidth(2); w.setframerate(24000)
                    w.writeframes(data)
                data = buf.getvalue()
            secs = _wav_seconds(data)
            if secs > MAX_LINE_SECONDS:
                print(f"[tts] {name}: {secs:.1f}s is too long for '{text}', retrying", flush=True)
                continue
            raw.write_bytes(data)
            print(f"[tts] {name} {secs:.1f}s", flush=True)
            return raw
        except Exception as e:
            print(f"[tts] {name}: {e!s:.120}, retrying", flush=True)
        time.sleep(4 * (attempt + 1))
    raise RuntimeError(f"gave up on {name}")


def music(client) -> Path:
    from google.genai import types
    raw = RAW / "music.mp3"
    resp = client.models.generate_content(
        model=MUSIC_MODEL, contents=MUSIC_PROMPT,
        config=types.GenerateContentConfig(response_modalities=["AUDIO"]),
    )
    raw.write_bytes(_audio_part(resp).data)
    print("[music] generated", flush=True)
    return raw


def ffmpeg(*args: str) -> None:
    subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", *args], check=True)


def finish_line(raw: Path, name: str) -> None:
    # Trim the silence the model pads either end with, so the voice lands ON the
    # moment it answers. Then level every line to the same loudness with a soft
    # ceiling: no line may be startlingly louder than another (CLAUDE.md §3).
    out = SFX / f"train_{name}.mp3"
    ffmpeg(
        "-i", str(raw),
        "-af",
        "silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.05,"
        "areverse,silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.12,areverse,"
        "loudnorm=I=-18:TP=-3:LRA=7,afade=t=in:d=0.01",
        "-ar", "44100", "-ac", "1", "-c:a", "libmp3lame", "-q:a", "4", str(out),
    )
    print(f"[out] {out.relative_to(ROOT)}", flush=True)


def finish_music(raw: Path) -> None:
    # Matched to the template's tracks (~-15 LUFS); the audio controller plays
    # music quietly under the cues on top of that.
    out = MUSIC / "little_train.mp3"
    ffmpeg("-i", str(raw), "-af", "loudnorm=I=-16:TP=-2:LRA=9",
           "-ar", "44100", "-c:a", "libmp3lame", "-b:a", "128k", str(out))
    print(f"[out] {out.relative_to(ROOT)}", flush=True)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("names", nargs="*", help="line names and/or 'music' (default: all)")
    ap.add_argument("--force", action="store_true")
    args = ap.parse_args()
    names = args.names or [*LINES, "music"]
    RAW.mkdir(parents=True, exist_ok=True)
    client = None

    for name in names:
        if name == "music":
            raw = RAW / "music.mp3"
            if args.force or not raw.exists():
                client = client or _client()
                music(client)
            finish_music(raw)
            continue
        text, voice = LINES[name]
        raw = RAW / f"{name}.wav"
        if args.force or not raw.exists():
            client = client or _client()
            tts(client, name, text, voice)
        finish_line(raw, name)


if __name__ == "__main__":
    main()
