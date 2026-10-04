import 'package:flutter/material.dart';

import 'theme.dart';

import '../features/dev/cat_lab_screen.dart';
import '../features/timeline/timeline_screen.dart';
import '../features/today/today_screen.dart';

/// Bottom-tab shell. Today sits in the middle and is the default tab.
class AveloShell extends StatefulWidget {
  const AveloShell({super.key});

  @override
  State<AveloShell> createState() => _AveloShellState();
}

class _AveloShellState extends State<AveloShell> {
  int _index = 2;

  static const _tabs = <_Tab>[
    _Tab('Plan', Icons.checklist_outlined, Icons.checklist),
    _Tab('Timeline', Icons.timeline_outlined, Icons.timeline),
    _Tab('Today', Icons.pets_outlined, Icons.pets),
    _Tab('Progress', Icons.show_chart_outlined, Icons.show_chart),
    _Tab('Profile', Icons.person_outline, Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Screens run under the floating pill; MediaQuery padding tells them
      // how much to leave clear.
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: const [
          _ComingSoon(title: 'Plan', note: 'Avoid list and pursue list'),
          TimelineScreen(),
          TodayScreen(),
          _ComingSoon(title: 'Progress', note: 'Projected vs actual weight'),
          _ComingSoon(title: 'Profile', note: 'You, her, and settings'),
        ],
      ),
      bottomNavigationBar: _PillNav(
        tabs: _tabs,
        index: _index,
        onSelect: (i) => setState(() => _index = i),
      ),
    );
  }
}

/// Floating rounded tab bar.
class _PillNav extends StatelessWidget {
  const _PillNav({
    required this.tabs,
    required this.index,
    required this.onSelect,
  });

  final List<_Tab> tabs;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: AveloColors.surface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AveloColors.ink, width: 2),
          ),
          child: Row(
            children: [
              for (final (i, t) in tabs.indexed)
                Expanded(
                  child: _PillNavItem(
                    tab: t,
                    selected: i == index,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillNavItem extends StatelessWidget {
  const _PillNavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final _Tab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AveloColors.terracotta : AveloColors.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1.1 : 1,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                selected ? tab.selectedIcon : tab.icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              tab.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab {
  const _Tab(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.title, required this.note});

  final String title;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (title == 'Profile')
            IconButton(
              tooltip: 'Cat lab',
              icon: const Icon(Icons.science_outlined),
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const CatLabScreen())),
            ),
        ],
      ),
      body: Center(
        child: Text('$note\n(coming next)', textAlign: TextAlign.center),
      ),
    );
  }
}
