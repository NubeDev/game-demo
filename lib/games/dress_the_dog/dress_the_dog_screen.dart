import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../../audio/audio_controller.dart';
import '../../audio/songs.dart';
import '../../shared/home_button.dart';
import '../../shared/kid_haptics.dart';
import '../../shared/kid_sounds.dart';
import 'components/dog.dart';
import 'components/wardrobe_rail.dart';
import 'components/weather_backdrop.dart';
import 'components/weather_switch.dart';
import 'wardrobe.dart';

/// Dress the Dog — a toy, not a round.
///
/// There is no goal, so there is nothing to fail: the child dresses the dog,
/// picks the weather, and the dog reacts. See
/// `docs/scope/games/dress-the-dog-scope.md` and this folder's README.
///
/// Built as Flutter widgets rather than a `FlameGame` (unlike Balloon Pop)
/// because nothing here moves on its own or needs collision — it is a dressing
/// table: tap a picture, a picture changes. A Flame game would add a loop and a
/// component tree for no gain. The dog's idle motion comes from one ticker.
class DressTheDogScreen extends StatefulWidget {
  const DressTheDogScreen({super.key});

  @override
  State<DressTheDogScreen> createState() => _DressTheDogScreenState();
}

class _DressTheDogScreenState extends State<DressTheDogScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  double _t = 0;

  Outfit _outfit = const Outfit();
  Weather _weather = Weather.sun;
  Slot _slot = Slot.head;

  /// The feeling last announced with a sound, so a reaction fires when the
  /// dog's feeling *changes* rather than on every rebuild.
  DogFeeling _lastAnnounced = DogFeeling.fine;

  /// True while an item is being dragged, so the dog can show it is ready to
  /// catch it. Purely an invitation — nothing depends on the child noticing.
  bool _dragging = false;

  /// True while a dragged item is over the dog.
  bool _overDog = false;

  DogFeeling get _feeling => _outfit.feelingIn(_weather);

  @override
  void initState() {
    super.initState();
    _ticker.start();
    context.read<AudioController>().playSong(Songs.play);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    setState(() => _t = elapsed.inMilliseconds / 1000);
  }

  KidSounds get _sounds => KidSounds(context.read<AudioController>());

  /// Reacts to the outfit having changed.
  ///
  /// Note what is NOT here: nothing blocks a change, nothing scolds, nothing
  /// counts. A mismatch gets the soft `wobble` cue — the same gentle "hmm" used
  /// everywhere else — and the dog's comedy carries the rest. Only the
  /// just-right moment gets a celebration, so being right is a bigger reward
  /// rather than being wrong a punishment (CLAUDE.md §3).
  void _announce(DogFeeling feeling) {
    if (feeling == _lastAnnounced) return;
    _lastAnnounced = feeling;

    if (feeling == DogFeeling.justRight) {
      _sounds.celebrate();
      KidHaptics.celebrate();
    } else if (feeling == DogFeeling.fine) {
      _sounds.pop();
      KidHaptics.pop();
    } else {
      // Too cold / too hot / too wet: soft, never a buzzer, and never a
      // haptic — a physical jolt after a "wrong" choice is punishment.
      _sounds.wobble();
    }
  }

  void _tapItem(WardrobeItem item) {
    setState(() {
      // Tapping what is already worn takes it off, so undo needs no extra
      // control a child would have to find.
      _outfit = _outfit[item.slot]?.id == item.id
          ? _outfit.without(item.slot)
          : _outfit.wearing(item);
    });
    _sounds.tap();
    _announce(_feeling);
  }

  /// An item was dropped ON the dog. Identical to tapping it, deliberately:
  /// the two input paths must not diverge in behaviour or feel.
  void _dropItem(WardrobeItem item) {
    setState(() {
      _outfit = _outfit.wearing(item);
      _dragging = false;
      _overDog = false;
    });
    _sounds.pop();
    KidHaptics.pop();
    _announce(_feeling);
  }

  /// A drag that ended anywhere else.
  ///
  /// **Nothing happens, and nothing says it failed** — no sound, no wobble, no
  /// item flying back with a thud. A missed drop is the one way this game could
  /// make a child feel they got something wrong, so it is silent and the item
  /// is simply still in the rail, ready to be tapped instead (CLAUDE.md §3).
  void _dragEnded() {
    if (!mounted) return;
    setState(() {
      _dragging = false;
      _overDog = false;
    });
  }

  void _tapWeather(Weather weather) {
    setState(() => _weather = weather);
    _sounds.tap();
    KidHaptics.tap();
    _announce(_feeling);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: WeatherBackdrop(weather: _weather, t: _t),
          ),
          // The dog, centre stage and big. Positioned from the BOTTOM so its
          // feet meet the ground band — anchored by a fraction of the screen
          // it floats above the ground on a short screen.
          Positioned(
            left: 0,
            right: 300, // clear of the wardrobe rail
            bottom: 74, // stands in the ground band, not on top of it
            child: Center(
              child: DragTarget<WardrobeItem>(
                onWillAcceptWithDetails: (_) {
                  setState(() => _overDog = true);
                  return true;
                },
                onLeave: (_) => setState(() => _overDog = false),
                onAcceptWithDetails: (details) => _dropItem(details.data),
                builder: (context, candidate, rejected) {
                  // The target is MUCH larger than the dog's outline — a
                  // five-year-old aims at "the dog", not at its collar. Being
                  // generous here is what stops a drop ever feeling like a miss.
                  return SizedBox(
                    width: 420,
                    height: 400,
                    child: Center(
                      child: AnimatedScale(
                        // The dog leans in a little when something is over it:
                        // an invitation, not an instruction.
                        scale: _overDog ? 1.30 : 1.22,
                        duration: const Duration(milliseconds: 160),
                        alignment: Alignment.bottomCenter,
                        child: Dog(
                          outfit: _outfit,
                          feeling: _feeling,
                          t: _t,
                          reaching: _dragging,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Wardrobe down the right.
          Align(
            alignment: const Alignment(0.94, 0.28),
            child: SafeArea(
              child: WardrobeRail(
                slot: _slot,
                outfit: _outfit,
                onSlotChanged: (slot) {
                  setState(() => _slot = slot);
                  _sounds.tap();
                },
                onItemTapped: _tapItem,
                onDragStarted: () => setState(() => _dragging = true),
                onDragEnded: _dragEnded,
              ),
            ),
          ),
          // Weather along the bottom left, away from the wardrobe so a reach
          // for one cannot catch the other.
          Align(
            alignment: const Alignment(-0.7, 0.94),
            child: SafeArea(
              child: WeatherSwitch(weather: _weather, onChanged: _tapWeather),
            ),
          ),
          // The same corner as every other game.
          Positioned(
            top: 20,
            right: 20,
            child: SafeArea(child: HomeButton(onPressed: _sounds.tap)),
          ),
        ],
      ),
    );
  }
}
