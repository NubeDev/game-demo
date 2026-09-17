import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../audio/audio_controller.dart';
import '../shared/kid_palette.dart';
import '../shared/kid_sounds.dart';
import '../shared/parental_gate.dart';
import 'game_tile.dart';

/// The picture menu — the only place a child has to make a choice.
///
/// Rules this encodes (CLAUDE.md §3):
///  * NO TEXT anywhere a child looks. Not even the app title. Each game is an
///    icon and a colour.
///  * No scrolling. Everything visible at once; a five-year-old should not have
///    to discover that content exists off-screen.
///  * Same layout every time — no "recently played", no reordering.
///    Predictability is the feature.
///  * The settings cog is small, grey and adult-looking, and is gated.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sounds = KidSounds(context.read<AudioController>());

    return Scaffold(
      backgroundColor: KidPalette.menuBackground,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GameTile(
                      icon: Icons.celebration_rounded,
                      color: KidPalette.playColors[0],
                      onTap: () {
                        sounds.tap();
                        GoRouter.of(context).go('/balloon-pop');
                      },
                    ),
                    const SizedBox(width: 28),
                    // Coming soon. These respond to a tap with a wobble and a
                    // soft sound rather than doing nothing — a dead button
                    // teaches the child the screen is unreliable.
                    GameTile(
                      icon: Icons.category_rounded,
                      color: KidPalette.playColors[3],
                      comingSoon: true,
                      onTap: sounds.wobble,
                    ),
                    const SizedBox(width: 28),
                    GameTile(
                      icon: Icons.pets_rounded,
                      color: KidPalette.playColors[4],
                      comingSoon: true,
                      onTap: sounds.wobble,
                    ),
                  ],
                ),
              ),
            ),
            // The adult's door. Deliberately quiet: small, grey, cornered,
            // and behind the parental gate.
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                iconSize: 28,
                color: KidPalette.parentGrey,
                icon: const Icon(Icons.settings_rounded),
                onPressed: () => ParentalGate.guard(
                  context,
                  onPass: () => GoRouter.of(context).push('/settings'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
