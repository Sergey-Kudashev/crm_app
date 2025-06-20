import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;


class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _moveController;
  late final Animation<double> _moveAnimation;
  late final Animation<double> _rotationAnimation;
  late final AnimationController _fadeController;
  late Future<void> _preloadFuture;

  @override
  void initState() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
    ));

    super.initState();

    _preloadFuture = _preloadHome();

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

    // 🔄 Обертання логотипа
    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * 3.1416) // 360°
        .animate(CurvedAnimation(
      parent: _moveController,
      curve: Curves.easeInOut,
    ));

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _startAnimation();
  }

  Future<void> _preloadHome() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('activity')
          .orderBy('date', descending: true)
          .limit(20)
          .get();
    } catch (e) {
      debugPrint('Preload error: $e');
    }
  }

  Future<void> _startAnimation() async {
    await Future.wait([
      _moveController.forward(),
      _preloadFuture,
    ]);
    await _fadeController.forward();

    // SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    //   statusBarColor: Colors.deepPurple,
    //   statusBarIconBrightness: Brightness.light,
    // ));
    if (kIsWeb) {
  html.document
      .querySelector('meta[name="theme-color"]')
      ?.setAttribute('content', '#673AB7');
}


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
                  child: Transform.rotate(
                    angle: _rotationAnimation.value,
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
