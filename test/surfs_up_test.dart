import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:little_games/games/surfs_up/surf.dart';

const _dt = 1 / 60;

/// Runs [surf] for [seconds], collecting every event.
List<SurfEvent> _run(Surf surf, double seconds, {void Function(Surf)? each}) {
  final events = <SurfEvent>[];
  for (var t = 0.0; t < seconds; t += _dt) {
    each?.call(surf);
    surf.update(_dt);
    events.addAll(surf.drainEvents());
  }
  return events;
}

/// Ticks until [done] or [limit] seconds, so a test fails instead of hanging.
void _until(Surf surf, bool Function(Surf) done, {double limit = 120}) {
  for (var t = 0.0; t < limit; t += _dt) {
    if (done(surf)) return;
    surf.update(_dt);
  }
  fail('never got there: phase ${surf.phase}, waves ${surf.wavesCaught}');
}

void main() {
  group('a child who never taps', () {
    test('still rides every wave and reaches the party', () {
      final surf = Surf(random: Random(1));
      final events = _run(surf, 90);
      expect(events.where((e) => e == SurfEvent.helpedCatch).length,
          greaterThanOrEqualTo(Surf.wavesPerTrip));
      expect(events, contains(SurfEvent.party));
      expect(events, contains(SurfEvent.nextTrip));
      expect(surf.trip, greaterThanOrEqualTo(1));
    });

    test('is helped after exactly ${Surf.helpAfterMisses} misses', () {
      final surf = Surf(random: Random(1));
      final events = <SurfEvent>[];
      _until(surf, (s) {
        events.addAll(s.drainEvents());
        return s.phase == SurfPhase.poppingUp;
      });
      events.addAll(surf.drainEvents());
      expect(events.where((e) => e == SurfEvent.missed).length,
          Surf.helpAfterMisses);
      expect(events.last, SurfEvent.helpedCatch);
    });
  });

  test('a tap in the window catches the swell', () {
    final surf = Surf();
    _until(surf, (s) => s.inCatchWindow);
    surf.tap();
    expect(surf.phase, SurfPhase.poppingUp);
    expect(surf.drainEvents(), contains(SurfEvent.caught));
    expect(surf.helped, isFalse);
  });

  test('a tap too early is a paddle, and takes nothing away', () {
    final surf = Surf();
    _until(surf, (s) => s.incoming != null && !s.inCatchWindow);
    surf.drainEvents();
    surf.tap();
    expect(surf.phase, SurfPhase.paddling);
    expect(surf.drainEvents(), [SurfEvent.paddle]);
    expect(surf.missedRun, 0);
    // The same swell still arrives and can still be caught.
    _until(surf, (s) => s.inCatchWindow, limit: 5);
  });

  test('tapping as fast as possible never gets stuck', () {
    final surf = Surf(random: Random(2));
    final events = _run(surf, 120, each: (s) => s.tap());
    expect(events.where((e) => e == SurfEvent.nextTrip).length,
        greaterThanOrEqualTo(2));
  });

  test('a thousand random taps never get stuck either', () {
    final rng = Random(7);
    final surf = Surf(random: Random(3));
    final events = _run(surf, 300, each: (s) {
      if (rng.nextDouble() < 0.05) s.tap();
    });
    expect(events.where((e) => e == SurfEvent.nextTrip).length,
        greaterThanOrEqualTo(3));
  });

  group('riding', () {
    Surf riding() {
      final surf = Surf();
      _until(surf, (s) => s.inCatchWindow);
      surf.tap();
      _until(surf, (s) => s.phase == SurfPhase.riding);
      surf.drainEvents();
      return surf;
    }

    test('low shells are collected without a tap', () {
      final surf = riding();
      final lows = surf.shells.where((s) => !s.high).length;
      _until(surf, (s) => s.phase != SurfPhase.riding);
      expect(surf.shellsThisRide, lows);
      expect(surf.shells.where((s) => s.high),
          everyElement(isA<Shell>().having((s) => s.state, 'state',
              ShellState.passed)));
    });

    test('hopping on every chance collects every shell', () {
      final surf = riding();
      _until(surf, (s) {
        if (s.phase == SurfPhase.riding) s.tap();
        return s.phase != SurfPhase.riding;
      });
      expect(surf.shellsThisRide, Surf.shellsPerRide);
    });

    test('a hop timed at a high shell collects it', () {
      final surf = riding();
      final high = surf.shells.firstWhere((s) => s.high);
      // Start the hop so its peak is over the shell.
      final takeoff = high.x - Surf.rideSpeed * Surf.hopTime / 2;
      _until(surf, (s) => s.kokoX >= takeoff);
      surf.tap();
      _until(surf, (s) => s.kokoX > high.x + Surf.shellReach);
      expect(high.state, ShellState.collected);
    });

    test('a tap mid-hop is kept for the next hop, not dropped', () {
      final surf = riding();
      surf.tap();
      _until(surf, (s) => s.hopT! > Surf.hopTime - Surf.hopBuffer / 2);
      surf.tap();
      _until(surf, (s) => s.hopT == null || s.hopT! < 0.05, limit: 1);
      expect(surf.hopT, isNotNull);
    });
  });

  test('progress dots only ever go up within a trip', () {
    final surf = Surf(random: Random(4));
    var last = 0;
    var trip = 0;
    _run(surf, 120, each: (s) {
      if (s.trip != trip) {
        trip = s.trip;
        last = 0;
      }
      expect(s.wavesCaught, greaterThanOrEqualTo(last));
      expect(s.wavesCaught, lessThanOrEqualTo(Surf.wavesPerTrip));
      last = s.wavesCaught;
    });
  });

  test('the beach appears only on the last wave, under Koko at the end', () {
    final surf = Surf();
    _until(surf, (s) => s.shoreX != null);
    expect(surf.wavesCaught, Surf.wavesPerTrip - 1);
    _until(surf, (s) => s.phase == SurfPhase.party);
    // She ends up on the sand, not floating out at sea.
    expect(surf.kokoX, greaterThan(surf.shoreX!));
    expect(surf.sandHeight(surf.kokoX), greaterThan(surf.seaHeight(surf.kokoX)));
  });

  test('the next trip is swapped in behind a full veil', () {
    final surf = Surf();
    _until(surf, (s) => s.phase == SurfPhase.veil);
    var maxVeil = 0.0;
    _until(surf, (s) {
      maxVeil = max(maxVeil, s.veil);
      return s.trip == 1;
    });
    expect(maxVeil, greaterThan(0.95));
    expect(surf.shoreX, isNull);
    _until(surf, (s) => s.phase == SurfPhase.paddling, limit: 2);
    expect(surf.veil, 0);
  });
}
