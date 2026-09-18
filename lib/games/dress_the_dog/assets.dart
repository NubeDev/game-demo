/// Every asset path Dress the Dog uses, in one place.
///
/// Placeholder art is currently drawn in code (`components/dog.dart` and the
/// backdrop), so there are no image paths yet. When real artwork arrives the
/// paths land here and nothing else in the game changes — see CLAUDE.md §5.
class DressTheDogAssets {
  const DressTheDogAssets._();

  // TODO(art): the Rive dog. `lib/shared/rive_character.dart` is ready to drive
  // it through data binding (CLAUDE.md §2). The artboard must expose:
  //   * a number per slot — `Head`, `Face`, `Body`, `Feet` — indexing the
  //     wardrobe item worn, 0 for nothing;
  //   * a number `Weather` — 0 sun, 1 rain, 2 snow;
  //   * a number `Feeling` — matching DogFeeling's order in wardrobe.dart;
  //   * a trigger `GoOutside` for the just-right celebration.
  // Until then the shape-drawn dog stands in and the game plays identically.
  // static const dog = 'assets/rive/dog.riv';
}
