import 'package:flutter/material.dart';

import '../../../shared/kid_palette.dart';
import '../wardrobe.dart';

/// The three weather buttons: sun, rain, snow.
///
/// Kid rules (CLAUDE.md §3, and the scope):
///  * Pictures, never words — the player cannot read.
///  * 100x100 buttons where the screen allows, shrinking with [scale] on a
///    short screen but never below the 80x80 minimum, spaced so a coarse finger
///    cannot hit two.
///  * **The child is the only thing that changes the weather.** Nothing in the
///    game switches it automatically: an outfit they were pleased with must
///    never be invalidated by something they did not do.
class WeatherSwitch extends StatelessWidget {
  const WeatherSwitch({
    super.key,
    required this.weather,
    required this.onChanged,
    this.scale = 1.0,
    this.columns = 3,
  });

  final Weather weather;
  final ValueChanged<Weather> onChanged;

  /// How many buttons go across before wrapping.
  final int columns;

  /// Shrinks the row to fit a short screen; the screen decides this.
  final double scale;

  static const buttonSize = 100.0;

  /// The 80x80 floor from CLAUDE.md §3 — never shrink past a hittable target.
  static const minButtonSize = 84.0;

  static double sizeFor(double scale) =>
      (buttonSize * scale).clamp(minButtonSize, buttonSize);

  /// How wide the row is at [scale] in [columns], so the screen can keep the
  /// dog and the wardrobe clear of it.
  static double widthFor(double scale, [int columns = 3]) =>
      columns * (sizeFor(scale) + 20 * scale);

  /// How tall it is, for the same.
  static double heightFor(double scale, [int columns = 3]) {
    final rows = (Weather.values.length / columns).ceil();
    return rows * sizeFor(scale) + (rows - 1) * (10 * scale);
  }

  /// How many across the buttons go, to fit [room] without any of them
  /// shrinking below the 80x80 rule (CLAUDE.md §3). Three where there is
  /// width for three; otherwise they wrap, which is still three big buttons
  /// rather than three small ones.
  ///
  /// [roomForFullRow], when given, is the width available ignoring whatever
  /// else wants to share the bottom of the screen: a full row that fits THAT
  /// is kept, because wrapping to spare a neighbour space it does not need
  /// just makes the layout worse.
  static int columnsFor(double scale, double room, {double? roomForFullRow}) {
    final full = Weather.values.length;
    if (roomForFullRow != null && widthFor(scale, full) <= roomForFullRow) {
      return full;
    }
    for (var columns = full; columns > 1; columns--) {
      if (widthFor(scale, columns) <= room) return columns;
    }
    return 1;
  }

  static const _icons = {
    Weather.sun: Icons.wb_sunny_rounded,
    Weather.rain: Icons.grain_rounded,
    Weather.snow: Icons.ac_unit_rounded,
  };

  static const _colors = {
    Weather.sun: Color(0xFFFFC94D),
    Weather.rain: Color(0xFF7FB4D8),
    Weather.snow: Color(0xFFBBD9F2),
  };

  @override
  Widget build(BuildContext context) {
    final size = sizeFor(scale);

    return SizedBox(
      // Bounded, so the Wrap below actually wraps at [columns].
      width: widthFor(scale, columns),
      child: Wrap(
      // Wraps rather than shrinks: three buttons a finger can hit, on two
      // lines if need be, beats three that it cannot (CLAUDE.md §3).
      spacing: 0,
      runSpacing: 10 * scale,
      children: [
        for (final w in Weather.values)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10 * scale),
            child: GestureDetector(
              onTapDown: (_) => onChanged(w),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: _colors[w],
                  shape: BoxShape.circle,
                  border: Border.all(
                    // The chosen one is outlined, not dimmed: dimming the
                    // others reads as "those are broken".
                    color: w == weather ? KidPalette.ink : Colors.white,
                    width: w == weather ? 6 : 4,
                  ),
                  boxShadow: const [
                    BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 3)),
                  ],
                ),
                child: Icon(_icons[w], size: size * 0.52, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
