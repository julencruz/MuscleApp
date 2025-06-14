import 'package:flutter/material.dart';
import 'package:muscle_app/backend/exercise_loader.dart';
import 'package:muscle_app/frontend/home.dart';
import 'package:muscle_app/frontend/modofocusdescanso.dart';
import 'package:muscle_app/backend/save_stats.dart';
import 'package:muscle_app/frontend/welcomeAnimation.dart';


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
  // Controladores y valores para peso y repeticiones por serie
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  // Lista para almacenar el histórico de las series completadas
  final List<Map<String, dynamic>> _completedSeries = [];
  
  // Lista para almacenar todos los datos de la rutina completa
  static List<List<String>> allCurrentWeights = [];
  static List<List<String>> allCurrentReps = [];
  static List<dynamic> allExercises = [];
  static List<List<bool>> allSeriesDone = [];
  
  // Mantener un registro global de todos los ejercicios completados en la sesión
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
    
    // Initialize controllers with default values
    final exercise = widget.routine['days'][widget.dayIndex]['exercises'][widget.exerciseIndex];
    _weightController.text = exercise['lastWeight'].toString();
    for (final exercise in widget.routine['days'][widget.dayIndex]['exercises']) {
      totalExercises += exercise['series'];
    }
    _repsController.text = exercise['reps'].toString();
    
    // If it's the first exercise of the day, initialize global lists
    if (widget.exerciseIndex == 0) {
      final day = widget.routine['days'][widget.dayIndex];
      final totalExercises = day['exercises'].length;
      
      // Reset static lists for a new session
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
    
    // Validar los valores ingresados
    final weight = _weightController.text.trim();
    final reps = _repsController.text.trim();
    
    if (weight.isEmpty || reps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter weight and reps'))
      );
      return;
    }
    
    try {
      // Intentar convertir para validar que sean números
      int.parse(weight);
      int.parse(reps);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid numbers for weight and reps'))
      );
      return;
    }
    
    // Guardar la serie actual en el historial local
    _completedSeries.add({
      'series': currentSeries,
      'weight': weight,
      'reps': reps,
      'exerciseName': exercise['exerciseName'],
    });
    
    // Guardar la serie actual en el registro global
    // Añadir los datos a las listas globales
    if (allCurrentWeights[widget.exerciseIndex].length < currentSeries) {
      allCurrentWeights[widget.exerciseIndex].add(weight);
      allCurrentReps[widget.exerciseIndex].add(reps);
      allSeriesDone[widget.exerciseIndex].add(true);
    } else {
      allCurrentWeights[widget.exerciseIndex][currentSeries - 1] = weight;
      allCurrentReps[widget.exerciseIndex][currentSeries - 1] = reps;
      allSeriesDone[widget.exerciseIndex][currentSeries - 1] = true;
    }
    
    // Añadir al registro global de ejercicios completados
    allCompletedExercises.add({
      'exerciseName': exercise['exerciseName'],
      'series': currentSeries,
      'weight': weight,
      'reps': reps,
    });
    
    print(exercise);
    // Mostrar la página de descanso como un bottom sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: false, // Para que el usuario no pueda cerrar el modal deslizando
      builder: (context) => ModoFocusDescansoPage(
        exerciseTitle: exercise['exerciseName'],
        initialTime: widget.routine['restTime'],
        onDescansoCompleto: () {
          // Cuando el descanso termina, cerramos el modal y avanzamos a la siguiente serie
          Navigator.pop(context);
          setState(() {
            // Si no es la última serie, avanzamos a la siguiente
            if (currentSeries < exercise['series']) {
              currentSeries++;
            } else {
              // Si es la última serie, navegamos al siguiente ejercicio
              _navegarSiguienteEjercicio();
            }
          });
        },
      ),
    );
  }
  
  // Función para guardar todas las estadísticas
  Future<void> _saveAllStats() async {
    try {
      // Asegurarse de que las listas tienen la misma longitud
      print("⚙️ Preparando datos para guardar estadísticas");
      print("📊 Pesos: $allCurrentWeights");
      print("🔢 Repeticiones: $allCurrentReps");
      print("📋 Ejercicios: ${allExercises.length}");
      print("✅ Series completadas: $allSeriesDone");
      
      // Ajustar las listas si es necesario
      for (int i = 0; i < allExercises.length; i++) {
        // Si no hay datos para este ejercicio, añadir datos vacíos
        if (i >= allCurrentWeights.length) {
          allCurrentWeights.add([]);
          allCurrentReps.add([]);
          allSeriesDone.add([]);
        }
        
        // Obtener el número esperado de series para este ejercicio
        final expectedSeries = allExercises[i]['series'];
        
        // Asegurar que tenemos el número correcto de series
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
      
      print("✅ Estadísticas guardadas correctamente");
    } catch (e) {
      print('❌ Error al guardar estadísticas: $e');
      rethrow; // Reenviar el error para manejarlo en el widget
    }
  }

  void _navegarSiguienteEjercicio() {
    final day = widget.routine['days'][widget.dayIndex];
    
    // Verificamos si hay más ejercicios en el día actual
    if (widget.exerciseIndex < day['exercises'].length - 1) {
      // Ir al siguiente ejercicio
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
      // No hay más ejercicios, mostrar diálogo de rutina completada
      showDialog(
        context: context,
        barrierDismissible: false, // No permitir cerrar el diálogo tocando fuera
        builder: (context) => FutureBuilder(
          future: _saveAllStats(), // Guardar estadísticas antes de mostrar el diálogo
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                title: Text('Saving stats...'),
                content: Center(
                  heightFactor: 1,
                  child: CircularProgressIndicator(color: Color(0xFFA90015)),
                ),
              );
            } else {
              return AlertDialog(
                title: const Text('Completed workout'),
                content: const Text('You have completed all exercises for today! Your stats have been saved.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Cierra el diálogo
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomePage(initialPageIndex: 0),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFA90015),
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
    
    // Llamar a importExercisesDetails para obtener todos los detalles
    List<Map<String, dynamic>> exercises = await ExerciseLoader.importExercisesDetails();

    // Buscar el ejercicio que corresponde al exercise['exerciseID'] (usamos 'eID' que es el ID del ejercicio)
    var selectedExercise = exercises.firstWhere(
      (ex) => ex['id'] == exercise['exerciseID'],
      orElse: () => {}, // Si no se encuentra, devuelve un Map vacío
    );

    // Verificar que el ejercicio existe y tiene instrucciones
    if (selectedExercise.isEmpty || !selectedExercise.containsKey('instructions')) {
      return; // Si no tiene instrucciones, salimos
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true, // Permite controlar el tamaño del modal
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
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFA90015),
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
                    backgroundColor: const Color(0xFFA90015),
                    minimumSize: const Size(200, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Ok',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // Método para mostrar el historial de series completadas
  void _showSeriesHistoryDialog() {
    // Verificamos si hay ejercicios completados globalmente
    if (allCompletedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No sets completed yet')),
      );
      return;
    }
    
    // Agrupar ejercicios por nombre
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
      backgroundColor: Colors.white,
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
            const Text(
              'Session history',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFA90015)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Completed sets in this session:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
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
                          style: const TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFA90015),
                          ),
                        ),
                      ),
                      const Divider(height: 4),
                      ...series.map((serie) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 1,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFFFF3F3),
                            foregroundColor: const Color(0xFFA90015),
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
                backgroundColor: const Color(0xFFA90015),
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Close', style: TextStyle(color: Colors.white)),
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        shadowColor: Colors.grey.withOpacity(0.1),
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              child: IconButton(
                icon: const Icon(Icons.close, color: Color(0xFFA90015)),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return Dialog(
                        backgroundColor: Colors.white,
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
                                      color: const Color(0xFFFFECEE),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.warning_rounded,
                                    color: Color(0xFFA90015),
                                    size: 32,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Exit workout?',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'You will lose your progress! 😰',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF666666),
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
                                        side: const BorderSide(color: Color(0xFFDDDDDD)),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Color(0xFF444444),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context); // Close dialog
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => HomePage(initialPageIndex: 0),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFA90015),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: const Text(
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
              style: const TextStyle(
                fontSize: 20,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(Icons.info_outline, color: Color(0xFFA90015)),
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
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),

              ExerciseImageCarousel(exercise: exercise),
              const SizedBox(height: 24),

              _buildExerciseCard(exercise, totalSeries),
              const SizedBox(height: 40),

              // Progreso total de la rutina al final
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
                            color: Colors.grey[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          Text(
                            '${(_calculateTotalRoutineProgress(allCompletedExercises, totalExercises) * 100).toInt()}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFA90015),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.history, color: Color(0xFFA90015)),
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
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFA90015)),
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
  int completedExercises = allCompletedExercises.length; // Número de ejercicios completados
  if (totalExercises == 0) return 0.0; // Evitar división por cero
  return completedExercises / totalExercises; // Progreso total
}

  Widget _buildExerciseCard(Map<String, dynamic> exercise, int totalSeries) {
    return Card(
      color: Colors.white,
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
                          const Icon(Icons.fitness_center, color: Color(0xFFA90015)),
                          const SizedBox(width: 8),
                          const Text(
                            'Weight:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
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
                          const Icon(Icons.repeat, color: Color(0xFFA90015)),
                          const SizedBox(width: 8),
                          const Text(
                            'Reps:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
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
              style: const TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                color: Color(0xFFA90015),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _mostrarDescanso, // Ahora solo tenemos un botón para continuar
              icon: const Icon(Icons.navigate_next),
              label: const Text('Continue'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA90015),
                foregroundColor: Colors.white,
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
            color: const Color(0xFFA90015).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$number',
            style: const TextStyle(
              color: Color(0xFFA90015),
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
              color: Colors.grey[800],
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
                  color: Colors.white,
                  alignment: Alignment.center,
                  child: const Text('Error de imagen'),
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
                            ? const Color(0xFFA90015) // Punto rojo activo
                            : Colors.white.withOpacity(0.5),
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