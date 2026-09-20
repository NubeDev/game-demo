/// Neil, the town, and everything that happens between them.
///
/// Pure Dart — no Flame, no canvas, no widgets — so the rules that keep this
/// game kind can be tested without standing up a game. The components in
/// `components/` only ever *draw* what this file decides.
///
/// The rules that live here, and the constants that enforce them:
///
///  * **Every tap is answered.** [tapAt] never refuses, never queues and never
///    ignores. A tap on bare ground is a real destination with a real flump at
///    the end of it; a tap while he is already moving replaces the old one
///    instantly. There is nowhere on the screen that does nothing.
///  * **Nothing alive is ever sat on.** [_stepClear] moves anything alive away
///    from Neil from [clearRadius] out — which is far enough that a child never
///    even aims at one — at [clearSpeed], which is faster than Neil's fastest
///    heave. There is no branch in this file that lets a living thing be
///    squashed.
///  * **Nothing stays squashed.** The moment Neil moves off, a prop springs
///    back through [_springOmega]/[_springDamp] and is exactly at rest within
///    [springSettle] seconds. Nothing in this game can be left broken.
///  * **Nothing can be lost or missed.** A dot fills the first time Neil sits
///    on a given thing; sitting on it again is just as much fun and simply does
///    not fill one. Nothing is ever taken away, and there is no count of what
///    is left (CLAUDE.md §3).
///  * **The game waits, and waiting looks like something.** After
///    [idleBeforeSleep] with nothing touched, Neil dozes off by himself, and
///    any tap at all wakes him.
library;

import 'dart:math';

import 'town.dart';

/// One thing in the town, while the game is running.
class Prop {
  Prop({required this.kind, required TownSpot spot}) : spot = spot, home = spot;

  final PropKind kind;

  /// Where it is now. Mutable: anything alive moves itself clear of Neil.
  TownSpot spot;

  /// Where it started. Creatures drift back here once Neil is well away, so a
  /// town that has been walked all over settles back to the way it looked.
  final TownSpot home;

  /// How squashed it is: 0 at rest, 1 fully squashed ([PropKind.squashTo]), and
  /// **negative while it is springing back past its resting height**, which is
  /// what makes the springback read as elastic rather than as a reset.
  double squash = 0;

  /// Neil is on it right now.
  bool occupied = false;

  /// Seconds since Neil got off, while the spring is still ringing.
  double? releasedAt;

  /// How squashed it was at the moment he got off, which is what the spring
  /// rings down from — and how big a boing it is worth.
  double releasedFrom = 0;

  /// Whether sitting on this has ever filled a dot. Never shown on screen and
  /// never marked on the prop — the scope is explicit that nothing tells the
  /// child a thing is "used".
  bool visited = false;

  /// Seconds since it last answered the bellow (or was bumped), or null.
  double? answeredAt;

  /// Seconds since Neil last landed on it, for the one-off splash: seagulls out
  /// of the bin, spray from the hose, sand thrown up by a flop.
  double? floppedAt;

  /// Its resting height, once squashed. 1 = untouched, and above 1 while the
  /// spring overshoots.
  double get heightFactor =>
      (1 - squash * (1 - kind.squashTo)).clamp(0.05, 1.6);

  /// Answers the bellow, or a tap during the nap. Restarts every time: a child
  /// leaning on the button must see the dog answer every single press.
  void answer() => answeredAt = 0;

  void tick(double dt) {
    final answered = answeredAt;
    if (answered != null) {
      answeredAt = answered + dt;
      if (answeredAt! > 2.0) answeredAt = null;
    }
    final flopped = floppedAt;
    if (flopped != null) {
      floppedAt = flopped + dt;
      if (floppedAt! > 2.5) floppedAt = null;
    }

    if (occupied) {
      squash = min(1, squash + dt / NeilWorld.squashSeconds);
      return;
    }

    final since = releasedAt;
    if (since == null) return;
    final t = since + dt;
    releasedAt = t;
    if (t >= NeilWorld.springSettle) {
      // Exactly at rest, not merely close to it: "nothing stays squashed" is a
      // promise, and a prop left at 0.003 squashed forever would quietly break
      // it over a long play session.
      releasedAt = null;
      squash = 0;
      return;
    }
    // A damped oscillation: down through zero, past it (taller than rest), and
    // back. The overshoot is the whole point — it is what says "bouncy castle"
    // rather than "repaired".
    squash = releasedFrom *
        cos(NeilWorld._springOmega * t) *
        exp(-NeilWorld._springDamp * t);
  }

