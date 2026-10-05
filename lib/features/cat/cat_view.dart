import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import '../../data/exercises.dart';
import 'cat_clip.dart';

/// The Avelo cat, rendered from `assets/rive/avelo_cat.riv`.
///
/// Inputs map 1:1 to the `AveloCatVM` view model in the Rive file:
/// - [bodyMass] 100 = round, 0 = fit. Changes are eased over [bodyMassDuration]
///   so the cat visibly slims after an exercise.
/// - [energy] 0 = sleepy half-lids, 100 = bright eyes.
/// - [lookAtCamera] plays the "Ready?" look.
class CatView extends StatelessWidget {
  const CatView({
    super.key,
    required this.bodyMass,
    required this.energy,
    this.lookAtCamera = false,
    this.groundShadow = true,
    this.exercising = false,
    this.move = CatMove.squat,
    this.bodyMassDuration = const Duration(milliseconds: 1600),
  });

  final double bodyMass;
  final double energy;
  final bool lookAtCamera;

  /// Off when she sits on furniture rather than the floor.
  final bool groundShadow;

  /// Plays the workout loop and shows her sweatband.
  final bool exercising;

  /// Which workout loop plays while [exercising].
  final CatMove move;
  final Duration bodyMassDuration;

  @override
  Widget build(BuildContext context) {
    // Squats play the Layer clip of the heaviest cat (other moves and sizes
    // are still the Rive rig).
    if (exercising && move == CatMove.squat) {
      return CatClip.squatHeavy(groundShadow: groundShadow);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(end: bodyMass),
      duration: bodyMassDuration,
      curve: Curves.easeInOutCubic,
      builder: (context, mass, _) => TweenAnimationBuilder<double>(
        tween: Tween(end: energy),
        duration: const Duration(milliseconds: 500),
        builder: (context, e, _) => _RiveCat(
          bodyMass: mass,
          energy: e,
          lookAtCamera: lookAtCamera,
          groundShadow: groundShadow,
          exercising: exercising,
          move: move,
        ),
      ),
    );
  }
}

class _RiveCat extends StatefulWidget {
  const _RiveCat({
    required this.bodyMass,
    required this.energy,
    required this.lookAtCamera,
    required this.groundShadow,
    required this.exercising,
    required this.move,
  });

  final double bodyMass;
  final double energy;
  final bool lookAtCamera;
  final bool groundShadow;
  final bool exercising;
  final CatMove move;

  @override
  State<_RiveCat> createState() => _RiveCatState();
}

class _RiveCatState extends State<_RiveCat> {
  RiveWidgetController? _controller;
  ViewModelInstance? _vm;
  ViewModelInstanceNumber? _bodyMass;
  ViewModelInstanceNumber? _energy;
  ViewModelInstanceBoolean? _look;
  ViewModelInstanceNumber? _shadow;
  ViewModelInstanceBoolean? _exercising;
  ViewModelInstanceNumber? _move;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// One decoded file shared by every cat on screen (Timeline shows five).
  static Future<File?>? _sharedFile;

  Future<void> _load() async {
    try {
      final file = await (_sharedFile ??= File.asset(
        'assets/rive/avelo_cat.riv',
        riveFactory: Factory.rive,
      ));
      if (file == null) {
        _sharedFile = null;
        throw StateError('Could not load avelo_cat.riv');
      }
      final controller = RiveWidgetController(
        file,
        artboardSelector: ArtboardSelector.byName('AveloCat'),
        stateMachineSelector: StateMachineSelector.byName('AveloCatSM'),
      );
      final vm = controller.dataBind(DataBind.auto());
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _vm = vm;
        _bodyMass = vm.number('bodyMass');
        _energy = vm.number('energy');
        _look = vm.boolean('lookAtCamera');
        _shadow = vm.number('groundShadow');
        _exercising = vm.boolean('exercising');
        _move = vm.number('move');
      });
      _push();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _push() {
    _bodyMass?.value = widget.bodyMass;
    _energy?.value = widget.energy;
    _look?.value = widget.lookAtCamera;
    _shadow?.value = widget.groundShadow ? 100 : 0;
    // The state machine only picks a move on its way out of Still, so a new
    // move while already exercising drops back to Still for one frame.
    final moveChanged = _move != null && _move!.value != widget.move.index;
    _move?.value = widget.move.index.toDouble();
    if (moveChanged && widget.exercising) {
      _exercising?.value = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _exercising?.value = widget.exercising;
      });
    } else {
      _exercising?.value = widget.exercising;
    }
  }

  @override
  void didUpdateWidget(covariant _RiveCat oldWidget) {
    super.didUpdateWidget(oldWidget);
    _push();
  }

  @override
  void dispose() {
    _bodyMass?.dispose();
    _energy?.dispose();
    _look?.dispose();
    _shadow?.dispose();
    _exercising?.dispose();
    _move?.dispose();
    _vm?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(child: Text('Cat failed to load:\n$_error'));
    }
    final controller = _controller;
    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return RiveWidget(controller: controller, fit: Fit.contain);
  }
}
