import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/exercises.dart';
import '../../data/progress.dart';
import '../cat/cat_view.dart';
import 'exercise_session_screen.dart';

/// Today: the lazy cat in her cozy spot, and up to three exercises to pick.
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  /// The exercise the cat is currently asking "Ready?" about.
  Exercise? _asking;

  Future<void> _start(Exercise exercise) async {
    setState(() => _asking = null);
    final finished = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ExerciseSessionScreen(exercise: exercise),
      ),
    );
    if (finished == true) {
      await ref
          .read(progressProvider.notifier)
          .completeExercise(exercise.id, exercise.effort);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${exercise.name} done. She felt that too!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(progressProvider);
    final remaining = dailyExercises
        .where((e) => !progress.doneToday.contains(e.id))
        .toList();
    final visible = remaining.take(3).toList();
    final asking = _asking;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(doneCount: progress.doneToday.length),
            Expanded(
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Positioned.fill(
                    child: CatView(
                      bodyMass: progress.bodyMass,
                      energy: asking != null ? 100 : progress.energy,
                      lookAtCamera: asking != null,
                    ),
                  ),
                  if (asking != null)
                    Positioned(
                      top: 8,
                      child: _SpeechBubble(text: 'Ready? ${asking.name}!'),
                    ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: asking != null
                  ? _ReadyPanel(
                      key: const ValueKey('ready'),
                      exercise: asking,
                      onGo: () => _start(asking),
                      onLater: () => setState(() => _asking = null),
                    )
                  : _ExerciseList(
                      key: const ValueKey('list'),
                      exercises: visible,
                      remaining: remaining.length,
                      onPick: (e) => setState(() => _asking = e),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.doneCount});

  final int doneCount;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final line = switch (doneCount) {
      0 => 'She is waiting for you on the sofa.',
      1 => 'One down. She is wide awake now.',
      _ => '$doneCount exercises together today.',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Today',
                    style: text.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
                Text(line,
                    style:
                        text.bodyMedium?.copyWith(color: AveloColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AveloColors.ink, width: 2),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 18,
          color: AveloColors.ink,
        ),
      ),
    );
  }
}

class _ExerciseList extends StatelessWidget {
  const _ExerciseList({
    super.key,
    required this.exercises,
    required this.remaining,
    required this.onPick,
  });

  final List<Exercise> exercises;
  final int remaining;
  final ValueChanged<Exercise> onPick;

  @override
  Widget build(BuildContext context) {
    if (exercises.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'All done for today. She is proud of you.',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Pick one to do together · $remaining left today',
              style: const TextStyle(
                color: AveloColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final e in exercises) ...[
            _ExerciseCard(exercise: e, onTap: () => onPick(e)),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise, required this.onTap});

  final Exercise exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AveloColors.fur,
                foregroundColor: AveloColors.ink,
                child: Icon(exercise.icon),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  exercise.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                formatDuration(exercise.seconds),
                style: const TextStyle(color: AveloColors.muted),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AveloColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadyPanel extends StatelessWidget {
  const _ReadyPanel({
    super.key,
    required this.exercise,
    required this.onGo,
    required this.onLater,
  });

  final Exercise exercise;
  final VoidCallback onGo;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            exercise.cue,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: AveloColors.muted),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onGo,
            child: Text("Let's go · ${formatDuration(exercise.seconds)}"),
          ),
          TextButton(onPressed: onLater, child: const Text('Not now')),
        ],
      ),
    );
  }
}

String formatDuration(int seconds) {
  if (seconds < 60) return '${seconds}s';
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return s == 0 ? '$m min' : '$m min ${s}s';
}
