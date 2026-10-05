import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'progress.dart';
import 'wallet.dart';

/// Which list a rule belongs to.
enum PlanKind {
  /// Small things to do more of.
  pursue,

  /// Things to skip.
  avoid,
}

/// Each list stays short: a few rules kept beat a long list ignored.
const int kMaxPlanItems = 5;

class PlanItem {
  const PlanItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.emoji,
  });

  final String id;
  final PlanKind kind;
  final String title;
  final String emoji;

  PlanItem copyWith({String? title, String? emoji}) => PlanItem(
    id: id,
    kind: kind,
    title: title ?? this.title,
    emoji: emoji ?? this.emoji,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'title': title,
    'emoji': emoji,
  };

  factory PlanItem.fromJson(Map<String, Object?> json) => PlanItem(
    id: json['id'] as String,
    kind: PlanKind.values.byName(json['kind'] as String),
    title: json['title'] as String,
    emoji: json['emoji'] as String? ?? '⭐',
  );
}

/// A ready-made rule offered when adding one.
class PlanSuggestion {
  const PlanSuggestion(this.emoji, this.title);
  final String emoji;
  final String title;
}

const pursueSuggestions = <PlanSuggestion>[
  PlanSuggestion('💧', 'A glass of water before each meal'),
  PlanSuggestion('🚶', 'A 10-minute walk after dinner'),
  PlanSuggestion('🥦', 'Vegetables with lunch'),
  PlanSuggestion('🍳', 'Protein at breakfast'),
  PlanSuggestion('🍽️', 'Eat slowly, put the fork down between bites'),
  PlanSuggestion('🛏️', 'In bed by 11'),
  PlanSuggestion('🍎', 'Fruit for the afternoon snack'),
  PlanSuggestion('🪜', 'Take the stairs'),
];

const avoidSuggestions = <PlanSuggestion>[
  PlanSuggestion('🥤', 'Sugary drinks'),
  PlanSuggestion('🌙', 'Snacking after 9 pm'),
  PlanSuggestion('🍔', 'Fast food'),
  PlanSuggestion('🍰', 'Desserts on weekdays'),
  PlanSuggestion('🍽️', 'Second helpings'),
  PlanSuggestion('📱', 'Eating in front of a screen'),
  PlanSuggestion('🍺', 'Alcohol on weeknights'),
  PlanSuggestion('🍟', 'Chips from the bag'),
];

/// Emoji offered in the add/edit sheet.
const planEmoji = [
  '💧', '🚶', '🥦', '🍳', '🍎', '🛏️', '🪜', '🧘', //
  '🥤', '🌙', '🍔', '🍰', '🍽️', '📱', '🍺', '🍟',
];

class Plan {
  const Plan({required this.items, required this.day, required this.kept});

  final List<PlanItem> items;

  /// The calendar day (yyyy-mm-dd) [kept] belongs to.
  final String day;

  /// Ids of rules kept on [day].
  final List<String> kept;

  List<PlanItem> of(PlanKind kind) =>
      items.where((i) => i.kind == kind).toList();

  int get keptCount => items.where((i) => kept.contains(i.id)).length;

  Plan copyWith({List<PlanItem>? items, String? day, List<String>? kept}) =>
      Plan(
        items: items ?? this.items,
        day: day ?? this.day,
        kept: kept ?? this.kept,
      );

  Map<String, Object?> toJson() => {
    'items': [for (final i in items) i.toJson()],
    'day': day,
    'kept': kept,
  };

  factory Plan.fromJson(Map<String, Object?> json) => Plan(
    items: [
      for (final i in (json['items'] as List? ?? const []))
        PlanItem.fromJson((i as Map).cast<String, Object?>()),
    ],
    day: json['day'] as String? ?? '',
    kept: (json['kept'] as List?)?.cast<String>() ?? const [],
  );
}

/// A starting plan, so the page is never empty; every rule can be edited.
const _starter = <PlanItem>[
  PlanItem(
    id: 'p1',
    kind: PlanKind.pursue,
    title: 'A glass of water before each meal',
    emoji: '💧',
  ),
  PlanItem(
    id: 'p2',
    kind: PlanKind.pursue,
    title: 'A 10-minute walk after dinner',
    emoji: '🚶',
  ),
  PlanItem(
    id: 'p3',
    kind: PlanKind.pursue,
    title: 'Vegetables with lunch',
    emoji: '🥦',
  ),
  PlanItem(id: 'a1', kind: PlanKind.avoid, title: 'Sugary drinks', emoji: '🥤'),
  PlanItem(
    id: 'a2',
    kind: PlanKind.avoid,
    title: 'Snacking after 9 pm',
    emoji: '🌙',
  ),
];

final planProvider = NotifierProvider<PlanNotifier, Plan>(PlanNotifier.new);

class PlanNotifier extends Notifier<Plan> {
  static const _key = 'avelo.plan.v1';

  @override
  Plan build() {
    _load();
    return Plan(items: _starter, day: _today, kept: const []);
  }

  String get _today => dayKey(ref.read(clockProvider)());

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      await _save();
      return;
    }
    state = _rollover(Plan.fromJson(jsonDecode(raw) as Map<String, Object?>));
  }

  /// A new day starts with nothing kept yet.
  Plan _rollover(Plan p) =>
      p.day == _today ? p : p.copyWith(day: _today, kept: const []);

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }

  Future<void> add(PlanKind kind, String title, String emoji) async {
    if (state.of(kind).length >= kMaxPlanItems) return;
    final id = '${kind.name[0]}${DateTime.now().microsecondsSinceEpoch}';
    state = _rollover(state).copyWith(
      items: [
        ...state.items,
        PlanItem(id: id, kind: kind, title: title, emoji: emoji),
      ],
    );
    await _save();
  }

  Future<void> update(PlanItem item) async {
    state = state.copyWith(
      items: [for (final i in state.items) i.id == item.id ? item : i],
    );
    await _save();
  }

  /// Removes [item]; returns a callback that puts it back where it was.
  Future<Future<void> Function()> remove(PlanItem item) async {
    final before = state;
    final wasKept = state.kept.contains(item.id) && state.day == _today;
    final wallet = ref.read(walletProvider.notifier);
    if (wasKept) await wallet.planRule(item.id, kept: false);
    state = state.copyWith(
      items: state.items.where((i) => i.id != item.id).toList(),
      kept: state.kept.where((id) => id != item.id).toList(),
    );
    await _save();
    return () async {
      state = before;
      await _save();
      if (wasKept) await wallet.planRule(item.id, kept: true);
    };
  }

  /// Marks [item] kept (or not) today.
  Future<void> toggleKept(PlanItem item) async {
    final p = _rollover(state);
    final kept = !p.kept.contains(item.id);
    state = p.copyWith(
      kept: kept
          ? [...p.kept, item.id]
          : p.kept.where((id) => id != item.id).toList(),
    );
    await Future.wait([
      _save(),
      ref.read(walletProvider.notifier).planRule(item.id, kept: kept),
    ]);
  }
}
