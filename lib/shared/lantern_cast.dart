import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The six Lantern Island friends, and the one place their pictures live.
///
/// The cast and their soft-outline artwork come from the Lantern Island spec
/// (`game-script/LANTERN_ISLAND_SPEC.md`). The names there are provisional, so
/// they are kept here and nowhere else: renaming a friend is a one-line edit.
/// Names are never shown to the child (CLAUDE.md §3: no text to play) — they
/// exist for code, tests and the parent area.
///
/// The artwork is approved SVG, shipped as-is in `assets/lantern_island/`.
/// Games draw it as a raster [ui.Image] made once at load ([rasterizeSvg]),
/// so a frame costs the same as any other picture.
enum LanternFriend {
  koko('Koko', 'koko-quokka'),
  biggy('Biggy', 'biggy-cat'),
  luna('Luna', 'luna-unicorn'),
  tobi('Tobi', 'tobi-seal'),
  tiko('Tiko', 'tiko-platypus'),
  pacho('Pacho', 'pacho-capybara');

  const LanternFriend(this.displayName, this._file);

  final String displayName;
  final String _file;

  String get svg => '${LanternCast.dir}/$_file.svg';
}

class LanternCast {
  const LanternCast._();

  static const dir = 'assets/lantern_island';

  /// The outline colour every friend is drawn with. Scenery drawn in code uses
  /// it too, so the world and the cast read as one picture.
  static const outline = ui.Color(0xFF5A3A28);

  /// The soft beige ground shadow from the style guide.
  static const shadow = ui.Color(0xFFCFC4B8);
}

/// Draws the SVG at [assetPath] into an image [height] pixels tall, keeping
/// its proportions. Done once per picture at load.
///
/// The [bundle] is only for tests; the app reads from the root bundle.
Future<ui.Image> rasterizeSvg(
  String assetPath, {
  double height = 512,
  AssetBundle? bundle,
}) async {
  final info = await vg.loadPicture(
    SvgAssetLoader(assetPath, assetBundle: bundle),
    null,
  );
  final scale = height / info.size.height;
  final width = (info.size.width * scale).ceil();
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder)
    ..scale(scale)
    ..drawPicture(info.picture);
  info.picture.dispose();
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height.ceil());
  picture.dispose();
  return image;
}
