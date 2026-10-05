import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/paws.dart';
import '../../app/sfx.dart';
import '../../app/theme.dart';
import '../../data/equipment.dart';
import '../../data/exercises.dart';
import '../../data/wallet.dart';

/// Shop: spend paws on home-gym equipment; each piece unlocks two moves
/// that are worth more effort (and more paws) than the basics.
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
    final next = equipmentCatalog.where((e) => !wallet.owns(e.id)).firstOrNull;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              sliver: SliverList.list(
                children: [
                  _Header(paws: wallet.paws),
                  const SizedBox(height: 8),
                  _NextUp(item: next, paws: wallet.paws),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text('Equipment', style: display(22))),
                        Text(
                          '${wallet.owned.length} of ${equipmentCatalog.length} owned',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AveloColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                24 + MediaQuery.paddingOf(context).bottom,
              ),
              sliver: SliverGrid.builder(
                itemCount: equipmentCatalog.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.86,
                ),
                itemBuilder: (context, i) {
                  final item = equipmentCatalog[i];
                  return _EquipmentCard(
                    item: item,
                    owned: wallet.owns(item.id),
                    affordable: wallet.paws >= item.price,
                    paws: wallet.paws,
                    onTap: () => showEquipmentSheet(context, item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.paws});

  final int paws;

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
                const Text('HER HOME GYM', style: eyebrow),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text('Shop', style: display(28)),
                    IconButton(
                      tooltip: 'How paws work',
                      onPressed: () => _showHowItWorks(context),
                      icon: const Icon(
                        Icons.info_outline_rounded,
                        color: AveloColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PawBalance(paws: paws),
        ],
      ),
    );
  }
}

/// The next piece to save for: what it unlocks, how close you are, and a
/// buy button the moment it's affordable.
class _NextUp extends StatelessWidget {
  const _NextUp({required this.item, required this.paws});

  final Equipment? item;
  final int paws;

  @override
  Widget build(BuildContext context) {
    final item = this.item;
    if (item == null) return const _GymComplete();
    final ready = paws >= item.price;
    final share = (paws / item.price).clamp(0.0, 1.0);
    final moves = item.unlocks.map((e) => e.name).join(' & ');

    return Material(
      color: ready ? AveloColors.goldLight : AveloColors.peach,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: ready ? AveloColors.goldDeep : AveloColors.ink,
          width: ready ? 2.5 : 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showEquipmentSheet(context, item),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ready ? 'READY TO BUY' : 'SAVING FOR',
                          style: eyebrow.copyWith(
                            color: const Color(0xFF8E3F22),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(item.name, style: display(24)),
                        const SizedBox(height: 4),
                        Text(
                          'Unlocks $moves',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                            color: AveloColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Floating(
                    enabled: ready,
                    child: SizedBox(
                      width: 92,
                      height: 92,
                      child: SvgPicture.asset(item.art),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (ready)
                FilledButton(
                  onPressed: () => showEquipmentSheet(context, item),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Get it for  '),
                      PawAmount(item.price, size: 17, color: Colors.white),
                    ],
                  ),
                )
              else
                _SavingBar(share: share, paws: paws, price: item.price),
            ],
          ),
        ),
      ),
    );
  }
}

/// Progress toward a price, with "35 / 60" at the end.
class _SavingBar extends StatelessWidget {
  const _SavingBar({
    required this.share,
    required this.paws,
    required this.price,
  });

