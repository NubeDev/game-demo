import 'dart:ui';

import '../../shared/lantern_cast.dart';

/// One trip's beach: the time of day, and who is waiting on the sand.
///
/// Trips cycle through these in order, so the day moves on as the child plays
/// — morning, midday, a soft sunset — and a different group of friends is
/// there each time. Nothing about it is a level: every beach is the same
/// three waves.
class Beach {
  const Beach({
    required this.skyTop,
    required this.skyBottom,
    required this.sun,
    required this.sunHeight,
    required this.seaFar,
    required this.sea,
    required this.seaDeep,
    required this.sand,
    required this.friends,
  });

  final Color skyTop;
  final Color skyBottom;
  final Color sun;

  /// Where the sun sits, from 0 (on the horizon) to 1 (top of the sky).
  final double sunHeight;

  final Color seaFar;
  final Color sea;
  final Color seaDeep;
  final Color sand;

  final List<LanternFriend> friends;
}

const beaches = [
  Beach(
    skyTop: Color(0xFF9FD8F2),
    skyBottom: Color(0xFFE6F6FB),
    sun: Color(0xFFFFE08A),
    sunHeight: 0.45,
    seaFar: Color(0xFF7FC9CF),
    sea: Color(0xFF4FB3BA),
    seaDeep: Color(0xFF2F8C99),
    sand: Color(0xFFF2D9A6),
    friends: [LanternFriend.tobi, LanternFriend.biggy, LanternFriend.pacho],
  ),
  Beach(
    skyTop: Color(0xFF7CC4EE),
    skyBottom: Color(0xFFD3EEF9),
    sun: Color(0xFFFFE9A8),
    sunHeight: 0.85,
    seaFar: Color(0xFF6FC2D0),
    sea: Color(0xFF3FA6B8),
    seaDeep: Color(0xFF2A7F96),
    sand: Color(0xFFF4DDAE),
    friends: [LanternFriend.luna, LanternFriend.tiko, LanternFriend.tobi],
  ),
  // Sunset: warm, but soft. Peach, not red — calm is a rule (CLAUDE.md §3).
  Beach(
    skyTop: Color(0xFFF6B99A),
    skyBottom: Color(0xFFFCE3C4),
    sun: Color(0xFFFFD27A),
    sunHeight: 0.2,
    seaFar: Color(0xFF8FBFC8),
    sea: Color(0xFF5AA3B0),
    seaDeep: Color(0xFF3D7F92),
    sand: Color(0xFFF0CF9C),
    friends: [LanternFriend.pacho, LanternFriend.luna, LanternFriend.biggy],
  ),
];

Beach beachFor(int trip) => beaches[trip % beaches.length];
