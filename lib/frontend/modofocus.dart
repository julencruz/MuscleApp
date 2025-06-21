import 'package:flutter/material.dart';
import 'package:muscle_app/backend/exercise_loader.dart';
import 'package:muscle_app/frontend/home.dart';
import 'package:muscle_app/frontend/modofocusdescanso.dart';
import 'package:muscle_app/backend/save_stats.dart';
import 'package:muscle_app/frontend/welcomeAnimation.dart';
import 'package:muscle_app/theme/app_colors.dart';


class ModoFocusPage extends StatefulWidget {
  final Map<String, dynamic> routine;
  final int dayIndex;
  final int exerciseIndex;

  const ModoFocusPage({
    super.key,
    required this.routine,
    required this.dayIndex,
    required this.exerciseIndex,
  });

  @override
  State<ModoFocusPage> createState() => _ModoFocusPageState();
}

class _ModoFocusPageState extends State<ModoFocusPage> with SingleTickerProviderStateMixin {
  int currentSeries = 1;
  bool _showWelcome = false;
  late AnimationController _animationController;
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  final List<Map<String, dynamic>> _completedSeries = [];
  
  static List<List<String>> allCurrentWeights = [];
  static List<List<String>> allCurrentReps = [];
  static List<dynamic> allExercises = [];
  static List<List<bool>> allSeriesDone = [];
  static List<Map<String, dynamic>> allCompletedExercises = [];
  static num totalExercises = 0;
  
