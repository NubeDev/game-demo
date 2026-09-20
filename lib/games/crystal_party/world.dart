import 'dart:math';

/// Which crystals live where.
///
/// **The colour is not decoration and it is not a quiz — it is where the thing
/// is** (the scope). Blue lives low, in the grass and on rocks; pink lives high,
/// in the clouds. Going up and coming back down is the whole skill, and sorting
/// by colour happens as a side effect of flying well.
///
/// The two are told apart THREE ways, any one of which is enough on its own, so
/// a colourblind child is never locked out (CLAUDE.md §3):
///  * colour — blue / pink;
///  * shape — [blue] is a pointy shard, [pink] is a round blob;
///  * sound — they ring on different chime ladders.
enum CrystalColour {
  /// Low. In the grass, on a rock, on a lily pad — at hoof height, reachable
  /// without ever leaving the ground.
  blue,

  /// High. In the clouds, around treetops. Needs a hold to reach.
  pink;

  CrystalColour get other => this == blue ? pink : blue;
}

/// One thing the world has decided to place, and how far along the run it goes.
class PlacedThing {
  const PlacedThing({
    required this.distance,
    this.crystal,
    this.prop,
    this.treat,
    this.heightFraction = 0,
  });

  /// How far into the run it sits, in logical pixels from the start.
  final double distance;

  /// Set when this is a crystal.
  final CrystalColour? crystal;

  /// Set when this is something to rise over or drop under.
  final PropKind? prop;

  /// Set when this is something that is a delight to fly through.
  final TreatKind? treat;

  /// Where between the ground (0) and the top of the sky (1) it sits.
  final double heightFraction;
}

/// Things to rise over and drop under. Clip one and leaves scatter, she
/// wobbles, a soft boing, and the gallop carries on — **nothing stops, nothing
/// breaks, nothing is counted** (the scope).
enum PropKind {
  /// Tall, on the ground. Rise over it.
  pine(width: 90, height: 170, groundStanding: true),

  /// A stack of rocks. Lower than the pine.
  rocks(width: 104, height: 96, groundStanding: true),

  /// A low stone arch — the gap is underneath, so this one is dropped under.
  stoneArch(width: 150, height: 120, groundStanding: false),

  /// A washing line strung between two trees. High; drop under it.
  washingLine(width: 190, height: 58, groundStanding: false);

  const PropKind({
    required this.width,
    required this.height,
    required this.groundStanding,
  });

  final double width;
  final double height;

  /// True if it stands on the ground line; false if it hangs in the air with
  /// clear sky underneath.
  final bool groundStanding;
}

/// Things that are a delight to fly straight through. **None of these can be
/// missed and none of them can be hit wrong** — they have no failure state at
/// all, they are simply nice, and the child flies through them on purpose.
enum TreatKind {
  /// She comes out sparkling.
  waterfall(width: 96, height: 260, high: false),

  /// She comes out fluffy.
  cloud(width: 170, height: 86, high: true),

  /// They swirl into the trail.
  butterflies(width: 130, height: 110, high: true),

  /// A splash of colour up her legs.
  rainbowPuddle(width: 150, height: 34, high: false);

  const TreatKind({
    required this.width,
    required this.height,
    required this.high,
  });

  final double width;
  final double height;

  /// Whether it lives in the sky rather than on the ground.
  final bool high;
}

