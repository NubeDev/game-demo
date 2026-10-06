import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../audio/audio_controller.dart';
import '../../audio/songs.dart';
import '../../shared/home_button.dart';
import '../../shared/kid_sounds.dart';
import 'little_train_game.dart';

/// Hosts [LittleTrainGame] and the shared home button.
///
/// ## The whole screen is the brake
///
/// There is no button to find. A tap anywhere stops the train, and a tap
/// anywhere starts it again — the biggest touch target possible, for the one
/// thing the game asks (CLAUDE.md §3: targets ≥80×80).
///
/// ## Except the top band, which is the home button's
///
/// The same arrangement as Crystal Party: [topBandHeight] is left out of the
/// play area so a thumb reaching for home never stops the train instead.
class LittleTrainScreen extends StatefulWidget {
  const LittleTrainScreen({super.key});

  /// Tall enough to clear the home button ([HomeButton.size]) and its margin.
  static const double topBandHeight = 132;

  @override
  State<LittleTrainScreen> createState() => _LittleTrainScreenState();
}

class _LittleTrainScreenState extends State<LittleTrainScreen> {
  late final LittleTrainGame _game;

  @visibleForTesting
  LittleTrainGame get gameForTest => _game;

  @override
  void initState() {
    super.initState();
    final audio = context.read<AudioController>();
    audio.playSong(Songs.littleTrain);
    _game = LittleTrainGame(sounds: KidSounds(audio));
  }

  @override
  Widget build(BuildContext context) {
    final sounds = KidSounds(context.read<AudioController>());

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: GameWidget(game: _game)),
          Positioned(
            left: 0,
            right: 0,
            top: LittleTrainScreen.topBandHeight,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              // On the way DOWN: a tap does not resolve until the finger
              // lifts, and a five-year-old's finger often slides first. The
              // train must answer the moment it is touched.
              onTapDown: (_) => _game.tap(),
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: HomeButton(onPressed: sounds.tap),
          ),
        ],
      ),
    );
  }
}
