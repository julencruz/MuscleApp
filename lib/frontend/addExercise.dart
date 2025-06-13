import 'dart:async';
import 'package:flutter/material.dart';
import 'package:muscle_app/backend/exercise_loader.dart';
import 'package:muscle_app/backend/update_dock.dart';
import 'package:muscle_app/frontend/infoExercise.dart';

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
    print("HOLA: $allExercises");
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
    // Check if the exercise is already selected
    bool isSelected = _selectedExercises.any((e) => e['eID'] == exercise['eID']);
    
    if (isSelected) {
      // Remove it directly
      if (mounted) {
        setState(() {
          _selectedExercises.removeWhere((e) => e['eID'] == exercise['eID']);
        });
      }
    } else {
      // Show dialog to get reps/sets
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
      backgroundColor: Colors.grey[50],
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
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent, 
      centerTitle: true,
      elevation: 0, 
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Add Exercises',
            style: TextStyle(color: Colors.black87),
          ),
          if (_selectedExercises.isNotEmpty)
            Text(
              '${_selectedExercises.length} selected',
              style: const TextStyle(color: Color(0xFFA90015) , fontSize: 14),
            ),
        ],
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () {
            Navigator.pop(context);
            UpdateDock.updateSystemUI(Colors.white);
          },
      ),
      actions: [
        if (_selectedExercises.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton.icon(
              icon: const Icon(Icons.check, color: Color(0xFFA90015) ),
              label: const Text('SAVE', 
                style: TextStyle(color: Color(0xFFA90015) )),
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
          fillColor: Colors.white,
          hintText: 'Search exercises...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
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
    UpdateDock.updateSystemUI(Colors.grey[50]!);
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
        color: Colors.white,
        elevation: 2,
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(exercise['bodyPart'].toString().toUpperCase(),
                          style: TextStyle(
                            color: Colors.grey[600],
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
    // Obtener el músculo principal y el nivel
    final primaryMuscle = exercise['primaryMuscles'].isNotEmpty 
        ? exercise['primaryMuscles'][0]
        : 'default';
    final level = exercise['level']?.toString().toLowerCase() ?? 'beginner';

    // Obtener el color del borde según el nivel
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

    // Formatear nombre de la imagen
    final imageName = primaryMuscle.toLowerCase().replaceAll(' ', '_');
    final imagePath = 'assets/muscle_images/$imageName.png';

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[200],
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
            color: Colors.grey[600],
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
          icon: const Icon(Icons.info_outline, color: Color(0xFFA90015) ),
          onPressed: () => _showExerciseInfo(exercise),
        ),
        const SizedBox(width: 8),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFFA90015) : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Color(0xFFA90015) : Colors.grey,
              width: 2),
          ),
          child: isSelected 
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : null,
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: CircularProgressIndicator(color: Color(0xFFA90015)),
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
  
  // Track if we're using reps (true) or duration (false)
  bool useReps = true;
  
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
            
            // Mode selector
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
            
            // Dynamically show reps or duration based on selection
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
                if (useReps) {
                  Navigator.pop(context, {
                    ...widget.exercise,
                    'series': int.tryParse(seriesController.text) ?? 4,
                    'reps': int.tryParse(repsController.text) ?? 12,
                    'measurementType': 'reps',
                  });
                } else {
                  Navigator.pop(context, {
                    ...widget.exercise,
                    'series': int.tryParse(seriesController.text) ?? 4,
                    'duration': int.tryParse(durationController.text) ?? 30,
                    'measurementType': 'duration',
                  });
                }
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