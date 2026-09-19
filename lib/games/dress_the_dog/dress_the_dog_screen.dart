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

  /// The size the dog is painted at, before being scaled to fit its box.
  static double get _dogArtWidth => Dog.artSize.width;
  static double get _dogArtHeight => Dog.artSize.height;

  /// The screen height the full-size controls were designed against. Below
  /// this they shrink; above it they stay put rather than growing into a
  /// tablet-sized wardrobe.
  static const _designHeight = 560.0;
  static const _designWidth = 960.0;

  /// How far past the dog's own outline a drop still counts. A five-year-old
  /// aims at the animal, not at its collar.
  static const _dogDropMargin = 40.0;

  /// Where the backdrop's ground band starts, measured up from the bottom of
  /// the screen (see WeatherBackdrop). The dog stands a little INTO the band,
  /// so its feet meet the ground rather than floating above it.
  static const _groundLine = 74.0;

  /// The width the dog keeps whatever else is on screen. The dog is what the
  /// game is about; the controls wrap around it rather than squeezing it out.
  static const _dogKeepsWidth = 200.0;

  /// Floors, so the arithmetic above can never collapse to zero (and scale the
  /// dog by 0/0) on a very narrow screen.
  static const _minDogWidth = 80.0;
  static const _minDogHeight = 80.0;


  static const _railMargin = 12.0;
  static const _weatherMargin = 16.0;

  /// One scale for every control on the screen.
  ///
  /// Never above 1: on a big tablet the controls stay the size they were
  /// designed at rather than becoming comically large. The floor is 0.7 —
  /// below that the per-widget 84px minimums take over and stop anything
  /// shrinking past a hittable target (CLAUDE.md §3).
  static double _controlScale(double width, double height) {
    final byHeight = height / _designHeight;
    final byWidth = width / _designWidth;
    final fit = byHeight < byWidth ? byHeight : byWidth;
    return fit.clamp(0.7, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // LayoutBuilder, not fixed pixel offsets: a phone in landscape is only
      // ~400dp tall, where the full-size rail (4 x 120 tiles) does not fit and
      // used to overflow off the bottom. Everything below is sized from the
      // real box, so the same layout holds on a small phone and a tablet.
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final padding = MediaQuery.paddingOf(context);

          // The space actually available once the notch/gesture insets are
          // out of the way — controls are placed inside this, never under it.
          final safeW = size.width - padding.left - padding.right;
          final safeH = size.height - padding.top - padding.bottom;

          // One scale for every control, so the rail, the weather buttons and
          // the dog shrink together and the layout keeps its proportions
          // instead of rearranging under the child's hands (CLAUDE.md §3).
          final scale = _controlScale(safeW, safeH);

          // The rail gets the full height of the screen. It is kept out from
          // under the home button by WIDTH instead (see `railRight` below) —
          // reserving a home-button-tall strip above it costs height that the
          // shortest landscape phones do not have, and height is what the rail
          // needs to keep its targets hittable.
          final railTop = padding.top + _railMargin;

          // The rail stops above the weather buttons where they would meet, so
          // a reach for a coat can never land on the weather instead
          // (CLAUDE.md §3). `railH` is derived from this same bound, so the
          // rail's own choice of shape always matches the space it is given.
          final railRightEdge = padding.right + HomeButton.size + _railMargin * 2;

          // The rail always gets the FULL height. Shortening it to dodge the
          // weather row is a false economy: less height pushes the rail into
          // its wide tabs-across-the-top shape, which then crowds the dog far
          // worse than the weather row ever did. The weather row keeps clear
          // of the rail by WIDTH instead (see `weatherW` below).
          final railBottom = padding.bottom + _railMargin;
          final railH = size.height - railTop - railBottom;

          // On a short screen the items wrap into more columns rather than
          // shrinking past a hittable size (CLAUDE.md §3) or scrolling. The
          // rail works this out again from the box it is actually given; the
          // copy here is only so the dog can be kept clear of it.
          final columns = WardrobeRail.columnsFor(
            scale,
            WardrobeRail.tilesHeightFor(scale, railH),
            WardrobeRail.maxItemsInASlot,
          );

          // On a short screen the slot tabs move from the side of the rail to
          // a row across its top, where there is width to spare — so they
          // never shrink below a hittable size (CLAUDE.md §3).
          final tabsOnTop = WardrobeRail.tabsOnTopFor(scale, railH);
          final railW = WardrobeRail.widthFor(scale, columns, tabsOnTop);

          // The weather row shares the bottom of the screen with the rail, so
          // it gets only the width the rail leaves. Its own scale, because the
          // three buttons must fit that width without ever shrinking below the
          // 80x80 rule — WeatherSwitch clamps that floor itself.
          // The weather buttons share the bottom of the screen with the dog,
          // so they get the width the rail leaves, less the share the dog
          // keeps. The dog is the point of the game — it is the last thing to
          // give up space, not the first. Where three across will not fit,
          // they WRAP into a block; they never shrink, because the 80x80 rule
          // does not bend (CLAUDE.md §3).
          final weatherRoom =
              size.width - railW - railRightEdge - _weatherMargin * 2;
          final weatherColumns = WeatherSwitch.columnsFor(
            scale,
            weatherRoom - _dogKeepsWidth,
            // Three across whenever the row alone fits the space beside the
            // rail — the dog's reserved share only decides the wrap when the
            // screen is genuinely too narrow for both.
            roomForFullRow: weatherRoom,
          );
          final weatherH = WeatherSwitch.heightFor(scale, weatherColumns);
          final weatherW = WeatherSwitch.widthFor(scale, weatherColumns);

          // A wrapped block sits in the corner rather than lying along the
          // bottom, so the dog stands BESIDE it and keeps its feet on the
          // ground instead of being pushed up into the air by its extra rows.
          final weatherWraps = weatherColumns < Weather.values.length;
          final dogLeft = weatherWraps
              ? padding.left + _weatherMargin * 2 + weatherW
              : padding.left + _weatherMargin;

          // What is left between the weather buttons and the rail. On the
          // narrowest screens this can come out tiny or negative, so it has a
          // floor: the dog is drawn small rather than not at all.
          final dogW = (size.width - dogLeft - railW - railRightEdge)
              .clamp(_minDogWidth, size.width);

          // Where the dog's feet land: on the ground band where the weather
          // block is beside it, and just above the weather strip where the two
          // share the bottom of the screen. Either way the dog's idle bounce
          // can never swing over a button — a dog a child cannot tell from a
          // control is worse than a dog standing a little higher.
          final dogFeet = weatherWraps
              ? padding.bottom + _groundLine
              : padding.bottom + weatherH + _weatherMargin * 2;
          final dogH = (size.height - dogFeet - padding.top)
              .clamp(_minDogHeight, size.height);

          // The dog is drawn as large as that space allows, keeping its shape
          // and fitted to BOTH axes, so it can never spill out sideways on a
          // narrow screen or downwards on a short one.
          final artBoxW = (dogW - _dogDropMargin * 2).clamp(0.0, dogW);
          final artBoxH = (dogH - _dogDropMargin).clamp(0.0, dogH);
          final artFit = (artBoxW / _dogArtWidth) < (artBoxH / _dogArtHeight)
              ? artBoxW / _dogArtWidth
              : artBoxH / _dogArtHeight;
          final dogArt = Size(_dogArtWidth * artFit, _dogArtHeight * artFit);

          // The drop target is the dog's drawn area plus a generous margin,
          // capped by the dog's own box so it can never reach down over the
          // weather buttons below it.
          final dogBox = Size(
            (dogArt.width + _dogDropMargin * 2).clamp(0.0, dogW),
            (dogArt.height + _dogDropMargin).clamp(0.0, dogH),
          );

          return Stack(
            children: [
              Positioned.fill(
                child: WeatherBackdrop(weather: _weather, t: _t),
              ),
              // The dog, centre stage in the space the controls leave and as
              // big as that space allows. Its box ENDS at its feet and it is
              // bottom-aligned inside, so it stands on the ground band at any
              // screen height instead of hanging from the top.
              Positioned(
                left: dogLeft,
                bottom: dogFeet,
                width: dogW,
                height: dogH,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: DragTarget<WardrobeItem>(
                    onWillAcceptWithDetails: (_) {
                      setState(() => _overDog = true);
                      return true;
                    },
                    onLeave: (_) => setState(() => _overDog = false),
                    onAcceptWithDetails: (details) => _dropItem(details.data),
                    builder: (context, candidate, rejected) {
                      // The target is the dog's drawn area plus a generous
                      // margin — MUCH larger than its outline, because a
                      // five-year-old aims at "the dog", not at its collar.
                      // Being generous here is what stops a drop feeling like
                      // a miss. It is NOT the whole left of the screen: a drop
                      // up in the empty sky should still be a miss that quietly
                      // does nothing, rather than the dog reaching across the
                      // room for it.
                      return SizedBox(
                        width: dogBox.width,
                        height: dogBox.height,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: AnimatedScale(
                            // The dog leans in a little when something is over
                            // it: an invitation, not an instruction.
                            scale: _overDog ? 1.06 : 1.0,
                            duration: const Duration(milliseconds: 160),
                            alignment: Alignment.bottomCenter,
                            // The dog paints at its own fixed size, so it is
                            // SCALED to the space available rather than sized
                            // by it — `scale`, not a box, because the dog's
                            // idle motion moves it outside its own bounds and
                            // a box would clip the bounce.
                            child: Transform.scale(
                              scale: artFit,
                              alignment: Alignment.bottomCenter,
                              child: Dog(
                                outfit: _outfit,
                                feeling: _feeling,
                                t: _t,
                                reaching: _dragging,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Wardrobe down the right, vertically centred in the space below
              // the home button so the two can never overlap.
              Positioned(
                right: railRightEdge,
                top: railTop,
                // The same bound the sizing above assumed, so the rail's own
                // choice of shape cannot disagree with the space reserved for
                // it — that mismatch is what used to let it cover the dog.
                // `top` and `bottom` together bound the height, which is what
                // lets the rail reshape itself to fit rather than overflow.
                bottom: railBottom,
                child: WardrobeRail(
                  slot: _slot,
                  outfit: _outfit,
                  scale: scale,
                  onSlotChanged: (slot) {
                    setState(() => _slot = slot);
                    _sounds.tap();
                  },
                  onItemTapped: _tapItem,
                  onDragStarted: () => setState(() => _dragging = true),
                  onDragEnded: _dragEnded,
                ),
              ),
              // Weather along the bottom left, away from the wardrobe so a
              // reach for one cannot catch the other.
              Positioned(
                left: padding.left + _weatherMargin,
                bottom: padding.bottom + _weatherMargin,
                child: WeatherSwitch(
                  weather: _weather,
                  scale: scale,
                  columns: weatherColumns,
                  onChanged: _tapWeather,
                ),
              ),
              // The same corner as every other game.
              Positioned(
                top: padding.top + 20,
                right: padding.right + 20,
                child: HomeButton(onPressed: _sounds.tap),
              ),
            ],
          );
        },
      ),
    );
  }
}
