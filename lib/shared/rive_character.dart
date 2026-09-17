import 'package:flame/components.dart';
import 'package:flame_rive/flame_rive.dart';
import 'package:flutter/foundation.dart' hide Factory;

/// A Rive character that reacts to what the child does.
///
/// ---------------------------------------------------------------------------
/// RIVE API: this uses the **0.14+ API** and must keep doing so (CLAUDE.md §2).
///
///   File.asset(..., riveFactory: Factory.flutter)   to load
///   loadArtboard(file)                              for the artboard
///   artboard.defaultStateMachine()                  for the state machine
///   stateMachine.bindViewModelInstance(instance)    to bind data binding
///   boundRuntimeViewModelInstance.trigger/number()  to drive it
///
/// Do NOT reintroduce `StateMachineController`, `SMIInput`, `SMITrigger`,
/// `RiveFile.asset` or state-machine *inputs* — all removed in 0.14, and most
/// examples online still show them.
///
/// `await RiveNative.init()` must have run first; it is called once in main().
/// ---------------------------------------------------------------------------
///
/// The component degrades gracefully: if the file, artboard, state machine or
/// a named property is missing, it logs and does nothing. A missing character
/// must never take a game down — the child should still be able to play.
class RiveCharacter extends PositionComponent {
  RiveCharacter({
    required this.assetPath,
    required this.properties,
    super.position,
    super.size,
    super.anchor,
    super.priority,
  });

  /// e.g. `assets/rive/rewards.riv`.
  final String assetPath;

  /// Which view-model properties this character exposes. See
  /// [RiveCharacterProperties].
  final RiveCharacterProperties properties;

  StateMachine? _stateMachine;
  ViewModelInstance? _viewModel;

  /// True once the file loaded and bound successfully.
  bool get isReady => _viewModel != null;

  @override
  Future<void> onLoad() async {
    final file = await File.asset(assetPath, riveFactory: Factory.flutter);
    if (file == null) {
      debugPrint('RiveCharacter: could not load "$assetPath"');
      return;
    }

    final artboard = await loadArtboard(file);
    final stateMachine = artboard.defaultStateMachine();
    if (stateMachine == null) {
      debugPrint('RiveCharacter: "$assetPath" has no default state machine');
      return;
    }

    // Data binding: create an instance of the artboard's default view model and
    // bind it, so properties can be driven by name afterwards.
    final viewModel = file.defaultArtboardViewModel(artboard);
    final instance = viewModel?.createDefaultInstance();
    if (instance != null) {
      stateMachine.bindViewModelInstance(instance);
      _viewModel = stateMachine.boundRuntimeViewModelInstance;
    } else {
      debugPrint('RiveCharacter: "$assetPath" has no default view model');
    }

    _stateMachine = stateMachine;

    add(RiveComponent(
      artboard: artboard,
      stateMachine: stateMachine,
      size: size,
    ));
  }

  /// Fires the character's "something good happened" reaction.
  void celebrate() => _fire(properties.celebrateTrigger);

  /// Fires the gentle "not that one" reaction.
  ///
  /// This must never look sad, cross or disappointed — a character's reaction
  /// to a mistake is exactly where punishment sneaks back in (CLAUDE.md §3).
  void encourage() => _fire(properties.encourageTrigger);

  /// Sets a 0..1 excitement level, if the character exposes one. Used to build
  /// anticipation as the child approaches the next celebration.
  void setExcitement(double value) {
    final path = properties.excitementNumber;
    if (path == null) return;
    final number = _viewModel?.number(path);
    if (number == null) {
      debugPrint('RiveCharacter: no number property "$path"');
      return;
    }
    number.value = value.clamp(0, 1) * properties.excitementScale;
  }

  void _fire(String? path) {
    if (path == null) return;
    final trigger = _viewModel?.trigger(path);
    if (trigger == null) {
      debugPrint('RiveCharacter: no trigger property "$path"');
      return;
    }
    trigger.trigger();
  }

  /// Escape hatch for a game that needs the raw state machine.
  StateMachine? get stateMachine => _stateMachine;

  /// Escape hatch for reaching nested view models, e.g.
  /// `viewModel?.viewModel('Coin')?.number('Item_Value')`.
  ViewModelInstance? get viewModel => _viewModel;
}

/// The names a `.riv` file must expose for [RiveCharacter] to drive it.
///
/// Kept as data rather than hard-coded strings so a custom Rive file can be
/// dropped in by changing these names only — no Dart changes.
@immutable
class RiveCharacterProperties {
  const RiveCharacterProperties({
    this.celebrateTrigger,
    this.encourageTrigger,
    this.excitementNumber,
    this.excitementScale = 1.0,
  });

  /// Trigger fired on success.
  final String? celebrateTrigger;

  /// Trigger fired on a harmless mistake.
  final String? encourageTrigger;

  /// Number property for a 0..1 excitement level.
  final String? excitementNumber;

  /// What 1.0 excitement maps to in the file's own units — a file using 0..100
  /// sets this to 100.
  final double excitementScale;
}
