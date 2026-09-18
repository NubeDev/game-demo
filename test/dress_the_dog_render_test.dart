@Tags(['render'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_games/games/dress_the_dog/components/dog.dart';
import 'package:little_games/games/dress_the_dog/components/weather_backdrop.dart';
import 'package:little_games/games/dress_the_dog/wardrobe.dart';

/// Renders the placeholder dog to PNGs so it can actually be LOOKED at.
///
/// Not a golden test — nothing is compared. This exists because the dog is
/// drawn in code and `flutter test` cannot tell whether a shivering dog reads
/// as funny or as sad, which is the single thing this game has to get right.
const _outDir = String.fromEnvironment('SHOT_DIR', defaultValue: '');

void main() {
  const cases = <(String, Weather, List<String>)>[
    ('sun-bare', Weather.sun, []),
    ('sun-beach-justright', Weather.sun, ['sun_hat', 'sunglasses', 'swimming_trunks', 'flip_flops']),
    ('sun-toohot', Weather.sun, ['snow_coat', 'woolly_hat']),
    ('snow-swimmers-toocold', Weather.snow, ['swimming_trunks', 'flip_flops']),
    ('snow-justright', Weather.snow, ['woolly_hat', 'scarf', 'snow_coat', 'snow_boots']),
    ('rain-toowet', Weather.rain, []),
    ('rain-justright', Weather.rain, ['umbrella_hat', 'raincoat', 'wellies']),
    ('party', Weather.sun, ['party_hat', 'sunglasses']),
  ];

  testWidgets('render contact sheet', (tester) async {
    const cell = Size(320, 360);
    const cols = 4;
    final rows = (cases.length / cols).ceil();
    final sheet = Size(cell.width * cols, cell.height * rows);

    tester.view.physicalSize = sheet;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Widget cellFor((String, Weather, List<String>) c) {
      final (_, weather, itemIds) = c;
      var outfit = const Outfit();
      for (final id in itemIds) {
        outfit = outfit.wearing(Wardrobe.byId(id));
      }
      final feeling = outfit.feelingIn(weather);
      return SizedBox(
        width: cell.width,
        height: cell.height,
        child: Stack(
          children: [
            Positioned.fill(child: WeatherBackdrop(weather: weather, t: 1.2)),
            // Bottom-aligned, as the screen places it: this is what catches a
            // dog that floats above its own ground.
            Align(
              alignment: Alignment.bottomCenter,
              child: Dog(outfit: outfit, feeling: feeling, t: 1.2),
            ),
          ],
        ),
      );
    }

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: sheet),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(
            key: const Key('shot'),
            child: SizedBox(
              width: sheet.width,
              height: sheet.height,
              child: Column(
                children: [
                  for (var r = 0; r < rows; r++)
                    Row(
                      children: [
                        for (var c = 0; c < cols; c++)
                          if (r * cols + c < cases.length)
                            cellFor(cases[r * cols + c])
                          else
                            SizedBox(width: cell.width, height: cell.height),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    if (_outDir.isEmpty) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('shot')),
    );
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$_outDir/sheet.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
