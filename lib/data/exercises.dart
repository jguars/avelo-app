import 'package:flutter/material.dart';

/// One exercise the user and the cat can do together.
class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.cue,
    required this.seconds,
    required this.effort,
    required this.icon,
  });

  final String id;
  final String name;

  /// Short coaching line shown during the timer.
  final String cue;
  final int seconds;

  /// Effort points earned. The cat's body shape follows total effort.
  final double effort;
  final IconData icon;
}

/// Today's pool: up to 10 per day, 3 shown at a time.
const dailyExercises = <Exercise>[
  Exercise(
    id: 'squats',
    name: 'Chair squats',
    cue: 'Sit back like you are reaching for a chair, then stand tall.',
    seconds: 60,
    effort: 1,
    icon: Icons.event_seat_outlined,
  ),
  Exercise(
    id: 'walk',
    name: 'Brisk walk',
    cue: 'Arms swinging, steady breath. Talking pace, not racing.',
    seconds: 600,
    effort: 2,
    icon: Icons.directions_walk,
  ),
  Exercise(
    id: 'wall_pushups',
    name: 'Wall push-ups',
    cue: 'Hands on the wall, body straight, chest to the wall and back.',
    seconds: 45,
    effort: 1,
    icon: Icons.front_hand_outlined,
  ),
  Exercise(
    id: 'march',
    name: 'March in place',
    cue: 'Knees up, one at a time. Keep it light.',
    seconds: 120,
    effort: 1,
    icon: Icons.directions_run,
  ),
  Exercise(
    id: 'stretch',
    name: 'Morning stretch',
    cue: 'Reach up, lean side to side, roll your shoulders.',
    seconds: 90,
    effort: 0.5,
    icon: Icons.self_improvement,
  ),
  Exercise(
    id: 'stairs',
    name: 'Stair climb',
    cue: 'One flight, slow and steady. Hold the rail.',
    seconds: 120,
    effort: 1.5,
    icon: Icons.stairs_outlined,
  ),
  Exercise(
    id: 'calf_raises',
    name: 'Calf raises',
    cue: 'Up on your toes, pause, slowly down.',
    seconds: 45,
    effort: 0.5,
    icon: Icons.height,
  ),
  Exercise(
    id: 'dance',
    name: 'One-song dance',
    cue: 'Put on a song you love and move however feels good.',
    seconds: 180,
    effort: 1.5,
    icon: Icons.music_note_outlined,
  ),
  Exercise(
    id: 'arm_circles',
    name: 'Arm circles',
    cue: 'Small circles forward, then backward.',
    seconds: 60,
    effort: 0.5,
    icon: Icons.autorenew,
  ),
  Exercise(
    id: 'evening_walk',
    name: 'Evening stroll',
    cue: 'An easy walk after dinner helps more than you think.',
    seconds: 900,
    effort: 2,
    icon: Icons.nightlight_outlined,
  ),
];
