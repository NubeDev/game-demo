import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../world.dart';

/// The half-built rainbow arch on the horizon.
///
/// **Progress is visible twice** — behind her in the [Trail], and ahead of her
/// here. Each crystal slots a piece in. It is a picture that only ever fills,
/// never a number and never a bar that could go down.
///
/// ## Two sides, and the quiet help
///
/// The left half is blue, the right half pink, and the arch is full when both
/// sides are. This is what gives flying a shape — you have to go up sometimes —
/// and it is safe only because of the quiet help in [CrystalPartyWorld]: a
/// colour that falls behind starts appearing more often and lower down, so a
/// child who cannot yet manage the hold still reaches the party. **There is no
/// state in which the arch cannot be finished.**
///
/// ## The party is bright but SLOW
///
/// The single most likely rule in this repo to be broken by a future session
/// trying to make the ending feel big (the scope says so outright). A "crystal
/// party" is a strobe waiting to happen, and that is a real photosensitivity
/// risk (CLAUDE.md §3). So: [_blazeSeconds] is a slow swell, the glow eases in
/// over more than a second, and **nothing here changes faster than about twice
/// a second** — [_shimmerHz] is the ceiling on that and it is load-bearing.
/// Big is achieved with scale and colour, never with rate.
class Arch extends PositionComponent {
  Arch({required this.piecesPerSide, required super.position})
    : super(priority: -50);

  /// How many pieces each half takes. Twelve crystals a land, so six a side.
  final int piecesPerSide;

  final _filled = <CrystalColour, int>{
    CrystalColour.blue: 0,
    CrystalColour.pink: 0,
  };

  /// 0..1 — the blaze at the party. Swells, never flashes.
  double _blaze = 0;
  bool _blazing = false;

  /// How long the blaze takes to reach full. Slow on purpose: see the class
  /// doc. Do not shorten this.
  static const _blazeSeconds = 1.6;

  /// The fastest anything in this component is allowed to change, in cycles per
  /// second. **The photosensitivity ceiling** — the scope's "nothing changing
  /// faster than about twice a second". Anything added here must respect it.
  static const _shimmerHz = 1.6;

  double _time = 0;

  /// How many pieces of [colour] are in. Exposed for tests.
  int filled(CrystalColour colour) => _filled[colour]!;

  bool get isFull =>
      _filled[CrystalColour.blue]! >= piecesPerSide &&
      _filled[CrystalColour.pink]! >= piecesPerSide;

  /// How far along the blaze is, 0..1. Exposed for tests, which cannot see it.
  double get blaze => _blaze;

  /// Slot a piece in. Never removes one — there is no call that does.
  void addPiece(CrystalColour colour) {
    _filled[colour] = min(piecesPerSide, _filled[colour]! + 1);
  }

  /// The arch is full. Light it up, slowly.
  void startBlaze() => _blazing = true;

  /// Next land: an empty arch again, back on the horizon.
  void reset() {
    for (final colour in CrystalColour.values) {
      _filled[colour] = 0;
    }
    _blaze = 0;
    _blazing = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    if (_blazing && _blaze < 1) {
      _blaze = min(1, _blaze + dt / _blazeSeconds);
    }
  }

  @override
  void render(Canvas canvas) {
    if (size.x <= 0 || size.y <= 0) return;

    final centre = Offset(size.x / 2, size.y);
    final bands = archRainbow;

    // A SLIM ring, not a filled fan.
    //
    // The bands together take up only the outer third of the radius, so the
    // arch reads as an arch with sky showing through it. With wider bands the
    // six of them filled the whole disc and it looked like a paper fan
    // standing on the hill — which is not a thing a child recognises, and it
    // covered the part of the sky the pink crystals live in.
    final outerRadius = size.y * 0.94;
    final bandWidth = size.y * 0.055;

    for (var band = 0; band < bands.length; band++) {
      final radius = outerRadius - band * bandWidth;

      // Each band is drawn as a run of separate pieces, so "half-built" is
      // literally visible: the gaps are the pieces not yet gathered.
      for (var side = 0; side < 2; side++) {
        final colour = side == 0 ? CrystalColour.blue : CrystalColour.pink;
        final have = _filled[colour]!;
        for (var piece = 0; piece < piecesPerSide; piece++) {
          final isIn = piece < have || _blaze > 0;

          // Left half sweeps from the ground up to the top; right half down.
          final fraction = (piece + 0.5) / piecesPerSide;
          final angle = side == 0
              ? pi + fraction * pi / 2
              : pi * 2 - fraction * pi / 2;
          // A small gap between pieces, so they read as slotted-in blocks.
          final sweep = (pi / 2) / piecesPerSide * 0.82;

          // A piece not yet gathered is drawn as a GHOST rather than skipped.
          //
          // This is what makes the arch "visibly unfinished" from the first
          // second (the scope) instead of invisible until the first crystal:
          // the child can see the shape that is going to be filled, and each
          // crystal visibly turns one ghost solid. Without this the arch
          // simply is not there at the start of a land, which is the whole
          // point of having it on the horizon.
          if (!isIn) {
            canvas.drawArc(
              Rect.fromCircle(center: centre, radius: radius),
              angle - sweep / 2,
              sweep,
              false,
              Paint()
                ..color = Colors.white.withValues(alpha: 0.5)
                ..strokeWidth = bandWidth
                ..strokeCap = StrokeCap.butt
                ..style = PaintingStyle.stroke,
            );
            continue;
          }

          // The blaze fills the missing pieces in as it swells, so the arch
          // COMPLETES rather than switching on — and the completion is the
          // slow part.
          final blazeIn = piece < have
              ? 1.0
              : (_blaze * 1.4 - piece / piecesPerSide).clamp(0.0, 1.0);
          if (blazeIn <= 0) continue;

          // The shimmer, capped at the photosensitivity ceiling and small in
          // amplitude: a gentle breathing, never a blink.
          final shimmer =
              1 + sin(_time * pi * 2 * _shimmerHz + piece) * 0.06 * _blaze;

          canvas.drawArc(
            Rect.fromCircle(center: centre, radius: radius),
            angle - sweep / 2,
            sweep,
            false,
            Paint()
              ..color = Color.lerp(
                bands[band].withValues(alpha: 0.5),
                bands[band],
                _blaze,
              )!.withValues(alpha: (0.5 + 0.5 * _blaze) * blazeIn)
              ..strokeWidth = bandWidth * shimmer
              ..strokeCap = StrokeCap.butt
              ..style = PaintingStyle.stroke,
          );
        }
      }
    }

    // The glow at the party. Big and soft — scale, not rate.
    if (_blaze > 0) {
      canvas.drawCircle(
        centre,
        size.y * 0.75 * (0.8 + 0.2 * _blaze),
        Paint()
          ..color = Colors.white.withValues(alpha: _blaze * 0.22)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 30 * _blaze),
      );
    }
  }
}

/// The rainbow, kept identical to the unicorn's ribbon so the arch reads as the
/// same magic as her trail. Imported by value rather than reaching into the
/// component, which keeps this file free of a dependency on her.
const archRainbow = <Color>[
  Color(0xFFFF8FA8),
  Color(0xFFFFC46B),
  Color(0xFFFFE97A),
  Color(0xFF8FE3A0),
  Color(0xFF7FC9F5),
  Color(0xFFC49BF0),
];