  @override
  void initState() {
    super.initState();
    if (widget.exerciseIndex == 0){
      _showWelcome = true;
    }
    totalExercises = 0;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    final exercise = widget.routine['days'][widget.dayIndex]['exercises'][widget.exerciseIndex];
    _weightController.text = exercise['lastWeight'].toString();
    for (final exercise in widget.routine['days'][widget.dayIndex]['exercises']) {
      totalExercises += exercise['series'];
    }
    _repsController.text = exercise['reps'].toString();
    
    if (widget.exerciseIndex == 0) {
      final day = widget.routine['days'][widget.dayIndex];
      final totalExercises = day['exercises'].length;
      
      allCurrentWeights = List.generate(totalExercises, (_) => []);
      allCurrentReps = List.generate(totalExercises, (_) => []);
      allExercises = List.from(day['exercises']);
      allSeriesDone = List.generate(totalExercises, (_) => []);
      allCompletedExercises = [];
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _mostrarDescanso() {
    final day = widget.routine['days'][widget.dayIndex];
    final exercise = day['exercises'][widget.exerciseIndex];
    
    final weight = _weightController.text.trim();
    final reps = _repsController.text.trim();
    
    if (weight.isEmpty || reps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter weight and reps', style: TextStyle(color: contraryTextColor)), backgroundColor: snackBarBackgroundColor)
      );
      return;
    }
    
    try {
      int.parse(weight);
      int.parse(reps);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter valid numbers for weight and reps', style: TextStyle(color: contraryTextColor)), backgroundColor: snackBarBackgroundColor)
      );
      return;
    }
    
    _completedSeries.add({
      'series': currentSeries,
      'weight': weight,
      'reps': reps,
      'exerciseName': exercise['exerciseName'],
    });
    
    if (allCurrentWeights[widget.exerciseIndex].length < currentSeries) {
      allCurrentWeights[widget.exerciseIndex].add(weight);
      allCurrentReps[widget.exerciseIndex].add(reps);
      allSeriesDone[widget.exerciseIndex].add(true);
    } else {
      allCurrentWeights[widget.exerciseIndex][currentSeries - 1] = weight;
      allCurrentReps[widget.exerciseIndex][currentSeries - 1] = reps;
      allSeriesDone[widget.exerciseIndex][currentSeries - 1] = true;
    }
    
    allCompletedExercises.add({
      'exerciseName': exercise['exerciseName'],
      'series': currentSeries,
      'weight': weight,
      'reps': reps,
    });
    
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: false,
      builder: (context) => ModoFocusDescansoPage(
        exerciseTitle: exercise['exerciseName'],
        initialTime: widget.routine['restTime'],
        onDescansoCompleto: () {
          Navigator.pop(context);
          setState(() {
            if (currentSeries < exercise['series']) {
              currentSeries++;
            } else {
              _navegarSiguienteEjercicio();
            }
          });
        },
      ),
    );
  }
  
  Future<void> _saveAllStats() async {
    try {
      for (int i = 0; i < allExercises.length; i++) {
        if (i >= allCurrentWeights.length) {
          allCurrentWeights.add([]);
          allCurrentReps.add([]);
          allSeriesDone.add([]);
        }
        
        final expectedSeries = allExercises[i]['series'];
        
        while (allSeriesDone[i].length < expectedSeries) {
          allCurrentWeights[i].add("0");
          allCurrentReps[i].add("0");
          allSeriesDone[i].add(false);
        }
      }
      
      bool focus = true;
      await StatsSaver.saveStats(
        allCurrentWeights,
        allCurrentReps,
        allExercises,
        allSeriesDone,
        focus
      );
    } catch (e) {
      print('❌ Error al guardar estadísticas: $e');
      rethrow;
    }
  }

  void _navegarSiguienteEjercicio() {
    final day = widget.routine['days'][widget.dayIndex];
    
    if (widget.exerciseIndex < day['exercises'].length - 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ModoFocusPage(
            routine: widget.routine,
            dayIndex: widget.dayIndex,
            exerciseIndex: widget.exerciseIndex + 1,
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => FutureBuilder(
          future: _saveAllStats(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return AlertDialog(
                title: const Text('Saving stats...'),
                content: Center(
                  heightFactor: 1,
                  child: CircularProgressIndicator(color: redColor),
                ),
              );
            } else {
              return AlertDialog(
                title: const Text('Completed workout'),
                content: const Text('You have completed all exercises for today! Your stats have been saved.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomePage(initialPageIndex: 0),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: redColor,
                    ),
                    child: const Text('Complete'),
                  ),
                ],
              );
            }
          },
        ),
      );
    }
  }

  void _showExerciseInfoDialog() async {
    final day = widget.routine['days'][widget.dayIndex];
    final exercise = day['exercises'][widget.exerciseIndex];
    
    List<Map<String, dynamic>> exercises = await ExerciseLoader.importExercisesDetails();

    var selectedExercise = exercises.firstWhere(
      (ex) => ex['id'] == exercise['exerciseID'],
      orElse: () => {},
    );

    if (selectedExercise.isEmpty || !selectedExercise.containsKey('instructions')) {
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  selectedExercise['name'],
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: redColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Instructions to perform the exercise:',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
              ),
              const SizedBox(height: 12),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(
                  selectedExercise['instructions'].length,
                  (index) => _buildInstructionStep(
                    index + 1,
                    selectedExercise['instructions'][index],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: redColor,
                    minimumSize: const Size(200, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Ok',
                    style: TextStyle(fontSize: 16, color: contraryTextColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSeriesHistoryDialog() {
    if (allCompletedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No sets completed yet.', style: TextStyle(color: contraryTextColor)), backgroundColor: snackBarBackgroundColor)
      );
      return;
    }
    
    final Map<String, List<Map<String, dynamic>>> exerciseGroups = {};
    
    for (final exercise in allCompletedExercises) {
      final name = exercise['exerciseName'];
      if (!exerciseGroups.containsKey(name)) {
        exerciseGroups[name] = [];
      }
      exerciseGroups[name]!.add(exercise);
    }
    
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session history',
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.bold, 
                color: redColor
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Completed sets in this session:',
              style: TextStyle(
                fontSize: 14, 
                color: textColor2
              ),
            ),
            const Divider(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: exerciseGroups.length,
                itemBuilder: (context, index) {
                  final exerciseName = exerciseGroups.keys.elementAt(index);
                  final series = exerciseGroups[exerciseName]!;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          exerciseName,
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold,
                            color: redColor,
                          ),
                        ),
                      ),
                      const Divider(height: 4),
                      ...series.map((serie) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 1,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: redColor.withOpacity(0.1),
                            foregroundColor: redColor,
                            child: Text('${serie['series']}'),
                          ),
                          title: Text('${serie['weight']} kg', 
                            style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text('${serie['reps']} reps'),
                          trailing: const Icon(Icons.check_circle, color: Colors.green),
                        ),
                      )).toList(),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: redColor,
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Close', 
                style: TextStyle(color: contraryTextColor)
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showWelcome) {
      return WelcomeAnimation(
        onAnimationComplete: () {
          setState(() {
            _showWelcome = false;
          });
        },
      );
    }
    final day = widget.routine['days'][widget.dayIndex];
    final exercise = day['exercises'][widget.exerciseIndex];
    final totalSeries = exercise['series'];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: appBarBackgroundColor,
        shadowColor: shadowColor,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              child: IconButton(
                icon: Icon(Icons.close, color: redColor),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return Dialog(
                        backgroundColor: cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: redColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  Icon(
                                    Icons.warning_rounded,
                                    color: redColor,
                                    size: 32,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Exit workout?',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'You will lose your progress! 😰',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: textColor2,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: dividerColor),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: textColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => HomePage(initialPageIndex: 0),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: redColor,
                                        foregroundColor: contraryTextColor,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: Text(
                                        'Exit',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Text(
              day['dayName'] ?? 'Workout',
              style: TextStyle(
                fontSize: 20,
                color: textColor,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: Icon(Icons.info_outline, color: redColor),
              onPressed: _showExerciseInfoDialog,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  exercise['exerciseName'],
                  style: TextStyle(
                    fontSize: 24,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),

              ExerciseImageCarousel(exercise: exercise),
              const SizedBox(height: 24),

              _buildExerciseCard(exercise, totalSeries),
              const SizedBox(height: 40),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Progress: ${allCompletedExercises.length}/$totalExercises total sets',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: textColor2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          Text(
                            '${(_calculateTotalRoutineProgress(allCompletedExercises, totalExercises) * 100).toInt()}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: redColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.history, color: redColor),
                            onPressed: _showSeriesHistoryDialog,
                            tooltip: 'Sets history',
                            iconSize: 30,
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _calculateTotalRoutineProgress(allCompletedExercises, totalExercises),
                      backgroundColor: failedColor,
                      valueColor: AlwaysStoppedAnimation<Color>(redColor),
                      minHeight: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateTotalRoutineProgress(List<Map<String, dynamic>> allCompletedExercises, num totalExercises) {
    int completedExercises = allCompletedExercises.length;
    if (totalExercises == 0) return 0.0;
    return completedExercises / totalExercises;
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise, int totalSeries) {
    return Card(
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.fitness_center, color: redColor),
                          const SizedBox(width: 8),
                          Text(
                            'Weight:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.repeat, color: redColor),
                          const SizedBox(width: 8),
                          Text(
                            'Reps:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _repsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Set: $currentSeries/$totalSeries', 
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                color: redColor,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _mostrarDescanso,
              icon: const Icon(Icons.navigate_next, color: Colors.white,),
              label: const Text('Continue', style: TextStyle(color: Colors.white),),
              style: ElevatedButton.styleFrom(
                backgroundColor: redColor,
                foregroundColor: contraryTextColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: redColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$number',
              style: TextStyle(
                color: redColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ExerciseImageCarousel extends StatefulWidget {
  final Map<String, dynamic> exercise;

  const ExerciseImageCarousel({super.key, required this.exercise});

  @override
  _ExerciseImageCarouselState createState() => _ExerciseImageCarouselState();
}

class _ExerciseImageCarouselState extends State<ExerciseImageCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;
  late final List<String> _imagePaths;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _imagePaths = [
      '${widget.exercise['exerciseID']}/0.jpg',
      '${widget.exercise['exerciseID']}/1.jpg',
    ];

    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentPage) {
        setState(() => _currentPage = page);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _imagePaths.length,
              itemBuilder: (context, index) => Image.asset(
                'assets/images/exercises_images/${_imagePaths[index]}',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: cardColor,
                  alignment: Alignment.center,
                  child: Text('Error de imagen', style: TextStyle(color: textColor)),
                ),
              ),
            ),
            if (_imagePaths.length > 1)
              Positioned(
                bottom: 16,
                child: Row(
                  children: List.generate(
                    _imagePaths.length,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index
                            ? redColor
                            : contraryTextColor.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}