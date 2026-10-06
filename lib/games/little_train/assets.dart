/// Every asset path Little Train uses, in one place (CLAUDE.md §5).
///
/// **This is the first game in the app with real raster art.** Every picture
/// here was generated with Google's Gemini image model by
/// `tools/gen_little_train_art.py`, chroma-keyed to transparency, and shipped
/// as a plain `.webp`. The app never talks to Google: generation happened once,
/// on a developer's machine, and the files are just files (CLAUDE.md §4).
///
/// Paths are relative to `assets/images/`, which is where Flame's image cache
/// looks. To replace a picture, regenerate it with the tool (or drop in a
/// hand-drawn one with the same name) — nothing else changes.
class LittleTrainAssets {
  const LittleTrainAssets._();

  static const _dir = 'little_train';

  /// The style anchor every other picture was generated looking at. Drawn
  /// facing LEFT by the model despite being asked for right, so the train
  /// component flips it.
  static const engine = '$_dir/engine.webp';
  static const wagon = '$_dir/wagon.webp';

  /// The little post-and-bench a passenger waits beside. The sign shows a paw
  /// print rather than a word: nothing here asks the child to read.
  static const stopPost = '$_dir/stop_post.webp';

  /// A passenger standing and waving at the train.
  static String waiting(String animal) => '$_dir/${animal}_wait.webp';

  /// The same passenger sitting with both arms up — drawn behind the wagon, so
  /// only the cheering top half shows over the side.
  static String riding(String animal) => '$_dir/${animal}_ride.webp';

  /// The wide picture behind everything: sky, distant hills, and some ground.
  static String sky(String land) => '$_dir/${land}_sky.webp';

  /// The strip of track and ground the train runs on.
  static String ground(String land) => '$_dir/${land}_ground.webp';

  /// The station at the end of each land.
  static String station(String land) => '$_dir/${land}_station.webp';

  /// One of a land's scenery props (a tree, a snowman, ...).
  static String prop(String land, String prop) => '$_dir/${land}_$prop.webp';
}
