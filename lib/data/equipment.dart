import 'exercises.dart';

/// A piece of home-gym equipment bought with paws in the Shop.
class Equipment {
  const Equipment({
    required this.id,
    required this.name,
    required this.price,
    required this.blurb,
  });

  final String id;
  final String name;

  /// Cost in paws.
  final int price;
  final String blurb;

  String get art => 'assets/equipment/$id.svg';

  List<Exercise> get unlocks =>
      equipmentExercises.where((e) => e.equipment == id).toList();
}

/// Cheapest first. A typical day (three exercises, the daily bonus and a few
/// plan rules) earns about 50 paws, so the mat is a day or two away and the
/// rack a few weeks; each piece speeds up earning toward the next.
const equipmentCatalog = <Equipment>[
  Equipment(
    id: 'mat',
    name: 'Yoga mat',
    price: 60,
    blurb: 'Floor moves that wake up your core.',
  ),
  Equipment(
    id: 'rope',
    name: 'Jump rope',
    price: 150,
    blurb: 'Light cardio that gets the heart going.',
  ),
  Equipment(
    id: 'dumbbells',
    name: 'Dumbbells',
    price: 280,
    blurb: 'Strength that makes every day easier.',
  ),
  Equipment(
    id: 'kettlebell',
    name: 'Kettlebell',
    price: 450,
    blurb: 'Whole-body moves, big effort.',
  ),
  Equipment(
    id: 'treadmill',
    name: 'Treadmill',
    price: 700,
    blurb: 'Walk any weather, as long as you like.',
  ),
  Equipment(
    id: 'rack',
    name: 'Squat rack',
    price: 1000,
    blurb: 'The crown of her home gym.',
  ),
];

Equipment equipmentById(String id) =>
    equipmentCatalog.firstWhere((e) => e.id == id);
