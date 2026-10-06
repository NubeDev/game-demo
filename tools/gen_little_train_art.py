#!/usr/bin/env python3
"""
Generate Little Train's artwork with Google's Gemini image model.

This runs on a developer's machine, ONCE, and writes ordinary image files into
`assets/images/little_train/`. The app itself never talks to Google — it ships
the files, and is as offline as every other game here (CLAUDE.md §4).

    python3 -m venv tools/.venv
    tools/.venv/bin/pip install google-genai pillow numpy
    export GEMINI_API_KEY=...          # never commit it, never write it in a doc
    tools/.venv/bin/python tools/gen_little_train_art.py            # only what is missing
    tools/.venv/bin/python tools/gen_little_train_art.py --force engine bunny_wait
    tools/.venv/bin/python tools/gen_little_train_art.py --process  # re-key, no API calls

How it works:

1. **Style anchor.** `engine` is generated first. Every other prompt passes it
   in as a reference image and asks for "exactly the same art style", which is
   what keeps 40-odd separately generated pictures looking like one game.
2. **Pose pairs.** Each passenger is generated waiting, then generated again
   riding WITH the waiting picture as a reference, so it is the same animal.
3. **Transparency by chroma key.** The model only returns JPEG — no alpha. So
   characters are drawn on flat pure green (or magenta, for anything green
   itself) and the key colour is removed here, with the fringe de-spilled.
4. **Cache.** Raw model output lands in `tools/art_raw/little_train/` (not
   committed) and is reused, so only missing pictures are billed. `--process`
   redoes step 3 from the cache without spending anything.

The prompts below ARE the provenance: model, prompt and reference for every
file in the folder.
"""

from __future__ import annotations

import argparse
import io
import os
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass, field
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

MODEL = "gemini-3.1-flash-image"
ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "tools" / "art_raw" / "little_train"
OUT = ROOT / "assets" / "images" / "little_train"

STYLE = (
    "Children's picture-book illustration for a game for 5-year-olds: soft rounded "
    "shapes, thick friendly dark outlines, bright cheerful flat colours with gentle "
    "shading, cute and calm, nothing scary. No text, no letters, no numbers anywhere."
)
SAME_STYLE = "Use exactly the same art style, outline weight and colouring as the reference picture of the train. "
GREEN = "on a perfectly flat solid pure green (#00FF00) background, no ground, no shadow, no other objects."
MAGENTA = "on a perfectly flat solid pure magenta (#FF00FF) background, no ground, no shadow, no other objects."


@dataclass
class Art:
    name: str
    prompt: str
    aspect: str = "1:1"
    key: str | None = "green"          # None = opaque picture (a sky)
    refs: list[str] = field(default_factory=lambda: ["engine"])
    max_px: int = 512                   # longest side of the shipped file


def passenger(animal: str, look: str, key: str = "green") -> list[Art]:
    bg = GREEN if key == "green" else MAGENTA
    wait = Art(
        f"{animal}_wait",
        f"{STYLE} {SAME_STYLE}A single small {look}, standing on its hind legs facing the "
        f"viewer, waving one paw high in the air, smiling hopefully as if calling a train. "
        f"Whole body visible with margin, {bg}",
        key=key,
    )
    ride = Art(
        f"{animal}_ride",
        f"{STYLE} {SAME_STYLE}The SAME character as the first reference picture, now sitting "
        f"facing the viewer with both arms thrown up in the air, eyes closed with joy, laughing. "
        f"Whole body visible with margin, {bg}",
        key=key,
        refs=[f"{animal}_wait", "engine"],
    )
    return [wait, ride]


def land(name: str, sky: str, ground: str, props: list[tuple[str, str]], station: str) -> list[Art]:
    arts = [
        Art(
            f"{name}_sky",
            f"{STYLE} Use the same art style as the reference picture. A wide landscape "
            f"background for a side-scrolling game: {sky}. Lots of open sky in the top half. "
            f"No characters, no animals, no train, no railway track, no buildings.",
            aspect="21:9", key=None, max_px=2048,
        ),
        Art(
            f"{name}_ground",
            f"{STYLE} Use the same art style as the reference picture. Side view of one long "
            f"straight toy railway track running perfectly horizontally across the WHOLE width "
            f"of the picture, edge to edge, lying on {ground}. The ground strip fills only the "
            f"bottom third of the picture; the top two thirds are a perfectly flat solid pure "
            f"magenta (#FF00FF) background with nothing in it. No train, no characters.",
            aspect="21:9", key="magenta", max_px=2048,
        ),
        Art(
            f"{name}_station",
            f"{STYLE} {SAME_STYLE}A small cheerful toy railway station seen from the side, "
            f"{station}, with colourful bunting flags and a big round bell. Whole building "
            f"visible with margin, {MAGENTA}",
            aspect="4:3", key="magenta", max_px=768,
        ),
    ]
    for prop, look in props:
        arts.append(Art(
            f"{name}_{prop}",
            f"{STYLE} {SAME_STYLE}{look}, seen from the side, standing upright. Whole thing "
            f"visible with margin, {MAGENTA}",
            key="magenta",
        ))
    return arts


