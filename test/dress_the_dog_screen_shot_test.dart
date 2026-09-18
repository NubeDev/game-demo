@Tags(['render'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_games/audio/audio_controller.dart';
import 'package:little_games/games/dress_the_dog/dress_the_dog_screen.dart';
import 'package:little_games/games/dress_the_dog/wardrobe.dart';
import 'package:little_games/player_progress/persistence/memory_player_progress_persistence.dart';
import 'package:little_games/player_progress/player_progress.dart';
import 'package:little_games/settings/persistence/memory_settings_persistence.dart';
import 'package:little_games/settings/settings.dart';
import 'package:provider/provider.dart';

/// Renders the whole screen at tablet landscape size, so the LAYOUT can be
/// looked at — crowding, overlap and reach are not things a test can judge.
const _outDir = String.fromEnvironment('SHOT_DIR', defaultValue: '');

void main() {
  testWidgets('render screen', (tester) async {
    const size = Size(1280, 800);
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
        child: const MediaQuery(
          data: MediaQueryData(size: size),
          child: MaterialApp(
            home: RepaintBoundary(
              key: Key('shot'),
              child: DressTheDogScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    // Mid-drag: pick a coat up and hold it over the dog, so the drag ghost and
    // the dog's perked-up "ready to catch" pose can be looked at.
    // Press a clothing tile and drag it out over the sky, stopping SHORT of
    // the dog: this is the moment the child sees most — item in hand, dog
    // perked up and waiting, nothing committed yet.
    final tile = find.byType(Draggable<WardrobeItem>).first;
    final gesture = await tester.startGesture(tester.getCenter(tile));
    await tester.pump();
    // Several small moves, as a finger actually travels.
    for (final x in [900.0, 860.0, 820.0]) {
      await gesture.moveTo(Offset(x, 300));
      await tester.pump(const Duration(milliseconds: 60));
    }
    await tester.pump(const Duration(milliseconds: 120));

    if (_outDir.isEmpty) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('shot')),
    );
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$_outDir/screen.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
