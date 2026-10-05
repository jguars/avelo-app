import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/milestones.dart';
import '../../data/progress.dart';
import '../cat/cat_view.dart';

/// Her journey: how far along she is, and the five milestone shapes.
class JourneyPanel extends ConsumerWidget {
  const JourneyPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final next = milestones.where((m) => !isReached(m, progress)).firstOrNull;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        4,
        16,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        _Hero(progress: progress),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text('Milestones', style: display(22)),
        ),
        for (final (i, m) in milestones.indexed)
          _MilestoneRow(
            milestone: m,
            progress: progress,
            isNext: identical(m, next),
            isLast: i == milestones.length - 1,
          ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.progress});

  final Progress progress;

  @override
  Widget build(BuildContext context) {
    final diff = progress.effort - progress.plannedEffortToday;
    final (pace, paceColor, paceIcon) = switch (diff) {
      >= 1 => ('Ahead of plan', AveloColors.sageDeep, Icons.north_east_rounded),
      > -2 => ('On pace', AveloColors.sageDeep, Icons.check_rounded),
      _ => ('A little behind', AveloColors.terracotta, Icons.schedule_rounded),
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AveloColors.peach,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AveloColors.ink, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('DAY ${progress.dayNumber}', style: eyebrow),
              const Spacer(),
              Container(
                padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
                decoration: BoxDecoration(
                  color: AveloColors.card,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(paceIcon, size: 16, color: paceColor),
                    const SizedBox(width: 4),
                    Text(
                      pace,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: paceColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(end: progress.journey),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('${(v * 100).round()}%', style: display(44)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'of the way to her fit shape',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AveloColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: v,
                    minHeight: 12,
                    backgroundColor: AveloColors.surface,
                    color: AveloColors.coral,
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

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({
    required this.milestone,
    required this.progress,
    required this.isNext,
    required this.isLast,
  });

  final Milestone milestone;
  final Progress progress;
  final bool isNext;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final reached = isReached(milestone, progress);
    final future = !reached && !isNext;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 44),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: reached
                        ? AveloColors.sageDeep
                        : isNext
                        ? AveloColors.terracotta
                        : AveloColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: reached ? AveloColors.sageDeep : AveloColors.ink,
                      width: 2,
                    ),
                  ),
                  child: reached
                      ? const Icon(
                          Icons.check_rounded,
                          size: 13,
                          color: Colors.white,
                        )
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 3,
                      decoration: BoxDecoration(
                        color: reached
                            ? AveloColors.sageDeep
                            : AveloColors.track,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: isNext ? AveloColors.peach : AveloColors.card,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isNext ? AveloColors.terracotta : AveloColors.ink,
                    width: isNext ? 2.5 : 2,
                  ),
                ),
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Container(
                      width: 92,
                      height: 104,
                      decoration: BoxDecoration(
                        color: reached
                            ? AveloColors.sageSoft
                            : isNext
                            ? AveloColors.card
                            : AveloColors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Opacity(
                        opacity: future ? 0.5 : 1,
                        child: CatView(
                          bodyMass: milestone.bodyMass,
                          energy: milestone.energy,
                          groundShadow: false,
                          bodyMassDuration: Duration.zero,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            milestone.day == 0
                                ? 'Day one'
                                : 'Day ${milestone.day}',
                            style: display(20),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _dateLabel(progress.startDay, milestone.day),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AveloColors.muted,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _StatusChip(
                            milestone: milestone,
                            progress: progress,
                            reached: reached,
                            isNext: isNext,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _dateLabel(String? startDay, int offset) {
    if (startDay == null) return '';
    final d = DateTime.parse(startDay).add(Duration(days: offset));
    return '${_months[d.month - 1]} ${d.day}';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.milestone,
    required this.progress,
    required this.reached,
    required this.isNext,
  });

  final Milestone milestone;
  final Progress progress;
  final bool reached;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final (text, fg, bg) = reached
        ? (
            milestone.day == 0
                ? 'Where it began'
                : identical(milestone, milestones.last)
                ? 'Fit and happy!'
                : 'Reached',
            Colors.white,
            AveloColors.sageDeep,
          )
        : isNext
        ? (
            '≈ ${(milestone.plannedEffort - progress.effort).ceil()} '
                'exercises to go',
            Colors.white,
            AveloColors.terracotta,
          )
        : (
            '${(100 - milestone.bodyMass).round()}% of the way',
            AveloColors.muted,
            AveloColors.surface,
          );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }
}
