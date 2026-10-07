import '../../shared/lantern_cast.dart';

/// Every asset path Surf's Up uses, in one place (CLAUDE.md §5).
///
/// The friends are the approved Lantern Island SVGs ([LanternFriend]). The
/// sea, sky, sand, board and shells are drawn in code in the same soft-outline
/// style (flat fills, a warm brown outline), so there is nothing else to load.
class SurfsUpAssets {
  const SurfsUpAssets._();

  /// Koko with her leaning surfboard and ground shadow taken out of
  /// `koko-quokka.svg` and the view box trimmed to her — the game draws her
  /// standing ON a board it draws itself. Everything else in the file is the
  /// approved artwork, untouched.
  static const kokoSurfing = '${LanternCast.dir}/koko-surf.svg';
}
