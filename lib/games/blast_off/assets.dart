/// Every asset path Blast Off uses, in one place (CLAUDE.md §5).
///
/// The rocket, the jar and the numbers are drawn in code for now, so there are
/// no image paths yet — placeholder art is simple coloured shapes until real
/// artwork arrives, and swapping it in lands here rather than across the game.
class BlastOffAssets {
  const BlastOffAssets._();

  /// TODO(audio): the recorded voice counting, which is the real feature of
  /// this game and currently missing — the tone ladder in `KidSounds.count`
  /// stands in for it.
  ///
  /// A child who cannot read can absolutely count, and counting backwards out
  /// loud alongside a voice is the whole activity. Ten short files, spoken
  /// warmly and unhurriedly, with no urgency in the delivery:
  ///
  ///   assets/sfx/voice/count_10.mp3 … count_1.mp3, plus blast_off.mp3
  ///
  /// It must be a recording, not text-to-speech: every TTS engine worth using
  /// is a cloud call, and this app makes no network calls, ever (CLAUDE.md §4).
  /// An open question in the scope is whether it should be a *parent's* voice,
  /// recorded behind the parental gate.
  static const voiceCountDir = 'assets/sfx/voice/';

  /// TODO(art): a Rive rocket, if it earns it. `lib/shared/rive_character.dart`
  /// can drive one through data binding (CLAUDE.md §2), but a shape-drawn
  /// rocket may well be enough here — the drama is in the shake, the smoke and
  /// the sound rather than in character animation.
  // static const rocket = 'assets/rive/rocket.riv';
}
