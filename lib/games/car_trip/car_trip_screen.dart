import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../audio/audio_controller.dart';
import '../../audio/songs.dart';
import '../../shared/home_button.dart';
import '../../shared/kid_palette.dart';
import '../../shared/kid_sounds.dart';
import 'car_trip_game.dart';
import 'components/horn_button.dart';

/// Hosts [CarTripGame], the steering area, the horn and the home button.
///
/// The controls are Flutter widgets on top of the game rather than Flame
/// components, for the same reason Cat Run's are: hit testing is easier to
/// reason about, and the home button has to be identical in every game.
///
/// ## The steering area is the bottom half of the screen
///
/// There is no wheel and there are no buttons. A thumb anywhere in the bottom
/// half moves the car to that point across the road — the biggest possible
/// target, nothing to discover, and the pre-writing motion the scope exists to
/// practise. The car sits *above* the band ([CarTripGame.view]'s `carFraction`
/// is 0.82 but the hand rests lower), so the hand never covers the road ahead.
///
/// The horn sits on top of the band in the bottom-left corner, so a press on it
/// never also swerves the car, and the home button is in its usual top-right
/// corner, as far from the steering hand as the screen allows.
class CarTripScreen extends StatefulWidget {
  const CarTripScreen({super.key});

  /// How much of the screen, from the bottom, steers the car.
  static const double steeringFraction = 0.55;

  /// The steering area itself. Keyed because it is invisible: a test cannot
  /// find "the bottom half of the screen" any other way, and the layout test
  /// is what stops it creeping under the home button.
  static const steeringKey = Key('car trip steering');

  @override
  State<CarTripScreen> createState() => _CarTripScreenState();
}

class _CarTripScreenState extends State<CarTripScreen> {
  late final CarTripGame _game;

  /// The game, for the test that drives a thumb through the real widget tree.
  @visibleForTesting
  CarTripGame get gameForTest => _game;

  /// The pointer currently steering. A second finger takes over rather than
  /// fighting: a child re-grips with the other hand constantly, and the car
  /// should follow whichever thumb arrived last.
  int? _steering;

  /// Whether anything has ever touched the steering area. Drives the hand hint.
  bool _everTouched = false;

  @override
  void initState() {
    super.initState();
    context.read<AudioController>().playSong(Songs.play);
    _game = CarTripGame(sounds: KidSounds(context.read<AudioController>()));
  }

  void _steer(Offset position) => _game.steerToScreenX(position.dx);

  @override
  Widget build(BuildContext context) {
    final sounds = KidSounds(context.read<AudioController>());
    final screen = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: GameWidget(game: _game)),

          // The steering area. A raw Listener rather than a GestureDetector:
          // there is no gesture to recognise here (no tap, no drag threshold,
          // no arena to win) — the car simply goes where the finger is, from
          // the instant it lands. A pan gesture would swallow the first few
          // millimetres while it decided, which at five reads as the car
          // ignoring you.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: screen.height * CarTripScreen.steeringFraction,
            child: Listener(
              key: CarTripScreen.steeringKey,
              behavior: HitTestBehavior.opaque,
              onPointerDown: (event) {
                if (!_everTouched) setState(() => _everTouched = true);
                _steering = event.pointer;
                _steer(event.position);
              },
              onPointerMove: (event) {
                if (_steering != event.pointer) _steering = event.pointer;
                _steer(event.position);
              },
              onPointerUp: (event) {
                if (_steering == event.pointer) {
                  _steering = null;
                  _game.thumbUp();
                }
              },
              onPointerCancel: (event) {
                if (_steering == event.pointer) {
                  _steering = null;
                  _game.thumbUp();
                }
              },
              child: _everTouched
                  ? const SizedBox.expand()
                  : const _SteeringHint(),
            ),
          ),

          // The horn: bottom-left, on top of the steering area so pressing it
          // does not also swerve the car.
          Positioned(
            left: 20,
            bottom: 20,
            child: HornButton(onPressed: _game.horn),
          ),

          // Top-right, the same corner in every game, and the opposite end of
          // the screen from the steering hand.
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

/// A hand, pulsing near the bottom of the screen, until the child touches it
/// once.
///
/// This game is the only one in the app whose control cannot be seen — there is
/// no button to press, so there is nothing to point at. The player cannot read
/// an instruction (CLAUDE.md §3), so the instruction is a picture of the thing
/// they should do, and it goes away the moment they do it.
class _SteeringHint extends StatefulWidget {
  const _SteeringHint();

  @override
  State<_SteeringHint> createState() => _SteeringHintState();
}

class _SteeringHintState extends State<_SteeringHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, 0.55),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.35, end: 0.85).animate(_pulse),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.06).animate(_pulse),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.touch_app_rounded,
                size: 52,
                color: KidPalette.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
