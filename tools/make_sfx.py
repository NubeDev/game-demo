"""Synthesise gentle placeholder sound effects for Little Games.

Run from the repo root:   python3 tools/make_sfx.py
Then encode to mp3:       see tools/README.md

These are PLACEHOLDERS -- honest synthesised tones that obey the kid rules,
standing in until real audio is recorded. They are checked in so the game has
sound that is safe for a five-year-old today, and so regenerating them needs no
dependency beyond python3.

Design constraints (CLAUDE.md section 3): bright, friendly, calm. Nothing
percussive, nothing that reads as a buzzer or a bang. Pure sine tones with
soft attack and gentle decay, tuned to a pentatonic scale so any overlap of
two cues is still consonant.
"""
import math, wave, struct, os

SR = 44100
OUT = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "sfx"
)

# Pentatonic C major -- no semitone clashes when cues overlap.
def note(n):
    return 261.63 * (2 ** (n / 12.0))

C5, D5, E5, G5, A5, C6, E6, G6 = (note(n) for n in (12, 14, 16, 19, 21, 24, 28, 31))


def env(t, dur, attack=0.012, release=0.75):
    """Soft attack, smooth exponential-ish decay. No clicks at either end."""
    if t < attack:
        return t / attack
    p = (t - attack) / max(dur - attack, 1e-6)
    return max(0.0, (1.0 - p) ** 2) * (1.0 if p < release else (1.0 - p) / max(1 - release, 1e-6))


def tone(freq, dur, amp=0.5, start=0.0, vibrato=0.0, buf=None, total=None):
    n_total = int(SR * (total if total else dur + start))
    if buf is None:
        buf = [0.0] * n_total
    s0 = int(SR * start)
    for i in range(int(SR * dur)):
        if s0 + i >= len(buf):
            break
        t = i / SR
        f = freq * (1.0 + vibrato * math.sin(2 * math.pi * 5.5 * t))
        # A touch of 2nd harmonic keeps it warm rather than sterile/beepy.
        v = math.sin(2 * math.pi * f * t) + 0.18 * math.sin(4 * math.pi * f * t)
        buf[s0 + i] += v * amp * env(t, dur)
    return buf


def write(name, buf):
    peak = max(1e-9, max(abs(v) for v in buf))
    # Normalise to -3 dBFS. Per-cue loudness is set in Dart, not baked in here.
    gain = 0.707 / peak
    path = f"{OUT}/{name}.wav"
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(
            struct.pack("<h", int(max(-1, min(1, v * gain)) * 32767)) for v in buf
        ))
    print(f"  {name}.wav  {len(buf)/SR:.2f}s")


# --- pop: a soft "boop". One short round tone with a gentle upward bend. ---
# Deliberately NOT a bang: a realistic balloon burst startles a five-year-old.
for idx, base in enumerate((G5, A5, C6)):
    dur = 0.16
    buf = [0.0] * int(SR * dur)
    for i in range(len(buf)):
        t = i / SR
        f = base * (1.0 + 0.22 * (t / dur))  # small rise = playful, not alarming
        buf[i] = (math.sin(2 * math.pi * f * t) + 0.2 * math.sin(4 * math.pi * f * t)) * env(t, dur)
    write(f"kid_pop{idx + 1}", buf)

# --- celebrate: a rising four-note arpeggio, clearly bigger than a pop. ---
total = 1.1
buf = [0.0] * int(SR * total)
for k, (f, st) in enumerate(((C5, 0.0), (E5, 0.09), (G5, 0.18), (C6, 0.27))):
    tone(f, 0.75, amp=0.45, start=st, buf=buf, total=total)
# Sparkle on top, quiet, arriving after the arpeggio lands.
tone(E6, 0.5, amp=0.16, start=0.42, buf=buf, total=total)
tone(G6, 0.45, amp=0.13, start=0.52, buf=buf, total=total)
write("kid_celebrate1", buf)

