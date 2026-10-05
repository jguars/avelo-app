import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// The living-room window's sky, alive: clouds drift, the sun climbs into
/// place when the room appears and follows the time of day, and at night the
/// moon is up and stars twinkle.
///
/// Painted in the room's 390×440 grid on top of the room art, clipped to the
/// window, then the frame and mullions are redrawn over it.
class WindowSky extends StatefulWidget {
  const WindowSky({super.key, required this.hour});

  /// Local hour (0-23); minutes come from the clock.
  final int hour;

  @override
  State<WindowSky> createState() => _WindowSkyState();
}

class _WindowSkyState extends State<WindowSky> with TickerProviderStateMixin {
  /// Free-running time for drift and twinkle.
  late final _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 120),
  )..repeat();

  /// The sun (or moon) rising into place when the room appears.
  late final _rise = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..forward();

  bool _visible = true;

  /// Replays the rise each time the user comes back to Today.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible && !_visible) _rise.forward(from: 0);
    _visible = visible;
  }

  @override
  void dispose() {
    _loop.dispose();
    _rise.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final hour = widget.hour + DateTime.now().minute / 60;
    return RepaintBoundary(
      child: CustomPaint(
        painter: _SkyPainter(
          hour: hour,
          loop: still ? null : _loop,
          rise: still ? null : _rise,
        ),
      ),
    );
  }
}

class _SkyPainter extends CustomPainter {
  _SkyPainter({required this.hour, this.loop, this.rise})
    : super(repaint: Listenable.merge([?loop, ?rise]));

  final double hour;
  final Animation<double>? loop;
  final Animation<double>? rise;

  static const _grid = Size(390, 440);

  /// The arched window: x 44..160, top of the arch at y 64, sill at y 196.
  static final _window = Path()
    ..moveTo(44, 196)
    ..lineTo(44, 122)
    ..arcToPoint(const Offset(160, 122), radius: const Radius.circular(58))
    ..lineTo(160, 196)
    ..close();

  /// Sky gradient keyframes: (hour, top, bottom).
  static const _keys = <(double, Color, Color)>[
    (0, Color(0xFF2B3254), Color(0xFF444D78)),
    (4.5, Color(0xFF353C66), Color(0xFF5A5C86)),
    (6, Color(0xFFE8B49B), Color(0xFFF6D9B5)),
    (8, Color(0xFFBFDCE0), Color(0xFFEAF1E0)),
    (13, Color(0xFFA8D2E2), Color(0xFFDCEDE6)),
    (17, Color(0xFFDDC9A0), Color(0xFFF3E1C0)),
    (19, Color(0xFFD99485), Color(0xFFF2BA8C)),
    (20.5, Color(0xFF4B4E7C), Color(0xFF8A6F8E)),
    (22, Color(0xFF2B3254), Color(0xFF444D78)),
    (24, Color(0xFF2B3254), Color(0xFF444D78)),
  ];

  (Color, Color) _skyAt(double h) {
    for (var i = 0; i < _keys.length - 1; i++) {
      final (h0, t0, b0) = _keys[i];
      final (h1, t1, b1) = _keys[i + 1];
      if (h >= h0 && h <= h1) {
        final t = Curves.easeInOut.transform((h - h0) / (h1 - h0));
        return (Color.lerp(t0, t1, t)!, Color.lerp(b0, b1, t)!);
      }
    }
    return (_keys.first.$2, _keys.first.$3);
  }

  /// 1 deep at night, 0 in daylight.
  double _night(double h) {
    if (h >= 21 || h < 4.5) return 1;
    if (h < 6.5) return 1 - (h - 4.5) / 2;
    if (h > 19.5) return (h - 19.5) / 1.5;
    return 0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _grid.width, size.height / _grid.height);

    final secs = (loop?.value ?? 0.3) * 120;
    final risen = Curves.easeOutCubic.transform(rise?.value ?? 1);
    final night = _night(hour);

    canvas.save();
    canvas.clipPath(_window);
    canvas.clipRect(const Rect.fromLTRB(0, 0, 390, 193));

