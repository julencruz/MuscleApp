import 'package:flutter/material.dart';
import 'package:muscle_app/backend/user_service.dart';
import 'package:muscle_app/frontend/viewMarketplaceRoutine.dart';
import 'package:muscle_app/backend/update_dock.dart';
import 'package:muscle_app/theme/app_colors.dart';

String capitalize(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}

class SearchRoutinePage extends StatefulWidget {
  final List<Map<String, dynamic>> routines;

  const SearchRoutinePage({
    Key? key,
    required this.routines,
  }) : super(key: key);

  @override
  State<SearchRoutinePage> createState() => _SearchRoutinePageState();
}

class _SearchRoutinePageState extends State<SearchRoutinePage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredRoutines = [];
  final Map<String, String> _creatorNames = {};

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

  @override
  void initState() {
    super.initState();
    _filteredRoutines = widget.routines;
    _loadCreatorNames();
  }

  Future<void> _loadCreatorNames() async {
    for (var routine in _filteredRoutines) {
      final creatorId = routine['creatorId']?.toString() ?? '';
      if (creatorId.isNotEmpty && !_creatorNames.containsKey(creatorId)) {
        final name = await UserService.getCreatorNameFromId(creatorId);
        if (mounted) {
          setState(() {
            _creatorNames[creatorId] = name;
          });
        }
      }
    }
  }

  Color _getRoutineColor(String name) {
    final index = name.length % _routineColors.length;
    return _routineColors[index];
  }

  IconData _getRoutineIcon(String name) {
    final index = name.length % _routineIcons.length;
    return _routineIcons[index];
  }

  void _filterRoutines(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredRoutines = widget.routines;
      } else {
        _filteredRoutines = widget.routines.where((routine) {
          final name = routine['rName'].toString().toLowerCase();
          final routineId = routine['rID'].toString().toLowerCase();
          final creatorName = _creatorNames[routine['creatorId']?.toString() ?? '']?.toLowerCase() ?? '';
          
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) || creatorName.contains(searchLower) || routineId.contains(searchLower) || routine['creatorId'].toString().contains(query);
        }).toList();
      }
      _loadCreatorNames();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        surfaceTintColor: Colors.transparent,
        backgroundColor: appBarBackgroundColor,
        shadowColor: shadowColor,
        centerTitle: true,
        elevation: 0,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: failedColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by routine or creator...',
              hintStyle: TextStyle(color: hintColor),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search, color: hintColor),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: _filterRoutines,
            autofocus: true,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () {
            Navigator.pop(context);
            UpdateDock.updateSystemUI(appBarBackgroundColor);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: _buildSearchResults(),
      ),
    );
  }

  Widget _buildSearchResults() {
    UpdateDock.updateSystemUI(backgroundColor);
    if (_filteredRoutines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: hintColor),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'Search for routines'
                  : 'No matching routines found',
              style: TextStyle(
                color: textColor2,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredRoutines.length,
      itemBuilder: (context, index) {
        final routine = _filteredRoutines[index];
        final creatorId = routine['creatorId']?.toString() ?? '';
        final creatorName = _creatorNames[creatorId] ?? 'Loading...';
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _SearchResultCard(
            routine: routine,
            color: _getRoutineColor(routine['rName']),
            icon: _getRoutineIcon(routine['rName']),
            creatorName: creatorName,
            onTap: () => _navigateToRoutine(context, routine),
          ),
        );
      },
    );
  }

  void _navigateToRoutine(BuildContext context, Map<String, dynamic> routine) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewMarketplaceRoutine(routine: routine),
      ),
    );
    if (mounted) {
      setState(() {
        _searchController.text = _searchController.text;
        _filterRoutines(_searchController.text);
      });
    }
  }
}

class _SearchResultCard extends StatelessWidget {
  final Map<String, dynamic> routine;
  final Color color;
  final IconData icon;
  final String creatorName;
  final VoidCallback onTap;

  const _SearchResultCard({
    required this.routine,
    required this.color,
    required this.icon,
    required this.creatorName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 10,
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
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routine['rName'] ?? 'Unnamed Routine',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'By $creatorName',
                      style: TextStyle(
                        color: textColor2,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(routine['days'] as List?)?.length ?? 0} days • ${capitalize((routine['level'] as String?) ?? '')}',
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, color: redColor, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          (routine['averageRating'] ?? 0.0).toStringAsFixed(1),
                          style: TextStyle(
                            color: textColor,
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
                            routine['type'] ?? '',
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