import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/paws.dart';
import '../../app/sfx.dart';
import '../../app/theme.dart';
import '../../data/exercises.dart';
import '../../data/equipment.dart';
import '../../data/progress.dart';
import '../../data/wallet.dart';
import 'celebration_sheet.dart';
import 'exercise_session_screen.dart';
import 'living_room.dart';

/// Today: the cat on her sofa, and one exercise she picked for you.
///
/// One suggestion instead of a list keeps the decision small; "Show me
/// something else" cycles through the rest of today's pool.
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

enum _Mode { pick, ready }

class _TodayScreenState extends ConsumerState<TodayScreen> {
  _Mode _mode = _Mode.pick;
  int _pickOffset = 0;

  /// After the daily goal, the card rests until the user asks for more.
  bool _wantsMore = false;

  List<Exercise> _remaining(Progress p, Wallet w) =>
      availableExercises(w.ownedSet)
          .where((e) => !p.doneToday.contains(e.id))
          .toList();

  Future<void> _start(Exercise exercise) async {
    setState(() => _mode = _Mode.pick);
    final finished = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ExerciseSessionScreen(exercise: exercise),
      ),
    );
    if (finished != true) return;
    final before = ref.read(progressProvider).journey;
    await ref
        .read(progressProvider.notifier)
        .completeExercise(exercise.id, exercise.effort);
    final paws = await ref
        .read(walletProvider.notifier)
        .rewardExercise(exercise, ref.read(progressProvider).doneToday.length);
    if (!mounted) return;
    setState(() {
      _pickOffset = 0;
      _wantsMore = false;
    });
    await showCelebration(
      context,
      exercise: exercise,
      journeyBefore: before,
      progress: ref.read(progressProvider),
      paws: paws,
    );
  }

  String _speech(Progress p) {
    if (_mode == _Mode.ready) return 'Ready? I am… mostly.';
    final done = p.doneToday.length;
    if (done == 0) return 'Morning… is it time to move already?';
    if (done < kDailyGoal) return 'That felt good! One more?';
    return 'We did it today. Nap time?';
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(progressProvider);
    final now = ref.watch(clockProvider)();
    final remaining = _remaining(progress, ref.watch(walletProvider));
    final goalMet = progress.doneToday.length >= kDailyGoal;
    final pick = remaining.isEmpty
        ? null
        : remaining[_pickOffset % remaining.length];
    final resting = pick == null || (goalMet && !_wantsMore);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final Widget card;
    if (resting) {
      card = _RestCard(
        key: const ValueKey('rest'),
        allDone: pick == null,
        onMore: pick == null ? null : () => setState(() => _wantsMore = true),
      );
    } else if (_mode == _Mode.ready) {
      card = _ReadyCard(
        key: ValueKey('ready-${pick.id}'),
        exercise: pick,
        onGo: () => _start(pick),
        onLater: () => setState(() => _mode = _Mode.pick),
      );
    } else {
      card = _PickCard(
        key: ValueKey('pick-${pick.id}'),
        exercise: pick,
        canSwap: remaining.length > 1,
        onAccept: () {
          SfxPlayer.instance.play(Sfx.pop);
          setState(() => _mode = _Mode.ready);
        },
        onSwap: () => setState(() => _pickOffset++),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: _Header(now: now, done: progress.doneToday.length),
          ),
          Expanded(
            child: Stack(
              children: [
                // The room keeps a fixed size; the sheet grows over the rug
                // instead of pushing the room (and her) around.
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: kSheetRestHeight + bottomInset,
                  child: LivingRoom(
                    bodyMass: progress.bodyMass,
                    energy: _mode == _Mode.ready ? 100 : progress.energy,
                    lookAtCamera: _mode == _Mode.ready,
                    hour: now.hour,
                    speech: resting && pick == null ? null : _speech(progress),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AveloColors.surface,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      border: Border(
                        top: BorderSide(color: AveloColors.ink, width: 2),
                      ),
                    ),
                    padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSize(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween(
                                      begin: const Offset(0, 0.06),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                ),
                            child: card,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _WeekRow(progress: progress, now: now),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Height of the sheet's resting state above the bottom inset; the room ends
/// here, and taller card states overlap the rug.
const double kSheetRestHeight = 252;

class _Header extends StatelessWidget {
  const _Header({required this.now, required this.done});

  final DateTime now;
  final int done;

  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 18
        ? 'Good afternoon'
        : 'Good evening';
    final date =
        '${_weekdays[now.weekday - 1]}, ${_months[now.month - 1]} ${now.day}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date.toUpperCase(), style: eyebrow),
                const SizedBox(height: 2),
                Text(greeting, style: display(28)),
              ],
            ),
          ),
          _GoalChip(done: done),
        ],
      ),
    );
  }
}

/// "1 of 3 today" with a small progress ring.
class _GoalChip extends StatelessWidget {
  const _GoalChip({required this.done});

  final int done;

