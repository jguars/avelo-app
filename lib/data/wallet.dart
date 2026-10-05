import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'equipment.dart';
import 'exercises.dart';
import 'progress.dart';

/// Paws for each plan rule kept today.
const int kPawsPerRule = 2;

/// One-off bonus for reaching the daily goal.
const int kDailyGoalPaws = 15;

enum EarnKind { exercise, dailyGoal, planRule }

/// One line in the paws ledger.
class Earning {
  const Earning({
    required this.day,
    required this.kind,
    required this.amount,
    required this.ref,
  });

  /// yyyy-mm-dd.
  final String day;
  final EarnKind kind;
  final int amount;

  /// Exercise id or plan rule id.
  final String ref;

  Map<String, Object?> toJson() => {
    'day': day,
    'kind': kind.name,
    'amount': amount,
    'ref': ref,
  };

  factory Earning.fromJson(Map<String, Object?> j) => Earning(
    day: j['day'] as String,
    kind: EarnKind.values.byName(j['kind'] as String),
    amount: (j['amount'] as num).toInt(),
    ref: j['ref'] as String? ?? '',
  );
}

/// Paws balance, owned equipment, and recent earnings.
class Wallet {
  const Wallet({required this.paws, required this.owned, required this.ledger});

  const Wallet.initial() : paws = 0, owned = const [], ledger = const [];

  final int paws;

  /// Equipment ids, in the order bought.
  final List<String> owned;

  /// Earnings, oldest first; about two months are kept.
  final List<Earning> ledger;

  Set<String> get ownedSet => owned.toSet();

  bool owns(String id) => owned.contains(id);

  /// Paws earned on or after [day] (yyyy-mm-dd).
  int earnedSince(String day) => ledger
      .where((e) => e.day.compareTo(day) >= 0)
      .fold(0, (sum, e) => sum + e.amount);

  /// Earnings of [kind] on or after [day].
  int countSince(EarnKind kind, String day) =>
      ledger.where((e) => e.kind == kind && e.day.compareTo(day) >= 0).length;

  Wallet copyWith({int? paws, List<String>? owned, List<Earning>? ledger}) =>
      Wallet(
        paws: paws ?? this.paws,
        owned: owned ?? this.owned,
        ledger: ledger ?? this.ledger,
      );

  Map<String, Object?> toJson() => {
    'paws': paws,
    'owned': owned,
    'ledger': [for (final e in ledger) e.toJson()],
  };

  factory Wallet.fromJson(Map<String, Object?> j) => Wallet(
    paws: (j['paws'] as num?)?.toInt() ?? 0,
    owned: (j['owned'] as List?)?.cast<String>() ?? const [],
    ledger: [
      for (final e in (j['ledger'] as List? ?? const []))
        Earning.fromJson((e as Map).cast<String, Object?>()),
    ],
  );
}

final walletProvider = NotifierProvider<WalletNotifier, Wallet>(
  WalletNotifier.new,
);

class WalletNotifier extends Notifier<Wallet> {
  static const _key = 'avelo.wallet.v1';

  @override
  Wallet build() {
    _load();
    return const Wallet.initial();
  }

  String get _today => dayKey(ref.read(clockProvider)());

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      state = Wallet.fromJson(jsonDecode(raw) as Map<String, Object?>);
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }

  void _add(EarnKind kind, int amount, String ref) {
    final ledger = [
      ...state.ledger,
      Earning(day: _today, kind: kind, amount: amount, ref: ref),
    ];
    state = state.copyWith(
      paws: state.paws + amount,
      ledger: ledger.length > 600
          ? ledger.sublist(ledger.length - 600)
          : ledger,
    );
  }

  /// Pays for a finished exercise, plus the daily-goal bonus the first time
  /// [doneToday] reaches the goal. Returns the paws earned.
  Future<int> rewardExercise(Exercise exercise, int doneToday) async {
    var earned = exercise.paws;
    _add(EarnKind.exercise, exercise.paws, exercise.id);
    final today = _today;
    final bonusPaid = state.ledger.any(
      (e) => e.kind == EarnKind.dailyGoal && e.day == today,
    );
    if (doneToday >= kDailyGoal && !bonusPaid) {
      _add(EarnKind.dailyGoal, kDailyGoalPaws, 'goal');
      earned += kDailyGoalPaws;
    }
    await _save();
    return earned;
  }

  /// A plan rule ticked (or unticked) today. Unticking takes the paws back,
  /// so ticks can't be farmed.
  Future<void> planRule(String ruleId, {required bool kept}) async {
    final today = _today;
    if (kept) {
      _add(EarnKind.planRule, kPawsPerRule, ruleId);
    } else {
      final i = state.ledger.lastIndexWhere(
        (e) => e.kind == EarnKind.planRule && e.ref == ruleId && e.day == today,
      );
      if (i < 0) return;
      final ledger = [...state.ledger]..removeAt(i);
      state = state.copyWith(
        paws: state.paws - state.ledger[i].amount,
        ledger: ledger,
      );
    }
    await _save();
  }

  /// Buys [item] if affordable and not owned yet.
  Future<bool> buy(Equipment item) async {
    if (state.owns(item.id) || state.paws < item.price) return false;
    state = state.copyWith(
      paws: state.paws - item.price,
      owned: [...state.owned, item.id],
    );
    await _save();
    return true;
  }

  /// Debug only.
  Future<void> reset() async {
    state = const Wallet.initial();
    await _save();
  }
}
