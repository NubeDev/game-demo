import 'dart:math';

import 'package:flutter/material.dart';

/// The road, in data: what can be on it, where the child is, and how a point
/// out in front of the car turns into a point on the screen.
///
/// Everything here is pure — no Flame, no canvas, no screen — so the rules that
/// keep this game safe can be tested without standing up a game (the same
/// reason `cat_run/world.dart` is pure).
///
/// ## Two coordinates, and only two
///
///  * **lateral** — across the road. 0 is the centre line, ±1 is the tarmac
///    edge, and the child can steer out to [driveableLateral] on the grass.
///    Deliberately *not* pixels: the rules ("this cone is narrow", "a passenger
///    stands on the verge") must mean the same thing on a phone and a tablet,
///    and a rule written in pixels would quietly change with the screen.
///  * **depth** — how far ahead of the car something is, in world pixels. It
///    counts down to 0 as the car reaches it, and goes negative once passed.
library;

/// How far onto the grass the child can steer.
///
/// The verge is **drivable, not a boundary**: the ride goes bumpy and the car
/// slows a touch, and that is all (the scope: *soft edges*). This is the soft
/// rail that means there is no edge to fall off and no way to leave the world —
/// a five-year-old who cannot yet hold a line has to still be driving a second
/// later (CLAUDE.md §3: nothing to fail, no way to get stuck).
const double driveableLateral = 1.45;

/// Where the tarmac ends and the grass starts.
const double tarmacLateral = 1.0;

/// What the child is meant to do about a thing on the road — or, for most of
/// them, what happens without the child doing anything at all.
enum RoadAction {
  /// Drive straight through it, because it is fun: a puddle, a pile of leaves,
  /// a rainbow arch, a muddy patch, a car wash. These are the *reward* for
  /// steering, and there are deliberately more of them than of anything else.
  driveThrough,

  /// Clip it and it bounces away with a comedy boing. A cone, a beach ball, a
  /// hay bale, a wheelie bin.
  ///
  /// The only thing in the game that resembles an obstacle, and it is resolved
  /// the way Cat Run resolves its fences: keep the obstacle, delete the loss.
  /// Nothing stops, nothing breaks, nothing is counted.
  nudge,

  /// Pull up alongside and it hops in. The passengers.
  pickUp,

  /// Alive, and on the road. **It always steps aside by itself** — see
  /// [RoadThingKind.stepsAsideFromCar]. It cannot be hit, ever.
  stepsAside,

  /// Beside the road in the field, waving. Never collided with; it exists to
  /// answer the horn.
  waver,
}

/// What driving through something does to the car.
enum ThroughEffect {
  /// A sheet of spray.
  splash,

  /// Leaves scatter and swirl.
  scatter,

  /// The car comes out a different colour.
  repaint,

  /// The car gets filthy. Undone by the next [wash]; nothing else changes, and
  /// nothing about being muddy is a penalty.
  muddy,

  /// The car comes out sparkling.
  wash,
}

/// One kind of thing that can be on or beside the road.
///
/// **A data list, not hand-built levels** (the scope says so). The world picks
/// from [all] forever, which is why there is no end, no level and nothing to
/// unlock — and why adding a thing is one entry here plus a `case` in the
/// painter.
///
/// ## Drawn size and reach are different numbers, on purpose
///
/// [drawWidth] is the art. [reach] is how close the car has to come for
/// anything to happen, and it is **smaller than the art for a [RoadAction.nudge]
/// thing and much bigger for a passenger**. Both are generosity pointing the
/// same way: a near miss should read as a miss, and a near pickup should read
/// as a pickup. A five-year-old who steered "surely close enough" and got
/// nothing has been told the game ignored them (CLAUDE.md §3).
@immutable
class RoadThingKind {
  const RoadThingKind({
    required this.id,
    required this.action,
    required this.drawWidth,
    required this.drawHeight,
    required this.color,
    required this.reach,
    this.effect,
    this.secondColor,
  });

  /// Stable name, for tests and the painter's switch. Never shown on screen —
  /// the player cannot read (CLAUDE.md §3).
  final String id;

