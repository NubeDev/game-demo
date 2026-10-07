import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../audio/audio_controller.dart';
import '../../audio/songs.dart';
import '../../shared/home_button.dart';
import '../../shared/kid_sounds.dart';
import 'surfs_up_game.dart';

/// Hosts [SurfsUpGame] and the shared home button.
///
/// The whole screen below the top band is the one control — a tap anywhere
/// means "up" — so there is nothing to aim at (CLAUDE.md §3: targets ≥80×80).
/// The top band is the home button's, so a thumb reaching for home never
/// pops Koko up instead. Same arrangement as Little Train.
class SurfsUpScreen extends StatefulWidget {
  const SurfsUpScreen({super.key});

  /// Tall enough to clear the home button ([HomeButton.size]) and its margin.
  static const double topBandHeight = 132;

  @override
  State<SurfsUpScreen> createState() => _SurfsUpScreenState();
}

class _SurfsUpScreenState extends State<SurfsUpScreen> {
  late final SurfsUpGame _game;

  @visibleForTesting
  SurfsUpGame get gameForTest => _game;

  @override
  void initState() {
    super.initState();
    final audio = context.read<AudioController>();
    audio.playSong(Songs.play);
    _game = SurfsUpGame(sounds: KidSounds(audio));
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
            top: SurfsUpScreen.topBandHeight,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              // On the way DOWN, so the pop-up answers the moment the finger
              // lands — a tap that only counted on lift would feel late.
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