  @override
  Widget build(BuildContext context) {
    final shown = math.min(done, kDailyGoal);
    return Semantics(
      label: '$shown of $kDailyGoal exercises done today',
      excludeSemantics: true,
      child: Container(
        height: 44,
        padding: const EdgeInsets.fromLTRB(6, 0, 14, 0),
        decoration: BoxDecoration(
          color: AveloColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AveloColors.ink, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: shown / kDailyGoal),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => CircularProgressIndicator(
                  value: value,
                  strokeWidth: 4.5,
                  strokeCap: StrokeCap.round,
                  backgroundColor: AveloColors.track,
                  color: AveloColors.terracotta,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$shown of $kDailyGoal today',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared shell for the cards in the sheet.
class _SheetCard extends StatelessWidget {
  const _SheetCard({required this.child, this.color = AveloColors.peach});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AveloColors.ink, width: 2),
      ),
      child: child,
    );
  }
}

class _ExerciseHeading extends StatelessWidget {
  const _ExerciseHeading({
    required this.exercise,
    required this.label,
    required this.detail,
    this.reward,
  });

  final Exercise exercise;

  /// Paws shown after [detail] on the pick card.
  final int? reward;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AveloColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AveloColors.ink, width: 2),
          ),
          child: Icon(exercise.icon, color: AveloColors.ink, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: eyebrow.copyWith(color: const Color(0xFF8E3F22)),
              ),
              const SizedBox(height: 2),
              Text(exercise.name, style: display(22)),
              const SizedBox(height: 2),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B4A36),
                      ),
                    ),
                  ),
                  if (reward case final paws?) ...[
                    const Text(
                      '  ·  ',
                      style: TextStyle(fontSize: 14, color: Color(0xFF6B4A36)),
                    ),
                    PawAmount(paws, prefix: '+', size: 14),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PickCard extends StatelessWidget {
  const _PickCard({
    super.key,
    required this.exercise,
    required this.canSwap,
    required this.onAccept,
    required this.onSwap,
  });

  final Exercise exercise;
  final bool canSwap;
  final VoidCallback onAccept;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    return _SheetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ExerciseHeading(
            exercise: exercise,
            label: switch (exercise.equipment) {
              final id? => 'WITH HER ${equipmentById(id).name.toUpperCase()}',
              null => 'HER PICK FOR YOU',
            },
            detail: formatDuration(exercise.seconds),
            reward: exercise.paws,
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onAccept,
            child: const Text("Let's do it together"),
          ),
          TextButton(
            onPressed: canSwap ? onSwap : null,
            child: const Text('Show me something else'),
          ),
        ],
      ),
    );
  }
}

class _ReadyCard extends StatelessWidget {
  const _ReadyCard({
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
    return _SheetCard(
      color: AveloColors.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ExerciseHeading(
            exercise: exercise,
            label: 'READY?',
            detail: exercise.cue,
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onGo,
            child: Text("I'm ready · ${formatDuration(exercise.seconds)}"),
          ),
          TextButton(onPressed: onLater, child: const Text('Not now')),
        ],
      ),
    );
  }
}

class _RestCard extends StatelessWidget {
  const _RestCard({super.key, required this.allDone, this.onMore});

  final bool allDone;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return _SheetCard(
      color: const Color(0xFFDCE7D6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            allDone ? 'EVERY IDEA DONE' : 'DONE FOR TODAY',
            style: eyebrow.copyWith(color: const Color(0xFF3E5A39)),
          ),
          const SizedBox(height: 4),
          Text(
            allDone ? 'You did every one. Legend.' : 'Three together!',
            style: display(22),
          ),
          const SizedBox(height: 4),
          const Text(
            'She is curling up for a nap. Rest counts too.',
            style: TextStyle(fontSize: 14, color: Color(0xFF4F5E4B)),
          ),
          if (onMore != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onMore,
                child: const Text('One more anyway'),
              ),
            )
          else
            const SizedBox(height: 12),
        ],
      ),
    );
  }
}

/// Monday-to-Sunday dots for days she moved, plus overall journey.
class _WeekRow extends StatelessWidget {
  const _WeekRow({required this.progress, required this.now});

  final Progress progress;
  final DateTime now;

  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final active = progress.activeDays.toSet();

    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _DayColumn(
              letter: _letters[i],
              day: monday.add(Duration(days: i)),
              today: today,
              active: active,
            ),
          ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'Her journey',
              style: TextStyle(fontSize: 12, color: AveloColors.muted),
            ),
            Text(
              '${(progress.journey * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ],
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.letter,
    required this.day,
    required this.today,
    required this.active,
  });

  final String letter;
  final DateTime day;
  final DateTime today;
  final Set<String> active;

  @override
  Widget build(BuildContext context) {
    final isToday = day == today;
    final moved = active.contains(dayKey(day));
    final future = day.isAfter(today);

    final Widget dot;
    if (moved) {
      dot = Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          color: AveloColors.terracotta,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 16, color: Colors.white),
      );
    } else {
      dot = Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: isToday
              ? AveloColors.card
              : future
              ? AveloColors.track.withValues(alpha: 0.5)
              : AveloColors.track,
          shape: BoxShape.circle,
          border: isToday
              ? Border.all(color: AveloColors.terracotta, width: 2)
              : null,
        ),
      );
    }

    return Semantics(
      label: moved ? 'Moved' : (future ? 'Upcoming' : 'No exercise'),
      excludeSemantics: true,
      child: Column(
        children: [
          Text(
            letter,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: isToday ? AveloColors.terracotta : AveloColors.muted,
            ),
          ),
          const SizedBox(height: 4),
          dot,
        ],
      ),
    );
  }
}

String formatEffort(double e) =>
    e == e.roundToDouble() ? e.toStringAsFixed(0) : e.toStringAsFixed(1);

String formatDuration(int seconds) {
  if (seconds < 60) return '${seconds}s';
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return s == 0 ? '$m min' : '$m min ${s}s';
}
