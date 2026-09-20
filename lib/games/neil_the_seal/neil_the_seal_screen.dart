import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../audio/audio_controller.dart';
import '../../audio/songs.dart';
import '../../shared/home_button.dart';
import '../../shared/kid_sounds.dart';
import 'components/bellow_button.dart';
import 'neil_the_seal_game.dart';

/// Hosts [NeilTheSealGame], the bellow button and the home button.
///
/// The controls are Flutter widgets over the game rather than Flame components,
/// for the same reason Cat Run's and Car Trip's are: hit testing is easier to
/// reason about, and the home button has to be identical in every game.
///
/// ## The whole screen is the control
///
/// There is no stick, there are no direction buttons and there is nothing to
/// drag. A finger anywhere sends Neil there — the biggest possible target, and
/// nothing at all to discover. A second tap while he is walking replaces the
/// first instantly, so he never has to finish a trip and the child is never
/// waiting on him.
///
/// **A finger that lands on Neil himself rubs him instead.** That is the one
/// place on screen where a touch does not send him anywhere, and it is a
/// hand-sized target ([NeilTheSealGame.isOnNeil]) so it cannot be hit by
/// accident when a child meant to aim past him.
///
/// No hint is drawn anywhere. Car Trip needs one because its control is
/// invisible until you find it; here the very first touch — wherever it lands,
/// however accidental — makes an enormous seal set off across the screen, which
/// teaches the whole game in one go.
class NeilTheSealScreen extends StatefulWidget {
  const NeilTheSealScreen({super.key});

  @override
  State<NeilTheSealScreen> createState() => _NeilTheSealScreenState();
}

class _NeilTheSealScreenState extends State<NeilTheSealScreen> {
  late final NeilTheSealGame _game;

  /// The game, for the test that drives a finger through the real widget tree.
  @visibleForTesting
  NeilTheSealGame get gameForTest => _game;

  /// The pointer that is currently rubbing him, if any. Everything else is a
  /// destination.
  int? _rubbing;

  @override
  void initState() {
    super.initState();
    context.read<AudioController>().playSong(Songs.play);
    _game = NeilTheSealGame(sounds: KidSounds(context.read<AudioController>()));
  }

  void _down(PointerDownEvent event) {
    if (_game.isOnNeil(event.localPosition)) {
      _rubbing = event.pointer;
      _game.rub();
      return;
    }
    _game.tapAtScreen(event.localPosition);
  }

  void _move(PointerMoveEvent event) {
    // Only a finger that STARTED on him rubs. A finger that set off across the
    // screen and happened to pass over him is on its way somewhere, and turning
    // that into a rub would make the town feel sticky.
    if (_rubbing != event.pointer) return;
    if (!_game.isOnNeil(event.localPosition)) return;
    _game.rub();
  }

  void _release(int pointer) {
    if (_rubbing == pointer) _rubbing = null;
  }

  @override
  Widget build(BuildContext context) {
    final sounds = KidSounds(context.read<AudioController>());

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: GameWidget(game: _game)),

          // The town. A raw Listener rather than a GestureDetector: there is
          // no gesture to recognise here (no tap threshold, no drag arena to
          // win) — he leaves the instant the finger lands. A tap gesture would
          // wait for the finger to lift before deciding, and at five that reads
          // as the game hesitating.
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: _down,
              onPointerMove: _move,
              onPointerUp: (event) => _release(event.pointer),
              onPointerCancel: (event) => _release(event.pointer),
            ),
          ),

          // Bottom-right, on top of the town so pressing it never also sends
          // him somewhere. The opposite corner from Car Trip's horn.
          Positioned(
            right: 20,
            bottom: 20,
            child: BellowButton(onPressed: _game.bellow),
          ),

          // Top-right, the same corner in every game.
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
