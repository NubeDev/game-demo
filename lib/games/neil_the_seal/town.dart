/// The town, in data: what can be flopped on, where it is, and how a point in
/// the town turns into a point on the screen.
///
/// Everything here is pure — no Flame, no canvas, no screen — so the rules that
/// keep this game safe can be tested without standing up a game (the same
/// reason `car_trip/road.dart` and `cat_run/world.dart` are pure).
///
/// ## One coordinate space, and it is not pixels
///
/// A [TownSpot] is `x` across the town (0 = left edge, 1 = right edge) and `y`
/// from the back to the front (0 = the horizon, 1 = the bottom of the screen).
/// Deliberately *not* pixels: "a car is this wide", "these two things are well
/// clear of each other", "Neil crosses the town in about four seconds" have to
/// mean the same thing on a phone and on a tablet, and a rule written in pixels
/// would quietly change with the screen.
///
/// ## The whole town is one screen
///
/// Nothing scrolls. Everything worth sitting on is visible from wherever Neil
/// is, which is much kinder at five than a place to explore: a child never has
/// to discover that the game continues off-screen (the scope's open question
/// about scrolling, answered here for now).
library;

import 'dart:math';

import 'package:flutter/material.dart';

/// A step "into" the screen covers this much less ground than a step across.
///
/// The town is a wide, shallow strip rather than a square field, so a plain
/// `sqrt(dx² + dy²)` would make Neil's trips toward the sea feel enormously
/// longer than his trips along the beach. Every distance in this game —
/// arriving, reaching, snapping a tap to a prop, a wallaby getting clear — goes
/// through [townDistance] so they all agree.
const double depthToWidth = 0.55;

/// How far Neil can get in each direction. He can never leave the town: there
/// is no edge to fall off and nowhere to get stuck (CLAUDE.md §3).
///
/// The sides are set in from the screen edge by more than half his own length,
/// so **all of him stays in shot wherever he is sent**. Without that he walks
/// to the right-hand edge, half of him is cut off, and the one thing a child is
/// watching is the thing the screen clipped. Props are allowed further out than
/// this: a tap on one sends him as close as he can get, which is well inside
/// every prop's reach.
const double minX = 0.12;
const double maxX = 0.88;
const double minY = 0.16;
const double maxY = 0.90;

/// How far outside the town something alive is allowed to go.
///
/// **Creatures are not confined to Neil's town, and that is what makes
/// "nothing alive is ever squashed" a guarantee rather than a hope.** Neil is
/// boxed in by [minX]..[maxY]; a seagull he chases into the corner lifts off
/// and leaves, exactly as Car Trip's ducks wander off into the field where the
/// car cannot follow. Without this there is a corner of every location where a
/// determined child could eventually pin something against the edge.
///
/// Sized so that even with Neil jammed into his corner and a creature jammed
/// into the matching one, they are further apart than he is long.
const double creatureMargin = 0.13;

/// A place in the town. See the library doc for what the numbers mean.
@immutable
class TownSpot {
  const TownSpot(this.x, this.y);

  final double x;
  final double y;

  /// Clamped into the walkable town. Every target Neil is ever given goes
  /// through here, so a tap on the sky or off the edge still sends him
  /// somewhere real rather than nowhere.
  TownSpot get clamped =>
      TownSpot(x.clamp(minX, maxX), y.clamp(minY, maxY));

  /// Clamped into the wider area something alive may use. See
  /// [creatureMargin]: they can always go somewhere Neil cannot.
  TownSpot get clampedForCreature => TownSpot(
        x.clamp(minX - creatureMargin, maxX + creatureMargin),
        y.clamp(minY - creatureMargin, maxY + creatureMargin),
      );

  TownSpot shifted(double dx, double dy) => TownSpot(x + dx, y + dy);

  @override
  String toString() =>
      'TownSpot(${x.toStringAsFixed(3)}, ${y.toStringAsFixed(3)})';
}

/// How far apart two places in the town are, with depth counted at its true
/// visual weight. See [depthToWidth].
double townDistance(TownSpot a, TownSpot b) {
  final dx = a.x - b.x;
  final dy = (a.y - b.y) * depthToWidth;
  return sqrt(dx * dx + dy * dy);
}