  void _release() {
    if (!occupied) return;
    occupied = false;
    releasedFrom = squash;
    releasedAt = 0;
  }
}

/// What Neil is doing.
enum NeilState {
  /// On his way somewhere. Heave, flump, heave, flump.
  galumphing,

  /// Arrived, and settled. The resting state, and the one he spends most of
  /// his life in.
  flopped,

  /// Fell asleep by himself because nobody touched anything. Any tap wakes him.
  dozing,

  /// The reward nap: a yawn, the town gathering, a bucket of fish, a snore and
  /// the celebration. Ends by itself — there is nothing to dismiss.
  napping,
}

/// The simulation. See the library doc for the rules it exists to keep.
class NeilWorld {
  NeilWorld({TownPlace? place, Random? random})
      : place = place ?? TownPlace.values.first,
        _random = random ?? Random() {
    _settleInto(this.place);
  }

  final Random _random;

  TownPlace place;

  final props = <Prop>[];

  /// Where Neil is, and where he is heading. They are the same thing when he
  /// is flopped.
  late TownSpot neil;
  late TownSpot target;

  NeilState state = NeilState.flopped;

  /// Which way he is pointing: 1 right, -1 left.
  double facing = 1;

  /// The heave-flump phase, 0..1, looping. Drives both his speed and how he is
  /// drawn, so the lurch you see is the lurch that moved him.
  double cycle = 0;

  /// Seconds since he landed, while the flop is still settling.
  double flopT = 999;

  /// Seconds into the nap, or null.
  double? napT;

  /// Seconds into a doze, or null.
  double? dozeT;

  /// 0..1 — how much he is being rubbed right now. Decays when the finger
  /// stops.
  double rubbing = 0;

  /// 0..1 — a wriggle that outlasts the rub, so he stays floppy for a moment
  /// after the finger lifts.
  double wriggle = 0;

  /// How many dots are filled.
  int dotsFilled = 0;

  /// What he is sitting on, if anything.
  Prop? sittingOn;

  double _sinceTouch = 0;
  double _sinceRubCue = 0;
  double _sinceDozeSnore = 0;
  int _bellows = 0;

  final _round = <_Answer>[];

  // --- the numbers ---------------------------------------------------------

  /// How fast Neil averages, in town-widths per second.
  ///
  /// **He is the slowest thing in the app on purpose.** A quarter of the town
  /// per second is four seconds to cross the whole screen, which is the
  /// scope's starting point — slow enough that his weight is the joke, and the
  /// redirect is always available so nobody is ever stuck watching him.
  ///
  /// Named as an open question in the scope, because only a child settles where
  /// funny-slow turns into boring-slow. A test pins the crossing time so that
  /// changing this number is a deliberate act rather than a drift.
  static const double galumphSpeed = 0.25;

  /// The heave. He surges for the first [_push] of each cycle and coasts for
  /// the rest — heave, flump, heave, flump.
  static const double _push = 0.40;
  static const double _heave = 1.6;
  static const double _coast = 0.12;

  /// Cycles per second. About one heave a second: any faster and he reads as
  /// scurrying, which is the one thing he must never do.
  static const double cadence = 1.05;

  /// The shape of the heave at [phase] through a cycle.
  static double surgeAt(double phase) {
    final p = phase % 1.0;
    return p < _push ? 1 + _heave * sin(p / _push * pi) : _coast;
  }

  /// The mean of [surgeAt] over one cycle, worked out rather than measured, so
  /// that [galumphSpeed] means the speed he actually averages instead of a
  /// number the rhythm quietly scales. Pinned by a test against the real curve.
  static final double surgeMean =
      _push + _heave * _push * 2 / pi + (1 - _push) * _coast;

  /// The fastest he can ever move — the top of the heave.
  static final double maxSpeed = galumphSpeed * (1 + _heave) / surgeMean;

  /// How close counts as arrived.
  static const double arriveRadius = 0.015;

  /// How long the flop takes to settle.
  static const double flopSeconds = 0.55;

