import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom tabs, left to right.
enum AveloTab { shop, plan, today, progress, profile }

/// The selected bottom tab, so screens can send the user to another tab.
final tabProvider = NotifierProvider<TabNotifier, AveloTab>(TabNotifier.new);

class TabNotifier extends Notifier<AveloTab> {
  @override
  AveloTab build() => AveloTab.today;

  void go(AveloTab tab) => state = tab;
}