ARTS: list[Art] = [
    # The style anchor. Everything else is generated looking at this one.
    Art(
        "engine",
        f"{STYLE} A single small round toy steam train engine, side view facing right, red and "
        f"yellow with a big friendly face on the front, a puff of white steam. Centered, whole "
        f"engine visible with margin, {GREEN}",
        aspect="4:3", refs=[],
    ),
    Art(
        "wagon",
        f"{STYLE} {SAME_STYLE}One small open toy railway wagon with low sides and NO roof, empty, "
        f"side view, sky blue with yellow trim and the same red wheels as the engine. Whole wagon "
        f"visible with margin, {GREEN}",
        aspect="4:3",
    ),
    Art(
        "stop_post",
        f"{STYLE} {SAME_STYLE}A little wooden railway stop post: a short pole with a big round "
        f"sign on top showing a simple picture of a paw print, and a tiny bench beside it. "
        f"Whole thing visible with margin, {GREEN}",
    ),
    *passenger("bunny", "white bunny with a little blue backpack", "magenta"),
    *passenger("piglet", "pink piglet in green dungarees", "green"),
    *passenger("hedgehog", "brown hedgehog with a red scarf", "magenta"),
    *passenger("bear", "brown bear cub with a yellow sun hat", "magenta"),
    *passenger("fox", "orange fox cub with a fluffy white-tipped tail", "magenta"),
    *passenger("owl", "round little owl with big friendly eyes", "magenta"),
    *passenger("crab", "red crab with a tiny bucket and spade", "green"),
    *passenger("turtle", "green sea turtle with a striped swim ring", "magenta"),
    *passenger("seagull", "fluffy white seagull chick with a sailor hat", "magenta"),
    *passenger("penguin", "penguin chick with a woolly bobble hat", "magenta"),
    *passenger("polarbear", "white polar bear cub with a red woolly scarf", "magenta"),
    *passenger("reindeer", "little brown reindeer calf with soft antlers", "magenta"),
    *land(
        "meadow",
        "a sunny spring meadow, soft blue sky with fluffy clouds, distant rolling green hills "
        "with a few round trees, a windmill far away",
        "green grass with little flowers",
        [("tree", "One round leafy green tree"), ("flowers", "A bushy clump of colourful smiling flowers")],
        "with a red roof and flower boxes, in a sunny meadow",
    ),
    *land(
        "forest",
        "a friendly sunlit forest, tall green trees in the distance with soft light between them, "
        "warm golden sky, gentle hills, nothing dark",
        "soft green moss and brown earth with little mushrooms",
        [("pine", "One tall friendly green pine tree"), ("mushroom", "One big red-and-white spotted toadstool mushroom")],
        "made of logs with a green roof, a treehouse-cabin feel",
    ),
    *land(
        "seaside",
        "a sunny seaside, turquoise sea with small gentle waves, a lighthouse far away, a pale "
        "blue sky with puffy clouds and a little sailboat",
        "golden sand with small shells",
        [("palm", "One leaning palm tree with coconuts"), ("umbrella", "One stripy beach umbrella stuck in a little pile of sand")],
        "painted with blue and white stripes like a beach hut",
    ),
    *land(
        "snow",
        "snowy mountains under a soft pink-and-blue sky, gentle white peaks, a few snowy pine "
        "trees far away, soft falling snowflakes",
        "deep soft white snow",
        [("snowpine", "One small pine tree covered in snow"), ("snowman", "One friendly smiling snowman with a carrot nose and a scarf")],
        "with a snowy roof and warm glowing windows like a cosy chalet",
    ),
]
BY_NAME = {a.name: a for a in ARTS}


# --- generation --------------------------------------------------------------

def _client():
    from google import genai
    key = os.environ.get("GEMINI_API_KEY")
    if not key:
        raise SystemExit("GEMINI_API_KEY is not set. Export it in your shell; never put it in a file in this repo.")
    return genai.Client(api_key=key)


