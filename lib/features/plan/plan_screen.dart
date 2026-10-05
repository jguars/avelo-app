import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/sfx.dart';
import '../../app/theme.dart';
import '../../data/plan.dart';
import 'plan_item_sheet.dart';

/// Plan: a short list of things to do more of and things to skip, each
/// ticked off once a day.
///
/// Positive habits come first; both lists are capped at [kMaxPlanItems] so
/// the plan stays small enough to keep.
class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(planProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            24 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            _Header(kept: plan.keptCount, total: plan.items.length),
            const SizedBox(height: 8),
            _HerNote(kept: plan.keptCount, total: plan.items.length),
            const SizedBox(height: 24),
            _Section(kind: PlanKind.pursue, plan: plan),
            const SizedBox(height: 28),
            _Section(kind: PlanKind.avoid, plan: plan),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.kept, required this.total});

  final int kept;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 0, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SMALL RULES, EVERY DAY', style: eyebrow),
                const SizedBox(height: 2),
                Text('Our plan', style: display(28)),
              ],
            ),
          ),
          if (total > 0) _KeptChip(kept: kept, total: total),
        ],
      ),
    );
  }
}

/// "2 of 5 kept" with a small progress ring.
class _KeptChip extends StatelessWidget {
  const _KeptChip({required this.kept, required this.total});

  final int kept;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$kept of $total rules kept today',
      excludeSemantics: true,
      child: Container(
        height: 44,
        padding: const EdgeInsets.fromLTRB(6, 0, 14, 0),
        decoration: BoxDecoration(
          color: AveloColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AveloColors.ink, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: kept / total),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => CircularProgressIndicator(
                  value: value,
                  strokeWidth: 4.5,
                  strokeCap: StrokeCap.round,
                  backgroundColor: AveloColors.track,
                  color: AveloColors.sageDeep,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$kept of $total kept',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

/// A line from her, with her peeking up from the card's corner.
class _HerNote extends StatelessWidget {
  const _HerNote({required this.kept, required this.total});

  final int kept;
  final int total;

  String get _line {
    if (total == 0) return 'Let’s write down a few small rules together.';
    if (kept == 0) return 'Pick one rule to keep today. Just one counts.';
    if (kept < total) return '$kept kept so far. I’m writing it all down.';
    return 'Every rule kept today. Look at us!';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      decoration: BoxDecoration(
        color: AveloColors.peach,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AveloColors.ink, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned(
              right: 2,
              bottom: -34,
              width: 132,
              child: ExcludeSemantics(
                child: SvgPicture.asset('assets/cat/bust.svg'),
              ),
            ),
            Positioned.fill(
              right: 124,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 0, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: Text(
                      _line,
                      key: ValueKey(_line),
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends ConsumerWidget {
  const _Section({required this.kind, required this.plan});

  final PlanKind kind;
  final Plan plan;

  bool get _pursue => kind == PlanKind.pursue;

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final result = await showPlanItemSheet(
      context,
      kind: kind,
      taken: plan.items.map((i) => i.title).toSet(),
    );
    if (result case PlanItemSaved(:final title, :final emoji)) {
      await ref.read(planProvider.notifier).add(kind, title, emoji);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = plan.of(kind);
    final full = items.length >= kMaxPlanItems;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    _pursue ? 'Do more of' : 'Skip',
                    style: display(22),
                  ),
                ),
              ),
              Text(
                '${items.length} of $kMaxPlanItems',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AveloColors.muted,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 2, 4, 12),
          child: Text(
            _pursue
                ? 'Small things that add up. Tick them when done.'
                : 'Tick one when you’ve held off for the day.',
            style: const TextStyle(color: AveloColors.muted, fontSize: 14),
          ),
        ),
        for (final item in items) ...[
          _PlanRow(item: item, kept: plan.kept.contains(item.id)),
          const SizedBox(height: 10),
        ],
        if (full)
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 2, 4, 0),
            child: Text(
              'Five is plenty. Small plans are the ones that stick.',
              style: TextStyle(color: AveloColors.muted, fontSize: 14),
            ),
          )
        else
          _AddRow(
            label: _pursue ? 'Add something to do' : 'Add something to skip',
            onTap: () => _add(context, ref),
          ),
      ],
    );
  }
}

class _PlanRow extends ConsumerWidget {
  const _PlanRow({required this.item, required this.kept});

  final PlanItem item;
  final bool kept;

  bool get _pursue => item.kind == PlanKind.pursue;

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final result = await showPlanItemSheet(
      context,
      kind: item.kind,
      initial: item,
    );
    if (!context.mounted) return;
    switch (result) {
      case PlanItemSaved(:final title, :final emoji):
        await ref
            .read(planProvider.notifier)
            .update(item.copyWith(title: title, emoji: emoji));
      case PlanItemRemoved():
        await _remove(context, ref);
      case null:
        break;
    }
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final undo = await ref.read(planProvider.notifier).remove(item);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Removed “${item.title}”'),
          action: SnackBarAction(label: 'Undo', onPressed: undo),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tint = _pursue ? AveloColors.sageSoft : AveloColors.peach;
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _remove(context, ref),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AveloColors.terracotta,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, color: Colors.white),
            SizedBox(width: 6),
            Text(
              'Remove',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: kept ? tint : AveloColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AveloColors.ink, width: 2),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _edit(context, ref),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: kept ? AveloColors.card : tint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.25,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          alignment: Alignment.topLeft,
                          child: kept
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    _pursue ? 'Done today' : 'Held off today',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AveloColors.sageDeep,
                                    ),
                                  ),
                                )
                              : const SizedBox(width: double.infinity),
                        ),
                      ],
                    ),
                  ),
                  _KeepButton(
                    kept: kept,
                    label: _pursue
                        ? 'Done today: ${item.title}'
                        : 'Held off today: ${item.title}',
                    onTap: () {
                      if (!kept) SfxPlayer.instance.play(Sfx.pop);
                      ref.read(planProvider.notifier).toggleKept(item);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A round check, filled once the rule is kept today.
class _KeepButton extends StatelessWidget {
  const _KeepButton({
    required this.kept,
    required this.label,
    required this.onTap,
  });

  final bool kept;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: kept,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 26,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: kept ? 1 : 0),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              builder: (context, t, _) => Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.lerp(
                    AveloColors.card,
                    AveloColors.sageDeep,
                    t.clamp(0.0, 1.0),
                  ),
                  border: Border.all(
                    color: kept ? AveloColors.sageDeep : AveloColors.ink,
                    width: 2,
                  ),
                ),
                child: Transform.scale(
                  scale: math.max(0, t),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dashed "+ Add" row at the end of a list.
class _AddRow extends StatelessWidget {
  const _AddRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: CustomPaint(
        painter: _DashedBorder(),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 56,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_rounded, color: AveloColors.terracotta),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AveloColors.terracotta,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(1),
      const Radius.circular(18),
    );
    final paint = Paint()
      ..color = AveloColors.muted
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 12) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder oldDelegate) => false;
}
