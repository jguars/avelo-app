import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/progress.dart';
import '../cat/cat_view.dart';

/// A milestone on her journey, with the shape the plan expects by then.
class Milestone {
  const Milestone(this.day, this.energy);

  /// Days since the journey began.
  final int day;

  /// Brighter eyes further along the journey.
  final double energy;

  double get plannedEffort => day * kPlannedEffortPerDay;
  double get bodyMass => plannedBodyMassOnDay(day);
}

const milestones = <Milestone>[
  Milestone(0, 15),
  Milestone(7, 60),
  Milestone(15, 70),
  Milestone(30, 85),
  Milestone(60, 100),
];

/// Milestones are reached by effort, not by the calendar: working ahead of
/// the plan reaches them early, and a slow week never takes one away.
bool isReached(Milestone m, Progress p) => p.effort >= m.plannedEffort;

class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final next = milestones.where((m) => !isReached(m, progress)).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Her journey')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          4,
          16,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          _Summary(progress: progress),
          const SizedBox(height: 16),
          for (final (i, m) in milestones.indexed)
            _MilestoneRow(
              milestone: m,
              progress: progress,
              isNext: identical(m, next),
              isLast: i == milestones.length - 1,
            ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.progress});

  final Progress progress;

  @override
  Widget build(BuildContext context) {
    final diff = progress.effort - progress.plannedEffortToday;
    final pace = switch (diff) {
      >= 1 => 'Ahead of plan. She is impressed.',
      > -2 => 'Right on pace.',
      _ => 'A little behind plan. No rush, she never loses her progress.',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Day ${progress.dayNumber} · '
              '${(progress.journey * 100).toStringAsFixed(1)}% of the way',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.journey,
                minHeight: 10,
                backgroundColor: AveloColors.background,
                color: AveloColors.coral,
              ),
            ),
            const SizedBox(height: 10),
            Text(pace, style: const TextStyle(color: AveloColors.muted)),
          ],
        ),
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
    final dotColor = reached
        ? AveloColors.coral
        : isNext
        ? AveloColors.stripe
        : AveloColors.fur;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Rail with a dot per milestone.
          SizedBox(
            width: 28,
            child: Column(
              children: [
                const SizedBox(height: 22),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AveloColors.ink, width: 2),
                  ),
                  child: reached
                      ? const Icon(Icons.check, size: 10, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: reached ? AveloColors.coral : AveloColors.fur,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isNext ? AveloColors.coral : AveloColors.ink,
                    width: isNext ? 2.5 : 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 104,
                      height: 120,
                      child: Opacity(
                        opacity: reached || isNext ? 1 : 0.55,
                        child: CatView(
                          bodyMass: milestone.bodyMass,
                          energy: milestone.energy,
                          bodyMassDuration: Duration.zero,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(4, 12, 14, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'D${milestone.day}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              _dateLabel(progress.startDay, milestone.day),
                              style: const TextStyle(color: AveloColors.muted),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _statusLine(reached),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: reached
                                    ? AveloColors.coral
                                    : AveloColors.ink,
                              ),
                            ),
                          ],
                        ),
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

  String _statusLine(bool reached) {
    if (milestone.day == 0) return 'Where it all began';
    if (reached) {
      return milestone == milestones.last ? 'Fit and happy!' : 'Reached!';
    }
    if (milestone == milestones.last && !isNext) return 'Her fit shape';
    final left = milestone.plannedEffort - progress.effort;
    // Most exercises are worth about 1 effort point.
    final exercises = left.ceil();
    return isNext
        ? 'Next: about $exercises more exercises'
        : '${(100 - milestone.bodyMass).round()}% of the way';
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String _dateLabel(String? startDay, int offset) {
    if (startDay == null) return '';
    final d = DateTime.parse(startDay).add(Duration(days: offset));
    return 'Planned for ${_months[d.month - 1]} ${d.day}';
  }
}
