import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../audio/audio_controller.dart';
import '../../shared/home_button.dart';
import '../../shared/kid_sounds.dart';
import 'balloon_pop_game.dart';

/// Hosts [BalloonPopGame] and overlays the shared home button.
///
/// The home button is a Flutter widget on top of the game rather than a Flame
/// component, so it is identical in every game and cannot be accidentally
/// restyled per game.
class BalloonPopScreen extends StatelessWidget {
  const BalloonPopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sounds = KidSounds(context.read<AudioController>());

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: GameWidget(game: BalloonPopGame(sounds: sounds)),
          ),
          // Top-right, the same corner in every game. Padded well away from
          // the edge so it is not hit while reaching across the screen, but
          // never hidden.
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
