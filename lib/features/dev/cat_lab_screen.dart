import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/progress.dart';
import '../cat/cat_view.dart';

/// Debug screen: drive the Rive cat's inputs directly.
class CatLabScreen extends ConsumerStatefulWidget {
  const CatLabScreen({super.key});

  @override
  ConsumerState<CatLabScreen> createState() => _CatLabScreenState();
}

class _CatLabScreenState extends ConsumerState<CatLabScreen> {
  double _bodyMass = 100;
  double _energy = 0;
  bool _look = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cat lab')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CatView(
                bodyMass: _bodyMass,
                energy: _energy,
                lookAtCamera: _look,
                bodyMassDuration: Duration.zero,
              ),
            ),
            _slider('bodyMass', _bodyMass, (v) => _bodyMass = v),
            _slider('energy', _energy, (v) => _energy = v),
            SwitchListTile(
              title: const Text('lookAtCamera'),
              value: _look,
              onChanged: (v) => setState(() => _look = v),
            ),
            TextButton(
              onPressed: () => ref.read(progressProvider.notifier).reset(),
              child: const Text('Reset saved progress'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slider(String label, double value, ValueChanged<double> set) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label)),
          Expanded(
            child: Slider(
              value: value,
              max: 100,
              onChanged: (v) => setState(() => set(v)),
            ),
          ),
          SizedBox(width: 36, child: Text(value.round().toString())),
        ],
      ),
    );
  }
}