def generate(art: Art, client) -> None:
    from google.genai import types
    contents = [Image.open(RAW / f"{r}.jpg") for r in art.refs] + [art.prompt]
    for attempt in range(4):
        try:
            resp = client.models.generate_content(
                model=MODEL, contents=contents,
                config=types.GenerateContentConfig(
                    response_modalities=["IMAGE"],
                    image_config=types.ImageConfig(aspect_ratio=art.aspect),
                ),
            )
            for part in resp.candidates[0].content.parts:
                if part.inline_data:
                    # Re-encode whatever came back (JPEG, normally) as a JPEG
                    # we know the name of. The model ignores requested formats.
                    img = Image.open(io.BytesIO(part.inline_data.data)).convert("RGB")
                    img.save(RAW / f"{art.name}.jpg", quality=95)
                    print(f"[gen] {art.name} {img.size}", flush=True)
                    return
            print(f"[gen] {art.name}: no image ({resp.candidates[0].finish_reason}), retrying", flush=True)
        except Exception as e:  # 503 under load is common and transient
            print(f"[gen] {art.name}: {e!s:.120}, retrying", flush=True)
        time.sleep(5 * (attempt + 1))
    raise RuntimeError(f"gave up on {art.name}")


# --- chroma key --------------------------------------------------------------

def key_out(img: Image.Image, key: str) -> Image.Image:
    """Turn a flat green/magenta background into real transparency.

    "Keyness" is how much more of the key colour a pixel has than its other
    channels: high on the background, near zero on the subject, in between on
    the anti-aliased outline. That ramp becomes the alpha, so edges stay soft.
    """
    a = np.asarray(img.convert("RGB")).astype(np.float32)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    if key == "green":
        keyness = g - np.maximum(r, b)
    else:
        keyness = np.minimum(r, b) - g
    lo, hi = 45.0, 120.0
    alpha = 1.0 - np.clip((keyness - lo) / (hi - lo), 0, 1)

    # De-spill: the outline pixels that survive still carry a tint of the key
    # colour from JPEG bleed. Pull the key channel(s) back down near the edge.
    edge = np.asarray(
        Image.fromarray((alpha < 0.99).astype(np.uint8) * 255).filter(ImageFilter.MaxFilter(7))
    ) > 0
    if key == "green":
        g2 = np.minimum(g, np.maximum(r, b))
        a[..., 1] = np.where(edge, g2, g)
    else:
        spill = np.where(edge, np.clip(keyness, 0, None), 0)
        a[..., 0] = r - spill
        a[..., 2] = b - spill

    rgba = np.dstack([a, alpha * 255]).clip(0, 255).astype(np.uint8)
    out = Image.fromarray(rgba, "RGBA")
    bbox = out.getchannel("A").point(lambda v: 255 if v > 24 else 0).getbbox()
    if bbox:
        pad = 4
        bbox = (max(bbox[0] - pad, 0), max(bbox[1] - pad, 0),
                min(bbox[2] + pad, out.width), min(bbox[3] + pad, out.height))
        out = out.crop(bbox)
    return out


def process(art: Art) -> None:
    img = Image.open(RAW / f"{art.name}.jpg")
    img = key_out(img, art.key) if art.key else img.convert("RGB")
    scale = art.max_px / max(img.size)
    if scale < 1:
        img = img.resize((round(img.width * scale), round(img.height * scale)), Image.LANCZOS)
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / f"{art.name}.webp"
    img.save(path, "WEBP", quality=86, method=6)
    print(f"[out] {path.relative_to(ROOT)} {img.size} {path.stat().st_size // 1024}KB", flush=True)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("names", nargs="*", help="only these (default: all)")
    ap.add_argument("--force", action="store_true", help="regenerate even if cached")
    ap.add_argument("--process", action="store_true", help="re-key from cache only, no API calls")
    args = ap.parse_args()

    unknown = [n for n in args.names if n not in BY_NAME]
    if unknown:
        raise SystemExit(f"unknown art: {unknown}")
    chosen = [BY_NAME[n] for n in args.names] if args.names else ARTS
    RAW.mkdir(parents=True, exist_ok=True)

    if not args.process:
        todo = [a for a in chosen if args.force or not (RAW / f"{a.name}.jpg").exists()]
        client = _client()  # bind it: a temporary Client is GC'd mid-request
        # Dependencies first: the engine (style anchor), then every waiting
        # pose, then everything that references one of those.
        for wave in (
            [a for a in todo if not a.refs],
            [a for a in todo if a.refs == ["engine"]],
            [a for a in todo if a.refs and a.refs != ["engine"]],
        ):
            with ThreadPoolExecutor(4) as pool:
                list(pool.map(lambda a: generate(a, client), wave))

    for art in chosen:
        if (RAW / f"{art.name}.jpg").exists():
            process(art)
        else:
            print(f"[skip] {art.name}: not generated", file=sys.stderr)


if __name__ == "__main__":
    main()
