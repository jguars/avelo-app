import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/theme.dart';
import '../cat/cat_view.dart';

/// The cozy living room with the cat on the sofa.
///
/// Laid out on the mockup's 390×440 grid and scaled to cover the available
/// space, anchored to the floor, so shorter screens crop the top of the wall
/// rather than the cat.
class LivingRoom extends StatelessWidget {
  const LivingRoom({
    super.key,
    required this.bodyMass,
    required this.energy,
    required this.lookAtCamera,
    required this.hour,
    this.speech,
  });

  final double bodyMass;
  final double energy;
  final bool lookAtCamera;

  /// Local hour (0-23); sets the sky in the window and the lamp glow.
  final int hour;

  /// What she says, shown in a bubble beside her head. Null hides it.
  final String? speech;

  static const _size = Size(390, 440);

  @override
  Widget build(BuildContext context) {
    // Fit the width so the sofa and bubble never crop at the sides; a taller
    // box shows more wall above, a shorter one crops the top of the wall.
    return ClipRect(
      child: ColoredBox(
        color: AveloColors.wall,
        child: OverflowBox(
          alignment: Alignment.bottomCenter,
          maxHeight: double.infinity,
          child: FittedBox(
            fit: BoxFit.fitWidth,
            alignment: Alignment.bottomCenter,
            child: SizedBox.fromSize(
              size: _size,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: _RoomBack(light: _Light.forHour(hour)),
                  ),
                  // Her feet rest on the seat cushion (y = 294).
                  Positioned(
                    left: 81,
                    top: 52,
                    width: 228,
                    height: 266,
                    child: CatView(
                      bodyMass: bodyMass,
                      energy: energy,
                      lookAtCamera: lookAtCamera,
                      groundShadow: false,
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: SvgPicture.asset(
                        'assets/scene/room_front.svg',
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 230,
                    top: 66,
                    width: 142,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutBack,
                      transitionBuilder: (child, animation) => ScaleTransition(
                        scale: animation,
                        alignment: Alignment.bottomLeft,
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                      child: speech == null
                          ? const SizedBox.shrink()
                          : _SpeechBubble(key: ValueKey(speech), text: speech!),
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

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'She says: $text',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: AveloColors.card,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: AveloColors.ink, width: 2),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13.5,
            height: 1.25,
            fontWeight: FontWeight.w700,
            color: AveloColors.text,
          ),
        ),
      ),
    );
  }
}

/// How the window and lamp look at a given time of day.
class _Light {
  const _Light({
    required this.sky,
    required this.sun,
    required this.sunY,
    required this.cloud,
    required this.glow,
  });

  final String sky;
  final String sun;
  final double sunY;
  final String cloud;
  final double glow;

  static const _morning = _Light(
    sky: '#D7E9E2',
    sun: '#F6D68A',
    sunY: 150,
    cloud: '#FBF1DE',
    glow: 0,
  );
  static const _day = _Light(
    sky: '#CFE3DC',
    sun: '#F6D68A',
    sunY: 112,
    cloud: '#FBF1DE',
    glow: 0,
  );
  static const _dusk = _Light(
    sky: '#F0C29A',
    sun: '#EE8E5E',
    sunY: 172,
    cloud: '#F8DCC4',
    glow: 0.45,
  );
  static const _night = _Light(
    sky: '#3F4A6E',
    sun: '#FBF1DE',
    sunY: 106,
    cloud: '#56618A',
    glow: 0.6,
  );

  static _Light forHour(int hour) {
    if (hour < 6 || hour >= 20) return _night;
    if (hour < 11) return _morning;
    if (hour < 17) return _day;
    return _dusk;
  }

  String apply(String svg) => svg
      .replaceAll('#SKY000', sky)
      .replaceAll('#SUN000', sun)
      .replaceAll('SUNY', sunY.toStringAsFixed(0))
      .replaceAll('#CLOUD0', cloud)
      .replaceAll('GLOW', glow.toString());
}

/// The room behind the cat, recoloured for the time of day.
class _RoomBack extends StatelessWidget {
  const _RoomBack({required this.light});

  final _Light light;

  static Future<String>? _source;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _source ??= rootBundle.loadString('assets/scene/room_back.svg'),
      builder: (context, snapshot) {
        final svg = snapshot.data;
        if (svg == null) return const ColoredBox(color: AveloColors.wall);
        return SvgPicture.string(light.apply(svg), fit: BoxFit.fill);
      },
    );
  }
}