/// What sort of thing this is, which is the same question as "may Neil sit on
/// it?".
enum PropNature {
  /// Furniture. Neil flops on it, it squashes, and it springs straight back the
  /// moment he moves off. **Nothing here is ever broken** — see [FlopReaction].
  floppable,

  /// Alive. Notices Neil coming and moves clear long before he arrives, and
  /// **can never be sat on** (see `world.dart`). Same rule as Car Trip's ducks:
  /// squashing something alive is funny in a game and appalling in life, and a
  /// five-year-old does not hold those apart.
  alive,

  /// Part of the town — a shack, a ute, a cow over the fence. Never moved,
  /// never sat on. It exists to answer the bellow.
  scenery,
}

/// What a thing does when two tonnes of seal lands on it.
///
/// Every one of these is **elastic**. Nothing cracks, nothing shatters, nothing
/// stays bent: the read has to be "that car is a bouncy castle", never "that
/// car is wrecked" (the scope's *Kid-rules impact*). The difference between
/// squashing and wrecking, to a five-year-old, is entirely whether it springs
/// back — so it always does.
enum FlopReaction {
  /// The car, down on its springs with a long boing. The signature move, and
  /// the real Neil's whole reputation.
  sink,

  /// The cone: flat as a pancake, then straight back up. The other half of the
  /// signature pair.
  squashFlat,

  /// The jetty planks going doing-oing.
  planks,

  /// The pile of kelp.
  squelch,

  /// The wheelie bin tips over and seagulls explode out of it.
  tipOver,

  /// The garden hose starts spraying.
  spray,

  /// The trampoline. A mistake everyone is glad he made.
  bounce,

  /// Dry sand takes a perfect Neil-shaped dent — and smooths over after.
  dent,

  /// The boat rocks on its trailer.
  rock,
}

/// One kind of thing in the town.
///
/// **A data list, not a hand-built scene** (the scope says so): a new location
/// is a new list of placements, not new code. Adding a thing is one entry here
/// plus a `case` in the painter.
///
/// ## Drawn size, reach and tap reach are three different numbers
///
/// [width]/[height] are the art. [reach] is how close Neil has to land for the
/// thing to react. [tapReach] is how close a *finger* has to be for the game to
/// decide the child meant this thing — and it is much the biggest of the three,
/// because a five-year-old aiming at a car and getting bare ground has been
/// told the game ignored them (CLAUDE.md §3).
@immutable
class PropKind {
  const PropKind({
    required this.id,
    required this.nature,
    required this.width,
    required this.height,
    required this.color,
    this.secondColor,
    this.reaction,
    this.reach = 0.08,
    this.squashTo = 0.45,
    this.answerVoice,
  });

  /// Stable name, for tests and the painter's switch. Never shown on screen —
  /// the player cannot read (CLAUDE.md §3).
  final String id;

  final PropNature nature;

  /// Drawn size in town units (1.0 = the full width of the town).
  final double width;
  final double height;

  final Color color;
  final Color? secondColor;

  /// What it does when Neil lands on it. Null for everything alive and for
  /// scenery, neither of which is ever sat on.
  final FlopReaction? reaction;

  /// How close Neil has to land for this to react.
  final double reach;

  /// How flat it goes, as a fraction of its height: 0.45 means it squashes to
  /// 45% of its resting height. A cone goes almost flat; a car barely sinks,
  /// because a car that folded in half would read as damage.
  final double squashTo;

  /// Which of the town's voices this answers the bellow with, or null if it
  /// answers silently. A shack's curtain twitches and says nothing, which is a
  /// good beat in the round.
  final int? answerVoice;

  /// How close a *tap* has to be for the game to decide the child meant this.
  ///
  /// Comfortably larger than [reach], so a tap that picked a prop always lands
  /// on it: Neil is sent to the prop's own spot, and zero is inside any reach.
  /// Pinned by a test, along with what this works out to in pixels on the
  /// smallest screen this app supports.
  double get tapReach => reach * 1.8;

  /// Whether Neil can sit on it at all.
  bool get isFloppable => nature == PropNature.floppable;

  // --- things to flop on ---------------------------------------------------

