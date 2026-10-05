import 'progress.dart';

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
