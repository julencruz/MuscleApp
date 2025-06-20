import 'package:flutter/material.dart';
import 'package:muscle_app/backend/exercise_loader.dart';
import 'package:muscle_app/theme/app_colors.dart';


class InfoWarmupExerciseScreen extends StatefulWidget {
  final String exerciseId;

  const InfoWarmupExerciseScreen({Key? key, required this.exerciseId}) : super(key: key);

  @override
  State<InfoWarmupExerciseScreen> createState() => _InfoWarmupExerciseScreenState();
}

class _InfoWarmupExerciseScreenState extends State<InfoWarmupExerciseScreen> {
  Map<String, dynamic>? _exerciseData;
  late PageController _pageController;
  int _currentPage = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
      });
    });
    _loadExerciseData();
  }

  Future<void> _loadExerciseData() async {
    final data = await ExerciseLoader.getExerciseById(widget.exerciseId);
    setState(() {
      _exerciseData = data;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: appBarBackgroundColor,
        elevation: 0,
        shadowColor: shadowColor,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 32, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isLoading ? 'Cargando...' : _exerciseData?['name'] ?? 'Ejercicio',
          style: TextStyle(
            fontSize: 20,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: redColor))
          : _exerciseData == null
              ? Center(child: Text('Ejercicio no encontrado', style: TextStyle(color: textColor)))
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Column(
                          children: [
                            _buildImageCarousel(_exerciseData!['images'] as List<dynamic>),
                            const SizedBox(height: 28),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildInstructionsSection(_exerciseData!['instructions'] as List<dynamic>),
                          const SizedBox(height: 40),
                        ]),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildImageCarousel(List<dynamic> images) {
    return AspectRatio(
      aspectRatio: 1.1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: images.isEmpty
            ? Container(
                color: cardColor,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported_rounded, color: hintColor, size: 48),
                    const SizedBox(height: 8),
                    Text('Imagen no disponible', style: TextStyle(color: hintColor)),
                  ],
                ),
              )
            : Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: images.length,
                    itemBuilder: (context, index) => Image.asset(
                      'assets/images/exercises_images/${images[index]}',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: cardColor,
                        alignment: Alignment.center,
                        child: Text('Error de imagen', style: TextStyle(color: textColor)),
                      ),
                    ),
                  ),
                  if (images.length > 1)
                    Positioned(
                      bottom: 16,
                      child: Row(
                        children: List.generate(
                          images.length,
                          (index) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentPage == index
                                  ? redColor
                                  : contraryTextColor.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildInstructionsSection(List<dynamic> instructions) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Instructions'),
          const SizedBox(height: 16),
          ...instructions.asMap().entries.map(
            (entry) => _buildInstructionStep(entry.key + 1, entry.value as String),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(text,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: textColor,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildInstructionStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: redColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$number',
              style: TextStyle(
                color: redColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}