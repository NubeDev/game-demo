import 'package:flutter/material.dart';

/// The places she flies through, in order, forever.
///
/// **A land is the next place, never a gate** (the scope's *Not this*). Nothing
/// here is locked, nothing is unlocked, nothing is missed by leaving early, and
/// the next land always arrives. There is no level number, no world map, no
/// stars out of three and no replaying one for a better result — [next] simply
/// wraps, so a child who plays for an hour goes round again and the meadow is
/// as welcome the second time.
///
/// **Later lands are prettier, never harder.** Nothing in this enum affects
/// speed, spacing, crystal height or anything else the world does — it is
/// colours and a water line, and that is the whole difference between lands.
/// A future session adding a `difficulty` field here is breaking the game
/// (CLAUDE.md §3: no difficulty ramp).
enum Land {
  meadow(
    skyTop: Color(0xFFBDE8FF),
    skyBottom: Color(0xFFEAF8FF),
    groundNear: Color(0xFF9FDF95),
    groundFar: Color(0xFFBDEBB4),
  ),
  beach(
    skyTop: Color(0xFFBFE9FF),
    skyBottom: Color(0xFFFFF3D6),
    groundNear: Color(0xFFF2DCA6),
    groundFar: Color(0xFFF7E9C6),
    // The sea, for the whale to breach in.
    water: Color(0xFF7FC9EC),
  ),
  snowyMountain(
    skyTop: Color(0xFFD8E9F7),
    skyBottom: Color(0xFFF4FAFF),
    groundNear: Color(0xFFEDF5FB),
    groundFar: Color(0xFFDCE9F3),
  ),
  cloudIsland(
    skyTop: Color(0xFFCFE4FF),
    skyBottom: Color(0xFFFFEFF6),
    groundNear: Color(0xFFF6F0FF),
    groundFar: Color(0xFFE4DAF7),
  ),
  glowwormCave(
    // The cave DIMS, it never goes black (the scope, and CLAUDE.md §3:
    // nothing startling, no sudden dark). This is the darkest the app gets and
    // it is still a lit room — a child can see every crystal, the unicorn and
    // the home button throughout.
    skyTop: Color(0xFF4A5A86),
    skyBottom: Color(0xFF6E7FAE),
    groundNear: Color(0xFF55618C),
    groundFar: Color(0xFF6B78A5),
    glow: true,
  ),
  nightSky(
    skyTop: Color(0xFF3F4E82),
    skyBottom: Color(0xFF8A93C9),
    groundNear: Color(0xFF6C77AD),
    groundFar: Color(0xFF8189BC),
    glow: true,
  );

  const Land({
    required this.skyTop,
    required this.skyBottom,
    required this.groundNear,
    required this.groundFar,
    this.water,
    this.glow = false,
  });

  final Color skyTop;
  final Color skyBottom;
  final Color groundNear;
  final Color groundFar;

  /// Set where there is water below — the beach. **Still never a drop**: the
  /// water is shallow and sits at the ground line, so there is nothing under
  /// her but ground or shallow water (the scope).
  final Color? water;

  /// Whether this land has floating lights in it (the cave, the night sky).
  /// They drift; they do not blink.
  final bool glow;

  /// Always another land. Wraps, so there is no last one and no end.
  Land get next => Land.values[(index + 1) % Land.values.length];
}
