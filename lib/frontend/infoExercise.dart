import 'package:flutter/material.dart';

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
  State<InfoExerciseScreen> createState() => _InfoExerciseScreenState() ;
}

class _InfoExerciseScreenState extends State<InfoExerciseScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
      });
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
          widget.name,
          style: TextStyle(
            fontSize: 20,
            color: theme.colorScheme.onBackground,
            letterSpacing: -0.5,
          ),
        ),
      ),
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

  Widget _buildPRBadge() {
    final pr = widget.pr;
    final hasPR = pr > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFA90015).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA90015).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          hasPR? const Icon(Icons.emoji_events_rounded, color: Color(0xFFA90015), size: 28) : const Icon(Icons.not_interested, color: Color(0xFFA90015), size: 28),
          const SizedBox(width: 12),
          Text(
            hasPR ? '${pr.toStringAsFixed(1)} kg' : 'Has not been set',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFFA90015),
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildImageCarousel() {
    return AspectRatio(
      aspectRatio: 1.1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: widget.images.isEmpty 
          ? Container(
              color: Colors.white,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported_rounded, 
                    color: Colors.white, 
                    size: 48),
                  const SizedBox(height: 8),
                  Text('Imagen no disponible',
                    style: TextStyle(color: Colors.white)),
                ],
              ),
            )
          : Stack(
              alignment: Alignment.bottomCenter,
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: widget.images.length,
                  itemBuilder: (context, index) => Image.asset(
                    'assets/images/exercises_images/${widget.images[index]}',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.white,
                      alignment: Alignment.center,
                      child: const Text('Error de imagen'),
                    ),
                  ),
                ),
                if (widget.images.length > 1)
                  Positioned(
                    bottom: 16,
                    child: Row(
                      children: List.generate(
                        widget.images.length,
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

  Widget _buildDetailSection() {
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
          _buildSectionTitle('Exercise details'),
          _buildInfoItem(
            Icons.fitness_center_rounded,
            'Primary muscles',
            widget.primaryMuscles.isNotEmpty ? widget.primaryMuscles[0] : 'None',
          ),
          _buildInfoItem(
            Icons.account_tree_rounded,
            'Secondary muscles',
            widget.secondaryMuscles.isNotEmpty ? widget.secondaryMuscles.join(', ') : 'None',
          ),
          _buildInfoItem(Icons.bar_chart_rounded, 'Level', widget.level),
          const SizedBox(height: 28),
          _buildSectionTitle('Instructions'),
          const SizedBox(height: 16),
          ...widget.instructions.asMap().entries.map(
                (entry) => _buildInstructionStep(entry.key + 1, entry.value),
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

  Widget _buildInfoItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: const Color(0xFFA90015)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
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