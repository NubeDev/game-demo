import 'dart:async';
import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../../audio/audio_controller.dart';
import '../../audio/songs.dart';
import '../../shared/home_button.dart';
import '../../shared/kid_haptics.dart';
import '../../shared/kid_palette.dart';
import '../../shared/kid_sounds.dart';
import 'blast_off_game.dart';
import 'components/big_button.dart';
import 'countdown.dart';

/// Hosts [BlastOffGame] and the buttons around it.
///
/// The buttons are Flutter widgets over the game rather than Flame components,
/// so the home button is identical to every other game's and the rest match
/// its size and feel.
///
/// What is on screen depends only on [Countdown.phase], and each phase shows
/// as few things as possible:
///
///  * **waiting** — pick a length, and GO;
///  * **counting** — stop, and that is all; nothing must compete with the
///    count itself;
///  * **launched** — again, once the rocket has actually left.
///
/// The home button is present in all three (CLAUDE.md §3).
class BlastOffScreen extends StatefulWidget {
  const BlastOffScreen({super.key});

  /// The band at the bottom of the screen the buttons own, which the game
  /// grows its grass to cover so the rocket stands clear above it.
  ///
  /// Deliberately the SAME for every phase, taking the tallest control any
  /// phase can show. A per-phase inset would be tighter, but the ground — and
  /// the rocket standing on it — would visibly jump each time the phase
  /// changed. A screen that does not rearrange under a child's hands is worth
  /// more than the sky it costs (CLAUDE.md §3).
  ///
  /// It is also the same at every WIDTH, because the controls are always one
  /// row: when the row will not fit, the ± steppers drop out rather than the
  /// layout gaining a second line (see `_waitingControls`).
  ///
  /// Public so the layout test can check the scene against the same number the
  /// buttons are laid out with, rather than against a copy that can drift.
  static double controlsReserve(double width) {
    return _controlsBottomMargin +
        math.max(_goButtonSize, _againButtonSize) +
        _sceneBreathingRoom;
  }

  @override
  State<BlastOffScreen> createState() => _BlastOffScreenState();
}

class _BlastOffScreenState extends State<BlastOffScreen> {
  final Countdown _countdown = Countdown();
  late final BlastOffGame _game;

  /// How long the launch is left alone before the "again" button appears —
  /// long enough for the rocket to actually leave, short enough that a child
  /// who wants another one is not kept waiting.
  static const _againDelay = Duration(milliseconds: 1600);

  Timer? _againTimer;
  bool _againReady = false;

  @override
  void initState() {
    super.initState();
    context.read<AudioController>().playSong(Songs.play);
    _game = BlastOffGame(
      sounds: KidSounds(context.read<AudioController>()),
      countdown: _countdown,
      onLaunch: _armAgainButton,
    );
    _countdown.addListener(_onCountdownChanged);
  }

  @override
  void dispose() {
    _againTimer?.cancel();
    _countdown.removeListener(_onCountdownChanged);
    _countdown.dispose();
    super.dispose();
  }

