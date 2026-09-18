import 'dart:math';

import 'package:flutter/painting.dart';

/// Shapes drawn in more than one place.
///
/// Placeholder art is "simple coloured shapes" (CLAUDE.md §5) — but a star that
/// is actually a circle teaches the child nothing and reads as a dot. These are
/// the real outlines, so the placeholder stage still looks like what it means.
class KidShapes {
  const KidShapes._();

  /// A classic five-point star, point upwards.
  ///
  /// [innerRatio] is how far in the valleys sit: lower is spikier. 0.45 is the
  /// friendly, chunky star a child recognises, rather than a sharp asterisk.
  static Path star(
    Offset centre,
    double radius, {
    int points = 5,
    double innerRatio = 0.45,
  }) {
    final path = Path();
    // Start at the top so the star always points up, whatever the point count.
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : radius * innerRatio;
      final a = -pi / 2 + i * pi / points;
      final p = Offset(centre.dx + cos(a) * r, centre.dy + sin(a) * r);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  /// A soft cloud: three overlapping lobes on a flat base. Deliberately round —
  /// nothing in a five-year-old's sky should have a corner.
  static Path cloud(Offset centre, double width) {
    final h = width * 0.42;
    final rect = Rect.fromCenter(center: centre, width: width, height: h);
    return Path()
      ..addOval(Rect.fromCircle(
        center: Offset(rect.left + width * 0.28, rect.center.dy),
        radius: h * 0.44,
      ))
      ..addOval(Rect.fromCircle(
        center: Offset(rect.center.dx, rect.center.dy - h * 0.16),
        radius: h * 0.58,
      ))
      ..addOval(Rect.fromCircle(
        center: Offset(rect.right - width * 0.26, rect.center.dy),
        radius: h * 0.40,
      ))
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTRB(
          rect.left + width * 0.16,
          rect.center.dy - h * 0.08,
          rect.right - width * 0.14,
          rect.center.dy + h * 0.42,
        ),
        Radius.circular(h * 0.25),
      ));
  }
}
