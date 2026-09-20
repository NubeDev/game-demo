import 'dart:math';

import 'package:flutter/material.dart';

import '../../shared/kid_palette.dart';

/// What the child is meant to do about a thing in the way.
enum ObstacleAction {
  /// Press the paw. A fence, a flowerpot, a log, a puddle.
  jump,

  /// Press the crouching cat. A low pipe, a branch, a washing line.
  duck,

  /// Land on it and it launches the cat. A mushroom, a snail, a cushion.
  bounce,

  /// Overhead. Headbutt it and something pops out.
  block,
}

/// What a miss looks like. Every one of these keeps the cat running
/// (CLAUDE.md §3: no losing, no game over) — they differ only in the slapstick.
enum MissStyle {
  /// Hit a fence: comic tumble, dust puff, lands on its feet, runs on.
  tumble,

  /// Missed a duck: squashed flat for half a second, pops back, runs on.
  pancake,

  /// Landed in water: belly-flop, splash, floats back up, runs on.
  splash,

  /// Nothing at all. Used by the things that cannot be missed — a bounce the
  /// cat simply ran past, a block it never jumped at.
  none,
}

/// One kind of thing in the world: its shape, its size, and what to do about it.
///
/// **Obstacles are a data list, not hand-placed levels** (the scope says so).
/// The world picks from [all] at random forever, which is why there is no end,
/// no level, no "1-1", and nothing to unlock — and why adding a new obstacle is
/// one entry here plus a `case` in the painter.
///
/// ## Two sizes per obstacle, and why
///
/// [size] is the drawn art. [hitBox] is what the cat actually collides with,
/// and it is deliberately **smaller** — see [hitInset]. A five-year-old who
/// jumps a frame late should clear the fence anyway; a clip that was visually
/// "surely that was over it" reading as a bonk is the same injustice as a tap
/// the game ignored (CLAUDE.md §3).
@immutable
class ObstacleKind {
  const ObstacleKind({
    required this.id,
    required this.action,
    required this.size,
    required this.color,
    this.missStyle = MissStyle.tumble,
    this.hitInset = 0.22,
  });

  /// Stable name, for tests and for the painter's switch. Never shown on
  /// screen — the player cannot read (CLAUDE.md §3).
  final String id;

  final ObstacleAction action;

  /// The drawn size in logical pixels, at the ground.
  final Size size;

  final Color color;

  /// What a miss looks like.
  final MissStyle missStyle;

  /// How much of the art is *not* solid, as a fraction of each edge.
  ///
  /// Generosity, deliberately baked into the data rather than applied at the
  /// collision site, so every obstacle gets it and a new one cannot forget.
  final double hitInset;

  /// The collidable box, centred in the art.
  Size get hitBox => Size(
    size.width * (1 - hitInset * 2),
    // Height is inset from the TOP only: the bottom is the ground, and a
    // fence whose lower edge was not solid would let the cat clip through
    // the legs of it, which looks like the game glitching rather than
    // like a generous hitbox.
    size.height * (1 - hitInset),
  );

  /// Things that arrive on the ground and are jumped over.
  static const fence = ObstacleKind(
    id: 'fence',
    action: ObstacleAction.jump,
    size: Size(83, 110),
    color: Color(0xFFC98B5A),
  );
  static const flowerpot = ObstacleKind(
    id: 'flowerpot',
    action: ObstacleAction.jump,
    size: Size(77, 86),
    color: Color(0xFFE8825A),
  );
  static const log = ObstacleKind(
    id: 'log',
    action: ObstacleAction.jump,
    size: Size(130, 71),
    color: Color(0xFFA9793F),
  );

  /// The puddle is flat and wide: it is the *easiest* thing in the game to
  /// clear, because the belly-flop is the funniest miss and a child who wants
  /// to see it should have to aim for it rather than keep getting it by
  /// accident.
  static const puddle = ObstacleKind(
    id: 'puddle',
    action: ObstacleAction.jump,
    size: Size(178, 38),
    color: Color(0xFF6FC7E8),
    missStyle: MissStyle.splash,
  );

