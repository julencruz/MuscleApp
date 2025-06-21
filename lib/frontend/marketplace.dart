import 'package:flutter/material.dart';
import 'package:muscle_app/backend/marketplace_service.dart';
import 'package:muscle_app/frontend/viewMarketplaceRoutine.dart';
import 'package:muscle_app/frontend/searchRoutine.dart';
import 'package:muscle_app/theme/app_colors.dart';

enum DifficultyLevel { beginner, intermediate, expert }

enum RoutineType { 
  fullBody,
  upperBody,
  lowerBody,
  pushPullLegs,
  upperLower,
  bodyPart,
  cardio
}

extension RoutineTypeExtension on RoutineType {
  String get displayName {
    switch (this) {
      case RoutineType.fullBody:
        return 'FULL BODY';
      case RoutineType.upperBody:
        return 'UPPER BODY';
      case RoutineType.lowerBody:
        return 'LOWER BODY';
      case RoutineType.pushPullLegs:
        return 'PUSH PULL LEGS';
      case RoutineType.upperLower:
        return 'UPPER/LOWER';
      case RoutineType.bodyPart:
        return 'BODY PART SPLIT';
      case RoutineType.cardio:
        return 'CARDIO';
    }
  }
}

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  DifficultyLevel? _selectedDifficulty;
  List<Map<String, dynamic>> _routines = [];
  bool _isLoading = true;
  final Map<RoutineType, bool> _categoryVisibility = {};

  final List<Color> _routineColors = [
    Colors.red[400]!,
    Colors.blue[600]!,
    Colors.green[700]!,
    Colors.orange[600]!,
    Colors.indigo[600]!,
    Colors.teal[600]!,
    Colors.deepPurple[600]!,
  ];

  final List<IconData> _routineIcons = [
    Icons.fitness_center,
    Icons.directions_run,
    Icons.sports_mma,
    Icons.sports_handball,
    Icons.sports_baseball,
    Icons.sports_basketball,
    Icons.sports_football,
  ];

  Color _getRoutineColor(String name) {
    final index = name.length % _routineColors.length;
    return _routineColors[index];
  }

  IconData _getRoutineIcon(String name) {
    final index = name.length % _routineIcons.length;
    return _routineIcons[index];
  }

  @override
  void initState() {
    super.initState();
    _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    try {
      final routines = await MarketplaceService.getMarketplaceRoutines();
      setState(() {
        _routines = routines;
        for (var type in RoutineType.values) {
          _categoryVisibility[type] = _hasRoutinesForType(type.displayName);
        }
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading routines: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _hasRoutinesForType(String type) {
    if (_selectedDifficulty == null) {
      return _routines.any((routine) => routine['type'] == type);
    }
    return _routines.any((routine) => 
      routine['type'] == type && 
      routine['level'] == _selectedDifficulty!.name
    );
  }

  List<Map<String, dynamic>> _getFilteredRoutines(String type) {
    if (_selectedDifficulty == null) {
      return _routines.where((routine) => routine['type'] == type).toList();
    }
    return _routines.where((routine) => 
      routine['type'] == type && 
      routine['level'] == _selectedDifficulty!.name
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: redColor,
          )
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        surfaceTintColor: Colors.transparent,
        backgroundColor: appBarBackgroundColor,
        elevation: 0,
        shadowColor: shadowColor,
        centerTitle: true,
        title: Text(
          'Marketplace',
          style: TextStyle(
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: textColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchRoutinePage(
                    routines: _routines,
                  ),
                ),
              );
            },
          )
        ]
      ),
      body: RefreshIndicator(
        color: redColor,
        onRefresh: _loadRoutines,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
              sliver: SliverToBoxAdapter(
                child: _buildDifficultySelector(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final type = RoutineType.values[index];
                    if (!_categoryVisibility[type]!) return const SizedBox.shrink();
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: _buildRoutineSection(type),
                    );
                  },
                  childCount: RoutineType.values.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSegmentTextColor(DifficultyLevel level) {
    return _selectedDifficulty == level ? Colors.white : textColor;
  }

  Widget _buildDifficultySelector() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SegmentedButton<DifficultyLevel?>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment<DifficultyLevel?>(
            value: DifficultyLevel.beginner,
            label: Text('Beginner', style: TextStyle(color: _getSegmentTextColor(DifficultyLevel.beginner))),
            icon: Icon(Icons.arrow_circle_up, size: 18, color: _getSegmentTextColor(DifficultyLevel.beginner)),
          ),
          ButtonSegment<DifficultyLevel?>(
            value: DifficultyLevel.intermediate,
            label: Text('Average', style: TextStyle(color: _getSegmentTextColor(DifficultyLevel.intermediate))),
            icon: Icon(Icons.trending_up, size: 18, color: _getSegmentTextColor(DifficultyLevel.intermediate)),
          ),
          ButtonSegment<DifficultyLevel?>(
            value: DifficultyLevel.expert,
            label: Text('Expert', style: TextStyle(color: _getSegmentTextColor(DifficultyLevel.expert))),
            icon: Icon(Icons.star, size: 18, color: _getSegmentTextColor(DifficultyLevel.expert)),
          ),
        ],
        selected: _selectedDifficulty != null ? {_selectedDifficulty!} : {},
        onSelectionChanged: (Set<DifficultyLevel?> newSelection) {
          setState(() {
            _selectedDifficulty = newSelection.isEmpty || newSelection.first == _selectedDifficulty 
              ? null 
              : newSelection.first;
            
            for (var type in RoutineType.values) {
              _categoryVisibility[type] = _hasRoutinesForType(type.displayName);
            }
          });
        },
        style: SegmentedButton.styleFrom(
          backgroundColor: cardColor,
          selectedBackgroundColor: redColor,
          foregroundColor: redColor,
          selectedForegroundColor: contraryTextColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          visualDensity: VisualDensity.compact,
        ),
        emptySelectionAllowed: true,
      ),
    );
  }

  Widget _buildRoutineSection(RoutineType type) {
    final routines = _getFilteredRoutines(type.displayName);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(
            type.displayName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...routines.map((routine) => 
          _WorkoutCard(
            title: routine['rName'] ?? 'Unnamed Routine',
            subtitle: '${routine['days']?.length ?? 0} days',
            rating: ((routine["averageRating"] * 100).truncate() / 100) ?? 0.0,
            icon: _getRoutineIcon(routine['rName'] ?? ''),
            color: _getRoutineColor(routine['rName'] ?? ''),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewMarketplaceRoutine(routine: routine),
                ),
              );
              setState(() {
                _isLoading = true;
              });
              await _loadRoutines();
              setState(() {
                _isLoading = false;
              });
            }
          ),
        ),
      ],
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double rating;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _WorkoutCard({
    required this.title,
    required this.subtitle,
    required this.rating,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, color: redColor, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          rating.toString(),
                          style: TextStyle(
                            color: hintColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: redColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'View routine',
                            style: TextStyle(
                              color: redColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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