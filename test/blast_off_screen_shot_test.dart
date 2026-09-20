@Tags(['render'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_games/audio/audio_controller.dart';
import 'package:little_games/games/blast_off/blast_off_screen.dart';
import 'package:little_games/player_progress/persistence/memory_player_progress_persistence.dart';
import 'package:little_games/player_progress/player_progress.dart';
import 'package:little_games/settings/persistence/memory_settings_persistence.dart';
import 'package:little_games/settings/settings.dart';
import 'package:provider/provider.dart';

/// Renders Blast Off so the LAYOUT can be looked at, at the sizes where the
/// rocket and the control buttons used to collide. Overlap and crowding are
/// not things an assertion judges well — this is for eyes.
const _outDir = String.fromEnvironment('SHOT_DIR', defaultValue: '');

const _shots = <(String, Size)>[
  ('tablet', Size(1280, 800)),
  ('iphone-se', Size(667, 375)),
  ('short-window', Size(1068, 348)),
];

void main() {
  for (final (name, size) in _shots) {
    testWidgets('render $name', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) =>
                  PlayerProgress(store: MemoryOnlyPlayerProgressPersistence()),
            ),
            Provider(
              create: (_) =>
                  SettingsController(store: MemoryOnlySettingsPersistence()),
            ),
            Provider(create: (_) => AudioController()),
          ],
          child: MediaQuery(
            data: MediaQueryData(size: size),
            child: const MaterialApp(
              home: RepaintBoundary(
                key: Key('shot'),
                child: BlastOffScreen(),
              ),
            ),
          ),
        ),
      );
      // Long enough for the Flame loop to lay the scene out and draw it.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      if (_outDir.isEmpty) return;
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('shot')),
      );
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$_outDir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }
}