  /// How far out something alive notices Neil and starts moving clear.
  ///
  /// Deliberately enormous — a fifth of the town, and several times his own
  /// length. By the time a child has decided to aim at the wallaby, the wallaby
  /// has already hopped somewhere else, so **the child never even gets to aim
  /// at one** (the scope: *nothing alive is ever squashed*). It watches his
  /// target as well as his position, so it is already moving before he sets
  /// off.
  static const double clearRadius = 0.22;

  /// How fast something alive gets clear. Faster than [maxSpeed], so it can
  /// always get away however he is chased — the same guarantee Car Trip gives
  /// its ducks. Pinned by a test.
  static const double clearSpeed = 0.85;

  /// How fast a creature drifts back to where it was once he is well away.
  static const double _returnSpeed = 0.12;

  /// How long a prop takes to squash flat under him.
  static const double squashSeconds = 0.22;

  /// The springback: a ring at [_springOmega] rad/s dying at [_springDamp],
  /// exactly at rest after [springSettle].
  static const double _springOmega = 13.0;
  static const double _springDamp = 4.5;
  static const double springSettle = 1.4;

  /// New things sat on per nap. Five, against seven or eight floppable things
  /// in every location — so the nap always arrives, and there is always
  /// something left un-sat-on. Nothing in this game is a set to complete.
  static const int dotsPerNap = 5;

  /// How long everything has to be left alone before he dozes off by himself.
  static const double idleBeforeSleep = 14;

  /// How often he snores while dozing. Long gaps: this is the game waiting,
  /// and waiting must not nag.
  static const double _dozeSnoreEvery = 6.5;

  /// The nap, beat by beat. A show, not a wait: something happens every second
  /// or so, and it ends by itself with nothing to dismiss.
  static const double _yawnAt = 0.0;
  static const double gatherAt = 1.4;
  static const double fishAt = 2.2;
  static const double snoreAt = 2.9;
  static const double celebrateAt = 3.4;
  static const double napSeconds = 5.2;

  /// How close the town comes while he sleeps. They gather round, but not on
  /// top of him.
  static const double _gatherRadius = 0.20;

  // --- callbacks the game listens to ---------------------------------------

  /// He landed. [onto] is what he landed on, or null for bare ground — which
  /// is still a flump, a puff of dust and a contented wobble.
  void Function(Prop? onto)? onFlop;

  /// Something got sat on. [isNew] is whether it filled a dot.
  void Function(Prop prop, bool isNew)? onSquash;

  /// Something he was sitting on started springing back.
  void Function(Prop prop)? onSpringBack;

  /// He is being rubbed and is enjoying it audibly. Fires occasionally rather
  /// than every frame.
  void Function()? onRubDelight;

  /// One voice of the town answering the bellow, in the order the round landed.
  void Function(Prop prop)? onAnswer;

  /// He dozed off by himself, and woke up again.
  void Function()? onDoze;
  void Function()? onWake;

  /// The nap: it began, he started snoring, the confetti, and waking up
  /// somewhere new.
  void Function()? onNapBegin;
  void Function()? onSnore;
  void Function()? onCelebrate;
  void Function(TownPlace place)? onWakeElsewhere;

  // --- what the child does -------------------------------------------------

  /// Send Neil to a place in the town.
  ///
  /// **Never refused.** Not while he is walking, not while he is asleep, not
  /// while he is mid-flop. A new tap replaces the old destination in the same
  /// frame, because a child who taps and sees nothing change has been told the
  /// game is ignoring them (CLAUDE.md §3), and "he never has to finish a trip"
  /// is what makes the control feel like his own.
  ///
  /// If a floppable thing is near enough to the tap, he is sent to *that* —
  /// [PropKind.tapReach] is far larger than the art, so "tap the car" needs no
  /// aim at all. Anything alive is deliberately never snapped to: it is already
  /// getting out of the way.
  void tapAt(TownSpot where) {
    _sinceTouch = 0;

    if (state == NeilState.napping) {
      // The celebration is playing and he is asleep — but a tap must still do
      // something, so the town he has gathered around him answers instead.
      _bumpNearest(where);
      return;
    }

    if (state == NeilState.dozing) {
      dozeT = null;
      onWake?.call();
    }

    target = _snap(where);
    facing = target.x >= neil.x ? 1 : -1;
    // He may be leaving something he was sitting on. It springs back whether or
    // not he actually goes anywhere.
    _standUp();
    state = NeilState.galumphing;
  }

