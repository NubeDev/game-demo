import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'games/balloon_pop/balloon_pop_screen.dart';
import 'games/blast_off/blast_off_screen.dart';
import 'games/car_trip/car_trip_screen.dart';
import 'games/cat_run/cat_run_screen.dart';
import 'games/crystal_party/crystal_party_screen.dart';
import 'games/dress_the_dog/dress_the_dog_screen.dart';
import 'games/neil_the_seal/neil_the_seal_screen.dart';
import 'games/quacky_the_duck/quacky_the_duck_screen.dart';
import 'menu/home_screen.dart';
import 'settings/settings_screen.dart';

/// Every route in the app, in one file.
///
/// Keeping them all here is also how we check that nothing reaches a
/// parent-only destination without passing the parental gate: `/settings` is
/// only ever pushed from `ParentalGate.guard` (CLAUDE.md §4).
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(key: Key('home')),
      routes: [
        GoRoute(
          path: 'balloon-pop',
          builder: (context, state) =>
              const BalloonPopScreen(key: Key('balloon pop')),
        ),
        GoRoute(
          path: 'blast-off',
          builder: (context, state) =>
              const BlastOffScreen(key: Key('blast off')),
        ),
        GoRoute(
          path: 'car-trip',
          builder: (context, state) =>
              const CarTripScreen(key: Key('car trip')),
        ),
        GoRoute(
          path: 'cat-run',
          builder: (context, state) => const CatRunScreen(key: Key('cat run')),
        ),
        GoRoute(
          path: 'crystal-party',
          builder: (context, state) =>
              const CrystalPartyScreen(key: Key('crystal party')),
        ),
        GoRoute(
          path: 'dress-the-dog',
          builder: (context, state) =>
              const DressTheDogScreen(key: Key('dress the dog')),
        ),
        GoRoute(
          path: 'neil-the-seal',
          builder: (context, state) =>
              const NeilTheSealScreen(key: Key('neil the seal')),
        ),
        GoRoute(
          path: 'quacky-the-duck',
          builder: (context, state) =>
              const QuackyTheDuckScreen(key: Key('quacky the duck')),
        ),
        GoRoute(
          path: 'settings',
          builder: (context, state) =>
              const SettingsScreen(key: Key('settings')),
        ),
      ],
    ),
  ],
);
