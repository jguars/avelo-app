import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// A looping frame sequence of the cat, cut from a Layer video clip.
///
/// Frames are `<folder>/f000.png` … and are decoded up front so the loop
/// never flickers while an image loads.
class CatClip extends StatefulWidget {
  const CatClip({
    super.key,
    required this.folder,
    required this.frames,
    this.fps = 15,
    this.groundShadow = true,
  });

  /// The heaviest calico squatting with her arms stretched out.
  const CatClip.squatHeavy({Key? key, bool groundShadow = true})
    : this(
        key: key,
        folder: 'assets/cat/squat_heavy',
        frames: 77,
        groundShadow: groundShadow,
      );

  final String folder;
  final int frames;
  final double fps;
  final bool groundShadow;

  @override
  State<CatClip> createState() => _CatClipState();
}

class _CatClipState extends State<CatClip> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  late final List<ImageProvider> _images = [
    for (var i = 0; i < widget.frames; i++)
      AssetImage('${widget.folder}/f${i.toString().padLeft(3, '0')}.png'),
  ];
  int _frame = 0;
  bool _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    Future.wait([for (final image in _images) precacheImage(image, context)])
        .then((_) {
          if (!mounted) return;
          setState(() => _ready = true);
          _ticker.start();
        });
  }

  void _tick(Duration elapsed) {
    final frame =
        (elapsed.inMicroseconds * widget.fps / 1e6).floor() % widget.frames;
    if (frame != _frame) setState(() => _frame = frame);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        if (widget.groundShadow)
          FractionallySizedBox(
            widthFactor: 0.62,
            heightFactor: 0.07,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0x2E5A3A26),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        Positioned.fill(
          child: Image(
            image: _images[_ready ? _frame : 0],
            fit: BoxFit.contain,
            alignment: Alignment.bottomCenter,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ],
    );
  }
}
