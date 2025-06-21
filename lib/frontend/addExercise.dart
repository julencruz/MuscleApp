import 'dart:async';
import 'package:flutter/material.dart';
import 'package:muscle_app/backend/exercise_loader.dart';
import 'package:muscle_app/backend/update_dock.dart';
import 'package:muscle_app/frontend/infoExercise.dart';
import 'package:muscle_app/theme/app_colors.dart';

class AddExerciseScreen extends StatefulWidget {
  final List<Map<String, dynamic>> recentExercises;
  const AddExerciseScreen({Key? key, required this.recentExercises}) : super(key: key);

  @override
  _AddExerciseScreenState createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends State<AddExerciseScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _debounce = Debounce(milliseconds: 300);
  
  List<Map<String, dynamic>> _selectedExercises = [];
  List<Map<String, dynamic>> _allExercises = [];
  List<Map<String, dynamic>> _visibleExercises = [];
  int _currentPage = 1;
  bool _isLoading = false;
  final int _pageSize = 50;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_scrollListener);
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadInitialData() async {
    final allExercises = await ExerciseLoader.importExercises();
    setState(() {
      _allExercises = allExercises;
      _visibleExercises = _allExercises.take(_pageSize).toList();
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.9) {
      _loadMoreExercises();
    }
  }

  void _loadMoreExercises() {
    if (_isLoading || _visibleExercises.length >= _allExercises.length) return;
    
    setState(() => _isLoading = true);
    final nextPage = _currentPage + 1;
    final startIndex = nextPage * _pageSize;
    final endIndex = startIndex + _pageSize;

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _visibleExercises.addAll(
          _allExercises.sublist(
            startIndex, 
            endIndex.clamp(0, _allExercises.length)
          )
        );
        _currentPage = nextPage;
        _isLoading = false;
      });
    });
  }

  void _onSearchChanged() {
    _debounce.run(() {
      final query = _searchController.text.toLowerCase();
      setState(() {
        _visibleExercises = _allExercises
            .where((e) => e['name'].toLowerCase().contains(query))
            .take(_pageSize)
            .toList();
        _currentPage = 1;
      });
    });
  }

  Future<void> _toggleExerciseSelection(Map<String, dynamic> exercise) async {
    bool isSelected = _selectedExercises.any((e) => e['eID'] == exercise['eID']);
    
    if (isSelected) {
      if (mounted) {
        setState(() {
          _selectedExercises.removeWhere((e) => e['eID'] == exercise['eID']);
        });
      }
    } else {
      final result = await showDialog(
        context: context,
        builder: (context) => RepsSetsDialog(exercise: exercise),
      );

      if (result != null && mounted) {
        setState(() {
          _selectedExercises.add(result);
        });
      }
    }
  }

  void _showExerciseInfo(Map<String, dynamic> exercise) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InfoExerciseScreen(
          name: exercise['name'],
          primaryMuscles: exercise['primaryMuscles'],
          secondaryMuscles: exercise['secondaryMuscles'],
          instructions: exercise['instructions'],
          images: exercise['images'],
          level: exercise['level'],
          pr: 0.0,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _buildExerciseList(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: appBarBackgroundColor,
      surfaceTintColor: Colors.transparent, 
      centerTitle: true,
      elevation: 0, 
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Add Exercises',
            style: TextStyle(color: textColor),
          ),
          if (_selectedExercises.isNotEmpty)
            Text(
              '${_selectedExercises.length} selected',
              style: TextStyle(color: redColor, fontSize: 14),
            ),
        ],
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: textColor),
        onPressed: () {
          Navigator.pop(context);
          UpdateDock.updateSystemUI(appBarBackgroundColor);
        },
      ),
      actions: [
        if (_selectedExercises.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton.icon(
              icon: Icon(Icons.check, color: redColor),
              label: Text('SAVE', style: TextStyle(color: redColor)),
              onPressed: () => Navigator.pop(context, _selectedExercises),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          filled: true,
          fillColor: cardColor,
          hintText: 'Search exercises...',
          hintStyle: TextStyle(color: hintColor),
          prefixIcon: Icon(Icons.search, color: hintColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 2),
        ),
      ),
    );
  }

  Widget _buildExerciseList() {
    UpdateDock.updateSystemUI(backgroundColor);
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _visibleExercises.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _visibleExercises.length) {
          return _buildLoadingIndicator();
        }
        return _buildExerciseItem(_visibleExercises[index]);
      },
    );
  }

  Widget _buildExerciseItem(Map<String, dynamic> exercise) {
    final isSelected = _selectedExercises.any((e) => e['eID'] == exercise['eID']);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Material(
        borderRadius: BorderRadius.circular(15),
        color: cardColor,
        elevation: 2,
        shadowColor: shadowColor,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => _toggleExerciseSelection(exercise),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                _buildExerciseIcon(exercise),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exercise['name'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor)),
                      const SizedBox(height: 4),
                      Text(exercise['bodyPart'].toString().toUpperCase(),
                          style: TextStyle(
                            color: hintColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                _buildActionIcons(exercise, isSelected),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseIcon(Map<String, dynamic> exercise) {
    final primaryMuscle = exercise['primaryMuscles'].isNotEmpty 
        ? exercise['primaryMuscles'][0]
        : 'default';
    final level = exercise['level']?.toString().toLowerCase() ?? 'beginner';

    Color getBorderColor() {
      switch (level) {
        case 'intermediate':
          return Colors.amber;
        case 'expert':
          return Colors.red;
        default:
          return Colors.green;
      }
    }

    final imageName = primaryMuscle.toLowerCase().replaceAll(' ', '_');
    final imagePath = 'assets/muscle_images/$imageName.png';

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: getBorderColor(),
          width: 2.5,
        ),
      ),
      child: ClipOval(
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.fitness_center,
            color: hintColor,
          ),
        ),
      ),
    );
  }

  Widget _buildActionIcons(Map<String, dynamic> exercise, bool isSelected) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.info_outline, color: redColor),
          onPressed: () => _showExerciseInfo(exercise),
        ),
        const SizedBox(width: 8),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isSelected ? redColor : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? redColor : dividerColor,
              width: 2),
          ),
          child: isSelected 
              ? Icon(Icons.check, color: contraryTextColor, size: 16)
              : null,
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: CircularProgressIndicator(color: redColor),
      ),
    );
  }
}

