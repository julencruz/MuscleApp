import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'addExercise.dart';
import 'package:muscle_app/backend/routine_saver.dart';

class EditScreen extends StatefulWidget {
  final Map<String, dynamic> routine;
  final List<Map<String, dynamic>> allRoutines;

  const EditScreen({
    Key? key,
    required this.routine,
    required this.allRoutines,
  }) : super(key: key);

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _restTimeController = TextEditingController();
  String _routineID = "";

  final List<String> _weekdaysShort = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  final List<String> _weekdaysFull = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  List<Map<String, dynamic>> _recentExercises = [];
  final List<bool> _selectedDays = List.filled(7, false);
  final Map<int, List<Map<String, dynamic>>> _exercisesByDay = {};
  final Map<int, List<Map<String, dynamic>>> _allExercisesByDay = {}; // Guarda TODOS los ejercicios
  List<String> _dayTypes = List.filled(7, '');
  static int _currentExerciseId = 10;

  @override
  void initState() {
    super.initState();
    _routineID = widget.routine['rID'] ?? "Routine ID not found";
    _nameController.text = widget.routine['rName'];
    _restTimeController.text = widget.routine['restTime'].toString();

    widget.routine['days'].forEach((day) {
      int dayIndex = _weekdaysFull.indexOf(day['weekDay']);
      if (dayIndex != -1) {
        _selectedDays[dayIndex] = true;
        _exercisesByDay[dayIndex] = [];
        _allExercisesByDay[dayIndex] = []; // Inicializar en ambos mapas
        _dayTypes[dayIndex] = day['dayName'] ?? '';
        
        day['exercises'].forEach((exercise) {
          _currentExerciseId++;
          final newExercise = {
            'id': _currentExerciseId,
            'eID': exercise['exerciseID'] ?? '',
            'name': exercise['exerciseName'] ?? 'Unnamed Exercise',
            'reps': exercise['reps'],
            'duration': exercise['duration'],
            'series': exercise['series'] ?? 3,
          };
          
          // Añadir a ambos mapas
          _allExercisesByDay[dayIndex]!.add(newExercise);
          _exercisesByDay[dayIndex]!.add(newExercise);
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _restTimeController.dispose();
    super.dispose();
  }

  void _toggleDaySelection(int index) {
    setState(() {
      _selectedDays[index] = !_selectedDays[index];
      
      // Asegurar que el día tiene entrada en _allExercisesByDay
      _allExercisesByDay[index] ??= [];
      
      // Actualizar _exercisesByDay según selección
      if (_selectedDays[index]) {
        _exercisesByDay[index] = List.from(_allExercisesByDay[index]!);
      } else {
        _exercisesByDay.remove(index);
      }
    });
  }

  void _navigateToAddExercise(int dayIndex) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExerciseScreen(recentExercises: _recentExercises),
      ),
    );

    if (result != null && result is List<Map<String, dynamic>>) {
      setState(() {
        // Asegurar que el día tiene entrada en ambos mapas
        _allExercisesByDay[dayIndex] ??= [];
        _exercisesByDay[dayIndex] ??= [];
        
        for (var exercise in result) {
          _currentExerciseId++;
          
          final newExercise = {
            'id': _currentExerciseId,
            'eID': exercise['eID'],
            'name': exercise['name'],
            'reps': exercise.containsKey('reps') ? exercise['reps'] : null,
            'duration': exercise.containsKey('duration') ? exercise['duration'] : null,
            'series': exercise['series'] ?? 3,
          };
          
          // Añadir a ambos mapas
          _allExercisesByDay[dayIndex]!.add(newExercise);
          if (_selectedDays[dayIndex]) {
            _exercisesByDay[dayIndex]!.add(newExercise);
          }

          // Actualizar ejercicios recientes
          _recentExercises.removeWhere((ex) => ex['eID'] == exercise['eID']);
          _recentExercises.insert(0, {
            'id': _currentExerciseId,
            'eID': exercise['eID'],
            'name': exercise['name'],
            'duration': exercise['duration'],
            'reps': exercise['reps'],
            'series': exercise['series'],
            'bodyPart': exercise['bodyPart'],
            'icon': exercise['icon']
          });

          if (_recentExercises.length > 3) {
            _recentExercises = _recentExercises.sublist(0, 3);
          }
        }
      });
    }
  }

  void _deleteExercise(int dayIndex, int exerciseId) {
    setState(() {
      _allExercisesByDay[dayIndex]?.removeWhere((exercise) => exercise['id'] == exerciseId);
      _exercisesByDay[dayIndex]?.removeWhere((exercise) => exercise['id'] == exerciseId);
    });
  }

  void _saveRoutine() async {
    try {
      // Filtrar solo los días seleccionados para guardar
      final exercisesToSave = Map.fromEntries(
        _allExercisesByDay.entries.where((entry) => _selectedDays[entry.key])
      );
      
      var routines = await RoutineSaver.updateRoutineInUserLibrary(
        _nameController,
        _restTimeController,
        exercisesToSave, // Usamos el mapa filtrado
        _dayTypes,
        _routineID,
        widget.allRoutines.indexOf(widget.routine),
        widget.allRoutines
      );
      Navigator.pop(context, routines);
    } catch (e) {
      print('Error saving routine: $e');
    }
  }

  void _onExerciseReordered(int dayIndex, int oldIndex, int newIndex) {
    setState(() {
      if (_allExercisesByDay[dayIndex] != null) {
        final exercise = _allExercisesByDay[dayIndex]!.removeAt(oldIndex);
        _allExercisesByDay[dayIndex]!.insert(newIndex, exercise);
        
        if (_exercisesByDay[dayIndex] != null) {
          final uiExercise = _exercisesByDay[dayIndex]!.removeAt(oldIndex);
          _exercisesByDay[dayIndex]!.insert(newIndex, uiExercise);
        }
      }
    });
  }

  void _onExerciseUpdated(int dayIndex, int exerciseId, Map<String, dynamic> updatedExercise) {
    setState(() {
      // Actualizar en ambos mapas
      final allExercisesList = _allExercisesByDay[dayIndex];
      if (allExercisesList != null) {
        final exerciseIndex = allExercisesList.indexWhere((exercise) => exercise['id'] == exerciseId);
        if (exerciseIndex != -1) {
          _allExercisesByDay[dayIndex]![exerciseIndex] = {
            ..._allExercisesByDay[dayIndex]![exerciseIndex],
            ...updatedExercise,
          };
        }
      }
      
      final exercisesList = _exercisesByDay[dayIndex];
      if (exercisesList != null) {
        final exerciseIndex = exercisesList.indexWhere((exercise) => exercise['id'] == exerciseId);
        if (exerciseIndex != -1) {
          _exercisesByDay[dayIndex]![exerciseIndex] = {
            ..._exercisesByDay[dayIndex]![exerciseIndex],
            ...updatedExercise,
          };
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.grey.withOpacity(0.1),
        centerTitle: true,
        title: const Text('Edit Routine'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded, color: Colors.black),
            onPressed: _saveRoutine,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            RoutineTitleAndRestTime(
              nameController: _nameController,
              restTimeController: _restTimeController,
            ),
            const SizedBox(height: 24),
            WeekdaysSelector(
              weekdaysShort: _weekdaysShort,
              selectedDays: _selectedDays,
              onToggleDay: _toggleDaySelection,
            ),
            const SizedBox(height: 24),
            ...List.generate(_selectedDays.length, (dayIndex) {
              if (!_selectedDays[dayIndex]) return const SizedBox.shrink();
              
              return ExerciseDay(
                dayIndex: dayIndex,
                dayName: _weekdaysFull[dayIndex],
                dayType: _dayTypes[dayIndex],
                exercises: _exercisesByDay[dayIndex] ?? [],
                onAddExercise: () => _navigateToAddExercise(dayIndex),
                onDayTypeChanged: (newDayType) {
                  setState(() => _dayTypes[dayIndex] = newDayType);
                },
                onDeleteExercise: (id) => _deleteExercise(dayIndex, id),
                onExerciseUpdated: _onExerciseUpdated,
                onExerciseReordered: _onExerciseReordered,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class RoutineTitleAndRestTime extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController restTimeController;

  const RoutineTitleAndRestTime({
    Key? key,
    required this.nameController,
    required this.restTimeController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: nameController,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24),
            decoration: InputDecoration(
              hintText: 'Routine Name',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontWeight: FontWeight.bold,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFA90015),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
              suffixIcon: Icon(
                Icons.edit,
                color: Colors.grey[400],
                size: 20,
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Rest Time', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Container(
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: restTimeController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Text('sec', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WeekdaysSelector extends StatelessWidget {
  final List<String> weekdaysShort;
  final List<bool> selectedDays;
  final Function(int) onToggleDay;

  const WeekdaysSelector({
    Key? key,
    required this.weekdaysShort,
    required this.selectedDays,
    required this.onToggleDay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Weekdays', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(weekdaysShort.length, (index) {
              return GestureDetector(
                onTap: () => onToggleDay(index),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selectedDays[index] ? const Color(0xFFA90015) : Colors.white,
                    border: Border.all(
                      color: selectedDays[index] ? Colors.transparent : Colors.grey.withOpacity(0.2),
                    ),
                    boxShadow: selectedDays[index]
                        ? [BoxShadow(color: const Color(0xFFA90015).withOpacity(0.2), blurRadius: 8)]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      weekdaysShort[index],
                      style: TextStyle(
                        color: selectedDays[index] ? Colors.white : Colors.grey[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class ExerciseDay extends StatefulWidget {
  final int dayIndex;
  final String dayName;
  final String? dayType;
  final List<Map<String, dynamic>> exercises;
  final VoidCallback onAddExercise;
  final Function(String) onDayTypeChanged;
  final Function(int) onDeleteExercise;
  final Function(int, int, Map<String, dynamic>) onExerciseUpdated;
  final Function(int, int, int) onExerciseReordered; // Nueva función para reordenar

  const ExerciseDay({
    Key? key,
    required this.dayIndex,
    required this.dayName,
    this.dayType,
    required this.exercises,
    required this.onAddExercise,
    required this.onDayTypeChanged,
    required this.onDeleteExercise,
    required this.onExerciseUpdated,
    required this.onExerciseReordered, // Agregamos este parámetro
  }) : super(key: key);

  @override
  State<ExerciseDay> createState() => _ExerciseDayState();
}

class _ExerciseDayState extends State<ExerciseDay> {
  late TextEditingController _dayTypeController;

  @override
  void initState() {
    super.initState();
    _dayTypeController = TextEditingController(text: widget.dayType ?? '');
  }

  @override
  void dispose() {
    _dayTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(widget.dayName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _dayTypeController,
                  onChanged: widget.onDayTypeChanged,
                  decoration: InputDecoration(
                    hintText: 'Name your workout',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFA90015)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Reemplazamos los ejercicios individuales con un ReorderableListView
          widget.exercises.isNotEmpty 
            ? ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.exercises.length,
              onReorder: (oldIndex, newIndex) {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                widget.onExerciseReordered(widget.dayIndex, oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final exercise = widget.exercises[index];
                return ExerciseItem(
                  key: ValueKey(exercise['id']),
                  index: index, // Pass the current index here
                  name: exercise['name'] ?? 'Unnamed Exercise',
                  reps: exercise['reps'],
                  duration: exercise['duration'],
                  series: exercise['series'] ?? 3,
                  onDelete: () => widget.onDeleteExercise(exercise['id']),
                  onUpdate: (updatedExercise) {
                    widget.onExerciseUpdated(widget.dayIndex, exercise['id'], updatedExercise);
                  },
                );
              },
            )
            : const SizedBox(height: 8),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: widget.onAddExercise,
              icon: const Icon(Icons.add_circle_outline, color: Color(0xFFA90015)),
              label: const Text('Add exercise', style: TextStyle(color: Color(0xFFA90015))),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFA90015).withOpacity(0.1),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ExerciseItem extends StatelessWidget {
  final int index;
  final String name;
  final int? reps;
  final int? duration;
  final int series;
  final VoidCallback onDelete;
  final Function(Map<String, dynamic>) onUpdate;

  const ExerciseItem({
    Key? key,
    required this.index,
    required this.name,
    required this.reps,
    required this.duration,
    required this.series,
    required this.onDelete,
    required this.onUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final repsText = duration != null 
        ? '${duration}s x $series' 
        : '${reps ?? 0} x $series';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _showEditDialog(context),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index, // Use the provided index instead of -1
                child: Icon(Icons.drag_handle, color: Colors.grey[600]),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(name, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Text(repsText, style: const TextStyle(fontWeight: FontWeight.w500)),
              IconButton(
                icon: const Icon(Icons.delete, color: Color(0xFFA90015)),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) async {
    final result = await showDialog(
      context: context,
      builder: (context) => RepsSetsDialog(
        exercise: {
          'name': name,
          'reps': reps,
          'duration': duration,
          'series': series,
        },
      ),
    );

    if (result != null) {
      onUpdate(result);
    }
  }
}

class RepsSetsDialog extends StatefulWidget {
  final Map<String, dynamic> exercise;
  
  const RepsSetsDialog({Key? key, required this.exercise}) : super(key: key);

  @override
  _RepsSetsDialogState createState() => _RepsSetsDialogState();
}

class _RepsSetsDialogState extends State<RepsSetsDialog> {
  late TextEditingController seriesController;
  late TextEditingController repsController;
  late TextEditingController durationController;
  late bool useReps;
  
  @override
  void initState() {
    super.initState();
    useReps = widget.exercise['reps'] != null;
    seriesController = TextEditingController(text: widget.exercise['series']?.toString() ?? '3');
    repsController = TextEditingController(text: widget.exercise['reps']?.toString() ?? '12');
    durationController = TextEditingController(text: widget.exercise['duration']?.toString() ?? '30');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.exercise['name'],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
            const SizedBox(height: 20),
            
            // Selector de modo (Reps/Duration)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => useReps = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: useReps ? const Color(0xFFA90015) : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Center(
                          child: Text(
                            'REPS',
                            style: TextStyle(
                              color: useReps ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => useReps = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !useReps ? const Color(0xFFA90015) : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Center(
                          child: Text(
                            'DURATION',
                            style: TextStyle(
                              color: !useReps ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            _buildInputField('Sets', seriesController),
            const SizedBox(height: 16),
            
            // Muestra reps o duration según la selección
            _buildInputField(
              useReps ? 'Reps' : 'Duration (sec)', 
              useReps ? repsController : durationController
            ),
            
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA90015),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () {
                Navigator.pop(context, {
                  'series': int.tryParse(seriesController.text) ?? 3,
                  'reps': useReps ? int.tryParse(repsController.text) : null,
                  'duration': !useReps ? int.tryParse(durationController.text) : null,
                });
              },
              child: const Text('Confirm', 
                  style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        SizedBox(
          width: 120,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
