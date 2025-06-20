import 'package:flutter/material.dart';
import 'animated_splash_screen.dart'; // імпортуй свою анімацію
import '../app.dart'; // або твій основний App/Home екран
import '/widgets/theme.dart'; // якщо ти зберіг у lib/theme.dart


class SplashWrapper extends StatelessWidget {
  const SplashWrapper({super.key});

  @override
Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: lightTheme, // світла тема
      darkTheme: darkTheme, // темна тема
      themeMode: ThemeMode.system, // автоматичний вибір (можеш змінити на light)
      initialRoute: '/',
      routes: {
        '/': (context) => const AnimatedSplashScreen(),
        '/home': (context) => const MyApp(),
      },
    );
  }
}