  final RoadAction action;

  /// Drawn size in road units (1.0 = half the tarmac's width).
  final double drawWidth;
  final double drawHeight;

  final Color color;

  /// A second colour where the shape needs one — the cone's stripe, the
  /// passenger's tummy. Placeholder art only.
  final Color? secondColor;

  /// How close, laterally, the car must come for this thing to do its thing.
  final double reach;

  /// For [RoadAction.driveThrough] only.
  final ThroughEffect? effect;

  /// Whether this thing gets out of the way by itself.
  ///
  /// **The one rule in this game that is about the world outside it.** Driving
  /// into an animal is funny in a game and appalling in life, and a
  /// five-year-old does not hold those apart — so nothing alive can be hit here
  /// at all. The ducks notice the car and waddle aside well before it arrives;
  /// only cones, balls, bales and bins bounce.
  bool get stepsAsideFromCar => action == RoadAction.stepsAside;

  // --- fun to drive through ------------------------------------------------

  static const puddle = RoadThingKind(
    id: 'puddle',
    action: RoadAction.driveThrough,
    drawWidth: 0.62,
    drawHeight: 0.22,
    color: Color(0xFF6FC7E8),
    reach: 0.42,
    effect: ThroughEffect.splash,
  );
  static const leaves = RoadThingKind(
    id: 'leaves',
    action: RoadAction.driveThrough,
    drawWidth: 0.55,
    drawHeight: 0.20,
    color: Color(0xFFE8A33A),
    reach: 0.40,
    effect: ThroughEffect.scatter,
  );
  static const rainbowArch = RoadThingKind(
    id: 'rainbow_arch',
    action: RoadAction.driveThrough,
    // Spans the whole road: an arch that cannot be missed, because the nicest
    // thing in the game should not depend on aim.
    drawWidth: 2.2,
    drawHeight: 1.1,
    color: Color(0xFFFF6B8A),
    secondColor: Color(0xFF4FC3F7),
    reach: 2.0,
    effect: ThroughEffect.repaint,
  );
  static const mud = RoadThingKind(
    id: 'mud',
    action: RoadAction.driveThrough,
    drawWidth: 0.70,
    drawHeight: 0.24,
    color: Color(0xFF9B7A4F),
    reach: 0.45,
    effect: ThroughEffect.muddy,
  );
  static const carWash = RoadThingKind(
    id: 'car_wash',
    action: RoadAction.driveThrough,
    drawWidth: 2.2,
    drawHeight: 1.0,
    color: Color(0xFF7FD4F0),
    secondColor: Color(0xFFFFFFFF),
    reach: 2.0,
    effect: ThroughEffect.wash,
  );

  // --- satisfying to steer around ------------------------------------------

  static const cone = RoadThingKind(
    id: 'cone',
    action: RoadAction.nudge,
    drawWidth: 0.24,
    drawHeight: 0.34,
    color: Color(0xFFFF8A3D),
    secondColor: Color(0xFFFFFFFF),
    // Smaller than the art: a clip that looked like a miss IS a miss.
    reach: 0.16,
  );
  static const beachBall = RoadThingKind(
    id: 'beach_ball',
    action: RoadAction.nudge,
    drawWidth: 0.30,
    drawHeight: 0.30,
    color: Color(0xFFFFE156),
    secondColor: Color(0xFFFF6B8A),
    reach: 0.20,
  );
  static const hayBale = RoadThingKind(
    id: 'hay_bale',
    action: RoadAction.nudge,
    drawWidth: 0.40,
    drawHeight: 0.32,
    color: Color(0xFFE3C063),
    reach: 0.28,
  );
  static const bin = RoadThingKind(
    id: 'bin',
    action: RoadAction.nudge,
    drawWidth: 0.28,
    drawHeight: 0.40,
    color: Color(0xFF6FD97F),
    reach: 0.20,
  );

  // --- passengers ----------------------------------------------------------
  //
  // They wait on the verge. The reach is far bigger than the animal, because
  // the scope asks for "pull up alongside", not "hit the dog".