  /// The car. Half of what this game is for.
  static const car = PropKind(
    id: 'car',
    nature: PropNature.floppable,
    width: 0.20,
    height: 0.085,
    color: Color(0xFF4FC3F7),
    secondColor: Color(0xFF3A3A44),
    reaction: FlopReaction.sink,
    reach: 0.13,
    // Barely sinks. A car squashed to half its height reads as crushed; a car
    // that dips on its springs and bounces reads as a bouncy castle, which is
    // the whole difference this game rests on.
    squashTo: 0.74,
  );

  /// The traffic cone. The other half.
  static const cone = PropKind(
    id: 'cone',
    nature: PropNature.floppable,
    width: 0.05,
    height: 0.07,
    color: Color(0xFFFF8A3D),
    secondColor: Color(0xFFFFFFFF),
    reaction: FlopReaction.squashFlat,
    // Generous for something this small: a cone is the thing a child aims at
    // most, and a near miss must not read as the game ignoring them.
    reach: 0.085,
    // Nearly flat, and completely fine about it.
    squashTo: 0.12,
  );

  static const jetty = PropKind(
    id: 'jetty',
    nature: PropNature.floppable,
    width: 0.26,
    height: 0.045,
    color: Color(0xFFC49A6C),
    secondColor: Color(0xFF8D6742),
    reaction: FlopReaction.planks,
    reach: 0.15,
    squashTo: 0.55,
  );

  static const kelp = PropKind(
    id: 'kelp',
    nature: PropNature.floppable,
    width: 0.13,
    height: 0.045,
    color: Color(0xFF7A8F4A),
    secondColor: Color(0xFF5C6E33),
    reaction: FlopReaction.squelch,
    reach: 0.10,
    squashTo: 0.25,
  );

  static const bin = PropKind(
    id: 'bin',
    nature: PropNature.floppable,
    width: 0.065,
    height: 0.10,
    color: Color(0xFF6FD97F),
    secondColor: Color(0xFF4FA35C),
    reaction: FlopReaction.tipOver,
    reach: 0.09,
    squashTo: 0.30,
  );

  static const hose = PropKind(
    id: 'hose',
    nature: PropNature.floppable,
    width: 0.11,
    height: 0.028,
    color: Color(0xFF4FC3F7),
    secondColor: Color(0xFF2E8B57),
    reaction: FlopReaction.spray,
    reach: 0.095,
    squashTo: 0.40,
  );

  static const trampoline = PropKind(
    id: 'trampoline',
    nature: PropNature.floppable,
    width: 0.17,
    height: 0.055,
    color: Color(0xFFB07BE8),
    secondColor: Color(0xFF7A4FA8),
    reaction: FlopReaction.bounce,
    reach: 0.12,
    squashTo: 0.35,
  );

  static const sand = PropKind(
    id: 'sand',
    nature: PropNature.floppable,
    width: 0.16,
    height: 0.04,
    // Paler than any ground it sits on, with a rim: dry sand on a sandy beach
    // is invisible without one, and a prop a child cannot see is a prop they
    // cannot choose.
    color: Color(0xFFFCF3DA),
    secondColor: Color(0xFFC9A96E),
    reaction: FlopReaction.dent,
    reach: 0.11,
    squashTo: 0.20,
  );

  static const boat = PropKind(
    id: 'boat',
    nature: PropNature.floppable,
    width: 0.22,
    height: 0.075,
    color: Color(0xFFFF6B8A),
    secondColor: Color(0xFFF7F3EC),
    reaction: FlopReaction.rock,
    reach: 0.14,
    squashTo: 0.70,
  );

  // --- alive, and therefore never sat on -----------------------------------
  //
  // They all get clear well before Neil arrives (see `world.dart`), so the
  // child never even aims at one. The bellow is what they are really for.

