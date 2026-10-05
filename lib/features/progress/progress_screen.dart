import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'journey_panel.dart';
import 'weight_panel.dart';

/// Progress: her journey and your weight, side by side. Swipe between them
/// or tap the switch at the top.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _pages = PageController();

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int page) => _pages.animateToPage(
    page,
    duration: const Duration(milliseconds: 320),
    curve: Curves.easeOutCubic,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('HOW FAR WE’VE COME', style: eyebrow),
                  const SizedBox(height: 2),
                  Text('Progress', style: display(28)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _PanelSwitch(
                controller: _pages,
                labels: const ['Her journey', 'Your weight'],
                onSelect: _go,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: PageView(
                controller: _pages,
                children: const [JourneyPanel(), WeightPanel()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two-segment switch whose thumb follows the page as it is swiped.
class _PanelSwitch extends StatelessWidget {
  const _PanelSwitch({
    required this.controller,
    required this.labels,
    required this.onSelect,
  });

  final PageController controller;
  final List<String> labels;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AveloColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AveloColors.ink, width: 2),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth / labels.length;
          return AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final page =
                  controller.hasClients &&
                      controller.position.hasContentDimensions
                  ? controller.page ?? 0
                  : 0.0;
              return Stack(
                children: [
                  Positioned(
                    left: page * w,
                    top: 0,
                    bottom: 0,
                    width: w,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AveloColors.terracotta,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (final (i, label) in labels.indexed)
                        Expanded(
                          child: Semantics(
                            button: true,
                            selected: page.round() == i,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => onSelect(i),
                              child: Center(
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Color.lerp(
                                      AveloColors.muted,
                                      Colors.white,
                                      (1 - (page - i).abs()).clamp(0.0, 1.0),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
