import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/sfx.dart';
import '../../app/theme.dart';
import '../../data/exercises.dart';
import '../../data/progress.dart';
import 'living_room.dart';
import 'today_screen.dart' show formatDuration;

/// Trust + timer: the user and the cat exercise until the timer runs out.
/// Pops `true` when the exercise was completed.
class ExerciseSessionScreen extends ConsumerStatefulWidget {
  const ExerciseSessionScreen({super.key, required this.exercise});

  final Exercise exercise;

  @override
  ConsumerState<ExerciseSessionScreen> createState() =>
      _ExerciseSessionScreenState();
}

enum _Phase { countdown, running, finished }

class _ExerciseSessionScreenState extends ConsumerState<ExerciseSessionScreen> {
  static const _countFrom = 3;

  Timer? _ticker;
  _Phase _phase = _Phase.countdown;
  int _count = _countFrom;
  late int _left = widget.exercise.seconds;
  bool _paused = false;

  int get _elapsed => widget.exercise.seconds - _left;

  @override
  void initState() {
    super.initState();
    HapticFeedback.selectionClick();
    SfxPlayer.instance.play(Sfx.tick);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    switch (_phase) {
      case _Phase.countdown:
        if (_count > 1) {
          HapticFeedback.selectionClick();
          SfxPlayer.instance.play(Sfx.tick);
          setState(() => _count--);
        } else {
          HapticFeedback.mediumImpact();
          SfxPlayer.instance.play(Sfx.go);
          setState(() => _phase = _Phase.running);
        }
      case _Phase.running:
        if (_paused) return;
        if (_left > 1) {
          setState(() => _left--);
        } else {
          HapticFeedback.heavyImpact();
          SfxPlayer.instance.play(Sfx.done);
          setState(() {
            _left = 0;
            _phase = _Phase.finished;
          });
        }
      case _Phase.finished:
        break;
    }
  }

