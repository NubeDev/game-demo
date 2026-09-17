/// Every asset path Balloon Pop uses, in one place.
///
/// Placeholder art is currently drawn in code (coloured shapes), so there are
/// no image paths yet. When real artwork arrives, the paths land here and
/// nothing else in the game changes — see CLAUDE.md §5.
class BalloonPopAssets {
  const BalloonPopAssets._();

  /// The Rive character that reacts to pops.
  ///
  /// TODO(art): currently `rewards.riv` from the official flame_rive example,
  /// used so the data binding can be tested before real art exists. See
  /// `lib/games/balloon_pop/README.md` for what a custom file must expose.
  static const character = 'assets/rive/rewards.riv';

  // TODO(art): real balloon sprites, e.g.
  // static const balloonRed = 'images/balloons/red.png';
}
