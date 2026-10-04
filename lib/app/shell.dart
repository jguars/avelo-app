import 'package:flutter/material.dart';

import '../features/dev/cat_lab_screen.dart';
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
      body: IndexedStack(
        index: _index,
        children: const [
          _ComingSoon(title: 'Plan', note: 'Avoid list and pursue list'),
          _ComingSoon(title: 'Timeline', note: 'Her shape at D0 to D60'),
          TodayScreen(),
          _ComingSoon(title: 'Progress', note: 'Projected vs actual weight'),
          _ComingSoon(title: 'Profile', note: 'You, her, and settings'),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final t in _tabs)
            NavigationDestination(
              icon: Icon(t.icon),
              selectedIcon: Icon(t.selectedIcon),
              label: t.label,
            ),
        ],
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
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CatLabScreen()),
              ),
            ),
        ],
      ),
      body: Center(child: Text('$note\n(coming next)', textAlign: TextAlign.center)),
    );
  }
}