  /// Rebuilds the controls when the countdown moves — but never *during* a
  /// build.
  ///
  /// The countdown is ticked by the Flame loop, and GameWidget runs that loop
  /// inside its own build. A listener that called setState straight from
  /// there throws "setState() or markNeedsBuild() called during build", which
  /// on a device is a red screen at the exact moment the rocket launches. So
  /// a change that arrives mid-frame is applied just after that frame
  /// instead; a change from a button press rebuilds immediately, as normal.
  void _onCountdownChanged() {
    if (!mounted) return;

    final phase = SchedulerBinding.instance.schedulerPhase;
    final midFrame =
        phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks;

    if (midFrame) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  /// Starts the wait for the "again" button. Called at the moment of launch.
  void _armAgainButton() {
    _againTimer?.cancel();
    _againReady = false;
    _againTimer = Timer(_againDelay, () {
      if (mounted) setState(() => _againReady = true);
    });
  }

  /// Clears it again, whenever a new countdown begins.
  ///
  /// This has to go through setState: the flag alone leaves the button on
  /// screen until something else happens to rebuild, and a stale "again"
  /// button sitting over a running countdown is both wrong and pressable.
  void _disarmAgainButton() {
    _againTimer?.cancel();
    if (_againReady) {
      setState(() => _againReady = false);
    }
  }

  KidSounds get _sounds => KidSounds(context.read<AudioController>());

  @override
  Widget build(BuildContext context) {
    _game.bottomInset = BlastOffScreen.controlsReserve(
      MediaQuery.sizeOf(context).width,
    );

    return Scaffold(
      body: Stack(
        // Every child here is positioned (or an AnimatedBuilder returning a
        // Positioned), and a Stack sizes itself to its NON-positioned
        // children — of which there are none, so it collapsed to 0x0 and took
        // the controls with it. The "again" button ended up zero-wide and
        // 174px above the top of the screen, unhittable: after a launch the
        // child was left on a screen with nothing to press but home, which
        // reads exactly like the game having crashed.
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: GameWidget(game: _game)),

          // Rebuilds only the controls when the countdown changes; the game
          // itself is driving its own frames.
          //
          // The AnimatedBuilder must be a DIRECT child of this Stack and must
          // itself return the Positioned. Wrapping it in an inner Stack gives
          // that Stack unbounded constraints, so it sizes to 0x0 and every
          // Positioned inside it collapses with it — which is how the "again"
          // button ended up 150px tall, zero wide and 174px above the top of
          // the screen, where nothing could hit it. It looked like a crash.
          _controls(context),

          Positioned(
            top: 20,
            right: 20,
            child: HomeButton(onPressed: _sounds.tap),
          ),

          // The adult's readout. See Countdown.clock for why this is the one
          // piece of child-facing text in the game, and why it is quiet.
          if (_countdown.phase != CountdownPhase.launched)
            Positioned(top: 26, left: 26, child: _ClockReadout(_countdown)),
        ],
      ),
    );
  }

  Widget _controls(BuildContext context) {
    return switch (_countdown.phase) {
      CountdownPhase.waiting => _waitingControls(),
      CountdownPhase.counting => _countingControls(),
      CountdownPhase.paused => _countingControls(),
      CountdownPhase.launched => _launchedControls(),
    };
  }

  /// Pick how long, then GO.
  ///
  /// Two ways to set the time, because a five-year-old and the adult next to
  /// them want different things:
  ///
  ///  * **three quick presets** — a short one, a middling one and a long one,
  ///    as pictures, for a child who just wants to go;
  ///  * **more and less**, stepping one rung at a time, for fine-tuning.
  ///
  /// Neither shows a number of minutes to read. The chosen length is shown as
  /// a ROW OF DOTS instead — more dots means a longer wait — which is the same
  /// trick the star jar plays during the count (CLAUDE.md §3).
  ///
  /// ## Why this stays on ONE row, always
  ///
  /// It used to wrap the presets onto a second row when the screen was narrow.
  /// That kept every button legal but made the control band 268px tall, and on
  /// an iPhone SE in landscape (375px) that leaves 107px of sky for a rocket
  /// that needs 171px — so the buttons were drawn over the rocket and took its
  /// taps. A second row is simply unaffordable on a short screen.
  ///
  /// So when space is tight the **± step buttons drop out** instead. They are
  /// the fine-tuning pair, and the presets on either side of them still reach
  /// every length on the ladder — nothing becomes unreachable, and the child's
  /// route (pick a picture, press GO) is untouched. Losing the adult's nudge
  /// buttons on a small phone is a far smaller cost than losing the rocket.
  Widget _waitingControls() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: _controlsBottomMargin,
      // FittedBox rather than Transform.scale for the remaining slack — the
      // row has to be *laid out* smaller, not merely painted smaller, or it
      // still overflows at its natural width and the buttons at the end are
      // unreachable.
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _waitingRow(
                withSteppers: _fitsSteppers(constraints.maxWidth),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _waitingRow({required bool withSteppers}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final preset in CountdownLength.presets) ...[
          _lengthButton(preset),
          const SizedBox(width: 14),
        ],
        const SizedBox(width: 16),

        if (withSteppers) ...[
          // Less / more, either side of the dots they change. Shorter is on
          // the left and longer on the right, matching how the dots grow.
          _stepButton(
            icon: Icons.remove_rounded,
            enabled: _countdown.canShorten,
            semanticLabel: 'less',
            onTap: _countdown.shorter,
          ),
          const SizedBox(width: 12),
          _LengthDots(length: _countdown.length),
          const SizedBox(width: 12),
          _stepButton(
            icon: Icons.add_rounded,
            enabled: _countdown.canLengthen,
            semanticLabel: 'more',
            onTap: _countdown.longer,
          ),
        ] else
          // The dots stay even when the steppers go: they are how the chosen
          // length is shown at all, and a preset with no visible effect would
          // read as a button that does nothing.
          _LengthDots(length: _countdown.length),

        const SizedBox(width: 28),
        // GO is bigger than everything else and a different colour, so it
        // is obvious which button starts the fun.
        BigButton(
          icon: Icons.play_arrow_rounded,
          color: KidGo.green,
          size: _goButtonSize,
          semanticLabel: 'go',
          onTap: () {
            _sounds.tap();
            KidHaptics.tap();
            _game.go();
          },
        ),
      ],
    );
  }

  /// One step along the ladder.
  ///
  /// At the end of the ladder the button goes visibly dim and answers with the
  /// soft wobble cue rather than silence — a button that looks alive but does
  /// nothing teaches a child the screen is unreliable, and this app never lets
  /// a tap simply vanish (CLAUDE.md §3).
  Widget _stepButton({
    required IconData icon,
    required bool enabled,
    required String semanticLabel,
    required bool Function() onTap,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: BigButton(
        icon: icon,
        color: KidGo.choice,
        size: _stepButtonSize,
        semanticLabel: semanticLabel,
        onTap: () {
          if (onTap()) {
            _sounds.tap();
            KidHaptics.tap();
          } else {
            _sounds.wobble();
          }
        },
      ),
    );
  }

  /// A preset: jumps straight to one rung, no stepping needed.
  Widget _lengthButton(CountdownLength length) {
    return BigButton(
      icon: _presetIcons[length]!,
      color: KidGo.choice,
      size: _stepButtonSize,
      selected: _countdown.length == length,
      semanticLabel: 'preset ${length.seconds}s',
      onTap: () {
        _sounds.tap();
        _countdown.choose(length: length);
      },
    );
  }

  /// While a countdown is underway: pause or play, and stop.
  ///
  /// Both sit bottom-left, away from the home button, and nothing else is on
  /// screen — during the count the count itself is the thing being watched.
  ///
  /// Pause is the adult's button as much as the child's: someone knocks at the
  /// door mid-toothbrush, and the alternative to pausing is starting again.
  /// It takes nothing away, and the clock does not drain while it is held.
  Widget _countingControls() {
    final paused = _countdown.phase == CountdownPhase.paused;

    return Positioned(
      left: 24,
      bottom: _controlsBottomMargin,
      child: Row(
        children: [
          BigButton(
            // One button that swaps its picture, rather than two that swap
            // places — a five-year-old tracks "the button there" more
            // reliably than a pair that move.
            icon: paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            color: paused ? KidGo.green : KidGo.choice,
            size: 110,
            semanticLabel: paused ? 'play' : 'pause',
            onTap: () {
              _sounds.tap();
              KidHaptics.tap();
              if (paused) {
                _countdown.resume();
              } else {
                _countdown.pause();
              }
            },
          ),
          const SizedBox(width: 16),
          BigButton(
            icon: Icons.stop_rounded,
            color: KidGo.stop,
            size: 110,
            semanticLabel: 'stop',
            onTap: () {
              _sounds.tap();
              _disarmAgainButton();
              _game.again();
            },
          ),
        ],
      ),
    );
  }

  /// Another one, please — which is the thing a child wants most after a
  /// launch. Held back until the rocket has actually gone, so it never cuts
  /// the moment short.
  ///
  /// The delay is driven by [_againTimer] here rather than by the game's
  /// clock. It used to read `countdown.sinceLaunch`, which only advances
  /// inside the Flame loop — and once the launch is over the loop has nothing
  /// left to animate, so that counter froze at zero and the button never
  /// arrived. The child was left on a dead screen with nothing to press but
  /// home, at the best moment in the game. A widget-layer timer cannot stall
  /// that way.
  Widget _launchedControls() {
    if (!_againReady) return const SizedBox.shrink();
    return Positioned(
      left: 0,
      right: 0,
      bottom: _controlsBottomMargin,
      child: Center(
        child: BigButton(
          icon: Icons.refresh_rounded,
          color: KidGo.green,
          size: _againButtonSize,
          semanticLabel: 'again',
          onTap: () {
            _sounds.tap();
            KidHaptics.tap();
            _disarmAgainButton();
            _game.again();
            _game.go();
          },
        ),
      ),
    );
  }
}

