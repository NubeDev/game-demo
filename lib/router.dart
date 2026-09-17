import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'games/balloon_pop/balloon_pop_screen.dart';
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
          path: 'settings',
          builder: (context, state) =>
              const SettingsScreen(key: Key('settings')),
        ),
      ],
    ),
  ],
);