  /// A finger is moving over Neil. He wriggles, kicks a back flipper and flings
  /// sand about.
  ///
  /// It has no purpose, fills no dot and changes nothing — and it is probably
  /// the reason a child comes back to this game. It deliberately does **not**
  /// interrupt a trip: rubbing him on the way somewhere is a perfectly good
  /// thing to want to do, and stopping him for it would make the control feel
  /// like it is being taken away.
  void rub() {
    _sinceTouch = 0;
    if (state == NeilState.dozing) {
      dozeT = null;
      onWake?.call();
      state = NeilState.flopped;
    }
    rubbing = min(1, rubbing + 0.12);
    wriggle = 1;
  }

  /// The bellow button. Does nothing to the game — and then the town answers,
  /// one voice after another, in an order it has never been in before.
  ///
  /// This is what keeps it from being Car Trip's horn with different art: that
  /// one makes things wave, this one starts a round.
  void bellow() {
    _sinceTouch = 0;
    if (state == NeilState.dozing) {
      dozeT = null;
      onWake?.call();
      state = NeilState.flopped;
    }
    _bellows++;

    // A fresh round every press, so leaning on the button restarts it rather
    // than stacking up — and so the order is never twice the same.
    _round.clear();
    final voices = props.where((p) => !p.kind.isFloppable).toList()
      ..shuffle(_random);
    var at = 0.30;
    for (final prop in voices) {
      _round.add(_Answer(prop, at));
      at += 0.26 + _random.nextDouble() * 0.24;
    }
  }

  /// How many times the bellow has been pressed, so the cue alternates between
  /// its variants.
  int get bellows => _bellows;

  // --- the simulation ------------------------------------------------------

  void update(double dt) {
    if (dt <= 0) return;

    for (final prop in props) {
      prop.tick(dt);
      final since = prop.releasedAt;
      // The frame the spring starts is the frame the boing plays.
      if (since != null && since <= dt) onSpringBack?.call(prop);
    }

    _runRound(dt);
    _moveCreatures(dt);
    _fade(dt);

    switch (state) {
      case NeilState.galumphing:
        _galumph(dt);
      case NeilState.flopped:
        flopT += dt;
        _sinceTouch += dt;
        if (_sinceTouch >= idleBeforeSleep) {
          state = NeilState.dozing;
          dozeT = 0;
          _sinceDozeSnore = 0;
          onDoze?.call();
        }
      case NeilState.dozing:
        dozeT = (dozeT ?? 0) + dt;
        // He snores gently until somebody comes back. Spaced right out: the
        // game waiting should look and sound like something, not nag.
        _sinceDozeSnore += dt;
        if (_sinceDozeSnore >= _dozeSnoreEvery) {
          _sinceDozeSnore = 0;
          onSnore?.call();
        }
      case NeilState.napping:
        _nap(dt);
    }
  }

  void _galumph(double dt) {
    cycle = (cycle + dt * cadence) % 1.0;
    flopT += dt;
    _sinceTouch += dt;

    final togo = townDistance(neil, target);
    if (togo <= arriveRadius) {
      _land();
      return;
    }

    final step = galumphSpeed * surgeAt(cycle) / surgeMean * dt;
    if (step >= togo) {
      neil = target;
      _land();
      return;
    }

    // The step is measured in the same metric as the distance, so a trip
    // straight up the beach takes as long as it looks like it should.
    final dx = target.x - neil.x;
    final dy = (target.y - neil.y) * depthToWidth;
    final scale = step / togo;
    neil = TownSpot(neil.x + dx * scale, neil.y + dy * scale / depthToWidth)
        .clamped;
  }

