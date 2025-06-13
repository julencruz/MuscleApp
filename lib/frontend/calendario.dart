import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:muscle_app/backend/get_active_routine.dart';
import 'package:muscle_app/frontend/viewRoutine.dart';
import 'package:muscle_app/backend/update_dock.dart';

class CalendarioPage extends StatefulWidget {
  final List<DateTime> daysRegistered;
  final List<int> allowedWeekdays; // 1 = Lunes, 7 = Domingo

  const CalendarioPage({
    super.key,
    required this.daysRegistered,
    required this.allowedWeekdays,
  });

  @override
  _CalendarioPageState createState() => _CalendarioPageState();
}

class _CalendarioPageState extends State<CalendarioPage> {
  late DateTime _currentDate;
  late DateFormat _dateFormatter;
  late Map<String, dynamic> routine;

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime.now();
    
    // Inicializa el DateFormat con localización española
    _dateFormatter = DateFormat('MMMM y', 'es');

    _initializeRoutine();
    
    
  }

  Future<void> _initializeRoutine() async {
    routine = await ActiveRoutine.getActiveRoutine() ?? {};
    UpdateDock.updateSystemUI(Colors.grey[50]!);
  }

  // Obtener el primer día del mes (reemplazo para DateUtils.getFirstDayOfMonth)
  DateTime _getFirstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  // Obtener el número de días en el mes (reemplazo para DateUtils.getDaysInMonth)
  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  // Comprobar si dos fechas son el mismo día
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isRegistered(DateTime date) {
    return widget.daysRegistered.any((d) =>
        d.year == date.year && d.month == date.month && d.day == date.day);
  }

  bool _isAllowed(DateTime date) {
    return widget.allowedWeekdays.contains(date.weekday);
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.chevron_left_rounded,
              size: 32,
              color: Color(0xFFA90015),
            ),
            onPressed: () => setState(() {
              _currentDate = DateTime(_currentDate.year, _currentDate.month - 1);
            }),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFA90015).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _dateFormatter.format(_currentDate),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFA90015),
                letterSpacing: 0.5,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.chevron_right_rounded,
              size: 32,
              color: Color(0xFFA90015),
            ),
            onPressed: () => setState(() {
              _currentDate = DateTime(_currentDate.year, _currentDate.month + 1);
            }),
          ),
        ],
      ),
    );
}

// Mejora del Widget _buildWeekdaysHeader
Widget _buildWeekdaysHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: ['L', 'M', 'X', 'J', 'V', 'S', 'D'].map((day) {
          return Expanded(
            child: Text(
              day,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFA90015),
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          );
        }).toList(),
      ),
    );
}

  // En la clase _CalendarioPageState, añade esta función
String _getDayName(int weekday) {
  const Map<int, String> weekdayNames = {
    1: 'Lunes',
    2: 'Martes',
    3: 'Miércoles',
    4: 'Jueves',
    5: 'Viernes',
    6: 'Sábado',
    7: 'Domingo',
  };
  return weekdayNames[weekday] ?? '';
}

