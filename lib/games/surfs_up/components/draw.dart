import 'dart:ui';

import '../../../shared/lantern_cast.dart';

/// The soft-outline style's stroke: the cast's warm brown, round-jointed, so
/// shapes drawn in code sit with the SVG friends.
Paint outlinePaint(double width, {double alpha = 1}) => Paint()
  ..style = PaintingStyle.stroke
  ..color = LanternCast.outline.withValues(alpha: alpha)
  ..strokeWidth = width
  ..strokeJoin = StrokeJoin.round
  ..strokeCap = StrokeCap.round;
