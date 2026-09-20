import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../shared/celebration.dart';
import '../../shared/kid_haptics.dart';
import '../../shared/kid_sounds.dart';
import 'components/neil_painter.dart';
import 'components/progress_shells.dart';
import 'components/town_backdrop.dart';
import 'components/town_layer.dart';
import 'town.dart';
import 'world.dart';

/// Neil the Seal.
///
/// Neil is an enormous, extremely relaxed elephant seal in a small seaside
/// town. The child taps somewhere; he galumphs there and flops down; whatever
/// he lands on squashes, boings, and springs straight back the moment he moves
/// off. That is the entire game.
///
/// ## The verb is new, and that is the point
///
/// Balloon Pop is *where to tap*. Dress the Dog is *which to pick*. Cat Run is
/// *when to press*. Blast Off is *how long to wait*. Car Trip is *holding a
/// line*. This one is **choose a place, then watch what a big soft heavy thing
/// does when it gets there** — the child picks the destination, and the comedy
/// is the journey and the landing.
///
/// ## What this game is at risk of getting wrong, and how it doesn't
///
///  * **The whole game is sitting on things that belong to other people.**
///    Resolved entirely by springiness: every squash is elastic, loud, funny
///    and completely undone the moment he moves ([NeilWorld.springSettle]).
///    Nothing in the art suggests damage — no cracks, no shattered glass, no
///    wonky wheel — so the read is "that car is a bouncy castle", not "that car
///    is wrecked".
///  * **Nobody may ever be annoyed with Neil.** This is the rule the game will
///    be tempted to break, because "cross neighbour" is where the comedy
///    usually lives. There is no car alarm, no siren, no shouting and no angry
///    anybody in this file or in `sounds.dart`. At five, an adult being cross
///    about something you just did is the thing that stops play.
///  * **A mis-read tap reads as being ignored.** So there is no such thing:
///    every tap sends him somewhere, a new tap overrides the old one instantly,
///    and landing on bare ground gets the same flump, dust and settling wobble
///    as landing on a car ([_onFlop]).
///  * **Nothing alive is ever squashed.** `world.dart` moves every creature
///    clear from a fifth of the town away, faster than he can heave. The child
///    never even gets to aim at one.
///  * **He is the slowest thing in the app on purpose**, which is a real risk
///    with a five-year-old's patience. The redirect is always available so
///    nobody is ever stuck watching, and the crossing time is pinned by a test
///    so that changing it is deliberate. Only a child settles where funny-slow
///    turns into boring-slow.
class NeilTheSealGame extends FlameGame {
  NeilTheSealGame({required this.sounds, Random? random})
      : _world = NeilWorld(random: random);

  final KidSounds sounds;
  final NeilWorld _world;

  // NOT `late final`: these are built in the async onLoad(), and the whole
  // screen is a control from the moment it paints. A finger that arrives in
  // that gap would hit a LateInitializationError, which in a release build is
  // swallowed inside the gesture callback — so the game would look broken and
  // silently do nothing. (The same trap Cat Run and Car Trip document.)
  TownBackdrop? _backdrop;
  TownLayer? _layer;
  ProgressShells? _shells;
  Celebration? _celebration;

  /// Alternates the flump variants, so a child tapping thirty times does not
  /// hear one identical sample thirty times.
  int _flumps = 0;

  @override
  Color backgroundColor() => TownPlace.values.first.sky;

  /// The projection this screen is using. The game's rules never need it —
  /// every one of them is in town units — but a finger arrives in pixels.
  TownView get view => TownView(width: size.x, height: size.y);

  /// The simulation. NOT named `world`: FlameGame has its own `world` (the
  /// component tree's root), and shadowing it compiles right up until something
  /// inside Flame reaches for the real one. Car Trip hit exactly this and its
  /// spawner is named around it too.
  NeilWorld get town => _world;

  @override
  Future<void> onLoad() async {
    final backdrop = TownBackdrop(place: _world.place);
    _backdrop = backdrop;
    add(backdrop);

    final layer = TownLayer(world: _world);
    _layer = layer;
    add(layer);

    final shells = ProgressShells(
      // Top-left: clear of the home button (top-right), clear of the bellow
      // button (bottom-right), and out of the way of a hand tapping the town.
      position: Vector2(24, 24),
    );
    _shells = shells;
    add(shells);

    final celebration = Celebration();
    _celebration = celebration;
    add(celebration);

    _wire();
  }

