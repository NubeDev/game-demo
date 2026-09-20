import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../audio/audio_controller.dart';
import '../audio/songs.dart';
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

/// How many games are on the menu. The tiles shrink to fit this many across.
const int _games = 4;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AudioController>().playSong(Songs.menu);
  }

  @override
  Widget build(BuildContext context) {
    final sounds = KidSounds(context.read<AudioController>());

    return Scaffold(
      backgroundColor: KidPalette.menuBackground,
      body: SafeArea(
        child: Stack(
          children: [
            // One row, every game visible at once, no scrolling — so the
            // tiles shrink to fit rather than the row growing a scrollbar a
            // five-year-old would never find (CLAUDE.md §3). They never go
            // below GameTile.minSize.
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 24.0;
                const sidePadding = 32.0;
                final room =
                    constraints.maxWidth - sidePadding * 2 - gap * (_games - 1);
                final tile = (room / _games)
                    .clamp(GameTile.minSize, GameTile.defaultSize)
                    // Never taller than the screen either: a landscape phone
                    // is short, not narrow.
                    .clamp(GameTile.minSize, constraints.maxHeight - 32);

                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: sidePadding,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GameTile(
                          icon: Icons.celebration_rounded,
                          color: KidPalette.playColors[0],
                          size: tile,
                          onTap: () {
                            sounds.tap();
                            GoRouter.of(context).go('/balloon-pop');
                          },
                        ),
                        const SizedBox(width: gap),
                        GameTile(
                          icon: Icons.directions_run_rounded,
                          color: KidPalette.playColors[3],
                          size: tile,
                          onTap: () {
                            sounds.tap();
                            GoRouter.of(context).go('/cat-run');
                          },
                        ),
                        const SizedBox(width: gap),
                        GameTile(
                          icon: Icons.pets_rounded,
                          color: KidPalette.playColors[4],
                          size: tile,
                          onTap: () {
                            sounds.tap();
                            GoRouter.of(context).go('/dress-the-dog');
                          },
                        ),
                        const SizedBox(width: gap),
                        GameTile(
                          icon: Icons.rocket_launch_rounded,
                          color: KidPalette.playColors[1],
                          size: tile,
                          onTap: () {
                            sounds.tap();
                            GoRouter.of(context).go('/blast-off');
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
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