/// How wide the waiting row wants to be: three presets, less, dots, more and
/// GO, with the gaps between them. Measured rather than guessed, so the scale
/// below is honest.
/// The control sizes, named once so [BlastOffScreen.controlsReserve] and the
/// widgets below cannot drift apart. The reserve is what stops the rocket
/// being drawn underneath these.
const double _stepButtonSize = 92;
const double _goButtonSize = 132;
const double _againButtonSize = 150;
const double _controlsBottomMargin = 24;

/// A little clear air between the tallest button and the rocket above it, so
/// they read as separate things rather than as one stack.
const double _sceneBreathingRoom = 8;

/// The side padding the control row sits inside.
const double _controlsSidePadding = 16;

/// How wide the waiting row wants to be with the ± steppers in it, and without.
/// Measured rather than guessed, so the decision below is honest.
const double _rowWidthWithSteppers = _rowWidthBare +
    _stepButtonSize +
    12 +
    12 +
    _stepButtonSize;

/// Presets, the dots and GO — everything that never drops out.
const double _rowWidthBare =
    _stepButtonSize * 3 + 14 * 3 + 16 + _dotsWidth + 28 + _goButtonSize;

const double _dotsWidth = 108;

/// The smallest the waiting row may be scaled.
///
/// The smallest button in it is 92, so this keeps every touch target at or
/// above 80x80 on the narrowest screen we support — the kid rule, expressed as
/// the one number that enforces it (CLAUDE.md §3).
const double _minControlScale = 80 / _stepButtonSize;

