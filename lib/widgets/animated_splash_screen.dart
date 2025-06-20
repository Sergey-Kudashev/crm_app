import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _moveController;
  late final Animation<double> _moveAnimation;
  late final AnimationController _fadeController;
  late Future<void> _preloadFuture;

  @override
  void initState() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
  statusBarColor: Colors.white,
  statusBarIconBrightness: Brightness.dark,
));

    super.initState();

    // ініціалізація preload логіки
    _preloadFuture = _preloadHome();

    // Анімація руху
    _moveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _moveAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 50.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 50.0, end: -200.0), weight: 70),
    ]).animate(CurvedAnimation(
      parent: _moveController,
      curve: Curves.easeInOut,
    ));

    // Анімація зникнення
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _startAnimation();
  }

  Future<void> _preloadHome() async {
    // тут можеш preload'ити щось
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _startAnimation() async {
    await Future.wait([
      _moveController.forward(),
      _preloadFuture,
    ]);
    await _fadeController.forward();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.deepPurple,
      statusBarIconBrightness: Brightness.light,
    ));

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  void dispose() {
    _moveController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: Listenable.merge([_moveController, _fadeController]),
        builder: (context, child) {
          return SizedBox.expand(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.translate(
                  offset: Offset(0, _moveAnimation.value),
                  child: Opacity(
                    opacity: 1.0 - _fadeController.value,
                    child: Center(
                      child: Image.asset(
                        'assets/splash_logo.png',
                        width: 120,
                        height: 120,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
