import 'package:flutter/services.dart';

/// A tiny physical answer to what the child just did.
///
/// Why this exists: at five, the finger is ahead of the eye. A pop the hand can
/// *feel* lands even when the child is looking at the next balloon, and it
/// reinforces "that worked" without adding anything to the screen or the mix.
///
/// Rules this keeps (CLAUDE.md §3):
///  * Only ever the LIGHT end of the scale. A heavy buzz is startling, and a
///    long vibration reads as an alarm.
///  * Never used for a mistake. There is no haptic on the wobble cue — a
///    physical jolt after a wrong tap is punishment, however small.
///  * Entirely optional. Every call is fire-and-forget and swallows failure:
///    desktop, the simulator and tablets without a vibrator simply do nothing,
///    and a game must never depend on it.
class KidHaptics {
  const KidHaptics._();

  /// A balloon popped. The smallest impact the platform offers.
  static void pop() => _fireAndForget(HapticFeedback.lightImpact);

  /// The celebration. One step up, once every ten pops — still not a jolt.
  static void celebrate() => _fireAndForget(HapticFeedback.mediumImpact);

  /// A button. The same tick the OS uses for a picker, so it feels native.
  static void tap() => _fireAndForget(HapticFeedback.selectionClick);

  static void _fireAndForget(Future<void> Function() action) {
    try {
      // Errors arrive asynchronously (no vibrator, no platform channel), so
      // both paths have to be swallowed.
      action().catchError((Object _) {});
    } catch (_) {
      // Ignored on purpose — see the class doc.
    }
  }
}
