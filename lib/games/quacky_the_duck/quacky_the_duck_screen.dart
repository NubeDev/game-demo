import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../audio/audio_controller.dart';
import '../../audio/songs.dart';
import '../../shared/home_button.dart';
import '../../shared/kid_sounds.dart';
import 'components/play_buttons.dart';
import 'quacky_the_duck_game.dart';

/// Hosts [QuackyTheDuckGame], the two play buttons and the shared home button.
///
/// The buttons are Flutter widgets on top of the game rather than Flame
/// components, for the same reason the home button is: they have to be
/// identical, big and placed the same way every time, and a widget's hit
/// testing is easier to reason about than a component's.
///
/// ## The hit areas are much bigger than the buttons
///
/// Each button is [QuackyButton.buttonSize] (140) drawn, but sits inside an
/// invisible box covering its whole bottom quarter of the screen. A
/// five-year-old mid-chase does not look at their thumb, so **anywhere in the
/// bottom-left ducks and anywhere in the bottom-right dashes** — the scope asks
/// for exactly this, and it is the difference between a game that answers and a
/// game that seems to ignore them (CLAUDE.md §3).
///
/// The home button is top-right, far from both, so it cannot be hit mid-dash.
class QuackyTheDuckScreen extends StatefulWidget {
  const QuackyTheDuckScreen({super.key});

  @override
  State<QuackyTheDuckScreen> createState() => _QuackyTheDuckScreenState();
}

class _QuackyTheDuckScreenState extends State<QuackyTheDuckScreen> {
  late final QuackyTheDuckGame _game;

  /// The game, for the test that drives a press through the real widget tree.
  @visibleForTesting
  QuackyTheDuckGame get gameForTest => _game;

  @override
  void initState() {
    super.initState();
    context.read<AudioController>().playSong(Songs.play);
    _game = QuackyTheDuckGame(
      sounds: KidSounds(context.read<AudioController>()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sounds = KidSounds(context.read<AudioController>());

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: GameWidget(game: _game)),

          // The two hit areas, each half the screen wide and half tall, in the
          // bottom corners. Transparent — the visible button inside says where
          // the middle of it is.
          _HitArea(
            alignment: Alignment.bottomLeft,
            onPressed: _game.pressDuck,
            onReleased: _game.releaseDuck,
            kind: QuackyButtonKind.flat,
          ),
          _HitArea(
            alignment: Alignment.bottomRight,
            onPressed: _game.pressDash,
            kind: QuackyButtonKind.dash,
          ),

          // Top-right, the same corner in every game, and deliberately the
          // opposite end of the screen from both play buttons.
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

/// One bottom quarter of the screen, with its picture button drawn in it.
class _HitArea extends StatelessWidget {
  const _HitArea({
    required this.alignment,
    required this.onPressed,
    required this.kind,
    this.onReleased,
  });

  final Alignment alignment;
  final VoidCallback onPressed;
  final VoidCallback? onReleased;
  final QuackyButtonKind kind;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final isLeft = alignment == Alignment.bottomLeft;

    return Positioned(
      left: isLeft ? 0 : null,
      right: isLeft ? null : 0,
      bottom: 0,
      width: screen.width * QuackyButton.hitAreaFraction,
      height: screen.height * QuackyButton.hitAreaFraction,
      child: GestureDetector(
        // Opaque so the whole quarter is hit-tested, even where it is
        // transparent — that is the entire point of this widget.
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => onPressed(),
        onTapUp: (_) => onReleased?.call(),
        onTapCancel: () => onReleased?.call(),
        child: Align(
          alignment: alignment,
          child: Padding(
            // Clear of the very corner, so a hand resting on the bezel does not
            // sit on the button, but well within the quarter.
            padding: const EdgeInsets.all(22),
            child: IgnorePointer(
              // The quarter above handles the press; this is the picture.
              // Without this, the small button would swallow the press and the
              // generous area would only work outside it.
              child: QuackyButton(
                kind: kind,
                onPressed: onPressed,
                onReleased: onReleased,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
