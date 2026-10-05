import 'package:flutter/material.dart';

/// Which animation the cat plays while exercising. The index is the Rive
/// `move` input, so keep the order in sync with the AveloCatSM Move layer.
enum CatMove { squat, march, pushUp, stretch, cheer }

/// One exercise the user and the cat can do together.
class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.cue,
    required this.seconds,
    required this.effort,
    required this.icon,
    required this.move,
    this.equipment,
  });

  final String id;
  final String name;

  /// Short coaching line shown during the timer.
  final String cue;
  final int seconds;

  /// Effort points earned. The cat's body shape follows total effort.
  final double effort;
  final IconData icon;

  /// What she does alongside you.
  final CatMove move;

  /// Shop equipment id this needs; null for bodyweight moves.
  final String? equipment;

  /// Paws earned for finishing it: ten per effort point, so equipment moves,
  /// which are worth more effort, also pay more.
  int get paws => (effort * 10).round();
}

/// What the user can do with the equipment they own: equipment moves first
/// (they pay the most), then the bodyweight basics.
List<Exercise> availableExercises(Set<String> owned) => [
  ...equipmentExercises.reversed.where((e) => owned.contains(e.equipment)),
  ...dailyExercises,
];

/// Bodyweight basics, always available.
const dailyExercises = <Exercise>[
  Exercise(
    id: 'squats',
    name: 'Chair squats',
    cue: 'Sit back like you are reaching for a chair, then stand tall.',
    seconds: 60,
    effort: 1,
    icon: Icons.event_seat_outlined,
    move: CatMove.squat,
  ),
  Exercise(
    id: 'walk',
    name: 'Brisk walk',
    cue: 'Arms swinging, steady breath. Talking pace, not racing.',
    seconds: 600,
    effort: 2,
    icon: Icons.directions_walk,
    move: CatMove.march,
  ),
  Exercise(
    id: 'wall_pushups',
    name: 'Wall push-ups',
    cue: 'Hands on the wall, body straight, chest to the wall and back.',
    seconds: 45,
    effort: 1,
    icon: Icons.front_hand_outlined,
    move: CatMove.pushUp,
  ),
  Exercise(
    id: 'march',
    name: 'March in place',
    cue: 'Knees up, one at a time. Keep it light.',
    seconds: 120,
    effort: 1,
    icon: Icons.directions_run,
    move: CatMove.march,
  ),
  Exercise(
    id: 'stretch',
    name: 'Morning stretch',
    cue: 'Reach up, lean side to side, roll your shoulders.',
    seconds: 90,
    effort: 0.5,
    icon: Icons.self_improvement,
    move: CatMove.stretch,
  ),
  Exercise(
    id: 'stairs',
    name: 'Stair climb',
    cue: 'One flight, slow and steady. Hold the rail.',
    seconds: 120,
    effort: 1.5,
    icon: Icons.stairs_outlined,
    move: CatMove.march,
  ),
  Exercise(
    id: 'calf_raises',
    name: 'Calf raises',
    cue: 'Up on your toes, pause, slowly down.',
    seconds: 45,
    effort: 0.5,
    icon: Icons.height,
    move: CatMove.squat,
  ),
  Exercise(
    id: 'dance',
    name: 'One-song dance',
    cue: 'Put on a song you love and move however feels good.',
    seconds: 180,
    effort: 1.5,
    icon: Icons.music_note_outlined,
    move: CatMove.cheer,
  ),
  Exercise(
    id: 'arm_circles',
    name: 'Arm circles',
    cue: 'Small circles forward, then backward.',
    seconds: 60,
    effort: 0.5,
    icon: Icons.autorenew,
    move: CatMove.stretch,
  ),
  Exercise(
    id: 'evening_walk',
    name: 'Evening stroll',
    cue: 'An easy walk after dinner helps more than you think.',
    seconds: 900,
    effort: 2,
    icon: Icons.nightlight_outlined,
    move: CatMove.march,
  ),
];