  static const dog = RoadThingKind(
    id: 'dog',
    action: RoadAction.pickUp,
    drawWidth: 0.30,
    drawHeight: 0.30,
    color: Color(0xFFD9A05B),
    secondColor: Color(0xFF6B4A2F),
    reach: 0.62,
  );
  static const duck = RoadThingKind(
    id: 'duck',
    action: RoadAction.pickUp,
    drawWidth: 0.26,
    drawHeight: 0.28,
    color: Color(0xFFFFE156),
    secondColor: Color(0xFFFFB03A),
    reach: 0.62,
  );
  static const sheep = RoadThingKind(
    id: 'sheep',
    action: RoadAction.pickUp,
    drawWidth: 0.34,
    drawHeight: 0.30,
    color: Color(0xFFF7F3EC),
    secondColor: Color(0xFF4A3B33),
    reach: 0.62,
  );
  static const bear = RoadThingKind(
    id: 'bear',
    action: RoadAction.pickUp,
    drawWidth: 0.36,
    drawHeight: 0.36,
    color: Color(0xFFB07BE8),
    secondColor: Color(0xFF7A4FA8),
    reach: 0.62,
  );

  // --- alive, and on the road ----------------------------------------------

  static const crossingDucks = RoadThingKind(
    id: 'crossing_ducks',
    action: RoadAction.stepsAside,
    drawWidth: 0.34,
    drawHeight: 0.22,
    color: Color(0xFFFFE156),
    secondColor: Color(0xFFFFB03A),
    reach: 0.50,
  );
  static const crossingHedgehog = RoadThingKind(
    id: 'crossing_hedgehog',
    action: RoadAction.stepsAside,
    drawWidth: 0.26,
    drawHeight: 0.18,
    color: Color(0xFF9B7A4F),
    secondColor: Color(0xFF6B4A2F),
    reach: 0.50,
  );

  // --- out in the fields, waiting to be beeped at --------------------------

  static const cow = RoadThingKind(
    id: 'cow',
    action: RoadAction.waver,
    drawWidth: 0.50,
    drawHeight: 0.36,
    color: Color(0xFFFFFFFF),
    secondColor: Color(0xFF4A3B33),
    reach: 0,
  );
  static const tractor = RoadThingKind(
    id: 'tractor',
    action: RoadAction.waver,
    drawWidth: 0.60,
    drawHeight: 0.42,
    color: Color(0xFF6FD97F),
    secondColor: Color(0xFFFFB03A),
    reach: 0,
  );
  static const tree = RoadThingKind(
    id: 'tree',
    action: RoadAction.waver,
    drawWidth: 0.55,
    drawHeight: 0.80,
    color: Color(0xFF6FBF6A),
    secondColor: Color(0xFF8D6742),
    reach: 0,
  );

  /// Everything the world can place.
  static const all = <RoadThingKind>[
    puddle,
    leaves,
    rainbowArch,
    mud,
    carWash,
    cone,
    beachBall,
    hayBale,
    bin,
    dog,
    duck,
    sheep,
    bear,
    crossingDucks,
    crossingHedgehog,
    cow,
    tractor,
    tree,
  ];

  static List<RoadThingKind> withAction(RoadAction action) =>
      all.where((k) => k.action == action).toList();

  /// The widest thing that can sit on the tarmac and actually be hit.
  ///
  /// Pinned by a test against the width of the road: if a nudge thing is ever
  /// wide enough to leave no way past, the test fails rather than a child
  /// meeting a wall they cannot steer around (CLAUDE.md §3).
  static double get widestNudge =>
      withAction(RoadAction.nudge).map((k) => k.drawWidth).reduce(max);
}

