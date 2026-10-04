import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Total effort at which the cat reaches her fit shape (bodyMass 0).
const double kTargetEffort = 120;

/// Planned pace: about two exercises a day reaches the target on day 60.
const double kPlannedEffortPerDay = kTargetEffort / 60;

/// The user's effort history. The cat's body follows effort, never logged
/// weight, and never regains: effort only goes up.
class Progress {
  const Progress({
    required this.effort,
    required this.doneToday,
    required this.day,
    required this.lastActiveDay,
    required this.startDay,
    this.activeDays = const [],
  });

  const Progress.initial()
    : effort = 0,
      doneToday = const [],
      day = '',
      lastActiveDay = null,
      startDay = null,
      activeDays = const [];

  final double effort;

  /// Exercise ids completed on [day].
  final List<String> doneToday;

  /// The calendar day (yyyy-mm-dd) [doneToday] belongs to.
  final String day;

  /// Last day with at least one completed exercise.
  final String? lastActiveDay;

  /// The day the journey began (D0).
  final String? startDay;

  /// Days (yyyy-mm-dd) with at least one finished exercise, oldest first.
  final List<String> activeDays;

  /// 100 = round (start), 0 = fit. Drives the Rive `bodyMass` input.
  double get bodyMass => bodyMassForEffort(effort);

  /// 0..1 share of the way from round to fit.
  double get journey => 1 - bodyMass / 100;

  /// Whole days since [startDay] (D0 = 0).
  int get dayNumber {
    final start = startDay;
    if (start == null || day.isEmpty) return 0;
    return DateTime.parse(day).difference(DateTime.parse(start)).inDays;
  }

  /// Effort the plan expects by today.
  double get plannedEffortToday => dayNumber * kPlannedEffortPerDay;

  /// 0 = sleepy, 100 = bright. Drives the Rive `energy` input.
  /// The Rive lids snap open between 20 and 60, so the first exercise of the
  /// day jumps her straight to bright eyes (in-between lids read as moody).
  double get energy => doneToday.isEmpty
      ? 15
      : (60 + 20.0 * (doneToday.length - 1)).clamp(0, 100);

  Progress copyWith({
    double? effort,
    List<String>? doneToday,
    String? day,
    String? lastActiveDay,
    String? startDay,
    List<String>? activeDays,
  }) => Progress(
    effort: effort ?? this.effort,
    doneToday: doneToday ?? this.doneToday,
    day: day ?? this.day,
    lastActiveDay: lastActiveDay ?? this.lastActiveDay,
    startDay: startDay ?? this.startDay,
    activeDays: activeDays ?? this.activeDays,
  );

  Map<String, Object?> toJson() => {
    'effort': effort,
    'doneToday': doneToday,
    'day': day,
    'lastActiveDay': lastActiveDay,
    'startDay': startDay,
    'activeDays': activeDays,
  };

  factory Progress.fromJson(Map<String, Object?> json) => Progress(
    effort: (json['effort'] as num?)?.toDouble() ?? 0,
    doneToday: (json['doneToday'] as List?)?.cast<String>() ?? const [],
    day: json['day'] as String? ?? '',
    lastActiveDay: json['lastActiveDay'] as String?,
    startDay: json['startDay'] as String?,
    activeDays: (json['activeDays'] as List?)?.cast<String>() ?? const [],
  );
}

double bodyMassForEffort(double effort) =>
    (100 * (1 - effort / kTargetEffort)).clamp(0, 100).toDouble();

/// Where the plan expects her to be on [day] (days since start).
double plannedBodyMassOnDay(int day) =>
    bodyMassForEffort(day * kPlannedEffortPerDay);

/// Exercises a day that count as "done for today".
const int kDailyGoal = 3;

String dayKey(DateTime t) =>
    '${t.year.toString().padLeft(4, '0')}-'
    '${t.month.toString().padLeft(2, '0')}-'
    '${t.day.toString().padLeft(2, '0')}';

/// Overridable so tests can pin the date.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final progressProvider = NotifierProvider<ProgressNotifier, Progress>(
  ProgressNotifier.new,
);

class ProgressNotifier extends Notifier<Progress> {
  static const _key = 'avelo.progress.v1';

  @override
  Progress build() {
    _load();
    return const Progress.initial();
  }

  String get _today => dayKey(ref.read(clockProvider)());

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final loaded = raw == null
        ? const Progress.initial()
        : Progress.fromJson(jsonDecode(raw) as Map<String, Object?>);
    state = _rollover(loaded);
    if (raw == null || loaded.startDay == null) await _save();
  }

  /// A new day starts with an empty "done today" list. The first ever day
  /// becomes the journey's D0.
  Progress _rollover(Progress p) {
    final today = _today;
    var next = p.day == today ? p : p.copyWith(day: today, doneToday: const []);
    if (next.startDay == null) next = next.copyWith(startDay: today);
    // Saves from before day history existed: today's work still counts.
    if (next.doneToday.isNotEmpty && !next.activeDays.contains(today)) {
      next = next.copyWith(activeDays: [...next.activeDays, today]);
    }
    return next;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }

  Future<void> completeExercise(String id, double effort) async {
    final current = _rollover(state);
    final today = _today;
    final days = current.activeDays.contains(today)
        ? current.activeDays
        : [...current.activeDays, today];
    state = current.copyWith(
      effort: current.effort + effort,
      doneToday: [...current.doneToday, id],
      lastActiveDay: today,
      // Keep about two months; older days are not shown anywhere.
      activeDays: days.length > 62 ? days.sublist(days.length - 62) : days,
    );
    await _save();
  }

  /// Debug only: wipe progress and restart the journey today.
  Future<void> reset() async {
    state = _rollover(const Progress.initial());
    await _save();
  }
}
