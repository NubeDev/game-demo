/// Every asset path Balloon Pop uses, in one place.
///
/// Placeholder art is currently drawn in code (coloured shapes), so there are
/// no image paths yet. When real artwork arrives, the paths land here and
/// nothing else in the game changes — see CLAUDE.md §5.
class BalloonPopAssets {
  const BalloonPopAssets._();

  // TODO(art): the Rive character. There is no .riv file yet — the stand-in
  // that used to sit here was the flame_rive example's rewards screen, not a
  // character, and it was removed. `lib/shared/rive_character.dart` is ready
  // for a real one; README.md in this folder says what it must expose. The
  // path lands here and nothing else in the game changes.
  // static const character = 'assets/rive/character.riv';

  // TODO(art): real balloon sprites, e.g.
  // static const balloonRed = 'images/balloons/red.png';
}
