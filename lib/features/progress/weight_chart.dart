import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/weight.dart';

/// Logged weight (solid terracotta, one point per day: the day's last
/// weigh-in) against the plan (dashed blue), with an optional goal line.
/// Touch and drag to read any day.
class WeightChart extends StatefulWidget {
  const WeightChart({super.key, required this.log, required this.days});

  final WeightLog log;

  /// Days shown, ending today; null shows everything since the first log.
  final int? days;

  @override
  State<WeightChart> createState() => _WeightChartState();
}

class _WeightChartState extends State<WeightChart> {
  int? _touched;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _date(DateTime d) => '${_months[d.month - 1]} ${d.day}';

  @override
  Widget build(BuildContext context) {
    final data = _ChartData.from(widget.log, widget.days);
    final touched = _touched;
    final t = touched == null ? null : data.daily[touched];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 28,
          child: t == null
              ? const _Legend()
              : Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${_date(t.day)}  ',
                        style: const TextStyle(color: AveloColors.muted),
                      ),
                      TextSpan(
                        text: '${t.kg.toStringAsFixed(1)} kg',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      if (widget.log.plannedOn(t.day) case final plan?)
                        TextSpan(
                          text: '   plan ${plan.toStringAsFixed(1)}',
                          style: const TextStyle(color: AveloColors.muted),
                        ),
                    ],
                  ),
                  style: const TextStyle(fontSize: 15),
                ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, box) {
            final size = Size(box.maxWidth, 190);
            void touch(Offset p) {
              final i = data.nearest(p.dx, size);
              if (i != _touched) setState(() => _touched = i);
            }

            return Semantics(
              label: data.summary,
              child: GestureDetector(
                onTapDown: (d) => touch(d.localPosition),
                onHorizontalDragStart: (d) => touch(d.localPosition),
                onHorizontalDragUpdate: (d) => touch(d.localPosition),
                onHorizontalDragEnd: (_) => setState(() => _touched = null),
                onTapUp: (_) => setState(() => _touched = null),
                child: CustomPaint(
                  size: size,
                  painter: _ChartPainter(data: data, touched: _touched),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              _date(data.start),
              style: const TextStyle(fontSize: 12, color: AveloColors.muted),
            ),
            const Spacer(),
            Text(
              _date(data.end),
              style: const TextStyle(fontSize: 12, color: AveloColors.muted),
            ),
            const SizedBox(width: 36),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget item(String label, Color color, {bool dashed = false}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(22, 10),
          painter: _LegendLine(color, dashed),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AveloColors.muted,
          ),
        ),
      ],
    );
    return Row(
      children: [
        item('You', AveloColors.terracotta),
        const SizedBox(width: 16),
        item('Plan', AveloColors.chartPlan, dashed: true),
      ],
    );
  }
}

class _LegendLine extends CustomPainter {
  _LegendLine(this.color, this.dashed);
  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    if (dashed) {
      for (var x = 0.0; x < size.width; x += 8) {
        canvas.drawLine(
          Offset(x, y),
          Offset(math.min(x + 4, size.width), y),
          p,
        );
      }
    } else {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(_LegendLine old) => false;
}

class _DayPoint {
  const _DayPoint(this.day, this.kg);
  final DateTime day;
  final double kg;
}

class _ChartData {
  _ChartData({
    required this.daily,
    required this.start,
    required this.end,
    required this.lo,
    required this.hi,
    required this.log,
  });

  final List<_DayPoint> daily;
  final DateTime start;
  final DateTime end;
  final double lo;
  final double hi;
  final WeightLog log;

  static DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

  factory _ChartData.from(WeightLog log, int? days) {
    final today = _day(DateTime.now());
    final first = _day(log.first!.at);
    var start = days == null ? first : today.subtract(Duration(days: days - 1));
    if (start.isBefore(first) && days == null) start = first;
    // Always show at least a week so a single point isn't jammed at an edge.
    if (today.difference(start).inDays < 6) {
      start = today.subtract(const Duration(days: 6));
    }

    final byDay = <DateTime, double>{};
    for (final e in log.entries) {
      final d = _day(e.at);
      if (!d.isBefore(start)) byDay[d] = e.kg; // last weigh-in of the day wins
    }
    final daily = [
      for (final MapEntry(:key, :value) in byDay.entries) _DayPoint(key, value),
    ]..sort((a, b) => a.day.compareTo(b.day));

    final values = [
      for (final p in daily) p.kg,
      ?log.plannedOn(start.isBefore(first) ? first : start),
      ?log.plannedOn(today),
      ?log.goalKg,
    ];
    if (values.isEmpty) values.add(log.latest!.kg);
    var lo = values.reduce(math.min);
    var hi = values.reduce(math.max);
    // Keep the goal from flattening the data when it is far away.
    if (log.goalKg case final g? when daily.isNotEmpty) {
      final dataLo = daily.map((p) => p.kg).reduce(math.min);
      if (dataLo - g > 6) lo = math.min(dataLo, log.plannedOn(today) ?? dataLo);
    }
    lo = (lo - 0.6).floorToDouble();
    hi = (hi + 0.6).ceilToDouble();
    if (hi - lo < 3) hi = lo + 3;
    return _ChartData(
      daily: daily,
      start: start,
      end: today,
      lo: lo,
      hi: hi,
      log: log,
    );
  }

