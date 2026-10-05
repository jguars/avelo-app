import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart';

import 'app/sfx.dart';
import 'app/shell.dart';
import 'app/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RiveNative.init();
  // Don't hold the first frame for sounds; they are ready within a moment.
  SfxPlayer.instance.init();
  runApp(const ProviderScope(child: AveloApp()));
}

class AveloApp extends StatelessWidget {
  const AveloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Avelo',
      debugShowCheckedModeBanner: false,
      theme: buildAveloTheme(),
      home: const AveloShell(),
    );
  }
}
