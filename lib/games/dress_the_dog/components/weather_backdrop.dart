import 'dart:math';

import 'package:flutter/material.dart';

import '../wardrobe.dart';

/// Sky, ground and falling weather behind the dog.
///
/// Deliberately calm (CLAUDE.md §3): **no lightning, no thunder, no flashing**.
/// Rain falls softly and snow drifts; neither ever gets heavy enough to read as
/// a storm. The sky is pale so the dog and the wardrobe stay the loudest things
/// on screen.
class WeatherBackdrop extends StatelessWidget {
  const WeatherBackdrop({super.key, required this.weather, required this.t});

  final Weather weather;
  final double t;

  @override
  Widget build(BuildContext context) {
    final (top, bottom) = Wardrobe.skyFor(weather);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ),
      ),
      child: CustomPaint(
        painter: _WeatherPainter(weather: weather, t: t),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _WeatherPainter extends CustomPainter {
  _WeatherPainter({required this.weather, required this.t});

  final Weather weather;
  final double t;

  /// Fixed so the flakes don't reshuffle every frame.
  static final _random = Random(7);
  static final _drops = List.generate(
    54,
    (_) => (_random.nextDouble(), _random.nextDouble(), _random.nextDouble()),
  );

  @override
  void paint(Canvas canvas, Size size) {
    // Ground: a soft band, tinted by the weather.
    final groundColor = switch (weather) {
      Weather.sun => const Color(0xFF9FDF95),
      Weather.rain => const Color(0xFF86B98A),
      Weather.snow => const Color(0xFFF7FBFF),
    };
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-40, size.height - 96, size.width + 80, 200),
        const Radius.circular(70),
      ),
      Paint()..color = groundColor,
    );

    if (weather == Weather.sun) {
      // A friendly sun in the corner, no rays that could strobe.
      canvas.drawCircle(
        Offset(size.width * 0.5, 74),
        52,
        Paint()..color = const Color(0xFFFFE9A3),
      );
      return;
    }

    for (final (fx, fy, speed) in _drops) {
      final fall = (fy + t * (0.05 + speed * 0.12)) % 1.0;
      final x = fx * size.width;
      final y = fall * size.height;
      if (weather == Weather.rain) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, 4, 15),
            const Radius.circular(2),
          ),
          Paint()..color = const Color(0xFF8FBEDD).withValues(alpha: 0.7),
        );
      } else {
        // Snow drifts sideways as it falls, so it reads as snow and not rain.
        canvas.drawCircle(
          Offset(x + sin(t * 0.8 + fy * 6) * 12, y),
          3.5 + speed * 2.5,
          Paint()..color = Colors.white.withValues(alpha: 0.9),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_WeatherPainter old) =>
      old.t != t || old.weather != weather;
}
