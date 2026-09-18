List<String> soundTypeToFilename(SfxType type) => switch (type) {
  // Kid cues. Several variants where the sound repeats often, so a child
  // popping twenty balloons does not hear one identical sample twenty times.
  SfxType.kidPop => const ['kid_pop1.mp3', 'kid_pop2.mp3', 'kid_pop3.mp3'],
  SfxType.kidCelebrate => const ['kid_celebrate1.mp3'],
  SfxType.kidWobble => const ['kid_wobble1.mp3'],
  SfxType.kidTap => const ['kid_tap1.mp3'],

  // Template sfx, kept for reference. Not used by any game — they are arcade
  // hit/damage sounds and too harsh for this audience (CLAUDE.md §3).
  SfxType.jump => const ['jump1.mp3'],
  SfxType.doubleJump => const ['double_jump1.mp3'],
  SfxType.hit => const ['hit1.mp3', 'hit2.mp3'],
  SfxType.damage => const ['damage1.mp3', 'damage2.mp3'],
  SfxType.score => const ['score1.mp3', 'score2.mp3'],
  SfxType.buttonTap => const [
    'click1.mp3',
    'click2.mp3',
    'click3.mp3',
    'click4.mp3',
  ],
};

/// Allows control over loudness of different SFX types.
///
/// The kid cues are mixed deliberately: the pop is frequent so it sits low,
/// the celebration is the loudest thing in the app because it is the reward,
/// and the wobble is the quietest of all — it follows a mistake and must never
/// feel like being told off (CLAUDE.md §3).
double soundTypeToVolume(SfxType type) {
  switch (type) {
    case SfxType.kidPop:
      return 0.55;
    case SfxType.kidCelebrate:
      return 0.8;
    case SfxType.kidWobble:
      return 0.3;
    case SfxType.kidTap:
      return 0.5;
    case SfxType.score:
    case SfxType.jump:
    case SfxType.doubleJump:
    case SfxType.damage:
    case SfxType.hit:
      return 0.4;
    case SfxType.buttonTap:
      return 1.0;
  }
}

enum SfxType {
  kidPop,
  kidCelebrate,
  kidWobble,
  kidTap,
  score,
  jump,
  doubleJump,
  hit,
  damage,
  buttonTap,
}