# --- wobble: two soft low notes, falling slightly. "Not that one" -- never a
# buzzer, never harsh. Quietest cue in the set. ---
total = 0.42
buf = [0.0] * int(SR * total)
tone(E5, 0.2, amp=0.5, start=0.0, vibrato=0.01, buf=buf, total=total)
tone(D5, 0.28, amp=0.45, start=0.12, vibrato=0.012, buf=buf, total=total)
write("kid_wobble1", buf)

# --- tap: very short, light. A UI tick, not a game event. ---
dur = 0.09
buf = tone(A5, dur, amp=0.5, total=dur)
write("kid_tap1", buf)

# --- count: the countdown ladder, one rung per number (Blast Off). ---
# Ten rungs climbing a pentatonic scale, so the SOUND says "nearly there" to a
# child who cannot read the digit. Rung 0 is played at ten and rung 9 at one,
# so the phrase resolves upward into the launch.
#
# The last three rungs are deliberately longer and rounder: three-two-one is
# the moment everything leans in, and the ear should hear that lean rather than
# just another tick. Still no transient -- excitement comes from pitch and
# length, never from a bang (CLAUDE.md section 3).
_ladder = (C5, D5, E5, G5, A5, C6, note(26), note(28), note(31), note(33))
for idx, base in enumerate(_ladder):
    final_three = idx >= len(_ladder) - 3
    dur = 0.34 if final_three else 0.2
    buf = [0.0] * int(SR * dur)
    for i in range(len(buf)):
        t = i / SR
        f = base * (1.0 + 0.05 * (t / dur))
        v = math.sin(2 * math.pi * f * t) + 0.2 * math.sin(4 * math.pi * f * t)
        buf[i] = v * env(t, dur)
    # The last three get a quiet fifth underneath -- fuller, not louder.
    if final_three:
        tone(base / 2, dur, amp=0.3, buf=buf, total=dur)
    write(f"kid_count{idx + 1}", buf)

# --- launch: zero. A rising swell, NOT an explosion. ---
# The biggest sound in the app, and the one most at risk of breaking the "no
# startling" rule: it is built as a slow crescendo of stacked fifths with a
# soft attack, so it arrives rather than hits.
total = 1.6
buf = [0.0] * int(SR * total)
for k, (f, st, dur) in enumerate((
    (note(0), 0.0, 1.5),
    (note(7), 0.08, 1.4),
    (note(12), 0.16, 1.3),
    (note(19), 0.3, 1.15),
    (note(24), 0.5, 0.95),
    (note(31), 0.75, 0.7),
)):
    # Rising amplitude with each stacked voice = a swell that opens out.
    tone(f, dur, amp=0.22 + 0.04 * k, start=st, vibrato=0.004, buf=buf, total=total)
write("kid_launch1", buf)

# --- horn: the Car Trip horn. Two short warm notes, "parp-parp". ---
# This cue is unlike every other one here: it is not feedback for anything, it
# is a toy. A five-year-old will press it dozens of times in a row, so it has to
# survive repetition -- hence two variants a step apart, played alternately.
#
# A real car horn is a harsh, loud warning with a hard transient, which is
# exactly what CLAUDE.md section 3 forbids. This is the friendly cartoon version:
# a warm third, soft attack, short, and mixed below the pop so a child leaning on
# the button never drowns out the game.
for idx, (lo, hi) in enumerate(((E5, G5), (G5, C6))):
    total = 0.44
    buf = [0.0] * int(SR * total)
    for start in (0.0, 0.22):  # two parps, not one
        tone(lo, 0.16, amp=0.42, start=start, buf=buf, total=total)
        tone(hi, 0.16, amp=0.30, start=start, buf=buf, total=total)
    write(f"kid_horn{idx + 1}", buf)


# ===========================================================================
# Neil the Seal
# ===========================================================================
#
# This game is built around its noises more than any other in the app: the
# whole joke is that an enormous soft animal lands on something and the
# something answers. So these are less "cues" and more "the punchline" -- and
# they still obey the same rules (CLAUDE.md section 3). Nothing percussive,
# nothing above ~4 kHz, and the loudest thing in the game is a snore.
#
# What is deliberately NOT here: a car alarm, a siren, a shout, an angry
# anything. The scope forbids all of them outright -- nobody in this town is
# ever cross that Neil is there.


