/// Every asset path Crystal Party uses, in one place.
///
/// Placeholder art is drawn in code (coloured shapes), so there are no image
/// paths yet. When real artwork arrives the paths land here and nothing else in
/// the game changes — see CLAUDE.md §5.
class CrystalPartyAssets {
  const CrystalPartyAssets._();

  // TODO(art): the unicorn. Currently a shape-drawn white blob with a triangle
  // horn and a rainbow ribbon in `components/unicorn.dart`. **The flight model
  // was tuned against her exact body height**, so the sprite that replaces her
  // has to keep the same body height and hoof line, or the crystal heights in
  // `world.dart` stop matching what the child sees.
  // static const unicorn = 'images/crystal_party/unicorn.png';

  // TODO(art): the crystals. Blue is a POINTY SHARD and pink is a ROUND BLOB —
  // that shape difference is a kid rule, not a style choice: it is what makes
  // the colour sorting work for a colourblind child (CLAUDE.md §3). Real art
  // must keep the two silhouettes clearly different.
  // static const blueCrystal = 'images/crystal_party/crystal_blue.png';
  // static const pinkCrystal = 'images/crystal_party/crystal_pink.png';

  // TODO(art): props — pine, rocks, stone arch, washing line. Hitboxes live in
  // `components/prop.dart` and are deliberately smaller than the art, so
  // swapping art does not change how forgiving a clip is.

  // TODO(art): treats — waterfall, cloud, butterflies, rainbow puddle.

  // TODO(art): the rainbow arch. Drawn as slotted arcs in
  // `components/arch.dart`; real art has to keep the "half-built" reading,
  // because that IS the progress readout.

  // TODO(art): the friendly creatures — dragon, rabbits, sheep, whale. All
  // scenery, none of them collidable.

  // TODO(art): the Rive unicorn, if the character ever becomes one. The scope
  // calls this the strongest candidate `lib/shared/rive_character.dart` has
  // had — a face that reacts to every crystal. See the README.
  // static const unicornRive = 'assets/rive/unicorn.riv';
}
