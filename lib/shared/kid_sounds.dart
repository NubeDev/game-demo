import '../audio/audio_controller.dart';
import '../audio/sounds.dart';

/// Named sound cues for the games.
///
/// Games ask for a *feeling* (`pop`, `celebrate`, `wobble`) rather than an
/// asset path, so swapping the actual audio later is a one-file change here.
///
/// Everything routes through the template's [AudioController], which already
/// honours the mute settings — so muting in the parent area silences these
/// automatically and no game has to check.
///
/// TODO(art): these currently reuse the template's arcade sfx. Replace with
/// soft, friendly equivalents. A realistic balloon *bang* would startle a
/// five-year-old — the pop needs to be a gentle "boop".
class KidSounds {
  const KidSounds(this._audio);

  final AudioController _audio;

  /// A balloon popped, a shape dropped in the right hole — the small, frequent
  /// "yes that worked" cue.
  void pop() => _audio.playSfx(SfxType.score);

  /// The big one, after a set of successes.
  void celebrate() => _audio.playSfx(SfxType.score);

  /// A gentle "not that one, try again". Deliberately soft and short: this is
  /// the only cue that follows a mistake, and it must never sound like a
  /// buzzer. Never accompanied by anything that takes progress away.
  void wobble() => _audio.playSfx(SfxType.hit);

  /// A button or menu tap.
  void tap() => _audio.playSfx(SfxType.buttonTap);
}
