import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../audio/audio_controller.dart';
import '../../audio/songs.dart';
import '../../shared/home_button.dart';
import '../../shared/kid_sounds.dart';
import 'crystal_party_game.dart';

/// Hosts [CrystalPartyGame] and the shared home button.
///
/// ## The whole screen is the button
///
/// This is the largest touch target in the app — there is nothing to aim at and
/// nothing to miss (CLAUDE.md §3: targets ≥80×80, generously spaced; here the
/// target is the screen). A hold anywhere raises her, a release anywhere brings
/// her down. A child does not have to find anything.
///
/// ## Except the top band, which is the home button's
///
/// The one exception, and it is deliberate. The home button lives in the usual
/// top-right corner, and [CrystalPartyScreen.topBandHeight] of the screen is
/// excluded from the hold so a thumb reaching for home never accidentally flies
/// her instead. The scope asks for exactly this: the home button is *well away
/// from where a holding thumb rests*, and a five-year-old holds low.
///
/// The band is transparent and unmarked — there is nothing there to see, and
/// a child pressing in it simply gets nothing, which is what it means to be
/// out of the play area.
class CrystalPartyScreen extends StatefulWidget {
  const CrystalPartyScreen({super.key});

  /// How much of the top of the screen belongs to the home button rather than
  /// to the play area. Tall enough to clear the button ([HomeButton.size]) plus
  /// its margin, and no taller — every pixel below this is the control.
  ///
  /// Public because the layout test asserts the home button sits entirely
  /// inside it: if the play area ever grows up into this band, a thumb
  /// reaching for home starts flying her instead.
  static const double topBandHeight = 132;

  @override
  State<CrystalPartyScreen> createState() => _CrystalPartyScreenState();
}

class _CrystalPartyScreenState extends State<CrystalPartyScreen> {
  late final CrystalPartyGame _game;

  /// The game, for the test that drives a hold through the real widget tree.
  @visibleForTesting
  CrystalPartyGame get gameForTest => _game;

  @override
  void initState() {
    super.initState();
    context.read<AudioController>().playSong(Songs.play);
    _game = CrystalPartyGame(sounds: KidSounds(context.read<AudioController>()));
  }

  @override
  Widget build(BuildContext context) {
    final sounds = KidSounds(context.read<AudioController>());

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: GameWidget(game: _game)),

          // The play area: everything below the top band. One gesture
          // detector, no buttons, nothing to find.
          Positioned(
            left: 0,
            right: 0,
            top: CrystalPartyScreen.topBandHeight,
            bottom: 0,
            child: GestureDetector(
              // Opaque so the whole area is hit-tested even though it is
              // transparent — that is the entire point of this widget.
              behavior: HitTestBehavior.opaque,
              // onTapDown/onTapUp alone would not do: a tap gesture does not
              // fire until the press RESOLVES, so a long hold would not lift
              // her until the child let go. The raw pointer callbacks are what
              // make "hold and she rises" actually respond on the way down.
              onPanDown: (_) => _game.hold(),
              onPanEnd: (_) => _game.release(),
              onPanCancel: _game.release,
              onTapDown: (_) => _game.hold(),
              onTapUp: (_) => _game.release(),
              onTapCancel: _game.release,
            ),
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
