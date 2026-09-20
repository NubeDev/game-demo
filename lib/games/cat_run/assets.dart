/// Every asset path Cat Run uses, in one place.
///
/// Placeholder art is drawn in code (coloured shapes), so there are no image
/// paths yet. When real artwork arrives the paths land here and nothing else in
/// the game changes — see CLAUDE.md §5.
class CatRunAssets {
  const CatRunAssets._();

  // TODO(art): the cat. Currently a shape-drawn blob cat in
  // `components/cat.dart` — the jump arc was tuned against it, so the sprite
  // that replaces it has to keep the same body height and foot line or the
  // clearances in `world.dart` stop matching what the child sees.
  // static const cat = 'images/cat_run/cat.png';

  // TODO(art): obstacles — fence, flowerpot, log, puddle, pipe, branch,
  // washing line, mushroom, snail, cushion, block. One sprite each; the
  // hitboxes live in `obstacles.dart` and are deliberately smaller than the
  // art, so swapping art does not change the timing.
  // static const fence = 'images/cat_run/fence.png';

  // TODO(art): the Rive cat, if the character ever becomes one. See the
  // README — a shape cat does everything this game needs, and
  // `lib/shared/rive_character.dart` is ready if that changes.
  // static const catRive = 'assets/rive/cat.riv';
}