class RepsSetsDialog extends StatefulWidget {
  final Map<String, dynamic> exercise;
  
  const RepsSetsDialog({Key? key, required this.exercise}) : super(key: key);

  @override
  _RepsSetsDialogState createState() => _RepsSetsDialogState();
}

class _RepsSetsDialogState extends State<RepsSetsDialog> {
  final seriesController = TextEditingController(text: '4');
  final repsController = TextEditingController(text: '12');
  final durationController = TextEditingController(text: '30');
  
  bool useReps = true;
  String durationUnit = 'sec'; // 'sec' o 'min'

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.exercise['name'],
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor)),
            const SizedBox(height: 20),
            
            // Mode selector
            Container(
              decoration: BoxDecoration(
                color: backgroundColor,
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
                          color: useReps ? redColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Center(
                          child: Text(
                            'REPS',
                            style: TextStyle(
                              color: useReps ? Colors.white : hintColor,
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
                          color: !useReps ? redColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Center(
                          child: Text(
                            'DURATION',
                            style: TextStyle(
                              color: !useReps ? Colors.white : hintColor,
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
            
            useReps
              ? _buildInputField('Reps', repsController)
              : _buildDurationField(),
            
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: redColor,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () {
                if (useReps) {
                  Navigator.pop(context, {
                    ...widget.exercise,
                    'series': int.tryParse(seriesController.text) ?? 4,
                    'reps': int.tryParse(repsController.text) ?? 12,
                    'measurementType': 'reps',
                  });
                } else {
                  int durationValue = int.tryParse(durationController.text) ?? 30;
                  if (durationUnit == 'min') {
                    durationValue *= 60;
                  }
                  Navigator.pop(context, {
                    ...widget.exercise,
                    'series': int.tryParse(seriesController.text) ?? 4,
                    'duration': durationValue,
                    'measurementType': 'duration',
                  });
                }
              },
              child: Text('Confirm', 
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
        Text(label, style: TextStyle(fontSize: 16, color: textColor)),
        SizedBox(
          width: 120,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: textColor),
            decoration: InputDecoration(
              filled: true,
              fillColor: backgroundColor,
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

  Widget _buildDurationField() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Duration', style: TextStyle(fontSize: 16, color: textColor)),
        Container(
          width: 120,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: '30',
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
                  value: durationUnit,
                  underline: SizedBox(),
                  
                  style: TextStyle(color: hintColor, fontWeight: FontWeight.w600, fontSize: 14),
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
                        int currentValue = int.tryParse(durationController.text) ?? 0;
                        if (durationUnit == 'min' && value == 'sec') {
                          durationController.text = (currentValue * 60).toString();
                        } else if (durationUnit == 'sec' && value == 'min') {
                          durationController.text = (currentValue ~/ 60).toString();
                        }
                        durationUnit = value;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  @override
  void dispose() {
    seriesController.dispose();
    repsController.dispose();
    durationController.dispose();
    super.dispose();
  }
}

class Debounce {
  final int milliseconds;
  Timer? _timer;

  Debounce({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}