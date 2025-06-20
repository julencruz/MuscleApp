import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:muscle_app/backend/get_active_routine.dart';
import 'package:muscle_app/backend/save_stats.dart';
import 'package:muscle_app/frontend/editProfile.dart';
import 'package:muscle_app/frontend/achievementLibrary.dart';
import 'package:muscle_app/theme/app_colors.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _showExercise = true;
  String _searchQuery = '';
  String _selectedExerciseId = '1';
  final List<String> userData = ['Username', 'None'];
  int DPW = 0;
  dynamic activeRoutine = {};
  Map<String, Map<String, dynamic>> exerciseData = {};
  List<double> proportionData = [];
  final List<String> muscleGroups = ['Push', 'Pull', 'Core', 'Legs'];
  final List<Color> muscleColors = [
    const Color(0xFFD32F2F),
    const Color(0xFF1976D2),
    const Color(0xFF388E3C),
    const Color(0xFFF57C00),
  ];
  final _accentColor = redColor;
  final _backgroundColor = backgroundColor;
  final _cardColor = cardColor;
  final _textColor = textColor;
  final _secondaryTextColor = hintColor;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _loadUserName(user.uid);
      await _loadActiveRoutine();
      final exerciseStats = await StatsSaver.fetchExerciseStats(user.uid);
      final propData = await StatsSaver.fetchProportionData(user.uid);

      setState(() {
        exerciseData = exerciseStats;
        if (!exerciseData.containsKey(_selectedExerciseId) && exerciseData.isNotEmpty) {
          _selectedExerciseId = exerciseData.keys.first;
        }
        if (activeRoutine != null) {
          DPW = activeRoutine['amount'] ?? 0;
          userData[1] = activeRoutine['rName']?.toString() ?? 'None';
        }
        proportionData = propData;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserName(String userId) async {
    final document = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (document.exists) {
      final userData = document.data() as Map<String, dynamic>;
      if (userData.containsKey('nombre')) {
        this.userData[0] = userData['nombre'];
      }
    }
  }

  Future<void> _loadActiveRoutine() async {
    try {
      activeRoutine = await ActiveRoutine.getActiveRoutine();
      setState(() {
        if (activeRoutine == null || activeRoutine.isEmpty) {
          userData[1] = 'None';
          DPW = 0;
          return;
        }
        final routineName = activeRoutine['rName']?.toString() ?? '';
        userData[1] = routineName.isEmpty ? 'Unnamed Routine' : routineName;
        DPW = activeRoutine['amount'] ?? 0;
      });
    } catch (e) {
      setState(() {
        userData[1] = 'None';
        DPW = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        surfaceTintColor: Colors.transparent,
        backgroundColor: appBarBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'My Profile',
          style: TextStyle(
            color: _textColor,
          ),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.settings, color: _textColor),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: const EditProfileDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileCard(),
            const SizedBox(height: 16),
            _buildRoutineCard(),
            const SizedBox(height: 16),
            _buildToggleButtons(),
            const SizedBox(height: 16),
            _buildChartContainer(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accentColor.withOpacity(0.1),
            ),
            child: Icon(Icons.person, color: _accentColor, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userData[0],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: _textColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(12)
              ),
              child:
                  const Icon(Icons.emoji_events, color: Colors.white, size: 24),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => AchievementLibraryScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineCard() {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildRoutineStat(
              'fitness-center', 
              'ROUTINE', 
              userData[1].length > 15 ? userData[1].substring(0, 15) : userData[1]
            ),
            VerticalDivider(
              color: dividerColor,
              thickness: 1,
              indent: 8,
              endIndent: 8,
            ),
            _buildRoutineStat('calendar-today', 'DAYS/WEEK', DPW.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineStat(String icon, String title, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon == 'fitness-center' ? Icons.fitness_center_rounded : Icons.calendar_today_rounded,
            color: _accentColor, size: 22),
        const SizedBox(height: 12),
        Text(title,
            style: TextStyle(
                color: _secondaryTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _textColor)),
      ],
    );
  }

  Widget _buildToggleButtons() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _showExercise = true),
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              child: Container(
                decoration: BoxDecoration(
                  color: _showExercise ? _accentColor : Colors.transparent,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                ),
                child: Center(
                  child: Text(
                    'Exercise',
                    style: TextStyle(
                      color: _showExercise ? Colors.white : _textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _showExercise = false),
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
              child: Container(
                decoration: BoxDecoration(
                  color: !_showExercise ? _accentColor : Colors.transparent,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                ),
                child: Center(
                  child: Text(
                    'Proportion',
                    style: TextStyle(
                      color: !_showExercise ? Colors.white : _textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartContainer() {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_showExercise) _buildExerciseChart(),
          if (!_showExercise) _buildProportionChart(),
        ],
      ),
    );
  }

  List<String> _getFilteredExerciseIds() {
    return _searchQuery.isEmpty 
      ? exerciseData.keys.toList()
      : exerciseData.keys.where((id) => exerciseData[id]!['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  Widget _buildExerciseChart() {
    final filteredExerciseIds = _getFilteredExerciseIds();

    if (!filteredExerciseIds.contains(_selectedExerciseId) && filteredExerciseIds.isNotEmpty) {
      _selectedExerciseId = filteredExerciseIds.first;
    }

    final selectedExercise = exerciseData[_selectedExerciseId];
    final weightEntries = selectedExercise != null
        ? List<Map<String, dynamic>>.from(selectedExercise['weights'] as List)
        : <Map<String, dynamic>>[];

    final pr = selectedExercise != null ? (selectedExercise['pr'] as double) : 0.0;

    List<FlSpot> spots = [];
    List<String> dateLabels = [];

    if (weightEntries.isNotEmpty) {
      final firstDate = (weightEntries.first['date'] as Timestamp).toDate();
      Map<int, int> countByDay = {};

      for (final entry in weightEntries) {
        final weight = entry['weight'] as double;
        final date = (entry['date'] as Timestamp).toDate();
        final daysDiff = date.difference(firstDate).inDays;

        final count = countByDay.update(daysDiff, (c) => c + 1, ifAbsent: () => 0);
        final offset = count * 0.1;

        spots.add(FlSpot(daysDiff + offset, weight));
        dateLabels.add('${date.day}/${date.month}');
      }
    }

    double maxValue = spots.isEmpty ? pr : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    maxValue = maxValue < pr ? pr : maxValue;

    double intervalY = (maxValue / 5).ceilToDouble();
    double maxY = (maxValue * 1.1).clamp(maxValue + 1, maxValue + 10);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: _secondaryTextColor),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search exercise',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: _secondaryTextColor),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
            ],
          ),
        ),

        if (filteredExerciseIds.isNotEmpty)
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: filteredExerciseIds.length,
              itemBuilder: (context, index) {
                final id = filteredExerciseIds[index];
                final exercise = exerciseData[id]!;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      exercise['name'] as String,
                      style: TextStyle(
                        color: _selectedExerciseId == id ? contraryTextColor : _textColor,
                        fontSize: 12,
                      ),
                    ),
                    selected: _selectedExerciseId == id,
                    onSelected: (selected) => setState(() => _selectedExerciseId = id),
                    selectedColor: _accentColor,
                    backgroundColor: _backgroundColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                );
              },
            ),
          ),

        const SizedBox(height: 16),

        if (selectedExercise != null)
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        int index = spots.indexWhere((spot) => spot.x == value);
                        if (index != -1 && index < dateLabels.length) {
                          return Text(
                            dateLabels[index],
                            style: TextStyle(fontSize: 10, color: _secondaryTextColor),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: intervalY,
                      getTitlesWidget: (value, _) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          '${value.toInt()}',
                          style: TextStyle(fontSize: 10, color: _secondaryTextColor),
                        ),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: _secondaryTextColor.withOpacity(0.2), width: 1),
                    left: BorderSide(color: _secondaryTextColor.withOpacity(0.2), width: 1),
                  ),
                ),
                minX: 0,
                maxX: spots.isNotEmpty ? spots.map((e) => e.x).reduce((a, b) => a > b ? a : b) + 0.5 : 1,
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: false,
                    barWidth: 3,
                    color: _accentColor,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: _accentColor.withOpacity(0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        int index = spots.indexWhere((s) => s.x == spot.x);
                        final label = (index >= 0 && index < dateLabels.length) ? dateLabels[index] : '';
                        return LineTooltipItem(
                          '$label\n${spot.y.toStringAsFixed(1)} kg',
                          TextStyle(color: contraryTextColor, fontSize: 12),
                        );
                      }).toList();
                    },
                  ),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: pr,
                      color: _accentColor,
                      strokeWidth: 2,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 5, bottom: 5),
                        style: TextStyle(
                          color: _accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        labelResolver: (_) => 'PR: $pr',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 300,
            child: Center(
              child: Text(
                'No exercise selected',
                style: TextStyle(color: _secondaryTextColor),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProportionChart() {
    if (proportionData.isEmpty || proportionData.every((v) => v == 0.0)) {
      return Center(child: Text("No proportion data available", style: TextStyle(color: _secondaryTextColor)));
    }

    final double total = proportionData.fold(0.0, (a, b) => a + b);
    final screenWidth = MediaQuery.of(context).size.width;
    final chartSize = screenWidth * 0.4;

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.only(top: 20, bottom: 8),
            width: double.infinity,
            child: Text(
              'Muscle Group Distribution',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textColor),
            ),
          ),
          
          const SizedBox(height: 25),
          
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            height: chartSize,
            width: chartSize,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: chartSize * 0.2,
                sectionsSpace: 2,
                sections: List.generate(proportionData.length, (i) {
                  final val = proportionData[i];
                  final pct = total > 0
                      ? (val / total * 100).toStringAsFixed(1)
                      : '0.0';
                  return PieChartSectionData(
                    color: muscleColors[i],
                    value: val,
                    title: '$pct%',
                    radius: chartSize * 0.4,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }),
              ),
            ),
          ),
          
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: failedColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: List.generate(muscleGroups.length, (i) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12, 
                      height: 12, 
                      decoration: BoxDecoration(
                        color: muscleColors[i],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      muscleGroups[i], 
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _textColor,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}