  /// Things to duck under. Rare, slow, and announced before they arrive —
  /// see `world.dart`. Missing one is NOT a failure state: the cat is squashed
  /// flat for half a second, pops back into shape and runs on.
  static const pipe = ObstacleKind(
    id: 'pipe',
    action: ObstacleAction.duck,
    size: Size(154, 80),
    color: Color(0xFF7FB77E),
    missStyle: MissStyle.pancake,
  );
  static const branch = ObstacleKind(
    id: 'branch',
    action: ObstacleAction.duck,
    size: Size(142, 65),
    color: Color(0xFF8C9E5B),
    missStyle: MissStyle.pancake,
  );
  static const washingLine = ObstacleKind(
    id: 'washing_line',
    action: ObstacleAction.duck,
    size: Size(207, 74),
    color: Color(0xFFEFA9C6),
    missStyle: MissStyle.pancake,
  );

  /// Things to bounce on. Landing on one launches the cat high; it giggles,
  /// springs back, and is **still there afterwards** — nothing is squashed out
  /// of existence (the scope's *Not this*, and CLAUDE.md §3: nothing scary).
  static const mushroom = ObstacleKind(
    id: 'mushroom',
    action: ObstacleAction.bounce,
    size: Size(107, 83),
    color: Color(0xFFFF8FA3),
    missStyle: MissStyle.none,
  );
  static const snail = ObstacleKind(
    id: 'snail',
    action: ObstacleAction.bounce,
    size: Size(112, 68),
    color: Color(0xFFD8A657),
    missStyle: MissStyle.none,
  );
  static const cushion = ObstacleKind(
    id: 'cushion',
    action: ObstacleAction.bounce,
    size: Size(124, 59),
    color: Color(0xFFB07BE8),
    missStyle: MissStyle.none,
  );

  /// A block overhead. Headbutt it and something pops out.
  static const block = ObstacleKind(
    id: 'block',
    action: ObstacleAction.block,
    size: Size(95, 95),
    color: Color(0xFFFFCB6B),
    missStyle: MissStyle.none,
    // The one obstacle whose hitbox is *generous*, not mean: it is a reward,
    // so a headbutt that nearly connected should connect. Negative inset.
    hitInset: -0.10,
  );

  /// Everything the world can spawn.
  static const all = <ObstacleKind>[
    fence,
    flowerpot,
    log,
    puddle,
    pipe,
    branch,
    washingLine,
    mushroom,
    snail,
    cushion,
    block,
  ];

  static List<ObstacleKind> withAction(ObstacleAction action) =>
      all.where((k) => k.action == action).toList();

  /// The tallest thing the cat must clear. The jump is tuned against this, and
  /// a test pins the arc against it — add a taller obstacle and the test fails
  /// rather than the child silently being unable to clear it.
  static double get tallestJumpable =>
      withAction(ObstacleAction.jump).map((k) => k.hitBox.height).reduce(max);
}

/// What pops out of a headbutted block. Purely a nicer moment — no obstacle
/// pays out progress except the fish, so nothing here can be "missed out on".
enum BlockPrize { butterfly, fish, musicNote, leaves }

/// The scenery the run passes through. It changes at every celebration and
/// cycles forever: garden → beach → snow → garden...
///
/// There is no unlocking and no progression here. A child who plays for two
/// minutes sees the beach; one who plays for an hour sees the same three
/// places again. Nothing is missable (CLAUDE.md §3).
enum Scene {
  garden(
    skyTop: KidPalette.skyTop,
    skyBottom: KidPalette.skyBottom,
    groundNear: Color(0xFF9FDF95),
    groundFar: Color(0xFFBDEBB4),
  ),
  beach(
    skyTop: Color(0xFFBFE9FF),
    skyBottom: Color(0xFFFFF3D6),
    groundNear: Color(0xFFF2DCA6),
    groundFar: Color(0xFFF7E9C6),
  ),
  snow(
    skyTop: Color(0xFFD8E9F7),
    skyBottom: Color(0xFFF4FAFF),
    groundNear: Color(0xFFEDF5FB),
    groundFar: Color(0xFFDCE9F3),
  );

  const Scene({
    required this.skyTop,
    required this.skyBottom,
    required this.groundNear,
    required this.groundFar,
  });

  final Color skyTop;
  final Color skyBottom;
  final Color groundNear;
  final Color groundFar;

  Scene get next => Scene.values[(index + 1) % Scene.values.length];
}
