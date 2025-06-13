import 'package:flutter/material.dart';
import 'package:muscle_app/backend/exercise_loader.dart';


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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.grey.withOpacity(0.1),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isLoading ? 'Cargando...' : _exerciseData?['name'] ?? 'Ejercicio',
          style: TextStyle(
            fontSize: 20,
            color: theme.colorScheme.onBackground,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _exerciseData == null
              ? const Center(child: Text('Ejercicio no encontrado'))
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
                color: Colors.white,
                alignment: Alignment.center,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported_rounded, color: Colors.grey, size: 48),
                    SizedBox(height: 8),
                    Text('Imagen no disponible', style: TextStyle(color: Colors.grey)),
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
                        color: Colors.white,
                        alignment: Alignment.center,
                        child: const Text('Error de imagen'),
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
                                  ? const Color(0xFFA90015)
                                  : Colors.white.withOpacity(0.5),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
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
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Colors.black87,
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
              color: const Color(0xFFA90015).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$number',
              style: const TextStyle(
                color: Color(0xFFA90015),
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
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}