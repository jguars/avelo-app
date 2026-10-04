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
      final before = ref.read(progressProvider).journey;
      await ref
          .read(progressProvider.notifier)
          .completeExercise(exercise.id, exercise.effort);
      if (!mounted) return;
      final after = ref.read(progressProvider).journey;
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: AveloColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (_) => _Celebration(
          exercise: exercise,
          before: before,
          after: after,
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
            _Header(
              doneCount: progress.doneToday.length,
              journey: progress.journey,
            ),
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
  const _Header({required this.doneCount, required this.journey});

  final int doneCount;
  final double journey;

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
          _JourneyChip(journey: journey),
        ],
      ),
    );
  }
}

class _JourneyChip extends StatelessWidget {
  const _JourneyChip({required this.journey});

  final double journey;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'How far she is from her fit shape',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AveloColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AveloColors.ink, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flag_outlined, size: 16, color: AveloColors.coral),
            const SizedBox(width: 4),
            Text(
              '${(journey * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
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

/// Shown after every finished exercise: the journey bar visibly moves, so
/// progress feels earned even when her shape changes only a little.
class _Celebration extends StatelessWidget {
  const _Celebration({
    required this.exercise,
    required this.before,
    required this.after,
  });

  final Exercise exercise;
  final double before;
  final double after;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'You both did it!',
              textAlign: TextAlign.center,
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              '${exercise.name} done. She is a little lighter now.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AveloColors.muted),
            ),
            const SizedBox(height: 24),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: before, end: after),
              duration: const Duration(milliseconds: 1400),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Her journey',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Text(
                        '${(value * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 14,
                      backgroundColor: AveloColors.background,
                      color: AveloColors.coral,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '+${_formatEffort(exercise.effort)} effort',
              textAlign: TextAlign.right,
              style: const TextStyle(color: AveloColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to her'),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatEffort(double e) =>
      e == e.roundToDouble() ? e.toStringAsFixed(0) : e.toStringAsFixed(1);
}

String formatDuration(int seconds) {
  if (seconds < 60) return '${seconds}s';
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return s == 0 ? '$m min' : '$m min ${s}s';
}
