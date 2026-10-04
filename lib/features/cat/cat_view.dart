import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

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
    this.bodyMassDuration = const Duration(milliseconds: 1600),
  });

  final double bodyMass;
  final double energy;
  final bool lookAtCamera;
  final Duration bodyMassDuration;

  @override
  Widget build(BuildContext context) {
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
  });

  final double bodyMass;
  final double energy;
  final bool lookAtCamera;

  @override
  State<_RiveCat> createState() => _RiveCatState();
}

class _RiveCatState extends State<_RiveCat> {
  File? _file;
  RiveWidgetController? _controller;
  ViewModelInstance? _vm;
  ViewModelInstanceNumber? _bodyMass;
  ViewModelInstanceNumber? _energy;
  ViewModelInstanceBoolean? _look;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final file = await File.asset(
        'assets/rive/avelo_cat.riv',
        riveFactory: Factory.rive,
      );
      if (file == null) throw StateError('Could not load avelo_cat.riv');
      final controller = RiveWidgetController(
        file,
        artboardSelector: ArtboardSelector.byName('AveloCat'),
        stateMachineSelector: StateMachineSelector.byName('AveloCatSM'),
      );
      final vm = controller.dataBind(DataBind.auto());
      if (!mounted) {
        controller.dispose();
        file.dispose();
        return;
      }
      setState(() {
        _file = file;
        _controller = controller;
        _vm = vm;
        _bodyMass = vm.number('bodyMass');
        _energy = vm.number('energy');
        _look = vm.boolean('lookAtCamera');
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
    _vm?.dispose();
    _controller?.dispose();
    _file?.dispose();
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