  /// Test builds only: skip the countdown and timer straight to "done".
  void _finishNow() {
    if (_phase == _Phase.finished) return;
    HapticFeedback.heavyImpact();
    SfxPlayer.instance.play(Sfx.done);
    setState(() {
      _paused = false;
      _left = 0;
      _phase = _Phase.finished;
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// What she says, by phase and progress.
  String get _speech {
    switch (_phase) {
      case _Phase.countdown:
        return 'Stretch those paws…';
      case _Phase.finished:
        return 'WE DID IT!';
      case _Phase.running:
        if (_paused) return "Little break. I'm not complaining.";
        if (_left <= 10) return 'Almost! Almost!';
        final total = widget.exercise.seconds;
        if (_elapsed * 2 >= total) {
          const late = [
            'Halfway there!',
            'Look at us go!',
            'Sweating… in a good way.',
          ];
          return late[((_elapsed - total ~/ 2) ~/ 12) % late.length];
        }
        const early = [
          "Let's go!",
          'Breathe… keep breathing.',
          'I can feel it already.',
        ];
        return early[(_elapsed ~/ 12) % early.length];
    }
  }

  Future<void> _confirmStop() async {
    if (_phase == _Phase.finished) {
      Navigator.of(context).pop(false);
      return;
    }
    final wasPaused = _paused;
    setState(() => _paused = true);
    final stop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AveloColors.surface,
        title: Text('Stop here?', style: display(22)),
        content: const Text(
          "She'll wait on the sofa. This one won't count yet.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Stop'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (stop == true) {
      Navigator.of(context).pop(false);
    } else {
      setState(() => _paused = wasPaused);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(progressProvider);
    final now = ref.watch(clockProvider)();
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmStop();
      },
      child: Scaffold(
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: _TopBar(
                title: widget.exercise.name,
                onClose: _confirmStop,
                onSkip: kDebugMode ? _finishNow : null,
              ),
            ),
            Expanded(
              child: LivingRoom(
                spot: CatSpot.rug,
                move: widget.exercise.move,
                bodyMass: progress.bodyMass,
                energy: 100,
                // She looks at you before you start and when you finish.
                lookAtCamera: _phase != _Phase.running,
                exercising: _phase == _Phase.running && !_paused,
                hour: now.hour,
                speech: _speech,
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: AveloColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(color: AveloColors.ink, width: 2),
                ),
              ),
              padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      _TimerRing(
                        phase: _phase,
                        count: _count,
                        left: _left,
                        total: widget.exercise.seconds,
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_statusLabel, style: eyebrow),
                            const SizedBox(height: 4),
                            Text(
                              _phase == _Phase.finished
                                  ? 'She is so proud of you. And a little out of breath.'
                                  : widget.exercise.cue,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.35,
                                color: Color(0xFF6B4A36),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _actions(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _statusLabel => switch (_phase) {
    _Phase.countdown => 'GET READY',
    _Phase.running when _paused => 'PAUSED',
    _Phase.running => 'TOGETHER NOW',
    _Phase.finished => 'DONE · +${_effortLabel()} EFFORT',
  };

  String _effortLabel() {
    final e = widget.exercise.effort;
    return e == e.roundToDouble() ? e.toStringAsFixed(0) : e.toStringAsFixed(1);
  }

  Widget _actions() {
    if (_phase == _Phase.finished) {
      return FilledButton(
        onPressed: () => Navigator.of(context).pop(true),
        child: const Text('We did it!'),
      );
    }
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        shape: const StadiumBorder(),
        side: const BorderSide(color: AveloColors.ink, width: 2),
        foregroundColor: AveloColors.text,
        textStyle: const TextStyle(
          fontFamily: AveloFonts.body,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
      onPressed: _phase == _Phase.running
          ? () => setState(() => _paused = !_paused)
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_paused ? Icons.play_arrow_rounded : Icons.pause_rounded),
          const SizedBox(width: 6),
          Text(_paused ? 'Resume' : 'Pause'),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.onClose, this.onSkip});

  final String title;
  final VoidCallback onClose;

  /// Debug builds only: finish the exercise instantly for testing.
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Stop',
            onPressed: onClose,
            style: IconButton.styleFrom(
              backgroundColor: AveloColors.surface,
              side: const BorderSide(color: AveloColors.ink, width: 2),
              fixedSize: const Size(44, 44),
            ),
            icon: const Icon(Icons.close_rounded, color: AveloColors.ink),
          ),
          Expanded(
            child: Column(
              children: [
                const Text('TOGETHER', style: eyebrow),
                Text(title, style: display(22)),
              ],
            ),
          ),
          if (onSkip != null)
            IconButton(
              tooltip: 'Finish now (test)',
              onPressed: onSkip,
              style: IconButton.styleFrom(
                backgroundColor: AveloColors.goldLight,
                side: const BorderSide(color: AveloColors.ink, width: 2),
                fixedSize: const Size(44, 44),
              ),
              icon: const Icon(
                Icons.fast_forward_rounded,
                color: AveloColors.ink,
              ),
            )
          else
            // Balances the close button so the title stays centred.
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}

/// Big ring: counts 3-2-1, then the time left, then a check.
class _TimerRing extends StatelessWidget {
  const _TimerRing({
    required this.phase,
    required this.count,
    required this.left,
    required this.total,
  });

  final _Phase phase;
  final int count;
  final int left;
  final int total;

  @override
  Widget build(BuildContext context) {
    final fraction = switch (phase) {
      _Phase.countdown => 0.0,
      _Phase.running => 1 - left / total,
      _Phase.finished => 1.0,
    };
    final Widget center = switch (phase) {
      _Phase.countdown => Text('$count', style: display(44)),
      _Phase.running => FittedBox(
        child: Text(
          _clock(left),
          style: display(30)
              .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
      ),
      _Phase.finished => const Icon(
        Icons.check_rounded,
        size: 48,
        color: AveloColors.terracotta,
      ),
    };

    return Semantics(
      label: switch (phase) {
        _Phase.countdown => 'Starting in $count',
        _Phase.running => '${formatDuration(left)} left',
        _Phase.finished => 'Finished',
      },
      excludeSemantics: true,
      child: SizedBox(
        width: 116,
        height: 116,
        child: Stack(
          fit: StackFit.expand,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(end: fraction),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: 10,
                strokeCap: StrokeCap.round,
                backgroundColor: AveloColors.track,
                color: AveloColors.terracotta,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: KeyedSubtree(
                    key: ValueKey(phase == _Phase.countdown ? count : phase),
                    child: center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _clock(int seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
