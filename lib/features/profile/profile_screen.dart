import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/nav.dart';
import '../../app/paws.dart';
import '../../app/theme.dart';
import '../../data/equipment.dart';
import '../../data/plan.dart';
import '../../data/profile.dart';
import '../../data/progress.dart';
import '../../data/wallet.dart';
import '../../data/weight.dart';
import '../dev/cat_lab_screen.dart';
import '../progress/weight_panel.dart' show showKgSheet;

/// Profile: the two of you, this week at a glance, and settings.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final progress = ref.watch(progressProvider);
    final wallet = ref.watch(walletProvider);
    final plan = ref.watch(planProvider);
    final weight = ref.watch(weightProvider);
    final now = ref.watch(clockProvider)();
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final weekStart = dayKey(monday);
    final daysThisWeek = now.weekday;
    final rulesPossible = plan.items.length * daysThisWeek;
    final rulesKept = wallet.countSince(EarnKind.planRule, weekStart);

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
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 0, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('THE TWO OF US', style: eyebrow),
                  const SizedBox(height: 2),
                  Text('Profile', style: display(28)),
                ],
              ),
            ),
            _DuoCard(profile: profile, days: progress.dayNumber + 1),
            const SizedBox(height: 24),
            _SectionTitle('This week'),
            Row(
              children: [
                Expanded(
                  child: _WeekTile(
                    icon: Icons.directions_run_rounded,
                    value: '${wallet.countSince(EarnKind.exercise, weekStart)}',
                    label: 'exercises',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _WeekTile(
                    icon: Icons.checklist_rounded,
                    value: '$rulesKept',
                    label: 'rules kept',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _WeekTile(
                    coin: true,
                    value: '${wallet.earnedSince(weekStart)}',
                    label: 'paws earned',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _PlanReport(kept: rulesKept, possible: rulesPossible),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _LinkTile(
                    title: 'Weight',
                    value: weight.latest == null
                        ? 'Log it'
                        : '${weight.latest!.kg.toStringAsFixed(1)} kg',
                    onTap: () =>
                        ref.read(tabProvider.notifier).go(AveloTab.progress),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _LinkTile(
                    title: 'Her gym',
                    value:
                        '${wallet.owned.length} of ${equipmentCatalog.length}',
                    trailing: wallet.owned.isEmpty
                        ? null
                        : SizedBox(
                            width: 28,
                            height: 28,
                            child: SvgPicture.asset(
                              equipmentById(wallet.owned.last).art,
                            ),
                          ),
                    onTap: () =>
                        ref.read(tabProvider.notifier).go(AveloTab.shop),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionTitle('Settings'),
            _Settings(profile: profile, weight: weight),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 10),
    child: Text(text, style: display(22)),
  );
}

/// The user and the cat, side by side.
class _DuoCard extends StatelessWidget {
  const _DuoCard({required this.profile, required this.days});

  final Profile profile;
  final int days;

  @override
  Widget build(BuildContext context) {
    final you = profile.name.isEmpty ? 'You' : profile.name;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      decoration: BoxDecoration(
        color: AveloColors.peach,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AveloColors.ink, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AveloColors.terracotta,
                      shape: BoxShape.circle,
                      border: Border.all(color: AveloColors.ink, width: 2),
                    ),
                    child: Text(
                      you.characters.first.toUpperCase(),
                      style: display(24, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('$you & ${profile.catName}', style: display(22)),
                  const SizedBox(height: 2),
                  Text(
                    days == 1 ? 'Day one together' : 'Together for $days days',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AveloColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 120,
            child: Transform.translate(
              offset: const Offset(6, 14),
              child: SvgPicture.asset('assets/cat/bust.svg'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekTile extends StatelessWidget {
  const _WeekTile({
    required this.value,
    required this.label,
    this.icon,
    this.coin = false,
  });

  final IconData? icon;
  final bool coin;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$value $label this week',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 14),
        decoration: BoxDecoration(
          color: AveloColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AveloColors.ink, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            coin
                ? const PawCoin(size: 22)
                : Icon(icon, size: 22, color: AveloColors.terracotta),
            const SizedBox(height: 8),
            Text(value, style: display(26)),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AveloColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanReport extends StatelessWidget {
  const _PlanReport({required this.kept, required this.possible});

  final int kept;
  final int possible;

  @override
  Widget build(BuildContext context) {
    final share = possible == 0 ? 0.0 : (kept / possible).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AveloColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AveloColors.ink, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Plan kept',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${(share * 100).round()}%',
                style: display(20, color: AveloColors.sageDeep),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: share,
              minHeight: 10,
              backgroundColor: AveloColors.track,
              color: AveloColors.sageDeep,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$kept of $possible rule-days this week',
            style: const TextStyle(fontSize: 13, color: AveloColors.muted),
          ),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.title,
    required this.value,
    required this.onTap,
    this.trailing,
  });

  final String title;
  final String value;
  final VoidCallback onTap;
  final Widget? trailing;

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
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: eyebrow.copyWith(fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
              const Icon(Icons.chevron_right_rounded, color: AveloColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _Settings extends ConsumerWidget {
  const _Settings({required this.profile, required this.weight});

  final Profile profile;
  final WeightLog weight;

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String initial,
    required Profile Function(String) apply,
  }) async {
    final controller = TextEditingController(text: initial);
    final value = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AveloColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: display(24)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: 20,
              textCapitalization: TextCapitalization.words,
              onSubmitted: (v) => Navigator.of(context).pop(v),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                filled: true,
                fillColor: AveloColors.card,
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AveloColors.ink,
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AveloColors.ink,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    final trimmed = value?.trim();
    if (trimmed == null) return;
    await ref.read(profileProvider.notifier).update(apply(trimmed));
  }

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start over?'),
        content: const Text(
          'Her shape, your paws and her gym go back to day one. '
          'Your plan and weigh-ins stay.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Start over'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(progressProvider.notifier).reset();
    await ref.read(walletProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(profileProvider.notifier);
    return Material(
      color: AveloColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AveloColors.ink, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _SettingRow(
            icon: Icons.person_outline_rounded,
            title: 'Your name',
            value: profile.name.isEmpty ? 'Add' : profile.name,
            onTap: () => _editName(
              context,
              ref,
              title: 'What should she call you?',
              initial: profile.name,
              apply: (v) => profile.copyWith(name: v),
            ),
          ),
          _SettingRow(
            icon: Icons.pets_rounded,
            title: 'Her name',
            value: profile.catName,
            onTap: () => _editName(
              context,
              ref,
              title: 'Name your cat',
              initial: profile.catName,
              apply: (v) => profile.copyWith(catName: v.isEmpty ? 'Mochi' : v),
            ),
          ),
          _SettingRow(
            icon: Icons.flag_outlined,
            title: 'Goal weight',
            value: weight.goalKg == null
                ? 'Set'
                : '${weight.goalKg!.toStringAsFixed(1)} kg',
            onTap: () async {
              final kg = await showKgSheet(
                context,
                title: 'Your goal weight',
                initial: weight.goalKg ?? ((weight.latest?.kg ?? 90) - 5),
                action: 'Set goal',
              );
              if (kg != null) {
                await ref.read(weightProvider.notifier).setGoal(kg);
              }
            },
          ),
          SwitchListTile(
            secondary: const Icon(
              Icons.volume_up_outlined,
              color: AveloColors.ink,
            ),
            title: const Text(
              'Sound effects',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            value: profile.sound,
            activeTrackColor: AveloColors.sageDeep,
            onChanged: (v) => notifier.update(profile.copyWith(sound: v)),
          ),
          const Divider(height: 1, color: AveloColors.track),
          _SettingRow(
            icon: Icons.science_outlined,
            title: 'Cat lab',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const CatLabScreen())),
          ),
          _SettingRow(
            icon: Icons.restart_alt_rounded,
            title: 'Start over',
            danger: true,
            last: true,
            onTap: () => _reset(context, ref),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.value,
    this.danger = false,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback onTap;
  final bool danger;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AveloColors.terracotta : AveloColors.ink;
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: color),
          title: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w700, color: color),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (value != null)
                Text(
                  value!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AveloColors.muted,
                  ),
                ),
              const Icon(Icons.chevron_right_rounded, color: AveloColors.muted),
            ],
          ),
          onTap: onTap,
        ),
        if (!last) const Divider(height: 1, color: AveloColors.track),
      ],
    );
  }
}
