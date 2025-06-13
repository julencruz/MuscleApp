import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'create.dart';
import 'workout.dart';
import 'library.dart';
import 'marketplace.dart';
import 'profile.dart';

class HomePage extends StatefulWidget {
  final int initialPageIndex;

  const HomePage({super.key, this.initialPageIndex = 0});

  @override
  State<HomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late int currentPageIndex;
  late AnimationController _controller;

@override
void initState() {
    super.initState();
    currentPageIndex = widget.initialPageIndex;

    // Configura el modo inmersivo para eliminar la barra de gestos
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge, overlays: [SystemUiOverlay.bottom]);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 125),
      lowerBound: 0.93,
      upperBound: 1.0,
    );
  }

@override
void dispose() {
  _controller.dispose();
  super.dispose();
}

 @override
Widget build(BuildContext context) {
  return Scaffold(
    resizeToAvoidBottomInset: true,
    bottomNavigationBar: Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: BottomAppBar(
        height: 75,
        padding: EdgeInsets.zero,
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  _buildNavItem(Icons.fitness_center_outlined, Icons.fitness_center, 0),
                  _buildNavItem(Icons.format_list_bulleted_outlined, Icons.format_list_bulleted, 1),
                ],
              ),
            ),
            Container(
              width: 70,
              height: 70,
              padding: const EdgeInsets.all(5),
              child: ScaleTransition(
                scale: _controller,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFA90015),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      await _controller.reverse();
                      await _controller.forward();
                      setState(() {
                        currentPageIndex = 2;
                      });
                    },
                    customBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      Icons.add,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  _buildNavItem(Icons.search_outlined, Icons.search, 3),
                  _buildNavItem(Icons.person_outline, Icons.person, 4),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    body: _getPage(currentPageIndex),
  );
}


  Widget _buildNavItem(IconData outlinedIcon, IconData filledIcon, int index) {
    bool isSelected = currentPageIndex == index;
    
    return InkWell(
      onTap: () {
      HapticFeedback.lightImpact();
      setState(() => currentPageIndex = index);
    },
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? filledIcon : outlinedIcon,
              color: isSelected ? const Color(0xFFA90015) : Colors.grey.shade700,
              size: 26,
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return const WorkoutPage();
      case 1:
        return const LibraryPage();
      case 2:
        return const CreateScreen();
      case 3:
        return const MarketplacePage();
      case 4:
        return const ProfilePage();
      default:
        return const WorkoutPage();
    }
  }
}