/// Where a trip ends up. Changes at every arrival and cycles forever:
/// farm → beach → park → snowy village → farm…
///
/// There is no unlocking and nothing missable here. A child who plays for a
/// minute sees the beach; one who plays all afternoon sees the same four places
/// again (CLAUDE.md §3).
enum Destination {
  farm(
    skyTop: Color(0xFFBDE8FF),
    skyBottom: Color(0xFFEAF8FF),
    field: Color(0xFF9FDF95),
    fieldFar: Color(0xFFBDEBB4),
    tarmac: Color(0xFF9E9E9E),
    verge: Color(0xFF8ACB80),
  ),
  beach(
    skyTop: Color(0xFFBFE9FF),
    skyBottom: Color(0xFFFFF3D6),
    field: Color(0xFFF2DCA6),
    fieldFar: Color(0xFFF7E9C6),
    tarmac: Color(0xFFA8A29A),
    verge: Color(0xFFEBD49B),
  ),
  park(
    skyTop: Color(0xFFCDEBFF),
    skyBottom: Color(0xFFF0FBE8),
    field: Color(0xFF8FD98A),
    fieldFar: Color(0xFFB6E8A8),
    tarmac: Color(0xFF9A968F),
    verge: Color(0xFF7EC97A),
  ),
  snowyVillage(
    skyTop: Color(0xFFD8E9F7),
    skyBottom: Color(0xFFF4FAFF),
    field: Color(0xFFEDF5FB),
    fieldFar: Color(0xFFDCE9F3),
    tarmac: Color(0xFFB4B8BC),
    verge: Color(0xFFE3EEF6),
  );

  const Destination({
    required this.skyTop,
    required this.skyBottom,
    required this.field,
    required this.fieldFar,
    required this.tarmac,
    required this.verge,
  });

  final Color skyTop;
  final Color skyBottom;
  final Color field;
  final Color fieldFar;
  final Color tarmac;
  final Color verge;

  Destination get next =>
      Destination.values[(index + 1) % Destination.values.length];
}

/// Turns a point out in front of the car into a point on the screen.
///
/// The road runs *away* from the viewer to a horizon, which is the view a child
/// already has of a toy car pushed along a carpet — and, just as importantly,
/// it is not Cat Run's side-on view, so the two games do not read as the same
/// game with different art (the scope's open question about the camera,
/// answered here).
///
/// The projection is the textbook one: something [focal] pixels in front of the
/// eye is drawn at full size, and everything further away shrinks by
/// `focal / (focal + depth)`. One number, [scaleAt], drives the lot — position,
/// size, and the width of the road itself — so nothing can drift out of
/// agreement with anything else.
@immutable
class Perspective {
  const Perspective({
    required this.width,
    required this.height,
    this.horizonFraction = 0.34,
    this.carFraction = 0.82,
    this.focal = 300,
  });

  final double width;
  final double height;

  /// Where the road meets the sky.
  final double horizonFraction;

  /// How far down the screen the car sits. Low, so most of the screen is the
  /// road ahead: the child has to *see* what is coming in order to steer around
  /// it, and a thumb resting at the bottom must not cover it.
  final double carFraction;

  /// The distance at which things are drawn at full size — i.e. at the car.
  final double focal;

  /// How far ahead things are drawn at all. Beyond this they are a speck on the
  /// horizon and not worth the work.
  static const double viewDepth = 1100;

  double get horizonY => height * horizonFraction;
  double get carY => height * carFraction;

  /// Half the tarmac's width, in pixels, at the car.
  ///
  /// Capped so a wide tablet does not get a motorway: the road has to stay
  /// crossable in about a second of steering, or holding a line stops meaning
  /// anything.
  double get roadHalfWidth => min(width * 0.30, 300);

  /// How big something at [depth] is drawn, as a fraction of its size at the
  /// car. 1 at the car, shrinking toward 0 at the horizon.
  double scaleAt(double depth) =>
      // Clamped just short of the eye: something level with the car must not
      // divide by zero as it goes past.
      focal / (focal + max(depth, -focal * 0.55));

  /// Where [depth] lands on the screen, vertically.
  double yAt(double depth) => horizonY + (carY - horizonY) * scaleAt(depth);

  /// Where a point across the road lands on the screen, horizontally.
  double xAt(double lateral, double depth) =>
      width / 2 + lateral * roadHalfWidth * scaleAt(depth);

  /// A width in road units, in pixels, at [depth].
  double widthAt(double roadUnits, double depth) =>
      roadUnits * roadHalfWidth * scaleAt(depth);
}
