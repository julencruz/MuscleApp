import 'package:flutter/material.dart';
import 'package:muscle_app/backend/achievement_manager.dart';
import 'package:muscle_app/backend/exercise_loader.dart';
import 'package:muscle_app/frontend/infoWarmup.dart';
import 'package:muscle_app/theme/app_colors.dart';

class WarmUpButton extends StatefulWidget {
  final List<dynamic> dayRoutine;

  const WarmUpButton({
    super.key,
    required this.dayRoutine,
  });

  @override
  State<WarmUpButton> createState() => _WarmUpButtonState();
}

class _WarmUpButtonState extends State<WarmUpButton> {
  bool _isHovered = false;

  // List of all possible muscle groups
  final List<String> allMuscleGroups = [
    'triceps', 'chest', 'middle back', 'glutes', 'abdominals',
    'lats', 'neck', 'shoulders', 'quadriceps', 'calves',
    'lower back', 'adductors', 'forearms', 'biceps',
    'traps', 'hamstrings', 'abductors'
  ];

  // Mapping muscles to specific warm-up exercises
  final Map<String, List<Map<String, String>>> muscleWarmups = {
    'triceps': [
      {'name': 'Arm circles', 'description': '30 seconds each direction', 'id': 'Arm_Circles'},
      {'name': 'Tricep stretches', 'description': '15 seconds each arm', 'id': 'Triceps_Stretch'}
    ],
    'chest': [
      {'name': 'Chest stretches', 'description': '30 seconds', 'id': 'Dynamic_Chest_Stretch'},
      {'name': 'Cross overs', 'description': '5 each side', 'id': 'Cross_Over_-_With_Bands' }
    ],
    'middle back': [
      {'name': 'Cat stretches', 'description': '30 seconds', 'id': 'Cat_Stretch'},
      {'name': 'Thoracic rotations', 'description': '5 each side', 'id': 'Middle_Back_Stretch'}
    ],
    'glutes': [
      {'name': 'Glute bridges', 'description': '10 reps', 'id': 'Butt_Lift_Bridge'},
    ],
    'abdominals': [
      {'name': 'Cross-Body Crunches', 'description': '20 total', 'id': 'Cross-Body_Crunch'},
      {'name': 'Leg raise', 'description': '20 total', 'id': 'Flat_Bench_Lying_Leg_Raise'}
    ],
    'lats': [
      {'name': 'Child\'s pose', 'description': '5 each side', 'id': 'Childs_Pose'},
    ],
    'neck': [
      {'name': 'Side to side', 'description': '4 directions, 10 seconds each', 'id':'Isometric_Neck_Exercise_-_Sides'},
      {'name': 'Front and back', 'description': '15 reps', 'id': 'Isometric_Neck_Exercise_-_Front_And_Back'}
    ],
    'shoulders': [
      {'name': 'Arm circles', 'description': '30 seconds each direction', 'id': 'Arm_Circles'},
      {'name': 'Shoulder rolls', 'description': '10 forward, 10 backward', 'id': 'Shoulder_Circles'}
    ],
    'quadriceps': [
      {'name': 'Bodyweight squats', 'description': '10 reps', 'id': 'Bodyweight_Squat'},
      {'name': 'Quad stretches', 'description': '15 seconds each leg', 'id': 'Standing_Elevated_Quad_Stretch'}
    ],
    'calves': [
      {'name': 'Calf stretch', 'description': '15 reps', 'id': 'Calf_Stretch_Hands_Against_Wall'},
      {'name': 'Seated calf stretch', 'description': '20 seconds', 'id': 'Seated_Calf_Stretch'}
    ],
    'lower back': [
      {'name': 'Cat-cow stretches', 'description': '30 seconds', 'id': 'Cat_Stretch'},
      {'name': 'Supermans', 'description': '8 reps, hold 3 seconds', 'id': 'Superman'}
    ],
    'adductors': [
      {'name': 'Groin stretch', 'description': '5 reps', 'id':'Groiners' },
    ],
    'forearms': [
      {'name': 'Wrist circles', 'description': '10 each direction', 'id': 'Wrist_Circles'},
      {'name': 'Forearm stretches', 'description': '15 seconds', 'id': 'Kneeling_Forearm_Stretch'}
    ],
    'biceps': [
      {'name': 'Bicep stretches', 'description': '15 seconds each arm', 'id': 'Standing_Biceps_Stretch'}
    ],
    'traps': [
      {'name': 'Shoulder shrugs', 'description': '10 reps', 'id': 'Dumbbell_Shrug'}
    ],
    'hamstrings': [
      {'name': 'Standing toe touches', 'description': '10 reps', 'id': 'Standing_Toe_Touches'},
    ],
    'abductors': [
      {'name': 'Side leg raises', 'description': '8 each side', 'id': 'Side_Leg_Raises'},
    ],
  };

