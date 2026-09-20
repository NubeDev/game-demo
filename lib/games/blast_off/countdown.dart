import 'package:flutter/foundation.dart';

/// What the child is counting down *to*.
///
/// The picture decides what zero looks like. Only the rocket exists in this
/// slice; the cake, the race flag and the egg timer are the next one, and they
/// change nothing here — see `docs/scope/games/blast-off-scope.md`.
enum Skin { rocket }

/// How long a countdown runs.
///
/// Every length the child can reach is one of these rungs. There is no number
/// pad and no free typing, so there is no such thing as a countdown of 47
/// seconds: the presets jump straight to a rung, and the more/less buttons
/// step one rung at a time. That is what keeps an adjustable time from
/// needing an adult to read it (CLAUDE.md §3).
///
/// The rungs get coarser as they get longer — five second steps at the bottom,
/// minutes at the top — because "one more" means something quite different at
/// five seconds than at five minutes.
enum CountdownLength {
  five(seconds: 5),
  ten(seconds: 10),
  fifteen(seconds: 15),
  thirty(seconds: 30),
  oneMinute(seconds: 60),

  /// Two minutes of tooth-brushing, which is the thing this game is quietly
  /// most useful for.
  twoMinutes(seconds: 120),

  threeMinutes(seconds: 180),

  /// Five minutes to tidy up. Long enough that the jar barely moves at first,
  /// which is exactly the point — anticipation is the feature.
  fiveMinutes(seconds: 300),

  tenMinutes(seconds: 600);

  const CountdownLength({required this.seconds});

  final int seconds;

  /// The next rung up, or null at the top. Null is what greys the button out
  /// — a button that is there but does nothing teaches a child the screen is
  /// unreliable, so it must visibly stop instead.
  CountdownLength? get longer =>
      index < values.length - 1 ? values[index + 1] : null;

  /// The next rung down, or null at the bottom.
  CountdownLength? get shorter => index > 0 ? values[index - 1] : null;

  /// Where this length sits on the ladder: 0 at the shortest, 1 at the
  /// longest.
  ///
  /// What the picture does with it is the picture's business — the rocket
  /// draws itself bigger for a longer countdown, which is the third way the
  /// game says how long the wait is without a number in it. The dots say it
  /// on the button row, the star jar says it while counting, and the rocket
  /// says it in the one place a child is already looking: a five-year-old
  /// cannot read "5:00", but can see plainly that this is the big rocket
  /// (CLAUDE.md §3).
  ///
  /// Deliberately a position rather than a size. How much room there is to be
  /// big in depends on the screen, and only the scene knows that — see
  /// Rocket.fitTo.
  double get sizeStep => index / (values.length - 1);

  /// The three quick presets, as pictures.
  ///
  /// Deliberately far apart — a very short one, a middling one and a long one
  /// — so a child choosing by picture gets a genuinely different countdown
  /// each time rather than three that feel the same.
  static const presets = <CountdownLength>[five, thirty, fiveMinutes];
}

/// Where a countdown has got to.
enum CountdownPhase {
  /// Nothing running. The child is picking, or has just come back from a
  /// launch. Both are the same state — there is no "finished" to clear.
  waiting,

  /// Counting. The only state with a clock in it.
  counting,

  /// Held, mid-count, by the child or the adult beside them.
  ///
  /// Deliberately a state of its own rather than "counting with dt of zero":
  /// everything on screen has to visibly settle when it is paused — the rocket
  /// stops rattling, the smoke thins — or a child cannot tell the difference
  /// between paused and broken.
  paused,

  /// Zero happened. The rocket is going; confetti is falling.
  launched,
}

/// The countdown itself, with no Flutter, Flame or audio in it.
///
/// ## Why this is a plain model
///
/// Everything that could make this game *wrong* for a five-year-old is a rule
/// about time, and time is exactly what is hard to check by looking at a
/// screen. Keeping the clock here means the rules below are pinned by tests
/// rather than by eye:
///
///  * **Nothing is ever required before zero.** There is no task attached, so
///    reaching zero cannot be failing to reach zero. This is the whole reason
///    a countdown is allowed in an app whose rules ban timers (CLAUDE.md §3 —
///    "no timer that can cause failure"). If a future change makes anything
///    depend on beating this clock, that change is the bug.
///  * **Stopping costs nothing.** [stop] returns to [CountdownPhase.waiting]
///    and nothing is recorded, subtracted or counted. A child who wanders off
///    mid-count has not abandoned anything.
///  * **It only ever goes down, and only while counting.** No pausing that can
///    be lost, no penalty that adds seconds back on.
class Countdown extends ChangeNotifier {
  Countdown({this.length = CountdownLength.ten, this.skin = Skin.rocket});

  /// How many rungs of the sound ladder a countdown is spread over, whatever
  /// its real length. See [soundRungsLeft].
  static const soundRungs = 10;

  /// How many stars the jar holds. The jar is the countdown drawn as a
  /// *quantity*, so a child who does not yet read digits still sees plainly
  /// that there is less left than there was.
  static const jarStars = 10;

  /// The last few numbers, where everything leans in: bigger, slower, fuller.
  static const finalStretch = 3;

  CountdownLength length;
  Skin skin;

  CountdownPhase _phase = CountdownPhase.waiting;
  CountdownPhase get phase => _phase;

  /// Seconds remaining, as a real number so the animation can use the
  /// fraction. [secondsLeft] is what the child sees.
  double _remaining = 0;

  /// How long the launch has been going, so the game knows when the rocket has
  /// left and the "again" button can appear.
  double _sinceLaunch = 0;
  double get sinceLaunch => _sinceLaunch;