  /// Everything the child hears. The world decides *what* happened; this is the
  /// only place that decides what it sounds like.
  void _wire() {
    _world
      ..onFlop = _onFlop
      ..onSquash = _onSquash
      ..onSpringBack = _onSpringBack
      ..onRubDelight = _onRubDelight
      ..onAnswer = _onAnswer
      ..onSnore = sounds.snore
      ..onCelebrate = _onCelebrate
      ..onWakeElsewhere = (place) => _backdrop?.changeTo(place);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _world.update(dt);
    // The row simply mirrors the count. It is never driven by an event, so it
    // cannot drift out of step with what the child is looking at.
    _shells?.filled = _world.dotsFilled;
  }

  /// He landed. There is always a flump, whatever he landed on — including
  /// nothing at all.
  void _onFlop(Prop? onto) {
    sounds.flump(variant: _flumps++);
    KidHaptics.pop();

    switch (onto?.kind.reaction) {
      case FlopReaction.sink:
      case FlopReaction.squashFlat:
        // The signature: a car down on its springs, a cone flat as a pancake.
        sounds.boing();
      case FlopReaction.planks:
      case FlopReaction.bounce:
      case FlopReaction.rock:
        // Quicker and higher — doing-oing rather than a long sag.
        sounds.boing(springingBack: true);
      case FlopReaction.squelch:
      case FlopReaction.spray:
        // TODO(audio): the hose wants a hiss of its own; the squelch stands in
        // for it. One more entry in `tools/make_sfx.py` when it exists.
        sounds.squelch();
      case FlopReaction.tipOver:
        // The bin goes over and the seagulls go up, which is their own voice
        // rather than a new sound.
        sounds.answer(1);
      case FlopReaction.dent:
      case null:
        // Dry sand, or bare ground. The flump above is the whole answer, and it
        // is deliberately just as satisfying as any other — there is no dead
        // tap in this game.
        break;
    }
  }

  /// Something got sat on for the first time: a shell fills and the chime goes
  /// up a rung.
  void _onSquash(Prop prop, bool isNew) {
    if (!isNew) return;
    // The rising ladder — the same one as Balloon Pop's pops and Car Trip's
    // passengers. It only ever climbs, so the sound itself says "nearly there"
    // to a child who has never noticed the shells.
    sounds.pop(progress: _world.dotsFilled / NeilWorld.dotsPerNap);
  }

  /// He moved off something. It springs back, and that is the sound that says
  /// nothing is broken.
  void _onSpringBack(Prop prop) {
    if (prop.releasedFrom < 0.25) return;
    sounds.boing(springingBack: true);
  }

  void _onRubDelight() {
    sounds.wriggle(variant: _flumps++);
    KidHaptics.tap();
  }

  void _onAnswer(Prop prop) {
    final voice = prop.kind.answerVoice;
    // A shack has no voice: its curtain twitches and it says nothing, which is
    // a good beat in the middle of the round.
    if (voice != null) sounds.answer(voice);
  }

  void _onCelebrate() {
    sounds.celebrate();
    KidHaptics.celebrate();
    _celebration?.burst(size);
  }

  // --- the controls --------------------------------------------------------

  /// Whether a finger at [point] has landed on Neil, which means a rub rather
  /// than a destination.
  bool isOnNeil(Offset point) {
    if (size.x <= 0) return false;
    return townDistance(view.spotAt(point), _world.neil) <=
        NeilPainter.rubReach;
  }

  /// A finger landed somewhere that is not Neil. He sets off, at once.
  void tapAtScreen(Offset point) {
    if (size.x <= 0) return;
    _world.tapAt(view.spotAt(point));
  }

  /// A finger is moving over Neil.
  void rub() => _world.rub();

  /// The bellow button.
  void bellow() {
    _world.bellow();
    sounds.bellow(press: _world.bellows);
    KidHaptics.tap();
  }

  // --- for the tests -------------------------------------------------------

  /// Only valid after [onLoad]; every test that uses these awaits it.
  @visibleForTesting
  TownLayer get layer => _layer!;

  @visibleForTesting
  ProgressShells get shells => _shells!;

  @visibleForTesting
  TownBackdrop get backdrop => _backdrop!;
}