  static const seagull = PropKind(
    id: 'seagull',
    nature: PropNature.alive,
    width: 0.045,
    height: 0.045,
    color: Color(0xFFFFFFFF),
    secondColor: Color(0xFFFFB03A),
    answerVoice: 1,
  );
  static const wallaby = PropKind(
    id: 'wallaby',
    nature: PropNature.alive,
    width: 0.055,
    height: 0.075,
    color: Color(0xFFB08968),
    secondColor: Color(0xFF6B4A2F),
    answerVoice: 2,
  );
  static const pademelon = PropKind(
    id: 'pademelon',
    nature: PropNature.alive,
    width: 0.045,
    height: 0.055,
    color: Color(0xFF9B7A5F),
    secondColor: Color(0xFF6B4A2F),
    answerVoice: 2,
  );
  static const wombat = PropKind(
    id: 'wombat',
    nature: PropNature.alive,
    width: 0.07,
    height: 0.04,
    color: Color(0xFF8A7360),
    secondColor: Color(0xFF5C4A3B),
    answerVoice: 2,
  );
  static const dog = PropKind(
    id: 'dog',
    nature: PropNature.alive,
    width: 0.06,
    height: 0.05,
    color: Color(0xFFD9A05B),
    secondColor: Color(0xFF6B4A2F),
    answerVoice: 0,
  );
  static const kidOnBike = PropKind(
    id: 'kid_on_bike',
    nature: PropNature.alive,
    width: 0.055,
    height: 0.08,
    color: Color(0xFFFFE156),
    secondColor: Color(0xFF4FC3F7),
    answerVoice: 1,
  );

  // --- the town, watching --------------------------------------------------

  static const ute = PropKind(
    id: 'ute',
    nature: PropNature.scenery,
    width: 0.16,
    height: 0.075,
    color: Color(0xFFE8734A),
    secondColor: Color(0xFF3A3A44),
    answerVoice: 3,
  );
  static const cow = PropKind(
    id: 'cow',
    nature: PropNature.scenery,
    width: 0.10,
    height: 0.065,
    color: Color(0xFFF7F3EC),
    secondColor: Color(0xFF4A3B33),
    answerVoice: 4,
  );

  /// A weatherboard shack. Its curtain twitches and it says nothing at all,
  /// which is a good beat in the middle of the round.
  static const shack = PropKind(
    id: 'shack',
    nature: PropNature.scenery,
    width: 0.15,
    height: 0.11,
    color: Color(0xFFEFE7DA),
    secondColor: Color(0xFF9FB8C4),
  );

  static const all = <PropKind>[
    car, cone, jetty, kelp, bin, hose, trampoline, sand, boat,
    seagull, wallaby, pademelon, wombat, dog, kidOnBike,
    ute, cow, shack,
  ];

  /// Everything Neil can sit on. Used by the tests that check the town is fair.
  static List<PropKind> get floppables =>
      all.where((k) => k.isFloppable).toList();
}

/// One thing, in one place, in one location's layout.
@immutable
class PropPlacement {
  const PropPlacement(this.kind, this.x, this.y);

  final PropKind kind;
  final double x;
  final double y;

  TownSpot get spot => TownSpot(x, y);
}