/// Decides what comes next, and where in the sky it goes.
///
/// Pulled out of the game and made pure so **the rules that keep this game safe
/// are testable without a running game**. Every number here is load-bearing
/// against CLAUDE.md §3:
///
///  * **One speed, forever** ([scrollSpeed]). Nothing in this class reads
///    elapsed time, distance or how well the child is doing to decide how hard
///    to be. There is no difficulty ramp — later lands are prettier, never
///    faster and never denser (the scope's *Not this*).
///  * **A floor on the spacing** ([minGap]), so a crystal and a prop never
///    arrive together and the child is never asked to be two places at once.
///  * **Crystals outnumber props heavily** ([propInEvery]) — the crystals are
///    the game, the props are the journey.
///  * **The quiet help** ([_helpingColour]) — if one side of the arch is
///    lagging, that colour starts appearing more often and lower down, so a
///    child who cannot manage the hold still reaches the party. It is never
///    announced and there is nothing on screen that says it happened.
class CrystalPartyWorld {
  CrystalPartyWorld({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// How fast the world scrolls past, in logical pixels per second.
  ///
  /// **One gentle speed, forever.** Slower than Cat Run's 190, because nothing
  /// here has to be timed: the child is choosing a height continuously, not
  /// finding a moment, and a calmer scroll makes the sky easier to read.
  static const scrollSpeed = 150.0;

  /// The minimum space between any two things, in pixels.
  ///
  /// At [scrollSpeed] this is about 1.5 seconds — comfortably longer than the
  /// rise-and-settle of a hold, so a child who has just come down for a blue
  /// crystal is never immediately asked to go back up.
  static const minGap = 230.0;

  /// How much extra space a prop wants after it, on top of [minGap]. A crystal
  /// tucked right behind a pine tree would ask the child to clip the tree to
  /// get it, which is the one shape this game must never have.
  static const afterPropGap = 180.0;

  /// Roughly one thing in this many is a prop to rise over or drop under.
  static const propInEvery = 6;

  /// Roughly one in this many is a treat to fly through.
  static const treatInEvery = 5;

  /// How far ahead of the screen edge things are placed.
  static const spawnLookahead = 220.0;

  /// Where a blue crystal sits, as a fraction of the sky above the ground.
  /// Low enough to be swept up by a galloping unicorn with no hold at all.
  static const blueLow = 0.0;
  static const blueHigh = 0.16;

  /// Where a pink crystal sits. The top of this range is the highest thing in
  /// the game, and [CrystalPartyWorld] never places anything above it — about
  /// two seconds of hold, which is the scope's ceiling on a small thumb.
  static const pinkLow = 0.55;
  static const pinkHigh = 0.92;

  /// The top of the pink range while that colour is being helped.
  ///
  /// **Still comfortably above [blueHigh], and still inside the pink band** —
  /// it is a shorter hold, not a free one, so the child is practising the same
  /// move and the colours still mean what they mean. A helped pink sits in the
  /// bottom slice of pink's own range rather than dropping out of the sky.
  static const helpedPinkHigh = 0.68;

  double _lastDistance = 0;
  bool _lastWasProp = false;

  /// How many of each colour the arch has taken so far this land. Only ever
  /// read by [_helpingColour] — it is never shown, never counted out loud, and
  /// never a score.
  final _gathered = <CrystalColour, int>{
    CrystalColour.blue: 0,
    CrystalColour.pink: 0,
  };

  /// How far the world has placed to. Bookkeeping only, never shown.
  double get lastDistance => _lastDistance;

  /// Tell the world a crystal went in, so the quiet help can notice a lag.
  void recordGathered(CrystalColour colour) =>
      _gathered[colour] = _gathered[colour]! + 1;

  /// Start the next land: the arch is empty again, so the help starts neutral.
  void resetLand() {
    for (final colour in CrystalColour.values) {
      _gathered[colour] = 0;
    }
  }

  /// How many of [colour] have gone into the arch this land. Exposed for tests,
  /// which are the only thing that ever reads a count in this game.
  int gathered(CrystalColour colour) => _gathered[colour]!;

  /// How far behind the other side a colour has to fall before the game starts
  /// quietly helping.
  ///
  /// Three is deliberately small: by the time a child has missed three pinks
  /// they have almost certainly not worked out the hold, and waiting longer
  /// leaves them watching a half-built arch — the exact failure the scope's
  /// kid-rules section is guarding against.
  static const helpThreshold = 3;

  /// The colour the game is quietly helping with, or null if both sides are
  /// keeping up.
  ///
  /// **Never surfaced.** There is no icon, no message and no sound for this —
  /// the game comes to meet the child and never says so (the scope).
  CrystalColour? get helpingColour {
    final blue = _gathered[CrystalColour.blue]!;
    final pink = _gathered[CrystalColour.pink]!;
    if (pink + helpThreshold <= blue) return CrystalColour.pink;
    if (blue + helpThreshold <= pink) return CrystalColour.blue;
    return null;
  }

  /// The next thing, given how far the world has scrolled.
  ///
  /// Returns null when there is nothing to place yet, which is most frames.
  PlacedThing? next(double scrolled, double screenWidth) {
    final horizon = scrolled + screenWidth + spawnLookahead;
    final at = _lastDistance + _gapAfter(_lastWasProp);
    if (at > horizon) return null;

    _lastDistance = at;

    // A prop, a treat, or — most of the time — a crystal.
    if (!_lastWasProp && _random.nextInt(propInEvery) == 0) {
      _lastWasProp = true;
      final prop = PropKind.values[_random.nextInt(PropKind.values.length)];
      return PlacedThing(distance: at, prop: prop);
    }
    _lastWasProp = false;

    if (_random.nextInt(treatInEvery) == 0) {
      final treat = TreatKind.values[_random.nextInt(TreatKind.values.length)];
      return PlacedThing(
        distance: at,
        treat: treat,
        // Ground treats sit on the ground; sky treats sit where a held
        // unicorn flies, so flying through one is a thing you choose.
        heightFraction: treat.high ? 0.45 + _random.nextDouble() * 0.35 : 0,
      );
    }

    final colour = _pickColour();
    return PlacedThing(
      distance: at,
      crystal: colour,
      heightFraction: crystalHeight(colour),
    );
  }

  /// The gap before the next thing. Varied so the run is not metronomic, but
  /// **the variation is all upward** — never below the floor.
  double _gapAfter(bool afterProp) =>
      minGap + (afterProp ? afterPropGap : 0) + _random.nextDouble() * 200;

  /// Which colour the next crystal is.
  ///
  /// Even odds normally. When one side is lagging, that colour comes up about
  /// three times in four — enough to catch the arch up within a land, gentle
  /// enough that the other colour has not disappeared.
  CrystalColour _pickColour() {
    final helping = helpingColour;
    if (helping != null && _random.nextInt(4) != 0) return helping;
    return _random.nextBool() ? CrystalColour.blue : CrystalColour.pink;
  }

  /// Where a crystal of [colour] floats, as a fraction of the sky.
  ///
  /// A helped pink sits lower — a shorter hold, which is the whole mechanism of
  /// the quiet help. Blue never moves: it is already reachable at a gallop, so
  /// there is nothing to help with.
  double crystalHeight(CrystalColour colour) {
    if (colour == CrystalColour.blue) {
      return blueLow + _random.nextDouble() * (blueHigh - blueLow);
    }
    // Helped or not, a pink crystal never leaves the pink band: the floor is
    // always [pinkLow], and help only lowers the CEILING. Letting the floor
    // move would put pinks down among the blues and quietly undo the one
    // thing the colours are there to teach.
    final top = helpingColour == CrystalColour.pink ? helpedPinkHigh : pinkHigh;
    return pinkLow + _random.nextDouble() * (top - pinkLow);
  }
}
