import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../lands.dart';
import '../little_train_game.dart';
import '../ride.dart';
import 'draw.dart';

/// Everything behind the passengers and the train: sky, props, the station,
/// the stop posts, and the strip of track.
///
/// ## Why the pictures are mirror-tiled
///
/// The generated sky and track pictures were never drawn to tile — their left
/// and right edges do not match. Laying every other copy down flipped makes
/// each seam meet its own mirror image, so the join is invisible by
/// construction. The cost is some symmetry a grown-up might spot; a child
/// watching the train will not.
class Scenery extends Component with HasGameReference<LittleTrainGame> {
  /// How much slower than the track the sky moves. Far away, so slow.
  static const skyParallax = 0.25;

  /// How tall the gap between the rails is drawn, in ride units. Every land's
  /// strip is scaled to hit this, so all four tracks read as one railway.
  static const gaugeOnScreen = 0.055;

  static const propHeight = 0.42;
  static const stationHeight = 0.5;
  static const stopPostHeight = 0.26;

  /// Props are placed on a grid this far apart, then nudged.
  static const propSpacing = 1.15;

  @override
  void render(Canvas canvas) {
    final g = game;
    final land = g.ride.land;
    final size = g.size;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = land.skyColor,
    );

    _sky(canvas, g, land);

    final strip = g.images.fromCache(land.ground);
    final stripHeight = gaugeOnScreen * g.unit / land.gauge;
    final stripTop = g.railY - land.railLine * stripHeight;

    // Under the strip, so a tall screen never shows sky below the track.
    canvas.drawRect(
      Rect.fromLTRB(0, stripTop + stripHeight * 0.5, size.x, size.y),
      Paint()..color = land.groundColor,
    );

    // Things that stand behind the track stand on its far edge.
    final backLine = g.backLine;
    _props(canvas, g, land, backLine);
    _station(canvas, g, land, backLine);
    _stopPosts(canvas, g, backLine);

    _tiled(
      canvas,
      strip,
      top: stripTop,
      height: stripHeight,
      scroll: g.ride.trainX * g.unit,
      width: size.x,
    );
  }

  void _sky(Canvas canvas, LittleTrainGame g, Land land) {
    final sky = g.images.fromCache(land.sky);
    // Tall enough to reach under the track strip, so its own ground shows
    // through any gaps in the strip's top edge.
    final height = g.railY + 0.08 * g.unit;
    _tiled(
      canvas,
      sky,
      top: 0,
      height: height,
      scroll: g.ride.trainX * g.unit * skyParallax,
      width: g.size.x,
    );
  }

  void _tiled(
    Canvas canvas,
    Image image, {
    required double top,
    required double height,
    required double scroll,
    required double width,
  }) {
    final tileWidth = height * image.width / image.height;
    final first = (scroll / tileWidth).floor();
    for (var k = first; k * tileWidth - scroll < width; k++) {
      final left = k * tileWidth - scroll;
      drawPicture(
        canvas,
        image,
        Rect.fromLTWH(left, top, tileWidth + 0.5, height),
        flip: k.isOdd,
      );
    }
  }

  void _props(Canvas canvas, LittleTrainGame g, Land land, double backLine) {
    final ride = g.ride;
    final left = ride.trainX - g.frontX / g.unit - propHeight;
    final right = ride.trainX + ride.viewAhead + propHeight;
    final paths = land.propPaths;
    for (var k = (left / propSpacing).floor();
        k * propSpacing < right;
        k++) {
      // Deterministic per grid slot, so a prop is the same prop every frame
      // and every time it scrolls back past (it never does, but tests do).
      final r = Random(k * 7919 + ride.landIndex);
      if (r.nextDouble() < 0.25) continue; // the odd gap reads as natural
      final x = k * propSpacing + r.nextDouble() * propSpacing * 0.6;
      if (_crowded(ride, x)) continue;
      final image = g.images.fromCache(paths[r.nextInt(paths.length)]);
      final h = propHeight * (0.8 + r.nextDouble() * 0.35) * g.unit;
      drawPicture(
        canvas,
        image,
        standing(image, g.screenX(x), backLine, h),
        flip: r.nextBool(),
      );
    }
  }

  /// Keep props off the stop posts and the station, so a waiting passenger is
  /// never half-hidden behind a tree — they are the thing to look at.
  bool _crowded(Ride ride, double x) {
    for (final p in ride.passengers) {
      if ((p.stopX - x).abs() < 0.7) return true;
    }
    return (ride.stationBuildingX - x).abs() < 0.75;
  }

  void _station(Canvas canvas, LittleTrainGame g, Land land, double backLine) {
    final image = g.images.fromCache(land.station);
    final rect = standing(
      image,
      g.screenX(g.ride.stationBuildingX),
      backLine,
      stationHeight * g.unit,
    );
    if (rect.right < 0 || rect.left > g.size.x) return;
    drawPicture(canvas, image, rect);
  }

  void _stopPosts(Canvas canvas, LittleTrainGame g, double backLine) {
    final image = g.images.fromCache(g.stopPostPath);
    for (final p in g.ride.passengers) {
      final rect = standing(
        image,
        g.screenX(p.stopX + 0.16),
        backLine,
        stopPostHeight * g.unit,
      );
      if (rect.right < 0 || rect.left > g.size.x) continue;
      drawPicture(canvas, image, rect);
    }
  }
}
