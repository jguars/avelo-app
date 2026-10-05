import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/plan.dart';

/// What the add/edit sheet hands back.
sealed class PlanItemResult {
  const PlanItemResult();
}

class PlanItemSaved extends PlanItemResult {
  const PlanItemSaved(this.title, this.emoji);
  final String title;
  final String emoji;
}

class PlanItemRemoved extends PlanItemResult {
  const PlanItemRemoved();
}

/// Adds a rule to [kind]'s list, or edits [initial] when given.
///
/// [taken] hides suggestions already in the plan.
Future<PlanItemResult?> showPlanItemSheet(
  BuildContext context, {
  required PlanKind kind,
  PlanItem? initial,
  Set<String> taken = const {},
}) {
  return showModalBottomSheet<PlanItemResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AveloColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _PlanItemSheet(kind: kind, initial: initial, taken: taken),
  );
}

class _PlanItemSheet extends StatefulWidget {
  const _PlanItemSheet({
    required this.kind,
    required this.initial,
    required this.taken,
  });

  final PlanKind kind;
  final PlanItem? initial;
  final Set<String> taken;

  @override
  State<_PlanItemSheet> createState() => _PlanItemSheetState();
}

class _PlanItemSheetState extends State<_PlanItemSheet> {
  late final _title = TextEditingController(text: widget.initial?.title);
  late String _emoji =
      widget.initial?.emoji ?? (_pursue ? planEmoji.first : planEmoji[8]);

  bool get _pursue => widget.kind == PlanKind.pursue;
  bool get _editing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _title.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    Navigator.of(context).pop(PlanItemSaved(title, _emoji));
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = (_pursue ? pursueSuggestions : avoidSuggestions)
        .where((s) => !widget.taken.contains(s.title))
        .toList();
    final canSave = _title.text.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _editing
                  ? 'Edit rule'
                  : _pursue
                  ? 'Something to do more of'
                  : 'Something to skip',
              style: display(24),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              autofocus: !_editing,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              maxLength: 60,
              onSubmitted: (_) => _save(),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: _pursue
                    ? 'e.g. A walk after lunch'
                    : 'e.g. Soda with dinner',
                filled: true,
                fillColor: AveloColors.card,
                counterText: '',
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: Text(_emoji, style: const TextStyle(fontSize: 22)),
                ),
                prefixIconConstraints: const BoxConstraints(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AveloColors.ink,
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AveloColors.terracotta,
                    width: 2.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('ICON', style: eyebrow),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 8,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final e in planEmoji)
                  _EmojiChoice(
                    emoji: e,
                    selected: e == _emoji,
                    onTap: () => setState(() => _emoji = e),
                  ),
              ],
            ),
            if (!_editing && suggestions.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('IDEAS', style: eyebrow),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in suggestions)
                    ActionChip(
                      avatar: Text(s.emoji),
                      label: Text(s.title),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AveloColors.text,
                      ),
                      backgroundColor: AveloColors.card,
                      side: const BorderSide(
                        color: AveloColors.ink,
                        width: 1.5,
                      ),
                      shape: const StadiumBorder(),
                      onPressed: () => setState(() {
                        _title.text = s.title;
                        _title.selection = TextSelection.collapsed(
                          offset: s.title.length,
                        );
                        _emoji = s.emoji;
                      }),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: canSave ? _save : null,
              child: Text(_editing ? 'Save' : 'Add to plan'),
            ),
            if (_editing) ...[
              const SizedBox(height: 4),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(const PlanItemRemoved()),
                child: const Text('Remove from plan'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmojiChoice extends StatelessWidget {
  const _EmojiChoice({
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AveloColors.peach : AveloColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AveloColors.terracotta : AveloColors.track,
              width: selected ? 2.5 : 1.5,
            ),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 20)),
        ),
      ),
    );
  }
}