  final double share;
  final int paws;
  final int price;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$paws of $price paws saved',
      excludeSemantics: true,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: AveloColors.surface,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: AveloColors.ink, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: share),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => FractionallySizedBox(
                      widthFactor: v,
                      heightFactor: 1,
                      child: const ColoredBox(color: AveloColors.gold),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const PawCoin(size: 18),
          const SizedBox(width: 4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$paws',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                TextSpan(
                  text: ' / $price',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AveloColors.muted,
                  ),
                ),
              ],
            ),
            style: const TextStyle(
              fontSize: 14,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _GymComplete extends StatelessWidget {
  const _GymComplete();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AveloColors.sageSoft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AveloColors.ink, width: 2),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            size: 48,
            color: AveloColors.goldDeep,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GYM COMPLETE',
                  style: eyebrow.copyWith(color: AveloColors.sageDeep),
                ),
                Text('She has it all!', style: display(22)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A gentle bob for things that are ready to buy.
class _Floating extends StatefulWidget {
  const _Floating({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  State<_Floating> createState() => _FloatingState();
}

class _FloatingState extends State<_Floating>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  void _sync() {
    final on = widget.enabled && !MediaQuery.disableAnimationsOf(context);
    if (on && !_c.isAnimating) _c.repeat(reverse: true);
    if (!on && _c.isAnimating) _c.animateTo(0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_Floating old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -4 * Curves.easeInOut.transform(_c.value)),
        child: child,
      ),
      child: widget.child,
    );
  }
}

enum _CardState { owned, affordable, saving }

class _EquipmentCard extends StatelessWidget {
  const _EquipmentCard({
    required this.item,
    required this.owned,
    required this.affordable,
    required this.paws,
    required this.onTap,
  });

  final Equipment item;
  final bool owned;
  final bool affordable;
  final int paws;
  final VoidCallback onTap;

  _CardState get _state => owned
      ? _CardState.owned
      : affordable
      ? _CardState.affordable
      : _CardState.saving;

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final (tile, border, borderWidth) = switch (state) {
      _CardState.owned => (AveloColors.sageSoft, AveloColors.ink, 2.0),
      _CardState.affordable => (
        AveloColors.goldLight,
        AveloColors.goldDeep,
        2.5,
      ),
      _CardState.saving => (AveloColors.surface, AveloColors.ink, 2.0),
    };

    return Semantics(
      button: true,
      label: switch (state) {
        _CardState.owned => '${item.name}, in her gym',
        _CardState.affordable =>
          '${item.name}, ${item.price} paws, ready to buy',
        _CardState.saving =>
          '${item.name}, ${item.price} paws, ${item.price - paws} to go',
      },
      excludeSemantics: true,
      child: Material(
        color: AveloColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: border, width: borderWidth),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: tile,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 26, 16, 12),
                          child: _Floating(
                            enabled: state == _CardState.affordable,
                            child: SvgPicture.asset(item.art),
                          ),
                        ),
                      ),
                      if (state != _CardState.saving)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: state == _CardState.owned
                              ? const _Badge(
                                  icon: Icons.check_rounded,
                                  fg: Colors.white,
                                  bg: AveloColors.sageDeep,
                                )
                              : _Badge(
                                  text: '+${item.unlocks.length} moves',
                                  fg: AveloColors.text,
                                  bg: AveloColors.card,
                                ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 32,
                  child: switch (state) {
                    _CardState.owned => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'In her gym',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AveloColors.sageDeep,
                          ),
                        ),
                      ),
                    ),
                    _CardState.affordable => Container(
                      decoration: BoxDecoration(
                        color: AveloColors.terracotta,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Buy  ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          PawAmount(item.price, size: 14, color: Colors.white),
                        ],
                      ),
                    ),
                    _CardState.saving => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: PawAmount(item.price, size: 15),
                      ),
                    ),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small corner badge on a card's art: "+2 moves" or a check.
class _Badge extends StatelessWidget {
  const _Badge({required this.fg, required this.bg, this.text, this.icon});

  final String? text;
  final IconData? icon;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      constraints: const BoxConstraints(minWidth: 26),
      padding: EdgeInsets.symmetric(horizontal: text == null ? 0 : 9),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AveloColors.ink, width: 1.5),
      ),
      child: text == null
          ? Icon(icon, size: 16, color: fg)
          : Text(
              text!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
    );
  }
}

