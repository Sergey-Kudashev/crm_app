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
  bool _videoError = false;

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
    try {
      if (kIsWeb) {
        _videoController = VideoPlayerController.network('videos/splash.mp4');
      } else {
        _videoController = VideoPlayerController.asset('assets/videos/splash.mp4');
      }

      await _videoController.initialize();
      _videoController.setLooping(false);
      _videoController.setVolume(0); // Для Web autoplay
      _videoController.play();

      // Навігація після завершення
      _videoController.addListener(() {
        if (_videoController.value.position >= _videoController.value.duration &&
            mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      });
    } catch (e) {
      debugPrint('Video init error: $e');
      setState(() {
        _videoError = true;
      });

      // Якщо відео не запускається, перейти через 3 секунди
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      });
    }
  }

  @override
  void dispose() {
    if (!_videoError) {
      _videoController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _videoError || !_videoController.value.isInitialized
            ? Image.asset(
                'assets/splash_logo.png',
                width: 160,
                height: 160,
              )
            : AspectRatio(
                aspectRatio: _videoController.value.aspectRatio,
                child: VideoPlayer(_videoController),
              ),
      ),
    );
  }
}
