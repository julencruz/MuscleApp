import 'package:flutter/material.dart';
import 'package:muscle_app/backend/achievement_manager.dart';
import 'package:muscle_app/backend/get_routines.dart';
import 'package:muscle_app/backend/marketplace_service.dart';
import 'package:muscle_app/backend/routine_notifs.dart';
import 'package:muscle_app/backend/routine_saver.dart';
import 'package:muscle_app/frontend/cuestionarioRutina.dart';
import 'package:muscle_app/frontend/home.dart';
import 'package:muscle_app/frontend/viewRoutine.dart';
import 'package:muscle_app/frontend/edit.dart';
import 'package:muscle_app/backend/save_active_routine.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> routines = [];
  int? activeRoutineIndex;
  late Future<void> _routinesFuture;

  @override
  bool get wantKeepAlive => true; // Prevents state loss during navigation

  void setActiveRoutine(int index) {
    clearSharedPreferences();
    SaveActiveRoutine.updateActiveRoutine(index, routines);
    
    // Schedule notifications for the new active routine
    RoutineNotificationManager.scheduleRoutineNotifications(routines[index]);
    
    setState(() {
      activeRoutineIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _routinesFuture = loadRoutines();
  }

  Future<void> loadRoutines() async {
    try {
      final fetchedRoutines = await RoutineService.getUserRoutines();
      if (!mounted) return;
      setState(() {
        routines = fetchedRoutines;
      });
      loadActiveRoutineIndex();
    } catch (e) {
      print('Error al cargar rutinas: $e');
      if (!mounted) return;
      setState(() {
        routines = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar rutinas')),
        );
      }
    }
  }

  void loadActiveRoutineIndex() {
    int? index;
    for (int i = 0; i < routines.length; i++){
      if (routines[i]['isActive'] == true){
        index = i;
      }
    } 
    if (!mounted) return;
    setState(() {
      activeRoutineIndex = index;
    });
  }

  void _handleEdit(routine) {
    clearSharedPreferences();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditScreen(
          routine: routine,
          allRoutines: routines,
        ),
      ),
    ).then((updatedRoutine) {
      if (updatedRoutine != null && mounted) {
        setState(() {
          routines = updatedRoutine;
          loadActiveRoutineIndex();
        });
      } 
    });
  }

  void _handleDelete(index) async {
    clearSharedPreferences();
    var updatedRoutines = await RoutineSaver.removeRoutine(routines, index);
    if (!mounted) return;
    setState(() {
      routines = updatedRoutines;
      loadActiveRoutineIndex();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deleted routine')),
    );
  }

  Future<void> clearSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); 
    print('Todo ha sido borrado de SharedPreferences');
  }

  Widget _buildNoRoutinesView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, size: 64, color: Color(0xFFA90015)),
            const SizedBox(height: 20),
            const Text(
              "No routines yet!",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              "It looks like you haven't created or added any routines. Let's fix that!",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RoutineQuestionnaire()),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFA90015),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.auto_awesome),
              label: const Text(
                'Give me a personalized routine',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomePage(initialPageIndex: 3),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.storefront),
              label: const Text(
                'Search in the marketplace',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomePage(initialPageIndex: 2),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFA90015),
                side: const BorderSide(color: Color(0xFFA90015), width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.edit_note),
              label: const Text(
                'Create one from scratch',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutinesList() {
    return ListView.builder(
      itemCount: routines.length,
      itemBuilder: (context, index) {
        final routine = routines[index];
        return _RoutineCard(
          handleEdit: () => _handleEdit(routine),
          handleDelete: () => _handleDelete(index),
          routine: routine,
          routines: routines,
          title: routine['rName']?.toString().isEmpty == true
              ? 'Unnamed Routine'
              : routine['rName'],
          daysCount: (routine['days'] as List<dynamic>?)
                  ?.where((day) =>
                      day is Map<String, dynamic> &&
                      (day['exercises'] as List?)?.isNotEmpty == true)
                  .length ??
              0,
          isActive: activeRoutineIndex == index,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewRoutine(routine: routine),
              ),
            );
          },
          onActiveChanged: () => setActiveRoutine(index),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.grey.withOpacity(0.1),
        title: const Text('My Routines', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder(
          future: _routinesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFA90015)),
              );
            } 
            
            // Once data is loaded
            return routines.isEmpty 
                ? _buildNoRoutinesView()
                : _buildRoutinesList();
          },
        ),
      ),
    );
  }
}

// ignore: must_be_immutable
class _RoutineCard extends StatefulWidget {
  final String title;
  final int daysCount;
  final Map<String, dynamic> routine;
  final VoidCallback onTap;
  final bool isActive;
  final VoidCallback onActiveChanged;
  final VoidCallback handleEdit;
  final VoidCallback handleDelete;
  List<Map<String, dynamic>> routines;

  _RoutineCard({
    required this.title,
    required this.daysCount,
    required this.routine,
    required this.onTap,
    required this.isActive,
    required this.handleEdit,
    required this.handleDelete,
    required this.onActiveChanged, required this.routines,
  });

  @override
  State<_RoutineCard> createState() => __RoutineCardState();
}

class __RoutineCardState extends State<_RoutineCard> {
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
  Widget build(BuildContext context) {
    final routineColor = _getRoutineColor(widget.title);
    final routineIcon = _getRoutineIcon(widget.title);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: routineColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    routineIcon,
                    color: routineColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.daysCount == 1
                            ? '1 day'
                            : '${widget.daysCount} days',
                        style: TextStyle(
                          color: routineColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: widget.onActiveChanged,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.isActive ? Color(0xFFA90015) : Colors.grey[400]!,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: widget.isActive
                          ? Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Color(0xFFA90015),
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.grey[600],
                    size: 22,
                  ),
                  onPressed: () => _showOptionsMenu(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    final accentColor = Color(0xFFA90015);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      elevation: 10,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: accentColor,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 24),
            _buildMenuItem(context, Icons.edit_outlined, "Edit", onTap: widget.handleEdit),
            _buildMenuItem(context, Icons.share_outlined, "Publish to marketplace", onTap: () => _handlePublish(widget.routine)),
            _buildMenuItem(
              context,
              Icons.share,
              "Share",
              subtitle: "Routine needs to be published on the Marketplace",
              onTap: () => _handleShare(widget.routine),
            ),
            _buildMenuItem(context, Icons.delete_outlined, "Delete", isRed: true, onTap: widget.handleDelete),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _handleShare(Map<String, dynamic> routine) {
    final String rutinaId = routine['rID']; 
    Share.share('Check out this routine on the marketplace! 💪\n$rutinaId');
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String text, {
    bool isRed = false,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    final accentColor = Color(0xFFA90015);
    final textColor = isRed ? accentColor : Colors.grey[800];
    final iconColor = isRed ? accentColor : Colors.grey[600];
    final subtitleColor = Colors.grey[500];

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.pop(context);
        if (onTap != null) onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 26),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePublish(routine) async {
    try {
      final response = await MarketplaceService.saveRoutineToMarketplace(routine: routine);
      if (response) {
        AchievementManager().unlockAchievement("share_routine");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Routine published successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to publish routine')),
        );
      }
    } catch (e) {
      // Aquí capturamos las excepciones específicas
      if (e.toString().contains('El creador de la rutina no coincide')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You can't publish a routine to the marketplace if you are not the creator!"),
          ),
        );
      } else if (e.toString().contains('La rutina no tiene nombre')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You can't publish a routine without a name!"),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to publish routine'),
          ),
        );
      }
    }
  }
}
