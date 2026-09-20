import 'dart:math';

import 'package:flutter/material.dart';

import '../../shared/kid_palette.dart';

/// What the child is meant to do about a thing in the way.
enum HazardAction {
  /// Press the flat-duck button. A bench, a low gate, a washing line.
  duck,

  /// Nothing at all. Bump into it and it rattles, splashes or scatters, and
  /// Quacky carries straight on. These exist so the park is full of things
  /// that answer without anything being required of the child.
  bump,
}

/// One kind of thing on the path.
///
/// **A data list, not hand-placed levels** (the scope says so): the park picks
/// from [all] at random forever, which is why there is no end, no level and
/// nothing to unlock. Adding one is an entry here plus a `case` in the painter.
///
/// ## Two sizes, and why
///
/// [size] is the drawn art; [hitBox] is what Quacky actually collides with and
/// is deliberately **smaller** (see [hitInset]). A five-year-old who presses a
/// frame late should skid under the bench anyway — a clip that was visually
/// "surely that was under it" reading as a bonk is the same injustice as a tap
/// the game ignored (CLAUDE.md §3).
@immutable
class HazardKind {
  const HazardKind({
    required this.id,
    required this.action,
    required this.size,
    required this.color,
    this.hitInset = 0.22,
  });

  /// Stable name, for tests and the painter's switch. Never shown on screen —
  /// the player cannot read (CLAUDE.md §3).
  final String id;

  final HazardAction action;

  /// The drawn size in logical pixels.
  final Size size;

  final Color color;

  /// How much of the art is *not* solid, as a fraction of each edge.
  /// Generosity baked into the data rather than applied at the collision site,
  /// so every hazard gets it and a new one cannot forget.
  final double hitInset;

  /// The collidable box, centred in the art.
  Size get hitBox => Size(
    size.width * (1 - hitInset * 2),
    // Inset from the TOP only. These hang down from above, and a bench whose
    // lower edge was not solid would let Quacky clip through it, which looks
    // like the game glitching rather than like a generous hitbox.
    size.height * (1 - hitInset),
  );

  // --- things to duck under ------------------------------------------------
  //
  // Rare, slow and telegraphed (see `QuackyWorld`). Missing one is NOT a
  // failure state: Quacky bonks his beak, spins round in a huff with a puff of
  // feathers and carries on, and whatever he was chasing waits for him.

  static const bench = HazardKind(
    id: 'bench',
    action: HazardAction.duck,
    size: Size(190, 84),
    color: Color(0xFFC98B5A),
  );
  static const gate = HazardKind(
    id: 'gate',
    action: HazardAction.duck,
    size: Size(150, 92),
    color: Color(0xFF8C9E5B),
  );
  static const washingLine = HazardKind(
    id: 'washing_line',
    action: HazardAction.duck,
    size: Size(215, 76),
    color: Color(0xFFEFA9C6),
  );
  static const picnicRug = HazardKind(
    id: 'picnic_rug',
    action: HazardAction.duck,
    size: Size(200, 70),
    color: Color(0xFFFF8FA3),
  );
  static const sprinkler = HazardKind(
    id: 'sprinkler',
    action: HazardAction.duck,
    size: Size(168, 80),
    color: Color(0xFF6FC7E8),
  );
  static const dogLead = HazardKind(
    id: 'dog_lead',
    action: HazardAction.duck,
    size: Size(205, 62),
    color: Color(0xFFD8A657),
  );

  // --- things to bump into for fun ----------------------------------------
  //
  // None of these stop him, none of them can be missed, and none of them is
  // ever required. They are the park answering back.

  static const bin = HazardKind(
    id: 'bin',
    action: HazardAction.bump,
    size: Size(84, 96),
    color: Color(0xFF7FB77E),
  );
  static const puddle = HazardKind(
    id: 'puddle',
    action: HazardAction.bump,
    size: Size(172, 34),
    color: Color(0xFF6FC7E8),
  );
  static const pigeons = HazardKind(
    id: 'pigeons',
    action: HazardAction.bump,
    size: Size(130, 56),
    color: Color(0xFFB0B7C4),
  );
  static const deckchair = HazardKind(
    id: 'deckchair',
    action: HazardAction.bump,
    size: Size(104, 88),
    color: Color(0xFFB07BE8),
  );

  /// Everything the park can place.
  static const all = <HazardKind>[
    bench,
    gate,
    washingLine,
    picnicRug,
    sprinkler,
    dogLead,
    bin,
    puddle,
    pigeons,
    deckchair,
  ];

  static List<HazardKind> withAction(HazardAction action) =>
      all.where((k) => k.action == action).toList();

  /// The deepest thing Quacky has to skid under. His ducked height is pinned
  /// against this by a test — add a lower hazard and the test fails rather than
  /// the child silently being unable to get under it.
  static double get deepestDuckable =>
      withAction(HazardAction.duck).map((k) => k.hitBox.height).reduce(max);
}

