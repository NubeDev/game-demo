import 'package:flutter/material.dart';

import '../../../shared/kid_palette.dart';
import '../wardrobe.dart';

/// The three weather buttons: sun, rain, snow.
///
/// Kid rules (CLAUDE.md §3, and the scope):
///  * Pictures, never words — the player cannot read.
///  * 100x100 buttons, spaced, so a coarse finger cannot hit two.
///  * **The child is the only thing that changes the weather.** Nothing in the
///    game switches it automatically: an outfit they were pleased with must
///    never be invalidated by something they did not do.
class WeatherSwitch extends StatelessWidget {
  const WeatherSwitch({
    super.key,
    required this.weather,
    required this.onChanged,
  });

  final Weather weather;
  final ValueChanged<Weather> onChanged;

  static const buttonSize = 100.0;

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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final w in Weather.values)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: GestureDetector(
              onTapDown: (_) => onChanged(w),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: buttonSize,
                height: buttonSize,
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
                child: Icon(_icons[w], size: 52, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
