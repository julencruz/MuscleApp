import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:muscle_app/backend/routine_saver.dart';
import 'package:muscle_app/backend/workout_generator.dart';
import 'package:muscle_app/frontend/home.dart';

class RoutineQuestionnaire extends StatefulWidget {
  const RoutineQuestionnaire({super.key});

  @override
  State<RoutineQuestionnaire> createState() => _RoutineQuestionnaireState();
}

class _RoutineQuestionnaireState extends State<RoutineQuestionnaire>
    with TickerProviderStateMixin {
   
  String? level;
  String? goal;
  double _sliderValue = 3; // Initial value representing the mid-range
  int step = 0;
  List<bool> selectedDays = List.generate(7, (index) => false);
  final List<String> weekdaysShort = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  // Color definitions for each level
  final Map<String, Color> levelColors = {
    'Beginner': const Color(0xFF2E7D32),  // Green
    'Intermediate': const Color(0xFFFFA000),  // Amber
    'Expert': const Color(0xFFA90015),  // Red
  };

  // Color definitions for each goal
  final Map<String, Color> goalColors = {
    'Improve physique': const Color(0xFF1976D2),  // Blue
    'Increase strength': const Color(0xFF7B1FA2),  // Purple
    'Improve health': const Color(0xFF00796B),  // Teal
  };

  // Maps for icons
  final Map<String, IconData> levelIcons = {
    'Beginner': Icons.directions_run,
    'Intermediate': Icons.sports_gymnastics,
    'Expert': Icons.sports_martial_arts,
  };

  final Map<String, IconData> goalIcons = {
    'Improve physique': Icons.accessibility_new,
    'Increase strength': Icons.fitness_center,
    'Improve health': Icons.personal_injury,
  };

  // Controllers for icon animations
  late AnimationController _iconAnimationController;
  late Animation<double> _iconOpacityAnimation;
  
  // Controller for particle effects
  late AnimationController _particleController;
  
  // Background effect controllers list
  List<AnimationController> _backgroundEffectControllers = [];

  // Mapping slider values to time ranges
  final Map<double, String> timeRanges = {
    1: "≤ 30 min",
    2: "31-60 min",
    3: "61-90 min",
    4: "91-120 min",
    5: "> 120 min",
  };

  String get _selectedTimeLabel => timeRanges[_sliderValue] ?? '';

  @override
  void initState() {
    super.initState();

    // Initialize icon animation controller
    _iconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _iconOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconAnimationController,
        curve: Curves.easeOut,
      ),
    );
    
    // Initialize particle effect controller
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    // Create controllers for background effects (5 icons per option for more visual impact)
    for (int i = 0; i < 5; i++) {
      _backgroundEffectControllers.add(
        AnimationController(
          vsync: this,
          duration: Duration(milliseconds: 1200 + (i * 300)),
        )
      );
    }
  }

  @override
  void dispose() {
    _iconAnimationController.dispose();
    _particleController.dispose();
    for (final controller in _backgroundEffectControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _nextStep() {
    HapticFeedback.mediumImpact();

    if (step == 0 && level == null){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a level'),
          backgroundColor: Color(0xFFA90015),
          duration: Duration(milliseconds: 600),
        ),
      );
    } else if (step == 1 && goal == null){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a goal'),
          backgroundColor: Color(0xFFA90015),
          duration: Duration(milliseconds: 600),
        ),
      );
    } else if (step == 2 && !selectedDays.contains(true)){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select at least one day"),
          backgroundColor: Color(0xFFA90015),
          duration: Duration(milliseconds: 600),
        ),
      );
    } else {
      setState(() {
      if (step < 3) {
        step++;
      } else {
        _submit();
      }
    });
    }
  }

  void _submit() async {
    if (level != null && goal != null && _selectedTimeLabel.isNotEmpty && selectedDays.contains(true)) {
      try {

        // Generar la rutina
        final routine = await generateRoutine(
          level: level!,
          goal: goal!,
          sliderValue: _sliderValue,
          selectedDays: selectedDays,
        );
        
        // Guardar la rutina usando el método simplificado
        await RoutineSaver.saveRoutineFromMarketplace(routine);

        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("¡Rutina guardada con éxito!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Navegar hacia atrás después de guardar la rutina
        Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomePage(initialPageIndex: 1),
                      ),
                    );
      } catch (e) {
        // Ocultar indicador de carga en caso de error
        
        // Mostrar mensaje de error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al guardar la rutina: ${e.toString()}"),
            backgroundColor: Color(0xFFA90015),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Mostrar mensaje de error si faltan campos
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor completa todos los campos requeridos."),
          backgroundColor: Color(0xFFA90015),
          duration: Duration(milliseconds: 600),
        ),
      );
    }
  }

  void _toggleDay(int index) {
    setState(() {
      selectedDays[index] = !selectedDays[index];
    });
    print("Días seleccionados: $selectedDays");
  }

  void _selectLevel(String option) {
    HapticFeedback.lightImpact();
    setState(() {
      level = option;
      _triggerIconAnimation();
      _triggerBackgroundAnimations();
      print("Nivel de expertise: $level");
    });
    
  }

  void _selectGoal(String option) {
    HapticFeedback.lightImpact();
    setState(() {
      goal = option;
      _triggerIconAnimation();
      _triggerBackgroundAnimations();
      print("Objetivo: $goal");
    });
    
  }

  void _triggerIconAnimation() {
    _iconAnimationController.reset();
    _iconAnimationController.forward();
  }

  void _triggerBackgroundAnimations() {
    for (var controller in _backgroundEffectControllers) {
      controller.reset();
      controller.forward();
    }
  }
  

  List<Widget> _buildBackgroundIcons(String selectedOption, bool isLevel) {
    if ((isLevel && level == null) || (!isLevel && goal == null)) {
      return [];
    }

    final IconData mainIcon =
        isLevel ? levelIcons[selectedOption]! : goalIcons[selectedOption]!;
    final Color effectColor = isLevel ? levelColors[selectedOption]! : goalColors[selectedOption]!;

    return List.generate(5, (index) {
      return AnimatedBuilder(
        animation: _backgroundEffectControllers[index],
        builder: (context, child) {
          final value = _backgroundEffectControllers[index].value;

          // Create more dynamic movement for the background icons
          double top = 20.0 + (index * 40) + (value * 60) * math.sin(value * 3);
          double right = 10.0 + (index * 15) + (value * 30) * math.cos(value * 2);

          double opacity = (0.8 - (value * 0.6)).clamp(0.0, 1.0);
          double size = 24.0 - (index * 2);
          double rotation = value * math.pi * 2;

          return Positioned(
            top: top,
            right: right,
            child: Transform.rotate(
              angle: rotation,
              child: Opacity(
                opacity: opacity,
                child: Icon(
                  mainIcon,
                  color: effectColor.withOpacity(0.4),
                  size: size,
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildLevelOption(String option) {
    final isSelected = level == option;
    final optionColor = levelColors[option]!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: () => _selectLevel(option),
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: isSelected ? optionColor : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isSelected 
                        ? optionColor.withOpacity(0.2)
                        : Colors.black12,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Colors.white.withOpacity(0.3)
                              : optionColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          levelIcons[option],
                          color: isSelected ? Colors.white : optionColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        option,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  if (isSelected)
                    AnimatedBuilder(
                      animation: _iconAnimationController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _iconOpacityAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              color: optionColor,
                              size: 20,
                            ),
                          ),
                        );
                      },
                    )
                  else
                    const SizedBox(),
                ],
              ),
            ),
            if (isSelected) ..._buildBackgroundIcons(option, true),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalOption(String option) {
    final isSelected = goal == option;
    final optionColor = goalColors[option]!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: () => _selectGoal(option),
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: isSelected ? optionColor : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isSelected 
                        ? optionColor.withOpacity(0.2)
                        : Colors.black12,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Colors.white.withOpacity(0.3)
                              : optionColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          goalIcons[option],
                          color: isSelected ? Colors.white : optionColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        option,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  if (isSelected)
                    AnimatedBuilder(
                      animation: _iconAnimationController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _iconOpacityAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              color: optionColor,
                              size: 20,
                            ),
                          ),
                        );
                      },
                    )
                  else
                    const SizedBox(),
                ],
              ),
            ),
            if (isSelected) ..._buildBackgroundIcons(option, false),
          ],
        ),
      ),
    );
  }
  

  Widget _buildStepContent() {
    // Use the fixed accent color for consistent styling
    const Color accentColor = Color(0xFFA90015);
    
    switch (step) {
      case 0:
        return Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What is your gym level?',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),
                ...['Beginner', 'Intermediate', 'Expert']
                    .map((option) => _buildLevelOption(option)),
              ],
            ),
          ],
        );
      case 1:
        return Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What is your goal?',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),
                ...['Improve physique', 'Increase strength', 'Improve health']
                    .map((option) => _buildGoalOption(option)),
              ],
            ),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How much time do you want to train?',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: accentColor, width: 2),
                ),
                child: Text(
                  _selectedTimeLabel,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: accentColor, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 8,
                activeTrackColor: accentColor,
                inactiveTrackColor: accentColor.withOpacity(0.2),
                thumbColor: Colors.white,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                overlayColor: accentColor.withOpacity(0.1),
              ),
              child: Slider(
                value: _sliderValue,
                min: 1,
                max: 5,
                divisions: 4,
                onChanged: (value) {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _sliderValue = value.roundToDouble();
                    print("Valor tiempo: ${timeRanges[_sliderValue]}");
                  });
                },
              ),
            ),
            const SizedBox(height: 30),
            // Show icons based on slider value (approximated to time)
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < (_sliderValue).ceil().clamp(1, 5); i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          [
                            Icons.fitness_center,
                            Icons.directions_run,
                            Icons.sports_gymnastics,
                            Icons.timer,
                            Icons.emoji_events,
                          ][i % 5],
                          color: accentColor,
                          size: 24,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      case 2:
        return WeekdaysSelector(weekdaysShort: weekdaysShort, selectedDays: selectedDays, onToggleDay: _toggleDay);
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use fixed accent color for buttons
    const Color accentColor = Color(0xFFA90015);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text('Tell us about yourself'),
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Step indicator
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: index == step ? 30 : 10,
                      height: 10,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: index == step
                            ? accentColor
                            : (index < step
                                ? accentColor.withOpacity(0.5)
                                : Colors.grey.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    );
                  }),
                ),
              ),

              // Main content
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildStepContent(),
                ),
              ),

              const SizedBox(height: 24),

              // Next button
              FilledButton(
                onPressed: _nextStep,
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      step < 3 ? 'Next' : 'Generate Routine',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      step < 3 
                          ? Icons.arrow_forward
                          : Icons.fitness_center,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WeekdaysSelector extends StatefulWidget {
  final List<String> weekdaysShort;
  final List<bool> selectedDays;
  final Function(int) onToggleDay;

  const WeekdaysSelector({
    super.key,
    required this.weekdaysShort,
    required this.selectedDays,
    required this.onToggleDay,
  });

  @override
  State<WeekdaysSelector> createState() => _WeekdaysSelectorState();
}

class _WeekdaysSelectorState extends State<WeekdaysSelector>
    with TickerProviderStateMixin {
  late AnimationController _containerController;
  late Animation<double> _containerOpacity;
  final List<AnimationController> _dayControllers = [];
  final List<Animation<double>> _dayScaleAnimations = [];

  @override
  void initState() {
    super.initState();

    // Main container animation
    _containerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _containerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _containerController,
        curve: Curves.easeIn,
      ),
    );

    // Initialize animations for each day
    for (int i = 0; i < widget.weekdaysShort.length; i++) {
      final dayController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      );

      final dayScale = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(
          parent: dayController,
          curve: Curves.easeOutBack,
        ),
      );

      _dayControllers.add(dayController);
      _dayScaleAnimations.add(dayScale);

      // Stagger the animations
      Future.delayed(Duration(milliseconds: 100 + (i * 50)), () {
        if (mounted) dayController.forward();
      });
    }

    _containerController.forward();
  }

  @override
  void dispose() {
    _containerController.dispose();
    for (final controller in _dayControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleDayTap(int index) {
    HapticFeedback.lightImpact();
    widget.onToggleDay(index);

    // Play animation when toggling
    _dayControllers[index].reset();
    _dayControllers[index].forward();
  }

  @override
  Widget build(BuildContext context) {
    const Color accentColor = Color(0xFFA90015);
    const Color unselectedColor = Color(0xFFF5F5F5);
    const Color textColor = Color(0xFF424242);
    const Color selectedTextColor = Colors.white;

    return AnimatedBuilder(
      animation: _containerController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _containerOpacity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
                child: Text(
                  'Select your training days',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14), // Ligeramente aumentado el padding
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Days selection row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: List.generate(widget.weekdaysShort.length, (index) {
                          final isSelected = widget.selectedDays[index];

                          return Padding(
                            padding: EdgeInsets.only(
                              right: index < widget.weekdaysShort.length - 1 ? 10.0 : 0, // Ligeramente aumentado el padding derecho
                            ),
                            child: AnimatedBuilder(
                              animation: _dayControllers[index],
                              builder: (context, child) {
                                return GestureDetector(
                                  onTap: () => _handleDayTap(index),
                                  child: Transform.scale(
                                    scale: _dayScaleAnimations[index].value,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 40, // Ligeramente aumentado el ancho del círculo
                                      height: 40, // Ligeramente aumentado la altura del círculo
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected ? accentColor : unselectedColor,
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: accentColor.withOpacity(0.3),
                                                  blurRadius: 7, // Ligeramente aumentado el blur del shadow
                                                  offset: const Offset(0, 2),
                                                )
                                              ]
                                            : null,
                                      ),
                                      child: Center(
                                        child: Text(
                                          widget.weekdaysShort[index],
                                          style: TextStyle(
                                            color: isSelected ? selectedTextColor : textColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14, // Ligeramente aumentado el tamaño de la fuente
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }),
                      ),
                    ),

                    // Selected days summary
                    Padding(
                      padding: const EdgeInsets.only(top: 14, left: 4), // Ligeramente aumentado el padding superior
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                        child: Text(
                          _getSelectedDaysText(),
                          key: ValueKey<String>(_getSelectedDaysText()),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.black54,
                                height: 1.2,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getSelectedDaysText() {
    final selectedCount = widget.selectedDays.where((day) => day).length;

    if (selectedCount == 0) return 'No days selected';
    if (selectedCount == 7) return 'Every day';

    final fullDayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final selectedDayNames = <String>[];

    for (int i = 0; i < widget.selectedDays.length; i++) {
      if (widget.selectedDays[i]) {
        selectedDayNames.add(fullDayNames[i]);
      }
    }

    if (selectedCount == 5 &&
        !widget.selectedDays[5] && !widget.selectedDays[6]) return 'Weekdays';
    if (selectedCount == 2 &&
        widget.selectedDays[5] && widget.selectedDays[6]) return 'Weekends';

    // For better handling of long text
    if (selectedCount > 3) {
      return '$selectedCount days: ${selectedDayNames.first}, ${selectedDayNames[1]}...';
    }

    return selectedDayNames.join(', ');
  }
}