/// Every asset path Quacky the Duck uses, in one place.
///
/// Placeholder art is drawn in code (coloured shapes), so there are no image
/// paths yet. When real artwork arrives the paths land here and nothing else in
/// the game changes — see CLAUDE.md §5.
class QuackyAssets {
  const QuackyAssets._();

  // TODO(art): Quacky. Currently a shape-drawn duck in `components/quacky.dart`
  // — the duck clearances were tuned against `Quacky.duckedHeight`, so the
  // sprite that replaces it has to keep the same flat height and foot line or
  // the clearances in `quacky_the_duck_game.dart` stop matching what the child
  // sees.
  // static const quacky = 'images/quacky_the_duck/quacky.png';

  // TODO(art): the chase targets — child with a bread bag, duck with a crust,
  // pushchair, pigeon with a sandwich, the duck-food dispenser. One sprite
  // each. Every one of them is LAUGHING and none of them is running away; see
  // the scope's *Kid-rules impact* before drawing any of them.
  // static const childWithBag = 'images/quacky_the_duck/child_with_bag.png';

  // TODO(art): hazards — bench, gate, washing line, picnic rug, sprinkler, dog
  // lead, bin, puddle, pigeons, deckchair. The hitboxes live in `park.dart` and
  // are deliberately smaller than the art, so swapping art does not change the
  // timing.
  // static const bench = 'images/quacky_the_duck/bench.png';

  // TODO(art): the Rive Quacky, if the character ever becomes one. `Mood`
  // already runs 0..1 through `Mood.brightness`, which is exactly what a bound
  // ViewModelInstanceNumber would take — this is the strongest candidate
  // `lib/shared/rive_character.dart` has had. See the scope's open question.
  // static const quackyRive = 'assets/rive/quacky.riv';
}
