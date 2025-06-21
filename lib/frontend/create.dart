import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:muscle_app/backend/achievement_manager.dart';
import 'package:muscle_app/backend/routine_saver.dart';
import 'package:muscle_app/frontend/cuestionarioRutina.dart';
import 'package:muscle_app/frontend/home.dart';
import 'package:muscle_app/theme/app_colors.dart';
import 'addExercise.dart';

// Pantalla principal
class CreateScreen extends StatefulWidget {
  const CreateScreen({Key? key}) : super(key: key);

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _restTimeController = TextEditingController();
  
  final List<String> _weekdaysShort = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  final List<String> _weekdaysFull = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  String _restTimeUnit = 'sec';
  
  List<Map<String, dynamic>> _recentExercises = [];
  final List<bool> _selectedDays = [false, false, false, false, false, false, false];
  final Map<int, List<Map<String, dynamic>>> _exercisesByDay = {};
  final Map<int, List<Map<String, dynamic>>> _allExercisesByDay = {}; // Guarda TODOS los ejercicios
  List<String> _dayTypes = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  static int _currentExerciseId = 10;

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
    final List<dynamic>? result = await Navigator.push(
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
            'measurementType': exercise['measurementType'] ?? 'reps',
            'duration': exercise['measurementType'] == 'duration' ? exercise['duration'] : null,
            'reps': exercise['measurementType'] == 'reps' ? exercise['reps'] : null,
            'series': exercise['series'],
          };
          
          // Añadir a ambos mapas
          _allExercisesByDay[dayIndex]!.add(newExercise);
          if (_selectedDays[dayIndex]) {
            _exercisesByDay[dayIndex]!.add(newExercise);
          }

          // Actualizar ejercicios recientes
          if (_recentExercises.isNotEmpty) {
            _recentExercises.removeWhere((ex) => ex['eID'] == exercise['eID']);
          }

