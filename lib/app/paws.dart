import 'package:flutter/material.dart';

import 'theme.dart';

/// The paw coin: Avelo's currency. Earned by moving, never by food.
class PawCoin extends StatelessWidget {
  const PawCoin({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(size: Size.square(size), painter: _CoinPainter()),
  );
}

class _CoinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final c = Offset(s / 2, s / 2);
    final r = s / 2;
    canvas.drawCircle(c, r, Paint()..color = AveloColors.ink);
    canvas.drawCircle(c, r * 0.84, Paint()..color = AveloColors.gold);
    canvas.drawCircle(
      c.translate(-r * 0.14, -r * 0.14),
      r * 0.58,
      Paint()..color = AveloColors.goldLight,
    );
    canvas.drawCircle(
      c,
      r * 0.84,
      Paint()..color = AveloColors.gold.withValues(alpha: 0.55),
    );
    // Paw: one big pad and four toes.
    final paw = Paint()..color = AveloColors.goldDeep;
    canvas.drawOval(
      Rect.fromCenter(
        center: c.translate(0, r * 0.2),
        width: r * 0.62,
        height: r * 0.48,
      ),
      paw,
    );
    for (final (dx, dy) in [
      (-0.36, -0.12),
      (-0.13, -0.36),
      (0.13, -0.36),
      (0.36, -0.12),
    ]) {
      canvas.drawCircle(c.translate(r * dx, r * dy), r * 0.13, paw);
    }
  }

  @override
  bool shouldRepaint(_CoinPainter oldDelegate) => false;
}

/// A coin with an amount beside it, e.g. "🪙 120".
class PawAmount extends StatelessWidget {
  const PawAmount(
    this.amount, {
    super.key,
    this.size = 16,
    this.prefix = '',
    this.color = AveloColors.text,
  });

  final int amount;
  final double size;
  final String prefix;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$prefix$amount paws',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PawCoin(size: size * 1.2),
          SizedBox(width: size * 0.3),
          Text(
            '$prefix$amount',
            style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.w800,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Wallet balance pill for page headers; the number rolls when it changes.
class PawBalance extends StatelessWidget {
  const PawBalance({super.key, required this.paws});

  final int paws;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'You have $paws paws',
      excludeSemantics: true,
      child: Container(
        height: 44,
        padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
        decoration: BoxDecoration(
          color: AveloColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AveloColors.ink, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PawCoin(size: 26),
            const SizedBox(width: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(end: paws.toDouble()),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => Text(
                '${v.round()}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
