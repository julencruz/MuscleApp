import 'package:flutter/material.dart';
import 'widgets.dart';

class HomeWidgetScreen extends StatelessWidget {
  const HomeWidgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Workout'),
        centerTitle: true,
        actions: const [Icon(Icons.notifications_none)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GoalsWidget(
              completedWorkouts: 3,
              totalWorkouts: 5,
              streak: 5,
            ),
            const SizedBox(height: 20),
            const DiesWidget(),
            const SizedBox(height: 20),
            const TodaysWorkoutWidget(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
