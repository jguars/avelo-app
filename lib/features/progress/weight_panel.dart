import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/theme.dart';
import '../../data/weight.dart';
import 'weight_chart.dart';

/// Your weight: where you are, the trend against the plan, and every
/// weigh-in. Weigh in as often as you like.
class WeightPanel extends ConsumerStatefulWidget {
  const WeightPanel({super.key});

  @override
  ConsumerState<WeightPanel> createState() => _WeightPanelState();
}

class _WeightPanelState extends ConsumerState<WeightPanel> {
  int? _days = 30;
  bool _showAll = false;

  Future<void> _logWeight() async {
    final log = ref.read(weightProvider);
    final kg = await showKgSheet(
      context,
      title: 'Log your weight',
      initial: log.latest?.kg ?? 90,
      action: 'Save',
    );
    if (kg != null) await ref.read(weightProvider.notifier).log(kg);
  }

  Future<void> _setGoal() async {
    final log = ref.read(weightProvider);
    final kg = await showKgSheet(
      context,
      title: 'Your goal weight',
      initial: log.goalKg ?? ((log.latest?.kg ?? 90) - 5),
      action: 'Set goal',
    );
    if (kg != null) await ref.read(weightProvider.notifier).setGoal(kg);
  }

  @override
  Widget build(BuildContext context) {
    final log = ref.watch(weightProvider);
    final bottom = 24 + MediaQuery.paddingOf(context).bottom;

    if (log.entries.isEmpty) {
      return _Empty(onLog: _logWeight, bottom: bottom);
    }

    final entries = log.entries.reversed.toList();
    final shown = _showAll ? entries : entries.take(5).toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 4, 16, bottom),
      children: [
        _Stats(log: log, onSetGoal: _setGoal),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            color: AveloColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AveloColors.ink, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WeightChart(log: log, days: _days),
              const SizedBox(height: 12),
              _RangePicker(
                value: _days,
                onChanged: (d) => setState(() => _days = d),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _logWeight,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Log weight'),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text('Weigh-ins', style: display(22)),
        ),
        for (final (i, e) in shown.indexed)
          _EntryRow(
            entry: e,
            previous: i + 1 < entries.length ? entries[i + 1] : null,
          ),
        if (entries.length > 5)
          TextButton(
            onPressed: () => setState(() => _showAll = !_showAll),
            child: Text(_showAll ? 'Show less' : 'Show all ${entries.length}'),
          ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onLog, required this.bottom});

  final VoidCallback onLog;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(24, 24, 24, bottom),
      children: [
        Center(
          child: Container(
            width: 168,
            height: 168,
            decoration: const BoxDecoration(
              color: AveloColors.peach,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: SvgPicture.asset('assets/cat/bust.svg'),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Let’s see where we start',
          textAlign: TextAlign.center,
          style: display(24),
        ),
        const SizedBox(height: 6),
        const Text(
          'One weigh-in sets your starting point and plan line.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: AveloColors.muted),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onLog,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Log first weigh-in'),
        ),
      ],
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.log, required this.onSetGoal});

  final WeightLog log;
  final VoidCallback onSetGoal;

  @override
  Widget build(BuildContext context) {
    final change = log.change;
    final goal = log.goalKg;
    final left = goal == null ? null : log.latest!.kg - goal;
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'NOW',
            value: log.latest!.kg.toStringAsFixed(1),
            unit: 'kg',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'CHANGE',
            value:
                '${change > 0
                    ? '+'
                    : change < 0
                    ? '−'
                    : ''}'
                '${change.abs().toStringAsFixed(1)}',
            unit: 'kg',
            valueColor: change < 0 ? AveloColors.sageDeep : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'TO GOAL',
            value: left == null
                ? 'Set'
                : left <= 0
                ? 'Done!'
                : left.toStringAsFixed(1),
            unit: left == null || left <= 0 ? '' : 'kg',
            onTap: onSetGoal,
            valueColor: left == null ? AveloColors.terracotta : null,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.unit,
    this.valueColor,
    this.onTap,
  });

  final String label;
  final String value;
  final String unit;
  final Color? valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AveloColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AveloColors.ink, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(label, style: eyebrow.copyWith(fontSize: 11)),
                  if (onTap != null) ...[
                    const Spacer(),
                    const Icon(
                      Icons.edit_rounded,
                      size: 14,
                      color: AveloColors.muted,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: TextStyle(
                          fontFamily: AveloFonts.display,
                          fontSize: 24,
                          color: valueColor ?? AveloColors.text,
                        ),
                      ),
                      if (unit.isNotEmpty)
                        TextSpan(
                          text: ' $unit',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AveloColors.muted,
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
    );
  }
}

