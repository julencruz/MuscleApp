import 'package:flutter/material.dart';
import 'package:muscle_app/theme/app_colors.dart';

class InfoExerciseScreen extends StatefulWidget {
  final String name;
  final List<dynamic> primaryMuscles;
  final List<dynamic> secondaryMuscles;
  final List<dynamic> instructions;
  final List<dynamic> images;
  final String level;
  final double pr;

  const InfoExerciseScreen({
    Key? key,
    required this.name,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.instructions,
    required this.images,
    required this.level,
    required this.pr,
  }) : super(key: key);

  @override
  State<InfoExerciseScreen> createState() => _InfoExerciseScreenState();
}

class _InfoExerciseScreenState extends State<InfoExerciseScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  _buildPRBadge(),
                  const SizedBox(height: 28),
                  _buildImageCarousel(),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildDetailSection(),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
        widget.name,
        style: TextStyle(
          fontSize: 20,
          color: textColor,
          letterSpacing: -0.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPRBadge() {
    final pr = widget.pr;
    final hasPR = pr > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: redColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: redColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasPR ? Icons.emoji_events_rounded : Icons.not_interested,
            color: redColor,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            hasPR ? '${pr.toStringAsFixed(1)} kg' : 'No PR set',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: redColor,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    if (widget.images.isEmpty) {
      return _buildNoImagePlaceholder();
    }

    return AspectRatio(
      aspectRatio: 1.1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) => _buildImageItem(index),
            ),
            if (widget.images.length > 1) _buildPageIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildNoImagePlaceholder() {
    return AspectRatio(
      aspectRatio: 1.1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          color: cardColor,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported_rounded,
                color: hintColor,
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                'No image available',
                style: TextStyle(color: hintColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageItem(int index) {
    final imagePath = 'assets/images/exercises_images/${widget.images[index]}';
    
    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: cardColor,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, color: hintColor, size: 48),
            const SizedBox(height: 8),
            Text(
              'Image error',
              style: TextStyle(color: textColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Positioned(
      bottom: 16,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          widget.images.length,
          (index) => Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _currentPage == index
                  ? redColor
                  : Colors.white.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection() {
    return Container(
      padding: const EdgeInsets.all(24),
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
          _buildSectionTitle('Exercise Details'),
          const SizedBox(height: 16),
          _buildInfoItem(
            Icons.fitness_center_rounded,
            'Primary Muscles',
            _formatMuscleList(widget.primaryMuscles),
          ),
          _buildInfoItem(
            Icons.account_tree_rounded,
            'Secondary Muscles',
            _formatMuscleList(widget.secondaryMuscles),
          ),
          _buildInfoItem(Icons.bar_chart_rounded, 'Level', widget.level),
          const SizedBox(height: 32),
          _buildSectionTitle('Instructions'),
          const SizedBox(height: 16),
          if (widget.instructions.isNotEmpty)
            ...widget.instructions.asMap().entries.map(
                  (entry) => _buildInstructionStep(entry.key + 1, entry.value.toString()),
                )
          else
            _buildNoInstructionsPlaceholder(),
        ],
      ),
    );
  }

  String _formatMuscleList(List<dynamic> muscles) {
    if (muscles.isEmpty) return 'None';
    return muscles.map((muscle) => muscle.toString()).join(', ');
  }

  Widget _buildNoInstructionsPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hintColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: hintColor),
          const SizedBox(width: 12),
          Text(
            'No instructions available',
            style: TextStyle(color: hintColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: textColor,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: redColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: redColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
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
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: redColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: redColor.withOpacity(0.3)),
            ),
            child: Text(
              '$number',
              style: TextStyle(
                color: redColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}