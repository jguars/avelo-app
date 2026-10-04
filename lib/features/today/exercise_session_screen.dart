import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/exercises.dart';
import '../../data/progress.dart';
import '../cat/cat_view.dart';
import 'today_screen.dart' show formatDuration;

/// Trust + timer: the user and the cat exercise until the timer runs out.
/// Pops `true` when the exercise was completed.
class ExerciseSessionScreen extends ConsumerStatefulWidget {
  const ExerciseSessionScreen({super.key, required this.exercise});

  final Exercise exercise;

  @override
  ConsumerState<ExerciseSessionScreen> createState() =>
      _ExerciseSessionScreenState();
}

class _ExerciseSessionScreenState extends ConsumerState<ExerciseSessionScreen> {
  Timer? _ticker;
  late int _left = widget.exercise.seconds;
  bool _paused = false;

  bool get _finished => _left <= 0;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_paused || _finished) return;
      setState(() => _left--);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(progressProvider);
    final total = widget.exercise.seconds;
    final fraction = 1 - _left / total;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise.name),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Stop',
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            children: [
              Expanded(
                child: CatView(
                  bodyMass: progress.bodyMass,
                  energy: 100,
                ),
              ),
              Text(
                _finished ? 'Done!' : formatDuration(_left),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 10,
                  backgroundColor: AveloColors.surface,
                  color: AveloColors.coral,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.exercise.cue,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AveloColors.muted, fontSize: 15),
              ),
              const SizedBox(height: 20),
              if (_finished)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('We did it'),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      shape: const StadiumBorder(),
                      side: const BorderSide(color: AveloColors.ink, width: 1.5),
                      foregroundColor: AveloColors.ink,
                    ),
                    onPressed: () => setState(() => _paused = !_paused),
                    child: Text(_paused ? 'Resume' : 'Pause'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
