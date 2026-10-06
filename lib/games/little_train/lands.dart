import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'assets.dart';

/// One land the train travels through: its pictures, its three passengers, and
/// the numbers needed to sit the train on its generated track.
@immutable
class Land {
  const Land({
    required this.name,
    required this.passengers,
    required this.props,
    required this.railLine,
    required this.gauge,
    required this.groundColor,
    required this.skyColor,
  });

  /// The file-name stem shared by this land's pictures.
  final String name;

  /// Who waits along the line, in order. Exactly
  /// [passengersPerLand] — one per wagon, so a full train IS the progress
  /// readout (CLAUDE.md §3: progress, never a score).
  final List<String> passengers;

  /// The scenery props scattered behind the track.
  final List<String> props;

  /// Where the train's wheels touch, as a fraction of the ground strip's height
  /// from its top. Measured by eye from each generated strip — the model put
  /// the rails at a different height in every one.
  final double railLine;

  /// The distance from the far rail to the near rail, as a fraction of the
  /// strip's height. Each strip is scaled so this comes out the same on screen,
  /// which is what makes four separately generated tracks read as one railway.
  final double gauge;

  /// Painted under the ground strip, so a tall screen never shows a gap below
  /// it. Sampled from each strip.
  final Color groundColor;

  /// Painted behind the sky picture, and used for the veil between lands.
  final Color skyColor;

  String get sky => LittleTrainAssets.sky(name);
  String get ground => LittleTrainAssets.ground(name);
  String get station => LittleTrainAssets.station(name);
  List<String> get propPaths =>
      [for (final p in props) LittleTrainAssets.prop(name, p)];

  /// Every picture this land needs, for preloading.
  List<String> get allPaths => [
    sky,
    ground,
    station,
    ...propPaths,
    for (final p in passengers) ...[
      LittleTrainAssets.waiting(p),
      LittleTrainAssets.riding(p),
    ],
  ];
}

/// How many passengers each land has, which is also how many wagons the train
/// pulls. Three: enough to feel like a trainful, few enough that every land
/// ends in a party within a couple of minutes.
const passengersPerLand = 3;

/// The journey, in order. It loops: after the snow comes the meadow again.
const lands = <Land>[
  Land(
    name: 'meadow',
    passengers: ['bunny', 'piglet', 'hedgehog'],
    props: ['tree', 'flowers'],
    railLine: 0.52,
    gauge: 0.207,
    groundColor: Color(0xFF8CC152),
    skyColor: Color(0xFFA5E1FA),
  ),
  Land(
    name: 'forest',
    passengers: ['bear', 'fox', 'owl'],
    props: ['pine', 'mushroom'],
    railLine: 0.33,
    gauge: 0.197,
    groundColor: Color(0xFF613D1F),
    skyColor: Color(0xFFFED694),
  ),
  Land(
    name: 'seaside',
    passengers: ['crab', 'turtle', 'seagull'],
    props: ['palm', 'umbrella'],
    railLine: 0.52,
    gauge: 0.29,
    groundColor: Color(0xFFEFB053),
    skyColor: Color(0xFFC0EBF6),
  ),
  Land(
    name: 'snow',
    passengers: ['penguin', 'polarbear', 'reindeer'],
    props: ['snowpine', 'snowman'],
    railLine: 0.37,
    gauge: 0.19,
    groundColor: Color(0xFFDFEEF2),
    skyColor: Color(0xFFC3D9FD),
  ),
];