  static const plotRight = 36.0; // room for y labels

  double x(DateTime d, Size s) {
    final span = math.max(1, end.difference(start).inDays);
    return d.difference(start).inHours / 24 / span * (s.width - plotRight);
  }

  double y(double kg, Size s) => 8 + (hi - kg) / (hi - lo) * (s.height - 16);

  int? nearest(double dx, Size s) {
    if (daily.isEmpty) return null;
    var best = 0;
    for (var i = 1; i < daily.length; i++) {
      if ((x(daily[i].day, s) - dx).abs() <
          (x(daily[best].day, s) - dx).abs()) {
        best = i;
      }
    }
    return best;
  }

  String get summary {
    if (daily.isEmpty) return 'No weigh-ins in this range';
    final a = daily.first.kg;
    final b = daily.last.kg;
    return 'Weight from ${a.toStringAsFixed(1)} to ${b.toStringAsFixed(1)} kg '
        'over ${end.difference(start).inDays + 1} days';
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({required this.data, required this.touched});

  final _ChartData data;
  final int? touched;

  @override
  void paint(Canvas canvas, Size size) {
    final plotW = size.width - _ChartData.plotRight;

    // Recessive grid with right-hand labels.
    final grid = Paint()
      ..color = AveloColors.track
      ..strokeWidth = 1;
    final step = _niceStep(data.hi - data.lo);
    for (var v = (data.lo / step).ceil() * step; v <= data.hi; v += step) {
      final y = data.y(v, size);
      canvas.drawLine(Offset(0, y), Offset(plotW, y), grid);
      _label(canvas, v.toStringAsFixed(step < 1 ? 1 : 0), Offset(plotW + 8, y));
    }

    // Goal line.
    final goal = data.log.goalKg;
    if (goal != null && goal >= data.lo && goal <= data.hi) {
      final y = data.y(goal, size);
      final p = Paint()
        ..color = AveloColors.sageDeep
        ..strokeWidth = 1.5;
      for (var x = 0.0; x < plotW; x += 4) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + 1.5, plotW), y), p);
      }
      _label(canvas, 'Goal', Offset(4, y - 10), color: AveloColors.sageDeep);
    }

    // Plan: dashed straight line from the first weigh-in (or range start).
    final first = DateTime(
      data.log.first!.at.year,
      data.log.first!.at.month,
      data.log.first!.at.day,
    );
    final planStart = first.isAfter(data.start) ? first : data.start;
    final steps = math.max(1, data.end.difference(planStart).inDays);
    final plan = Path();
    for (var i = 0; i <= steps; i++) {
      final d = planStart.add(Duration(days: i));
      final kg = data.log.plannedOn(d)!;
      final o = Offset(data.x(d, size), data.y(kg, size));
      i == 0 ? plan.moveTo(o.dx, o.dy) : plan.lineTo(o.dx, o.dy);
    }
    _dashed(
      canvas,
      plan,
      Paint()
        ..color = AveloColors.chartPlan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // You: solid line and dots ringed with the card colour.
    final pts = [
      for (final p in data.daily)
        Offset(data.x(p.day, size), data.y(p.kg, size)),
    ];
    if (pts.length > 1) {
      final line = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final o in pts.skip(1)) {
        line.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(
        line,
        Paint()
          ..color = AveloColors.terracotta
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round,
      );
    }
    final ring = Paint()..color = AveloColors.card;
    final dot = Paint()..color = AveloColors.terracotta;
    final showDots = pts.length <= 40;
    for (final (i, o) in pts.indexed) {
      if (!showDots && i != pts.length - 1 && i != touched) continue;
      canvas.drawCircle(o, 6, ring);
      canvas.drawCircle(o, 4.5, dot);
    }

    // Crosshair on the touched day.
    if (touched case final i?) {
      final o = pts[i];
      canvas.drawLine(
        Offset(o.dx, 0),
        Offset(o.dx, size.height),
        Paint()
          ..color = AveloColors.ink.withValues(alpha: 0.35)
          ..strokeWidth = 1.5,
      );
      canvas.drawCircle(o, 8, ring);
      canvas.drawCircle(o, 6, dot);
    }
  }

  static double _niceStep(double span) {
    for (final s in [0.5, 1.0, 2.0, 5.0, 10.0]) {
      if (span / s <= 4) return s;
    }
    return 20;
  }

  void _label(Canvas canvas, String text, Offset at, {Color? color}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: AveloFonts.body,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color ?? AveloColors.muted,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at.translate(0, -tp.height / 2));
  }

  void _dashed(Canvas canvas, Path path, Paint paint) {
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 9) {
        canvas.drawPath(m.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.data != data || old.touched != touched;
}