  /// He arrives. Something is squashed, or nothing is — and either way there is
  /// a flump, because **there is no dead tap**.
  void _land() {
    state = NeilState.flopped;
    flopT = 0;
    // The rhythm restarts from the top, so the next trip begins with a heave
    // rather than halfway through a coast.
    cycle = 0;

    final landedOn = <Prop>[];
    final wasNew = <bool>[];
    for (final prop in props) {
      // The only place a prop is ever squashed, and it can only ever be a
      // floppable one. There is deliberately no branch here for anything alive.
      if (!prop.kind.isFloppable) continue;
      if (townDistance(prop.spot, neil) > prop.kind.reach) continue;

      prop.occupied = true;
      prop.releasedAt = null;
      prop.floppedAt = 0;
      landedOn.add(prop);
      // Sitting on the same car twice is exactly as much fun; it simply does
      // not fill a shell, and nothing anywhere says so.
      wasNew.add(!prop.visited);
      prop.visited = true;
    }

    final fresh = wasNew.where((n) => n).length;

    // The dots are counted before anything is announced, so the rising chime
    // the game plays on [onSquash] is already at the right rung: the sound has
    // to say "nearly there" in the same instant the shell fills.
    if (fresh > 0) dotsFilled = min(dotsPerNap, dotsFilled + fresh);

    sittingOn = landedOn.isEmpty ? null : landedOn.first;
    onFlop?.call(sittingOn);
    for (var i = 0; i < landedOn.length; i++) {
      onSquash?.call(landedOn[i], wasNew[i]);
    }

    if (dotsFilled >= dotsPerNap) _beginNap();
  }

  /// Whatever he was sitting on springs back.
  void _standUp() {
    for (final prop in props) {
      prop._release();
    }
    sittingOn = null;
  }

  void _fade(double dt) {
    // The rub decays when the finger stops, and the wriggle outlasts it, so he
    // stays floppy for a beat rather than snapping back to attention.
    rubbing = max(0, rubbing - dt * 2.2);
    wriggle = max(0, wriggle - dt * 0.9);

    if (rubbing > 0.2) {
      _sinceRubCue += dt;
      if (_sinceRubCue > 0.45) {
        _sinceRubCue = 0;
        onRubDelight?.call();
      }
    } else {
      _sinceRubCue = 0;
    }
  }

  /// Everything alive gets itself out of the way, and wanders back afterwards.
  ///
  /// There is no branch anywhere in this file that lets Neil land on one. This
  /// is the same rule as Car Trip's, for the same reason: a five-year-old does
  /// not hold "funny in a game" and "appalling in life" apart, so the game
  /// never offers the choice.
  void _moveCreatures(double dt) {
    for (final prop in props) {
      if (prop.kind.nature != PropNature.alive) continue;

      // While he sleeps the town comes in to watch instead of keeping clear.
      if (state == NeilState.napping && (napT ?? 0) >= gatherAt) {
        _drawNear(prop, dt);
        continue;
      }

      final threatened = townDistance(prop.spot, neil) < clearRadius ||
          townDistance(prop.spot, target) < clearRadius;
      if (threatened) {
        _stepClear(prop, dt);
      } else if (townDistance(prop.spot, prop.home) > 0.004) {
        _walk(prop, prop.home, _returnSpeed * dt);
      }
    }
  }

  void _stepClear(Prop prop, double dt) {
    final step = clearSpeed * dt;
    final before = townDistance(prop.spot, neil);

    var next = _awayStep(prop.spot, neil, step);
    if (townDistance(next, neil) <= before) {
      // Backed into a corner of the town. Slide along the edge rather than
      // pressing into it — a creature that got stuck against the edge with Neil
      // coming would eventually be sat on, which cannot be allowed to happen.
      next = _sideStep(prop.spot, neil, step);
    }
    prop.spot = next;
  }

  /// One step directly away from [from].
  TownSpot _awayStep(TownSpot spot, TownSpot from, double step) {
    var dx = spot.x - from.x;
    var dy = spot.y - from.y;
    if (dx.abs() < 1e-6 && dy.abs() < 1e-6) {
      // Exactly on top of each other (only reachable by a test placing them
      // there): pick a direction rather than dividing by zero.
      dx = 1;
      dy = 0;
    }
    final len = sqrt(dx * dx + dy * dy * depthToWidth * depthToWidth);
    return TownSpot(
      spot.x + dx / len * step,
      spot.y + dy / len * step / depthToWidth,
    ).clampedForCreature;
  }

  /// One step at right angles, toward the middle of the town — the way out of a
  /// corner.
  TownSpot _sideStep(TownSpot spot, TownSpot from, double step) {
    final dx = spot.x - from.x;
    final dy = spot.y - from.y;
    // Perpendicular, taken toward the town's middle so it never slides further
    // into the corner it is already in.
    var px = -dy;
    var py = dx;
    if ((0.5 - spot.x) * px + (0.5 - spot.y) * py < 0) {
      px = -px;
      py = -py;
    }
    final len = sqrt(px * px + py * py * depthToWidth * depthToWidth);
    if (len < 1e-6) return spot;
    return TownSpot(
      spot.x + px / len * step,
      spot.y + py / len * step / depthToWidth,
    ).clampedForCreature;
  }

