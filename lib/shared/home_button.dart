import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'kid_palette.dart';

/// The way out of any game, identical everywhere.
///
/// Rules this encodes (see CLAUDE.md §3):
///  * Always the SAME corner in every game, so it is learned once.
///  * Big — well past the 80x80 minimum — because leaving must never need aim.
///  * A house icon, no text: the player cannot read.
///  * No confirmation dialog. A child cannot read "Are you sure?", and leaving
///    costs nothing because there is no score to lose.
class HomeButton extends StatelessWidget {
  const HomeButton({super.key, this.onPressed});

  /// Called before navigating home — e.g. to play a tap sound.
  final VoidCallback? onPressed;

  /// Generous: the whole button is the touch target.
  static const double size = 96;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Home',
      button: true,
      child: GestureDetector(
        onTap: () {
          onPressed?.call();
          GoRouter.of(context).go('/');
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            border: Border.all(color: KidPalette.ink, width: 4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.home_rounded,
            size: 52,
            color: KidPalette.ink,
          ),
        ),
      ),
    );
  }
}