/// Whether the ± steppers fit alongside everything else at a legal size.
///
/// Below this the row keeps the presets, the dots and GO, and loses the
/// steppers — see `_BlastOffScreenState._waitingControls` for why one row
/// matters more than the steppers do.
bool _fitsSteppers(double width) =>
    width - _controlsSidePadding * 2 >=
    _rowWidthWithSteppers * _minControlScale;

/// The time in digits, for the adult.
///
/// Deliberately styled like the settings cog rather than like the game: small,
/// grey, cornered, low contrast. A child's eye should slide off it (CLAUDE.md
/// §3) — it is not a score, not a target, and nothing in the game refers to it.
class _ClockReadout extends StatelessWidget {
  const _ClockReadout(this.countdown);

  final Countdown countdown;

  @override
  Widget build(BuildContext context) {
    return Text(
      countdown.clock,
      style: const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: KidPalette.parentGrey,
        letterSpacing: 1,
      ),
    );
  }
}

/// A picture per preset — a hint at how long it feels, never a number.
///
/// A mouse for the quick one, a hopping rabbit for the middle, a tortoise for
/// the long one. Speed is the only idea here a five-year-old already has for
/// "how long will this take".
const _presetIcons = <CountdownLength, IconData>{
  CountdownLength.five: Icons.pest_control_rodent_rounded,
  CountdownLength.thirty: Icons.cruelty_free_rounded,
  CountdownLength.fiveMinutes: Icons.emoji_nature_rounded,
};

/// The chosen length, drawn as dots — more dots, longer wait.
///
/// This is the only readout of the time, and it is deliberately not a number:
/// it says "longer than the last one" and "shorter than the last one", which
/// is the whole of what a child needs to set a countdown. An adult reads it
/// perfectly well too, once they have pressed more a couple of times.
class _LengthDots extends StatelessWidget {
  const _LengthDots({required this.length});

  final CountdownLength length;

  @override
  Widget build(BuildContext context) {
    final rungs = CountdownLength.values.length;
    final filled = length.index + 1;

    return SizedBox(
      width: 108,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 7,
        runSpacing: 7,
        children: [
          for (var i = 0; i < rungs; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: i < filled ? 17 : 13,
              height: i < filled ? 17 : 13,
              decoration: BoxDecoration(
                color: i < filled ? KidPalette.star : KidPalette.starEmpty,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

/// The three button colours this game needs, named by their job.
///
/// Deliberately not red for stop: a fully saturated red reads as "wrong" even
/// to a child who cannot read, and stopping here is not a mistake.
class KidGo {
  const KidGo._();

  static const green = Color(0xFF4CC97A);
  static const choice = Color(0xFF6BA8E8);
  static const stop = Color(0xFFF0A24B);
}
