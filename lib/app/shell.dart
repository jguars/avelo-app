import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile.dart';
import '../features/plan/plan_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/progress/progress_screen.dart';
import '../features/shop/shop_screen.dart';
import '../features/today/today_screen.dart';
import 'nav.dart';
import 'theme.dart';

/// Bottom-tab shell. Today sits in the middle and is the default tab.
class AveloShell extends ConsumerWidget {
  const AveloShell({super.key});

  static const _tabs = <_Tab>[
    _Tab('Shop', Icons.storefront_outlined, Icons.storefront),
    _Tab('Plan', Icons.checklist_outlined, Icons.checklist),
    _Tab('Today', Icons.pets_outlined, Icons.pets),
    _Tab('Progress', Icons.show_chart_outlined, Icons.show_chart),
    _Tab('Profile', Icons.person_outline, Icons.person),
  ];

  static const _screens = <Widget>[
    ShopScreen(),
    PlanScreen(),
    TodayScreen(),
    ProgressScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Loads saved preferences (sound) at startup.
    ref.watch(profileProvider);
    final index = ref.watch(tabProvider).index;
    return Scaffold(
      // Screens run under the floating pill; MediaQuery padding tells them
      // how much to leave clear.
      extendBody: true,
      body: IndexedStack(
        index: index,
        children: [
          // Hidden tabs keep their state but stop animating.
          for (final (i, screen) in _screens.indexed)
            TickerMode(enabled: i == index, child: screen),
        ],
      ),
      bottomNavigationBar: _PillNav(
        tabs: _tabs,
        index: index,
        onSelect: (i) => ref.read(tabProvider.notifier).go(AveloTab.values[i]),
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
