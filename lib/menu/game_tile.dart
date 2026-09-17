import 'dart:math';

import 'package:flutter/material.dart';

import '../shared/kid_palette.dart';

/// One big picture button on the menu.
///
/// Sized far above the 80x80 minimum — on a landscape tablet this is roughly
/// palm-sized, which is what a five-year-old actually aims with.
class GameTile extends StatefulWidget {
  const GameTile({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
    this.comingSoon = false,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  /// Shown muted, and wobbles instead of navigating.
  final bool comingSoon;

  static const double size = 168;

  @override
  State<GameTile> createState() => _GameTileState();
}

class _GameTileState extends State<GameTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wobble = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void dispose() {
    _wobble.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.comingSoon) {
      // Gentle "not yet" — a wobble, never a scold.
      _wobble.forward(from: 0);
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.comingSoon
        ? Color.alphaBlend(Colors.white.withValues(alpha: 0.6), widget.color)
        : widget.color;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _wobble,
        builder: (context, child) {
          // A small left-right shake that settles: three swings, each one
          // smaller than the last.
          final t = _wobble.value;
          final offset = sin(t * pi * 6) * 10 * (1 - t);
          return Transform.translate(
            offset: Offset(offset, 0),
            child: child,
          );
        },
        child: Container(
          width: GameTile.size,
          height: GameTile.size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(
              color: KidPalette.ink.withValues(alpha: 0.25),
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: KidPalette.ink.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            widget.icon,
            size: 88,
            color: Colors.white.withValues(
              alpha: widget.comingSoon ? 0.65 : 1,
            ),
          ),
        ),
      ),
    );
  }
}