          _recentExercises.insert(0, {
            'id': _currentExerciseId,
            'eID': exercise['eID'],
            'name': exercise['name'],
            'measurementType': exercise['measurementType'] ?? 'reps',
            'duration': exercise['measurementType'] == 'duration' ? exercise['duration'] : null,
            'reps': exercise['measurementType'] == 'reps' ? exercise['reps'] : null,
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

  void _reorderExercise(int dayIndex, int oldIndex, int newIndex) {
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

  void _saveRoutine() {
    int restTimeValue = int.tryParse(_restTimeController.text) ?? 0;
    if (_restTimeUnit == 'min') {
      restTimeValue *= 60;
    }
    _restTimeController.text = restTimeValue.toString();

    // Filtrar solo los días seleccionados para guardar
    final exercisesToSave = Map.fromEntries(
      _allExercisesByDay.entries.where((entry) => _selectedDays[entry.key])
    );
    
    AchievementManager().unlockAchievement("start_journey");
    RoutineSaver.addRoutineToUserLibrary(
      _nameController, 
      _restTimeController, 
      exercisesToSave,
      _dayTypes
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Workout saved!', style: TextStyle(color: contraryTextColor)), backgroundColor: snackBarBackgroundColor),
    );
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(initialPageIndex: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.auto_awesome, color: textColor),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RoutineQuestionnaire()),
            );
          },
        ),
        surfaceTintColor: Colors.transparent,
        backgroundColor: appBarBackgroundColor,
        elevation: 0,
        shadowColor: shadowColor,
        centerTitle: true,
        title: Text('Create Routine', style: TextStyle(color: textColor),),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.save_rounded, color: textColor),
              ),
              onPressed: _saveRoutine,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Routine Name',
                        hintStyle: TextStyle(
                          color: hintColor,
                          fontWeight: FontWeight.bold,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: dividerColor,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: textColor,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                        suffixIcon: Icon(
                          Icons.edit,
                          color: hintColor,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: backgroundColor,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Rest Time',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 120,
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: dividerColor,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _restTimeController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: InputDecoration(
                                    hintText: '90',
                                    hintStyle: TextStyle(
                                      color: hintColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 8,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.only(right: 8),
                                child: DropdownButton<String>(
                                  value: _restTimeUnit,
                                  underline: SizedBox(),
                                  style: TextStyle(
                                    color: hintColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  dropdownColor: backgroundColor,
                                  borderRadius: BorderRadius.circular(12),
                                  items: [
                                    DropdownMenuItem(
                                      value: 'sec',
                                      child: Text('sec', style: TextStyle(color: hintColor)),
                                    ),
                                    DropdownMenuItem(
                                      value: 'min',
                                      child: Text('min', style: TextStyle(color: hintColor)),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        int currentValue = int.tryParse(_restTimeController.text) ?? 0;
                                        if (_restTimeUnit == 'min' && value == 'sec') {
                                          _restTimeController.text = (currentValue * 60).toString();
                                        } else if (_restTimeUnit == 'sec' && value == 'min') {
                                          _restTimeController.text = (currentValue ~/ 60).toString();
                                        }
                                        _restTimeUnit = value;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekdays',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        _weekdaysShort.length,
                        (index) => GestureDetector(
                          onTap: () => _toggleDaySelection(index),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _selectedDays[index]
                                  ? redColor
                                  : cardColor,
                              border: Border.all(
                                color: _selectedDays[index]
                                    ? Colors.transparent
                                    : dividerColor,
                                width: 1.5,
                              ),
                              boxShadow: [
                                if (_selectedDays[index])
                                  BoxShadow(
                                    color: redColor.withOpacity(0.2),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _weekdaysShort[index],
                                style: TextStyle(
                                  color: _selectedDays[index]
                                      ? Colors.white
                                      : textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
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
              
              Column(
                children: _selectedDays.asMap().entries.where((e) => e.value).map(
                  (entry) => ExerciseDay(
                    dayIndex: entry.key,
                    dayName: _weekdaysFull[entry.key],
                    exercises: _exercisesByDay[entry.key] ?? [],
                    onAddExercise: () => _navigateToAddExercise(entry.key),
                    onDayTypeChanged: (newDayType) {
                      setState(() {
                        _dayTypes[entry.key] = newDayType;
                      });
                    },
                    onDeleteExercise: (exerciseId) => _deleteExercise(entry.key, exerciseId),
                    onExerciseReordered: _reorderExercise,
                  ),
                ).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget de título y tiempo de descanso
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
    return Column(
      children: [
        // Título de la rutina
        TextField(
          controller: nameController,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          decoration: const InputDecoration(
            hintText: 'Routine Name',
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 16.0),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Tiempo de descanso
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Rest Time: ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(
              width: 100,
              child: TextField(
                controller: restTimeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  hintText: '90',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                  suffixText: 'sec',
                  hintStyle: TextStyle(color: hintColor),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Widget de selección de días de la semana
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text(
            'Weekdays',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(weekdaysShort.length, (index) {
            return GestureDetector(
              onTap: () => onToggleDay(index),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selectedDays[index] ? redColor : Colors.transparent,
                  border: Border.all(
                    color: textColor,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    weekdaysShort[index],
                    style: TextStyle(
                      color: selectedDays[index] ? contraryTextColor : textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// Widget para un día específico con sus ejercicios y un input para el nombre del día
class ExerciseDay extends StatefulWidget {
  final int dayIndex;
  final String dayName;
  final String? dayType;
  final List<Map<String, dynamic>> exercises;
  final VoidCallback onAddExercise;
  final Function(String) onDayTypeChanged;
  final Function(int) onDeleteExercise;
  final Function(int, int, int) onExerciseReordered;

  const ExerciseDay({
    Key? key,
    required this.dayIndex,
    required this.dayName,
    this.dayType,
    required this.exercises,
    required this.onAddExercise,
    required this.onDayTypeChanged,
    required this.onDeleteExercise,
    required this.onExerciseReordered,
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
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.dayName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _dayTypeController,
                  decoration: InputDecoration(
                    hintText: 'Name your workout',
                    hintStyle: TextStyle(
                      color: hintColor,
                      fontWeight: FontWeight.w500,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: dividerColor,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: redColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: backgroundColor,
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  onChanged: widget.onDayTypeChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Reorderable list of exercises
          ReorderableListView.builder(
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
                index: index,
                name: exercise['name'],
                reps: exercise['measurementType'] == 'duration' 
                      ? '${exercise['duration']}s x ${exercise['series']}' 
                      : '${exercise['reps']} x ${exercise['series']}',
                onDelete: () => widget.onDeleteExercise(exercise['id']),
              );
            },
          ),
          // Add exercise button
          Center(
            child: TextButton.icon(
              onPressed: widget.onAddExercise,
              icon: Icon(
                Icons.add_circle_outline_rounded,
                color: redColor,
              ),
              label: Text(
                'Add exercise',
                style: TextStyle(
                  color: redColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: redColor.withOpacity(0.1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget para un elemento de ejercicio individual
class ExerciseItem extends StatelessWidget {
  final int index;
  final String name;
  final String reps;
  final VoidCallback onDelete;

  const ExerciseItem({
    Key? key,
    required this.index,
    required this.name,
    required this.reps,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ReorderableDragStartListener(
      index: index,
      child: Container(
        key: ValueKey('${name}_$index'),
        margin: const EdgeInsets.only(bottom: 8.0),
        padding: const EdgeInsets.symmetric(
          vertical: 12.0,
          horizontal: 16.0,
        ),
        decoration: BoxDecoration(
          color: failedColor,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            const Icon(Icons.drag_handle),
            const SizedBox(width: 8),
            Flexible(
              fit: FlexFit.tight,
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              reps,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.delete, color: redColor),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}