/// Where Neil is. Cycles forever: beach → boat ramp → main street → caravan
/// park → footy oval → beach…
///
/// There is nothing to unlock and nothing missable. A child who plays for a
/// minute sees the boat ramp; one who plays all afternoon sees the same five
/// places again, and **later places are prettier, never harder** — no location
/// has more to dodge, because there is nothing to dodge anywhere (the scope:
/// *no difficulty*).
enum TownPlace {
  beach(
    sky: Color(0xFFCFE8F5),
    sea: Color(0xFF8FAEB8),
    groundFar: Color(0xFFF2E3C0),
    groundNear: Color(0xFFEFD9A8),
    start: TownSpot(0.34, 0.50),
    layout: [
      PropPlacement(PropKind.car, 0.78, 0.18),
      PropPlacement(PropKind.kelp, 0.16, 0.26),
      PropPlacement(PropKind.sand, 0.45, 0.24),
      PropPlacement(PropKind.cone, 0.62, 0.40),
      PropPlacement(PropKind.bin, 0.88, 0.44),
      PropPlacement(PropKind.boat, 0.18, 0.72),
      PropPlacement(PropKind.kelp, 0.58, 0.68),
      PropPlacement(PropKind.sand, 0.86, 0.80),
      PropPlacement(PropKind.seagull, 0.68, 0.52),
      PropPlacement(PropKind.seagull, 0.90, 0.26),
      PropPlacement(PropKind.wallaby, 0.10, 0.80),
      PropPlacement(PropKind.dog, 0.52, 0.88),
      PropPlacement(PropKind.shack, 0.06, 0.16),
    ],
  ),
  boatRamp(
    sky: Color(0xFFD4E9F2),
    sea: Color(0xFF7FA3AE),
    groundFar: Color(0xFFCFCAC0),
    groundNear: Color(0xFFBFB9AE),
    start: TownSpot(0.44, 0.65),
    layout: [
      PropPlacement(PropKind.jetty, 0.24, 0.22),
      PropPlacement(PropKind.boat, 0.70, 0.20),
      PropPlacement(PropKind.cone, 0.44, 0.40),
      PropPlacement(PropKind.kelp, 0.12, 0.50),
      PropPlacement(PropKind.car, 0.80, 0.52),
      PropPlacement(PropKind.bin, 0.30, 0.74),
      PropPlacement(PropKind.kelp, 0.60, 0.72),
      PropPlacement(PropKind.sand, 0.88, 0.84),
      PropPlacement(PropKind.seagull, 0.50, 0.16),
      PropPlacement(PropKind.seagull, 0.86, 0.34),
      PropPlacement(PropKind.pademelon, 0.16, 0.86),
      PropPlacement(PropKind.dog, 0.68, 0.90),
      PropPlacement(PropKind.ute, 0.06, 0.20),
    ],
  ),
  mainStreet(
    sky: Color(0xFFDCEBF5),
    sea: Color(0xFF9BB6BE),
    groundFar: Color(0xFFB9B4AC),
    groundNear: Color(0xFFA9A49C),
    start: TownSpot(0.38, 0.67),
    layout: [
      PropPlacement(PropKind.car, 0.20, 0.30),
      PropPlacement(PropKind.car, 0.62, 0.26),
      PropPlacement(PropKind.cone, 0.42, 0.46),
      PropPlacement(PropKind.bin, 0.88, 0.58),
      PropPlacement(PropKind.hose, 0.14, 0.68),
      PropPlacement(PropKind.cone, 0.50, 0.72),
      PropPlacement(PropKind.car, 0.66, 0.84),
      PropPlacement(PropKind.dog, 0.16, 0.90),
      PropPlacement(PropKind.kidOnBike, 0.70, 0.88),
      PropPlacement(PropKind.seagull, 0.24, 0.18),
      PropPlacement(PropKind.shack, 0.06, 0.18),
      PropPlacement(PropKind.ute, 0.94, 0.18),
    ],
  ),
  caravanPark(
    sky: Color(0xFFD8EFE4),
    sea: Color(0xFF8FB8A8),
    groundFar: Color(0xFFBEE4AE),
    groundNear: Color(0xFFA6D897),
    start: TownSpot(0.40, 0.59),
    layout: [
      PropPlacement(PropKind.trampoline, 0.30, 0.34),
      PropPlacement(PropKind.car, 0.72, 0.28),
      PropPlacement(PropKind.hose, 0.14, 0.56),
      PropPlacement(PropKind.cone, 0.52, 0.52),
      PropPlacement(PropKind.bin, 0.88, 0.56),
      PropPlacement(PropKind.sand, 0.28, 0.80),
      PropPlacement(PropKind.cone, 0.62, 0.78),
      PropPlacement(PropKind.wallaby, 0.10, 0.84),
      PropPlacement(PropKind.wombat, 0.66, 0.90),
      PropPlacement(PropKind.dog, 0.78, 0.86),
      PropPlacement(PropKind.pademelon, 0.94, 0.32),
      PropPlacement(PropKind.cow, 0.06, 0.18),
      PropPlacement(PropKind.shack, 0.80, 0.16),
    ],
  ),
  footyOval(
    sky: Color(0xFFD2E9F7),
    sea: Color(0xFF93B4C0),
    groundFar: Color(0xFFA8DC9C),
    groundNear: Color(0xFF93CF87),
    start: TownSpot(0.27, 0.61),
    layout: [
      PropPlacement(PropKind.trampoline, 0.20, 0.26),
      PropPlacement(PropKind.cone, 0.48, 0.30),
      PropPlacement(PropKind.car, 0.80, 0.34),
      PropPlacement(PropKind.bin, 0.12, 0.60),
      PropPlacement(PropKind.cone, 0.40, 0.58),
      PropPlacement(PropKind.sand, 0.68, 0.66),
      PropPlacement(PropKind.cone, 0.26, 0.84),
      PropPlacement(PropKind.hose, 0.86, 0.84),
      PropPlacement(PropKind.kidOnBike, 0.58, 0.88),
      PropPlacement(PropKind.wallaby, 0.94, 0.52),
      PropPlacement(PropKind.pademelon, 0.06, 0.36),
      PropPlacement(PropKind.dog, 0.72, 0.14),
      PropPlacement(PropKind.cow, 0.92, 0.16),
      PropPlacement(PropKind.ute, 0.06, 0.16),
    ],
  );

