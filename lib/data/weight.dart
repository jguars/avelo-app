import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Planned pace: a steady, sustainable 0.7 kg a week.
const double kPlannedKgPerWeek = 0.7;

class WeightEntry {
  const WeightEntry(this.at, this.kg);

  final DateTime at;
  final double kg;

  Map<String, Object?> toJson() => {'at': at.toIso8601String(), 'kg': kg};

  factory WeightEntry.fromJson(Map<String, Object?> j) => WeightEntry(
    DateTime.parse(j['at'] as String),
    (j['kg'] as num).toDouble(),
  );
}

/// Every weigh-in (any number per day) and the goal.
class WeightLog {
  const WeightLog({required this.entries, this.goalKg});

  /// Oldest first.
  final List<WeightEntry> entries;
  final double? goalKg;

  WeightEntry? get first => entries.firstOrNull;
  WeightEntry? get latest => entries.lastOrNull;

  /// Change since the first weigh-in (negative = lost).
  double get change => entries.length < 2 ? 0 : latest!.kg - first!.kg;

  /// Where the plan expects the user on [day]: a straight line down from the
  /// first weigh-in, stopping at the goal.
  double? plannedOn(DateTime day) {
    final start = first;
    if (start == null) return null;
    final days = day.difference(start.at).inHours / 24;
    final kg = start.kg - kPlannedKgPerWeek * days / 7;
    final goal = goalKg;
    return goal == null || goal >= start.kg ? kg : (kg < goal ? goal : kg);
  }

  /// When the plan reaches the goal, if one is set below the start.
  DateTime? get goalDate {
    final start = first;
    final goal = goalKg;
    if (start == null || goal == null || goal >= start.kg) return null;
    final days = (start.kg - goal) / kPlannedKgPerWeek * 7;
    return start.at.add(Duration(hours: (days * 24).round()));
  }

  /// 0..1 of the way from the first weigh-in to the goal.
  double get toGoal {
    final start = first;
    final goal = goalKg;
    if (start == null || goal == null || goal >= start.kg) return 0;
    return ((start.kg - latest!.kg) / (start.kg - goal)).clamp(0, 1);
  }

  WeightLog copyWith({List<WeightEntry>? entries, double? goalKg}) => WeightLog(
    entries: entries ?? this.entries,
    goalKg: goalKg ?? this.goalKg,
  );

  Map<String, Object?> toJson() => {
    'entries': [for (final e in entries) e.toJson()],
    'goalKg': goalKg,
  };

  factory WeightLog.fromJson(Map<String, Object?> j) => WeightLog(
    entries: [
      for (final e in (j['entries'] as List? ?? const []))
        WeightEntry.fromJson((e as Map).cast<String, Object?>()),
    ],
    goalKg: (j['goalKg'] as num?)?.toDouble(),
  );
}

final weightProvider = NotifierProvider<WeightNotifier, WeightLog>(
  WeightNotifier.new,
);

class WeightNotifier extends Notifier<WeightLog> {
  static const _key = 'avelo.weight.v1';

  @override
  WeightLog build() {
    _load();
    return const WeightLog(entries: []);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      state = WeightLog.fromJson(jsonDecode(raw) as Map<String, Object?>);
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }

  Future<void> log(double kg, [DateTime? at]) async {
    final entries = [...state.entries, WeightEntry(at ?? DateTime.now(), kg)]
      ..sort((a, b) => a.at.compareTo(b.at));
    state = state.copyWith(entries: entries);
    await _save();
  }

  /// Removes [entry]; returns a callback that puts it back.
  Future<Future<void> Function()> remove(WeightEntry entry) async {
    state = state.copyWith(
      entries: state.entries.where((e) => !identical(e, entry)).toList(),
    );
    await _save();
    return () => log(entry.kg, entry.at);
  }

  Future<void> setGoal(double kg) async {
    state = state.copyWith(goalKg: kg);
    await _save();
  }
}
