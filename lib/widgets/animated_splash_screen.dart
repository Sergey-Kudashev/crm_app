import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:video_player/video_player.dart';

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen> {
  late VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();
    _setThemeColorForWeb();
    _preloadHome();
    _initVideo();
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

Future<void> _initVideo() async {
  _videoController = VideoPlayerController.asset('assets/videos/splash.mp4');
  await _videoController.initialize();
  _videoController.setLooping(false);

  // 🧩 ДОДАЙ ЦЕ! Інакше в браузері відео не запуститься
  _videoController.setVolume(0); 

  _videoController.play();

  Future.delayed(const Duration(milliseconds: 3200), () {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  });
}


  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _videoController.value.isInitialized
            ? AspectRatio(
                aspectRatio: _videoController.value.aspectRatio,
                child: VideoPlayer(_videoController),
              )
            : const SizedBox(), // або можна показати спіннер
      ),
    );
  }
}
