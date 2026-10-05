import 'package:avelo/data/progress.dart';
import 'package:avelo/data/equipment.dart';
import 'package:avelo/data/exercises.dart';
import 'package:avelo/data/milestones.dart';
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
        startDay: null,
      );
      expect(p.bodyMass, 0);
    });

    test('completing exercises slims the cat and wakes her up', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(() => DateTime(2026, 10, 4, 9)),
        ],
      );
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
      final container = ProviderContainer(
        overrides: [clockProvider.overrideWithValue(() => now)],
      );
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

    test('first launch sets D0, and day number counts from it', () async {
      SharedPreferences.setMockInitialValues({});
      var now = DateTime(2026, 10, 4, 9);
      final container = ProviderContainer(
        overrides: [clockProvider.overrideWithValue(() => now)],
      );
      addTearDown(container.dispose);
      container.read(progressProvider);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(progressProvider).startDay, '2026-10-04');

      now = DateTime(2026, 10, 11, 9);
      await container
          .read(progressProvider.notifier)
          .completeExercise('walk', 2);
      final p = container.read(progressProvider);
      expect(p.startDay, '2026-10-04');
      expect(p.dayNumber, 7);
      expect(p.plannedEffortToday, 14);
    });
  });

  group('Timeline', () {
    test('plan reaches fit on D60 and is linear before', () {
      expect(plannedBodyMassOnDay(0), 100);
      expect(plannedBodyMassOnDay(30), closeTo(50, 0.001));
      expect(plannedBodyMassOnDay(60), 0);
      expect(plannedBodyMassOnDay(90), 0);
    });

    test('milestones are reached by effort, not by the calendar', () {
      Progress withEffort(double e) => Progress(
        effort: e,
        doneToday: const [],
        day: '2026-10-05',
        lastActiveDay: null,
        startDay: '2026-10-04',
      );
      final d7 = milestones[1];
      expect(isReached(d7, withEffort(13.9)), isFalse);
      expect(isReached(d7, withEffort(14)), isTrue);
      expect(isReached(milestones.first, withEffort(0)), isTrue);
    });
  });

  group('Economy', () {
    test('equipment unlocks two richer moves each', () {
      for (final item in equipmentCatalog) {
        expect(item.unlocks, hasLength(2), reason: item.id);
        for (final e in item.unlocks) {
          expect(e.paws, greaterThan(10), reason: e.id);
        }
      }
      final basics = availableExercises({});
      expect(basics.every((e) => e.equipment == null), isTrue);
      final withMat = availableExercises({'mat'});
      expect(withMat.first.equipment, 'mat');
      expect(withMat.length, basics.length + 2);
    });

    test('prices climb with each piece', () {
      final prices = equipmentCatalog.map((e) => e.price).toList();
      expect(prices, orderedEquals([...prices]..sort()));
    });
  });
}
