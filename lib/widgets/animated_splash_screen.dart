import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen> {
  bool _gifFailed = false;

  @override
  void initState() {
    super.initState();
    _setThemeColorForWeb();
    _preloadHome();
    _startSplashTimer();
  }

  void _setThemeColorForWeb() {
    if (kIsWeb) {
      html.document
          .querySelector('meta[name="theme-color"]')
          ?.setAttribute('content', '#673AB7');
    }
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

  void _startSplashTimer() {
    Future.delayed(const Duration(milliseconds: 2900), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FittedBox(
          fit: BoxFit.fitWidth,
          child: _gifFailed
              ? Image.asset(
                  'assets/splash_logo.png',
                  gaplessPlayback: true,
                )
              : Image.asset(
                  'assets/splash.gif',
                  gaplessPlayback: true,
                  errorBuilder: (context, error, stackTrace) {
                    setState(() {
                      _gifFailed = true;
                    });
                    return Image.asset(
                      'assets/splash_logo.png',
                      gaplessPlayback: true,
                    );
                  },
                ),
        ),
      ),
    );
  }
}