  // Always include these general warm-up exercises
  final List<Map<String, String>> generalWarmups = [
    {'name': 'Jumping jacks', 'description': '30 seconds', 'id': 'Jumping_Jacks'},
    {'name': 'High knees', 'description': '20 seconds', 'id': 'High_Knees'},
    {'name': 'Arm circles', 'description': '10 each direction', 'id': 'Arm_Circles'}
  ];

  // Function to get muscle groups from today's workout
  Future<List<String>> getMusclesForToday() async {
    List<String> todaysMuscles = [];
    final allExercises = await ExerciseLoader.importExercises();

    // Get all exercises for today - dayRoutine is now a list of exercises
    List<dynamic> todaysExercises = widget.dayRoutine;

    for (var exercise in todaysExercises) {
      String exerciseID = exercise['exerciseID'];

      // Find the exercise details in the full list
      var exerciseDetails = allExercises.firstWhere(
            (e) => e['eID'] == exerciseID,
        orElse: () => {'primaryMuscles': [], 'secondaryMuscles': []},
      );

      // Add primary muscles
      for (var muscle in exerciseDetails['primaryMuscles'] ?? []) {
        if (!todaysMuscles.contains(muscle)) {
          todaysMuscles.add(muscle);
        }
      }

      // Add secondary muscles
      for (var muscle in exerciseDetails['secondaryMuscles'] ?? []) {
        if (!todaysMuscles.contains(muscle)) {
          todaysMuscles.add(muscle);
        }
      }
    }

    return todaysMuscles;
  }

  // Generate personalized warm-up exercises, ensuring no duplicates
  Future<List<Map<String, String>>> getPersonalizedWarmups() async {
    List<Map<String, String>> warmupExercises = [];
    Set<String> addedExerciseIds = {}; // To keep track of added exercises
    List<String> targetMuscles = await getMusclesForToday();

    // Add general warm-ups, ensuring no duplicates
    for (var warmup in generalWarmups) {
      if (addedExerciseIds.add(warmup['id']!)) {
        warmupExercises.add(warmup);
      }
    }

    // Add specific warm-ups for the muscles being trained today, ensuring no duplicates
    for (String muscle in targetMuscles) {
      if (muscleWarmups.containsKey(muscle)) {
        final warmup = muscleWarmups[muscle]![0];
        if (addedExerciseIds.add(warmup['id']!)) {
          warmupExercises.add(warmup);
        }
      }
    }

    // Limit to maximum 8 warm-up exercises to keep it reasonable
    if (warmupExercises.length > 8) {
      warmupExercises = warmupExercises.sublist(0, 8);
    }

    return warmupExercises;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        // Get personalized warm-ups
        AchievementManager().unlockAchievement("view_warmup");
        final personalizedWarmups = await getPersonalizedWarmups();
        print(personalizedWarmups);

        if (!mounted) return;

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.local_fire_department, color: redColor),
                  const SizedBox(width: 10),
                  Text(
                    "Warming Up",
                    style: TextStyle(fontWeight: FontWeight.bold, color: textColor2),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Get your muscles ready for your workout!", style: TextStyle(color: textColor2)),
                  const SizedBox(height: 16),
                  ...personalizedWarmups.map((warmup) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("• ", style: TextStyle(fontWeight: FontWeight.bold, color: redColor)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    warmup['name']!,
                                    style: TextStyle(fontWeight: FontWeight.w500, color: textColor2),
                                  ),
                                  Text(
                                    warmup['description']!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: hintColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => InfoWarmupExerciseScreen(exerciseId: warmup['id']!),
                                  ),
                                );
                              },
                              child: Icon(
                                Icons.info_outline,
                                size: 20,
                                color: redColor,
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                ],
              ),
              actions: [
                TextButton(
                  child: Text(
                    "Ready",
                    style: TextStyle(
                      color: redColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
      },
      onHover: (value) => setState(() => _isHovered = value),
      borderRadius: BorderRadius.circular(12),
      splashColor: const Color(0xFFFFD5D5),
      highlightColor: const Color(0xFFFFECEC),
      child: Container(
        decoration: BoxDecoration(
          color: _isHovered ? const Color(0xFFFFE5E5) : cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: redColor, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_fire_department,
                size: 16,
                color: redColor,
              ),
              const SizedBox(width: 5), // Added some spacing
              Text(
                "Warm Up",
                style: TextStyle(
                  color: redColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}