/// Moves unlocked by Shop equipment, cheapest equipment first. Each piece
/// adds two moves worth more effort than the basics.
const equipmentExercises = <Exercise>[
  Exercise(
    id: 'mat_plank',
    name: 'Knee plank',
    cue: 'Forearms on the mat, knees down, belly in. Breathe.',
    seconds: 30,
    effort: 1.5,
    icon: Icons.horizontal_rule,
    move: CatMove.pushUp,
    equipment: 'mat',
  ),
  Exercise(
    id: 'mat_bridge',
    name: 'Glute bridges',
    cue: 'Lie back, feet flat, lift your hips and squeeze.',
    seconds: 60,
    effort: 1.5,
    icon: Icons.airline_seat_flat_angled,
    move: CatMove.stretch,
    equipment: 'mat',
  ),
  Exercise(
    id: 'rope_skips',
    name: 'Easy rope skips',
    cue: 'Small hops, soft knees. Stepping over the rope counts too.',
    seconds: 60,
    effort: 2,
    icon: Icons.all_inclusive,
    move: CatMove.march,
    equipment: 'rope',
  ),
  Exercise(
    id: 'rope_steps',
    name: 'Rope step-overs',
    cue: 'Swing slowly and step over, one foot at a time.',
    seconds: 120,
    effort: 2,
    icon: Icons.all_inclusive,
    move: CatMove.cheer,
    equipment: 'rope',
  ),
  Exercise(
    id: 'db_goblet',
    name: 'Goblet squats',
    cue: 'Hold one dumbbell at your chest, sit back, stand tall.',
    seconds: 60,
    effort: 2.5,
    icon: Icons.fitness_center,
    move: CatMove.squat,
    equipment: 'dumbbells',
  ),
  Exercise(
    id: 'db_press',
    name: 'Overhead press',
    cue: 'Dumbbells at your shoulders, press up, lower slowly.',
    seconds: 45,
    effort: 2.5,
    icon: Icons.fitness_center,
    move: CatMove.stretch,
    equipment: 'dumbbells',
  ),
  Exercise(
    id: 'kb_deadlift',
    name: 'Kettlebell deadlift',
    cue: 'Hinge at the hips, flat back, stand up with the bell.',
    seconds: 60,
    effort: 3,
    icon: Icons.sports_gymnastics,
    move: CatMove.squat,
    equipment: 'kettlebell',
  ),
  Exercise(
    id: 'kb_carry',
    name: 'Suitcase carry',
    cue: 'Bell in one hand, walk tall, swap hands halfway.',
    seconds: 90,
    effort: 3,
    icon: Icons.luggage_outlined,
    move: CatMove.march,
    equipment: 'kettlebell',
  ),
  Exercise(
    id: 'tm_incline',
    name: 'Incline walk',
    cue: 'Gentle incline, steady pace, let your arms swing.',
    seconds: 900,
    effort: 3.5,
    icon: Icons.trending_up,
    move: CatMove.march,
    equipment: 'treadmill',
  ),
  Exercise(
    id: 'tm_intervals',
    name: 'Walk-jog intervals',
    cue: 'One minute brisk, one minute easy. Repeat.',
    seconds: 600,
    effort: 3.5,
    icon: Icons.speed,
    move: CatMove.march,
    equipment: 'treadmill',
  ),
  Exercise(
    id: 'rack_squat',
    name: 'Rack squats',
    cue: 'Light bar on your back, sit down between the uprights, drive up.',
    seconds: 90,
    effort: 4,
    icon: Icons.fitness_center,
    move: CatMove.squat,
    equipment: 'rack',
  ),
  Exercise(
    id: 'rack_rows',
    name: 'Bar rows',
    cue: 'Hang under a low bar, heels down, pull your chest up.',
    seconds: 45,
    effort: 4,
    icon: Icons.rowing,
    move: CatMove.pushUp,
    equipment: 'rack',
  ),
];
