import 'dart:math';

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

/// Every game on the menu, in a fixed order.
///
/// A list rather than a hand-written row, because with eight games the row has
/// to be able to become two rows on a small screen — and the layout below has
/// to know how many there are to work that out. The ORDER never changes: no
/// "recently played", no reordering, because predictability is the feature.
const _games = <_MenuGame>[
  _MenuGame(
    icon: Icons.celebration_rounded,
    colorIndex: 0,
    route: '/balloon-pop',
  ),
  _MenuGame(
    icon: Icons.directions_run_rounded,
    colorIndex: 3,
    route: '/cat-run',
  ),
  _MenuGame(icon: Icons.pets_rounded, colorIndex: 4, route: '/dress-the-dog'),
  _MenuGame(
    icon: Icons.directions_car_rounded,
    colorIndex: 5,
    route: '/car-trip',
  ),
  _MenuGame(
    // A seal is not in the Material set; a wave is the nearest thing that
    // reads as "the seaside" to a child who cannot read the name.
    icon: Icons.waves_rounded,
    colorIndex: 2,
    route: '/neil-the-seal',
  ),
  _MenuGame(
    // A unicorn is not in the Material set either. Sparkles are the nearest
    // thing that reads as "crystals and magic" to a child who cannot read.
    icon: Icons.auto_awesome_rounded,
    colorIndex: 6,
    route: '/crystal-party',
  ),
  _MenuGame(
    icon: Icons.rocket_launch_rounded,
    colorIndex: 1,
    route: '/blast-off',
  ),
  _MenuGame(
    // A duck is not in the Material set. An egg is the nearest thing that
    // reads as "a bird" to a child who cannot read the name — and it is
    // unmistakably not any of the other seven shapes, which is the job the
    // icon actually has to do here.
    icon: Icons.egg_rounded,
    colorIndex: 7,
    route: '/quacky-the-duck',
  ),
];

/// One tile's worth of menu. Not a class a child ever sees — it exists so the
/// layout can count the games and wrap them.
class _MenuGame {
  const _MenuGame({
    required this.icon,
    required this.colorIndex,
    required this.route,
  });

  final IconData icon;

  /// Which of [KidPalette.playColors] this tile is.
  final int colorIndex;

  final String route;
}

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

  Widget _tile(
    BuildContext context,
    KidSounds sounds,
    _MenuGame game,
    double size,
  ) {
    return GameTile(
      icon: game.icon,
      color: KidPalette.playColors[game.colorIndex],
      size: size,
      onTap: () {
        sounds.tap();
        GoRouter.of(context).go(game.route);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sounds = KidSounds(context.read<AudioController>());

    return Scaffold(
      backgroundColor: KidPalette.menuBackground,
      body: SafeArea(
        child: Stack(
          children: [
            // Every game visible at once, no scrolling — the tiles shrink
            // to fit rather than the row growing a scrollbar a five-year-old
            // would never find (CLAUDE.md §3), and they never go below
            // GameTile.minSize.
            LayoutBuilder(
              builder: (context, constraints) {
                final layout = _MenuLayout.fit(
                  count: _games.length,
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                );

                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var row = 0; row < layout.rows.length; row++) ...[
                        if (row > 0) SizedBox(height: layout.gap),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < layout.rows[row].length; i++)
                              ...[
                                if (i > 0) SizedBox(width: layout.gap),
                                _tile(
                                  context,
                                  sounds,
                                  layout.rows[row][i],
                                  layout.tile,
                                ),
                              ],
                          ],
                        ),
                      ],
                    ],
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

/// How the tiles are laid out on this screen: how big, and in how many rows.
///
/// Pulled out and made pure so **the kid rule it protects is testable without
/// pumping a widget**: a touch target below 80×80 is one a five-year-old misses
/// (CLAUDE.md §3), and this class exists to guarantee every tile clears it on
/// every screen the app ships to.
///
/// ## Why this is no longer just a row
///
/// With six games a single row fitted a small landscape phone once the spacing
/// gave way. **Seven does not** — at [GameTile.minSize] plus any gap at all, a
/// seven-wide row overflows a 640px-wide phone. The options were a smaller
/// tile (breaks the kid rule), a scrolling row (breaks "everything visible at
/// once" — a five-year-old does not know content exists off-screen), or a
/// second row. The second row is the only one that breaks nothing.
///
/// So: **one row while one row fits, two rows when it does not.** The tile
/// never shrinks below [GameTile.minSize], and nothing ever scrolls.
@immutable
class _MenuLayout {
  const _MenuLayout({required this.rows, required this.tile, required this.gap});

  /// The games, split into the rows they are drawn in.
  final List<List<_MenuGame>> rows;

  /// The edge of every tile. Identical across rows — a grid of different sizes
  /// would read as some games being more important than others.
  final double tile;

  final double gap;

  /// Roomy spacing, when there is room for it.
  static const maxGap = 24.0;
  static const maxPad = 32.0;

  /// Work out the biggest layout that fits, preferring a single row.
  static _MenuLayout fit({
    required int count,
    required double width,
    required double height,
  }) {
    // One row first, because one row is the most readable thing for a child:
    // no wrapping to follow, and the game they want is always in the same
    // place left to right.
    for (final rowCount in [1, 2]) {
      final perRow = (count / rowCount).ceil();
      // The tallest tile this many rows can be, and the widest this many
      // across can be — whichever is smaller.
      final byHeight =
          (height - maxPad - maxGap * (rowCount - 1)) / rowCount;
      final byWidth = (width - maxPad * 2 - maxGap * (perRow - 1)) / perRow;
      final tile = [byHeight, byWidth, GameTile.defaultSize].reduce(min);
      if (tile >= GameTile.minSize) {
        return _MenuLayout(
          rows: _split(count, rowCount),
          tile: tile,
          gap: maxGap,
        );
      }
    }

    // Neither fits at full spacing. **The spacing gives way, never the tile**:
    // 88 is the kid-rule floor, and a narrower gap is still a gap.
    const rowCount = 2;
    final perRow = (count / rowCount).ceil();
    // Two pixels of slack, so a rounding error cannot become an overflow
    // stripe on a child's screen.
    final spare = width - GameTile.minSize * perRow - 2;
    final gap = (spare / (perRow + 1)).clamp(0.0, maxGap);
    return _MenuLayout(
      rows: _split(count, rowCount),
      tile: GameTile.minSize,
      gap: gap,
    );
  }

  /// Split [count] games into [rowCount] rows, fullest row first — so a
  /// seven-game menu is four above three, which centres neatly and keeps the
  /// first row the one the eye lands on.
  static List<List<_MenuGame>> _split(int count, int rowCount) {
    final perRow = (count / rowCount).ceil();
    return [
      for (var i = 0; i < count; i += perRow)
        _games.sublist(i, min(i + perRow, count)),
    ];
  }
}
