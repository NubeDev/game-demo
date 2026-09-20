List<String> soundTypeToFilename(SfxType type) => switch (type) {
  // Kid cues. Several variants where the sound repeats often, so a child
  // popping twenty balloons does not hear one identical sample twenty times.
  SfxType.kidPop => const ['kid_pop1.mp3', 'kid_pop2.mp3', 'kid_pop3.mp3'],
  SfxType.kidCelebrate => const ['kid_celebrate1.mp3'],
  SfxType.kidWobble => const ['kid_wobble1.mp3'],
  SfxType.kidTap => const ['kid_tap1.mp3'],

  // The countdown ladder (Blast Off): one rung per number, ten rungs climbing
  // a pentatonic scale. Played in order, so the sound itself says "nearly
  // there" to a child who cannot read the digit.
  SfxType.kidCount => const [
    'kid_count1.mp3',
    'kid_count2.mp3',
    'kid_count3.mp3',
    'kid_count4.mp3',
    'kid_count5.mp3',
    'kid_count6.mp3',
    'kid_count7.mp3',
    'kid_count8.mp3',
    'kid_count9.mp3',
    'kid_count10.mp3',
  ],
  SfxType.kidLaunch => const ['kid_launch1.mp3'],

  // The Car Trip horn. Two variants, alternated, because this is the one cue a
  // child presses for its own sake — a single sample would grate within a
  // minute of discovering the button.
  SfxType.kidHorn => const ['kid_horn1.mp3', 'kid_horn2.mp3'],

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
    case SfxType.kidCount:
      // Between the pop and the celebration: the count is frequent, so it
      // must not tire, but it is the thing being listened to.
      return 0.6;
    case SfxType.kidLaunch:
      // Zero is the biggest moment in the game, so it matches the
      // celebration rather than exceeding it — the ordering wobble < pop <
      // count < celebrate/launch is pinned by a test (CLAUDE.md §3).
      return 0.8;
    case SfxType.kidHorn:
      // Below the pop on purpose. The horn does nothing useful and will be
      // pressed dozens of times in a row, so it must never drown out the cue
      // that actually says "that worked" (CLAUDE.md §3).
      return 0.45;
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
  kidCount,
  kidLaunch,
  kidHorn,
  score,
  jump,
  doubleJump,
  hit,
  damage,
  buttonTap,
}