    // Sky.
    final (top, bottom) = _skyAt(hour);
    canvas.drawRect(
      const Rect.fromLTRB(44, 64, 160, 196),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ).createShader(const Rect.fromLTRB(44, 64, 160, 196)),
    );

    // Stars, twinkling out of step.
    if (night > 0) {
      final rnd = math.Random(7);
      for (var i = 0; i < 16; i++) {
        final p = Offset(
          48 + rnd.nextDouble() * 108,
          70 + rnd.nextDouble() * 100,
        );
        final phase = rnd.nextDouble() * math.pi * 2;
        final speed = 0.8 + rnd.nextDouble() * 1.6;
        final tw = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(phase + secs * speed));
        final r = 0.9 + rnd.nextDouble() * 1.1;
        canvas.drawCircle(
          p,
          r,
          Paint()
            ..color = const Color(0xFFFFF6D8).withValues(alpha: night * tw),
        );
        if (r > 1.6) {
          // A little sparkle cross on the bigger stars.
          final s = Paint()
            ..color = const Color(0xFFFFF6D8)
                .withValues(alpha: night * tw * 0.6)
            ..strokeWidth = 0.8;
          canvas.drawLine(p.translate(-r * 2.4, 0), p.translate(r * 2.4, 0), s);
          canvas.drawLine(p.translate(0, -r * 2.4), p.translate(0, r * 2.4), s);
        }
      }
      // A shooting star now and then.
      final cycle = secs % 14;
      if (cycle < 0.9 && night > 0.6) {
        final t = cycle / 0.9;
        final head = Offset(70 + 70 * t, 74 + 34 * t);
        canvas.drawLine(
          head,
          head.translate(-18, -9),
          Paint()
            ..shader = LinearGradient(
              colors: [
                const Color(0xFFFFF6D8).withValues(alpha: (1 - t) * night),
                const Color(0x00FFF6D8),
              ],
            ).createShader(Rect.fromPoints(head, head.translate(-18, -9)))
            ..strokeWidth = 1.6
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // Sun by day, moon by night; both climb into place on arrival.
    final day = (hour - 6) / 14; // 0 at 06:00, 1 at 20:00
    if (day > -0.05 && day < 1.05) {
      final t = day.clamp(0.0, 1.0);
      final sky = Offset(56 + 92 * t, 184 - 104 * math.sin(math.pi * t));
      final pos = sky.translate(0, (1 - risen) * 70);
      final dusk = (hour - 17).clamp(0.0, 3.0) / 3;
      final dawn = (1 - (hour - 6).clamp(0.0, 2.0) / 2);
      final warm = math.max(dusk, dawn);
      final sun = Color.lerp(
        const Color(0xFFF8D67A),
        const Color(0xFFEE8E5E),
        warm,
      )!;
      final pulse = 0.5 + 0.5 * math.sin(secs * 0.9);
      canvas.drawCircle(
        pos,
        26 + 3 * pulse,
        Paint()
          ..shader = RadialGradient(
            colors: [sun.withValues(alpha: 0.45), sun.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: pos, radius: 29)),
      );
      canvas.drawCircle(pos, 14, Paint()..color = sun);
      canvas.drawCircle(
        pos.translate(-4, -4),
        5,
        Paint()..color = Colors.white.withValues(alpha: 0.35),
      );
    }
    if (night > 0.3) {
      // Night runs 20:00 → 06:00.
      final n = ((hour < 12 ? hour + 24 : hour) - 20) / 10;
      final t = n.clamp(0.0, 1.0);
      final sky = Offset(60 + 84 * t, 150 - 64 * math.sin(math.pi * t));
      final pos = sky.translate(0, (1 - risen) * 60);
      final moon = const Color(0xFFFBF1DE).withValues(alpha: night);
      canvas.drawCircle(
        pos,
        22,
        Paint()
          ..shader = RadialGradient(
            colors: [
              moon.withValues(alpha: 0.25 * night),
              moon.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: pos, radius: 22)),
      );
      // Crescent: a full disc with the sky colour bitten out.
      canvas.saveLayer(Rect.fromCircle(center: pos, radius: 14), Paint());
      canvas.drawCircle(pos, 11, Paint()..color = moon);
      canvas.drawCircle(
        pos.translate(5, -3),
        9.5,
        Paint()..blendMode = BlendMode.dstOut,
      );
      canvas.restore();
    }

    // Clouds drift right and wrap around.
    final cloud = Color.lerp(
      Color.lerp(
        const Color(0xFFFFF8EA),
        const Color(0xFFF8D6BE),
        ((hour - 17).clamp(0.0, 3.0) / 3),
      ),
      const Color(0xFF5E6890),
      night,
    )!;
    const clouds = <(double, double, double, double)>[
      // (y, scale, seconds to cross, offset)
      (102, 1.0, 70, 0.1),
      (138, 0.75, 52, 0.55),
      (168, 1.15, 90, 0.8),
    ];
    for (final (y, scale, cross, offset) in clouds) {
      final span = 116 + 60 * scale; // window width plus the cloud itself
      final x = 44 - 30 * scale + ((secs / cross + offset) % 1) * span;
      _cloud(
        canvas,
        Offset(x, y),
        scale,
        cloud.withValues(alpha: 0.95 - 0.35 * night),
      );
    }

    canvas.restore(); // window clip

    // Frame and mullions back on top.
    final ink = Paint()
      ..color = AveloColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawPath(_window, ink);
    canvas.drawLine(const Offset(102, 66), const Offset(102, 194), ink);
    canvas.drawLine(const Offset(44, 140), const Offset(160, 140), ink);

    canvas.restore();
  }

  void _cloud(Canvas canvas, Offset at, double s, Color color) {
    final p = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(at.dx - 22 * s, at.dy - 6 * s, 50 * s, 13 * s),
        Radius.circular(7 * s),
      ),
      p,
    );
    canvas.drawCircle(at.translate(-6 * s, -6 * s), 9 * s, p);
    canvas.drawCircle(at.translate(8 * s, -9 * s), 11 * s, p);
    canvas.drawCircle(at.translate(20 * s, -3 * s), 7 * s, p);
  }

  @override
  bool shouldRepaint(_SkyPainter old) =>
      old.hour != hour || old.loop != loop || old.rise != rise;
}