class _RangePicker extends StatelessWidget {
  const _RangePicker({required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = <(String, int?)>[
      ('2W', 14),
      ('1M', 30),
      ('3M', 90),
      ('All', null),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final (label, days) in options)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(label),
              selected: value == days,
              onSelected: (_) => onChanged(days),
              showCheckmark: false,
              labelStyle: TextStyle(
                fontWeight: FontWeight.w800,
                color: value == days ? Colors.white : AveloColors.muted,
              ),
              selectedColor: AveloColors.ink,
              backgroundColor: AveloColors.surface,
              side: BorderSide.none,
              shape: const StadiumBorder(),
            ),
          ),
      ],
    );
  }
}

class _EntryRow extends ConsumerWidget {
  const _EntryRow({required this.entry, required this.previous});

  final WeightEntry entry;
  final WeightEntry? previous;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = entry.at;
    final time =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    final delta = previous == null ? null : entry.kg - previous!.kg;
    return Dismissible(
      key: ObjectKey(entry),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AveloColors.terracotta,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) async {
        final messenger = ScaffoldMessenger.of(context);
        final undo = await ref.read(weightProvider.notifier).remove(entry);
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Text('Weigh-in removed'),
              action: SnackBarAction(label: 'Undo', onPressed: undo),
            ),
          );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AveloColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AveloColors.track, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${_months[d.month - 1]} ${d.day}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(
                      text: '  $time',
                      style: const TextStyle(color: AveloColors.muted),
                    ),
                  ],
                ),
                style: const TextStyle(fontSize: 15),
              ),
            ),
            if (delta != null && delta.abs() >= 0.05)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  '${delta > 0 ? '+' : '−'}${delta.abs().toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: delta < 0 ? AveloColors.sageDeep : AveloColors.muted,
                  ),
                ),
              ),
            Text(
              '${entry.kg.toStringAsFixed(1)} kg',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

/// A big kg picker: type it, or nudge it with − / + (hold to repeat).
Future<double?> showKgSheet(
  BuildContext context, {
  required String title,
  required double initial,
  required String action,
}) {
  return showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AveloColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _KgSheet(title: title, initial: initial, action: action),
  );
}

class _KgSheet extends StatefulWidget {
  const _KgSheet({
    required this.title,
    required this.initial,
    required this.action,
  });

  final String title;
  final double initial;
  final String action;

  @override
  State<_KgSheet> createState() => _KgSheetState();
}

class _KgSheetState extends State<_KgSheet> {
  late final _text = TextEditingController(
    text: widget.initial.toStringAsFixed(1),
  );

  double? get _value {
    final v = double.tryParse(_text.text.replaceAll(',', '.'));
    return v != null && v >= 30 && v <= 300 ? v : null;
  }

  void _nudge(double by) {
    final v = (_value ?? widget.initial) + by;
    HapticFeedback.selectionClick();
    setState(() => _text.text = v.clamp(30, 300).toStringAsFixed(1));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final valid = _value != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, textAlign: TextAlign.center, style: display(24)),
              const SizedBox(height: 20),
              Row(
                children: [
                  _NudgeButton(
                    icon: Icons.remove_rounded,
                    onTap: () => _nudge(-0.1),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _text,
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                        fontFamily: AveloFonts.display,
                        fontSize: 48,
                        color: AveloColors.text,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        suffixText: 'kg',
                        suffixStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AveloColors.muted,
                        ),
                      ),
                    ),
                  ),
                  _NudgeButton(
                    icon: Icons.add_rounded,
                    onTap: () => _nudge(0.1),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: valid
                    ? () =>
                          Navigator.of(context)
                              .pop(double.parse(_value!.toStringAsFixed(1)))
                    : null,
                child: Text(widget.action),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get title => widget.title;
}

class _NudgeButton extends StatefulWidget {
  const _NudgeButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_NudgeButton> createState() => _NudgeButtonState();
}

class _NudgeButtonState extends State<_NudgeButton> {
  bool _held = false;

  Future<void> _repeat() async {
    _held = true;
    var delay = 300;
    while (_held && mounted) {
      widget.onTap();
      await Future<void>.delayed(Duration(milliseconds: delay));
      delay = (delay * 0.8).clamp(50, 300).round();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.icon == Icons.add_rounded ? 'Add 0.1 kg' : 'Remove 0.1 kg',
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPressStart: (_) => _repeat(),
        onLongPressEnd: (_) => _held = false,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AveloColors.card,
            shape: BoxShape.circle,
            border: Border.all(color: AveloColors.ink, width: 2),
          ),
          child: Icon(widget.icon, color: AveloColors.ink, size: 28),
        ),
      ),
    );
  }
}