def bend(freq_at, dur, amp=0.5, start=0.0, buf=None, total=None, harm=0.18,
         attack=0.012):
    """A tone whose pitch follows freq_at(p), with p running 0..1 over `dur`.

    `tone()` can only wobble around a fixed pitch. A boing, a squelch and a
    bellow are all pitch SHAPES -- the movement *is* the sound -- so they need
    the frequency to be a function of time.

    The phase is integrated rather than computed as sin(2*pi*f*t): with a
    changing f the latter jumps whenever f moves, which is an audible click,
    and a click is exactly the transient these cues must not have.
    """
    n_total = int(SR * (total if total else dur + start))
    if buf is None:
        buf = [0.0] * n_total
    s0 = int(SR * start)
    n = max(1, int(SR * dur))
    phase = 0.0
    for i in range(n):
        if s0 + i >= len(buf):
            break
        phase += 2 * math.pi * freq_at(i / n) / SR
        v = math.sin(phase) + harm * math.sin(2 * phase)
        buf[s0 + i] += v * amp * env(i / SR, dur, attack=attack)
    return buf


# --- flump: Neil lands. ---------------------------------------------------
# Two tonnes arriving gently: a soft low whumph that drops away. It plays on
# EVERY tap, including the ones that land on bare ground -- "there is no dead
# tap" is the scope's rule and this is the sound of it being kept -- so it has
# two variants and sits low in the mix.
for idx, top in enumerate((note(-5), note(-8))):
    dur = 0.30
    buf = bend(lambda p, top=top: top * (1.0 - 0.42 * p),
               dur, amp=0.55, total=dur, harm=0.38)
    write(f"kid_flump{idx + 1}", buf)

# --- boing: the car on its springs, and the spring back. ------------------
# THE sound of this game. The scope is built around the car and the cone, and
# says the springback has to be perfect because everything else in the town is
# judged against it.
#
# A boing is a pitch WOBBLE that decays -- not a hit. There is no attack
# transient anywhere in it, which is what keeps a two-tonne animal landing on
# a car friendly rather than violent. Variant 1 is the sink (pitch sagging
# under the weight), variant 2 is the springback (shorter, rising, relieved).
for idx, (base, drift, dur) in enumerate(
    ((note(-3), -0.10, 0.62), (note(2), 0.09, 0.42))
):
    def shape(p, base=base, drift=drift, dur=dur):
        decay = (1.0 - p) ** 1.5
        return (base * (1.0 + drift * p)
                * (1.0 + 0.30 * decay * math.sin(2 * math.pi * 8.5 * p * dur)))
    write(f"kid_boing{idx + 1}", bend(shape, dur, amp=0.55, total=dur, harm=0.3))

# --- squelch: the pile of kelp. -------------------------------------------
# Low, wet and slow. A long downward bend with a lazy wobble under it -- the
# opposite of the boing, so the two props are told apart by ear alone.
dur = 0.50
write("kid_squelch1", bend(
    lambda p: note(-9) * (1.0 - 0.33 * p) * (1.0 + 0.11 * math.sin(2 * math.pi * 3.4 * p * dur)),
    dur, amp=0.5, total=dur, harm=0.45,
))

# --- bellow: the honk button. ---------------------------------------------
# The one button in this game that does nothing, and the thing a child will
# press twenty times in a row -- so two variants, alternated, and mixed below
# the cue that actually says "that worked".
#
# Deliberately NOT a roar. A real bull elephant seal rears up and roars and it
# is terrifying; the scope rules all of that out. This is a burp with opinions:
# low, round, slightly rude, and over quickly.
for idx, base in enumerate((note(-17), note(-15))):
    def shape(p, base=base):
        # Up into it, then a long sag. A burp, not a threat.
        return (base
                * (1.0 + 0.16 * math.sin(math.pi * min(1.0, p * 1.6)) - 0.13 * p)
                * (1.0 + 0.05 * math.sin(2 * math.pi * 5.0 * p)))
    write(f"kid_bellow{idx + 1}", bend(shape, 0.75, amp=0.55, total=0.75, harm=0.42))

