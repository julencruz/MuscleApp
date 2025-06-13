import 'package:flutter/material.dart';


class GoalsWidget extends StatelessWidget {
  final int completedWorkouts;
  final int totalWorkouts;
  final int streak;

  const GoalsWidget({
    Key? key,
    required this.completedWorkouts,
    required this.totalWorkouts,
    required this.streak,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  blurRadius: 5,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                const Text("🔥", style: TextStyle(fontSize: 30)),
                const SizedBox(width: 10),
                // Texto de racha
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$streak days",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Keep pushing! Don't lose your streak",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class DiesWidget extends StatelessWidget {
  const DiesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 5,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildWorkoutBox("18", "Push", Colors.grey[300]!, Colors.black),
          ),
          const SizedBox(width: 8),
          Expanded( // Añadido
            child: _buildWorkoutBox("19", "Leg Day", Color(0xFFA90015), Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded( // Añadido
            child: _buildWorkoutBox("20", "Pull", Colors.grey[300]!, Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutBox(
    String number,
    String text,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            number,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4,),
          Text(text, style: TextStyle(fontSize: 14, color: textColor)),
        ],
      ),
    );
  }
}

class TodaysWorkoutWidget extends StatelessWidget {
  const TodaysWorkoutWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Color(0xFFA90015),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Done',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            "Leg Day",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildExerciseRow(
            exercise: "Sentadillas",
            kgs: ["65", "65"],
            reps: ["10", "10"],
          ),
          const SizedBox(height: 20),
          _buildExerciseRow(exercise: "Prensa", sets: "3x12"),
          const SizedBox(height: 30),
          Center(child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(Icons.shuffle),
                const SizedBox(width: 50),
                _buildActionButton(Icons.play_arrow),
              ],
            ),)
        ],
      ),
    );
  }

  Widget _buildExerciseRow({
    required String exercise,
    String? sets,
    List<String>? kgs,
    List<String>? reps,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 82, 78, 78).withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                exercise,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (sets != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    sets,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (kgs != null && reps != null) ... [ //spread operator, poner multiples elementos en una lista
            const Divider(height: 20, thickness: 0.5, color: Colors.grey),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildWeightRepsColumn('kg', kgs),
                const SizedBox(width: 25),
                _buildWeightRepsColumn('reps', reps),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildWeightRepsColumn(String title, List<String> values) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 2,
              ),
            ],
          ),
          child: Column(
            children:
                values
                    .map(
                      (value) => Text(
                        value,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon){
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFA90015),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        iconSize: 30,
        onPressed: (){},
      ),
    );
  }
}
