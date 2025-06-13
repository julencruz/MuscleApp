import 'package:flutter/material.dart';

class WelcomeAnimation extends StatefulWidget {
  final VoidCallback onAnimationComplete;
  final Color primaryColor;
  final List<String> welcomeWords;
  final String logoPath;
  final String humorMessage;

  const WelcomeAnimation({
    super.key, 
    required this.onAnimationComplete,
    this.primaryColor = const Color(0xFFA90015),
    this.welcomeWords = const ['Focus', 'Train', 'Achieve'],
    this.logoPath = 'assets/images/logoMuscleApp2.png',
    this.humorMessage = "Don't forget to warm up",
  });

  @override
  State<WelcomeAnimation> createState() => _WelcomeAnimationState();
}

class _WelcomeAnimationState extends State<WelcomeAnimation>
    with TickerProviderStateMixin {
  
  // Controladores para cada fase de la animación
  late AnimationController _logoController;
  late AnimationController _wordsController;
  late AnimationController _finalController;
  late AnimationController _humorController;
  
  // Animaciones para el logo
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  
  // Lista de animaciones para palabras 
  List<Animation<double>> _wordOpacityAnimations = [];
  List<Animation<double>> _wordScaleAnimations = [];
  List<Animation<Offset>> _wordOffsetAnimations = [];
  
  // Animación para el mensaje final
  late Animation<double> _finalScaleAnimation;
  late Animation<double> _finalOpacityAnimation;
  
  // Animación para el mensaje de humor
  late Animation<double> _humorOpacityAnimation;
  late Animation<Offset> _humorOffsetAnimation;

  @override
  void initState() {
    super.initState();
    
    // Inicializar controlador para el logo - más rápido ahora
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // 600 → 300
    );
    
    _logoScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );
    
    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    
    // Controlador para todas las palabras - más rápido
    _wordsController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.welcomeWords.length * 300), // 400 → 200 por palabra
    );
    
    // Crear animaciones para cada palabra
    for (int i = 0; i < widget.welcomeWords.length; i++) {
      final startInterval = i / widget.welcomeWords.length;
      final endInterval = (i + 0.7) / widget.welcomeWords.length;
      
      final opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _wordsController,
          curve: Interval(startInterval, endInterval, curve: Curves.easeOut),
        ),
      );
      
      final scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(
          parent: _wordsController,
          curve: Interval(startInterval, endInterval, curve: Curves.easeOutBack),
        ),
      );
      
      final offsetAnimation = Tween<Offset>(
        begin: Offset(0, 0.3),
        end: Offset(0, 0),
      ).animate(
        CurvedAnimation(
          parent: _wordsController,
          curve: Interval(startInterval, endInterval, curve: Curves.easeOutCubic),
        ),
      );
      
      _wordOpacityAnimations.add(opacityAnimation);
      _wordScaleAnimations.add(scaleAnimation);
      _wordOffsetAnimations.add(offsetAnimation);
    }
    
    // Inicializar controlador para el mensaje final - más rápido
    _finalController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // 600 → 300
    );
    
    _finalScaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _finalController,
        curve: Curves.easeOutBack,
      ),
    );
    
    _finalOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _finalController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );
    
    // Controlador para el mensaje humorístico
    _humorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // 600 → 300
    );
    
    _humorOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _humorController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
      ),
    );
    
    _humorOffsetAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _humorController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    // Iniciar secuencia de animaciones
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    // Mostrar el logo
    await _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 150)); // 300 → 150
    
    // Mostrar las palabras secuencialmente pero permaneciendo visibles
    await _wordsController.forward();
    await Future.delayed(const Duration(milliseconds: 200)); // 300 → 150
    
    // Mostrar mensaje final
    await _finalController.forward();
    await Future.delayed(const Duration(milliseconds: 150)); // 300 → 150
    
    // Mostrar mensaje humorístico
    await _humorController.forward();
    await Future.delayed(const Duration(milliseconds: 200)); // 1200 → 600
    
    // Fade out de todo
    await Future.delayed(const Duration(milliseconds: 150)); // 300 → 150
    await Future.wait([
      _finalController.reverse(),
      _humorController.reverse(),
      _wordsController.reverse(),
      _logoController.reverse(),
    ]);
    
    // Notificar que la animación ha terminado
    widget.onAnimationComplete();
  }
  @override
  void dispose() {
    _logoController.dispose();
    _wordsController.dispose();
    _finalController.dispose();
    _humorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _logoController, 
            _wordsController,
            _finalController,
            _humorController,
          ]),
          builder: (context, child) {
            return Stack(
              children: [
                // Fondo con estilo minimalista
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.2,
                        colors: [
                          Colors.white,
                          Colors.grey[50]!,
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Logo personalizado animado
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 80.0),
                    child: Opacity(
                      opacity: _logoOpacityAnimation.value,
                      child: Transform.scale(
                        scale: _logoScaleAnimation.value,
                        child: Image.asset(
                          widget.logoPath,
                          width: 120,
                          height: 120,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Palabras animadas (una debajo de otra)
                Align(
                  alignment: Alignment.center,
                  child: _buildWordColumn(),
                ),
                
                // Mensaje humorístico en la parte inferior
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 60.0),
                    child: SlideTransition(
                      position: _humorOffsetAnimation,
                      child: Opacity(
                        opacity: _humorOpacityAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Text(
                            widget.humorMessage,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
  
  // Construir todas las palabras en columna con diferentes animaciones
  Widget _buildWordColumn() {
    // Palabras de bienvenida
    List<Widget> wordWidgets = [];
    
    for (int i = 0; i < widget.welcomeWords.length; i++) {
      final wordWidget = Opacity(
        opacity: _wordOpacityAnimations[i].value,
        child: Transform.scale(
          scale: _wordScaleAnimations[i].value,
          child: SlideTransition(
            position: _wordOffsetAnimations[i],
            child: Text(
              widget.welcomeWords[i],
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: widget.primaryColor,
                letterSpacing: 1.5,
                shadows: [
                  Shadow(
                    color: widget.primaryColor.withOpacity(0.2),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
      
      wordWidgets.add(wordWidget);
      
      // Espacio entre palabras
      if (i < widget.welcomeWords.length - 1) {
        wordWidgets.add(const SizedBox(height: 15));
      }
    }
    
    // Mensaje final
    final finalMessage = Opacity(
      opacity: _finalOpacityAnimation.value,
      child: Transform.scale(
        scale: _finalScaleAnimation.value,
        child: Padding(
          padding: const EdgeInsets.only(top: 30.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: widget.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'All distractions removed',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: widget.primaryColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
    
    wordWidgets.add(finalMessage);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: wordWidgets,
    );
  }
}