  /// The town gathering round the sleeping seal — close, but not on him.
  void _drawNear(Prop prop, double dt) {
    final away = townDistance(prop.spot, neil);
    if (away <= _gatherRadius) return;
    // Never further than the edge of the circle they are gathering on, whatever
    // the frame length: they come to watch him sleep, not to stand on him.
    final step = min(_returnSpeed * 2.4 * dt, away - _gatherRadius);
    if (step <= 0) return;
    _walk(prop, neil, step);
  }

  void _walk(Prop prop, TownSpot towards, double step) {
    final togo = townDistance(prop.spot, towards);
    if (togo <= step || togo <= 1e-6) {
      prop.spot = towards;
      return;
    }
    final scale = step / togo;
    prop.spot = TownSpot(
      prop.spot.x + (towards.x - prop.spot.x) * scale,
      prop.spot.y + (towards.y - prop.spot.y) * scale,
    ).clampedForCreature;
  }

  void _runRound(double dt) {
    if (_round.isEmpty) return;
    for (final answer in _round) {
      answer.at -= dt;
    }
    _round.removeWhere((answer) {
      if (answer.at > 0) return false;
      answer.prop.answer();
      onAnswer?.call(answer.prop);
      return true;
    });
  }

  // --- the nap -------------------------------------------------------------

  void _beginNap() {
    state = NeilState.napping;
    napT = _yawnAt;
    _standUp();
    target = neil;
    onNapBegin?.call();
  }

  void _nap(double dt) {
    final was = napT ?? 0;
    final now = was + dt;
    napT = now;

    if (was < snoreAt && now >= snoreAt) onSnore?.call();
    if (was < celebrateAt && now >= celebrateAt) onCelebrate?.call();
    if (now < napSeconds) return;

    // Somewhere new in town, everything fresh, nothing carried over. There is
    // no last location and no end to this — it simply goes round again.
    final next = place.next;
    dotsFilled = 0;
    _settleInto(next);
    state = NeilState.flopped;
    napT = null;
    flopT = 0;
    _sinceTouch = 0;
    onWakeElsewhere?.call(next);
  }

  /// The nearest thing that can answer, bumped. Used for taps during the nap,
  /// so that even then there is nowhere on screen that does nothing.
  void _bumpNearest(TownSpot where) {
    Prop? best;
    var bestAway = double.infinity;
    for (final prop in props) {
      if (prop.kind.isFloppable) continue;
      final away = townDistance(prop.spot, where);
      if (away < bestAway) {
        bestAway = away;
        best = prop;
      }
    }
    if (best == null) return;
    best.answer();
    onAnswer?.call(best);
  }

  // --- setting up ----------------------------------------------------------

  void _settleInto(TownPlace next) {
    place = next;
    props
      ..clear()
      ..addAll(next.layout.map((p) => Prop(kind: p.kind, spot: p.spot)));
    neil = next.start;
    target = next.start;
    sittingOn = null;
    cycle = 0;
    rubbing = 0;
    wriggle = 0;
    dozeT = null;
    _round.clear();
  }

  /// Where a tap actually sends him: the nearest floppable thing within its
  /// [PropKind.tapReach], or the tapped spot itself.
  TownSpot _snap(TownSpot where) {
    Prop? best;
    var bestAway = double.infinity;
    for (final prop in props) {
      if (!prop.kind.isFloppable) continue;
      final away = townDistance(prop.spot, where);
      if (away > prop.kind.tapReach || away >= bestAway) continue;
      bestAway = away;
      best = prop;
    }
    // Snapping to the prop's own spot — not merely near it — is what guarantees
    // the flop actually squashes it: zero is inside every reach.
    return (best?.spot ?? where).clamped;
  }

  /// The things Neil could still sit on for the first time here. Not shown to
  /// the child anywhere — this exists for the tests that check a nap is always
  /// reachable.
  int get unvisitedFloppables =>
      props.where((p) => p.kind.isFloppable && !p.visited).length;
}

class _Answer {
  _Answer(this.prop, this.at);

  final Prop prop;

  /// Seconds until this voice answers.
  double at;
}