  const TownPlace({
    required this.sky,
    required this.sea,
    required this.groundFar,
    required this.groundNear,
    required this.start,
    required this.layout,
  });

  final Color sky;

  /// Tasmania is a grey sea under a big grey sky, not a postcard. Muted on
  /// purpose, so the props — the things worth sitting on — stay the loudest
  /// thing on screen (the same rule that keeps KidPalette's backgrounds pale).
  final Color sea;

  final Color groundFar;
  final Color groundNear;

  /// Where Neil wakes up here.
  ///
  /// Three rules on it, all pinned by tests:
  ///
  ///  * **Clear of every floppable thing's reach**, so he never wakes up
  ///    already sitting on something.
  ///  * **Clear of most of every floppable thing's drawn footprint**, so the
  ///    first thing a child sees is a seal and a town rather than a seal lying
  ///    across a boat. Only *most*: he is as long as a car and these towns are
  ///    busy, so a little overlap with something behind him is depth, not a
  ///    mistake.
  ///  * **Further than [NeilWorld.clearRadius] from anything alive**, so a new
  ///    location does not open with the whole town scattering away from him.
  ///    They are all delighted he is here, and that has to be what a child sees
  ///    first.
  final TownSpot start;

  final List<PropPlacement> layout;

  TownPlace get next => TownPlace.values[(index + 1) % TownPlace.values.length];

  /// Only the things Neil can sit on. Used by the tests that check every
  /// location is fair.
  Iterable<PropPlacement> get floppables =>
      layout.where((p) => p.kind.isFloppable);
}

/// Turns a place in the town into a place on the screen, and back again.
///
/// A gentle oblique view rather than Car Trip's road perspective: the town is a
/// strip seen from slightly above, so everything worth sitting on is visible at
/// once and nothing is hidden behind anything else. Things further back are
/// drawn a little smaller ([scaleAt]) — enough to read as depth, not enough to
/// make the back of the town a worse place to tap.
@immutable
class TownView {
  const TownView({
    required this.width,
    required this.height,
    this.horizonFraction = 0.42,
    this.backScale = 0.85,
  });

  final double width;
  final double height;

  /// Where the ground meets the sea.
  final double horizonFraction;

  /// How big something at the very back is drawn, against the very front.
  ///
  /// Deliberately mild, for two reasons. A strong perspective makes the far
  /// props small targets, and every prop here has to stay comfortably past
  /// 80×80 wherever it sits (CLAUDE.md §3). It also squeezes the back of the
  /// town toward the middle of the screen, which stacks far things on top of
  /// near ones into columns that read as clutter rather than as depth.
  final double backScale;

  double get horizonY => height * horizonFraction;
  double get groundHeight => height - horizonY;

  /// How big something at depth [y] is drawn, 0 (the back) to 1 (the front).
  double scaleAt(double y) => backScale + (1 - backScale) * y.clamp(0.0, 1.0);

  double xAt(TownSpot spot) =>
      width / 2 + (spot.x - 0.5) * width * scaleAt(spot.y);

  double yAt(TownSpot spot) => horizonY + spot.y.clamp(0.0, 1.0) * groundHeight;

  Offset offsetAt(TownSpot spot) => Offset(xAt(spot), yAt(spot));

  /// A length in town units, in pixels, at depth [y].
  double lengthAt(double units, double y) => units * width * scaleAt(y);

  /// The inverse of [xAt]/[yAt]: where on the ground a finger landed.
  ///
  /// A tap above the horizon comes back as the very back of the town rather
  /// than as nothing, because **there is no dead tap in this game** — every
  /// touch has to send Neil somewhere (the scope's *Kid-rules impact*).
  TownSpot spotAt(Offset point) {
    if (width <= 0 || groundHeight <= 0) return const TownSpot(0.5, 0.5);
    final y = ((point.dy - horizonY) / groundHeight).clamp(0.0, 1.0);
    final x = (point.dx - width / 2) / (width * scaleAt(y)) + 0.5;
    return TownSpot(x, y).clamped;
  }
}
