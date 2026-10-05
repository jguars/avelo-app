import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/paws.dart';
import '../../app/sfx.dart';
import '../../app/theme.dart';
import '../../data/exercises.dart';
import '../../data/progress.dart';
import '../cat/cat_view.dart';
import '../../data/milestones.dart';

/// Shown after every finished exercise: she cheers, confetti flies, and the
/// journey bar visibly moves, so progress feels earned even when her shape
/// changes only a little.
Future<void> showCelebration(
  BuildContext context, {
  required Exercise exercise,
  required double journeyBefore,
  required Progress progress,
  required int paws,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AveloColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _CelebrationSheet(
      exercise: exercise,
      journeyBefore: journeyBefore,
      progress: progress,
      paws: paws,
    ),
  );
}

class _CelebrationSheet extends StatefulWidget {
  const _CelebrationSheet({
    required this.exercise,
    required this.journeyBefore,
    required this.progress,
    required this.paws,
  });

  final Exercise exercise;
  final double journeyBefore;
  final Progress progress;

  /// Paws earned, including any daily-goal bonus.
  final int paws;

  @override
  State<_CelebrationSheet> createState() => _CelebrationSheetState();
}

class _CelebrationSheetState extends State<_CelebrationSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confetti = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void initState() {
    super.initState();
    SfxPlayer.instance.play(Sfx.cheer);
    HapticFeedback.heavyImpact();
    _confetti.forward();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.progress;
    final done = p.doneToday.length;
    final goalJustMet = done == kDailyGoal;
    final next = milestones.where((m) => !isReached(m, p)).firstOrNull;
    final nextLine = next == null
        ? 'She has reached her fit shape. Keep her company!'
        : 'About ${(next.plannedEffort - p.effort).ceil()} more exercises '
              'to D${next.day}';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AveloColors.track,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Blush rug she hops on.
                  Positioned(
                    bottom: 8,
                    child: Container(
                      width: 230,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AveloColors.blush,
                        borderRadius: const BorderRadius.all(
                          Radius.elliptical(115, 22),
                        ),
                        border: Border.all(color: AveloColors.ink, width: 2),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    width: 190,
                    height: 222,
                    child: CatView(
                      bodyMass: p.bodyMass,
                      energy: 100,
                      exercising: true,
                      move: CatMove.cheer,
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _confetti,
                        builder: (context, _) => CustomPaint(
                          painter: _ConfettiPainter(_confetti.value),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              goalJustMet ? 'Three together!' : 'You both did it!',
              textAlign: TextAlign.center,
              style: display(28),
            ),
            const SizedBox(height: 6),
            Text(
              goalJustMet
                  ? "That's today's goal. She is so proud of you."
                  : '${widget.exercise.name} done. She is a little lighter now.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AveloColors.muted, fontSize: 15),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Chip(
                  leading: const PawCoin(size: 20),
                  text: '+${widget.paws} paws',
                ),
                const SizedBox(width: 8),
                _Chip(
                  leading: const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                    color: AveloColors.terracotta,
                  ),
                  text: '${math.min(done, kDailyGoal)} of $kDailyGoal today',
                ),
              ],
            ),
            const SizedBox(height: 18),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: widget.journeyBefore, end: p.journey),
              duration: const Duration(milliseconds: 1400),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Her journey',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Text(
                        '${(value * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 14,
                      backgroundColor: AveloColors.track,
                      color: AveloColors.terracotta,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              nextLine,
              style: const TextStyle(color: AveloColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to her'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.leading, required this.text});

  final Widget leading;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AveloColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AveloColors.ink, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

/// A one-shot burst of paper confetti in the cat's palette.
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t);

  /// 0..1 progress of the burst.
  final double t;

  static const _colors = [
    AveloColors.coral,
    AveloColors.fur,
    AveloColors.blush,
    Color(0xFF93AC8C), // sofa sage
    Color(0xFFF6D68A), // sun
  ];

  // Fixed particles so every burst looks the same and nothing is allocated
  // per frame.
  static final _particles = List.generate(36, (i) {
    final r = math.Random(i * 7919);
    final angle = -math.pi / 2 + (r.nextDouble() - 0.5) * math.pi * 1.1;
    return (
      angle: angle,
      speed: 160 + r.nextDouble() * 170,
      spin: (r.nextDouble() - 0.5) * 14,
      color: _colors[i % _colors.length],
      w: 6 + r.nextDouble() * 6,
      h: 9 + r.nextDouble() * 7,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final origin = Offset(size.width / 2, size.height * 0.55);
    final fade = t < 0.75 ? 1.0 : 1 - (t - 0.75) / 0.25;
    final paint = Paint();
    for (final p in _particles) {
      // Launch outwards, then fall under gravity.
      final d = p.speed * t;
      final pos =
          origin +
          Offset(math.cos(p.angle) * d, math.sin(p.angle) * d + 320 * t * t);
      paint.color = p.color.withValues(alpha: fade);
      canvas
        ..save()
        ..translate(pos.dx, pos.dy)
        ..rotate(p.spin * t)
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.w, height: p.h),
            const Radius.circular(2),
          ),
          paint,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
