import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Total effort at which the cat reaches her fit shape (bodyMass 0).
/// About two exercises a day for two months.
const double kTargetEffort = 120;

/// The user's effort history. The cat's body follows effort, never logged
/// weight, and never regains: effort only goes up.
class Progress {
  const Progress({
    required this.effort,
    required this.doneToday,
    required this.day,
    required this.lastActiveDay,
  });

  const Progress.initial()
      : effort = 0,
        doneToday = const [],
        day = '',
        lastActiveDay = null;

  final double effort;

  /// Exercise ids completed on [day].
  final List<String> doneToday;

  /// The calendar day (yyyy-mm-dd) [doneToday] belongs to.
  final String day;

  /// Last day with at least one completed exercise.
  final String? lastActiveDay;

  /// 100 = round (start), 0 = fit. Drives the Rive `bodyMass` input.
  double get bodyMass => (100 * (1 - effort / kTargetEffort)).clamp(0, 100);

  /// 0..1 share of the way from round to fit.
  double get journey => 1 - bodyMass / 100;

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
  }) =>
      Progress(
        effort: effort ?? this.effort,
        doneToday: doneToday ?? this.doneToday,
        day: day ?? this.day,
        lastActiveDay: lastActiveDay ?? this.lastActiveDay,
      );

  Map<String, Object?> toJson() => {
        'effort': effort,
        'doneToday': doneToday,
        'day': day,
        'lastActiveDay': lastActiveDay,
      };

  factory Progress.fromJson(Map<String, Object?> json) => Progress(
        effort: (json['effort'] as num?)?.toDouble() ?? 0,
        doneToday: (json['doneToday'] as List?)?.cast<String>() ?? const [],
        day: json['day'] as String? ?? '',
        lastActiveDay: json['lastActiveDay'] as String?,
      );
}

String dayKey(DateTime t) =>
    '${t.year.toString().padLeft(4, '0')}-'
    '${t.month.toString().padLeft(2, '0')}-'
    '${t.day.toString().padLeft(2, '0')}';

/// Overridable so tests can pin the date.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final progressProvider =
    NotifierProvider<ProgressNotifier, Progress>(ProgressNotifier.new);

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
  }

  /// A new day starts with an empty "done today" list.
  Progress _rollover(Progress p) =>
      p.day == _today ? p : p.copyWith(day: _today, doneToday: const []);

  Future<void> completeExercise(String id, double effort) async {
    final current = _rollover(state);
    state = current.copyWith(
      effort: current.effort + effort,
      doneToday: [...current.doneToday, id],
      lastActiveDay: _today,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }

  /// Debug only: wipe progress.
  Future<void> reset() async {
    state = const Progress.initial().copyWith(day: _today);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