Future<void> _showHowItWorks(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: AveloColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('How paws work', style: display(24)),
            const SizedBox(height: 16),
            const _LoopStep(
              icon: Icons.directions_run_rounded,
              title: 'Move together',
              detail: 'Every exercise you finish pays paws',
            ),
            const _LoopStep(
              icon: Icons.checklist_rounded,
              title: 'Keep your plan',
              detail:
                  '+$kPawsPerRule per rule kept, +$kDailyGoalPaws when you do 3 in a day',
            ),
            const _LoopStep(
              icon: Icons.storefront_rounded,
              title: 'Equip her gym',
              detail: 'Each piece unlocks two new moves',
            ),
            const _LoopStep(
              icon: Icons.bolt_rounded,
              title: 'Bigger moves, faster progress',
              detail: 'They count for more and pay more paws',
              last: true,
            ),
          ],
        ),
      ),
    ),
  );
}

class _LoopStep extends StatelessWidget {
  const _LoopStep({
    required this.icon,
    required this.title,
    required this.detail,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AveloColors.peach,
                  shape: BoxShape.circle,
                  border: Border.all(color: AveloColors.ink, width: 2),
                ),
                child: Icon(icon, color: AveloColors.ink, size: 22),
              ),
              if (!last)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AveloColors.track,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 2, bottom: last ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    detail,
                    style: const TextStyle(color: AveloColors.muted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Detail and purchase sheet for one piece of equipment.
Future<void> showEquipmentSheet(BuildContext context, Equipment item) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AveloColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _EquipmentSheet(item: item),
  );
}

class _EquipmentSheet extends ConsumerStatefulWidget {
  const _EquipmentSheet({required this.item});

  final Equipment item;

  @override
  ConsumerState<_EquipmentSheet> createState() => _EquipmentSheetState();
}

class _EquipmentSheetState extends ConsumerState<_EquipmentSheet>
    with SingleTickerProviderStateMixin {
  late final _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  bool _justBought = false;

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  Future<void> _buy() async {
    final ok = await ref.read(walletProvider.notifier).buy(widget.item);
    if (!ok || !mounted) return;
    SfxPlayer.instance.play(Sfx.cheer);
    HapticFeedback.heavyImpact();
    setState(() => _justBought = true);
    _pop.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final wallet = ref.watch(walletProvider);
    final owned = wallet.owns(item.id);
    final short = item.price - wallet.paws;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: AnimatedBuilder(
                animation: _pop,
                builder: (context, child) {
                  final t = Curves.elasticOut.transform(_pop.value);
                  return Transform.scale(
                    scale: _pop.isAnimating ? 0.7 + 0.3 * t : 1,
                    child: child,
                  );
                },
                child: Container(
                  width: 168,
                  height: 168,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: owned ? AveloColors.sageSoft : AveloColors.peach,
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(item.art),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _justBought ? 'Added to her gym!' : item.name,
              textAlign: TextAlign.center,
              style: display(26),
            ),
            const SizedBox(height: 4),
            Text(
              _justBought ? 'Two new moves are waiting on Today.' : item.blurb,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: AveloColors.muted),
            ),
            const SizedBox(height: 20),
            Text(owned ? 'MOVES YOU UNLOCKED' : 'UNLOCKS', style: eyebrow),
            const SizedBox(height: 8),
            for (final e in item.unlocks)
              _MoveRow(exercise: e, unlocked: owned),
            const SizedBox(height: 16),
            if (owned)
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AveloColors.sageDeep,
                ),
                child: Text(_justBought ? 'Yay!' : 'Close'),
              )
            else if (short > 0)
              FilledButton(
                onPressed: null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Need '),
                    PawAmount(short, size: 17, color: AveloColors.muted),
                    const Text(' more'),
                  ],
                ),
              )
            else
              FilledButton(
                onPressed: _buy,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Buy for  '),
                    PawAmount(item.price, size: 17, color: Colors.white),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MoveRow extends StatelessWidget {
  const _MoveRow({required this.exercise, required this.unlocked});

  final Exercise exercise;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
      decoration: BoxDecoration(
        color: AveloColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AveloColors.track, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: unlocked ? AveloColors.sageSoft : AveloColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              unlocked ? exercise.icon : Icons.lock_outline_rounded,
              color: AveloColors.ink,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              exercise.name,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
          PawAmount(exercise.paws, prefix: '+', size: 14),
        ],
      ),
    );
  }
}
