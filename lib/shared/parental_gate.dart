import 'package:flutter/material.dart';

import 'kid_palette.dart';

/// The check that separates the child's app from the adult's.
///
/// Required by Apple's Kids Category and Google Play Families: anything leading
/// out of the child's experience (settings, external links, purchases) must sit
/// behind a barrier a child cannot pass.
///
/// The mechanism is a **3-second deliberate hold**, with written instructions.
///
/// THE TEXT IS THE BARRIER — do not "improve" this screen by replacing the
/// instructions with icons. Everywhere else in this app text is forbidden
/// because the player cannot read; here that is exactly the point. A
/// five-year-old cannot follow a written instruction they cannot read, and
/// cannot sustain a deliberate 3-second hold on a target they don't understand.
///
/// This is not a security boundary against a determined older child; it is a
/// deliberate-action check, which is what the store programmes actually ask for.
class ParentalGate {
  const ParentalGate._();

  /// How long the adult must hold. 3s is the common convention — long enough to
  /// be deliberate, short enough that an adult doesn't think it's broken.
  static const holdDuration = Duration(seconds: 3);

  /// Shows the gate. Calls [onPass] only if the hold completes.
  ///
  /// Route every protected destination through here, so a future screen cannot
  /// accidentally skip the gate.
  static Future<void> guard(
    BuildContext context, {
    required VoidCallback onPass,
  }) async {
    final passed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _ParentalGateDialog(),
    );
    if (passed ?? false) {
      onPass();
    }
  }
}

class _ParentalGateDialog extends StatefulWidget {
  const _ParentalGateDialog();

  @override
  State<_ParentalGateDialog> createState() => _ParentalGateDialogState();
}

class _ParentalGateDialogState extends State<_ParentalGateDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: ParentalGate.holdDuration,
  )..addStatusListener((status) {
    if (status == AnimationStatus.completed && mounted) {
      Navigator.of(context).pop(true);
    }
  });

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startHold() => _controller.forward();

  /// Released early: drain back down rather than snapping to zero, so a child
  /// who tried sees something gentle happen rather than a rejection.
  void _cancelHold() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Grown-ups only',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: KidPalette.ink,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Press and hold the button for 3 seconds.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: KidPalette.ink),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              // Hold begins on press and is cancelled the moment the finger
              // lifts or slides off.
              onTapDown: (_) => _startHold(),
              onTapUp: (_) => _cancelHold(),
              onTapCancel: _cancelHold,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return SizedBox(
                    width: 110,
                    height: 110,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // The filling ring: the adult's feedback that the hold
                        // is working and how much is left.
                        SizedBox(
                          width: 110,
                          height: 110,
                          child: CircularProgressIndicator(
                            value: _controller.value,
                            strokeWidth: 8,
                            backgroundColor: const Color(0xFFE0E0E0),
                            valueColor: const AlwaysStoppedAnimation(
                              KidPalette.parentGrey,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 44,
                          color: KidPalette.parentGrey,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              // Always available: a child who opened this by accident must be
              // able to get out.
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