/// Who is up ahead carrying the bread.
///
/// The chase target is the whole game, so there are several and they are
/// visibly different at a glance — a child should be able to see *what* they
/// are catching up with from the far side of the screen.
enum ChaseKind {
  /// A child swinging a paper bag. The commonest, and the one the game is
  /// about. They run backwards, facing Quacky, waving the bag.
  childWithBag(
    color: Color(0xFF4FC3F7),
    size: Size(70, 132),
    treat: TreatKind.crust,
  ),

  /// Another duck with a crust. It shares — see the scope: nothing in this
  /// game is taken from anybody.
  duckWithCrust(
    color: Color(0xFFFFE156),
    size: Size(92, 74),
    treat: TreatKind.crust,
  ),

  /// A toddler in a pushchair dropping crumbs. Slowest of all.
  pushchair(
    color: Color(0xFFB07BE8),
    size: Size(104, 116),
    treat: TreatKind.crumbs,
  ),

  /// A pigeon with half a sandwich, which it gives up with bad grace.
  pigeonWithSandwich(
    color: Color(0xFFB0B7C4),
    size: Size(76, 62),
    treat: TreatKind.sandwich,
  ),

  /// The duck-food dispenser: peas, sweetcorn and proper duck pellets.
  ///
  /// In the park because bread is not actually good for ducks and a parent may
  /// well know it. Nobody is corrected and there is no text — the good food is
  /// simply *also* there, and it gets the nicest chomp in the game.
  foodDispenser(
    color: Color(0xFF6FD97F),
    size: Size(86, 140),
    treat: TreatKind.peas,
  );

  const ChaseKind({
    required this.color,
    required this.size,
    required this.treat,
  });

  final Color color;
  final Size size;

  /// What Quacky gets when he catches up.
  final TreatKind treat;
}

/// What gets eaten. Purely which chomp plays and which shape is drawn — every
/// treat is worth exactly one bread roll, so nothing here can be a better or
/// worse catch (CLAUDE.md §3: no score).
enum TreatKind { crust, crumbs, sandwich, peas }

/// How grumpy Quacky currently is, as a face rather than a number.
///
/// This is the second progress signal in the game and the one a child will
/// actually read: his eyebrows lift a notch with every treat. It **only ever
/// climbs within a round** — see `QuackyTheDuckGame._eat`.
enum Mood {
  furious,
  cross,
  grumbling,
  cheering,
  delighted;

  /// The mood for [eaten] treats out of [total]. Never goes down for a rising
  /// [eaten]; a test pins that.
  static Mood forProgress(int eaten, int total) {
    if (total <= 0) return Mood.furious;
    final p = (eaten / total).clamp(0.0, 1.0);
    final i = (p * (Mood.values.length - 1)).floor();
    return Mood.values[i.clamp(0, Mood.values.length - 1)];
  }

  /// 0 (furious) .. 1 (delighted). Drives the eyebrow angle and the bounce in
  /// the waddle, and is what a bound Rive number would take if Quacky ever
  /// becomes real art (see `assets.dart`).
  double get brightness => index / (Mood.values.length - 1);
}

/// The parts of the park the chase passes through. Changes at every
/// celebration and cycles forever: pond → bandstand → playing field →
/// allotments → pond...
///
/// There is no unlocking and no progression. A child who plays for two minutes
/// sees the bandstand; one who plays for an hour sees the same four places
/// again. Nothing is missable (CLAUDE.md §3).
enum ParkPlace {
  pond(
    skyTop: KidPalette.skyTop,
    skyBottom: KidPalette.skyBottom,
    groundNear: Color(0xFF9FDF95),
    groundFar: Color(0xFFBDEBB4),
  ),
  bandstand(
    skyTop: Color(0xFFCFE9FF),
    skyBottom: Color(0xFFFFF3D6),
    groundNear: Color(0xFFB7DF8F),
    groundFar: Color(0xFFD2ECB0),
  ),
  playingField(
    skyTop: Color(0xFFBFE9FF),
    skyBottom: Color(0xFFEFFBE8),
    groundNear: Color(0xFF8FD98A),
    groundFar: Color(0xFFB4E6AB),
  ),
  allotments(
    skyTop: Color(0xFFFFE3C2),
    skyBottom: Color(0xFFFFF6E6),
    groundNear: Color(0xFFCBBE88),
    groundFar: Color(0xFFE2D3A8),
  );

  const ParkPlace({
    required this.skyTop,
    required this.skyBottom,
    required this.groundNear,
    required this.groundFar,
  });

  final Color skyTop;
  final Color skyBottom;
  final Color groundNear;
  final Color groundFar;

  ParkPlace get next => ParkPlace.values[(index + 1) % ParkPlace.values.length];
}