void _showDayDetails(DateTime date) {
  final bool isAllowed = _isAllowed(date);
  final bool isRegistered = _isRegistered(date);
  final String dayName = _getDayName(date.weekday);
  final bool isFutureDate = date.isAfter(DateTime.now());

    String getDayRoutineName() {
      if (routine.isEmpty || routine['days'] == null) return '';
      
      // Convertir el nombre del día de español a inglés
      final Map<String, String> dayNameToEnglish = {
        'Lunes': 'Monday',
        'Martes': 'Tuesday',
        'Miércoles': 'Wednesday',
        'Jueves': 'Thursday',
        'Viernes': 'Friday',
        'Sábado': 'Saturday',
        'Domingo': 'Sunday'
      };
      
      String englishDayName = dayNameToEnglish[dayName] ?? dayName;
      
      // Buscar el día en la rutina
      final dayData = routine['days'].firstWhere(
        (day) => day['weekDay'] == englishDayName && 
                (day['exercises'] as List).isNotEmpty,
        orElse: () => null,
      );
      
      // Si no se encontró el día o no tiene ejercicios, devolver cadena vacía
      if (dayData == null) return '';
      
      // Si se encontró el día pero no tiene nombre, devolver 'Unnamed'
      return dayData['dayName'] == "" ? "Unnamed" : dayData['dayName'];
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      final String routineName = getDayRoutineName();
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 5,
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isRegistered 
                    ? const Color(0xFFA90015)
                    : (_isSameDay(date, DateTime.now()) || date.isAfter(DateTime.now())
                        ? Colors.white
                        : (isAllowed ? Colors.grey.shade200 : Colors.white)),
                  shape: BoxShape.circle,
                  border: _isSameDay(date, DateTime.now())
                      ? Border.all(color: Colors.red, width: 3)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isRegistered 
                          ? Colors.white 
                          : Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                dayName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFA90015),
                ),
              ),
              if (routineName.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  routineName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFA90015),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                DateFormat('d MMMM y', 'es').format(date),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isRegistered 
                          ? Icons.check_circle 
                          : (isAllowed ? Icons.fitness_center : Icons.block),
                      color: isRegistered 
                          ? Colors.green 
                          : (isAllowed ? const Color(0xFFA90015) : Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isRegistered 
                          ? 'Completed training'
                          : (isAllowed 
                              ? (isFutureDate 
                                  ? 'Programmed training day'
                                  : (_isSameDay(date, DateTime.now())
                                      ? 'Today\'s training day'
                                      : 'Failed training day'))
                              : 'Rest day'),
                      style: TextStyle(
                        color: isRegistered 
                            ? Colors.green 
                            : (isAllowed ? const Color(0xFFA90015) : Colors.grey),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (routine.isNotEmpty) ...[
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewRoutine(routine: routine),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA90015),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'View Routine',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    color: Color(0xFFA90015),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  Widget _buildDay(DateTime date) {
    final bool isCurrentMonth = date.month == _currentDate.month;
    
    if (!isCurrentMonth) {
      return Container();
    }

    final bool isToday = _isSameDay(date, DateTime.now());
    final bool isAllowed = _isAllowed(date);
    final bool isRegistered = _isRegistered(date);
    final bool isFutureDate = date.isAfter(DateTime.now());

    BoxDecoration decoration;
    Color textColor;

    if (isRegistered) {
      textColor = Colors.white;
      decoration = BoxDecoration(
        color: const Color(0xFFA90015),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA90015).withOpacity(0.2),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      );
    } else if (isToday) {
      textColor = const Color(0xFFA90015);
      decoration = BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFA90015),
          width: 1.9,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA90015).withOpacity(0.08),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      );
    } else {
      textColor = Colors.black87;
      decoration = BoxDecoration(
        // Solo aplicamos el color gris si es un día permitido Y no es una fecha futura
        color: isAllowed && !isFutureDate ? Colors.grey[200] : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showDayDetails(date),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: decoration,
        child: Center(
          child: Text(
            date.day.toString(),
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  } 

  Widget _buildCalendarGrid() {
    final firstDay = _getFirstDayOfMonth(_currentDate);
    final daysInMonth = _getDaysInMonth(_currentDate.year, _currentDate.month);
    final startingWeekday = firstDay.weekday;

    final List<DateTime> dates = [];
    for (int i = 1; i < startingWeekday; i++) {
      dates.add(firstDay.subtract(Duration(days: startingWeekday - i)));
    }
    for (int i = 0; i < daysInMonth; i++) {
      dates.add(DateTime(_currentDate.year, _currentDate.month, i + 1));
    }
    while (dates.length < 42) {
      dates.add(dates.last.add(const Duration(days: 1)));
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
      ),
      itemCount: 42,
      itemBuilder: (context, index) => _buildDay(dates[index]),
    );
    
  }

  @override
Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.black87,
          ),
          onPressed: () {
            Navigator.pop(context);
            UpdateDock.updateSystemUI(Colors.white);
          },
        ),
        title: const Text(
          'Calendar',
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              _buildWeekdaysHeader(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildCalendarGrid(),
              ),
            ],
          ),
        ),
      ),
    );
}
}