  /// The displayed number: 10, 9, 8 … 1. Never 0 — zero is not a number the
  /// child sees, it is the launch.
  int get secondsLeft => _remaining.ceil();

  /// The time as an adult reads it — "0:30", "5:00", "1:25".
  ///
  /// This is TEXT, on a screen whose whole design is that a child never needs
  /// to read anything (CLAUDE.md §3). It earns its place because the adult
  /// setting a two-minute toothbrush timer genuinely cannot tell two minutes
  /// from three by counting dots, and this game is the one in the app meant to
  /// be handed over by a parent.
  ///
  /// It is a *second* readout, never the only one: the dots and the star jar
  /// say the same thing without reading, and nothing about playing requires
  /// the digits. It is drawn quietly, small and grey, the way the settings cog
  /// is — an adult's affordance that does not invite a child's eye.
  String get clock {
    final seconds = _phase == CountdownPhase.waiting
        ? length.seconds
        : secondsLeft;
    final minutes = seconds ~/ 60;
    final rest = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$rest';
  }

  /// 0 at the start, 1 at zero.
  double get progress => length.seconds == 0
      ? 1
      : (1 - _remaining / length.seconds).clamp(0.0, 1.0);

  /// Stars still in the jar, out of [jarStars].
  ///
  /// A jar that is not counting is a FULL jar, never an empty one: an empty
  /// jar on the waiting screen would say "you have none left" to a child who
  /// has not started yet, and stopping must never look like being emptied out
  /// (see the class doc).
  int get starsLeft => _phase == CountdownPhase.waiting
      ? jarStars
      : (_remaining / length.seconds * jarStars).ceil().clamp(0, jarStars);

  /// True in the last [finalStretch] numbers — three, two, one.
  bool get isFinalStretch =>
      _phase == CountdownPhase.counting && secondsLeft <= finalStretch;

  /// Counting or held — i.e. a countdown exists, whether or not it is moving.
  /// Used by everything that should keep showing the rocket and the jar.
  bool get isUnderway =>
      _phase == CountdownPhase.counting || _phase == CountdownPhase.paused;

  /// The countdown mapped onto the sound ladder's ten rungs, so a two-minute
  /// toothbrush climbs the same musical phrase as a ten-second blast off.
  ///
  /// Returns the number to hand to `KidSounds.count`.
  int get soundRungsLeft {
    if (length.seconds <= soundRungs) return secondsLeft;
    final share = _remaining / length.seconds;
    return (share * soundRungs).ceil().clamp(1, soundRungs);
  }

  void choose({CountdownLength? length, Skin? skin}) {
    // The length is only ever set while waiting. Changing it mid-count would
    // either add seconds back on (which reads as a punishment) or cut them
    // off, and both make the clock feel like something being done TO the
    // child rather than something they set going.
    if (length != null && _phase == CountdownPhase.waiting) {
      this.length = length;
    }
    if (skin != null) this.skin = skin;
    notifyListeners();
  }

  /// One rung longer. Returns false at the top of the ladder, so the caller
  /// can grey the button out rather than letting it do nothing.
  bool longer() {
    final next = length.longer;
    if (next == null || _phase != CountdownPhase.waiting) return false;
    length = next;
    notifyListeners();
    return true;
  }

  /// One rung shorter. Returns false at the bottom.
  bool shorter() {
    final next = length.shorter;
    if (next == null || _phase != CountdownPhase.waiting) return false;
    length = next;
    notifyListeners();
    return true;
  }

  /// Whether the ladder has anywhere left to go, for the button states.
  bool get canLengthen =>
      _phase == CountdownPhase.waiting && length.longer != null;
  bool get canShorten =>
      _phase == CountdownPhase.waiting && length.shorter != null;

  void start() {
    _phase = CountdownPhase.counting;
    _remaining = length.seconds.toDouble();
    _sinceLaunch = 0;
    notifyListeners();
  }

  /// Hold it where it is. Nothing is lost and nothing drains while paused —
  /// pausing is not a penalty and cannot become one.
  void pause() {
    if (_phase != CountdownPhase.counting) return;
    _phase = CountdownPhase.paused;
    notifyListeners();
  }

  /// Carry on from exactly where it was. Never restarts, never rounds the
  /// remaining time away.
  void resume() {
    if (_phase != CountdownPhase.paused) return;
    _phase = CountdownPhase.counting;
    notifyListeners();
  }

  /// Stop, with no consequence of any kind. See the class doc.
  void stop() {
    _phase = CountdownPhase.waiting;
    _remaining = 0;
    _sinceLaunch = 0;
    notifyListeners();
  }

  /// Advances the clock. Returns the number that was just *reached* if this
  /// tick crossed into a new one — so the caller can say it out loud exactly
  /// once — or null.
  ///
  /// Returns 0 at the moment of launch.
  int? tick(double dt) {
    if (_phase == CountdownPhase.launched) {
      // Note for anyone tempted to drive UI from this: it only advances while
      // the Flame loop is running, and the loop stops once the launch has
      // nothing left to animate. The screen's "again" button used to wait on
      // it and consequently never appeared. Anything with a deadline belongs
      // on a widget-layer Timer instead — see BlastOffScreen.
      _sinceLaunch += dt;
      return null;
    }
    if (_phase != CountdownPhase.counting) return null;

    final before = secondsLeft;
    _remaining = (_remaining - dt).clamp(0.0, double.infinity);

    if (_remaining <= 0) {
      _phase = CountdownPhase.launched;
      _sinceLaunch = 0;
      notifyListeners();
      return 0;
    }

    notifyListeners();
    return secondsLeft != before ? secondsLeft : null;
  }
}