# --- snore: the nap, which is the reward. ---------------------------------
# "The biggest noise in the game is a snore, and it arrives after a yawn that
# telegraphs it" (the scope). Two slow breaths: a swell in, a longer sag out.
# The softest attack of anything in the app -- a quarter of a second -- so that
# the loudest moment in the game still cannot startle anybody.
total = 2.3
buf = [0.0] * int(SR * total)
for start in (0.0, 1.20):
    bend(lambda p: note(-19) * (1.0 + 0.20 * math.sin(math.pi * p)),
         0.95, amp=0.5, start=start, buf=buf, total=total, harm=0.34, attack=0.25)
    # A quiet fifth above, so it reads as a big soft body rather than a hum.
    bend(lambda p: note(-12) * (1.0 + 0.18 * math.sin(math.pi * p)),
         0.85, amp=0.16, start=start + 0.05, buf=buf, total=total, harm=0.2, attack=0.3)
write("kid_snore1", buf)

# --- the answers: the town replying to the bellow, in a round. ------------
# The dog, the seagulls, a wallaby thumping the ground, a ute, a cow over the
# fence. Played one after another in a shuffled order, so the round is never
# the same twice -- which is the whole reason this game's honk is not Car
# Trip's horn (the scope's *Kid-rules impact*).
#
# All five sit on the same pentatonic scale as everything else in the app.
# That matters more here than anywhere: this is the one cue designed to
# overlap with itself, and it has to stay consonant however the round lands.
_answers = (
    # (name, [(freq, start, dur, amp)], total, harm)
    # dog: two quick mid barks, warm and blunt.
    ("dog",     [(E5, 0.00, 0.10, 0.5), (E5, 0.16, 0.12, 0.45)], 0.32, 0.4),
    # seagulls: a pair of high rising chirps. Quiet -- high and loud is the
    # one combination that startles.
    ("seagull", [(C6, 0.00, 0.09, 0.3), (E6, 0.11, 0.10, 0.26)], 0.26, 0.12),
    # wallaby: two very low thumps on the ground. Felt more than heard.
    ("wallaby", [(note(-19), 0.00, 0.13, 0.55), (note(-19), 0.20, 0.13, 0.45)], 0.38, 0.5),
    # ute: a warm two-note parp from over the road.
    ("ute",     [(G5, 0.00, 0.16, 0.4), (C5, 0.00, 0.16, 0.34)], 0.24, 0.3),
    # cow: one long low note, falling. The last word, usually.
    ("cow",     [(note(-5), 0.00, 0.52, 0.5)], 0.56, 0.36),
)
for idx, (name, voices, total, harm) in enumerate(_answers):
    buf = [0.0] * int(SR * total)
    for freq, start, dur, amp in voices:
        if name == "cow":
            # The cow sags; everything else holds its note.
            bend(lambda p, f=freq: f * (1.0 - 0.14 * p),
                 dur, amp=amp, start=start, buf=buf, total=total, harm=harm)
        else:
            tone(freq, dur, amp=amp, start=start, buf=buf, total=total)
    write(f"kid_answer{idx + 1}", buf)

# --- wriggle: Neil being rubbed. -------------------------------------------
# It fills nothing, unlocks nothing and changes nothing, and it is probably the
# reason a child comes back to this game — so it gets its own cue rather than
# borrowing the flump. A small contented burble, rising: the sound of an animal
# enjoying itself and nothing more.
for idx, base in enumerate((note(-10), note(-8))):
    dur = 0.34
    def shape(p, base=base):
        return base * (1.0 + 0.18 * p) * (1.0 + 0.07 * math.sin(2 * math.pi * 9 * p))
    write(f"kid_wriggle{idx + 1}", bend(shape, dur, amp=0.5, total=dur, harm=0.3))
