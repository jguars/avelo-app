import 'package:avelo/data/progress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Progress', () {
    test('starts round and sleepy', () {
      const p = Progress.initial();
      expect(p.bodyMass, 100);
      expect(p.energy, 15);
    });

    test('reaches fit at target effort and never goes below 0', () {
      const p = Progress(
        effort: kTargetEffort * 2,
        doneToday: [],
        day: '',
        lastActiveDay: null,
      );
      expect(p.bodyMass, 0);
    });

    test('completing exercises slims the cat and wakes her up', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(overrides: [
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 4, 9)),
      ]);
      addTearDown(container.dispose);

      container.read(progressProvider);
      await Future<void>.delayed(Duration.zero);

      final notifier = container.read(progressProvider.notifier);
      await notifier.completeExercise('squats', 1);
      await notifier.completeExercise('walk', 2);

      final p = container.read(progressProvider);
      expect(p.effort, 3);
      expect(p.doneToday, ['squats', 'walk']);
      expect(p.bodyMass, closeTo(97.5, 0.001));
      expect(p.energy, 80);
      expect(p.lastActiveDay, '2026-10-04');
    });

    test('a new day clears doneToday but keeps effort', () async {
      SharedPreferences.setMockInitialValues({});
      var now = DateTime(2026, 10, 4, 9);
      final container = ProviderContainer(overrides: [
        clockProvider.overrideWithValue(() => now),
      ]);
      addTearDown(container.dispose);

      container.read(progressProvider);
      await Future<void>.delayed(Duration.zero);
      final notifier = container.read(progressProvider.notifier);
      await notifier.completeExercise('squats', 1);

      now = DateTime(2026, 10, 5, 9);
      await notifier.completeExercise('march', 1);

      final p = container.read(progressProvider);
      expect(p.effort, 2);
      expect(p.doneToday, ['march']);
      expect(p.day, '2026-10-05');
    });
  });
}
